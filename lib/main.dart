import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'src/app/vela_app.dart';
import 'src/platform/vela_windowing.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await VelaWindowing.initializeMainWindow();

  runApp(const ProviderScope(child: VelaApp()));
}
