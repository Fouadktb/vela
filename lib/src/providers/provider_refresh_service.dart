import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../catalog/catalog_models.dart';
import 'm3u/m3u_parser.dart';
import 'provider_models.dart';
import 'provider_repository.dart';
import 'xtream/xtream_client.dart';
import 'xtream/xtream_importer.dart';

class ProviderRefreshService {
  ProviderRefreshService({
    required ProviderRepository providerRepository,
    http.Client? httpClient,
    this.playlistTimeout = const Duration(seconds: 15),
    this.maxPlaylistBytes = 20 * 1024 * 1024,
  }) : _providerRepository = providerRepository,
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  final ProviderRepository _providerRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final Duration playlistTimeout;
  final int maxPlaylistBytes;
  final Map<String, Future<ProviderRefreshSummary>> _inFlightRefreshes = {};
  Future<List<ProviderRefreshSummary>>? _staleRefresh;
  Timer? _timer;
  var _disposed = false;

  Future<ProviderRefreshSummary> refreshProvider(String providerId) async {
    final provider = await _providerRepository.getProvider(providerId);
    if (provider == null) {
      throw const ProviderRefreshFailure('Provider was not found');
    }
    return refresh(provider);
  }

  Future<ProviderRefreshSummary> refresh(IptvProvider provider) async {
    final existing = _inFlightRefreshes[provider.id];
    if (existing != null) {
      return existing;
    }

    if (_disposed) {
      return ProviderRefreshSummary(
        providerId: provider.id,
        status: ProviderRefreshStatus.failed,
        itemCount: 0,
        message: 'Provider refresh service is not running',
        finishedAt: DateTime.now(),
      );
    }

    final refresh = _refresh(provider);
    _inFlightRefreshes[provider.id] = refresh;
    unawaited(
      refresh.whenComplete(() {
        if (identical(_inFlightRefreshes[provider.id], refresh)) {
          _inFlightRefreshes.remove(provider.id);
        }
      }),
    );
    return refresh;
  }

  Future<ProviderRefreshSummary> _refresh(IptvProvider provider) async {
    final run = await _providerRepository.createRefreshRun(provider.id);
    final startedAt = dateTimeFromMs(run.startedAtMs);

    try {
      final importResult = await _snapshotFor(provider);
      final itemCount = _snapshotItemCount(importResult.snapshot);
      if (itemCount == 0) {
        throw const ProviderRefreshFailure(
          'Provider did not return any playable items',
        );
      }
      await _providerRepository.replaceProviderCatalog(importResult.snapshot);
      final message = _successMessage(itemCount, importResult.warningMessage);
      await _providerRepository.finishRefreshRun(
        runId: run.id,
        status: ProviderRefreshStatus.succeeded,
        itemCount: itemCount,
        message: message,
      );
      return ProviderRefreshSummary(
        providerId: provider.id,
        status: ProviderRefreshStatus.succeeded,
        itemCount: itemCount,
        message: message,
        startedAt: startedAt,
        finishedAt: DateTime.now(),
      );
    } catch (error) {
      final message = _safeRefreshError(error);
      await _providerRepository.finishRefreshRun(
        runId: run.id,
        status: ProviderRefreshStatus.failed,
        message: message,
      );
      return ProviderRefreshSummary(
        providerId: provider.id,
        status: ProviderRefreshStatus.failed,
        itemCount: 0,
        message: message,
        startedAt: startedAt,
        finishedAt: DateTime.now(),
      );
    }
  }

  Future<List<ProviderRefreshSummary>> refreshStaleProvidersOnLaunch() {
    return refreshStaleProviders();
  }

  Future<List<ProviderRefreshSummary>> refreshStaleProviders() async {
    if (_disposed) {
      return const [];
    }
    final existing = _staleRefresh;
    if (existing != null) {
      return existing;
    }

    final refresh = _refreshStaleProviders();
    _staleRefresh = refresh;
    unawaited(
      refresh.whenComplete(() {
        if (identical(_staleRefresh, refresh)) {
          _staleRefresh = null;
        }
      }),
    );
    return refresh;
  }

  Future<List<ProviderRefreshSummary>> _refreshStaleProviders() async {
    final providers = await _providerRepository.listProviders();
    final staleProviders = providers.where((provider) {
      return provider.refreshEnabled &&
          provider.canRefresh &&
          provider.isRefreshStale;
    }).toList();
    final results = <ProviderRefreshSummary>[];
    for (final provider in staleProviders) {
      results.add(await refresh(provider));
    }
    return results;
  }

