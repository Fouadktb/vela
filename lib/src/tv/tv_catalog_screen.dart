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
const _tvCatalogInitialLimit = 160;
const _tvCatalogLimitStep = 160;

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
            limit: query.limit,
          )
          .asyncMap((items) {
            return catalogItemsToCards(
              catalogRepository,
              historyRepository,
              items,
            );
          });
    });

class TvCatalogScreen extends ConsumerStatefulWidget {
  const TvCatalogScreen({
    required this.section,
    required this.onOpenPlayer,
    this.persistentCategories = false,
    super.key,
  });

  final VelaSection section;
  final ValueChanged<PlayableItem> onOpenPlayer;
  final bool persistentCategories;

  @override
  ConsumerState<TvCatalogScreen> createState() => _TvCatalogScreenState();
}

class _TvCatalogScreenState extends ConsumerState<TvCatalogScreen> {
  int _itemLimit = _tvCatalogInitialLimit;
  String? _lastCatalogScope;
  DateTime? _lastLoadMoreAt;

  @override
  Widget build(BuildContext context) {
    final navigation = ref.watch(navigationControllerProvider);
    final section = widget.section;
    final state = navigation.stateFor(section);
    _resetLimitIfScopeChanged(section, state.selectedCategoryId);
    final categoriesValue = _categoriesForSection(ref, section);
    final selectedCategoryLabel = _selectedCategoryLabel(
      categoriesValue.value,
      state.selectedCategoryId,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final usePersistentCategories =
            widget.persistentCategories &&
            constraints.maxWidth >= 700 &&
            section.contentType != null;
        final content = _buildSectionContent(ref, section, state);

        if (usePersistentCategories) {
          final categoryWidth = constraints.maxWidth >= 1360
              ? 360.0
              : constraints.maxWidth >= 1100
              ? 320.0
              : constraints.maxWidth >= 860
              ? 280.0
              : 240.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: categoryWidth,
                child: _TvPersistentCategoryColumn(
                  section: section,
                  selectedCategoryId: state.selectedCategoryId,
                  categoriesValue: categoriesValue,
                  onSelectCategory: (categoryId) {
                    ref
                        .read(navigationControllerProvider)
                        .selectCategory(categoryId);
                  },
                  onTogglePinned: (category) =>
                      unawaited(_toggleCategoryFavorite(ref, category)),
                  onMove: (categories, category, direction) => unawaited(
                    _moveCategory(ref, categories, category, direction),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(child: content),
            ],
          );
        }

        if (widget.persistentCategories) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (section.contentType != null) ...[
                _TvCompactCategoryButton(
                  selectedCategoryLabel: selectedCategoryLabel,
                  onOpenCategories: () => _openCategorySheet(
                    context,
                    ref,
                    section: section,
                    selectedCategoryId: state.selectedCategoryId,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(child: content),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TvBrowseBar(
              selected: section,
              onSelect: ref.read(navigationControllerProvider).selectSection,
              selectedCategoryLabel: selectedCategoryLabel,
              categoryEnabled: section.contentType != null,
              onOpenCategories: () => _openCategorySheet(
                context,
                ref,
                section: section,
                selectedCategoryId: state.selectedCategoryId,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  Widget _buildSectionContent(
    WidgetRef ref,
    VelaSection section,
    SectionState state,
  ) {
    if (section == VelaSection.settings) {
      return _TvSettingsPanel(
        onOpenLive: () {
          ref
              .read(navigationControllerProvider)
              .selectSection(VelaSection.live);
        },
        onRefreshProviders: () => unawaited(_refreshProviders(ref)),
      );
    }

    return _itemsForSection(
      ref,
      section,
      state.selectedCategoryId,
      limit: _itemLimit,
    ).when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (error, _) => _TvCatalogMessage(
        icon: LucideIcons.circleAlert,
        title: 'Catalog unavailable',
        body: error.toString(),
      ),
      data: (items) {
        final selected = _selectedItem(items, state.selectedItemId);
        final hasMore = _sectionCanPage(section) && items.length >= _itemLimit;
        _syncSelectedItem(ref, section, selected, state.selectedItemId);
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
              return _TvCatalogGrid(
                items: items,
                selected: selected,
                hasMore: hasMore,
                onFocusItem: (item) => _selectItem(ref, item),
                onOpenItem: (item) => unawaited(_openItem(ref, item)),
                onToggleFavorite: (item) =>
                    unawaited(_toggleItemFavorite(ref, item)),
                onLoadMore: _loadMore,
              );
            }
            final detailWidth = constraints.maxWidth >= 1320 ? 440.0 : 380.0;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TvCatalogGrid(
                    items: items,
                    selected: selected,
                    hasMore: hasMore,
                    onFocusItem: (item) => _selectItem(ref, item),
                    onOpenItem: (item) => unawaited(_openItem(ref, item)),
                    onToggleFavorite: (item) =>
                        unawaited(_toggleItemFavorite(ref, item)),
                    onLoadMore: _loadMore,
                  ),
                ),
                const SizedBox(width: 22),
                SizedBox(
                  width: detailWidth,
                  child: TvDetailPanel(
                    item: selected,
                    onOpenPlayer: widget.onOpenPlayer,
                    onToggleFavorite: selected == null
                        ? null
                        : () => unawaited(_toggleItemFavorite(ref, selected)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  AsyncValue<List<CatalogCardItem>> _itemsForSection(
    WidgetRef ref,
    VelaSection section,
    String? categoryId, {
    required int limit,
  }) {
    if (section == VelaSection.recent) {
      return ref.watch(_tvRecentCatalogCardsProvider);
    }

    if (section == VelaSection.favorites) {
      final live = ref.watch(
        _tvCatalogCardsProvider(
          CatalogItemsQuery(
            section: CatalogContentType.live,
            favoritesOnly: true,
            limit: limit,
          ),
        ),
      );
      final movies = ref.watch(
        _tvCatalogCardsProvider(
          CatalogItemsQuery(
            section: CatalogContentType.movie,
            favoritesOnly: true,
            limit: limit,
          ),
        ),
      );
      final series = ref.watch(
        _tvCatalogCardsProvider(
          CatalogItemsQuery(
            section: CatalogContentType.series,
            favoritesOnly: true,
            limit: limit,
          ),
        ),
      );
      return _combineCatalogItems([live, movies, series]);
    }

    final contentType = section.contentType ?? CatalogContentType.live;
    return ref.watch(
      _tvCatalogCardsProvider(
        CatalogItemsQuery(
          section: contentType,
          categoryId: categoryId,
          limit: limit,
        ),
      ),
    );
  }

  void _resetLimitIfScopeChanged(VelaSection section, String? categoryId) {
    final scope = '${section.name}:${categoryId ?? 'all'}';
    if (_lastCatalogScope == scope) return;
    _lastCatalogScope = scope;
    _itemLimit = _tvCatalogInitialLimit;
    _lastLoadMoreAt = null;
  }

  bool _sectionCanPage(VelaSection section) {
    return section != VelaSection.recent && section != VelaSection.settings;
  }

  void _loadMore() {
    final now = DateTime.now();
    final lastLoadMoreAt = _lastLoadMoreAt;
    if (lastLoadMoreAt != null &&
        now.difference(lastLoadMoreAt) < const Duration(milliseconds: 450)) {
      return;
    }
    _lastLoadMoreAt = now;
    setState(() {
      _itemLimit += _tvCatalogLimitStep;
    });
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
      widget.onOpenPlayer(target.playable);
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

class _TvBrowseBar extends StatelessWidget {
  const _TvBrowseBar({
    required this.selected,
    required this.onSelect,
    required this.selectedCategoryLabel,
    required this.categoryEnabled,
    required this.onOpenCategories,
  });

  final VelaSection selected;
  final ValueChanged<VelaSection> onSelect;
  final String selectedCategoryLabel;
  final bool categoryEnabled;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: VelaSection.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final section = VelaSection.values[index];
                final isSelected = section == selected;
                return SizedBox(
                  width: 162,
                  child: TvFocusCard(
                    autofocus: index == selected.index,
                    onPressed: () => onSelect(section),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          section.icon,
                          size: 24,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : const Color(0xFFE7B85B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            section.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (categoryEnabled) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 286,
              child: TvFocusCard(
                onPressed: onOpenCategories,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.listFilter,
                      size: 24,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedCategoryLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.chevronDown, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TvCompactCategoryButton extends StatelessWidget {
  const _TvCompactCategoryButton({
    required this.selectedCategoryLabel,
    required this.onOpenCategories,
  });

  final String selectedCategoryLabel;
  final VoidCallback onOpenCategories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocusCard(
      onPressed: onOpenCategories,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            LucideIcons.listFilter,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedCategoryLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronDown, size: 20),
        ],
      ),
    );
  }
}

class _TvPersistentCategoryColumn extends StatelessWidget {
  const _TvPersistentCategoryColumn({
    required this.section,
    required this.selectedCategoryId,
    required this.categoriesValue,
    required this.onSelectCategory,
    required this.onTogglePinned,
    required this.onMove,
  });

  final VelaSection section;
  final String? selectedCategoryId;
  final AsyncValue<List<CatalogCategory>> categoriesValue;
  final ValueChanged<String?> onSelectCategory;
  final ValueChanged<CatalogCategory> onTogglePinned;
  final void Function(
    List<CatalogCategory> categories,
    CatalogCategory category,
    int direction,
  )
  onMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111315),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.listFilter,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${section.label} categories',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: categoriesValue.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                error: (error, _) => _TvCatalogMessage(
                  icon: LucideIcons.circleAlert,
                  title: 'Categories unavailable',
                  body: error.toString(),
                ),
                data: (categories) {
                  final orderedCategories = _favoritePinnedCategories(
                    categories,
                  );
                  final totalCount = categories.fold<int>(
                    0,
                    (count, category) => count + category.itemCount,
                  );
                  return ListView.separated(
                    itemCount: orderedCategories.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _TvCategorySheetRow(
                          label: 'All categories',
                          count: totalCount,
                          selected: selectedCategoryId == null,
                          pinned: false,
                          onSelect: () => onSelectCategory(null),
                        );
                      }
                      final category = orderedCategories[index - 1];
                      final canMoveUp =
                          index > 1 &&
                          orderedCategories[index - 2].isFavorite ==
                              category.isFavorite;
                      final canMoveDown =
                          index < orderedCategories.length &&
                          orderedCategories[index].isFavorite ==
                              category.isFavorite;
                      return _TvCategorySheetRow(
                        label: category.name,
                        count: category.itemCount,
                        selected: selectedCategoryId == category.id,
                        pinned: category.isFavorite,
                        onSelect: () => onSelectCategory(category.id),
                        onTogglePinned: () => onTogglePinned(category),
                        onMoveUp: canMoveUp
                            ? () => onMove(categories, category, -1)
                            : null,
                        onMoveDown: canMoveDown
                            ? () => onMove(categories, category, 1)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvCategorySheet extends ConsumerStatefulWidget {
  const _TvCategorySheet({
    required this.section,
    required this.selectedCategoryId,
  });

  final VelaSection section;
  final String? selectedCategoryId;

  @override
  ConsumerState<_TvCategorySheet> createState() => _TvCategorySheetState();
}

class _TvCategorySheetState extends ConsumerState<_TvCategorySheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentType = widget.section.contentType;
    final theme = Theme.of(context);
    final categoriesValue = contentType == null
        ? const AsyncValue<List<CatalogCategory>>.data([])
        : ref.watch(
            categoriesProvider(CategoryQuery(contentType: contentType)),
          );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: categoriesValue.when(
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
          ),
          error: (error, _) => _TvCatalogMessage(
            icon: LucideIcons.circleAlert,
            title: 'Categories unavailable',
            body: error.toString(),
          ),
          data: (categories) {
            final orderedCategories = _favoritePinnedCategories(categories);
            final query = _query.trim().toLowerCase();
            final visibleCategories = query.isEmpty
                ? orderedCategories
                : orderedCategories
                      .where(
                        (category) =>
                            category.name.toLowerCase().contains(query),
                      )
                      .toList();
            final totalCount = categories.fold<int>(
              0,
              (count, category) => count + category.itemCount,
            );
            final reorderDisabled = query.isNotEmpty;

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.listFilter,
                        size: 30,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.section.label} categories',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    autofocus: false,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search categories',
                      prefixIcon: Icon(LucideIcons.search),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TvCategorySheetRow(
                    label: 'All',
                    count: totalCount,
                    selected: widget.selectedCategoryId == null,
                    pinned: false,
                    onSelect: () {
                      ref
                          .read(navigationControllerProvider)
                          .selectCategory(null);
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: visibleCategories.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final category = visibleCategories[index];
                        final canMoveUp =
                            !reorderDisabled &&
                            index > 0 &&
                            visibleCategories[index - 1].isFavorite ==
                                category.isFavorite;
                        final canMoveDown =
                            !reorderDisabled &&
                            index < visibleCategories.length - 1 &&
                            visibleCategories[index + 1].isFavorite ==
                                category.isFavorite;
                        return _TvCategorySheetRow(
                          label: category.name,
                          count: category.itemCount,
                          selected: widget.selectedCategoryId == category.id,
                          pinned: category.isFavorite,
                          onSelect: () {
                            ref
                                .read(navigationControllerProvider)
                                .selectCategory(category.id);
                            Navigator.of(context).pop();
                          },
                          onTogglePinned: () =>
                              unawaited(_toggleCategoryFavorite(ref, category)),
                          onMoveUp: canMoveUp
                              ? () => unawaited(
                                  _moveCategory(ref, categories, category, -1),
                                )
                              : null,
                          onMoveDown: canMoveDown
                              ? () => unawaited(
                                  _moveCategory(ref, categories, category, 1),
                                )
                              : null,
                          reorderDisabled: reorderDisabled,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TvCategorySheetRow extends StatelessWidget {
  const _TvCategorySheetRow({
    required this.label,
    required this.count,
    required this.selected,
    required this.pinned,
    required this.onSelect,
    this.onTogglePinned,
    this.onMoveUp,
    this.onMoveDown,
    this.reorderDisabled = false,
  });

  final String label;
  final int count;
  final bool selected;
  final bool pinned;
  final VoidCallback onSelect;
  final VoidCallback? onTogglePinned;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool reorderDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? const Color(0xFF25211A) : const Color(0xFF151719),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              if (selected) ...[
                Icon(
                  LucideIcons.check,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: selected ? theme.colorScheme.primary : null,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                count.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFA9A39A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onTogglePinned != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: pinned ? 'Unpin category' : 'Pin category',
                  onPressed: onTogglePinned,
                  icon: Icon(
                    LucideIcons.star,
                    color: pinned
                        ? theme.colorScheme.primary
                        : const Color(0xFF716D66),
                  ),
                ),
                IconButton(
                  tooltip: reorderDisabled
                      ? 'Clear search to move category'
                      : 'Move up',
                  onPressed: onMoveUp,
                  icon: const Icon(LucideIcons.chevronUp),
                ),
                IconButton(
                  tooltip: reorderDisabled
                      ? 'Clear search to move category'
                      : 'Move down',
                  onPressed: onMoveDown,
                  icon: const Icon(LucideIcons.chevronDown),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openCategorySheet(
  BuildContext context,
  WidgetRef ref, {
  required VelaSection section,
  required String? selectedCategoryId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111315),
    barrierColor: const Color(0xCC000000),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
    ),
    builder: (_) {
      return _TvCategorySheet(
        section: section,
        selectedCategoryId: selectedCategoryId,
      );
    },
  );
}

String _selectedCategoryLabel(
  List<CatalogCategory>? categories,
  String? selectedCategoryId,
) {
  if (selectedCategoryId == null) {
    return 'All categories';
  }
  for (final category in categories ?? const <CatalogCategory>[]) {
    if (category.id == selectedCategoryId) {
      return category.name;
    }
  }
  return 'Selected category';
}

Future<void> _toggleCategoryFavorite(WidgetRef ref, CatalogCategory category) {
  return ref
      .read(categoryRepositoryProvider)
      .toggleCategoryFavorite(
        providerId: category.providerId,
        contentType: category.contentType,
        categoryId: category.id,
      );
}

Future<void> _moveCategory(
  WidgetRef ref,
  List<CatalogCategory> categories,
  CatalogCategory category,
  int delta,
) async {
  final scoped = _favoritePinnedCategories(
    categories
        .where(
          (candidate) =>
              candidate.providerId == category.providerId &&
              candidate.contentType == category.contentType,
        )
        .toList(),
  );
  final index = scoped.indexWhere((candidate) => candidate.id == category.id);
  final nextIndex = index + delta;
  if (index < 0 || nextIndex < 0 || nextIndex >= scoped.length) return;
  if (scoped[nextIndex].isFavorite != category.isFavorite) return;
  final ids = scoped.map((candidate) => candidate.id).toList();
  final moved = ids.removeAt(index);
  ids.insert(nextIndex, moved);
  await ref
      .read(categoryRepositoryProvider)
      .reorderCategories(
        providerId: category.providerId,
        contentType: category.contentType,
        categoryIds: ids,
      );
}

List<CatalogCategory> _favoritePinnedCategories(
  List<CatalogCategory> categories,
) {
  return [
    ...categories.where((category) => category.isFavorite),
    ...categories.where((category) => !category.isFavorite),
  ];
}

Future<void> _toggleItemFavorite(WidgetRef ref, CatalogCardItem item) {
  return ref
      .read(catalogRepositoryProvider)
      .toggleItemFavorite(
        providerId: item.providerId,
        itemId: item.id,
        itemType: FavoriteItemType.fromCatalog(item.contentType),
      );
}

class _TvCatalogGrid extends StatelessWidget {
  const _TvCatalogGrid({
    required this.items,
    required this.selected,
    required this.hasMore,
    required this.onFocusItem,
    required this.onOpenItem,
    required this.onToggleFavorite,
    required this.onLoadMore,
  });

  final List<CatalogCardItem> items;
  final CatalogCardItem? selected;
  final bool hasMore;
  final ValueChanged<CatalogCardItem> onFocusItem;
  final ValueChanged<CatalogCardItem> onOpenItem;
  final ValueChanged<CatalogCardItem> onToggleFavorite;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasMore &&
            notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 1200) {
          onLoadMore();
        }
        return false;
      },
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 210,
          mainAxisExtent: 260,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return _TvLoadMoreCard(
              loadedCount: items.length,
              onPressed: onLoadMore,
            );
          }
          final item = items[index];
          return _TvContentCard(
            item: item,
            selected: selected?.id == item.id,
            autofocus: index == 0,
            onFocus: () => onFocusItem(item),
            onPressed: () => onOpenItem(item),
            onToggleFavorite: () => onToggleFavorite(item),
          );
        },
      ),
    );
  }
}

class _TvLoadMoreCard extends StatelessWidget {
  const _TvLoadMoreCard({required this.loadedCount, required this.onPressed});

  final int loadedCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocusCard(
      onPressed: onPressed,
      onFocusChange: (focused) {
        if (focused) {
          _ensureFocusedVisible(context);
        }
      },
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.plus, size: 34, color: theme.colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            'Load more',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$loadedCount loaded',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFA9A39A),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TvContentCard extends StatelessWidget {
  const _TvContentCard({
    required this.item,
    required this.selected,
    required this.onFocus,
    required this.onPressed,
    required this.onToggleFavorite,
    this.autofocus = false,
  });

  final CatalogCardItem item;
  final bool selected;
  final VoidCallback onFocus;
  final VoidCallback onPressed;
  final VoidCallback onToggleFavorite;
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
          _ensureFocusedVisible(context);
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InkWell(
                      onTap: onPressed,
                      onLongPress: onToggleFavorite,
                      borderRadius: BorderRadius.circular(8),
                      canRequestFocus: false,
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
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      tooltip: item.isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        LucideIcons.star,
                        size: 18,
                        fill: item.isFavorite ? 1 : 0,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(38, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: item.isFavorite
                            ? theme.colorScheme.primary
                            : const Color(0xFFEDE8DF),
                        backgroundColor: const Color(0xCC111315),
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
    final tiles = [
      TvFocusCard(
        autofocus: true,
        onPressed: onRefreshProviders,
        padding: const EdgeInsets.all(22),
        child: _TvSettingsAction(
          icon: LucideIcons.refreshCw,
          title: 'Refresh Providers',
          body: 'Update stale catalogs and episode details.',
        ),
      ),
      TvFocusCard(
        onPressed: onOpenLive,
        padding: const EdgeInsets.all(22),
        child: _TvSettingsAction(
          icon: LucideIcons.tv,
          title: 'Open Live TV',
          body: 'Return to the channel catalog.',
        ),
      ),
      TvFocusCard(
        onPressed: () {},
        padding: const EdgeInsets.all(22),
        child: _TvSettingsAction(
          icon: LucideIcons.settings,
          title: 'Settings',
          body:
              'Provider maintenance is available here. More TV preferences will live in this menu.',
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 840) {
          return ListView.separated(
            itemCount: tiles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (_, index) =>
                SizedBox(height: 190, child: tiles[index]),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < tiles.length; index += 1) ...[
              Expanded(child: tiles[index]),
              if (index != tiles.length - 1) const SizedBox(width: 18),
            ],
          ],
        );
      },
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

void _ensureFocusedVisible(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      alignment: 0.12,
    );
  });
}
