import '../../catalog/catalog_models.dart';
import '../../catalog/catalog_repository.dart';
import '../../catalog/watch_history_repository.dart';
import 'item_grid.dart';
import 'series_playback_progress.dart';

Future<List<CatalogCardItem>> catalogItemsToCards(
  CatalogRepository catalogRepository,
  WatchHistoryRepository historyRepository,
  List<CatalogItem> items,
) async {
  final providerIds = items.map((item) => item.providerId).toSet();
  final hasMovies = items.any(
    (item) => item.contentType == CatalogContentType.movie,
  );
  final hasSeries = items.any(
    (item) => item.contentType == CatalogContentType.series,
  );
  final movieResumes = hasMovies
      ? await historyRepository.listActiveResumePositions(
          itemType: PlayableContentType.movie,
          providerIds: providerIds,
        )
      : <({String providerId, String itemId}), PlaybackPosition>{};
  final seriesPositions = hasSeries
      ? await historyRepository.listEpisodePositionsBySeries(
          seriesKeys: items
              .where((item) => item.contentType == CatalogContentType.series)
              .map((item) => (providerId: item.providerId, seriesId: item.id)),
        )
      : <({String providerId, String seriesId}), List<PlaybackPosition>>{};
  final cards = <CatalogCardItem>[];
  for (final item in items) {
    if (item.contentType != CatalogContentType.series) {
      cards.add(
        catalogItemToCard(
          item,
          resume: item.contentType == CatalogContentType.movie
              ? movieResumes[(providerId: item.providerId, itemId: item.id)]
              : null,
        ),
      );
      continue;
    }
    final positions =
        seriesPositions[(providerId: item.providerId, seriesId: item.id)];
    final seriesAction = positions == null || positions.isEmpty
        ? null
        : await _seriesPlaybackActionForPositions(
            catalogRepository: catalogRepository,
            item: item,
            positions: positions,
          );
    cards.add(
      catalogItemToCard(
        item,
        canPlayOverride: true,
        resume: seriesAction?.resume,
        seriesPlaybackAction: seriesAction,
      ),
    );
  }
  return cards;
}

Future<CatalogCardItem> recentToResolvedCard(
  CatalogRepository catalogRepository,
  WatchHistoryRepository historyRepository,
  WatchHistoryEntry entry,
) async {
  if (entry.itemType == PlayableContentType.episode &&
      entry.seriesId?.trim().isNotEmpty == true) {
    final card = await _recentEpisodeToSeriesCard(
      catalogRepository,
      historyRepository,
      entry,
    );
    if (card != null) {
      return card;
    }
  }

  final resolved = await _resolveRecentCatalogItem(catalogRepository, entry);
  if (resolved != null) {
    final card = catalogItemToCard(resolved);
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
      epgChannelId: card.epgChannelId,
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

Future<SeriesPlaybackAction?> _seriesPlaybackActionForPositions({
  required CatalogRepository catalogRepository,
  required CatalogItem item,
  required List<PlaybackPosition> positions,
}) async {
  final episodes = await catalogRepository.listEpisodesForSeries(
    providerId: item.providerId,
    seriesId: item.id,
  );
  return resolveSeriesPlaybackAction(episodes: episodes, positions: positions);
}

CatalogCardItem catalogItemToCard(
  CatalogItem item, {
  bool? canPlayOverride,
  PlaybackPosition? resume,
  String? subtitleOverride,
  SeriesPlaybackAction? seriesPlaybackAction,
}) {
  return CatalogCardItem(
    id: item.id,
    providerId: item.providerId,
    contentType: item.contentType,
    title: item.title,
    externalId: item.externalId,
    subtitle:
        subtitleOverride ??
        seriesPlaybackAction?.subtitle ??
        _subtitleFor(item),
    description: item.description,
    artworkUrl: item.artworkUrl,
    streamUrl: item.streamUrl,
    streamJson: item.streamJson,
    year: item.year,
    rating: item.rating,
    durationSeconds: item.durationSeconds,
    epgChannelId: item.epgChannelId,
    epgSummary: item.contentType == CatalogContentType.live
        ? item.subtitle ?? item.description ?? item.epgChannelId
        : null,
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
        _hasPlayableStream(
          streamUrl: item.streamUrl,
          streamJson: item.streamJson,
        ),
  );
}

Future<CatalogCardItem?> _recentEpisodeToSeriesCard(
  CatalogRepository catalogRepository,
  WatchHistoryRepository historyRepository,
  WatchHistoryEntry entry,
) async {
  final seriesId = entry.seriesId;
  if (seriesId == null || seriesId.trim().isEmpty) {
    return null;
  }
  final series = await catalogRepository.getItem(
    providerId: entry.providerId,
    contentType: CatalogContentType.series,
    id: seriesId,
  );
  if (series == null) {
    return null;
  }
  final episode = await catalogRepository.getEpisode(
    providerId: entry.providerId,
    seriesId: seriesId,
    episodeId: entry.itemId,
    seasonId: entry.seasonId,
  );
  final episodes = await catalogRepository.listEpisodesForSeries(
    providerId: entry.providerId,
    seriesId: seriesId,
  );
  final resume = PlaybackPosition(
    providerId: entry.providerId,
    itemId: entry.itemId,
    itemType: PlayableContentType.episode,
    seriesId: seriesId,
    seasonId: entry.seasonId,
    positionSeconds: entry.completed ? 0 : entry.positionSeconds,
    durationSeconds: entry.durationSeconds,
    completionPercentage: entry.completionPercentage,
    completed: entry.completed,
    updatedAtMs: entry.lastWatchedAtMs,
  );
  final positions = await historyRepository.listEpisodePositionsForSeries(
    providerId: entry.providerId,
    seriesId: seriesId,
  );
  final seriesAction = positions.isEmpty
      ? null
      : resolveSeriesPlaybackAction(episodes: episodes, positions: positions);
  final effectiveResume =
      seriesAction?.resume ?? latestResumablePosition(positions) ?? resume;
  return catalogItemToCard(
    series,
    canPlayOverride: true,
    resume: effectiveResume,
    seriesPlaybackAction: seriesAction,
    subtitleOverride:
        seriesAction?.subtitle ??
        _seriesResumeSubtitle(episode) ??
        entry.subtitle,
  ).copyWith(isRecent: true);
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

String? _seriesResumeSubtitle(CatalogEpisode? episode) {
  if (episode == null) {
    return null;
  }
  final episodeTitle = episode.title.trim();
  final prefix = 'S${episode.seasonNumber} E${episode.episodeNumber}';
  if (episodeTitle.isEmpty) {
    return prefix;
  }
  return '$prefix / $episodeTitle';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
