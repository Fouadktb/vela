import 'package:flutter/foundation.dart';

/// Capabilities shared by the macOS and Windows desktop apps.
class VelaPlatform {
  const VelaPlatform._();

  static bool get isDesktopWindowPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  static bool get supportsLocalFilePicker => isDesktopWindowPlatform;
}
