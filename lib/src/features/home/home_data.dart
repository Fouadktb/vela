import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation_controller.dart';
import '../../app/section_state.dart';
import '../../catalog/catalog_models.dart';
import '../catalog/catalog_card_mapper.dart';
import '../catalog/item_grid.dart';
import 'home_models.dart';

const _homeCacheDuration = Duration(minutes: 10);
const _homeRowLimit = 24;
const _homeHistoryLimit = 120;
const _homeFavoritesLimit = 10;
const _homePinnedCategoryLimit = 18;

final homeContinueWatchingProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      _keepHomeProviderWarm(ref);
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      final catalogRepository = ref.watch(catalogRepositoryProvider);
      return historyRepository
          .watchRecentlyWatched(limit: _homeHistoryLimit)
          .asyncMap((entries) async {
            final cards = <CatalogCardItem>[];
            final seenSeries = <String>{};
            for (final entry in entries) {
              if (entry.itemType == PlayableContentType.live) {
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
              if (card.canPlay) {
                cards.add(card);
              }
              if (cards.length >= _homeRowLimit) {
                break;
              }
            }
            return cards;
          });
    });

final homeRecentLiveProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      _keepHomeProviderWarm(ref);
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      final catalogRepository = ref.watch(catalogRepositoryProvider);
      return historyRepository
          .watchRecentlyWatched(limit: _homeHistoryLimit)
          .asyncMap((entries) async {
            final cards = <CatalogCardItem>[];
            final seen = <String>{};
            for (final entry in entries) {
              if (entry.itemType != PlayableContentType.live) {
                continue;
              }
              final key = '${entry.providerId}:${entry.itemId}';
              if (!seen.add(key)) {
                continue;
              }
              final card = await recentToResolvedCard(
                catalogRepository,
                historyRepository,
                entry,
              );
              if (card.canPlay) {
                cards.add(card);
              }
              if (cards.length >= _homeRowLimit) {
                break;
              }
            }
            return cards;
          });
    });

final homeLatestMoviesProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      _keepHomeProviderWarm(ref);
      final catalogRepository = ref.watch(catalogRepositoryProvider);
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      ref.watch(recentlyWatchedProvider);
      return catalogRepository
          .watchLatestItems(
            section: CatalogContentType.movie,
            limit: _homeRowLimit,
          )
          .asyncMap((items) {
            return catalogItemsToCards(
              catalogRepository,
              historyRepository,
              items,
            );
          });
    });

final homeLatestSeriesProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      _keepHomeProviderWarm(ref);
      final catalogRepository = ref.watch(catalogRepositoryProvider);
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      ref.watch(recentlyWatchedProvider);
      return catalogRepository
          .watchLatestItems(
            section: CatalogContentType.series,
            limit: _homeRowLimit,
          )
          .asyncMap((items) {
            return catalogItemsToCards(
              catalogRepository,
              historyRepository,
              items,
            );
          });
    });

final _homeFavoriteLiveProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      _keepHomeProviderWarm(ref);
      return _watchFavoriteCards(ref, CatalogContentType.live);
    });

final _homeFavoriteMoviesProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      _keepHomeProviderWarm(ref);
      return _watchFavoriteCards(ref, CatalogContentType.movie);
    });

final _homeFavoriteSeriesProvider =
    StreamProvider.autoDispose<List<CatalogCardItem>>((ref) {
      _keepHomeProviderWarm(ref);
      return _watchFavoriteCards(ref, CatalogContentType.series);
    });

final homeFavoritesProvider =
    Provider.autoDispose<AsyncValue<List<CatalogCardItem>>>((ref) {
      return combineHomeAsyncLists<CatalogCardItem>([
        ref.watch(_homeFavoriteLiveProvider),
        ref.watch(_homeFavoriteMoviesProvider),
        ref.watch(_homeFavoriteSeriesProvider),
      ], limit: _homeRowLimit);
    });

