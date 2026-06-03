import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/navigation_controller.dart';
import '../../catalog/catalog_models.dart';
import '../../catalog/catalog_repository.dart';
import '../../catalog/watch_history_repository.dart';
import 'catalog_card_mapper.dart';
import 'item_grid.dart';

const globalSearchPrefix = '/';

final globalSearchProvider = FutureProvider.autoDispose
    .family<GlobalSearchResults, GlobalSearchRequest>((ref, request) async {
      final query = request.query.trim();
      if (query.isEmpty) {
        return GlobalSearchResults(query: query, groups: const []);
      }

      final catalogRepository = ref.watch(catalogRepositoryProvider);
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      final recentEntries = ref.watch(recentlyWatchedProvider.future);

      final groups = await Future.wait([
        _searchCatalogGroup(
          catalogRepository: catalogRepository,
          historyRepository: historyRepository,
          query: query,
          type: GlobalSearchGroupType.live,
          section: CatalogContentType.live,
          limit: request.limitPerGroup,
        ),
        _searchCatalogGroup(
          catalogRepository: catalogRepository,
          historyRepository: historyRepository,
          query: query,
          type: GlobalSearchGroupType.movies,
          section: CatalogContentType.movie,
          limit: request.limitPerGroup,
        ),
        _searchCatalogGroup(
          catalogRepository: catalogRepository,
          historyRepository: historyRepository,
          query: query,
          type: GlobalSearchGroupType.series,
          section: CatalogContentType.series,
          limit: request.limitPerGroup,
        ),
        _searchFavoritesGroup(
          catalogRepository: catalogRepository,
          historyRepository: historyRepository,
          query: query,
          limit: request.limitPerGroup,
        ),
        _searchRecentGroup(
          catalogRepository: catalogRepository,
          historyRepository: historyRepository,
          query: query,
          entries: await recentEntries,
          limit: request.limitPerGroup,
        ),
      ]);

      return GlobalSearchResults(
        query: query,
        groups: groups.where((group) => group.results.isNotEmpty).toList(),
      );
    });

class GlobalSearchRequest {
  const GlobalSearchRequest({required this.query, this.limitPerGroup = 8});

  final String query;
  final int limitPerGroup;

  static bool isGlobalToolbarQuery(String value) {
    return value.trimLeft().startsWith(globalSearchPrefix);
  }

  static GlobalSearchRequest? fromToolbarQuery(String value) {
    if (!isGlobalToolbarQuery(value)) {
      return null;
    }
    final trimmed = value.trimLeft();
    return GlobalSearchRequest(
      query: trimmed.substring(globalSearchPrefix.length).trim(),
    );
  }

  static String enableToolbarQuery(String value) {
    final query = value.trim();
    if (query.startsWith(globalSearchPrefix)) {
      return query;
    }
    return query.isEmpty ? globalSearchPrefix : '$globalSearchPrefix $query';
  }

  static String disableToolbarQuery(String value) {
    if (!isGlobalToolbarQuery(value)) {
      return value;
    }
    return value.trimLeft().substring(globalSearchPrefix.length).trimLeft();
  }

  @override
  bool operator ==(Object other) {
    return other is GlobalSearchRequest &&
        other.query == query &&
        other.limitPerGroup == limitPerGroup;
  }

  @override
  int get hashCode => Object.hash(query, limitPerGroup);
}

class GlobalSearchResults {
  const GlobalSearchResults({required this.query, required this.groups});

  final String query;
  final List<GlobalSearchGroup> groups;

  bool get isEmpty => groups.every((group) => group.results.isEmpty);

  int get totalCount {
    return groups.fold(0, (count, group) => count + group.results.length);
  }
}

class GlobalSearchGroup {
  const GlobalSearchGroup({required this.type, required this.results});

  final GlobalSearchGroupType type;
  final List<GlobalSearchResult> results;

  String get title {
    return switch (type) {
      GlobalSearchGroupType.live => 'Live',
      GlobalSearchGroupType.movies => 'Movies',
      GlobalSearchGroupType.series => 'Series',
      GlobalSearchGroupType.favorites => 'Favorites',
      GlobalSearchGroupType.recent => 'Recent',
    };
  }

