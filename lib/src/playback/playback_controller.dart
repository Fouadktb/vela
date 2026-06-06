import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart';

import '../platform/vela_windowing.dart';
import 'playable_item.dart';
import 'player_state.dart';
import 'playback_error_policy.dart';
import 'track_models.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController() {
    _player = media_kit.Player(
      configuration: const media_kit.PlayerConfiguration(
        title: 'Vela',
        bufferSize: 128 * 1024 * 1024,
      ),
    );
    videoController = VideoController(_player);
    _tracks = _player.state.tracks;
    _selectedTrack = _player.state.track;
    _state = _state.copyWith(
      volume: _player.state.volume,
      playbackSpeed: _player.state.rate,
      buffering: _player.state.buffering,
      buffer: _player.state.buffer,
      bufferingPercentage: _player.state.bufferingPercentage,
      playing: _player.state.playing,
      duration: _player.state.duration,
      position: _player.state.position,
    );
    _syncTrackModels(notify: false);
    _bindPlayerStreams();
    _syncFullscreen();
  }

  late final media_kit.Player _player;
  late final VideoController videoController;
  late VelaPlayerState _state = const VelaPlayerState();
  late media_kit.Tracks _tracks;
  late media_kit.Track _selectedTrack;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _stalledTimer;
  DateTime? _lastTimelineNotifiedAt;
  Duration _lastNotifiedPosition = Duration.zero;
  Duration _lastNotifiedBuffer = Duration.zero;
  Duration _stallStartPosition = Duration.zero;
  Duration _stallStartBuffer = Duration.zero;
  double _lastAudibleVolume = 100;
  String? _dismissedPlaybackWarningMessage;
  bool _disposed = false;
  final VelaFullscreenController _fullscreenController =
      VelaFullscreenController();

  VelaPlayerState get state => _state;

  Future<void> open(PlayableItem item) async {
    _cancelStalledTimer();
    _dismissedPlaybackWarningMessage = null;
    _emit(
      _state.copyWith(
        item: item,
        status: VelaPlaybackStatus.opening,
        position: Duration.zero,
        duration: Duration.zero,
        buffer: Duration.zero,
        bufferingPercentage: 0,
        completed: false,
        errorMessage: null,
        playbackWarningMessage: null,
        audioTracks: const [],
        subtitleTracks: const [],
        videoTracks: const [],
      ),
    );

    try {
      await _player.open(
        media_kit.Media(item.streamUrl, httpHeaders: _mediaHttpHeaders),
        play: true,
      );
      if (item.kind != PlayableKind.live &&
          item.resumePosition > Duration.zero) {
        await _player.seek(item.resumePosition);
      }
      _emit(
        _state.copyWith(
          status: VelaPlaybackStatus.ready,
          playing: true,
          completed: false,
          errorMessage: null,
          playbackWarningMessage: null,
        ),
      );
    } catch (error) {
      _cancelStalledTimer();
      _emit(
        _state.copyWith(
          status: VelaPlaybackStatus.error,
          playing: false,
          errorMessage: error.toString(),
          playbackWarningMessage: null,
        ),
      );
    }
  }

  void clearPlaybackWarning() {
    if (_state.playbackWarningMessage == null) return;
    _dismissedPlaybackWarningMessage = _state.playbackWarningMessage;
    _emit(_state.copyWith(playbackWarningMessage: null));
  }

  Future<void> togglePlayPause() => _player.playOrPause();

  Future<void> seekRelative(Duration offset) {
    if (!_state.isSeekable) return Future<void>.value();
    return seekTo(_state.position + offset);
  }

  Future<void> seekTo(Duration position) {
    if (!_state.isSeekable) return Future<void>.value();
    final duration = _state.duration;
    final target = Duration(
      milliseconds: math.max(
        0,
        math.min(position.inMilliseconds, duration.inMilliseconds),
      ),
    );
    return _player.seek(target);
  }

  Future<void> setVolume(double volume) async {
    final next = volume.clamp(0, 100).toDouble();
    if (next > 0) {
      _lastAudibleVolume = next;
    }
    await _player.setVolume(next);
    _emit(_state.copyWith(volume: next, isMuted: next == 0));
  }

  Future<void> toggleMute() {
    if (_state.isMuted || _state.volume == 0) {
      return setVolume(_lastAudibleVolume <= 0 ? 80 : _lastAudibleVolume);
    }
    _lastAudibleVolume = _state.volume;
    return setVolume(0);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _player.setRate(speed);
    _emit(_state.copyWith(playbackSpeed: speed));
  }

  Future<void> selectAudioTrack(String id) async {
    final track = _tracks.audio.where((track) => track.id == id).firstOrNull;
    if (track == null) return;
    await _player.setAudioTrack(track);
  }

  Future<void> selectSubtitleTrack(String id) async {
    final track = _tracks.subtitle.where((track) => track.id == id).firstOrNull;
    await _player.setSubtitleTrack(track ?? media_kit.SubtitleTrack.no());
  }

  Future<void> turnSubtitlesOff() {
    return _player.setSubtitleTrack(media_kit.SubtitleTrack.no());
  }

  Future<void> selectVideoTrack(String id) async {
    final track = _tracks.video.where((track) => track.id == id).firstOrNull;
    if (track == null) return;
    await _player.setVideoTrack(track);
  }

  Future<void> toggleFullscreen() async {
    await _fullscreenController.toggleFullscreen();
    _emit(_state.copyWith(isFullscreen: _fullscreenController.isFullscreen));
  }

  Future<void> exitFullscreenIfNeeded() async {
    await _fullscreenController.exitFullscreenIfNeeded();
    _emit(_state.copyWith(isFullscreen: _fullscreenController.isFullscreen));
  }

  Future<void> stop() async {
    _cancelStalledTimer();
    _dismissedPlaybackWarningMessage = null;
    await _player.stop();
    _emit(
      _state.copyWith(
        status: VelaPlaybackStatus.idle,
        playing: false,
        buffering: false,
        completed: false,
        position: Duration.zero,
        duration: Duration.zero,
        buffer: Duration.zero,
        bufferingPercentage: 0,
        errorMessage: null,
        playbackWarningMessage: null,
        audioTracks: const [],
        subtitleTracks: const [],
        videoTracks: const [],
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _cancelStalledTimer();
    _player.dispose();
    super.dispose();
  }

  void _bindPlayerStreams() {
    _subscriptions
      ..add(
        _player.stream.position.listen((value) {
          _handlePositionChanged(value);
        }),
      )
      ..add(
        _player.stream.duration.listen((value) {
          _emit(_state.copyWith(duration: value));
        }),
      )
      ..add(
        _player.stream.buffer.listen((value) {
          _handleBufferChanged(value);
        }),
      )
      ..add(
        _player.stream.bufferingPercentage.listen((value) {
          _emitTimeline(
            _state.copyWith(bufferingPercentage: value.clamp(0, 100)),
          );
        }),
      )
      ..add(
        _player.stream.buffering.listen((value) {
          _handleBufferingChanged(value);
        }),
      )
      ..add(
        _player.stream.playing.listen((value) {
          _handlePlayingChanged(value);
        }),
      )
      ..add(
        _player.stream.completed.listen((value) {
          if (!value) {
            _emit(_state.copyWith(completed: false));
            return;
          }
          _cancelStalledTimer();
          _emit(
            _state.copyWith(
              completed: true,
              playing: false,
              status: VelaPlaybackStatus.completed,
            ),
          );
        }),
      )
      ..add(
        _player.stream.error.listen((value) {
          _handlePlayerError(value);
        }),
      )
      ..add(
        _player.stream.volume.listen((value) {
          if (value > 0) {
            _lastAudibleVolume = value;
          }
          _emit(_state.copyWith(volume: value, isMuted: value == 0));
        }),
      )
      ..add(
        _player.stream.rate.listen((value) {
          _emit(_state.copyWith(playbackSpeed: value));
        }),
      )
      ..add(
        _player.stream.tracks.listen((value) {
          _tracks = value;
          _syncTrackModels();
        }),
      )
      ..add(
        _player.stream.track.listen((value) {
          _selectedTrack = value;
          _syncTrackModels();
        }),
      );
  }

  Future<void> _syncFullscreen() async {
    final isFullscreen = await _fullscreenController.refreshFullscreenState();
    if (_disposed) return;
    _emit(_state.copyWith(isFullscreen: isFullscreen));
  }

  void _handlePositionChanged(Duration value) {
    final progressed = value > _state.position;
    _emitTimeline(_state.copyWith(position: value));
    if (!progressed) return;

    _clearStalledStatus();
    if (_state.buffering) {
      _startStalledTimer();
    }
  }

  void _handleBufferChanged(Duration value) {
    final progressed = value > _state.buffer;
    _emitTimeline(_state.copyWith(buffer: value));
    if (progressed && _state.buffering) {
      _startStalledTimer();
    }
  }

  void _handleBufferingChanged(bool value) {
    _emit(_state.copyWith(buffering: value));
    if (value) {
      _startStalledTimer();
      return;
    }

    _cancelStalledTimer();
    _clearStalledStatus();
  }

  void _handlePlayingChanged(bool value) {
    if (value) {
      _cancelStalledTimer();
      final status =
          _state.status == VelaPlaybackStatus.opening ||
              _state.status == VelaPlaybackStatus.stalled
          ? VelaPlaybackStatus.ready
          : _state.status;
      final next = _state.copyWith(playing: true, status: status);
      _emit(
        status == VelaPlaybackStatus.ready
            ? next.copyWith(errorMessage: null)
            : next,
      );
      return;
    }

    _emit(_state.copyWith(playing: false));
    if (_state.buffering) {
      _startStalledTimer();
    }
  }

  void _handlePlayerError(String value) {
    final decision = classifyPlaybackError(_state, value);
    if (decision.isFatal) {
      _cancelStalledTimer();
      _dismissedPlaybackWarningMessage = null;
      _emit(
        _state.copyWith(
          status: VelaPlaybackStatus.error,
          playing: false,
          errorMessage: decision.message,
          playbackWarningMessage: null,
        ),
      );
      return;
    }

    if (_dismissedPlaybackWarningMessage == decision.message) {
      return;
    }
    if (_state.playbackWarningMessage != decision.message) {
      _dismissedPlaybackWarningMessage = null;
    }
    final nextStatus =
        _state.status == VelaPlaybackStatus.opening ||
            _state.status == VelaPlaybackStatus.error
        ? VelaPlaybackStatus.ready
        : _state.status;
    if (_state.status == nextStatus &&
        _state.errorMessage == null &&
        _state.playbackWarningMessage == decision.message) {
      return;
    }
    _emit(
      _state.copyWith(
        status: nextStatus,
        errorMessage: null,
        playbackWarningMessage: decision.message,
      ),
    );
  }

  void _startStalledTimer() {
    _cancelStalledTimer();
    if (_state.status == VelaPlaybackStatus.idle ||
        _state.status == VelaPlaybackStatus.completed ||
        _state.status == VelaPlaybackStatus.error) {
      return;
    }

    _stallStartPosition = _state.position;
    _stallStartBuffer = _state.buffer;
    _stalledTimer = Timer(const Duration(seconds: 12), () {
      if (_disposed || !_state.buffering || _state.playing) return;
      if (_state.status == VelaPlaybackStatus.idle ||
          _state.status == VelaPlaybackStatus.completed ||
          _state.status == VelaPlaybackStatus.error) {
        return;
      }
      if (_state.position > _stallStartPosition ||
          _state.buffer > _stallStartBuffer) {
        return;
      }
      _emit(
        _state.copyWith(
          status: VelaPlaybackStatus.stalled,
          errorMessage: 'The stream stopped receiving data.',
        ),
      );
    });
  }

  void _cancelStalledTimer() {
    _stalledTimer?.cancel();
    _stalledTimer = null;
  }

  void _clearStalledStatus() {
    if (_state.status != VelaPlaybackStatus.stalled) return;
    _emit(
      _state.copyWith(status: VelaPlaybackStatus.ready, errorMessage: null),
    );
  }

  void _syncTrackModels({bool notify = true}) {
    final audio = _tracks.audio
        .map((track) {
          return PlaybackAudioTrack(
            id: track.id,
            title: _trackTitle(track.id, track.title, 'Audio'),
            language: track.language,
            isSelected: track == _selectedTrack.audio,
            isExternal: track.uri,
          );
        })
        .toList(growable: false);

    final subtitles = _tracks.subtitle
        .map((track) {
          return PlaybackSubtitleTrack(
            id: track.id,
            title: _trackTitle(track.id, track.title, 'Subtitles'),
            language: track.language,
            isSelected: track == _selectedTrack.subtitle,
            isExternal: track.uri || track.data,
          );
        })
        .toList(growable: false);

    final video = _tracks.video
        .map((track) {
          return PlaybackVideoTrack(
            id: track.id,
            title: _trackTitle(track.id, track.title, 'Video'),
            language: track.language,
            isSelected: track == _selectedTrack.video,
            isExternal: false,
          );
        })
        .toList(growable: false);

    _state = _state.copyWith(
      audioTracks: audio,
      subtitleTracks: subtitles,
      videoTracks: video,
    );
    if (notify) notifyListeners();
  }

  String _trackTitle(String id, String? title, String fallback) {
    if (id == 'auto') return 'Auto';
    if (id == 'no') return 'Off';
    if (title != null && title.trim().isNotEmpty) return title.trim();
    return '$fallback $id';
  }

  void _emit(VelaPlayerState next) {
    if (_disposed) return;
    _state = next;
    _lastTimelineNotifiedAt = DateTime.now();
    _lastNotifiedPosition = next.position;
    _lastNotifiedBuffer = next.buffer;
    notifyListeners();
  }

  void _emitTimeline(VelaPlayerState next) {
    if (_disposed) return;
    _state = next;
    final now = DateTime.now();
    final elapsed = _lastTimelineNotifiedAt == null
        ? const Duration(seconds: 1)
        : now.difference(_lastTimelineNotifiedAt!);
    final positionDelta = (next.position - _lastNotifiedPosition).abs();
    final bufferDelta = (next.buffer - _lastNotifiedBuffer).abs();
    if (elapsed < const Duration(milliseconds: 350) &&
        positionDelta < const Duration(seconds: 1) &&
        bufferDelta < const Duration(seconds: 5)) {
      return;
    }
    _lastTimelineNotifiedAt = now;
    _lastNotifiedPosition = next.position;
    _lastNotifiedBuffer = next.buffer;
    notifyListeners();
  }
}

const _mediaHttpHeaders = {
  'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20',
  'Accept':
      'video/*, audio/*, application/vnd.apple.mpegurl, application/x-mpegURL, */*',
};

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
