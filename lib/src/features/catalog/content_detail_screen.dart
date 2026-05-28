import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/navigation_controller.dart';
import '../../catalog/catalog_models.dart';
import '../../catalog/catalog_repository.dart';
import '../../catalog/watch_history_repository.dart';
import 'item_grid.dart';
import 'series_playback_progress.dart';

typedef CatalogPlayCallback =
    Future<void> Function(CatalogCardItem item, {bool restart});
typedef EpisodePlayCallback =
    Future<void> Function(CatalogCardItem item, CatalogEpisode episode);

final _detailCardProvider = StreamProvider.autoDispose
    .family<CatalogCardItem?, _DetailCardQuery>((ref, query) {
      final catalogRepository = ref.watch(catalogRepositoryProvider);
      final historyRepository = ref.watch(watchHistoryRepositoryProvider);
      return catalogRepository
          .watchItem(
            providerId: query.providerId,
            contentType: query.contentType,
            id: query.itemId,
          )
          .asyncMap((item) async {
            if (item == null) return null;
            return _catalogItemToCard(
              catalogRepository,
              historyRepository,
              item,
            );
          });
    });

final _detailEpisodesProvider = StreamProvider.autoDispose
    .family<List<CatalogEpisode>, _SeriesEpisodesQuery>((ref, query) {
      return ref
          .watch(catalogRepositoryProvider)
          .watchEpisodesForSeries(
            providerId: query.providerId,
            seriesId: query.seriesId,
          );
    });

final _episodePositionsProvider = StreamProvider.autoDispose
    .family<List<PlaybackPosition>, _SeriesEpisodesQuery>((ref, query) {
      return ref
          .watch(watchHistoryRepositoryProvider)
          .watchEpisodePositionsForSeries(
            providerId: query.providerId,
            seriesId: query.seriesId,
          );
    });

class ContentDetailScreen extends ConsumerStatefulWidget {
  const ContentDetailScreen({
    required this.initialItem,
    required this.onPlayItem,
    required this.onOpenEpisode,
    super.key,
  });

  final CatalogCardItem initialItem;
  final CatalogPlayCallback onPlayItem;
  final EpisodePlayCallback onOpenEpisode;

  @override
  ConsumerState<ContentDetailScreen> createState() =>
      _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  final Set<String> _requestedDetails = {};
  int? _selectedSeason;