  IconData get icon {
    return switch (type) {
      GlobalSearchGroupType.live => LucideIcons.tv,
      GlobalSearchGroupType.movies => LucideIcons.film,
      GlobalSearchGroupType.series => LucideIcons.library,
      GlobalSearchGroupType.favorites => LucideIcons.star,
      GlobalSearchGroupType.recent => LucideIcons.history,
    };
  }
}

enum GlobalSearchGroupType { live, movies, series, favorites, recent }

class GlobalSearchResult {
  const GlobalSearchResult({required this.groupType, required this.item});

  final GlobalSearchGroupType groupType;
  final CatalogCardItem item;
}

class GlobalSearchResultsView extends ConsumerWidget {
  const GlobalSearchResultsView({
    required this.request,
    required this.onOpenResult,
    super.key,
  });

  final GlobalSearchRequest request;
  final ValueChanged<GlobalSearchResult> onOpenResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = request.query.trim();
    if (query.isEmpty) {
      return const _GlobalSearchPrompt();
    }

    final value = ref.watch(globalSearchProvider(request));
    return value.when(
      data: (results) {
        if (results.isEmpty) {
          return _GlobalSearchNotice(
            icon: LucideIcons.searchX,
            title: 'No global results',
            body:
                'No live channels, movies, series, favorites, or recent items match "$query".',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(30, 4, 30, 32),
          itemBuilder: (context, index) {
            final group = results.groups[index];
            return _GlobalSearchGroupView(
              group: group,
              onOpenResult: onOpenResult,
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: 18),
          itemCount: results.groups.length,
        );
      },
      loading: () => const _GlobalSearchNotice(
        icon: LucideIcons.search,
        title: 'Searching library',
        body: 'Checking live, movies, series, favorites, and recent items.',
      ),
      error: (_, _) => const _GlobalSearchNotice(
        icon: LucideIcons.searchAlert,
        title: 'Search unavailable',
        body: 'The library search could not be loaded.',
      ),
    );
  }
}

class _GlobalSearchGroupView extends StatelessWidget {
  const _GlobalSearchGroupView({
    required this.group,
    required this.onOpenResult,
  });

  final GlobalSearchGroup group;
  final ValueChanged<GlobalSearchResult> onOpenResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(group.icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                group.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              group.results.length.toString(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFFA9A39A),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final result in group.results)
              _GlobalResultTile(
                result: result,
                onOpen: () => onOpenResult(result),
              ),
          ],
        ),
      ],
    );
  }
}

class _GlobalResultTile extends StatelessWidget {
  const _GlobalResultTile({required this.result, required this.onOpen});

