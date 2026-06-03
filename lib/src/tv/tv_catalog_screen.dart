import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/navigation_controller.dart';
import '../app/section_state.dart';
import '../catalog/catalog_models.dart';
import '../features/catalog/catalog_card_mapper.dart';
import '../features/catalog/catalog_playback_target.dart';
import '../features/catalog/item_grid.dart';
import '../playback/playable_item.dart';
import 'tv_detail_panel.dart';
import 'tv_focus.dart';

const _tvCatalogCacheDuration = Duration(minutes: 10);

final _tvRecentCatalogCardsProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      _keepTvCatalogProviderWarm(ref);
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      final catalogRepository = ref.watch(catalogRepositoryProvider);
      return historyRepository.watchRecentlyWatched().asyncMap((entries) async {
        final cards = <CatalogCardItem>[];
        final seenSeries = <String>{};
        for (final entry in entries) {
          if (entry.itemType == PlayableContentType.episode &&
              entry.seriesId?.trim().isNotEmpty == true) {
            final key = '${entry.providerId}:${entry.seriesId}';
            if (!seenSeries.add(key)) {
              continue;
            }
          }
          cards.add(
            await recentToResolvedCard(
              catalogRepository,
              historyRepository,
              entry,
            ),
          );
        }
        return cards;
      });
    });

final _tvCatalogCardsProvider = StreamProvider.autoDispose
    .family<List<CatalogCardItem>, CatalogItemsQuery>((ref, query) {
      _keepTvCatalogProviderWarm(ref);
      final catalogRepository = ref.watch(catalogRepositoryProvider);
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      ref.watch(recentlyWatchedProvider);
      return catalogRepository
          .watchItems(
            providerId: query.providerId,
            section: query.section,
            categoryId: query.categoryId,
            favoritesOnly: query.favoritesOnly,
          )
          .asyncMap((items) {
            return catalogItemsToCards(
              catalogRepository,
              historyRepository,
              items,
            );
          });
    });

class TvCatalogScreen extends ConsumerWidget {
  const TvCatalogScreen({
    required this.section,
    required this.onOpenPlayer,
    super.key,
  });