  @override
  Widget build(BuildContext context) {
    final itemValue = ref.watch(
      _detailCardProvider(
        _DetailCardQuery(
          providerId: widget.initialItem.providerId,
          contentType: widget.initialItem.contentType,
          itemId: widget.initialItem.id,
        ),
      ),
    );
    final item = itemValue.value ?? widget.initialItem;
    final episodesValue = item.contentType == CatalogContentType.series
        ? ref.watch(
            _detailEpisodesProvider(
              _SeriesEpisodesQuery(
                providerId: item.providerId,
                seriesId: item.id,
              ),
            ),
          )
        : const AsyncValue.data(<CatalogEpisode>[]);
    final episodePositionsValue = item.contentType == CatalogContentType.series
        ? ref.watch(
            _episodePositionsProvider(
              _SeriesEpisodesQuery(
                providerId: item.providerId,
                seriesId: item.id,
              ),
            ),
          )
        : const AsyncValue.data(<PlaybackPosition>[]);
    final effectiveItem = _withLatestSeriesResume(
      item,
      episodesValue.value ?? const <CatalogEpisode>[],
      episodePositionsValue.value ?? const <PlaybackPosition>[],
    );

    _refreshDetailsIfNeeded(effectiveItem);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D0E),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailTopBar(
              item: effectiveItem,
              onBack: () => Navigator.of(context).maybePop(),
              onToggleFavorite: () => _toggleFavorite(effectiveItem),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final main = _DetailMain(
                    item: effectiveItem,
                    episodes: episodesValue,
                    episodePositions: episodePositionsValue,
                    selectedSeason: _selectedSeason,
                    onSeasonChanged: (season) {
                      setState(() => _selectedSeason = season);
                    },
                    onPlayItem: widget.onPlayItem,
                    onOpenEpisode: widget.onOpenEpisode,
                  );
                  if (!wide) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 10, 28, 34),
                      child: main,
                    );
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 18, 42, 42),
                    child: main,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshDetailsIfNeeded(CatalogCardItem item) {
    if (item.contentType == CatalogContentType.live) {
      return;
    }
    final key = '${item.providerId}|${item.contentType.name}|${item.id}';
    if (_requestedDetails.contains(key)) {
      return;
    }
    _requestedDetails.add(key);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(providerRefreshServiceProvider)
            .refreshCatalogItemDetails(
              providerId: item.providerId,
              itemId: item.id,
              contentType: item.contentType,
              externalId: item.externalId,
            )
            .catchError((Object error, StackTrace stackTrace) {
              debugPrint('Failed to load catalog item details: $error');
              debugPrintStack(stackTrace: stackTrace);
            }),
      );
    });
  }

  Future<void> _toggleFavorite(CatalogCardItem item) {
    return ref
        .read(catalogRepositoryProvider)
        .toggleItemFavorite(
          providerId: item.providerId,
          itemId: item.id,
          itemType: FavoriteItemType.fromCatalog(item.contentType),
        );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.item,
    required this.onBack,
    required this.onToggleFavorite,
  });

  final CatalogCardItem item;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(LucideIcons.arrowLeft),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(item),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: item.isFavorite ? 'Remove favorite' : 'Add favorite',
            onPressed: onToggleFavorite,
            icon: Icon(
              LucideIcons.star,
              color: item.isFavorite
                  ? theme.colorScheme.primary
                  : const Color(0xFFD7D0C6),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailMain extends StatelessWidget {
  const _DetailMain({
    required this.item,
    required this.episodes,
    required this.episodePositions,
    required this.selectedSeason,
    required this.onSeasonChanged,
    required this.onPlayItem,
    required this.onOpenEpisode,
  });

  final CatalogCardItem item;
  final AsyncValue<List<CatalogEpisode>> episodes;
  final AsyncValue<List<PlaybackPosition>> episodePositions;
  final int? selectedSeason;
  final ValueChanged<int> onSeasonChanged;
  final CatalogPlayCallback onPlayItem;
  final EpisodePlayCallback onOpenEpisode;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final poster = _PosterPanel(item: item, onPlayItem: onPlayItem);
    final details = _MetadataPanel(
      item: item,
      episodes: episodes,
      episodePositions: episodePositions,
      selectedSeason: selectedSeason,
      onSeasonChanged: onSeasonChanged,
      onOpenEpisode: onOpenEpisode,
    );

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [poster, const SizedBox(height: 22), details],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 320, child: poster),
        const SizedBox(width: 34),
        Expanded(child: details),
      ],
    );
  }
}

class _PosterPanel extends StatelessWidget {
  const _PosterPanel({required this.item, required this.onPlayItem});

  final CatalogCardItem item;
  final CatalogPlayCallback onPlayItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: item.contentType == CatalogContentType.movie ? 0.68 : 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFF151719)),
              child: item.hasArtwork
                  ? Image.network(
                      item.artworkUrl!,
                      fit: item.contentType == CatalogContentType.movie
                          ? BoxFit.cover
                          : BoxFit.contain,
                      errorBuilder: (_, _, _) => _FallbackPoster(item: item),
                    )
                  : _FallbackPoster(item: item),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: item.canPlay ? () => unawaited(onPlayItem(item)) : null,
          icon: const Icon(LucideIcons.play, size: 18),
          label: Text(
            _primaryActionLabel(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (item.hasPlaybackProgress) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => unawaited(onPlayItem(item, restart: true)),
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text('Restart'),
          ),
        ],
      ],
    );
  }
}

class _MetadataPanel extends StatelessWidget {
  const _MetadataPanel({
    required this.item,
    required this.episodes,
    required this.episodePositions,
    required this.selectedSeason,
    required this.onSeasonChanged,
    required this.onOpenEpisode,
  });

