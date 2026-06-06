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
        if (!hasImportedCatalog || setupState.shouldBlockImportedCatalog) {
          return const ProviderSetupScreen();
        }

        final strings = VelaStrings.of(context);
        final heroValue = ref.watch(homeHeroProvider);
        final backgroundItem = heroValue.when<CatalogCardItem?>(
          data: _backgroundItemFor,
          loading: () => null,
          error: (_, _) => null,
        );
        final rows = [
          _HomeCardRowSpec(
            title: strings.homeContinueWatching,
            value: ref.watch(homeContinueWatchingProvider),
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

        return Directionality(
          textDirection: strings.textDirection,
          child: ColoredBox(
            color: const Color(0xFF0C0D0E),
            child: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _HomeBackground(item: backgroundItem),
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
                          child: _HomeHero(
                            value: heroValue,
                            onPlay: (item) => _openItem(ref, item),
                            onDetails: (item) =>
                                _openDetails(context, ref, item),
                            onBrowse: (item) => _browseItem(ref, item),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
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
                            onDetails: (item) =>
                                _openDetails(context, ref, item),
                          ),
                        ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
                    ],
                  ),
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
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground({required this.item});

  final CatalogCardItem? item;

  @override
  Widget build(BuildContext context) {
    final backgroundUrl = item?.artworkUrl?.trim();
    final hasBackground = backgroundUrl != null && backgroundUrl.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(color: Color(0xFF0C0D0E))),
        if (hasBackground)
          Image.network(
            backgroundUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xDD0C0D0E), Color(0xCC0C0D0E), Color(0xF20C0D0E)],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xEE0C0D0E), Color(0xAA0C0D0E)],
            ),
          ),
        ),
      ],
    );
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
          child: Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.all(22),
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
  const _HeroShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: compact ? 280 : 320,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0x66111315)),
              child: Stack(
                fit: StackFit.expand,
                children: [
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
      },
    );
  }
}

class _HomeCardRowSpec {
  const _HomeCardRowSpec({required this.title, required this.value});

  final String title;
  final AsyncValue<List<CatalogCardItem>> value;
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
          height: 172,
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
            height: 218,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _HomeCard(
                  item: item,
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
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
    required this.onSelect,
    required this.onOpen,
    required this.onDetails,
  });

  final CatalogCardItem item;
  final VoidCallback onSelect;
  final VoidCallback? onOpen;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    const width = 148.0;
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
              SizedBox(height: 154, child: _HomeArtwork(item: item)),
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
  const _HomeArtwork({required this.item});

  final CatalogCardItem item;

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
                fit: item.contentType == CatalogContentType.live
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

CatalogCardItem? _backgroundItemFor(CatalogCardItem? item) {
  if (item == null || !item.hasArtwork) {
    return null;
  }
  return switch (item.contentType) {
    CatalogContentType.movie || CatalogContentType.series => item,
    CatalogContentType.live => null,
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
