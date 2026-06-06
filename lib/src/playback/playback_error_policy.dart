import 'playable_item.dart';
import 'player_state.dart';

class PlaybackErrorDecision {
  const PlaybackErrorDecision._({required this.isFatal, required this.message});

  const PlaybackErrorDecision.fatal(String message)
    : this._(isFatal: true, message: message);

  const PlaybackErrorDecision.warning(String message)
    : this._(isFatal: false, message: message);

  final bool isFatal;
  final String message;
}

PlaybackErrorDecision classifyPlaybackError(
  VelaPlayerState state,
  String message,
) {
  final item = state.item;
  if (item == null || item.kind != PlayableKind.live) {
    return PlaybackErrorDecision.fatal(message);
  }

  final playbackStarted =
      state.status == VelaPlaybackStatus.ready ||
      state.playing ||
      state.position > Duration.zero ||
      state.buffer > Duration.zero;
  if (!playbackStarted) {
    return PlaybackErrorDecision.fatal(message);
  }

  return PlaybackErrorDecision.warning(message);
}
