import 'dart:io';

import 'package:flutter/foundation.dart';

enum VelaSurface { desktop, androidTv }

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
