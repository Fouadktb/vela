import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/navigation_controller.dart';
import '../app/section_state.dart';
import '../playback/playable_item.dart';
import '../playback/vela_player_route.dart';
import '../shared/vela_logo_mark.dart';
import '../updates/update_checker.dart';
import 'tv_catalog_screen.dart';
import 'tv_focus.dart';
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactSurface =
                    constraints.maxWidth < 1100 || constraints.maxHeight < 680;
                final sidebarLayout = hasProviders;
                final edgePadding = compactSurface ? 10.0 : 40.0;
                if (sidebarLayout) {
                  return Padding(
                    padding: EdgeInsets.all(edgePadding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TvShellSidebar(
                          selected: navigation.selectedSection,
                          wide: constraints.maxWidth >= 900,
                          availableUpdate: availableUpdate,
                          onSelect: ref
                              .read(navigationControllerProvider)
                              .selectSection,
                          onOpenUpdate: availableUpdate == null
                              ? null
                              : () => unawaited(_openUpdate(availableUpdate)),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: TvCatalogScreen(
                            section: navigation.selectedSection,
                            persistentCategories: true,
                            onOpenPlayer: (item) => _openPlayer(context, item),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.all(edgePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          VelaLogoMark(size: compactSurface ? 28 : 34),
                          SizedBox(width: compactSurface ? 10 : 14),
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
                      SizedBox(height: compactSurface ? 16 : 28),
                      if (!hasProviders)
                        const Expanded(child: TvProviderSetupScreen())
                      else
                        Expanded(
                          child: TvCatalogScreen(
                            section: navigation.selectedSection,
                            persistentCategories: false,
                            onOpenPlayer: (item) => _openPlayer(context, item),
                          ),
                        ),
                    ],
                  ),
                );
              },
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

class _TvShellSidebar extends StatefulWidget {
  const _TvShellSidebar({
    required this.selected,
    required this.wide,
    required this.availableUpdate,
    required this.onSelect,
    required this.onOpenUpdate,
  });

  final VelaSection selected;
  final bool wide;
  final UpdateStatus? availableUpdate;
  final ValueChanged<VelaSection> onSelect;
  final VoidCallback? onOpenUpdate;

  @override
  State<_TvShellSidebar> createState() => _TvShellSidebarState();
}

class _TvShellSidebarState extends State<_TvShellSidebar> {
  Timer? _collapseTimer;
  var _active = false;
  var _pinned = false;

  bool get _expanded => _pinned || _active;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _open() {
    _collapseTimer?.cancel();
    if (!_active) {
      setState(() => _active = true);
    }
  }

  void _scheduleCollapse() {
    if (_pinned) {
      return;
    }
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted && !_pinned) {
        setState(() => _active = false);
      }
    });
  }

  void _handleSectionPressed(VelaSection section) {
    if (!_expanded) {
      _open();
      return;
    }
    widget.onSelect(section);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expanded = _expanded;
    final expandedWidth = widget.wide ? 230.0 : 188.0;
    return MouseRegion(
      onEnter: (_) => _open(),
      onExit: (_) => _scheduleCollapse(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: expanded ? expandedWidth : 76,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF151719),
            border: Border.all(color: const Color(0xFF292D31)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: expanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    VelaLogoMark(size: expanded ? 44 : 38),
                    if (expanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vela',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                for (final section in VelaSection.values) ...[
                  _TvSidebarItem(
                    section: section,
                    selected: section == widget.selected,
                    expanded: expanded,
                    onFocusChange: (focused) {
                      if (focused) {
                        _open();
                      } else {
                        _scheduleCollapse();
                      }
                    },
                    onPressed: () => _handleSectionPressed(section),
                  ),
                  const SizedBox(height: 10),
                ],
                const Spacer(),
                TvFocusCard(
                  onPressed: () {
                    setState(() {
                      _pinned = !_pinned;
                      _active = _pinned;
                    });
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: expanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Icon(
                        _pinned ? LucideIcons.panelLeftClose : LucideIcons.pin,
                        size: 24,
                      ),
                      if (expanded) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _pinned ? 'Unpin' : 'Pin open',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.availableUpdate != null) ...[
                  const SizedBox(height: 10),
                  TvFocusCard(
                    onPressed: () {
                      if (!expanded) {
                        _open();
                        return;
                      }
                      widget.onOpenUpdate?.call();
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    onFocusChange: (focused) {
                      if (focused) {
                        _open();
                      } else {
                        _scheduleCollapse();
                      }
                    },
                    child: Row(
                      mainAxisAlignment: expanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.download,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        if (expanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.availableUpdate!.latestVersion,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TvSidebarItem extends StatelessWidget {
  const _TvSidebarItem({
    required this.section,
    required this.selected,
    required this.expanded,
    required this.onFocusChange,
    required this.onPressed,
  });

  final VelaSection section;
  final bool selected;
  final bool expanded;
  final ValueChanged<bool> onFocusChange;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : const Color(0xFFF4F0E8);
    return TvFocusCard(
      onFocusChange: onFocusChange,
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        mainAxisAlignment: expanded
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          Icon(section.icon, color: color, size: 25),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                section.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
