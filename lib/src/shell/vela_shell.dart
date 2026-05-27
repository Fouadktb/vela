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
    final providers = ref.watch(providersProvider);
    final hasProviders = providers.maybeWhen(
      data: (items) => items.isNotEmpty,
      orElse: () => false,
    );
    final selectedSection = navigation.selectedSection;
    final effectiveSection =
        !hasProviders && selectedSection != VelaSection.live
        ? VelaSection.live
        : selectedSection;
    if (effectiveSection != selectedSection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(navigationControllerProvider)
              .selectSection(effectiveSection);
        }
      });
    }

    return Scaffold(
      body: Row(
        children: [
          VelaSidebar(
            selectedSection: effectiveSection,
            hasProviders: hasProviders,
            onSectionSelected: (section) {
              if (!hasProviders && section != VelaSection.live) {
                return;
              }
              ref.read(navigationControllerProvider).selectSection(section);
            },
          ),
          Expanded(
            child: switch (effectiveSection) {
              VelaSection.settings => const SettingsScreen(),
              _ => CatalogScreen(
                section: effectiveSection,
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
