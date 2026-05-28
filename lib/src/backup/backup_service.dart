import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';

import '../catalog/catalog_repository.dart';
import '../catalog/watch_history_repository.dart';

class BackupService {
  const BackupService({
    required CatalogRepository catalogRepository,
    required WatchHistoryRepository watchHistoryRepository,
  }) : _catalogRepository = catalogRepository,
       _watchHistoryRepository = watchHistoryRepository;

  final CatalogRepository _catalogRepository;
  final WatchHistoryRepository _watchHistoryRepository;

  Future<String?> export({Map<String, String>? appSettings}) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'JSON',
          extensions: ['json'],
          mimeTypes: ['application/json'],
        ),
      ],
      suggestedName: 'vela-backup-${_fileTimestamp()}.json',
      confirmButtonText: 'Export',
    );
    if (location == null) {
      return null;
    }

    final data = await _buildBackup(appSettings: appSettings);
    final content = const JsonEncoder.withIndent('  ').convert(data);
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(content)),
      mimeType: 'application/json',
      name: 'vela-backup.json',
    );
    await file.saveTo(location.path);
    return location.path;
  }

  Future<Map<String, Object?>> _buildBackup({
    required Map<String, String>? appSettings,
  }) async {
    return {
      'schema_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'providers': await _catalogRepository.exportProviderMetadata(),
      'favorites': {
        'items': await _catalogRepository.exportFavoriteItems(),
        'categories': await _catalogRepository.exportFavoriteCategories(),
      },
      'category_order': await _catalogRepository.exportCategoryOrder(),
      'watch_history': await _watchHistoryRepository.exportWatchHistory(),
      'playback_positions': await _watchHistoryRepository
          .exportPlaybackPositions(),
      'playback_preferences': _playbackPreferences(appSettings),
      'app_settings': _safeSettings(appSettings),
    };
  }
}

Map<String, String>? _playbackPreferences(Map<String, String>? appSettings) {
  if (appSettings == null) {
    return null;
  }
  return {
    'default_audio': appSettings['default_audio'] ?? 'Auto',
    'default_subtitles': appSettings['default_subtitles'] ?? 'Off',
  };
}

Map<String, Object?>? _safeSettings(Map<String, String>? appSettings) {
  if (appSettings == null) {
    return null;
  }

  final redactedKeys = <String>[];
  final values = <String, String>{};
  for (final entry in appSettings.entries) {
    if (_looksSecret(entry.key) || _looksLikeUrl(entry.value)) {
      redactedKeys.add(entry.key);
      continue;
    }
    values[entry.key] = entry.value;
  }

  return {
    'values': values,
    if (redactedKeys.isNotEmpty) 'redacted_keys': redactedKeys,
  };
}

bool _looksSecret(String key) {
  return RegExp(
    r'(user|username|password|pass|token|secret|source|playlist|url|key)',
    caseSensitive: false,
  ).hasMatch(key);
}

bool _looksLikeUrl(String value) {
  return RegExp(r'https?://', caseSensitive: false).hasMatch(value);
}

String _fileTimestamp() {
  return DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
}