  void startIntervalRefresh({
    Duration checkEvery = const Duration(minutes: 1),
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(checkEvery, (_) {
      unawaited(
        refreshStaleProviders().catchError(
          (_) => const <ProviderRefreshSummary>[],
        ),
      );
    });
  }

  void stopIntervalRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    stopIntervalRefresh();
    final staleRefresh = _staleRefresh;
    if (staleRefresh != null) {
      await staleRefresh;
    }
    if (_inFlightRefreshes.isNotEmpty) {
      await Future.wait(_inFlightRefreshes.values);
    }
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<_ProviderImportResult> _snapshotFor(IptvProvider provider) {
    if (!provider.canRefresh) {
      throw const ProviderRefreshFailure('Provider details are incomplete');
    }
    return switch (provider.type) {
      ProviderType.xtream => _importXtream(provider),
      ProviderType.m3uUrl => _importM3uUrl(provider),
      ProviderType.m3uFile => _importM3uFile(provider),
    };
  }

  Future<_ProviderImportResult> _importM3uUrl(IptvProvider provider) async {
    final source = provider.m3uUrl?.trim();
    if (source == null || source.isEmpty) {
      throw const ProviderRefreshFailure('Playlist source is incomplete');
    }
    final playlist = await _loadPlaylistUrl(source);
    return _parsePlaylist(provider.id, playlist);
  }

  Future<_ProviderImportResult> _importM3uFile(IptvProvider provider) async {
    final path = provider.localFilePath?.trim();
    if (path == null || path.isEmpty) {
      throw const ProviderRefreshFailure('Playlist source is incomplete');
    }
    final file = File(path);
    try {
      final length = await file.length();
      if (length > maxPlaylistBytes) {
        throw const ProviderRefreshFailure('Playlist is too large to import');
      }
      return _parsePlaylist(provider.id, await file.readAsString());
    } on ProviderRefreshFailure {
      rethrow;
    } on FileSystemException {
      throw const ProviderRefreshFailure(
        'Local playlist file could not be read',
      );
    }
  }

  Future<_ProviderImportResult> _importXtream(IptvProvider provider) async {
    final serverUrl = provider.serverUrl?.trim();
    final username = provider.username?.trim();
    final password = provider.password?.trim();
    if (serverUrl == null ||
        serverUrl.isEmpty ||
        username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      throw const ProviderRefreshFailure(
        'Xtream provider details are incomplete',
      );
    }
    final client = XtreamClient(
      credentials: XtreamCredentials(
        serverUrl: serverUrl,
        username: username,
        password: password,
      ),
      httpClient: _httpClient,
      timeout: playlistTimeout,
    );
    final snapshot = await XtreamImporter(
      client,
    ).importProvider(providerId: provider.id);
    return _ProviderImportResult(snapshot: snapshot);
  }

  _ProviderImportResult _parsePlaylist(String providerId, String playlist) {
    final parsed = const M3uParser().parse(playlist, providerId: providerId);
    if (parsed.entries.isEmpty) {
      throw const ProviderRefreshFailure(
        'Playlist did not contain any playable items',
      );
    }
    return _ProviderImportResult(
      snapshot: parsed.snapshot,
      warningMessage: _m3uWarningSummary(parsed.diagnostics),
    );
  }

  Future<String> _loadPlaylistUrl(String source) async {
    final uri = Uri.tryParse(source);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const ProviderRefreshFailure('Playlist source is not supported');
    }

    late http.StreamedResponse response;
    try {
      response = await _httpClient
          .send(http.Request('GET', uri))
          .timeout(playlistTimeout);
    } on TimeoutException {
      throw const ProviderRefreshFailure('Playlist could not be loaded');
    } on http.ClientException {
      throw const ProviderRefreshFailure('Playlist could not be loaded');
    } catch (_) {
      throw const ProviderRefreshFailure('Playlist could not be loaded');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProviderRefreshFailure(
        'Playlist request failed with HTTP ${response.statusCode}',
      );
    }
    if (response.contentLength != null &&
        response.contentLength! > maxPlaylistBytes) {
      throw const ProviderRefreshFailure('Playlist is too large to import');
    }

    final bytes = <int>[];
    try {
      await for (final chunk in response.stream.timeout(playlistTimeout)) {
        bytes.addAll(chunk);
        if (bytes.length > maxPlaylistBytes) {
          throw const ProviderRefreshFailure('Playlist is too large to import');
        }
      }
    } on ProviderRefreshFailure {
      rethrow;
    } on TimeoutException {
      throw const ProviderRefreshFailure('Playlist could not be loaded');
    } catch (_) {
      throw const ProviderRefreshFailure('Playlist could not be loaded');
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}

class _ProviderImportResult {
  const _ProviderImportResult({required this.snapshot, this.warningMessage});

  final ProviderCatalogSnapshot snapshot;
  final String? warningMessage;
}

int _snapshotItemCount(ProviderCatalogSnapshot snapshot) {
  final playableItems = snapshot.items.where((item) {
    if (item.contentType == CatalogContentType.series) {
      return false;
    }
    return _hasPlayableStream(item.streamUrl, item.streamJson);
  }).length;
  final playableEpisodes = snapshot.episodes.where((episode) {
    return _hasPlayableStream(episode.streamUrl, episode.streamJson);
  }).length;
  return playableItems + playableEpisodes;
}

String _successMessage(int itemCount, String? warningMessage) {
  final base = 'Imported $itemCount items';
  if (warningMessage == null || warningMessage.isEmpty) {
    return base;
  }
  return '$base. $warningMessage';
}

String? _m3uWarningSummary(List<M3uParseDiagnostic> diagnostics) {
  if (diagnostics.isEmpty) {
    return null;
  }
  final count = diagnostics.length;
  final first = diagnostics.first;
  final noun = count == 1 ? 'entry' : 'entries';
  return 'Skipped $count malformed playlist $noun; first warning at line ${first.line}: ${first.message}';
}

bool _hasPlayableStream(String? streamUrl, String? streamJson) {
  return streamUrl?.trim().isNotEmpty == true ||
      streamJson?.trim().isNotEmpty == true;
}

String _safeRefreshError(Object error) {
  if (error is ProviderRefreshFailure) {
    return error.message;
  }
  if (error is XtreamClientException) {
    return error.message;
  }
  if (error is ArgumentError) {
    return 'Imported catalog data was not valid';
  }
  return 'Provider refresh failed';
}