  final CatalogCardItem item;
  final AsyncValue<List<CatalogEpisode>> episodes;
  final AsyncValue<List<PlaybackPosition>> episodePositions;
  final int? selectedSeason;
  final ValueChanged<int> onSeasonChanged;
  final EpisodePlayCallback onOpenEpisode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.title,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (item.year != null) _MetaChip(label: item.year.toString()),
            if (item.rating?.trim().isNotEmpty == true)
              _MetaChip(label: 'Rating ${item.rating}'),
            if (item.durationSeconds != null)
              _MetaChip(label: _duration(item.durationSeconds!)),
            if (item.hasPlaybackProgress)
              _MetaChip(
                label: item.seriesPlaybackSummary ?? 'Resume available',
              ),
          ],
        ),
        const SizedBox(height: 24),
        _OverviewBlock(description: item.description),
        if (item.contentType == CatalogContentType.series) ...[
          const SizedBox(height: 30),
          _EpisodeSection(
            item: item,
            episodes: episodes,
            episodePositions: episodePositions,
            selectedSeason: selectedSeason,
            onSeasonChanged: onSeasonChanged,
            onOpenEpisode: onOpenEpisode,
          ),
        ],
      ],
    );
  }
}

class _OverviewBlock extends StatelessWidget {
  const _OverviewBlock({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clean = description?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          clean?.isNotEmpty == true
              ? clean!
              : 'Loading description from the provider.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _EpisodeSection extends StatelessWidget {
  const _EpisodeSection({
    required this.item,
    required this.episodes,
    required this.episodePositions,
    required this.selectedSeason,
    required this.onSeasonChanged,
    required this.onOpenEpisode,
  });

  final CatalogCardItem item;
  final AsyncValue<List<CatalogEpisode>> episodes;
  final AsyncValue<List<PlaybackPosition>> episodePositions;
  final int? selectedSeason;
  final ValueChanged<int> onSeasonChanged;
  final EpisodePlayCallback onOpenEpisode;

  @override
  Widget build(BuildContext context) {
    return episodes.when(
      data: (items) {
        final playable = items.where(episodeCanPlay).toList();
        if (playable.isEmpty) {
          return const _NoticePanel(
            icon: LucideIcons.listVideo,
            title: 'Episodes unavailable',
            body: 'The provider has not returned playable episode details yet.',
          );
        }
        final positions = episodePositions.value ?? const <PlaybackPosition>[];
        final positionByEpisode = positionsByEpisode(positions);
        final seriesAction = resolveSeriesPlaybackAction(
          episodes: playable,
          positions: positions,
        );
        final activeEpisode = seriesAction?.episode;
        final seasons = playable.map((episode) => episode.seasonNumber).toSet();
        final sortedSeasons = seasons.toList()..sort();
        final activeSeason =
            selectedSeason != null && sortedSeasons.contains(selectedSeason)
            ? selectedSeason!
            : activeEpisode != null &&
                  sortedSeasons.contains(activeEpisode.seasonNumber)
            ? activeEpisode.seasonNumber
            : sortedSeasons.first;
        final visible = playable
            .where((episode) => episode.seasonNumber == activeSeason)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Episodes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                _SeasonDropdown(
                  seasons: sortedSeasons,
                  selectedSeason: activeSeason,
                  onChanged: onSeasonChanged,
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final episode in visible)
              _EpisodeTile(
                item: item,
                episode: episode,
                position: positionByEpisode[catalogEpisodePositionKey(episode)],
                isCurrentResume:
                    activeEpisode != null &&
                    episode.id == activeEpisode.id &&
                    episode.seasonId == activeEpisode.seasonId,
                onOpenEpisode: onOpenEpisode,
              ),
          ],
        );
      },
      loading: () => const _NoticePanel(
        icon: LucideIcons.listVideo,
        title: 'Loading episodes',
        body: 'Fetching seasons and episodes for this series.',
      ),
      error: (_, _) => const _NoticePanel(
        icon: LucideIcons.listX,
        title: 'Episodes unavailable',
        body: 'The provider did not return episode details.',
      ),
    );
  }
}

