import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/navigation_controller.dart';
import '../../app/section_state.dart';
import '../../catalog/catalog_models.dart';
import '../../playback/playable_item.dart';
import '../../shared/async_value_view.dart';
import '../../shared/empty_state.dart';
import '../providers/provider_setup_screen.dart';
import 'catalog_card_mapper.dart';
import 'catalog_playback_target.dart';
import 'category_list.dart';
import 'content_detail_screen.dart';
import 'detail_panel.dart';
import 'global_search.dart';
import 'item_grid.dart';
import 'live_guide_view.dart';

const _catalogCacheDuration = Duration(minutes: 10);
const _epgAutoRefreshCooldown = Duration(minutes: 15);
final _epgRefreshAttempts = <_EpgRefreshKey, _EpgRefreshAttempt>{};

final _recentCatalogCardsProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      _keepCatalogProviderWarm(ref);
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

final _catalogCardsProvider = StreamProvider.autoDispose
    .family<List<CatalogCardItem>, CatalogItemsQuery>((ref, query) {
      _keepCatalogProviderWarm(ref);
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

final _seriesEpisodesProvider = StreamProvider.autoDispose
    .family<List<CatalogEpisode>, _SeriesEpisodesQuery>((ref, query) {
      _keepCatalogProviderWarm(ref);
      return ref
          .watch(catalogRepositoryProvider)
          .watchEpisodesForSeries(
            providerId: query.providerId,
            seriesId: query.seriesId,
          );
    });

final _seriesEpisodePositionsProvider = StreamProvider.autoDispose
    .family<List<PlaybackPosition>, _SeriesEpisodesQuery>((ref, query) {
      _keepCatalogProviderWarm(ref);
      return ref
          .watch(watchHistoryRepositoryProvider)
          .watchEpisodePositionsForSeries(
            providerId: query.providerId,
            seriesId: query.seriesId,
          );
    });

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({
    required this.section,
    required this.onOpenPlayer,
    super.key,
  });

  final VelaSection section;
  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(providersProvider);

    return AsyncValueView(
      value: providers,
      data: (items) {
        final setupState = ref.watch(providerSetupImportControllerProvider);
        final hasImportedCatalog = items.any(
          (provider) => provider.hasImportedCatalog,
        );
        if (!hasImportedCatalog || setupState.shouldKeepSetupVisible) {
          return const ProviderSetupScreen();
        }
        return _CatalogContent(section: section, onOpenPlayer: onOpenPlayer);
      },
    );
  }
}

class _CatalogContent extends ConsumerWidget {
  const _CatalogContent({required this.section, required this.onOpenPlayer});

  final VelaSection section;
  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigation = ref.watch(navigationControllerProvider);
    final state = navigation.stateFor(section);
    final liveViewMode = navigation.liveViewMode;
    final liveGuideDayStartMs = navigation.liveGuideDayStartMs;
    final itemsValue = _itemsForSection(ref, section, state.selectedCategoryId);
    final categoriesValue = _categoriesForSection(ref, section);
    final globalSearchRequest = GlobalSearchRequest.fromToolbarQuery(
      state.searchQuery,
    );
    if (section == VelaSection.live) {
      _syncLiveGuideDayIfNeeded(ref, liveGuideDayStartMs);
    }

