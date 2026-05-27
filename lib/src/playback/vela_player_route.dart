import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'playable_item.dart';
import 'playback_controller.dart';
import 'player_state.dart';
import 'seek_zones.dart';
import 'vela_player_controls.dart';

class VelaPlayerRoute extends StatefulWidget {
  const VelaPlayerRoute({required this.item, required this.onClose, super.key});

  final PlayableItem item;
  final VoidCallback onClose;

  @override
  State<VelaPlayerRoute> createState() => _VelaPlayerRouteState();
}

class _VelaPlayerRouteState extends State<VelaPlayerRoute> {
  late final PlaybackController _controller;
  final FocusNode _focusNode = FocusNode(debugLabel: 'VelaPlayerRoute');
  Timer? _hideTimer;
  Timer? _seekFeedbackTimer;
  bool _controlsVisible = true;
  String? _seekFeedback;
  Alignment _seekFeedbackAlignment = Alignment.center;
  bool _allowPop = false;
  bool _didStopPlayback = false;
  bool _didExitFullscreen = false;
  Future<void>? _closeFuture;

  @override
  void initState() {
    super.initState();
    _controller = PlaybackController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.open(widget.item);
      _scheduleHide();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: KeyboardListener(
          focusNode: _focusNode,
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

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Video(
                        controller: _controller.videoController,
                        fit: BoxFit.contain,
                        fill: Colors.black,
                        controls: null,
                      ),
                      SeekZones(
                        onInteraction: _showControls,
                        onSeek: _handleSeekZone,
                      ),
                      if (state.buffering ||
                          state.status == VelaPlaybackStatus.opening)
                        const _BufferingIndicator(),
                      if (state.status == VelaPlaybackStatus.error)
                        _ErrorOverlay(message: state.errorMessage),
                      if (_seekFeedback != null)
                        _SeekFeedback(
                          label: _seekFeedback!,
                          alignment: _seekFeedbackAlignment,
                        ),
                      AnimatedOpacity(
                        opacity: _controlsVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: IgnorePointer(
                          ignoring: !_controlsVisible,
                          child: VelaPlayerControls(
                            controller: _controller,
                            state: state,
                            onClose: _close,
                            onNextEpisode: _openNextEpisode,
                          ),
                        ),
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

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    _showControls();

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        _close();
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.mediaPlayPause:
        _controller.togglePlayPause();
      case LogicalKeyboardKey.arrowLeft:
        _seek(SeekZoneDirection.backward);
      case LogicalKeyboardKey.arrowRight:
        _seek(SeekZoneDirection.forward);
    }
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
    await _controller.open(item);
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
      await _stopPlaybackIfNeeded();
    } finally {
      await _exitFullscreenIfNeeded();
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
}

class _BufferingIndicator extends StatelessWidget {
  const _BufferingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              'Playback failed',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'The stream could not be opened.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFD8D2C8),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
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
