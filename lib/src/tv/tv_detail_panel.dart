import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app/navigation_controller.dart';
import '../catalog/catalog_models.dart';
import '../features/catalog/catalog_playback_target.dart';
import '../features/catalog/item_grid.dart';
import '../playback/playable_item.dart';
import 'tv_focus.dart';

class TvDetailPanel extends ConsumerWidget {
  const TvDetailPanel({
    required this.item,
    required this.onOpenPlayer,
    super.key,
  });

  final CatalogCardItem? item;
  final ValueChanged<PlayableItem> onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = this.item;
    if (item == null) {
      return const _TvDetailEmptyState();
    }

    final theme = Theme.of(context);
    final metadata = _metadataFor(item);
    final episodesFuture = item.contentType == CatalogContentType.series
        ? episodesForSeries(ref, item)
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111315),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 168, child: _TvDetailArtwork(item: item)),
            const SizedBox(height: 18),
            Text(
              item.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                height: 1.05,
              ),
            ),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                metadata,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFC8C1B7),
                  letterSpacing: 0,
                ),
              ),
            ],
            if (item.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Text(
                item.description!.trim(),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: const Color(0xFFAFA8A0),
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 64,
              child: TvFocusCard(
                onPressed: () => unawaited(_openCard(ref, item)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (item.contentType == CatalogContentType.series) ...[
              const SizedBox(height: 20),
              Text(
                'Episodes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<CatalogEpisode>>(
                  future: episodesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      );
                    }
                    if (snapshot.hasError) {
                      return _TvDetailMessage(
                        title: 'Episodes unavailable',
                        body: snapshot.error.toString(),
                      );
                    }
                    final episodes = snapshot.data ?? const <CatalogEpisode>[];
                    if (episodes.isEmpty) {
                      return const _TvDetailMessage(
                        title: 'No episodes',
                        body: 'This series has no imported episodes yet.',
                      );
                    }
                    return ListView.separated(
                      itemCount: episodes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final episode = episodes[index];
                        return _TvEpisodeRow(
                          episode: episode,
                          onOpen: () => unawaited(
                            _openEpisode(
                              ref,
                              episode: episode,
                              episodes: episodes,
                              fallbackPosterUrl: item.artworkUrl,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  Future<void> _openCard(WidgetRef ref, CatalogCardItem item) async {
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

  Future<void> _openEpisode(
    WidgetRef ref, {
    required CatalogEpisode episode,
    required List<CatalogEpisode> episodes,
    String? fallbackPosterUrl,
  }) async {
    try {
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
        fallbackPosterUrl: fallbackPosterUrl,
        resume: resume,
      );
      if (target == null) return;
      onOpenPlayer(target.playable);
    } catch (error, stackTrace) {
      debugPrint('Failed to open TV episode: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

class _TvDetailArtwork extends StatelessWidget {
  const _TvDetailArtwork({required this.item});

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
      borderRadius: BorderRadius.circular(8),
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
                    Icon(icon, size: 52, color: const Color(0xFF716D66)),
              )
            else
              Icon(icon, size: 52, color: const Color(0xFF716D66)),
            if (item.hasResumeProgress)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  minHeight: 5,
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

class _TvEpisodeRow extends StatelessWidget {
  const _TvEpisodeRow({required this.episode, required this.onOpen});

  final CatalogEpisode episode;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playable = catalogEpisodeHasPlayableStream(episode);
    return SizedBox(
      height: 78,
      child: TvFocusCard(
        onPressed: onOpen,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                'S${episode.seasonNumber} E${episode.episodeNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFE7B85B),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                episode.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: playable ? null : const Color(0xFF8B8580),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              playable ? LucideIcons.play : LucideIcons.circleSlash,
              size: 20,
              color: playable
                  ? theme.colorScheme.primary
                  : const Color(0xFF716D66),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvDetailEmptyState extends StatelessWidget {
  const _TvDetailEmptyState();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF111315),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Center(
        child: _TvDetailMessage(
          title: 'Select a title',
          body: 'Details appear here.',
        ),
      ),
    );
  }
}

class _TvDetailMessage extends StatelessWidget {
  const _TvDetailMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFAFA8A0),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

String _primaryActionLabel(CatalogCardItem item) {
  if (item.seriesPlaybackLabel?.trim().isNotEmpty == true) {
    return item.seriesPlaybackLabel!;
  }
  if (item.hasResume) {
    return 'Resume';
  }
  return 'Play';
}

String _metadataFor(CatalogCardItem item) {
  final parts = <String>[
    _typeLabel(item.contentType),
    if (item.subtitle?.trim().isNotEmpty == true) item.subtitle!.trim(),
    if (item.seriesPlaybackSummary?.trim().isNotEmpty == true)
      item.seriesPlaybackSummary!.trim(),
    if (item.year != null) item.year.toString(),
    if (item.rating?.trim().isNotEmpty == true) 'Rating ${item.rating}',
    if (item.durationSeconds != null) _durationLabel(item.durationSeconds!),
  ];
  return parts.toSet().join(' / ');
}

String _typeLabel(CatalogContentType type) {
  return switch (type) {
    CatalogContentType.live => 'Live',
    CatalogContentType.movie => 'Movie',
    CatalogContentType.series => 'Series',
  };
}

String _durationLabel(int seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) {
    return '${minutes}m';
  }
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (remainder == 0) {
    return '${hours}h';
  }
  return '${hours}h ${remainder}m';
}
