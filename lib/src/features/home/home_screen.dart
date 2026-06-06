import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/navigation_controller.dart';
import '../../app/section_state.dart';
import '../../app/vela_strings.dart';
import '../../catalog/catalog_models.dart';
import '../../playback/playable_item.dart';
import '../catalog/catalog_playback_target.dart';
import '../catalog/content_detail_screen.dart';
import '../catalog/item_grid.dart';
import '../providers/provider_setup_screen.dart';
import 'home_data.dart';
import 'home_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({required this.onOpenPlayer, super.key});

  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(providersProvider);
    return providers.when(
      loading: () => const ColoredBox(
        color: Color(0xFF0C0D0E),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _HomeError(message: error.toString()),
      data: (items) {
        final setupState = ref.watch(providerSetupImportControllerProvider);
        final hasImportedCatalog = items.any(
          (provider) => provider.hasImportedCatalog,
        );
        if (!hasImportedCatalog || setupState.shouldKeepSetupVisible) {
          return const ProviderSetupScreen();
        }

        final strings = VelaStrings.of(context);
        final heroValue = ref.watch(homeHeroProvider);
        final rows = [
          _HomeCardRowSpec(
            title: strings.homeContinueWatching,
            value: ref.watch(homeContinueWatchingProvider),
          ),
          _HomeCardRowSpec(
            title: strings.homeRecentLive,
            value: ref.watch(homeRecentLiveProvider),
            compactArtwork: true,
          ),
          _HomeCardRowSpec(
            title: strings.homeLatestMovies,
            value: ref.watch(homeLatestMoviesProvider),
          ),
          _HomeCardRowSpec(
            title: strings.homeLatestSeries,
            value: ref.watch(homeLatestSeriesProvider),
          ),
          _HomeCardRowSpec(
            title: strings.homeFavorites,
            value: ref.watch(homeFavoritesProvider),
          ),
        ];
        final categoriesValue = ref.watch(homePinnedCategoriesProvider);

        return Directionality(
          textDirection: strings.textDirection,
          child: ColoredBox(
            color: const Color(0xFF0C0D0E),
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 26, 30, 8),
                      child: _HomeHero(
                        value: heroValue,
                        onPlay: (item) => _openItem(ref, item),
                        onDetails: (item) => _openDetails(context, ref, item),
                        onBrowse: (item) => _browseItem(ref, item),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 8, 30, 0),
                      child: Text(
                        strings.homeSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  for (final row in rows)
                    SliverToBoxAdapter(
                      child: _HomeCardRail(
                        spec: row,
                        onSelect: (item) => _selectHomeItem(ref, item),
                        onOpen: (item) => _openItem(ref, item),
                        onDetails: (item) => _openDetails(context, ref, item),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: _PinnedCategoryRail(
                      title: strings.homePinnedCategories,
                      value: categoriesValue,
                      onOpen: (category) => _openCategory(ref, category),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 34)),
                ],
              ),
            ),
          ),
        );
      },
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
      debugPrint('Failed to open home item: $error');
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
      debugPrint('Failed to open home episode: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _openDetails(
    BuildContext context,
    WidgetRef ref,
    CatalogCardItem item,
  ) async {
    if (item.contentType == CatalogContentType.live) {
      _browseItem(ref, item);
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

  void _browseItem(WidgetRef ref, CatalogCardItem item) {
    final navigation = ref.read(navigationControllerProvider);
    navigation.selectSection(_sectionFor(item.contentType));
    navigation.selectCategory(null);
    navigation.selectItem(item.id);
  }

  void _selectHomeItem(WidgetRef ref, CatalogCardItem item) {
    ref.read(navigationControllerProvider).selectHomeItem(item.id);
  }

  void _openCategory(WidgetRef ref, HomeCategoryTile category) {
    final navigation = ref.read(navigationControllerProvider);
    navigation.selectSection(category.section);
    navigation.selectCategory(category.id);
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.value,
    required this.onPlay,
    required this.onDetails,
    required this.onBrowse,
  });

  final AsyncValue<CatalogCardItem?> value;
  final ValueChanged<CatalogCardItem> onPlay;
  final ValueChanged<CatalogCardItem> onDetails;
  final ValueChanged<CatalogCardItem> onBrowse;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const _HeroShell(
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      ),
      error: (error, _) => _HeroShell(
        child: _HomeMessage(
          icon: LucideIcons.circleAlert,
          title: VelaStrings.english.homeRowsUnavailable,
          body: error.toString(),
        ),
      ),
      data: (item) {
        if (item == null) {
          return _HeroShell(
            child: _HomeMessage(
              icon: LucideIcons.sparkles,
              title: VelaStrings.english.homeEmptyTitle,
              body: VelaStrings.english.homeEmptyBody,
            ),
          );
        }
        return _HeroShell(
          backgroundUrl: item.artworkUrl,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeLabel(item),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFD6D0C6),
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (item.canPlay)
                          FilledButton.icon(
                            onPressed: () => onPlay(item),
                            icon: const Icon(LucideIcons.play),
                            label: Text(_primaryActionLabel(item)),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => onDetails(item),
                          icon: Icon(
                            item.contentType == CatalogContentType.live
                                ? LucideIcons.list
                                : LucideIcons.info,
                          ),
                          label: Text(
                            item.contentType == CatalogContentType.live
                                ? VelaStrings.english.homeBrowse
                                : VelaStrings.english.homeDetails,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => onBrowse(item),
                          icon: const Icon(LucideIcons.arrowRight),
                          label: const Text('Open in catalog'),
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

class _HeroShell extends StatelessWidget {
  const _HeroShell({required this.child, this.backgroundUrl});

  final Widget child;
  final String? backgroundUrl;

  @override
  Widget build(BuildContext context) {
    final hasBackground = backgroundUrl?.trim().isNotEmpty == true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 380,
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
                      Color(0xAA0C0D0E),
                      Color(0x330C0D0E),
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
  }
}

class _HomeCardRowSpec {
  const _HomeCardRowSpec({
    required this.title,
    required this.value,
    this.compactArtwork = false,
  });

  final String title;
  final AsyncValue<List<CatalogCardItem>> value;
  final bool compactArtwork;
}

class _HomeCardRail extends StatelessWidget {
  const _HomeCardRail({
    required this.spec,
    required this.onSelect,
    required this.onOpen,
    required this.onDetails,
  });

  final _HomeCardRowSpec spec;
  final ValueChanged<CatalogCardItem> onSelect;
  final ValueChanged<CatalogCardItem> onOpen;
  final ValueChanged<CatalogCardItem> onDetails;

  @override
  Widget build(BuildContext context) {
    return spec.value.when(
      loading: () => _RailShell(
        title: spec.title,
        child: const SizedBox(
          height: 206,
          child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
      ),
      error: (error, _) => _RailShell(
        title: spec.title,
        child: _HomeInlineError(message: error.toString()),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return _RailShell(
          title: spec.title,
          child: SizedBox(
            height: spec.compactArtwork ? 178 : 248,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = items[index];
                return _HomeCard(
                  item: item,
                  compactArtwork: spec.compactArtwork,
                  onSelect: () => onSelect(item),
                  onOpen: item.canPlay ? () => onOpen(item) : null,
                  onDetails: () => onDetails(item),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _RailShell extends StatelessWidget {
  const _RailShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.item,
    required this.compactArtwork,
    required this.onSelect,
    required this.onOpen,
    required this.onDetails,
  });

  final CatalogCardItem item;
  final bool compactArtwork;
  final VoidCallback onSelect;
  final VoidCallback? onOpen;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final width = compactArtwork ? 222.0 : 168.0;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onSelect,
          onDoubleTap: onOpen,
          onLongPress: onDetails,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: compactArtwork ? 124 : 178,
                child: _HomeArtwork(item: item, compact: compactArtwork),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _secondaryLabel(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeArtwork extends StatelessWidget {
  const _HomeArtwork({required this.item, required this.compact});

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
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF151719),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
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
                    Icon(icon, color: const Color(0xFF716D66), size: 36),
              )
            else
              Icon(icon, color: const Color(0xFF716D66), size: 36),
            if (item.hasResumeProgress)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: item.resumeProgress,
                  backgroundColor: const Color(0x66000000),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
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
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      LucideIcons.play,
                      size: 13,
                      color: Color(0xFF0C0D0E),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinnedCategoryRail extends StatelessWidget {
  const _PinnedCategoryRail({
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
        return _RailShell(
          title: title,
          child: SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryShortcut(
                  category: category,
                  onPressed: () => onOpen(category),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({required this.category, required this.onPressed});

  final HomeCategoryTile category;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(category.section.icon),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                '${category.itemCount} items',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 38),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeInlineError extends StatelessWidget {
  const _HomeInlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFE26D5A)),
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0C0D0E),
      child: _HomeMessage(
        icon: LucideIcons.circleAlert,
        title: VelaStrings.english.homeRowsUnavailable,
        body: message,
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
