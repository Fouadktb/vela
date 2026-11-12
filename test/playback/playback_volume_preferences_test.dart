import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:vela/src/playback/playback_volume_preferences.dart';
import 'package:vela/src/app/navigation_controller.dart';
import 'package:vela/src/catalog/catalog_database.dart';

void main() {
  test('restores volume before allowing playback to start', () async {
    final diskRead = Completer<String?>();
    final applied = <double>[];
    final session = PlaybackVolumeSession(
      repository: PlaybackVolumePreferencesRepository(
        read: () => diskRead.future,
        write: (_) async {},
      ),
      apply: (volume) async => applied.add(volume),
    );
    expect(applied, isEmpty);
    diskRead.complete(
      const PlaybackVolumePreferences(
        volume: 27,
        lastAudibleVolume: 27,
      ).encode(),
    );
    await session.ready;
    expect(applied, [27]);
  });

  test(
    'restores volume and mute after creating a new player session',
    () async {
      String? stored;
      final repository = PlaybackVolumePreferencesRepository(
        read: () async => stored,
        write: (value) async => stored = value,
      );
      final first = PlaybackVolumeSession(
        repository: repository,
        apply: (_) async {},
      );
      await first.setVolume(34);
      await first.toggleMute();

      // A new repository simulates a complete application restart.
      final applied = <double>[];
      final restarted = PlaybackVolumeSession(
        repository: PlaybackVolumePreferencesRepository(
          read: () async => stored,
          write: (value) async => stored = value,
        ),
        apply: (volume) async => applied.add(volume),
      );
      await restarted.ready;
      expect(applied, [0]);
      await restarted.toggleMute();
      expect(applied, [0, 34]);
      expect(PlaybackVolumePreferences.decode(stored).volume, 34);
    },
  );

  test('rapid slider updates persist in input order', () async {
    String? stored;
    final firstWrite = Completer<void>();
    var writes = 0;
    final applied = <double>[];
    final session = PlaybackVolumeSession(
      repository: PlaybackVolumePreferencesRepository(
        read: () async => stored,
        write: (value) async {
          if (++writes == 1) await firstWrite.future;
          stored = value;
        },
      ),
      apply: (volume) async => applied.add(volume),
    );
    final changes = [session.setVolume(15), session.setVolume(70)];
    await Future<void>.delayed(Duration.zero);
    expect(writes, 1);
    // Slow storage must not delay audible volume changes.
    expect(applied, [100, 15, 70]);
    firstWrite.complete();
    await Future.wait(changes);
    expect(applied, [100, 15, 70]);
    expect(PlaybackVolumePreferences.decode(stored).volume, 70);
  });

  test('a new route waits for pending repository writes', () async {
    String? stored;
    final pendingWrite = Completer<void>();
    final repository = PlaybackVolumePreferencesRepository(
      read: () async => stored,
      write: (value) async {
        await pendingWrite.future;
        stored = value;
      },
    );
    final save = repository.save(
      const PlaybackVolumePreferences(volume: 18, lastAudibleVolume: 18),
    );
    final load = repository.load();
    pendingWrite.complete();
    await save;
    expect((await load).volume, 18);
  });

  test('invalid saved preferences have safe defaults and bounded values', () {
    for (final input in [null, '', 'invalid', '[]', '{"volume":"loud"}']) {
      expect(PlaybackVolumePreferences.decode(input).volume, 100);
    }
    final bounded = PlaybackVolumePreferences.decode(
      '{"volume":200,"lastAudibleVolume":-1}',
    );
    expect(bounded.volume, 100);
    expect(bounded.lastAudibleVolume, 100);
    expect(PlaybackVolumePreferences.decode('{"volume":-4}').volume, 0);
    expect(bounded.withVolume(double.nan).volume, 100);
  });

  test('transient backend startup failure can be retried', () async {
    var attempts = 0;
    final applied = <double>[];
    final session = PlaybackVolumeSession(
      repository: PlaybackVolumePreferencesRepository(
        read: () async => const PlaybackVolumePreferences(
          volume: 29,
          lastAudibleVolume: 29,
        ).encode(),
        write: (_) async {},
      ),
      apply: (volume) async {
        if (++attempts == 1) throw StateError('backend not ready');
        applied.add(volume);
      },
    );
    await expectLater(session.ready, throwsStateError);
    await session.prepareForPlayback();
    expect(applied, [29]);
    await session.setVolume(42);
    expect(applied, [29, 42]);
  });

  test('real SQLite settings survive database and provider reopen', () async {
    final directory = await Directory.systemTemp.createTemp('vela-volume-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/catalog.sqlite');

    Future<void> withDatabase(
      Future<void> Function(ProviderContainer) action,
    ) async {
      final database = CatalogDatabase(NativeDatabase(file));
      final container = ProviderContainer(
        overrides: [catalogDatabaseProvider.overrideWithValue(database)],
      );
      try {
        await action(container);
      } finally {
        container.dispose();
        await database.close();
      }
    }

    await withDatabase((container) async {
      await container
          .read(appSettingsRepositoryProvider)
          .setValue('language', 'de');
      final session = PlaybackVolumeSession(
        repository: container.read(playbackVolumePreferencesProvider),
        apply: (_) async {},
      );
      await session.setVolume(31);
      await session.toggleMute();
      await session.flush();
    });

    await withDatabase((container) async {
      final applied = <double>[];
      final session = PlaybackVolumeSession(
        repository: container.read(playbackVolumePreferencesProvider),
        apply: (volume) async => applied.add(volume),
      );
      await session.ready;
      expect(applied, [0]);
      await session.toggleMute();
      expect(applied, [0, 31]);
      final settings = await container
          .read(appSettingsRepositoryProvider)
          .watchSettings()
          .first;
      expect(settings['language'], 'de');
      expect(
        PlaybackVolumePreferences.decode(
          settings[PlaybackVolumePreferencesRepository.settingsKey],
        ).volume,
        31,
      );
    });
  });

  test('a failed write does not block subsequent volume changes', () async {
    String? stored;
    var writes = 0;
    final session = PlaybackVolumeSession(
      repository: PlaybackVolumePreferencesRepository(
        read: () async => stored,
        write: (value) async {
          if (++writes == 1) throw StateError('temporary write failure');
          stored = value;
        },
      ),
      apply: (_) async {},
    );
    await session.setVolume(20);
    await session.setVolume(45);
    expect(PlaybackVolumePreferences.decode(stored).volume, 45);
  });
}