final homePinnedCategoriesProvider =
    Provider.autoDispose<AsyncValue<List<HomeCategoryTile>>>((ref) {
      final live = ref.watch(
        categoriesProvider(
          const CategoryQuery(
            contentType: CatalogContentType.live,
            favoritesOnly: true,
          ),
        ),
      );
      final movies = ref.watch(
        categoriesProvider(
          const CategoryQuery(
            contentType: CatalogContentType.movie,
            favoritesOnly: true,
          ),
        ),
      );
      final series = ref.watch(
        categoriesProvider(
          const CategoryQuery(
            contentType: CatalogContentType.series,
            favoritesOnly: true,
          ),
        ),
      );

      return combineHomeAsyncLists<CatalogCategory>([
        live,
        movies,
        series,
      ], limit: _homePinnedCategoryLimit).when(
        data: (categories) {
          return AsyncValue.data(
            categories
                .map(
                  (category) => HomeCategoryTile(
                    id: category.id,
                    providerId: category.providerId,
                    contentType: category.contentType,
                    section: _sectionFor(category.contentType),
                    name: category.name,
                    itemCount: category.itemCount,
                  ),
                )
                .toList(),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: AsyncValue.error,
      );
    });

final homeHeroProvider = Provider.autoDispose<AsyncValue<CatalogCardItem?>>((
  ref,
) {
  final selectedHomeItemId = ref.watch(
    navigationControllerProvider.select(
      (navigation) => navigation.selectedHomeItemId,
    ),
  );
  final values = [
    ref.watch(homeContinueWatchingProvider),
    ref.watch(homeLatestMoviesProvider),
    ref.watch(homeLatestSeriesProvider),
    ref.watch(homeRecentLiveProvider),
    ref.watch(homeFavoritesProvider),
  ];

  Object? firstError;
  StackTrace? firstStackTrace;
  var hasLoading = false;
  CatalogCardItem? firstCandidate;
  for (final value in values) {
    final result = value.when(
      data: (cards) {
        if (cards.isEmpty) {
          return null;
        }
        firstCandidate ??= cards.first;
        if (selectedHomeItemId != null) {
          for (final card in cards) {
            if (card.id == selectedHomeItemId) {
              return card;
            }
          }
        }
        return null;
      },
      loading: () {
        hasLoading = true;
        return null;
      },
      error: (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
        return null;
      },
    );
    if (result != null) {
      return AsyncValue.data(result);
    }
  }
  if (firstCandidate != null) {
    return AsyncValue.data(firstCandidate);
  }
  if (hasLoading) {
    return const AsyncValue.loading();
  }
  if (firstError != null) {
    return AsyncValue.error(firstError!, firstStackTrace ?? StackTrace.current);
  }
  return const AsyncValue.data(null);
});

Stream<List<CatalogCardItem>> _watchFavoriteCards(
  Ref ref,
  CatalogContentType contentType,
) {
  final catalogRepository = ref.watch(catalogRepositoryProvider);
  final historyRepository = ref.watch(watchHistoryRepositoryProvider);
  ref.watch(recentlyWatchedProvider);
  return catalogRepository
      .watchItems(
        section: contentType,
        favoritesOnly: true,
        limit: _homeFavoritesLimit,
      )
      .asyncMap((items) {
        return catalogItemsToCards(catalogRepository, historyRepository, items);
      });
}

AsyncValue<List<T>> combineHomeAsyncLists<T>(
  List<AsyncValue<List<T>>> values, {
  int? limit,
}) {
  Object? firstError;
  StackTrace? firstStackTrace;
  var hasLoading = false;
  final combined = <T>[];

  for (final value in values) {
    value.when(
      data: combined.addAll,
      loading: () {
        hasLoading = true;
      },
      error: (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      },
    );
  }

  if (combined.isNotEmpty) {
    return AsyncValue.data(
      limit == null ? combined : combined.take(limit).toList(),
    );
  }
  if (hasLoading) {
    return const AsyncValue.loading();
  }
  if (firstError != null) {
    return AsyncValue.error(firstError!, firstStackTrace ?? StackTrace.current);
  }
  return const AsyncValue.data([]);
}

VelaSection _sectionFor(CatalogContentType type) {
  return switch (type) {
    CatalogContentType.live => VelaSection.live,
    CatalogContentType.movie => VelaSection.movies,
    CatalogContentType.series => VelaSection.series,
  };
}

void _keepHomeProviderWarm(Ref ref) {
  final link = ref.keepAlive();
  Timer? disposeTimer;

  ref.onCancel(() {
    disposeTimer = Timer(_homeCacheDuration, link.close);
  });
  ref.onResume(() {
    disposeTimer?.cancel();
    disposeTimer = null;
  });
  ref.onDispose(() {
    disposeTimer?.cancel();
  });
}
