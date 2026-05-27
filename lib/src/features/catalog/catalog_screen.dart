import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/navigation_controller.dart';
import '../../app/section_state.dart';
import '../../catalog/catalog_models.dart';
import '../../catalog/catalog_repository.dart';
import '../../catalog/watch_history_repository.dart';
import '../../playback/playable_item.dart';
import '../../providers/xtream/xtream_client.dart';
import '../../shared/async_value_view.dart';
import '../../shared/empty_state.dart';
import '../providers/provider_setup_screen.dart';
import 'category_list.dart';
import 'detail_panel.dart';
import 'item_grid.dart';

final _recentCatalogCardsProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      final catalogRepository = ref.watch(catalogRepositoryProvider);
      return historyRepository.watchRecentlyWatched().asyncMap((entries) async {
        final cards = <CatalogCardItem>[];
        for (final entry in entries) {
          cards.add(await _recentToResolvedCard(catalogRepository, entry));
        }
        return cards;
      });
    });

final _catalogCardsProvider = StreamProvider.autoDispose
    .family<List<CatalogCardItem>, CatalogItemsQuery>((ref, query) {
      final catalogRepository = ref.watch(catalogRepositoryProvider);
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      return catalogRepository
          .watchItems(
            providerId: query.providerId,
            section: query.section,
            categoryId: query.categoryId,
            favoritesOnly: query.favoritesOnly,
          )
          .asyncMap((items) {
            return _catalogItemsToCards(historyRepository, items);
          });
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
    final itemsValue = _itemsForSection(ref, section, state.selectedCategoryId);
    final categoriesValue = _categoriesForSection(ref, section);

    return ColoredBox(
      color: const Color(0xFF0C0D0E),
      child: SafeArea(
        child: Column(
          children: [
            _CatalogToolbar(section: section, state: state),
            Expanded(
              child: AsyncValueView(
                value: itemsValue,
                data: (items) {
                  final visible = _filterItems(items, state.searchQuery);
                  final selected = _selectedItem(visible, state.selectedItemId);
                  if (selected != null && selected.id != state.selectedItemId) {
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
                        SizedBox(
                          width: 292,
                          child: AsyncValueView(
                            value: categoriesValue,
                            data: (categories) => CategoryList(
                              categories: categories,
                              searchQuery: state.categorySearchQuery,
                              selectedCategoryId: state.selectedCategoryId,
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
                        child: visible.isEmpty
                            ? EmptyState(
                                icon: section.icon,
                                title: section.emptyTitle,
                                message:
                                    'No items match the current section, category, or search filter.',
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
                      SizedBox(
                        width: 360,
                        child: DetailPanel(
                          item: selected,
                          onPlay: (item) => _openItem(ref, item),
                          onRestart: (item) =>
                              _openItem(ref, item, restart: true),
                          onToggleFavorite: (item) =>
                              _toggleItemFavorite(ref, item),
                          onRefreshProvider: () {
                            final providerId = selected?.providerId;
                            if (providerId != null) {
                              ref
                                  .read(providerRefreshServiceProvider)
                                  .refreshProvider(providerId);
                            }
                          },
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
      final target = await _playbackTargetForCard(ref, item, restart: restart);
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
}

class _CatalogToolbar extends ConsumerWidget {
  const _CatalogToolbar({required this.section, required this.state});

  final VelaSection section;
  final SectionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
                  section.eyebrow,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  section.label,
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
              onChanged: ref.read(navigationControllerProvider).setSearchQuery,
              controller: TextEditingController(text: state.searchQuery)
                ..selection = TextSelection.collapsed(
                  offset: state.searchQuery.length,
                ),
              decoration: InputDecoration(
                hintText: section.searchPlaceholder,
                prefixIcon: const Icon(LucideIcons.search),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackTarget {
  const _PlaybackTarget({required this.playable, required this.history});

  final PlayableItem playable;
  final WatchHistoryUpdate? history;
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

Future<List<CatalogCardItem>> _catalogItemsToCards(
  WatchHistoryRepository historyRepository,
  List<CatalogItem> items,
) async {
  final cards = <CatalogCardItem>[];
  for (final item in items) {
    if (item.contentType != CatalogContentType.series) {
      cards.add(
        _catalogItemToCard(
          item,
          resume: item.contentType == CatalogContentType.movie
              ? await historyRepository.lookupResumePosition(
                  providerId: item.providerId,
                  itemId: item.id,
                  itemType: PlayableContentType.movie,
                )
              : null,
        ),
      );
      continue;
    }
    final latestResume = await historyRepository.lookupLatestResumeForSeries(
      providerId: item.providerId,
      seriesId: item.id,
    );
    cards.add(
      _catalogItemToCard(item, canPlayOverride: true, resume: latestResume),
    );
  }
  return cards;
}

CatalogCardItem _catalogItemToCard(
  CatalogItem item, {
  bool? canPlayOverride,
  PlaybackPosition? resume,
}) {
  return CatalogCardItem(
    id: item.id,
    providerId: item.providerId,
    contentType: item.contentType,
    title: item.title,
    externalId: item.externalId,
    subtitle: _subtitleFor(item),
    description: item.description,
    artworkUrl: item.artworkUrl,
    streamUrl: item.streamUrl,
    streamJson: item.streamJson,
    year: item.year,
    rating: item.rating,
    durationSeconds: item.durationSeconds,
    epgSummary: item.contentType == CatalogContentType.live
        ? item.subtitle ?? item.description ?? item.epgChannelId
        : null,
    resumePositionSeconds: resume?.positionSeconds ?? 0,
    resumeDurationSeconds: resume?.durationSeconds,
    isFavorite: item.isFavorite,
    canPlay:
        canPlayOverride ??
        _hasPlayableStream(
          streamUrl: item.streamUrl,
          streamJson: item.streamJson,
        ),
  );
}

Future<CatalogCardItem> _recentToResolvedCard(
  CatalogRepository catalogRepository,
  WatchHistoryEntry entry,
) async {
  final resolved = await _resolveRecentCatalogItem(catalogRepository, entry);
  if (resolved != null) {
    final card = _catalogItemToCard(resolved);
    return CatalogCardItem(
      id: card.id,
      providerId: card.providerId,
      contentType: card.contentType,
      title: card.title,
      externalId: card.externalId,
      subtitle: entry.subtitle ?? card.subtitle,
      description: card.description,
      artworkUrl: entry.artworkUrl ?? card.artworkUrl,
      streamUrl: card.streamUrl,
      streamJson: card.streamJson,
      year: card.year,
      rating: card.rating,
      durationSeconds: entry.durationSeconds ?? card.durationSeconds,
      epgSummary: card.epgSummary,
      recentItemType: entry.itemType,
      seriesId: entry.seriesId,
      seasonId: entry.seasonId,
      resumePositionSeconds: entry.completed ? 0 : entry.positionSeconds,
      resumeDurationSeconds: entry.durationSeconds,
      isFavorite: card.isFavorite,
      isRecent: true,
      canPlay:
          card.canPlay ||
          _hasPlayableStream(
            streamUrl: resolved.streamUrl,
            streamJson: resolved.streamJson,
          ),
    );
  }

  final contentType = switch (entry.itemType) {
    PlayableContentType.live => CatalogContentType.live,
    PlayableContentType.movie => CatalogContentType.movie,
    PlayableContentType.episode => CatalogContentType.series,
  };
  return CatalogCardItem(
    id: entry.itemId,
    providerId: entry.providerId,
    contentType: contentType,
    title: entry.title,
    subtitle: entry.subtitle,
    artworkUrl: entry.artworkUrl,
    durationSeconds: entry.durationSeconds,
    recentItemType: entry.itemType,
    seriesId: entry.seriesId,
    seasonId: entry.seasonId,
    resumePositionSeconds: entry.completed ? 0 : entry.positionSeconds,
    resumeDurationSeconds: entry.durationSeconds,
    isRecent: true,
    canPlay: false,
  );
}

Future<CatalogItem?> _resolveRecentCatalogItem(
  CatalogRepository catalogRepository,
  WatchHistoryEntry entry,
) async {
  return switch (entry.itemType) {
    PlayableContentType.live => catalogRepository.getItem(
      providerId: entry.providerId,
      contentType: CatalogContentType.live,
      id: entry.itemId,
    ),
    PlayableContentType.movie => catalogRepository.getItem(
      providerId: entry.providerId,
      contentType: CatalogContentType.movie,
      id: entry.itemId,
    ),
    PlayableContentType.episode => _resolveRecentEpisodeCatalogItem(
      catalogRepository,
      entry,
    ),
  };
}

Future<CatalogItem?> _resolveRecentEpisodeCatalogItem(
  CatalogRepository catalogRepository,
  WatchHistoryEntry entry,
) async {
  final seriesId = entry.seriesId;
  if (seriesId == null || seriesId.trim().isEmpty) {
    return null;
  }
  final episodes = await catalogRepository.listEpisodesForSeries(
    providerId: entry.providerId,
    seriesId: seriesId,
  );
  final episode = episodes.where((candidate) {
    return candidate.id == entry.itemId &&
        (entry.seasonId == null || candidate.seasonId == entry.seasonId) &&
        _episodeHasPlayableStream(candidate);
  }).firstOrNull;
  if (episode == null) {
    return null;
  }
  return CatalogItem(
    id: episode.id,
    providerId: episode.providerId,
    contentType: CatalogContentType.series,
    title: episode.title,
    normalizedTitle: episode.normalizedTitle,
    updatedAtMs: episode.updatedAtMs,
    lastSeenAtMs: episode.lastSeenAtMs,
    subtitle: 'S${episode.seasonNumber} E${episode.episodeNumber}',
    description: episode.description,
    artworkUrl: episode.artworkUrl,
    streamUrl: episode.streamUrl,
    streamJson: episode.streamJson,
    durationSeconds: episode.durationSeconds,
  );
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
  final scoped = categories
      .where(
        (candidate) =>
            candidate.providerId == category.providerId &&
            candidate.contentType == category.contentType,
      )
      .toList();
  final index = scoped.indexWhere((candidate) => candidate.id == category.id);
  final nextIndex = index + delta;
  if (index < 0 || nextIndex < 0 || nextIndex >= scoped.length) return;
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

Future<void> _toggleItemFavorite(WidgetRef ref, CatalogCardItem item) {
  return ref
      .read(catalogRepositoryProvider)
      .toggleItemFavorite(
        providerId: item.providerId,
        itemId: item.id,
        itemType: FavoriteItemType.fromCatalog(item.contentType),
      );
}

Future<_PlaybackTarget?> _playbackTargetForCard(
  WidgetRef ref,
  CatalogCardItem item, {
  bool restart = false,
}) async {
  if (item.isRecent) {
    return _recentPlaybackTarget(ref, item, restart: restart);
  }

  if (item.contentType == CatalogContentType.series) {
    final episodes = await _episodesForSeries(ref, item);
    final resume = restart
        ? null
        : await ref
              .read(watchHistoryRepositoryProvider)
              .lookupLatestResumeForSeries(
                providerId: item.providerId,
                seriesId: item.id,
              );
    final firstPlayableEpisode = episodes
        .where(_episodeHasPlayableStream)
        .firstOrNull;
    final episode = restart
        ? firstPlayableEpisode
        : _episodeForResume(episodes, resume) ?? firstPlayableEpisode;
    if (episode == null) return null;
    return _episodePlaybackTarget(
      ref,
      episode: episode,
      episodes: episodes,
      fallbackPosterUrl: item.artworkUrl,
      resume: restart ? null : resume,
    );
  }

  final resume = !restart && item.contentType == CatalogContentType.movie
      ? await ref
            .read(watchHistoryRepositoryProvider)
            .lookupResumePosition(
              providerId: item.providerId,
              itemId: item.id,
              itemType: PlayableContentType.movie,
            )
      : null;
  final url = await _streamUrl(
    ref,
    providerId: item.providerId,
    contentType: item.contentType,
    streamUrl: item.streamUrl,
    streamJson: item.streamJson,
  );
  if (url == null) return null;
  return _PlaybackTarget(
    playable: PlayableItem(
      id: item.id,
      providerId: item.providerId,
      title: item.title,
      subtitle: item.subtitle,
      streamUrl: url,
      kind: item.contentType == CatalogContentType.live
          ? PlayableKind.live
          : PlayableKind.movie,
      posterUrl: item.contentType == CatalogContentType.movie
          ? item.artworkUrl
          : null,
      channelLogoUrl: item.contentType == CatalogContentType.live
          ? item.artworkUrl
          : null,
      durationSeconds: item.durationSeconds,
      resumePosition: resume == null
          ? Duration.zero
          : Duration(seconds: resume.positionSeconds),
    ),
    history: item.contentType == CatalogContentType.live
        ? WatchHistoryUpdate(
            itemId: item.id,
            itemType: PlayableContentType.live,
            providerId: item.providerId,
            title: item.title,
            subtitle: item.subtitle,
            artworkUrl: item.artworkUrl,
            durationSeconds: item.durationSeconds,
          )
        : null,
  );
}

Future<List<CatalogEpisode>> _episodesForSeries(
  WidgetRef ref,
  CatalogCardItem item,
) async {
  final catalogRepository = ref.read(catalogRepositoryProvider);
  var episodes = await catalogRepository.listEpisodesForSeries(
    providerId: item.providerId,
    seriesId: item.id,
  );
  if (episodes.any(_episodeHasPlayableStream)) {
    return episodes;
  }

  final externalSeriesId =
      item.externalId ??
      _externalSeriesIdFromCatalogId(item.providerId, item.id);
  if (externalSeriesId == null) {
    return episodes;
  }

  try {
    await ref
        .read(providerRefreshServiceProvider)
        .refreshSeriesEpisodeDetails(
          providerId: item.providerId,
          seriesId: item.id,
          externalSeriesId: externalSeriesId,
        );
  } catch (error, stackTrace) {
    debugPrint('Failed to lazy-load series episodes: $error');
    debugPrintStack(stackTrace: stackTrace);
    return episodes;
  }

  episodes = await catalogRepository.listEpisodesForSeries(
    providerId: item.providerId,
    seriesId: item.id,
  );
  return episodes;
}

Future<_PlaybackTarget?> _recentPlaybackTarget(
  WidgetRef ref,
  CatalogCardItem item, {
  bool restart = false,
}) async {
  final recentType = item.recentItemType;
  if (recentType == null) return null;

  if (recentType == PlayableContentType.episode) {
    final seriesId = item.seriesId;
    if (seriesId == null || seriesId.trim().isEmpty) return null;
    final episodes = await ref
        .read(catalogRepositoryProvider)
        .listEpisodesForSeries(providerId: item.providerId, seriesId: seriesId);
    final episode = episodes.where((candidate) {
      return candidate.id == item.id &&
          (item.seasonId == null || candidate.seasonId == item.seasonId);
    }).firstOrNull;
    if (episode == null) return null;
    final resume = !restart
        ? await ref
              .read(watchHistoryRepositoryProvider)
              .lookupResumePosition(
                providerId: episode.providerId,
                itemId: episode.id,
                itemType: PlayableContentType.episode,
                seriesId: episode.seriesId,
                seasonId: episode.seasonId,
              )
        : null;
    return _episodePlaybackTarget(
      ref,
      episode: episode,
      episodes: episodes,
      fallbackPosterUrl: item.artworkUrl,
      resume: resume,
    );
  }

  final contentType = recentType == PlayableContentType.live
      ? CatalogContentType.live
      : CatalogContentType.movie;
  final catalogItem = await ref
      .read(catalogRepositoryProvider)
      .getItem(
        providerId: item.providerId,
        contentType: contentType,
        id: item.id,
      );
  if (catalogItem == null) return null;
  final resume = recentType == PlayableContentType.movie && !restart
      ? PlaybackPosition(
          providerId: item.providerId,
          itemId: item.id,
          itemType: PlayableContentType.movie,
          positionSeconds: item.resumePositionSeconds,
          durationSeconds: item.resumeDurationSeconds,
          updatedAtMs: 0,
        )
      : null;
  return _playbackTargetForCard(
    ref,
    _catalogItemToCard(catalogItem, resume: resume),
    restart: restart,
  );
}

Future<_PlaybackTarget?> _episodePlaybackTarget(
  WidgetRef ref, {
  required CatalogEpisode episode,
  required List<CatalogEpisode> episodes,
  String? fallbackPosterUrl,
  PlaybackPosition? resume,
}) async {
  final railItems = await _episodePlayableItems(
    ref,
    episodes: episodes,
    fallbackPosterUrl: fallbackPosterUrl,
  );
  final current = railItems.where((candidate) {
    return candidate.id == episode.id && candidate.seasonId == episode.seasonId;
  }).firstOrNull;
  if (current == null) return null;

  final playable = current.copyWith(
    resumePosition: resume == null
        ? Duration.zero
        : Duration(seconds: resume.positionSeconds),
    episodeRailItems: railItems,
  );

  return _PlaybackTarget(playable: playable, history: null);
}

Future<List<PlayableItem>> _episodePlayableItems(
  WidgetRef ref, {
  required List<CatalogEpisode> episodes,
  String? fallbackPosterUrl,
}) async {
  final items = <PlayableItem>[];
  for (final episode in episodes.where(_episodeHasPlayableStream)) {
    final url = await _streamUrl(
      ref,
      providerId: episode.providerId,
      contentType: CatalogContentType.series,
      streamUrl: episode.streamUrl,
      streamJson: episode.streamJson,
    );
    if (url == null) continue;
    items.add(
      _episodePlayable(
        episode: episode,
        streamUrl: url,
        fallbackPosterUrl: fallbackPosterUrl,
      ),
    );
  }
  return items;
}

CatalogEpisode? _episodeForResume(
  List<CatalogEpisode> episodes,
  PlaybackPosition? resume,
) {
  if (resume == null) return null;
  return episodes.where((episode) {
    return episode.id == resume.itemId &&
        episode.seriesId == resume.seriesId &&
        (resume.seasonId == null || episode.seasonId == resume.seasonId) &&
        _episodeHasPlayableStream(episode);
  }).firstOrNull;
}

PlayableItem _episodePlayable({
  required CatalogEpisode episode,
  required String streamUrl,
  String? fallbackPosterUrl,
}) {
  return PlayableItem(
    id: episode.id,
    providerId: episode.providerId,
    title: episode.title,
    subtitle: 'S${episode.seasonNumber} E${episode.episodeNumber}',
    streamUrl: streamUrl,
    kind: PlayableKind.episode,
    posterUrl: episode.artworkUrl ?? fallbackPosterUrl,
    seriesId: episode.seriesId,
    seasonId: episode.seasonId,
    seasonNumber: episode.seasonNumber,
    episodeNumber: episode.episodeNumber,
    durationSeconds: episode.durationSeconds,
  );
}

bool _episodeHasPlayableStream(CatalogEpisode episode) {
  return _hasPlayableStream(
    streamUrl: episode.streamUrl,
    streamJson: episode.streamJson,
  );
}

bool _hasPlayableStream({String? streamUrl, String? streamJson}) {
  return streamUrl?.trim().isNotEmpty == true ||
      streamJson?.trim().isNotEmpty == true;
}

String? _externalSeriesIdFromCatalogId(String providerId, String itemId) {
  final prefix = '$providerId:series:';
  if (!itemId.startsWith(prefix)) {
    return null;
  }
  final externalId = itemId.substring(prefix.length).trim();
  return externalId.isEmpty ? null : externalId;
}

Future<String?> _streamUrl(
  WidgetRef ref, {
  required String providerId,
  required CatalogContentType contentType,
  String? streamUrl,
  String? streamJson,
}) async {
  if (streamUrl?.trim().isNotEmpty == true) {
    return streamUrl!.trim();
  }
  if (streamJson?.trim().isEmpty != false) {
    return null;
  }
  final data = jsonDecode(streamJson!) as Map<String, dynamic>;
  if (data['providerType'] != 'xtream') {
    return null;
  }
  final provider = await ref
      .read(providerRepositoryProvider)
      .getProvider(providerId);
  if (provider == null ||
      provider.serverUrl == null ||
      provider.username == null ||
      provider.password == null) {
    return null;
  }
  final client = XtreamClient(
    credentials: XtreamCredentials(
      serverUrl: provider.serverUrl!,
      username: provider.username!,
      password: provider.password!,
    ),
  );
  try {
    final streamId = data['streamId']?.toString();
    if (streamId == null || streamId.isEmpty) return null;
    final extension =
        data['containerExtension']?.toString() ??
        (contentType == CatalogContentType.live ? 'ts' : 'mp4');
    return switch (contentType) {
      CatalogContentType.live => client.buildLiveStreamUrl(
        streamId,
        containerExtension: extension,
      ),
      CatalogContentType.movie => client.buildMovieStreamUrl(
        streamId,
        containerExtension: extension,
      ),
      CatalogContentType.series => client.buildSeriesStreamUrl(
        streamId,
        containerExtension: extension,
      ),
    };
  } finally {
    client.close();
  }
}

String? _subtitleFor(CatalogItem item) {
  final parts = <String>[
    if (item.subtitle?.trim().isNotEmpty == true) item.subtitle!.trim(),
    if (item.year != null) item.year.toString(),
    if (item.rating?.trim().isNotEmpty == true) 'Rating ${item.rating}',
  ];
  if (parts.isEmpty) {
    return null;
  }
  return parts.join(' / ');
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