class _SeasonDropdown extends StatelessWidget {
  const _SeasonDropdown({
    required this.seasons,
    required this.selectedSeason,
    required this.onChanged,
  });

  final List<int> seasons;
  final int selectedSeason;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: selectedSeason,
      borderRadius: BorderRadius.circular(8),
      dropdownColor: const Color(0xFF151719),
      items: [
        for (final season in seasons)
          DropdownMenuItem(value: season, child: Text('Season $season')),
      ],
      onChanged: (season) {
        if (season != null) onChanged(season);
      },
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.item,
    required this.episode,
    required this.position,
    required this.isCurrentResume,
    required this.onOpenEpisode,
  });

  final CatalogCardItem item;
  final CatalogEpisode episode;
  final PlaybackPosition? position;
  final bool isCurrentResume;
  final EpisodePlayCallback onOpenEpisode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF151719),
        border: Border.all(
          color: isCurrentResume
              ? theme.colorScheme.primary
              : const Color(0xFF292D31),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => unawaited(onOpenEpisode(item, episode)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    episode.episodeNumber.toString().padLeft(2, '0'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        episode.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _episodeSubtitle(episode),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFA9A39A),
                        ),
                      ),
                      if (position != null) ...[
                        const SizedBox(height: 8),
                        _EpisodeProgress(position: position!),
                      ],
                      if (episode.description?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          episode.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(LucideIcons.play, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeProgress extends StatelessWidget {
  const _EpisodeProgress({required this.position});

  final PlaybackPosition position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = position.completionPercentage.clamp(0, 1).toDouble();
    final label = position.completed
        ? 'Watched'
        : 'Resume ${_duration(position.positionSeconds)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        if (progress > 0) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              backgroundColor: const Color(0xFF292D31),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NoticePanel extends StatelessWidget {
  const _NoticePanel({
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
    return Container(
      padding: const EdgeInsets.all(16),
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
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _FallbackPoster extends StatelessWidget {
  const _FallbackPoster({required this.item});

  final CatalogCardItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.contentType) {
      CatalogContentType.live => LucideIcons.tv,
      CatalogContentType.movie => LucideIcons.film,
      CatalogContentType.series => LucideIcons.library,
    };
    return Center(child: Icon(icon, size: 54, color: const Color(0xFF716D66)));
  }
}

class _DetailCardQuery {
  const _DetailCardQuery({
    required this.providerId,
    required this.contentType,
    required this.itemId,
  });

  final String providerId;
  final CatalogContentType contentType;
  final String itemId;

  @override
  bool operator ==(Object other) {
    return other is _DetailCardQuery &&
        other.providerId == providerId &&
        other.contentType == contentType &&
        other.itemId == itemId;
  }

  @override
  int get hashCode => Object.hash(providerId, contentType, itemId);
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

Future<CatalogCardItem> _catalogItemToCard(
  CatalogRepository catalogRepository,
  WatchHistoryRepository historyRepository,
  CatalogItem item,
) async {
  if (item.contentType == CatalogContentType.series) {
    final latestPosition = await historyRepository
        .lookupLatestPositionForSeries(
          providerId: item.providerId,
          seriesId: item.id,
        );
    final seriesAction = latestPosition == null
        ? null
        : resolveSeriesPlaybackAction(
            episodes: await catalogRepository.listEpisodesForSeries(
              providerId: item.providerId,
              seriesId: item.id,
            ),
            positions: [latestPosition],
          );
    return _cardFromItem(
      item,
      resume: seriesAction?.resume,
      seriesPlaybackAction: seriesAction,
      canPlayOverride: true,
    );
  }
  final resume = item.contentType == CatalogContentType.movie
      ? await historyRepository.lookupResumePosition(
          providerId: item.providerId,
          itemId: item.id,
          itemType: PlayableContentType.movie,
        )
      : null;
  return _cardFromItem(item, resume: resume);
}

CatalogCardItem _cardFromItem(
  CatalogItem item, {
  PlaybackPosition? resume,
  SeriesPlaybackAction? seriesPlaybackAction,
  bool? canPlayOverride,
}) {
  return CatalogCardItem(
    id: item.id,
    providerId: item.providerId,
    contentType: item.contentType,
    title: item.title,
    externalId: item.externalId,
    subtitle: seriesPlaybackAction?.subtitle ?? _subtitleFor(item),
    description: item.description,
    artworkUrl: item.artworkUrl,
    streamUrl: item.streamUrl,
    streamJson: item.streamJson,
    year: item.year,
    rating: item.rating,
    durationSeconds: item.durationSeconds,
    epgChannelId: item.epgChannelId,
    resumePositionSeconds:
        seriesPlaybackAction?.resume?.positionSeconds ??
        resume?.positionSeconds ??
        0,
    resumeDurationSeconds:
        seriesPlaybackAction?.resume?.durationSeconds ??
        resume?.durationSeconds,
    seriesPlaybackLabel: seriesPlaybackAction?.primaryLabel,
    seriesPlaybackSummary: seriesPlaybackAction?.summaryLabel,
    isFavorite: item.isFavorite,
    canPlay:
        canPlayOverride ??
        (item.streamUrl?.trim().isNotEmpty == true ||
            item.streamJson?.trim().isNotEmpty == true),
  );
}

String? _subtitleFor(CatalogItem item) {
  final parts = <String>[
    if (item.subtitle?.trim().isNotEmpty == true) item.subtitle!.trim(),
    if (item.year != null) item.year.toString(),
    if (item.rating?.trim().isNotEmpty == true) 'Rating ${item.rating}',
  ];
  return parts.isEmpty ? null : parts.join(' / ');
}

String _typeLabel(CatalogCardItem item) {
  return switch (item.contentType) {
    CatalogContentType.live => 'Live channel',
    CatalogContentType.movie => 'Movie',
    CatalogContentType.series => 'Series',
  };
}

String _primaryActionLabel(CatalogCardItem item) {
  if (!item.canPlay) return 'Unavailable';
  final seriesLabel = item.seriesPlaybackLabel?.trim();
  if (seriesLabel?.isNotEmpty == true) {
    return seriesLabel!;
  }
  if (item.hasResume) {
    final episodePrefix = _resumeEpisodePrefix(item);
    if (episodePrefix != null) {
      return 'Resume $episodePrefix';
    }
    return item.resumePositionSeconds < 60
        ? 'Resume'
        : 'Resume ${_duration(item.resumePositionSeconds)}';
  }
  if (item.contentType == CatalogContentType.series) {
    return 'Play First Episode';
  }
  return 'Play';
}

CatalogCardItem _withLatestSeriesResume(
  CatalogCardItem item,
  List<CatalogEpisode> episodes,
  List<PlaybackPosition> positions,
) {
  if (item.contentType != CatalogContentType.series) {
    return item;
  }
  final resume = latestResumablePosition(positions);
  final seriesAction = resolveSeriesPlaybackAction(
    episodes: episodes,
    positions: positions,
  );
  if (seriesAction == null && resume == null) {
    return item;
  }
  return item.copyWith(
    subtitle: seriesAction?.subtitle ?? item.subtitle,
    resumePositionSeconds:
        seriesAction?.resume?.positionSeconds ?? resume?.positionSeconds ?? 0,
    resumeDurationSeconds:
        seriesAction?.resume?.durationSeconds ?? resume?.durationSeconds,
    seriesPlaybackLabel: seriesAction?.primaryLabel,
    seriesPlaybackSummary: seriesAction?.summaryLabel,
  );
}

String? _resumeEpisodePrefix(CatalogCardItem item) {
  if (item.contentType != CatalogContentType.series) {
    return null;
  }
  final subtitle = item.subtitle?.trim();
  if (subtitle == null || !subtitle.startsWith('S')) {
    return null;
  }
  return subtitle.split('/').first.trim();
}

String _duration(int seconds) {
  if (seconds < 60) return '1m';
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours <= 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}

String _episodeSubtitle(CatalogEpisode episode) {
  final parts = <String>[
    'S${episode.seasonNumber} E${episode.episodeNumber}',
    if (episode.durationSeconds != null) _duration(episode.durationSeconds!),
  ];
  return parts.join(' / ');
}