  final GlobalSearchResult result;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final item = result.item;
    final theme = Theme.of(context);
    return SizedBox(
      width: 330,
      child: Material(
        color: const Color(0xFF151719),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 92,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF292D31)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(width: 62, child: _ResultArtwork(item: item)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _resultSubtitle(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFA9A39A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _ResultBadge(label: _contentLabel(item.contentType)),
                          if (item.isFavorite)
                            const _ResultBadge(label: 'Favorite'),
                          if (item.isRecent)
                            const _ResultBadge(label: 'Recent'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  item.contentType == CatalogContentType.live
                      ? LucideIcons.play
                      : LucideIcons.panelTopOpen,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultArtwork extends StatelessWidget {
  const _ResultArtwork({required this.item});

  final CatalogCardItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.contentType) {
      CatalogContentType.live => LucideIcons.tv,
      CatalogContentType.movie => LucideIcons.film,
      CatalogContentType.series => LucideIcons.library,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF0F1113)),
        child: item.hasArtwork
            ? Image.network(
                item.artworkUrl!,
                fit: item.contentType == CatalogContentType.live
                    ? BoxFit.contain
                    : BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(icon, color: const Color(0xFF716D66), size: 28),
              )
            : Icon(icon, color: const Color(0xFF716D66), size: 28),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D20),
        border: Border.all(color: const Color(0xFF34383C)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFD7D0C6),
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _GlobalSearchPrompt extends StatelessWidget {
  const _GlobalSearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const _GlobalSearchNotice(
      icon: LucideIcons.globe2,
      title: 'Global search',
      body:
          'Type after / to search live, movies, series, favorites, and recent items together.',
    );
  }
}

class _GlobalSearchNotice extends StatelessWidget {
  const _GlobalSearchNotice({
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF151719),
            border: Border.all(color: const Color(0xFF292D31)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(body, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<GlobalSearchGroup> _searchCatalogGroup({
  required CatalogRepository catalogRepository,
  required WatchHistoryRepository historyRepository,
  required String query,
  required GlobalSearchGroupType type,
  required CatalogContentType section,
  required int limit,
}) async {
  final items = await catalogRepository.searchItems(
    section: section,
    query: query,
    includeSubtitle: true,
    limit: limit,
  );
  final cards = await catalogItemsToCards(
    catalogRepository,
    historyRepository,
    items,
  );
  return GlobalSearchGroup(
    type: type,
    results: [
      for (final card in cards.where((card) => _cardMatches(card, query)))
        GlobalSearchResult(groupType: type, item: card),
    ].take(limit).toList(),
  );
}

Future<GlobalSearchGroup> _searchFavoritesGroup({
  required CatalogRepository catalogRepository,
  required WatchHistoryRepository historyRepository,
  required String query,
  required int limit,
}) async {
  final itemGroups = await Future.wait([
    catalogRepository.searchItems(
      section: CatalogContentType.live,
      query: query,
      favoritesOnly: true,
      includeSubtitle: true,
      limit: limit,
    ),
    catalogRepository.searchItems(
      section: CatalogContentType.movie,
      query: query,
      favoritesOnly: true,
      includeSubtitle: true,
      limit: limit,
    ),
    catalogRepository.searchItems(
      section: CatalogContentType.series,
      query: query,
      favoritesOnly: true,
      includeSubtitle: true,
      limit: limit,
    ),
  ]);
  final cards = await catalogItemsToCards(
    catalogRepository,
    historyRepository,
    itemGroups.expand((items) => items.take(limit)).take(limit).toList(),
  );
  return GlobalSearchGroup(
    type: GlobalSearchGroupType.favorites,
    results: [
      for (final card in cards.where((card) => _cardMatches(card, query)))
        GlobalSearchResult(
          groupType: GlobalSearchGroupType.favorites,
          item: card,
        ),
    ].take(limit).toList(),
  );
}

Future<GlobalSearchGroup> _searchRecentGroup({
  required CatalogRepository catalogRepository,
  required WatchHistoryRepository historyRepository,
  required String query,
  required List<WatchHistoryEntry> entries,
  required int limit,
}) async {
  final results = <GlobalSearchResult>[];
  final seenSeries = <String>{};
  for (final entry in entries) {
    if (!_entryMatches(entry, query)) {
      continue;
    }
    if (entry.itemType == PlayableContentType.episode &&
        entry.seriesId?.trim().isNotEmpty == true) {
      final key = '${entry.providerId}:${entry.seriesId}';
      if (!seenSeries.add(key)) {
        continue;
      }
    }
    final card = await recentToResolvedCard(
      catalogRepository,
      historyRepository,
      entry,
    );
    if (!card.canPlay) {
      continue;
    }
    results.add(
      GlobalSearchResult(groupType: GlobalSearchGroupType.recent, item: card),
    );
    if (results.length >= limit) {
      break;
    }
  }
  return GlobalSearchGroup(
    type: GlobalSearchGroupType.recent,
    results: results,
  );
}

bool _cardMatches(CatalogCardItem item, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return item.title.toLowerCase().contains(normalized) ||
      (item.subtitle?.toLowerCase().contains(normalized) ?? false) ||
      (item.seriesPlaybackSummary?.toLowerCase().contains(normalized) ?? false);
}

bool _entryMatches(WatchHistoryEntry entry, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return entry.title.toLowerCase().contains(normalized) ||
      (entry.subtitle?.toLowerCase().contains(normalized) ?? false);
}

String _resultSubtitle(CatalogCardItem item) {
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
