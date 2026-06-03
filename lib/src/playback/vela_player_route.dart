import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../app/navigation_controller.dart';
import '../catalog/catalog_models.dart';
import '../features/series/episode_rail.dart';
import '../platform/vela_windowing.dart';
import 'playable_item.dart';
import 'playback_controller.dart';
import 'playback_preferences.dart';
import 'player_state.dart';
import 'recent_live_channels.dart';
import 'seek_zones.dart';
import 'vela_player_controls.dart';

class VelaPlayerRoute extends ConsumerStatefulWidget {
  const VelaPlayerRoute({required this.item, required this.onClose, super.key});

  final PlayableItem item;
  final VoidCallback onClose;

  @override
  ConsumerState<VelaPlayerRoute> createState() => _VelaPlayerRouteState();
}

class _VelaPlayerRouteState extends ConsumerState<VelaPlayerRoute> {
  late final PlaybackController _controller;
  late final PlaybackPreferencesRepository _preferencesRepository;
  late final VelaWindowCloseGuard _windowCloseGuard;
  final FocusNode _focusNode = FocusNode(debugLabel: 'VelaPlayerRoute');
  Timer? _hideTimer;
  Timer? _seekFeedbackTimer;
  DateTime? _lastPersistedAt;
  String? _lastPersistedKey;
  Duration _lastPersistedPosition = Duration.zero;
  Future<void> _persistQueue = Future<void>.value();
  int _pendingPersistCount = 0;
  bool _controlsVisible = true;
  String? _seekFeedback;
  Alignment _seekFeedbackAlignment = Alignment.center;
  bool _hasPersistablePlaybackStarted = false;
  bool _allowPop = false;
  bool _didStopPlayback = false;
  bool _didExitFullscreen = false;
  Future<void>? _closeFuture;
  int _preferencesOpenSequence = 0;
  bool _isOpeningMedia = false;
  String? _currentOpenItemKey;
  PlaybackTrackPreferences? _trackPreferences;
  bool _trackPreferencesLoaded = false;
  bool _manualTrackSelectionMade = false;
  bool _audioPreferenceApplied = false;
  bool _subtitlePreferenceApplied = false;
  bool _videoPreferenceApplied = false;
  String? _autoAdvancedCompletedKey;
  Timer? _spaceHoldTimer;
  bool _spacePressed = false;
  bool _spaceHoldElapsed = false;
  bool _spaceHoldActive = false;
  double? _spaceSpeedBeforeHold;
  String? _currentLiveChannelKey;
  String? _lastPlaybackWarningMessage;
  bool _recentLiveChannelsExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller = PlaybackController();
    _preferencesRepository = PlaybackPreferencesRepository(
      ref.read(appSettingsRepositoryProvider),
    );
    _windowCloseGuard = VelaWindowCloseGuard(onClose: _close);
    _controller.addListener(_handlePlaybackUpdate);
    unawaited(_windowCloseGuard.enable());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _openItem(widget.item);
      _scheduleHide();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    _spaceHoldTimer?.cancel();
    _restoreSpaceHoldSpeedIfNeeded();
    _controller.removeListener(_handlePlaybackUpdate);
    unawaited(_windowCloseGuard.disable());
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentLiveChannels = ref.watch(
      recentLiveChannelsProvider(_currentLiveChannelKey),
    );

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          descendantsAreFocusable: false,
          descendantsAreTraversable: false,
          onKeyEvent: _handleKey,
          child: MouseRegion(
            onHover: (_) => _showControls(),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _showControls,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final state = _controller.state;

                  return Column(
                    children: [
                      Expanded(
                        child: _PlayerSurface(
                          controller: _controller,
                          state: state,
                          controlsVisible: _controlsVisible,
                          seekFeedback: _seekFeedback,
                          seekFeedbackAlignment: _seekFeedbackAlignment,
                          onClose: () => unawaited(_close()),
                          onRetry: _isOpeningMedia ? null : _retryPlayback,
                          onDismissPlaybackWarning:
                              _controller.clearPlaybackWarning,
                          onNextEpisode: _openNextEpisode,
                          onAudioTrackSelected: _selectAudioTrack,
                          onSubtitleTrackSelected: _selectSubtitleTrack,
                          onVideoTrackSelected: _selectVideoTrack,
                          onShowControls: _showControls,
                          onSeekZone: _handleSeekZone,
                          onCenterDoubleTap: _handleCenterDoubleTap,
                          recentLiveChannels: recentLiveChannels,
                          recentLiveChannelsExpanded:
                              _recentLiveChannelsExpanded,
                          onToggleRecentLiveChannels: _toggleRecentLiveChannels,
                          onOpenLiveChannel: _openLiveChannel,
                        ),
                      ),
                      if (!state.isFullscreen &&
                          state.item?.kind == PlayableKind.episode &&
                          state.item!.episodeRailItems.length > 1)
                        EpisodeRail(
                          currentItem: state.item!,
                          items: state.item!.episodeRailItems,
                          onSelect: _openRailEpisode,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    _showControls();

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _handleSpaceKey(event);
      return KeyEventResult.handled;
    }

    if (event is! KeyDownEvent) {
      return _isPlayerShortcutKey(event.logicalKey)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.browserBack:
        unawaited(_close());
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _controller.togglePlayPause();
      case LogicalKeyboardKey.arrowLeft:
        _seek(SeekZoneDirection.backward);
      case LogicalKeyboardKey.arrowRight:
        _seek(SeekZoneDirection.forward);
      case LogicalKeyboardKey.arrowUp:
        unawaited(_controller.setVolume(_controller.state.volume + 5));
      case LogicalKeyboardKey.arrowDown:
        unawaited(_controller.setVolume(_controller.state.volume - 5));
      case LogicalKeyboardKey.keyF:
        unawaited(_controller.toggleFullscreen());
      case LogicalKeyboardKey.keyM:
        unawaited(_controller.toggleMute());
      case LogicalKeyboardKey.keyN:
        final next = _controller.state.item?.nextEpisode;
        if (next != null) unawaited(_openNextEpisode(next));
      default:
        return KeyEventResult.ignored;
    }

    return KeyEventResult.handled;
  }

  bool _isPlayerShortcutKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyF ||
        key == LogicalKeyboardKey.keyM ||
        key == LogicalKeyboardKey.keyN;
  }

  void _handleSpaceKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_spacePressed) return;
      _spacePressed = true;
      _spaceHoldElapsed = false;
      _spaceHoldActive = false;
      _spaceSpeedBeforeHold = null;
      _spaceHoldTimer?.cancel();
      _spaceHoldTimer = Timer(
        const Duration(milliseconds: 300),
        _activateSpaceHoldSpeed,
      );
      return;
    }

    if (event is KeyUpEvent) {
      _finishSpacePress();
    }
  }

  void _activateSpaceHoldSpeed() {
    if (!_spacePressed || !mounted) return;
    _spaceHoldElapsed = true;
    final state = _controller.state;
    final item = state.item;
    if (!state.isSeekable || item?.kind == PlayableKind.live) {
      return;
    }

    _spaceHoldActive = true;
    _spaceSpeedBeforeHold = state.playbackSpeed;
    unawaited(_controller.setPlaybackSpeed(2));
  }

  void _finishSpacePress() {
    _spaceHoldTimer?.cancel();
    _spaceHoldTimer = null;
    if (!_spacePressed) return;

    _spacePressed = false;
    if (_spaceHoldActive) {
      _spaceHoldActive = false;
      final previousSpeed = _spaceSpeedBeforeHold ?? 1;
      _spaceHoldElapsed = false;
      _spaceSpeedBeforeHold = null;
      if ((_controller.state.playbackSpeed - previousSpeed).abs() > 0.01) {
        unawaited(_controller.setPlaybackSpeed(previousSpeed));
      }
      return;
    }

    if (_spaceHoldElapsed) {
      _spaceHoldElapsed = false;
      _spaceSpeedBeforeHold = null;
      return;
    }

    _spaceSpeedBeforeHold = null;
    _controller.togglePlayPause();
  }

  void _restoreSpaceHoldSpeedIfNeeded() {
    _spaceHoldTimer?.cancel();
    _spaceHoldTimer = null;
    if (!_spaceHoldActive) return;
    final previousSpeed = _spaceSpeedBeforeHold ?? 1;
    _spaceHoldActive = false;
    _spacePressed = false;
    _spaceHoldElapsed = false;
    _spaceSpeedBeforeHold = null;
    unawaited(_controller.setPlaybackSpeed(previousSpeed));
  }

  void _showControls() {
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_controller.state.playing) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _handleSeekZone(SeekZoneDirection direction) {
    _showControls();
    _seek(direction);
  }

  void _handleCenterDoubleTap() {
    _showControls();
    unawaited(_controller.toggleFullscreen());
  }

  void _toggleRecentLiveChannels() {
    setState(() {
      _recentLiveChannelsExpanded = !_recentLiveChannelsExpanded;
    });
    _showControls();
  }

  void _openLiveChannel(PlayableItem item) {
    _showControls();
    unawaited(_switchLiveChannel(item));
  }

  Future<void> _switchLiveChannel(PlayableItem item) async {
    await _persistProgress(force: true);
    await _openItem(item);
  }

  void _seek(SeekZoneDirection direction) {
    if (!_controller.state.isSeekable) return;
    final isBackward = direction == SeekZoneDirection.backward;
    _controller.seekRelative(Duration(seconds: isBackward ? -10 : 10));

    _seekFeedbackTimer?.cancel();
    setState(() {
      _seekFeedback = isBackward ? '-10' : '+10';
      _seekFeedbackAlignment = isBackward
          ? const Alignment(-0.58, 0)
          : const Alignment(0.58, 0);
    });
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _seekFeedback = null);
    });
  }

  Future<void> _openNextEpisode(PlayableItem item) async {
    _showControls();
    await _persistProgress(force: true);
    await _openEpisodeFromRail(item, resume: false);
  }

  Future<void> _openRailEpisode(PlayableItem item) async {
    _showControls();
    await _persistProgress(force: true);
    await _openEpisodeFromRail(item, resume: true);
  }

  Future<void> _openEpisodeFromRail(
    PlayableItem item, {
    required bool resume,
  }) async {
    final currentRail = _controller.state.item?.episodeRailItems;
    final rail = item.episodeRailItems.isNotEmpty
        ? item.episodeRailItems
        : currentRail ?? const <PlayableItem>[];
    final resumePosition = resume
        ? await _lookupResumePosition(item)
        : Duration.zero;
    await _openItem(
      item.copyWith(resumePosition: resumePosition, episodeRailItems: rail),
    );
  }

  Future<Duration> _lookupResumePosition(PlayableItem item) async {
    if (item.kind != PlayableKind.episode ||
        item.seriesId == null ||
        item.seasonId == null) {
      return Duration.zero;
    }
    final resume = await ref
        .read(watchHistoryRepositoryProvider)
        .lookupResumePosition(
          providerId: item.providerId,
          itemId: item.id,
          itemType: PlayableContentType.episode,
          seriesId: item.seriesId,
          seasonId: item.seasonId,
        );
    return resume == null
        ? Duration.zero
        : Duration(seconds: resume.positionSeconds);
  }

  Future<void> _openItem(PlayableItem item) async {
    if (_isOpeningMedia) return;
    final itemWithContinuity = _withEpisodeContinuity(item);
    final sequence = ++_preferencesOpenSequence;
    final itemKey = _historyKey(itemWithContinuity);
    _isOpeningMedia = true;
    _currentOpenItemKey = itemKey;
    _autoAdvancedCompletedKey = null;
    if (mounted) setState(() {});

    _resetTrackPreferences(
      itemWithContinuity,
      sequence: sequence,
      itemKey: itemKey,
    );
    _lastPersistedAt = null;
    _lastPersistedKey = null;
    _lastPersistedPosition = Duration.zero;
    _hasPersistablePlaybackStarted = false;
    try {
      await _controller.open(itemWithContinuity);
    } finally {
      if (mounted && sequence == _preferencesOpenSequence) {
        _isOpeningMedia = false;
        setState(() {});
      }
    }

    if (!_isCurrentOpen(sequence, itemKey)) return;
    unawaited(
      _applyTrackPreferencesIfReady(sequence: sequence, itemKey: itemKey),
    );
  }

  Future<void> _retryPlayback() async {
    if (_isOpeningMedia) return;
    final state = _controller.state;
    final item = state.item;
    if (item == null) return;

    _showControls();
    final resumePosition = _safeRetryPosition(state);
    await _openItem(item.copyWith(resumePosition: resumePosition));
  }

  Future<void> _close() async {
    _closeFuture ??= _performClose();
    await _closeFuture;
  }

  Future<void> _performClose() async {
    await _cleanupPlayback();
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    try {
      widget.onClose();
    } catch (error, stackTrace) {
      debugPrint('Failed to close player route: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _cleanupPlayback() async {
    try {
      _preferencesOpenSequence += 1;
      _currentOpenItemKey = null;
      await _persistProgress(force: true);
      await _stopPlaybackIfNeeded();
    } finally {
      await _exitFullscreenIfNeeded();
      await _windowCloseGuard.disable();
    }
  }

  Future<void> _stopPlaybackIfNeeded() async {
    if (_didStopPlayback) return;
    try {
      await _controller.stop();
      _didStopPlayback = true;
    } catch (error, stackTrace) {
      debugPrint('Failed to stop playback before closing: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _exitFullscreenIfNeeded() async {
    if (_didExitFullscreen) return;
    try {
      await _controller.exitFullscreenIfNeeded();
      _didExitFullscreen = true;
    } catch (error, stackTrace) {
      debugPrint('Failed to exit fullscreen before closing: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handlePlaybackUpdate() {
    final state = _controller.state;
    final warningMessage = state.playbackWarningMessage;
    if (warningMessage != null &&
        warningMessage != _lastPlaybackWarningMessage) {
      _showControls();
    }
    _lastPlaybackWarningMessage = warningMessage;
    final nextLiveChannelKey = liveChannelKeyForItem(state.item);
    if (nextLiveChannelKey != _currentLiveChannelKey && mounted) {
      setState(() => _currentLiveChannelKey = nextLiveChannelKey);
    }
    unawaited(_persistProgress());
    unawaited(_applyTrackPreferencesIfReady());
    _autoAdvanceCompletedEpisode(state);
  }

  void _autoAdvanceCompletedEpisode(VelaPlayerState state) {
    final item = state.item;
    final nextEpisode = item?.nextEpisode;
    if (!mounted ||
        _isOpeningMedia ||
        item == null ||
        item.kind != PlayableKind.episode ||
        nextEpisode == null ||
        state.status != VelaPlaybackStatus.completed ||
        !state.completed) {
      return;
    }

    final completedKey = _historyKey(item);
    if (_autoAdvancedCompletedKey == completedKey) return;
    _autoAdvancedCompletedKey = completedKey;
    unawaited(_openNextEpisode(nextEpisode));
  }

  void _resetTrackPreferences(
    PlayableItem item, {
    required int sequence,
    required String itemKey,
  }) {
    _trackPreferences = null;
    _trackPreferencesLoaded = false;
    _manualTrackSelectionMade = false;
    _audioPreferenceApplied = false;
    _subtitlePreferenceApplied = false;
    _videoPreferenceApplied = false;

    _preferencesRepository
        .load(item)
        .then((preferences) {
          if (!_hasCurrentOpenIdentity(sequence, itemKey)) return;
          _trackPreferences = preferences;
          _trackPreferencesLoaded = true;
          unawaited(
            _applyTrackPreferencesIfReady(sequence: sequence, itemKey: itemKey),
          );
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Failed to load playback preferences: $error');
          debugPrintStack(stackTrace: stackTrace);
          if (!_hasCurrentOpenIdentity(sequence, itemKey)) return;
          _trackPreferencesLoaded = true;
        });
  }

  Future<void> _applyTrackPreferencesIfReady({
    int? sequence,
    String? itemKey,
  }) async {
    final capturedSequence = sequence ?? _preferencesOpenSequence;
    final capturedItemKey = itemKey ?? _currentOpenItemKey;
    if (!_canApplyTrackPreferences(capturedSequence, capturedItemKey)) return;

    final preferences = _trackPreferences;
    if (preferences == null || preferences.isEmpty) {
      if (!_canApplyTrackPreferences(capturedSequence, capturedItemKey)) {
        return;
      }
      _audioPreferenceApplied = true;
      _subtitlePreferenceApplied = true;
      _videoPreferenceApplied = true;
      return;
    }

    final state = _controller.state;
    if (state.item == null ||
        !_canApplyTrackPreferences(capturedSequence, capturedItemKey)) {
      return;
    }

    try {
      if (!_audioPreferenceApplied) {
        if (!_canApplyTrackPreferences(capturedSequence, capturedItemKey)) {
          return;
        }
        final audioPreference = preferences.audio;
        if (audioPreference == null) {
          _audioPreferenceApplied = true;
        } else if (state.audioTracks.isNotEmpty) {
          _audioPreferenceApplied = true;
          final track = resolvePreferredAudioTrack(
            state.audioTracks,
            audioPreference,
          );
          if (track != null) {
            await _controller.selectAudioTrack(track.id);
            if (!_canApplyTrackPreferences(capturedSequence, capturedItemKey)) {
              return;
            }
          }
        }
      }

      if (!_subtitlePreferenceApplied) {
        if (!_canApplyTrackPreferences(capturedSequence, capturedItemKey)) {
          return;
        }
        final subtitlePreference = preferences.subtitle;
        if (subtitlePreference == null) {
          _subtitlePreferenceApplied = true;
        } else if (subtitlePreference.isSubtitlesOff) {
          _subtitlePreferenceApplied = true;
          await _controller.turnSubtitlesOff();
          if (!_canApplyTrackPreferences(capturedSequence, capturedItemKey)) {
            return;
          }
        } else if (state.subtitleTracks.isNotEmpty) {
          _subtitlePreferenceApplied = true;
          final track = resolvePreferredSubtitleTrack(
            state.subtitleTracks,
            subtitlePreference,
          );
          if (track != null) {
            await _controller.selectSubtitleTrack(track.id);
            if (!_canApplyTrackPreferences(capturedSequence, capturedItemKey)) {
              return;
            }
          }
        }
      }

      if (!_videoPreferenceApplied) {
        if (!_canApplyTrackPreferences(capturedSequence, capturedItemKey)) {
          return;
        }
        final videoPreference = preferences.video;
        if (videoPreference == null) {
          _videoPreferenceApplied = true;
        } else if (state.videoTracks.isNotEmpty) {
          _videoPreferenceApplied = true;
          final track = resolvePreferredVideoTrack(
            state.videoTracks,
            videoPreference,
          );
          if (track != null) {
            await _controller.selectVideoTrack(track.id);
            if (!_canApplyTrackPreferences(capturedSequence, capturedItemKey)) {
              return;
            }
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to apply playback preferences: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool _canApplyTrackPreferences(int sequence, String? itemKey) {
    return _trackPreferencesLoaded &&
        !_manualTrackSelectionMade &&
        _isCurrentOpen(sequence, itemKey);
  }

  bool _isCurrentOpen(int sequence, String? itemKey) {
    final item = _controller.state.item;
    return _hasCurrentOpenIdentity(sequence, itemKey) &&
        item != null &&
        _historyKey(item) == itemKey;
  }

  bool _hasCurrentOpenIdentity(int sequence, String? itemKey) {
    return mounted &&
        itemKey != null &&
        sequence == _preferencesOpenSequence &&
        _currentOpenItemKey == itemKey;
  }

  void _selectAudioTrack(String id) {
    unawaited(_selectAudioTrackAndSave(id));
  }

  Future<void> _selectAudioTrackAndSave(String id) async {
    final state = _controller.state;
    final item = state.item;
    final track = state.audioTracks.firstWhereOrNull((track) => track.id == id);
    _markManualTrackSelection();
    try {
      await _controller.selectAudioTrack(id);
      if (item == null || track == null) return;
      await _preferencesRepository.saveAudioTrack(item, track);
    } catch (error, stackTrace) {
      debugPrint('Failed to save audio preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _selectSubtitleTrack(String id) {
    if (id == 'off') {
      _turnSubtitlesOff();
      return;
    }
    unawaited(_selectSubtitleTrackAndSave(id));
  }

  Future<void> _selectSubtitleTrackAndSave(String id) async {
    final state = _controller.state;
    final item = state.item;
    final track = state.subtitleTracks.firstWhereOrNull(
      (track) => track.id == id,
    );
    _markManualTrackSelection();
    try {
      await _controller.selectSubtitleTrack(id);
      if (item == null || track == null) return;
      await _preferencesRepository.saveSubtitleTrack(item, track);
    } catch (error, stackTrace) {
      debugPrint('Failed to save subtitle preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _turnSubtitlesOff() {
    unawaited(_turnSubtitlesOffAndSave());
  }

  Future<void> _turnSubtitlesOffAndSave() async {
    final item = _controller.state.item;
    _markManualTrackSelection();
    try {
      await _controller.turnSubtitlesOff();
      if (item == null) return;
      await _preferencesRepository.saveSubtitlesOff(item);
    } catch (error, stackTrace) {
      debugPrint('Failed to save subtitle preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _selectVideoTrack(String id) {
    unawaited(_selectVideoTrackAndSave(id));
  }

  Future<void> _selectVideoTrackAndSave(String id) async {
    final state = _controller.state;
    final item = state.item;
    final track = state.videoTracks.firstWhereOrNull((track) => track.id == id);
    _markManualTrackSelection();
    try {
      await _controller.selectVideoTrack(id);
      if (item == null || track == null) return;
      await _preferencesRepository.saveVideoTrack(item, track);
    } catch (error, stackTrace) {
      debugPrint('Failed to save video preference: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _markManualTrackSelection() {
    _manualTrackSelectionMade = true;
    _audioPreferenceApplied = true;
    _subtitlePreferenceApplied = true;
    _videoPreferenceApplied = true;
  }

  Duration _safeRetryPosition(VelaPlayerState state) {
    final item = state.item;
    if (item == null || item.kind == PlayableKind.live || state.completed) {
      return Duration.zero;
    }
    if (state.position < const Duration(seconds: 2)) {
      return item.resumePosition;
    }
    final nearEnd =
        state.duration > Duration.zero &&
        state.duration - state.position < const Duration(seconds: 10);
    return nearEnd ? item.resumePosition : state.position;
  }

  Future<void> _persistProgress({bool force = false}) {
    if (!force && _pendingPersistCount > 0) {
      return Future<void>.value();
    }

    _pendingPersistCount += 1;
    late final Future<void> operation;
    operation = _persistQueue
        .then((_) => _persistProgressNow(force: force))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Failed to persist playback progress: $error');
          debugPrintStack(stackTrace: stackTrace);
        })
        .whenComplete(() {
          _pendingPersistCount -= 1;
          if (identical(_persistQueue, operation) &&
              _pendingPersistCount == 0) {
            _persistQueue = Future<void>.value();
          }
        });
    _persistQueue = operation;
    return operation;
  }

  Future<void> _persistProgressNow({required bool force}) async {
    final state = _controller.state;
    final item = state.item;
    if (item == null || !_canPersistProgress(state, item)) return;

    final now = DateTime.now();
    final key = _historyKey(item);
    final cadence = item.kind == PlayableKind.live
        ? const Duration(seconds: 60)
        : const Duration(seconds: 15);
    final minDelta = item.kind == PlayableKind.live
        ? Duration.zero
        : const Duration(seconds: 10);
    final elapsed = _lastPersistedAt == null
        ? cadence
        : now.difference(_lastPersistedAt!);
    final moved = (state.position - _lastPersistedPosition).abs();

    if (!force &&
        key == _lastPersistedKey &&
        elapsed < cadence &&
        moved < minDelta &&
        !state.completed) {
      return;
    }

    final update = _historyUpdateForState(state, item);
    if (update == null) return;

    await ref
        .read(watchHistoryRepositoryProvider)
        .addOrUpdateWatchHistory(update);
    _lastPersistedAt = now;
    _lastPersistedKey = key;
    _lastPersistedPosition = state.position;
  }

  bool _canPersistProgress(VelaPlayerState state, PlayableItem item) {
    if (state.status == VelaPlaybackStatus.idle ||
        state.status == VelaPlaybackStatus.opening) {
      return false;
    }

    if (!_hasPersistablePlaybackStarted &&
        (state.playing ||
            state.position > Duration.zero ||
            state.completed ||
            state.status == VelaPlaybackStatus.completed)) {
      _hasPersistablePlaybackStarted = true;
    }

    if (!_hasPersistablePlaybackStarted) {
      return false;
    }

    if (item.kind == PlayableKind.live) {
      return true;
    }

    return state.position > Duration.zero ||
        state.completed ||
        state.status == VelaPlaybackStatus.completed;
  }

  WatchHistoryUpdate? _historyUpdateForState(
    VelaPlayerState state,
    PlayableItem item,
  ) {
    final itemType = switch (item.kind) {
      PlayableKind.live => PlayableContentType.live,
      PlayableKind.movie => PlayableContentType.movie,
      PlayableKind.episode => PlayableContentType.episode,
    };
    if (item.kind == PlayableKind.episode &&
        (item.seriesId == null || item.seasonId == null)) {
      return null;
    }

    final duration = state.duration > Duration.zero
        ? state.duration
        : item.durationSeconds == null
        ? Duration.zero
        : Duration(seconds: item.durationSeconds!);
    final durationSeconds = duration > Duration.zero
        ? duration.inSeconds
        : null;
    final maxPositionSeconds = durationSeconds ?? 0x7fffffff;
    final positionSeconds = item.kind == PlayableKind.live
        ? 0
        : state.position.inSeconds.clamp(0, maxPositionSeconds).toInt();
    final completion = durationSeconds == null || durationSeconds == 0
        ? 0.0
        : positionSeconds / durationSeconds;
    final completed =
        item.kind != PlayableKind.live &&
        (state.completed || completion >= .92);

    return WatchHistoryUpdate(
      itemId: item.id,
      itemType: itemType,
      providerId: item.providerId,
      title: item.title,
      subtitle: item.subtitle,
      artworkUrl: item.kind == PlayableKind.live
          ? item.channelLogoUrl
          : item.posterUrl,
      seriesId: item.seriesId,
      seasonId: item.seasonId,
      positionSeconds: completed && durationSeconds != null
          ? durationSeconds
          : positionSeconds,
      durationSeconds: durationSeconds,
      completionPercentage: completed ? 1.0 : completion,
      completed: completed,
      incrementWatchCount: false,
    );
  }

  PlayableItem _withEpisodeContinuity(PlayableItem item) {
    if (item.kind != PlayableKind.episode || item.episodeRailItems.isEmpty) {
      return item;
    }
    final rail = item.episodeRailItems;
    final index = rail.indexWhere(
      (candidate) =>
          candidate.id == item.id && candidate.seasonId == item.seasonId,
    );
    final next = index >= 0 && index + 1 < rail.length
        ? rail[index + 1].copyWith(episodeRailItems: rail)
        : null;
    return item.copyWith(nextEpisode: next, episodeRailItems: rail);
  }

  String _historyKey(PlayableItem item) {
    return [
      item.providerId,
      item.kind.name,
      item.seriesId,
      item.seasonId,
      item.id,
    ].whereType<String>().join(':');
  }
}

class _PlayerSurface extends StatelessWidget {
  const _PlayerSurface({
    required this.controller,
    required this.state,
    required this.controlsVisible,
    required this.seekFeedback,
    required this.seekFeedbackAlignment,
    required this.onClose,
    required this.onRetry,
    required this.onDismissPlaybackWarning,
    required this.onNextEpisode,
    required this.onAudioTrackSelected,
    required this.onSubtitleTrackSelected,
    required this.onVideoTrackSelected,
    required this.onShowControls,
    required this.onSeekZone,
    required this.onCenterDoubleTap,
    required this.recentLiveChannels,
    required this.recentLiveChannelsExpanded,
    required this.onToggleRecentLiveChannels,
    required this.onOpenLiveChannel,
  });

  final PlaybackController controller;
  final VelaPlayerState state;
  final bool controlsVisible;
  final String? seekFeedback;
  final Alignment seekFeedbackAlignment;
  final VoidCallback onClose;
  final VoidCallback? onRetry;
  final VoidCallback onDismissPlaybackWarning;
  final ValueChanged<PlayableItem> onNextEpisode;
  final ValueChanged<String> onAudioTrackSelected;
  final ValueChanged<String> onSubtitleTrackSelected;
  final ValueChanged<String> onVideoTrackSelected;
  final VoidCallback onShowControls;
  final ValueChanged<SeekZoneDirection> onSeekZone;
  final VoidCallback onCenterDoubleTap;
  final AsyncValue<List<PlayableItem>> recentLiveChannels;
  final bool recentLiveChannelsExpanded;
  final VoidCallback onToggleRecentLiveChannels;
  final ValueChanged<PlayableItem> onOpenLiveChannel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Video(
          controller: controller.videoController,
          fit: BoxFit.contain,
          fill: Colors.black,
          controls: null,
        ),
        SeekZones(
          onInteraction: onShowControls,
          onSeek: onSeekZone,
          onCenterDoubleTap: onCenterDoubleTap,
        ),
        if ((state.buffering || state.status == VelaPlaybackStatus.opening) &&
            state.status != VelaPlaybackStatus.error &&
            state.status != VelaPlaybackStatus.stalled)
          _BufferingIndicator(state: state),
        if (state.canRetry)
          _RetryOverlay(
            status: state.status,
            message: state.errorMessage,
            onRetry: onRetry,
          ),
        if (seekFeedback != null)
          _SeekFeedback(label: seekFeedback!, alignment: seekFeedbackAlignment),
        AnimatedOpacity(
          opacity: controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            ignoring: !controlsVisible,
            child: VelaPlayerControls(
              controller: controller,
              state: state,
              onClose: onClose,
              onRetry: onRetry,
              onDismissPlaybackWarning: onDismissPlaybackWarning,
              onNextEpisode: onNextEpisode,
              onAudioTrackSelected: onAudioTrackSelected,
              onSubtitleTrackSelected: onSubtitleTrackSelected,
              onVideoTrackSelected: onVideoTrackSelected,
              recentLiveChannels: recentLiveChannels,
              recentLiveChannelsExpanded: recentLiveChannelsExpanded,
              onToggleRecentLiveChannels: onToggleRecentLiveChannels,
              onOpenLiveChannel: onOpenLiveChannel,
            ),
          ),
        ),
      ],
    );
  }
}

class _BufferingIndicator extends StatelessWidget {
  const _BufferingIndicator({required this.state});

  final VelaPlayerState state;

  @override
  Widget build(BuildContext context) {
    final percentage = state.bufferingPercentage.round();
    final hasPercentage = percentage > 0 && percentage < 100;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xB0000000),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
            if (hasPercentage) ...[
              const SizedBox(width: 12),
              Text(
                'Buffering $percentage%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RetryOverlay extends StatelessWidget {
  const _RetryOverlay({
    required this.status,
    required this.message,
    required this.onRetry,
  });

  final VelaPlaybackStatus status;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStalled = status == VelaPlaybackStatus.stalled;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xE617191C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x44FFFFFF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isStalled ? 'Playback stalled' : 'Playback failed',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  (isStalled
                      ? 'The stream stopped receiving data.'
                      : 'The stream could not be opened.'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFD8D2C8),
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(onRetry == null ? 'Opening...' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}

class _SeekFeedback extends StatelessWidget {
  const _SeekFeedback({required this.label, required this.alignment});

  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0x99000000),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x44FFFFFF)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
