import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/navigation_controller.dart';
import '../app/section_state.dart';
import '../features/providers/provider_setup_screen.dart';
import '../shared/vela_logo_mark.dart';
import '../updates/update_checker.dart';
import 'tv_focus.dart';

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
                          onPressed: () => unawaited(
                            openExternalUrl(availableUpdate.releaseUrl),
                          ),
                          icon: const Icon(LucideIcons.download),
                          label: Text(
                            'Update ${availableUpdate.latestVersion}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (!hasProviders)
                    const Expanded(child: ProviderSetupScreen())
                  else
                    Expanded(
                      child: _TvSectionGrid(
                        selected: navigation.selectedSection,
                        onSelect: ref
                            .read(navigationControllerProvider)
                            .selectSection,
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
}

class _TvSectionGrid extends StatelessWidget {
  const _TvSectionGrid({required this.selected, required this.onSelect});

  final VelaSection selected;
  final ValueChanged<VelaSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final sections = VelaSection.values;
    final theme = Theme.of(context);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 2.2,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final isSelected = section == selected;
        return TvFocusCard(
          autofocus: index == 0,
          onPressed: () => onSelect(section),
          child: Row(
            children: [
              Icon(
                section.icon,
                size: 34,
                color: isSelected
                    ? theme.colorScheme.primary
                    : const Color(0xFFE7B85B),
              ),
              const SizedBox(width: 16),
              Expanded(child: TvSectionTitle(section.label)),
            ],
          ),
        );
      },
    );
  }
}
