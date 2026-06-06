import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/navigation_controller.dart';
import '../app/section_state.dart';
import '../app/vela_strings.dart';
import '../catalog/catalog_models.dart';
import '../features/catalog/catalog_playback_target.dart';
import '../features/catalog/item_grid.dart';
import '../features/home/home_data.dart';
import '../features/home/home_models.dart';
import '../playback/playable_item.dart';
import 'tv_focus.dart';

class TvHomeScreen extends ConsumerWidget {
  const TvHomeScreen({required this.onOpenPlayer, super.key});

  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = VelaStrings.of(context);
    final heroValue = ref.watch(homeHeroProvider);
    final rows = [
      _TvHomeCardRowSpec(
        title: strings.homeContinueWatching,
        value: ref.watch(homeContinueWatchingProvider),
      ),
      _TvHomeCardRowSpec(
        title: strings.homeRecentLive,
        value: ref.watch(homeRecentLiveProvider),
        compactArtwork: true,
      ),
      _TvHomeCardRowSpec(
        title: strings.homeLatestMovies,
        value: ref.watch(homeLatestMoviesProvider),
      ),
      _TvHomeCardRowSpec(
        title: strings.homeLatestSeries,
        value: ref.watch(homeLatestSeriesProvider),
      ),
      _TvHomeCardRowSpec(
        title: strings.homeFavorites,
        value: ref.watch(homeFavoritesProvider),
      ),
    ];
    final categoriesValue = ref.watch(homePinnedCategoriesProvider);

