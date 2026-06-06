import 'package:flutter_test/flutter_test.dart';
import 'package:vela/src/playback/playable_item.dart';
import 'package:vela/src/playback/playback_error_policy.dart';
import 'package:vela/src/playback/player_state.dart';

void main() {
  group('classifyPlaybackError', () {
    test(
      'treats live errors after playback starts as non-blocking warnings',
      () {
        final decision = classifyPlaybackError(
          VelaPlayerState(
            item: _item(PlayableKind.live),
            status: VelaPlaybackStatus.ready,
            playing: true,
            position: const Duration(seconds: 4),
          ),
          'decoder recovered after distortion',
        );

        expect(decision.isFatal, isFalse);
        expect(decision.message, 'decoder recovered after distortion');
      },
    );

    test('keeps live open failures fatal before playback starts', () {
      final decision = classifyPlaybackError(
        VelaPlayerState(
          item: _item(PlayableKind.live),
          status: VelaPlaybackStatus.opening,
        ),
        'could not connect',
      );

      expect(decision.isFatal, isTrue);
      expect(decision.message, 'could not connect');
    });

    test('keeps on-demand playback errors fatal', () {
      final decision = classifyPlaybackError(
        VelaPlayerState(
          item: _item(PlayableKind.movie),
          status: VelaPlaybackStatus.ready,
          playing: true,
          position: const Duration(minutes: 12),
        ),
        'media source failed',
      );

      expect(decision.isFatal, isTrue);
      expect(decision.message, 'media source failed');
    });
  });
}

PlayableItem _item(PlayableKind kind) {
  return PlayableItem(
    id: 'item-${kind.name}',
    providerId: 'provider-1',
    title: 'Test item',
    streamUrl: 'https://example.test/stream.m3u8',
    kind: kind,
  );
}
