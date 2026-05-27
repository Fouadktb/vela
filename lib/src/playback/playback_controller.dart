import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' as media_kit;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import 'playable_item.dart';
import 'player_state.dart';
import 'track_models.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController() {
    _player = media_kit.Player();
    videoController = VideoController(_player);
    _tracks = _player.state.tracks;
    _selectedTrack = _player.state.track;
    _state = _state.copyWith(
      volume: _player.state.volume,
      playbackSpeed: _player.state.rate,
      buffering: _player.state.buffering,
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
  double _lastAudibleVolume = 100;
  bool _disposed = false;

  VelaPlayerState get state => _state;

  Future<void> open(PlayableItem item) async {
    _emit(
      _state.copyWith(
        item: item,
        status: VelaPlaybackStatus.opening,
        position: Duration.zero,
        duration: Duration.zero,
        completed: false,
        errorMessage: null,
      ),
    );

    try {
      await _player.open(media_kit.Media(item.streamUrl), play: true);
      _emit(
        _state.copyWith(
          status: VelaPlaybackStatus.ready,
          playing: true,
          completed: false,
          errorMessage: null,
        ),
      );
    } catch (error) {
      _emit(
        _state.copyWith(
          status: VelaPlaybackStatus.error,
          playing: false,
          errorMessage: error.toString(),
        ),
      );
    }
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
    final next = !await windowManager.isFullScreen();
    await windowManager.setFullScreen(next);
    _emit(_state.copyWith(isFullscreen: next));
  }

  Future<void> exitFullscreenIfNeeded() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
    _emit(_state.copyWith(isFullscreen: false));
  }

  Future<void> stop() async {
    await _player.stop();
    _emit(
      _state.copyWith(
        status: VelaPlaybackStatus.idle,
        playing: false,
        buffering: false,
        completed: false,
        position: Duration.zero,
        duration: Duration.zero,
        errorMessage: null,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  void _bindPlayerStreams() {
    _subscriptions
      ..add(
        _player.stream.position.listen((value) {
          _emit(_state.copyWith(position: value));
        }),
      )
      ..add(
        _player.stream.duration.listen((value) {
          _emit(_state.copyWith(duration: value));
        }),
      )
      ..add(
        _player.stream.buffering.listen((value) {
          _emit(_state.copyWith(buffering: value));
        }),
      )
      ..add(
        _player.stream.playing.listen((value) {
          final status = value && _state.status == VelaPlaybackStatus.opening
              ? VelaPlaybackStatus.ready
              : _state.status;
          _emit(_state.copyWith(playing: value, status: status));
        }),
      )
      ..add(
        _player.stream.completed.listen((value) {
          if (!value) {
            _emit(_state.copyWith(completed: false));
            return;
          }
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
          _emit(
            _state.copyWith(
              status: VelaPlaybackStatus.error,
              playing: false,
              errorMessage: value,
            ),
          );
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
    final isFullscreen = await windowManager.isFullScreen();
    _emit(_state.copyWith(isFullscreen: isFullscreen));
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
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
