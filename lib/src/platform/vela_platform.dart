import 'dart:io';

import 'package:flutter/foundation.dart';

/// High-level app surfaces supported by the current build.
enum VelaSurface { desktop, android }

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

  /// Android uses one adaptive shell for TV remotes and phone touch input.
  static bool get isAndroidSurface {
    return isAndroid;
  }

  static VelaSurface get surface {
    return isAndroidSurface ? VelaSurface.android : VelaSurface.desktop;
  }

  static bool get supportsLocalFilePicker {
    return isDesktopWindowPlatform;
  }
}
