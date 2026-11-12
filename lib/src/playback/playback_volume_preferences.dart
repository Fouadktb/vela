import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigation_controller.dart';

final playbackVolumePreferencesProvider =
    Provider<PlaybackVolumePreferencesRepository>((ref) {
      final settings = ref.watch(appSettingsRepositoryProvider);
      return PlaybackVolumePreferencesRepository(
        read: () async => (await settings
            .watchSettings()
            .first)[PlaybackVolumePreferencesRepository.settingsKey],
        write: (value) => settings.setValue(
          PlaybackVolumePreferencesRepository.settingsKey,
          value,
        ),
      );
    });

/// Global output preferences, shared by every channel and episode.
class PlaybackVolumePreferences {
  const PlaybackVolumePreferences({
    this.volume = 100,
    this.lastAudibleVolume = 100,
  });

  final double volume;
  final double lastAudibleVolume;

  factory PlaybackVolumePreferences.decode(String? raw) {
    if (raw == null) return const PlaybackVolumePreferences();
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return const PlaybackVolumePreferences();
      final volume = value['volume'];
      final audible = value['lastAudibleVolume'];
      return PlaybackVolumePreferences(
        volume: volume is num && volume.isFinite
            ? volume.toDouble().clamp(0, 100).toDouble()
            : 100,
        lastAudibleVolume: audible is num && audible.isFinite && audible > 0
            ? audible.toDouble().clamp(0, 100).toDouble()
            : 100,
      );
    } on FormatException {
      return const PlaybackVolumePreferences();
    }
  }

  String encode() =>
      jsonEncode({'volume': volume, 'lastAudibleVolume': lastAudibleVolume});

  PlaybackVolumePreferences withVolume(double next) {
    if (!next.isFinite) return this;
    final bounded = next.clamp(0, 100).toDouble();
    return PlaybackVolumePreferences(
      volume: bounded,
      lastAudibleVolume: bounded > 0 ? bounded : lastAudibleVolume,
    );
  }

  PlaybackVolumePreferences toggleMute() =>
      withVolume(volume == 0 ? lastAudibleVolume : 0);
}

/// Serializes disk writes across route lifetimes so a slow earlier write cannot
/// overwrite the most recent slider value.
class PlaybackVolumePreferencesRepository {
  PlaybackVolumePreferencesRepository({
    required Future<String?> Function() read,
    required Future<void> Function(String) write,
  }) : _read = read,
       _write = write;

  static const settingsKey = 'playback_output_volume';
  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  Future<void> _queue = Future<void>.value();

  Future<PlaybackVolumePreferences> load() async {
    await _queue;
    return PlaybackVolumePreferences.decode(await _read());
  }

  Future<void> flush() => _queue;

  Future<void> save(PlaybackVolumePreferences preferences) {
    final operation = _queue.then((_) => _write(preferences.encode()));
    // A failed write must not poison subsequent writes or reads.
    _queue = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }
}

/// Orders restoration, player updates and persistence without depending on a
/// particular media backend. Restoration finishes before media can be opened.
class PlaybackVolumeSession {
  PlaybackVolumeSession({
    required PlaybackVolumePreferencesRepository repository,
    required Future<void> Function(double) apply,
  }) : _repository = repository,
       _apply = apply {
    ready = _restore();
    _queue = ready.then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  final PlaybackVolumePreferencesRepository _repository;
  final Future<void> Function(double) _apply;
  PlaybackVolumePreferences _preferences = const PlaybackVolumePreferences();
  late final Future<void> ready;
  late Future<void> _queue;

  Future<void> _restore() async {
    try {
      _preferences = await _repository.load();
    } catch (error) {
      debugPrint('Failed to restore playback volume: $error');
    }
    await _apply(_preferences.volume);
  }

  Future<void> setVolume(double volume) =>
      _update((current) => current.withVolume(volume));

  Future<void> toggleMute() => _update((current) => current.toggleMute());

  Future<void> prepareForPlayback() async {
    try {
      await ready;
    } catch (_) {
      // A transient backend initialization failure must not poison every retry.
      await _apply(_preferences.volume);
    }
    await _queue;
  }

  Future<void> flush() async {
    await _queue;
    await _repository.flush();
  }

  Future<void> _save(PlaybackVolumePreferences preferences) async {
    try {
      await _repository.save(preferences);
    } catch (error) {
      debugPrint('Failed to save playback volume: $error');
    }
  }

  Future<void> _update(
    PlaybackVolumePreferences Function(PlaybackVolumePreferences) update,
  ) {
    Future<void> persisted = Future<void>.value();
    final operation = _queue.then((_) async {
      _preferences = update(_preferences);
      try {
        await _apply(_preferences.volume);
      } finally {
        // Persist the user's choice even if the media backend is shutting down.
        // Audio updates do not wait on disk. The repository still orders writes.
        persisted = _save(_preferences);
      }
    });
    _queue = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation.then((_) => persisted);
  }
}
