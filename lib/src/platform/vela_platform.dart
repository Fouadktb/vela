import 'dart:io';

import 'package:flutter/foundation.dart';

/// High-level app surfaces supported by the current build.
///
/// The first Android target is Android TV only. Generic Android phone/tablet
/// support is intentionally not modeled until that surface is added.
enum VelaSurface { desktop, androidTv }

/// Platform capability switches used to select startup, shell, and import UX.
class VelaPlatform {
  const VelaPlatform._();

  static bool get isDesktopWindowPlatform {
    if (kIsWeb) return false;
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// Treat Android as Android TV for now because this Android scaffold targets
  /// TV only. Add a separate mobile surface before supporting phone/tablet UX.
  static bool get isAndroidTv {
    return isAndroid;
  }

  static VelaSurface get surface {
    return isAndroidTv ? VelaSurface.androidTv : VelaSurface.desktop;
  }

  static bool get supportsLocalFilePicker {
    return isDesktopWindowPlatform;
  }
}