    return Directionality(
      textDirection: strings.textDirection,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _TvHomeHero(
              value: heroValue,
              onPlay: (item) => _openItem(ref, item),
              onBrowse: (item) => _browseItem(ref, item),
            ),
          ),
          for (final row in rows)
            SliverToBoxAdapter(
              child: _TvHomeCardRail(
                spec: row,
                onFocusItem: (item) => _browsePreview(ref, item),
                onOpen: (item) => _openItem(ref, item),
              ),
            ),
          SliverToBoxAdapter(
            child: _TvPinnedCategoryRail(
              title: strings.homePinnedCategories,
              value: categoriesValue,
              onOpen: (category) => _openCategory(ref, category),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
        ],
      ),
    );
  }

  Future<void> _openItem(WidgetRef ref, CatalogCardItem item) async {
    try {
      final target = await playbackTargetForCatalogCard(ref, item);
      if (target == null) {
        return;
      }
      final history = target.history;
      if (history != null) {
        unawaited(
          ref
              .read(watchHistoryRepositoryProvider)
              .addOrUpdateWatchHistory(history)
              .catchError((Object error, StackTrace stackTrace) {
                debugPrint('Failed to update TV home watch history: $error');
                debugPrintStack(stackTrace: stackTrace);
              }),
        );
      }
      onOpenPlayer(target.playable);
    } catch (error, stackTrace) {
      debugPrint('Failed to open TV home item: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _browsePreview(WidgetRef ref, CatalogCardItem item) {
    ref.read(navigationControllerProvider).selectHomeItem(item.id);
  }

  void _browseItem(WidgetRef ref, CatalogCardItem item) {
    final navigation = ref.read(navigationControllerProvider);
    navigation.selectSection(_sectionFor(item.contentType));
    navigation.selectCategory(null);
    navigation.selectItem(item.id);
  }

  void _openCategory(WidgetRef ref, HomeCategoryTile category) {
    final navigation = ref.read(navigationControllerProvider);
    navigation.selectSection(category.section);
    navigation.selectCategory(category.id);
  }
}

class _TvHomeHero extends StatelessWidget {
  const _TvHomeHero({
    required this.value,
    required this.onPlay,
    required this.onBrowse,
  });

  final AsyncValue<CatalogCardItem?> value;
  final ValueChanged<CatalogCardItem> onPlay;
  final ValueChanged<CatalogCardItem> onBrowse;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const _TvHeroShell(
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      ),
      error: (error, _) => _TvHeroShell(
        child: _TvHomeMessage(
          icon: LucideIcons.circleAlert,
          title: VelaStrings.english.homeRowsUnavailable,
          body: error.toString(),
        ),
      ),
      data: (item) {
        if (item == null) {
          return _TvHeroShell(
            child: _TvHomeMessage(
              icon: LucideIcons.sparkles,
              title: VelaStrings.english.homeEmptyTitle,
              body: VelaStrings.english.homeEmptyBody,
            ),
          );
        }
        return _TvHeroShell(
          backgroundUrl: item.artworkUrl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 26, 26, 28),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeLabel(item),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    if (item.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text(
                        item.description!.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFFD6D0C6),
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        SizedBox(
                          width: 238,
                          child: TvFocusCard(
                            autofocus: true,
                            onPressed: item.canPlay ? () => onPlay(item) : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.play, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _primaryActionLabel(item),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 190,
                          child: TvFocusCard(
                            onPressed: () => onBrowse(item),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.arrowRight, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    VelaStrings.english.homeBrowse,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TvHeroShell extends StatelessWidget {
  const _TvHeroShell({required this.child, this.backgroundUrl});

  final Widget child;
  final String? backgroundUrl;

  @override
  Widget build(BuildContext context) {
    final hasBackground = backgroundUrl?.trim().isNotEmpty == true;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 900 || constraints.maxHeight < 560;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: compact ? 320 : 430,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFF111315)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasBackground)
                    Image.network(
                      backgroundUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xEE0C0D0E),
                          Color(0xBB0C0D0E),
                          Color(0x220C0D0E),
                        ],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xDD0C0D0E), Color(0x000C0D0E)],
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TvHomeCardRowSpec {
  const _TvHomeCardRowSpec({
    required this.title,
    required this.value,
    this.compactArtwork = false,
  });

  final String title;
  final AsyncValue<List<CatalogCardItem>> value;
  final bool compactArtwork;
}

class _TvHomeCardRail extends StatelessWidget {
  const _TvHomeCardRail({
    required this.spec,
    required this.onFocusItem,
    required this.onOpen,
  });

  final _TvHomeCardRowSpec spec;
  final ValueChanged<CatalogCardItem> onFocusItem;
  final ValueChanged<CatalogCardItem> onOpen;

  @override
  Widget build(BuildContext context) {
    return spec.value.when(
      loading: () => const SizedBox(
        height: 156,
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      ),
      error: (error, _) => _TvHomeMessage(
        icon: LucideIcons.circleAlert,
        title: spec.title,
        body: error.toString(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        final rowHeight = spec.compactArtwork ? 214.0 : 292.0;
        return Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TvSectionTitle(spec.title),
              const SizedBox(height: 14),
              SizedBox(
                height: rowHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _TvHomeCard(
                      item: item,
                      compactArtwork: spec.compactArtwork,
                      onFocus: () => onFocusItem(item),
                      onOpen: item.canPlay ? () => onOpen(item) : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TvHomeCard extends StatelessWidget {
  const _TvHomeCard({
    required this.item,
    required this.compactArtwork,
    required this.onFocus,
    required this.onOpen,
  });

  final CatalogCardItem item;
  final bool compactArtwork;
  final VoidCallback onFocus;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final width = compactArtwork ? 286.0 : 188.0;
    final artworkHeight = compactArtwork ? 138.0 : 206.0;
    return SizedBox(
      width: width,
      child: TvFocusCard(
        onPressed: onOpen,
        padding: const EdgeInsets.all(8),
        onFocusChange: (focused) {
          if (focused) {
            onFocus();
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 160),
              alignment: 0.5,
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: artworkHeight,
              child: _TvHomeArtwork(item: item, compact: compactArtwork),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _secondaryLabel(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TvHomeArtwork extends StatelessWidget {
  const _TvHomeArtwork({required this.item, required this.compact});

  final CatalogCardItem item;
  final bool compact;

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
        decoration: const BoxDecoration(color: Color(0xFF0C0D0E)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.hasArtwork)
              Image.network(
                item.artworkUrl!,
                fit: compact || item.contentType == CatalogContentType.live
                    ? BoxFit.contain
                    : BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(icon, color: const Color(0xFF716D66), size: 34),
              )
            else
              Icon(icon, color: const Color(0xFF716D66), size: 34),
            if (item.hasResumeProgress)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: item.resumeProgress,
                  backgroundColor: const Color(0x66000000),
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

class _TvPinnedCategoryRail extends StatelessWidget {
  const _TvPinnedCategoryRail({
    required this.title,
    required this.value,
    required this.onOpen,
  });

  final String title;
  final AsyncValue<List<HomeCategoryTile>> value;
  final ValueChanged<HomeCategoryTile> onOpen;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TvSectionTitle(title),
              const SizedBox(height: 14),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return SizedBox(
                      width: 290,
                      child: TvFocusCard(
                        onPressed: () => onOpen(category),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        onFocusChange: (focused) {
                          if (focused) {
                            Scrollable.ensureVisible(
                              context,
                              duration: const Duration(milliseconds: 160),
                              alignment: 0.5,
                            );
                          }
                        },
                        child: Row(
                          children: [
                            Icon(
                              category.section.icon,
                              color: Theme.of(context).colorScheme.primary,
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0,
                                          height: 1.05,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${category.itemCount} items',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TvHomeMessage extends StatelessWidget {
  const _TvHomeMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

VelaSection _sectionFor(CatalogContentType type) {
  return switch (type) {
    CatalogContentType.live => VelaSection.live,
    CatalogContentType.movie => VelaSection.movies,
    CatalogContentType.series => VelaSection.series,
  };
}

String _typeLabel(CatalogCardItem item) {
  return switch (item.contentType) {
    CatalogContentType.live => 'Live Channel',
    CatalogContentType.movie => 'Movie',
    CatalogContentType.series => 'Series',
  };
}

String _primaryActionLabel(CatalogCardItem item) {
  return item.seriesPlaybackLabel ??
      (item.hasResume ? 'Resume' : VelaStrings.english.homePlay);
}

String _secondaryLabel(CatalogCardItem item) {
  return item.epgSummary ??
      item.seriesPlaybackSummary ??
      item.subtitle ??
      _typeLabel(item);
}
