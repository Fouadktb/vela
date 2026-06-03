import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/navigation_controller.dart';
import '../playback/playable_item.dart';
import '../playback/vela_player_route.dart';
import '../shared/vela_logo_mark.dart';
import '../updates/update_checker.dart';
import 'tv_catalog_screen.dart';
import 'tv_provider_setup_screen.dart';

class VelaTvShell extends ConsumerStatefulWidget {
  const VelaTvShell({super.key});

  @override
  ConsumerState<VelaTvShell> createState() => _VelaTvShellState();
}

class _VelaTvShellState extends ConsumerState<VelaTvShell> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(() async {
        await ref
            .read(providerRefreshServiceProvider)
            .refreshStaleProvidersOnLaunch();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(providersProvider);
    final updateStatus = ref.watch(updateStatusProvider).value;
    final availableUpdate = updateStatus?.hasUpdate == true
        ? updateStatus
        : null;
    final navigation = ref.watch(navigationControllerProvider);

    return providers.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text(error.toString()))),
      data: (items) {
        final hasProviders = items.any(
          (provider) => provider.hasImportedCatalog,
        );
        return Scaffold(
          backgroundColor: const Color(0xFF0C0D0E),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const VelaLogoMark(size: 34),
                      const SizedBox(width: 14),
                      Text(
                        'Vela',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                      const Spacer(),
                      if (availableUpdate != null)
                        FilledButton.icon(
                          onPressed: () async {
                            await _openUpdate(availableUpdate);
                          },
                          icon: const Icon(LucideIcons.download),
                          label: Text(
                            'Update ${availableUpdate.latestVersion}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (!hasProviders)
                    const Expanded(child: TvProviderSetupScreen())
                  else
                    Expanded(
                      child: TvCatalogScreen(
                        section: navigation.selectedSection,
                        onOpenPlayer: (item) => _openPlayer(context, item),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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

  Future<void> _openUpdate(UpdateStatus status) async {
    try {
      await openExternalUrl(status.androidApkUrl ?? status.releaseUrl);
    } on UpdateCheckException catch (error, stackTrace) {
      debugPrint('Failed to open update URL: $error\n$stackTrace');
      _showUpdateError();
    } catch (error, stackTrace) {
      debugPrint('Unexpected update launch error: $error\n$stackTrace');
      _showUpdateError();
    }
  }

  void _showUpdateError() {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the update download. Try again later.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          duration: Duration(seconds: 5),
        ),
      );
  }
}
