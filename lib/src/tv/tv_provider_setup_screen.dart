import 'package:flutter/material.dart';

import '../features/providers/provider_setup_screen.dart';

class TvProviderSetupScreen extends StatelessWidget {
  const TvProviderSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Transform.scale(scale: 1.08, child: const ProviderSetupScreen()),
      ),
    );
  }
}