    return ColoredBox(
      color: const Color(0xFF0C0D0E),
      child: SafeArea(
        child: Column(
          children: [
            _CatalogToolbar(
              section: section,
              state: state,
              liveViewMode: liveViewMode,
            ),
            Expanded(
              child: globalSearchRequest != null
                  ? GlobalSearchResultsView(
                      request: globalSearchRequest,
                      onOpenResult: (result) =>
                          _openGlobalSearchResult(context, ref, result),
                    )
                  : AsyncValueView(
                      value: itemsValue,
                      data: (items) {
                        final visible = _filterItems(items, state.searchQuery);
                        final selected = _selectedItem(
                          visible,
                          state.selectedItemId,
                        );
                        final seriesEpisodesValue =
                            selected?.contentType == CatalogContentType.series
                            ? ref.watch(
                                _seriesEpisodesProvider(
                                  _SeriesEpisodesQuery(
                                    providerId: selected!.providerId,
                                    seriesId: selected.id,
                                  ),
                                ),
                              )
                            : const AsyncValue.data(<CatalogEpisode>[]);
                        final seriesEpisodePositionsValue =
                            selected?.contentType == CatalogContentType.series
                            ? ref.watch(
                                _seriesEpisodePositionsProvider(
                                  _SeriesEpisodesQuery(
                                    providerId: selected!.providerId,
                                    seriesId: selected.id,
                                  ),
                                ),
                              )
                            : const AsyncValue.data(<PlaybackPosition>[]);
                        final epgProgramsValue = _epgProgramsForSelected(
                          ref,
                          selected,
                          liveGuideDayStartMs,
                        );
                        final guideProgramsValue =
                            section == VelaSection.live &&
                                liveViewMode == LiveCatalogViewMode.guide
                            ? _epgProgramsForLiveGuide(
                                ref,
                                visible,
                                liveGuideDayStartMs,
                              )
                            : const AsyncValue.data(<EpgProgram>[]);
                        _refreshSeriesEpisodesIfNeeded(
                          ref,
                          selected,
                          seriesEpisodesValue,
                        );
                        _refreshEpgIfNeeded(
                          ref,
                          selected,
                          epgProgramsValue,
                          liveGuideDayStartMs,
                        );
                        if (selected != null &&
                            selected.id != state.selectedItemId) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ref
                                .read(navigationControllerProvider)
                                .selectItem(selected.id);
                          });
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (section.contentType != null)
                              _ResizableCategoryPane(
                                width: navigation.categorySidebarWidth,
                                onResize: ref
                                    .read(navigationControllerProvider)
                                    .setCategorySidebarWidth,
                                child: AsyncValueView(
                                  value: categoriesValue,
                                  data: (categories) => CategoryList(
                                    categories: categories,
                                    searchQuery: state.categorySearchQuery,
                                    selectedCategoryId:
                                        state.selectedCategoryId,
                                    onSearchChanged: ref
                                        .read(navigationControllerProvider)
                                        .setCategorySearchQuery,
                                    onSelect: ref
                                        .read(navigationControllerProvider)
                                        .selectCategory,
                                    onToggleFavorite: (category) =>
                                        _toggleCategoryFavorite(ref, category),
                                    onMove: (category, delta) => _moveCategory(
                                      ref,
                                      categories,
                                      category,
                                      delta,
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: section.contentType == null ? 30 : 0,
                                  right: section.contentType == null ? 6 : 0,
                                ),
                                child: visible.isEmpty
                                    ? EmptyState(
                                        icon: section.icon,
                                        title: section.emptyTitle,
                                        message:
                                            'No items match the current section, category, or search filter.',
                                      )
                                    : section == VelaSection.live &&
                                          liveViewMode ==
                                              LiveCatalogViewMode.guide
                                    ? LiveGuideView(
                                        items: visible,
                                        selectedItemId: selected?.id,
                                        dayStartMs: liveGuideDayStartMs,
                                        epgPrograms: guideProgramsValue,
                                        onSelect: ref
                                            .read(navigationControllerProvider)
                                            .selectItem,
                                        onOpen: (item) => _openItem(ref, item),
                                        onRefreshEpg: () =>
                                            _refreshEpgForLiveGuide(
                                              ref,
                                              visible,
                                              liveGuideDayStartMs,
                                            ),
                                        onDayChanged: ref
                                            .read(navigationControllerProvider)
                                            .setLiveGuideDayStartMs,
                                      )
                                    : ItemGrid(
                                        items: visible,
                                        selectedItemId: selected?.id,
                                        onSelect: ref
                                            .read(navigationControllerProvider)
                                            .selectItem,
                                        onOpen: (item) => _openItem(ref, item),
                                      ),
                              ),
                            ),
                            SizedBox(
                              width: 360,
                              child: DetailPanel(
                                item: selected,
                                seriesEpisodes: seriesEpisodesValue,
                                episodePositions: seriesEpisodePositionsValue,
                                epgPrograms: epgProgramsValue,
                                onPlay: (item) => _openItem(ref, item),
                                onRestart: (item) =>
                                    _openItem(ref, item, restart: true),
                                onRefreshEpg: selected == null
                                    ? null
                                    : () => _refreshEpgForSelected(
                                        ref,
                                        selected,
                                        liveGuideDayStartMs,
                                      ),
                                onOpenEpisode: (item, episode) =>
                                    _openEpisode(ref, item, episode),
                                onOpenDetails: (item) =>
                                    _openDetails(context, ref, item),
                                onToggleFavorite: (item) =>
                                    _toggleItemFavorite(ref, item),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  AsyncValue<List<CatalogCardItem>> _itemsForSection(
    WidgetRef ref,
    VelaSection section,
    String? categoryId,
  ) {
    if (section == VelaSection.recent) {
      return ref.watch(_recentCatalogCardsProvider);
    }

    if (section == VelaSection.favorites) {
      final live = ref.watch(
        _catalogCardsProvider(
          const CatalogItemsQuery(
            section: CatalogContentType.live,
            favoritesOnly: true,
          ),
        ),
      );
      final movies = ref.watch(
        _catalogCardsProvider(
          const CatalogItemsQuery(
            section: CatalogContentType.movie,
            favoritesOnly: true,
          ),
        ),
      );
      final series = ref.watch(
        _catalogCardsProvider(
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
      _catalogCardsProvider(
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

  Future<void> _openItem(
    WidgetRef ref,
    CatalogCardItem item, {
    bool restart = false,
  }) async {
    try {
      final target = await playbackTargetForCatalogCard(
        ref,
        item,
        restart: restart,
      );
      if (target == null) {
        return;
      }
      onOpenPlayer(target.playable);
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
    } catch (error, stackTrace) {
      debugPrint('Failed to open catalog item: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openEpisode(
    WidgetRef ref,
    CatalogCardItem item,
    CatalogEpisode episode,
  ) async {
    try {
      final episodes = await episodesForSeries(ref.read, item);
      final resume = await ref
          .read(watchHistoryRepositoryProvider)
          .lookupResumePosition(
            providerId: episode.providerId,
            itemId: episode.id,
            itemType: PlayableContentType.episode,
            seriesId: episode.seriesId,
            seasonId: episode.seasonId,
          );
      final target = await playbackTargetForCatalogEpisode(
        ref,
        episode: episode,
        episodes: episodes,
        fallbackPosterUrl: item.artworkUrl,
        resume: resume,
      );
      if (target == null) {
        return;
      }
      onOpenPlayer(target.playable);
    } catch (error, stackTrace) {
      debugPrint('Failed to open episode: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openDetails(
    BuildContext context,
    WidgetRef ref,
    CatalogCardItem item,
  ) async {
    if (item.contentType == CatalogContentType.live) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ContentDetailScreen(
          initialItem: item,
          onPlayItem: (target, {restart = false}) {
            return _openItem(ref, target, restart: restart);
          },
          onOpenEpisode: (target, episode) {
            return _openEpisode(ref, target, episode);
          },
        ),
      ),
    );
  }

  Future<void> _openGlobalSearchResult(
    BuildContext context,
    WidgetRef ref,
    GlobalSearchResult result,
  ) async {
    final item = result.item;
    if (item.contentType == CatalogContentType.live) {
      await _openItem(ref, item);
      return;
    }
    await _openDetails(context, ref, item);
  }
}

class _ResizableCategoryPane extends StatelessWidget {
  const _ResizableCategoryPane({
    required this.width,
    required this.onResize,
    required this.child,
  });

  final double width;
  final ValueChanged<double> onResize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: width, child: child),
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              onResize(width + details.delta.dx);
            },
            child: SizedBox(
              width: 10,
              child: Center(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34383D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogToolbar extends ConsumerStatefulWidget {
  const _CatalogToolbar({
    required this.section,
    required this.state,
    required this.liveViewMode,
  });

  final VelaSection section;
  final SectionState state;
  final LiveCatalogViewMode liveViewMode;

  @override
  ConsumerState<_CatalogToolbar> createState() => _CatalogToolbarState();
}

class _CatalogToolbarState extends ConsumerState<_CatalogToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void didUpdateWidget(_CatalogToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.searchQuery != _searchController.text) {
      _searchController
        ..text = widget.state.searchQuery
        ..selection = TextSelection.collapsed(
          offset: widget.state.searchQuery.length,
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showLiveModeToggle = widget.section == VelaSection.live;
    final globalSearchActive = GlobalSearchRequest.isGlobalToolbarQuery(
      widget.state.searchQuery,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.section.eyebrow,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.section.label,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: ref.read(navigationControllerProvider).setSearchQuery,
              decoration: InputDecoration(
                hintText: globalSearchActive
                    ? 'Global search'
                    : '${widget.section.searchPlaceholder} or / global',
                prefixIcon: Icon(
                  globalSearchActive ? LucideIcons.globe2 : LucideIcons.search,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          IconButton.filledTonal(
            tooltip: globalSearchActive
                ? 'Search this section'
                : 'Search everything',
            onPressed: () {
              final controller = ref.read(navigationControllerProvider);
              if (globalSearchActive) {
                controller.setSearchQuery(
                  GlobalSearchRequest.disableToolbarQuery(
                    widget.state.searchQuery,
                  ),
                );
              } else {
                controller.setSearchQuery(
                  GlobalSearchRequest.enableToolbarQuery(
                    widget.state.searchQuery,
                  ),
                );
              }
            },
            icon: Icon(
              globalSearchActive ? LucideIcons.search : LucideIcons.globe2,
              size: 18,
            ),
          ),
          if (showLiveModeToggle) ...[
            const SizedBox(width: 14),
            SegmentedButton<LiveCatalogViewMode>(
              segments: const [
                ButtonSegment(
                  value: LiveCatalogViewMode.list,
                  icon: Icon(LucideIcons.list, size: 17),
                  tooltip: 'List view',
                ),
                ButtonSegment(
                  value: LiveCatalogViewMode.guide,
                  icon: Icon(LucideIcons.calendarDays, size: 17),
                  tooltip: 'Guide view',
                ),
              ],
              selected: {widget.liveViewMode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                ref
                    .read(navigationControllerProvider)
                    .setLiveViewMode(selection.first);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _EpgRefreshKey {
  const _EpgRefreshKey({required this.providerId, required this.dayStartMs});

  final String providerId;
  final int dayStartMs;

  @override
  bool operator ==(Object other) {
    return other is _EpgRefreshKey &&
        other.providerId == providerId &&
        other.dayStartMs == dayStartMs;
  }

  @override
  int get hashCode => Object.hash(providerId, dayStartMs);
}

class _EpgRefreshAttempt {
  _EpgRefreshAttempt({required this.lastAttemptAtMs});

  int lastAttemptAtMs;
  bool inFlight = false;
}

class _SeriesEpisodesQuery {
  const _SeriesEpisodesQuery({
    required this.providerId,
    required this.seriesId,
  });

  final String providerId;
  final String seriesId;

  @override
  bool operator ==(Object other) {
    return other is _SeriesEpisodesQuery &&
        other.providerId == providerId &&
        other.seriesId == seriesId;
  }

  @override
  int get hashCode => Object.hash(providerId, seriesId);
}

AsyncValue<List<EpgProgram>> _epgProgramsForSelected(
  WidgetRef ref,
  CatalogCardItem? selected,
  int dayStartMs,
) {
  if (selected == null || selected.contentType != CatalogContentType.live) {
    return const AsyncValue.data(<EpgProgram>[]);
  }
  final channelIds = epgChannelAliases(selected);
  if (channelIds.isEmpty) {
    return const AsyncValue.data(<EpgProgram>[]);
  }

  return ref.watch(
    epgProgramsProvider(
      EpgProgramsQuery(
        providerId: selected.providerId,
        channelIds: channelIds,
        fromMs: dayStartMs - const Duration(hours: 3).inMilliseconds,
        toMs: dayStartMs + const Duration(days: 2).inMilliseconds,
      ),
    ),
  );
}

AsyncValue<List<EpgProgram>> _epgProgramsForLiveGuide(
  WidgetRef ref,
  List<CatalogCardItem> items,
  int dayStartMs,
) {
  final providerIds = _liveProviderIds(items);
  if (providerIds.isEmpty) {
    return const AsyncValue.data(<EpgProgram>[]);
  }

  final values = <AsyncValue<List<EpgProgram>>>[
    for (final providerId in providerIds)
      ref.watch(
        liveGuideEpgProgramsProvider(
          ProviderDayEpgProgramsQuery(
            providerId: providerId,
            dayStartMs: dayStartMs,
          ),
        ),
      ),
  ];

  final error = values.where((value) => value.hasError).firstOrNull;
  if (error != null && values.every((value) => value.value == null)) {
    return AsyncValue.error(error.error!, error.stackTrace!);
  }
  final combined = [
    for (final value in values) ...(value.value ?? const <EpgProgram>[]),
  ];
  if (combined.isEmpty && values.any((value) => value.isLoading)) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(combined);
}

void _refreshSeriesEpisodesIfNeeded(
  WidgetRef ref,
  CatalogCardItem? selected,
  AsyncValue<List<CatalogEpisode>> episodesValue,
) {
  if (selected == null || selected.contentType != CatalogContentType.series) {
    return;
  }
  final externalSeriesId =
      selected.externalId ??
      externalSeriesIdFromCatalogId(selected.providerId, selected.id);
  if (externalSeriesId == null || externalSeriesId.trim().isEmpty) {
    return;
  }

  episodesValue.whenData((episodes) {
    if (episodes.any(catalogEpisodeHasPlayableStream)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(providerRefreshServiceProvider)
            .refreshSeriesEpisodeDetails(
              providerId: selected.providerId,
              seriesId: selected.id,
              externalSeriesId: externalSeriesId,
            )
            .catchError((Object error, StackTrace stackTrace) {
              debugPrint('Failed to load series episodes: $error');
              debugPrintStack(stackTrace: stackTrace);
            }),
      );
    });
  });
}

void _refreshEpgIfNeeded(
  WidgetRef ref,
  CatalogCardItem? selected,
  AsyncValue<List<EpgProgram>> programsValue,
  int dayStartMs,
) {
  if (selected == null || selected.contentType != CatalogContentType.live) {
    return;
  }
  if (epgChannelAliases(selected).isEmpty) {
    return;
  }

  programsValue.whenData((programs) {
    if (programs.isNotEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProviderEpgGuarded(
        ref,
        providerId: selected.providerId,
        dayStartMs: dayStartMs,
        force: false,
        errorMessage: 'Failed to load channel schedule',
      );
    });
  });
}

void _refreshEpgForSelected(
  WidgetRef ref,
  CatalogCardItem selected,
  int dayStartMs,
) {
  if (selected.contentType != CatalogContentType.live) {
    return;
  }
  _refreshProviderEpgGuarded(
    ref,
    providerId: selected.providerId,
    dayStartMs: dayStartMs,
    force: true,
    errorMessage: 'Failed to refresh channel schedule',
  );
}

void _refreshEpgForLiveGuide(
  WidgetRef ref,
  List<CatalogCardItem> items,
  int dayStartMs,
) {
  for (final providerId in _liveProviderIds(items)) {
    _refreshProviderEpgGuarded(
      ref,
      providerId: providerId,
      dayStartMs: dayStartMs,
      force: true,
      errorMessage: 'Failed to refresh live guide',
    );
  }
}

Set<String> _liveProviderIds(List<CatalogCardItem> items) {
  final providerIds = <String>{};
  for (final item in items) {
    if (item.contentType == CatalogContentType.live) {
      providerIds.add(item.providerId);
    }
  }
  return providerIds;
}

void _refreshProviderEpgGuarded(
  WidgetRef ref, {
  required String providerId,
  required int dayStartMs,
  required bool force,
  required String errorMessage,
}) {
  final key = _EpgRefreshKey(providerId: providerId, dayStartMs: dayStartMs);
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final attempt = _epgRefreshAttempts.putIfAbsent(
    key,
    () => _EpgRefreshAttempt(lastAttemptAtMs: 0),
  );
  if (attempt.inFlight) {
    return;
  }
  if (!force &&
      attempt.lastAttemptAtMs > 0 &&
      nowMs - attempt.lastAttemptAtMs <
          _epgAutoRefreshCooldown.inMilliseconds) {
    return;
  }

  attempt
    ..inFlight = true
    ..lastAttemptAtMs = nowMs;
  unawaited(
    ref
        .read(providerRefreshServiceProvider)
        .refreshProviderEpg(providerId, force: force)
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('$errorMessage: $error');
          debugPrintStack(stackTrace: stackTrace);
        })
        .whenComplete(() {
          attempt.inFlight = false;
        }),
  );
}

void _syncLiveGuideDayIfNeeded(WidgetRef ref, int dayStartMs) {
  final now = DateTime.now();
  final todayStartMs = DateTime(
    now.year,
    now.month,
    now.day,
  ).millisecondsSinceEpoch;
  if (dayStartMs == todayStartMs) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(navigationControllerProvider).setLiveGuideDayStartMs(todayStartMs);
  });
}

AsyncValue<List<CatalogCardItem>> _combineCatalogItems(
  List<AsyncValue<List<CatalogCardItem>>> values,
) {
  final error = values.where((value) => value.hasError).firstOrNull;
  if (error != null) {
    return AsyncValue.error(error.error!, error.stackTrace!);
  }
  if (values.any((value) => value.isLoading)) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data([
    for (final value in values) ...(value.value ?? const <CatalogCardItem>[]),
  ]);
}

void _keepCatalogProviderWarm(Ref ref) {
  final link = ref.keepAlive();
  Timer? disposeTimer;

  ref.onCancel(() {
    disposeTimer = Timer(_catalogCacheDuration, link.close);
  });
  ref.onResume(() {
    disposeTimer?.cancel();
    disposeTimer = null;
  });
  ref.onDispose(() {
    disposeTimer?.cancel();
  });
}

List<CatalogCardItem> _filterItems(
  List<CatalogCardItem> items,
  String searchQuery,
) {
  final query = searchQuery.trim().toLowerCase();
  if (query.isEmpty) return items;
  return items.where((item) {
    return item.title.toLowerCase().contains(query) ||
        (item.subtitle?.toLowerCase().contains(query) ?? false);
  }).toList();
}

CatalogCardItem? _selectedItem(List<CatalogCardItem> items, String? id) {
  if (items.isEmpty) return null;
  if (id == null) return items.first;
  return items.where((item) => item.id == id).firstOrNull ?? items.first;
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
