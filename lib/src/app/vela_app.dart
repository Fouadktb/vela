import 'package:flutter/material.dart';

import '../shell/vela_shell.dart';
import 'app_theme.dart';

class VelaApp extends StatelessWidget {
  const VelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vela',
      debugShowCheckedModeBanner: false,
      theme: buildVelaTheme(),
      home: const VelaShell(),
    );
  }
}
