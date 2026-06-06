import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/navigation_controller.dart';
import '../app/section_state.dart';
import '../features/catalog/catalog_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../playback/playable_item.dart';
import '../playback/vela_player_route.dart';
import '../updates/update_checker.dart';
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
    final updateStatus = ref.watch(updateStatusProvider).value;
    final hasProviders = providers.maybeWhen(
      data: (items) => items.any((provider) => provider.hasImportedCatalog),
      orElse: () => false,
    );
    final selectedSection = navigation.selectedSection;
    final effectiveSection =
        !hasProviders &&
            selectedSection != VelaSection.home &&
            selectedSection != VelaSection.live
        ? VelaSection.home
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
            updateStatus: updateStatus?.hasUpdate == true ? updateStatus : null,
            onUpdatePressed: updateStatus?.hasUpdate == true
                ? () => unawaited(openExternalUrl(updateStatus!.releaseUrl))
                : null,
            onSectionSelected: (section) {
              if (!hasProviders &&
                  section != VelaSection.home &&
                  section != VelaSection.live) {
                return;
              }
              ref.read(navigationControllerProvider).selectSection(section);
            },
          ),
          Expanded(
            child: switch (effectiveSection) {
              VelaSection.home => HomeScreen(
                onOpenPlayer: (item) => _openPlayer(context, item),
              ),
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
