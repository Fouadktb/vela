import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../app/app_version.dart';
import '../catalog/catalog_repository.dart';
import '../catalog/watch_history_repository.dart';
import '../updates/update_checker.dart';

class DiagnosticsExporter {
  const DiagnosticsExporter({
    required CatalogRepository catalogRepository,
    required WatchHistoryRepository watchHistoryRepository,
  }) : _catalogRepository = catalogRepository,
       _watchHistoryRepository = watchHistoryRepository;

  final CatalogRepository _catalogRepository;
  final WatchHistoryRepository _watchHistoryRepository;

  Future<String?> export({
    Map<String, String>? appSettings,
    UpdateStatus? updateStatus,
    Object? updateError,
    bool updateLoading = false,
  }) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Text',
          extensions: ['txt'],
          mimeTypes: ['text/plain'],
        ),
      ],
      suggestedName: 'vela-diagnostics-${_fileTimestamp()}.txt',
      confirmButtonText: 'Export',
    );
    if (location == null) {
      return null;
    }

    final content = await _buildDiagnostics(
      appSettings: appSettings,
      updateStatus: updateStatus,
      updateError: updateError,
      updateLoading: updateLoading,
    );
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(content)),
      mimeType: 'text/plain',
      name: 'vela-diagnostics.txt',
    );
    await file.saveTo(location.path);
    return location.path;
  }

  Future<String> _buildDiagnostics({
    required Map<String, String>? appSettings,
    required UpdateStatus? updateStatus,
    required Object? updateError,
    required bool updateLoading,
  }) async {
    final buffer = StringBuffer()
      ..writeln('Vela diagnostics')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('App: $velaVersion ($velaBuildNumber)')
      ..writeln('Platform: ${defaultTargetPlatform.name}')
      ..writeln();

    await _writeProviderSummaries(buffer);
    await _writeRefreshRuns(buffer);
    await _writeCatalogCounts(buffer);
    await _writeRecentlyWatchedCount(buffer);
    _writePlaybackPreferences(buffer, appSettings);
    _writeUpdateStatus(
      buffer,
      updateStatus: updateStatus,
      updateError: updateError,
      updateLoading: updateLoading,
    );

    return buffer.toString();
  }

  Future<void> _writeProviderSummaries(StringBuffer buffer) async {
    buffer.writeln('Provider summaries');
    try {
      final providers = await _catalogRepository.listProviders();
      if (providers.isEmpty) {
        buffer.writeln('- No providers configured');
      }
      for (final provider in providers) {
        final stats = await _catalogRepository.providerCatalogStats(
          provider.id,
        );
        buffer
          ..writeln('- ${_redact(provider.name)}')
          ..writeln('  id: ${provider.id}')
          ..writeln('  type: ${provider.type.name}')
          ..writeln('  source kind: ${provider.sourceKind ?? 'unavailable'}')
          ..writeln('  source: <redacted>')
          ..writeln('  username: ${_configured(provider.username)}')
          ..writeln('  password: ${_configured(provider.password)}')
          ..writeln('  enabled: ${provider.isEnabled}')
          ..writeln('  auto refresh: ${provider.autoRefreshEnabled}')
          ..writeln(
            '  auto refresh interval minutes: '
            '${provider.autoRefreshIntervalMinutes}',
          )
          ..writeln('  last refresh: ${_formatMs(provider.lastRefreshAtMs)}')
          ..writeln(
            '  counts: live=${stats.liveCount}, movies=${stats.movieCount}, '
            'series=${stats.seriesCount}, episodes=${stats.episodeCount}, '
            'epg=${stats.epgProgramCount}',
          );
      }
    } catch (error) {
      buffer.writeln('- unavailable: ${_redact(error.toString())}');
    }
    buffer.writeln();
  }

  Future<void> _writeRefreshRuns(StringBuffer buffer) async {
    buffer.writeln('Latest refresh runs');
    try {
      final runs = await _catalogRepository.listLatestRefreshRuns();
      if (runs.isEmpty) {
        buffer.writeln('- unavailable: no refresh runs recorded');
      }
      for (final run in runs) {
        buffer
          ..writeln('- ${run.id}')
          ..writeln('  provider id: ${run.providerId}')
          ..writeln('  status: ${run.status.name}')
          ..writeln('  started: ${_formatMs(run.startedAtMs)}')
          ..writeln('  finished: ${_formatMs(run.finishedAtMs)}')
          ..writeln('  item count: ${run.itemCount}')
          ..writeln(
            '  message: '
            '${run.errorMessage == null ? 'unavailable' : _redact(run.errorMessage!)}',
          );
      }
    } catch (error) {
      buffer.writeln('- unavailable: ${_redact(error.toString())}');
    }
    buffer.writeln();
  }

  Future<void> _writeCatalogCounts(StringBuffer buffer) async {
    buffer.writeln('Catalog counts');
    try {
      final stats = await _catalogRepository.catalogStats();
      buffer
        ..writeln('- live: ${stats.liveCount}')
        ..writeln('- movies: ${stats.movieCount}')
        ..writeln('- series: ${stats.seriesCount}')
        ..writeln('- episodes: ${stats.episodeCount}')
        ..writeln('- epg programs: ${stats.epgProgramCount}');
    } catch (error) {
      buffer.writeln('- unavailable: ${_redact(error.toString())}');
    }
    buffer.writeln();
  }

  Future<void> _writeRecentlyWatchedCount(StringBuffer buffer) async {
    buffer.writeln('Recently watched');
    try {
      final count = await _watchHistoryRepository.recentlyWatchedCount();
      buffer.writeln('- entries: $count');
    } catch (error) {
      buffer.writeln('- unavailable: ${_redact(error.toString())}');
    }
    buffer.writeln();
  }

  void _writePlaybackPreferences(
    StringBuffer buffer,
    Map<String, String>? appSettings,
  ) {
    buffer.writeln('Playback preferences');
    if (appSettings == null) {
      buffer
        ..writeln('- unavailable: settings have not loaded')
        ..writeln();
      return;
    }
    buffer
      ..writeln(
        '- default audio: ${_redact(appSettings['default_audio'] ?? 'Auto')}',
      )
      ..writeln(
        '- default subtitles: '
        '${_redact(appSettings['default_subtitles'] ?? 'Off')}',
      )
      ..writeln();
  }

  void _writeUpdateStatus(
    StringBuffer buffer, {
    required UpdateStatus? updateStatus,
    required Object? updateError,
    required bool updateLoading,
  }) {
    buffer.writeln('Update status');
    if (updateLoading) {
      buffer
        ..writeln('- unavailable: update check is still running')
        ..writeln();
      return;
    }
    if (updateError != null) {
      buffer
        ..writeln('- unavailable: ${_redact(updateError.toString())}')
        ..writeln();
      return;
    }
    if (updateStatus == null) {
      buffer
        ..writeln('- unavailable: update check has not run')
        ..writeln();
      return;
    }
    buffer
      ..writeln('- current version: ${updateStatus.currentVersion}')
      ..writeln('- latest version: ${updateStatus.latestVersion}')
      ..writeln('- has update: ${updateStatus.hasUpdate}')
      ..writeln('- checked at: ${updateStatus.checkedAt.toIso8601String()}')
      ..writeln('- release URL: ${_redact(updateStatus.releaseUrl)}')
      ..writeln();
  }
}

String _configured(String? value) {
  return value?.trim().isNotEmpty == true ? '<configured>' : 'not configured';
}

String _formatMs(int? value) {
  if (value == null) {
    return 'unavailable';
  }
  return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
}

String _fileTimestamp() {
  return DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
}

String _redact(String value) {
  var redacted = value.replaceAll(
    RegExp(r'https?://[^\s)\]}",]+', caseSensitive: false),
    '<redacted-url>',
  );
  redacted = redacted.replaceAllMapped(
    RegExp(
      r'([?&](?:username|user|password|pass|token|key|url|source)=)[^&\s]+',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}<redacted>',
  );
  redacted = redacted.replaceAllMapped(
    RegExp(
      r'\b(username|user|password|pass|token|secret|source|playlist|url)\s*[:=]\s*[^\s,;]+',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}=<redacted>',
  );
  return redacted;
}
