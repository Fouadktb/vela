import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigation_controller.dart';
import '../app/section_state.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/settings/settings_screen.dart';
import '../playback/playable_item.dart';
import '../playback/vela_player_route.dart';
import 'vela_sidebar.dart';

class VelaShell extends ConsumerStatefulWidget {
  const VelaShell({super.key});

  @override
  ConsumerState<VelaShell> createState() => _VelaShellState();
}

class _VelaShellState extends ConsumerState<VelaShell> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(() async {
        final service = ref.read(providerRefreshServiceProvider);
        await service.refreshStaleProvidersOnLaunch();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navigation = ref.watch(navigationControllerProvider);
    final selectedSection = navigation.selectedSection;

    return Scaffold(
      body: Row(
        children: [
          VelaSidebar(
            selectedSection: selectedSection,
            onSectionSelected: ref
                .read(navigationControllerProvider)
                .selectSection,
          ),
          Expanded(
            child: switch (selectedSection) {
              VelaSection.settings => const SettingsScreen(),
              _ => CatalogScreen(
                section: selectedSection,
                onOpenPlayer: (item) => _openPlayer(context, item),
              ),
            },
          ),
        ],
      ),
    );
  }

  void _openPlayer(BuildContext context, PlayableItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) {
          return VelaPlayerRoute(
            item: item,
            onClose: () => Navigator.of(routeContext).maybePop(),
          );
        },
      ),
    );
  }
}
