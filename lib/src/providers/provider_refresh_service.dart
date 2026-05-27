import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../catalog/catalog_models.dart';
import 'epg/xmltv_parser.dart';
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
    this.maxPlaylistBytes = 100 * 1024 * 1024,
  }) : _providerRepository = providerRepository,
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  final ProviderRepository _providerRepository;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final Duration playlistTimeout;
  final int maxPlaylistBytes;
  final Map<String, Future<ProviderRefreshSummary>> _inFlightRefreshes = {};
  final Map<String, Future<void>> _inFlightEpgRefreshes = {};
  final Map<String, Future<void>> _inFlightItemDetailRefreshes = {};
  final Map<String, Future<void>> _inFlightSeriesEpisodeRefreshes = {};
  Future<List<ProviderRefreshSummary>>? _staleRefresh;
  Timer? _timer;
  var _disposed = false;

  Future<ProviderRefreshSummary> refreshProvider(
    String providerId, {
    void Function(String message)? onProgress,
  }) async {
    final provider = await _providerRepository.getProvider(providerId);
    if (provider == null) {
      throw const ProviderRefreshFailure('Provider was not found');
    }
    return refresh(provider, onProgress: onProgress);
  }

  Future<void> refreshSeriesEpisodeDetails({
    required String providerId,
    required String seriesId,
    required String externalSeriesId,
    void Function(String message)? onProgress,
  }) async {
    final key = '$providerId|$seriesId';
    final existing = _inFlightSeriesEpisodeRefreshes[key];
    if (existing != null) {
      return existing;
    }
    final refresh = _refreshSeriesEpisodeDetails(
      providerId: providerId,
      seriesId: seriesId,
      externalSeriesId: externalSeriesId,
      onProgress: onProgress,
    );
    _inFlightSeriesEpisodeRefreshes[key] = refresh;
    unawaited(
      refresh.whenComplete(() {
        if (identical(_inFlightSeriesEpisodeRefreshes[key], refresh)) {
          _inFlightSeriesEpisodeRefreshes.remove(key);
        }
      }),
    );
    return refresh;
  }

  Future<void> refreshCatalogItemDetails({
    required String providerId,
    required String itemId,
    required CatalogContentType contentType,
    required String? externalId,
    void Function(String message)? onProgress,
  }) async {
    if (contentType == CatalogContentType.live) {
      return;
    }
    final cleanExternalId = externalId?.trim();
    if (cleanExternalId == null || cleanExternalId.isEmpty) {
      return;
    }
    final key = '$providerId|${contentType.name}|$itemId';
    final existing = _inFlightItemDetailRefreshes[key];
    if (existing != null) {
      return existing;
    }
    final refresh = switch (contentType) {
      CatalogContentType.movie => _refreshMovieDetails(
        providerId: providerId,
        itemId: itemId,
        externalMovieId: cleanExternalId,
        onProgress: onProgress,
      ),
      CatalogContentType.series => refreshSeriesEpisodeDetails(
        providerId: providerId,
        seriesId: itemId,
        externalSeriesId: cleanExternalId,
        onProgress: onProgress,
      ),
      CatalogContentType.live => Future<void>.value(),
    };
    _inFlightItemDetailRefreshes[key] = refresh;
    unawaited(
      refresh.whenComplete(() {
        if (identical(_inFlightItemDetailRefreshes[key], refresh)) {
          _inFlightItemDetailRefreshes.remove(key);
        }
      }),
    );
    return refresh;
  }

  Future<void> _refreshMovieDetails({
    required String providerId,
    required String itemId,
    required String externalMovieId,
    void Function(String message)? onProgress,
  }) async {
    final provider = await _providerRepository.getProvider(providerId);
    if (provider == null || provider.type != ProviderType.xtream) {
      return;
    }
    final client = _xtreamClientForProvider(provider);
    if (client == null) {
      return;
    }
    onProgress?.call('Loading movie details');
    final info = await client.getVodInfo(externalMovieId);
    onProgress?.call('Saving movie details');
    await _providerRepository.updateCatalogItemDetails(
      CatalogItemDetailsInput(
        providerId: providerId,
        itemId: itemId,
        contentType: CatalogContentType.movie,
        description: info.description,
        artworkUrl: info.artworkUrl,
        rating: info.rating,
        year: info.year,
        durationSeconds: info.durationSeconds,
      ),
    );
  }

  Future<void> _refreshSeriesEpisodeDetails({
    required String providerId,
    required String seriesId,
    required String externalSeriesId,
    void Function(String message)? onProgress,
  }) async {
    final provider = await _providerRepository.getProvider(providerId);
    if (provider == null) {
      throw const ProviderRefreshFailure('Provider was not found');
    }
    if (provider.type != ProviderType.xtream) {
      return;
    }
    final client = _xtreamClientForProvider(provider);
    if (client == null || externalSeriesId.trim().isEmpty) {
      throw const ProviderRefreshFailure(
        'Xtream provider details are incomplete',
      );
    }

    onProgress?.call('Loading episode details');
    final info = await client.getSeriesInfo(externalSeriesId.trim());
    await _providerRepository.updateCatalogItemDetails(
      CatalogItemDetailsInput(
        providerId: providerId,
        itemId: seriesId,
        contentType: CatalogContentType.series,
        description: info.overview,
        artworkUrl: info.cover,
        rating: info.rating,
        year: info.year,
        durationSeconds: info.durationSeconds,
      ),
    );
    await _providerRepository.updateSeriesDetails(
      SeriesDetailsInput(
        providerId: providerId,
        seriesId: seriesId,
        overview: info.overview,
        posterUrl: info.cover,
        backdropUrl: info.backdropUrl,
      ),
    );
    final details = xtreamSeriesEpisodeDetails(
      providerId: providerId,
      seriesItemId: seriesId,
      info: info,
    );
    onProgress?.call('Saving episode details');
    await _providerRepository.replaceSeriesEpisodeDetails(
      providerId: providerId,
      seriesId: seriesId,
      seasons: details.seasons,
      episodes: details.episodes,
    );
  }

  Future<void> refreshProviderEpg(
    String providerId, {
    void Function(String message)? onProgress,
  }) async {
    final existing = _inFlightEpgRefreshes[providerId];
    if (existing != null) {
      return existing;
    }
    final refresh = _refreshProviderEpg(providerId, onProgress: onProgress);
    _inFlightEpgRefreshes[providerId] = refresh;
    unawaited(
      refresh.whenComplete(() {
        if (identical(_inFlightEpgRefreshes[providerId], refresh)) {
          _inFlightEpgRefreshes.remove(providerId);
        }
      }),
    );
    return refresh;
  }

  Future<void> _refreshProviderEpg(
    String providerId, {
    void Function(String message)? onProgress,
  }) async {
    if (await _providerRepository.hasAnyEpgPrograms(providerId)) {
      return;
    }
    final provider = await _providerRepository.getProvider(providerId);
    if (provider == null || provider.type != ProviderType.xtream) {
      return;
    }
    final serverUrl = provider.serverUrl?.trim();
    final username = provider.username?.trim();
    final password = provider.password?.trim();
    if (serverUrl == null ||
        serverUrl.isEmpty ||
        username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return;
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

    try {
      onProgress?.call('Loading channel schedule');
      final xml = await _loadPlaylistUrl(client.buildXmlTvUri().toString());
      onProgress?.call('Parsing channel schedule');
      final programs = const XmltvParser().parse(
        xml,
        providerId: providerId,
        now: DateTime.now(),
      );
      if (programs.isEmpty) {
        return;
      }
      onProgress?.call('Saving channel schedule');
      await _providerRepository.replaceProviderEpg(
        providerId: providerId,
        programs: programs,
      );
    } catch (_) {
      return;
    }
  }

  Future<ProviderRefreshSummary> refresh(
    IptvProvider provider, {
    void Function(String message)? onProgress,
  }) async {
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

    final refresh = _refresh(provider, onProgress: onProgress);
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

  Future<ProviderRefreshSummary> _refresh(
    IptvProvider provider, {
    void Function(String message)? onProgress,
  }) async {
    final run = await _providerRepository.createRefreshRun(provider.id);
    final startedAt = dateTimeFromMs(run.startedAtMs);

    try {
      final importResult = await _snapshotFor(provider, onProgress: onProgress);
      final itemCount = _snapshotItemCount(importResult.snapshot);
      if (itemCount == 0) {
        throw const ProviderRefreshFailure(
          'Provider did not return any playable items',
        );
      }
      onProgress?.call('Saving catalog');
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
    if (_inFlightEpgRefreshes.isNotEmpty) {
      await Future.wait(_inFlightEpgRefreshes.values);
    }
    if (_inFlightItemDetailRefreshes.isNotEmpty) {
      await Future.wait(_inFlightItemDetailRefreshes.values);
    }
    if (_inFlightSeriesEpisodeRefreshes.isNotEmpty) {
      await Future.wait(_inFlightSeriesEpisodeRefreshes.values);
    }
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  XtreamClient? _xtreamClientForProvider(IptvProvider provider) {
    final serverUrl = provider.serverUrl?.trim();
    final username = provider.username?.trim();
    final password = provider.password?.trim();
    if (serverUrl == null ||
        serverUrl.isEmpty ||
        username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return XtreamClient(
      credentials: XtreamCredentials(
        serverUrl: serverUrl,
        username: username,
        password: password,
      ),
      httpClient: _httpClient,
      timeout: playlistTimeout,
    );
  }

  Future<_ProviderImportResult> _snapshotFor(
    IptvProvider provider, {
    void Function(String message)? onProgress,
  }) {
    if (!provider.canRefresh) {
      throw const ProviderRefreshFailure('Provider details are incomplete');
    }
    return switch (provider.type) {
      ProviderType.xtream => _importXtream(provider, onProgress: onProgress),
      ProviderType.m3uUrl => _importM3uUrl(provider, onProgress: onProgress),
      ProviderType.m3uFile => _importM3uFile(provider, onProgress: onProgress),
    };
  }

  Future<_ProviderImportResult> _importM3uUrl(
    IptvProvider provider, {
    void Function(String message)? onProgress,
  }) async {
    final source = provider.m3uUrl?.trim();
    if (source == null || source.isEmpty) {
      throw const ProviderRefreshFailure('Playlist source is incomplete');
    }
    onProgress?.call('Loading M3U playlist');
    final playlist = await _loadPlaylistUrl(source);
    onProgress?.call('Parsing M3U playlist');
    return _parsePlaylist(provider.id, playlist);
  }

  Future<_ProviderImportResult> _importM3uFile(
    IptvProvider provider, {
    void Function(String message)? onProgress,
  }) async {
    final path = provider.localFilePath?.trim();
    if (path == null || path.isEmpty) {
      throw const ProviderRefreshFailure('Playlist source is incomplete');
    }
    final file = File(path);
    try {
      onProgress?.call('Reading local playlist');
      final length = await file.length();
      if (length > maxPlaylistBytes) {
        throw const ProviderRefreshFailure('Playlist is too large to import');
      }
      final playlist = await file.readAsString();
      onProgress?.call('Parsing M3U playlist');
      return _parsePlaylist(provider.id, playlist);
    } on ProviderRefreshFailure {
      rethrow;
    } on FileSystemException {
      throw const ProviderRefreshFailure(
        'Local playlist file could not be read',
      );
    }
  }

  Future<_ProviderImportResult> _importXtream(
    IptvProvider provider, {
    void Function(String message)? onProgress,
  }) async {
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
    final result = await XtreamImporter(client)
        .importProvider(providerId: provider.id, onProgress: onProgress)
        .onError<XtreamClientException>((error, stackTrace) async {
          if (error.statusCode == null) {
            throw error;
          }
          return _importXtreamGeneratedPlaylist(
            providerId: provider.id,
            client: client,
            originalError: error,
            onProgress: onProgress,
          );
        });
    return _ProviderImportResult(
      snapshot: result.snapshot,
      warningMessage: result.warningMessage,
    );
  }

  Future<XtreamImportResult> _importXtreamGeneratedPlaylist({
    required String providerId,
    required XtreamClient client,
    required XtreamClientException originalError,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Xtream API was rejected; loading generated M3U playlist');
    try {
      final playlist = await _loadPlaylistUrl(
        client.buildM3uPlaylistUri().toString(),
      );
      onProgress?.call('Parsing generated M3U playlist');
      final parsed = _parsePlaylist(providerId, playlist);
      return XtreamImportResult(
        snapshot: parsed.snapshot,
        warningMessage: _combineWarnings(
          'Xtream API was rejected, so Vela imported the generated M3U playlist instead',
          parsed.warningMessage,
        ),
      );
    } on ProviderRefreshFailure catch (fallbackError) {
      throw ProviderRefreshFailure(
        '${originalError.message}. Generated M3U fallback failed: ${fallbackError.message}',
      );
    }
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
          .send(http.Request('GET', uri)..headers.addAll(_playlistHeaders))
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
  final catalogItems = snapshot.items.length;
  final playableEpisodes = snapshot.episodes.where((episode) {
    return _hasPlayableStream(episode.streamUrl, episode.streamJson);
  }).length;
  return catalogItems + playableEpisodes;
}

String _successMessage(int itemCount, String? warningMessage) {
  final base = 'Imported $itemCount items';
  if (warningMessage == null || warningMessage.isEmpty) {
    return base;
  }
  return '$base. $warningMessage';
}

String _combineWarnings(String first, String? second) {
  if (second == null || second.trim().isEmpty) {
    return first;
  }
  return '$first. $second';
}

const _playlistHeaders = {
  'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20',
  'Accept':
      'application/x-mpegURL, application/vnd.apple.mpegurl, text/plain, */*',
};

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
