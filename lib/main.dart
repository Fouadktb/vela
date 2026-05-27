import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/vela_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

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

  runApp(const ProviderScope(child: VelaApp()));
}