  final VelaSection section;
  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(navigationControllerProvider);
    final state = navigation.stateFor(section);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TvSectionRail(
          selected: section,
          onSelect: ref.read(navigationControllerProvider).selectSection,
        ),
        const SizedBox(height: 18),
        if (section == VelaSection.settings)
          Expanded(
            child: _TvSettingsPanel(
              onOpenLive: () {
                ref
                    .read(navigationControllerProvider)
                    .selectSection(VelaSection.live);
              },
              onRefreshProviders: () => unawaited(_refreshProviders(ref)),
            ),
          )
        else ...[
          _TvCategoryRail(
            value: _categoriesForSection(ref, section),
            selectedCategoryId: state.selectedCategoryId,
            onSelect: ref.read(navigationControllerProvider).selectCategory,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _itemsForSection(ref, section, state.selectedCategoryId)
                .when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  error: (error, _) => _TvCatalogMessage(
                    icon: LucideIcons.circleAlert,
                    title: 'Catalog unavailable',
                    body: error.toString(),
                  ),
                  data: (items) {
                    final selected = _selectedItem(items, state.selectedItemId);
                    _syncSelectedItem(
                      ref,
                      section,
                      selected,
                      state.selectedItemId,
                    );
                    if (items.isEmpty) {
                      return _TvCatalogMessage(
                        icon: LucideIcons.inbox,
                        title: section.emptyTitle,
                        body: 'Nothing to show in this section.',
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final showDetailPanel = constraints.maxWidth >= 980;
                        if (!showDetailPanel) {
                          return Column(
                            children: [
                              Expanded(
                                child: _TvCatalogGrid(
                                  items: items,
                                  selected: selected,
                                  onFocusItem: (item) => _selectItem(ref, item),
                                  onOpenItem: (item) =>
                                      unawaited(_openItem(ref, item)),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 360,
                                child: TvDetailPanel(
                                  item: selected,
                                  onOpenPlayer: onOpenPlayer,
                                ),
                              ),
                            ],
                          );
                        }
                        final detailWidth = constraints.maxWidth >= 1320
                            ? 440.0
                            : 380.0;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _TvCatalogGrid(
                                items: items,
                                selected: selected,
                                onFocusItem: (item) => _selectItem(ref, item),
                                onOpenItem: (item) =>
                                    unawaited(_openItem(ref, item)),
                              ),
                            ),
                            const SizedBox(width: 22),
                            SizedBox(
                              width: detailWidth,
                              child: TvDetailPanel(
                                item: selected,
                                onOpenPlayer: onOpenPlayer,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ],
    );
  }

  AsyncValue<List<CatalogCardItem>> _itemsForSection(
    WidgetRef ref,
    VelaSection section,
    String? categoryId,
  ) {
    if (section == VelaSection.recent) {
      return ref.watch(_tvRecentCatalogCardsProvider);
    }

    if (section == VelaSection.favorites) {
      final live = ref.watch(
        _tvCatalogCardsProvider(
          const CatalogItemsQuery(
            section: CatalogContentType.live,
            favoritesOnly: true,
          ),
        ),
      );
      final movies = ref.watch(
        _tvCatalogCardsProvider(
          const CatalogItemsQuery(
            section: CatalogContentType.movie,
            favoritesOnly: true,
          ),
        ),
      );
      final series = ref.watch(
        _tvCatalogCardsProvider(
          const CatalogItemsQuery(
            section: CatalogContentType.series,
            favoritesOnly: true,
          ),
        ),
      );
      return _combineCatalogItems([live, movies, series]);
    }

    final contentType = section.contentType ?? CatalogContentType.live;
    return ref.watch(
      _tvCatalogCardsProvider(
        CatalogItemsQuery(section: contentType, categoryId: categoryId),
      ),
    );
  }

  AsyncValue<List<CatalogCategory>> _categoriesForSection(
    WidgetRef ref,
    VelaSection section,
  ) {
    final contentType = section.contentType;
    if (contentType == null) {
      return const AsyncValue.data([]);
    }
    return ref.watch(
      categoriesProvider(CategoryQuery(contentType: contentType)),
    );
  }

  void _selectItem(WidgetRef ref, CatalogCardItem item) {
    ref.read(navigationControllerProvider).selectItem(item.id);
  }

  void _syncSelectedItem(
    WidgetRef ref,
    VelaSection section,
    CatalogCardItem? selected,
    String? selectedItemId,
  ) {
    if (selected == null || selected.id == selectedItemId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigation = ref.read(navigationControllerProvider);
      if (navigation.selectedSection == section) {
        navigation.selectItem(selected.id);
      }
    });
  }

  Future<void> _openItem(WidgetRef ref, CatalogCardItem item) async {
    if (item.contentType == CatalogContentType.series) {
      _selectItem(ref, item);
    }

    try {
      final target = await playbackTargetForCatalogCard(ref, item);
      if (target == null) return;
      final history = target.history;
      if (history != null) {
        unawaited(
          ref
              .read(watchHistoryRepositoryProvider)
              .addOrUpdateWatchHistory(history)
              .catchError((Object error, StackTrace stackTrace) {
                debugPrint('Failed to update watch history: $error');
                debugPrintStack(stackTrace: stackTrace);
              }),
        );
      }
      onOpenPlayer(target.playable);
    } catch (error, stackTrace) {
      debugPrint('Failed to open TV catalog item: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _refreshProviders(WidgetRef ref) async {
    try {
      await ref
          .read(providerRefreshServiceProvider)
          .refreshStaleProvidersOnLaunch();
    } catch (error, stackTrace) {
      debugPrint('Failed to refresh providers: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

class _TvSectionRail extends StatelessWidget {
  const _TvSectionRail({required this.selected, required this.onSelect});

  final VelaSection selected;
  final ValueChanged<VelaSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: VelaSection.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final section = VelaSection.values[index];
          final isSelected = section == selected;
          return SizedBox(
            width: 188,
            child: TvFocusCard(
              autofocus: index == selected.index,
              onPressed: () => onSelect(section),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    section.icon,
                    size: 28,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : const Color(0xFFE7B85B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TvCategoryRail extends StatelessWidget {
  const _TvCategoryRail({
    required this.value,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final AsyncValue<List<CatalogCategory>> value;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: value.when(
        loading: () => const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 220,
            child: LinearProgressIndicator(minHeight: 3),
          ),
        ),
        error: (error, _) => Text(
          error.toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        data: (categories) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _TvCategoryButton(
                  label: 'All',
                  selected: selectedCategoryId == null,
                  onPressed: () => onSelect(null),
                );
              }
              final category = categories[index - 1];
              return _TvCategoryButton(
                label: category.name,
                selected: selectedCategoryId == category.id,
                onPressed: () => onSelect(category.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _TvCategoryButton extends StatelessWidget {
  const _TvCategoryButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: label == 'All' ? 128 : 220,
      child: TvFocusCard(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (selected) ...[
              Icon(
                LucideIcons.check,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  height: 1.05,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvCatalogGrid extends StatelessWidget {
  const _TvCatalogGrid({
    required this.items,
    required this.selected,
    required this.onFocusItem,
    required this.onOpenItem,
  });

  final List<CatalogCardItem> items;
  final CatalogCardItem? selected;
  final ValueChanged<CatalogCardItem> onFocusItem;
  final ValueChanged<CatalogCardItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 210,
        mainAxisExtent: 260,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _TvContentCard(
          item: item,
          selected: selected?.id == item.id,
          autofocus: index == 0,
          onFocus: () => onFocusItem(item),
          onPressed: () => onOpenItem(item),
        );
      },
    );
  }
}

class _TvContentCard extends StatelessWidget {
  const _TvContentCard({
    required this.item,
    required this.selected,
    required this.onFocus,
    required this.onPressed,
    this.autofocus = false,
  });

  final CatalogCardItem item;
  final bool selected;
  final VoidCallback onFocus;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onPressed();
            return null;
          },
        ),
      },
      autofocus: autofocus,
      mouseCursor: SystemMouseCursors.click,
      onFocusChange: (focused) {
        if (focused) {
          onFocus();
        }
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
      },
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          final highlighted = focused || selected;
          return Material(
            color: highlighted
                ? const Color(0xFF1F211E)
                : const Color(0xFF151719),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(8),
              canRequestFocus: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: focused
                        ? theme.colorScheme.primary
                        : selected
                        ? const Color(0xFFE7B85B)
                        : const Color(0xFF292D31),
                    width: focused ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _TvCatalogArtwork(item: item)),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _secondaryLabel(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFA9A39A),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TvCatalogArtwork extends StatelessWidget {
  const _TvCatalogArtwork({required this.item});

  final CatalogCardItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.contentType) {
      CatalogContentType.live => LucideIcons.tv,
      CatalogContentType.movie => LucideIcons.film,
      CatalogContentType.series => LucideIcons.library,
    };
    final isLive = item.contentType == CatalogContentType.live;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF0C0D0E)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.hasArtwork)
              Image.network(
                item.artworkUrl!,
                fit: isLive ? BoxFit.contain : BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(icon, color: const Color(0xFF716D66), size: 36),
              )
            else
              Icon(icon, color: const Color(0xFF716D66), size: 36),
            Positioned(
              right: 8,
              top: 8,
              child: Icon(
                item.isFavorite ? LucideIcons.star : icon,
                size: 18,
                color: item.isFavorite
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0x99FFFFFF),
              ),
            ),
            if (item.canPlay)
              Positioned(
                right: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      LucideIcons.play,
                      size: 13,
                      color: Color(0xFF0C0D0E),
                    ),
                  ),
                ),
              ),
            if (item.hasResumeProgress)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: item.resumeProgress,
                  backgroundColor: const Color(0x99000000),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TvSettingsPanel extends StatelessWidget {
  const _TvSettingsPanel({
    required this.onOpenLive,
    required this.onRefreshProviders,
  });

  final VoidCallback onOpenLive;
  final VoidCallback onRefreshProviders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TvFocusCard(
            autofocus: true,
            onPressed: onRefreshProviders,
            padding: const EdgeInsets.all(24),
            child: _TvSettingsAction(
              icon: LucideIcons.refreshCw,
              title: 'Refresh Providers',
              body: 'Update stale catalogs and episode details.',
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: TvFocusCard(
            onPressed: onOpenLive,
            padding: const EdgeInsets.all(24),
            child: _TvSettingsAction(
              icon: LucideIcons.tv,
              title: 'Open Live TV',
              body: 'Return to the channel catalog.',
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF151719),
              border: Border.all(color: const Color(0xFF292D31)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.settings,
                    size: 34,
                    color: theme.colorScheme.primary,
                  ),
                  const Spacer(),
                  Text(
                    'Settings',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Provider maintenance is available here. Detailed preferences remain in the desktop settings area for now.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFAFA8A0),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TvSettingsAction extends StatelessWidget {
  const _TvSettingsAction({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 34, color: theme.colorScheme.primary),
        const Spacer(),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFAFA8A0),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _TvCatalogMessage extends StatelessWidget {
  const _TvCatalogMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFAFA8A0),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

AsyncValue<List<CatalogCardItem>> _combineCatalogItems(
  List<AsyncValue<List<CatalogCardItem>>> values,
) {
  for (final value in values) {
    if (value.hasError) {
      return AsyncValue.error(value.error!, value.stackTrace!);
    }
  }
  if (values.any((value) => value.isLoading)) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data([
    for (final value in values) ...(value.value ?? const <CatalogCardItem>[]),
  ]);
}

CatalogCardItem? _selectedItem(List<CatalogCardItem> items, String? id) {
  if (items.isEmpty) return null;
  if (id == null) return items.first;
  for (final item in items) {
    if (item.id == id) {
      return item;
    }
  }
  return items.first;
}

String _secondaryLabel(CatalogCardItem item) {
  return item.epgSummary ??
      item.seriesPlaybackSummary ??
      item.subtitle ??
      _contentLabel(item.contentType);
}

String _contentLabel(CatalogContentType type) {
  return switch (type) {
    CatalogContentType.live => 'Live channel',
    CatalogContentType.movie => 'Movie',
    CatalogContentType.series => 'Series',
  };
}

void _keepTvCatalogProviderWarm(Ref ref) {
  final link = ref.keepAlive();
  Timer? disposeTimer;

  ref.onCancel(() {
    disposeTimer = Timer(_tvCatalogCacheDuration, link.close);
  });
  ref.onResume(() {
    disposeTimer?.cancel();
    disposeTimer = null;
  });
  ref.onDispose(() {
    disposeTimer?.cancel();
  });
}
