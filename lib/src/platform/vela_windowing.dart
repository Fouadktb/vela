import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'vela_platform.dart';

class VelaWindowing {
  const VelaWindowing._();

  static Future<void> initializeMainWindow() async {
    if (!VelaPlatform.isDesktopWindowPlatform) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      return;
    }

    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: 'Vela',
        minimumSize: Size(1120, 720),
        size: Size(1440, 900),
        center: true,
        backgroundColor: Colors.black,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
}

class VelaFullscreenController {
  bool _isFullscreen = false;
  bool _restoreMaximizedAfterFullscreen = false;

  bool get isFullscreen => _isFullscreen;

  Future<bool> refreshFullscreenState() async {
    if (!VelaPlatform.isDesktopWindowPlatform) {
      _isFullscreen = true;
      return _isFullscreen;
    }
    _isFullscreen = await windowManager.isFullScreen();
    return _isFullscreen;
  }

  Future<void> setFullscreen(bool enabled) async {
    if (!VelaPlatform.isDesktopWindowPlatform) {
      _isFullscreen = true;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      return;
    }

    final isCurrentlyFullscreen = await windowManager.isFullScreen();
    if (isCurrentlyFullscreen == enabled) {
      _isFullscreen = enabled;
      return;
    }

    if (enabled) {
      await _prepareDesktopWindowForFullscreen();
      await windowManager.setFullScreen(true);
      _isFullscreen = true;
      return;
    }

    await windowManager.setFullScreen(false);
    await _restoreDesktopWindowAfterFullscreen();
    _isFullscreen = false;
  }

  Future<void> toggleFullscreen() async {
    final current = await refreshFullscreenState();
    await setFullscreen(!current);
  }

  Future<void> exitFullscreenIfNeeded() async {
    if (!VelaPlatform.isDesktopWindowPlatform) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _isFullscreen = true;
      return;
    }
    if (await windowManager.isFullScreen()) {
      await setFullscreen(false);
      return;
    }
    _isFullscreen = false;
  }

  Future<void> _prepareDesktopWindowForFullscreen() async {
    _restoreMaximizedAfterFullscreen = false;
    if (!Platform.isWindows) return;

    final wasMaximized = await windowManager.isMaximized();
    if (!wasMaximized) return;

    _restoreMaximizedAfterFullscreen = true;
    await windowManager.unmaximize();
  }

  Future<void> _restoreDesktopWindowAfterFullscreen() async {
    if (!Platform.isWindows || !_restoreMaximizedAfterFullscreen) return;

    _restoreMaximizedAfterFullscreen = false;
    await windowManager.maximize();
  }
}

class VelaWindowCloseGuard with WindowListener {
  VelaWindowCloseGuard({required this.onClose});

  final FutureOr<void> Function() onClose;
  bool _enabled = false;

  Future<void> enable() async {
    if (!VelaPlatform.isDesktopWindowPlatform || _enabled) return;
    try {
      await windowManager.setPreventClose(true);
      windowManager.addListener(this);
      _enabled = true;
    } catch (error, stackTrace) {
      debugPrint('Failed to intercept player window close: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> disable() async {
    if (!VelaPlatform.isDesktopWindowPlatform || !_enabled) return;
    try {
      windowManager.removeListener(this);
      await windowManager.setPreventClose(false);
    } catch (error, stackTrace) {
      debugPrint('Failed to restore player window close behavior: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _enabled = false;
    }
  }

  @override
  void onWindowClose() {
    unawaited(Future<void>.sync(onClose));
  }
}
