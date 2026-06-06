import 'playable_item.dart';
import 'track_models.dart';

enum VelaPlaybackStatus { idle, opening, ready, completed, error, stalled }

class VelaPlayerState {
  const VelaPlayerState({
    this.item,
    this.status = VelaPlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = Duration.zero,
    this.bufferingPercentage = 0,
    this.buffering = false,
    this.playing = false,
    this.completed = false,
    this.errorMessage,
    this.playbackWarningMessage,
    this.volume = 100,
    this.isMuted = false,
    this.playbackSpeed = 1,
    this.isFullscreen = false,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
    this.videoTracks = const [],
  });

  final PlayableItem? item;
  final VelaPlaybackStatus status;
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final double bufferingPercentage;
  final bool buffering;
  final bool playing;
  final bool completed;
  final String? errorMessage;
  final String? playbackWarningMessage;
  final double volume;
  final bool isMuted;
  final double playbackSpeed;
  final bool isFullscreen;
  final List<PlaybackAudioTrack> audioTracks;
  final List<PlaybackSubtitleTrack> subtitleTracks;
  final List<PlaybackVideoTrack> videoTracks;

  bool get hasMedia => item != null;
  bool get canRetry =>
      item != null &&
      (status == VelaPlaybackStatus.error ||
          status == VelaPlaybackStatus.stalled);
  bool get isLive => item?.kind == PlayableKind.live;
  bool get isSeekable {
    final currentItem = item;
    if (currentItem == null || currentItem.kind == PlayableKind.live) {
      return false;
    }
    return duration > Duration.zero;
  }

  VelaPlayerState copyWith({
    PlayableItem? item,
    VelaPlaybackStatus? status,
    Duration? position,
    Duration? duration,
    Duration? buffer,
    double? bufferingPercentage,
    bool? buffering,
    bool? playing,
    bool? completed,
    Object? errorMessage = _unchanged,
    Object? playbackWarningMessage = _unchanged,
    double? volume,
    bool? isMuted,
    double? playbackSpeed,
    bool? isFullscreen,
    List<PlaybackAudioTrack>? audioTracks,
    List<PlaybackSubtitleTrack>? subtitleTracks,
    List<PlaybackVideoTrack>? videoTracks,
  }) {
    return VelaPlayerState(
      item: item ?? this.item,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffer: buffer ?? this.buffer,
      bufferingPercentage: bufferingPercentage ?? this.bufferingPercentage,
      buffering: buffering ?? this.buffering,
      playing: playing ?? this.playing,
      completed: completed ?? this.completed,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
      playbackWarningMessage: identical(playbackWarningMessage, _unchanged)
          ? this.playbackWarningMessage
          : playbackWarningMessage as String?,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      audioTracks: audioTracks ?? this.audioTracks,
      subtitleTracks: subtitleTracks ?? this.subtitleTracks,
      videoTracks: videoTracks ?? this.videoTracks,
    );
  }
}

const Object _unchanged = Object();
