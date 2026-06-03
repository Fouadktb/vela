import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation_controller.dart';
import '../../catalog/catalog_models.dart';
import '../../playback/playable_item.dart';
import '../../providers/xtream/xtream_client.dart';
import 'item_grid.dart';
import 'series_playback_progress.dart';

class CatalogPlaybackTarget {
  const CatalogPlaybackTarget({required this.playable, this.history});

  final PlayableItem playable;
  final WatchHistoryUpdate? history;
}

Future<CatalogPlaybackTarget?> playbackTargetForCatalogCard(
  WidgetRef ref,
  CatalogCardItem item, {
  bool restart = false,
}) async {
  if (item.isRecent && item.recentItemType != null) {
    return _recentPlaybackTarget(ref, item, restart: restart);
  }

  if (item.contentType == CatalogContentType.series) {
    final episodes = await episodesForSeries(ref, item);
    final positions = restart
        ? null
        : await ref
              .read(watchHistoryRepositoryProvider)
              .listEpisodePositionsForSeries(
                providerId: item.providerId,
                seriesId: item.id,
              );
    final seriesAction = positions == null || positions.isEmpty
        ? null
        : resolveSeriesPlaybackAction(episodes: episodes, positions: positions);
    final firstPlayableEpisode = episodes
        .where(catalogEpisodeHasPlayableStream)
        .firstOrNull;
    final episode = restart
        ? firstPlayableEpisode
        : seriesAction?.episode ?? firstPlayableEpisode;
    if (episode == null) return null;
    return playbackTargetForCatalogEpisode(
      ref,
      episode: episode,
      episodes: episodes,
      fallbackPosterUrl: item.artworkUrl,
      resume: !restart && seriesAction?.kind == SeriesPlaybackActionKind.resume
          ? seriesAction?.resume
          : null,
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
  return CatalogPlaybackTarget(
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

Future<List<CatalogEpisode>> episodesForSeries(
  WidgetRef ref,
  CatalogCardItem item,
) async {
  final catalogRepository = ref.read(catalogRepositoryProvider);
  var episodes = await catalogRepository.listEpisodesForSeries(
    providerId: item.providerId,
    seriesId: item.id,
  );
  if (episodes.any(catalogEpisodeHasPlayableStream)) {
    return episodes;
  }

  final externalSeriesId =
      item.externalId ??
      externalSeriesIdFromCatalogId(item.providerId, item.id);
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

Future<CatalogPlaybackTarget?> playbackTargetForCatalogEpisode(
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

  return CatalogPlaybackTarget(playable: playable);
}

Future<CatalogPlaybackTarget?> _recentPlaybackTarget(
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
    return playbackTargetForCatalogEpisode(
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
  final url = await _streamUrl(
    ref,
    providerId: catalogItem.providerId,
    contentType: catalogItem.contentType,
    streamUrl: catalogItem.streamUrl,
    streamJson: catalogItem.streamJson,
  );
  if (url == null) return null;
  final subtitle = _subtitleFor(catalogItem);
  return CatalogPlaybackTarget(
    playable: PlayableItem(
      id: catalogItem.id,
      providerId: catalogItem.providerId,
      title: catalogItem.title,
      subtitle: subtitle,
      streamUrl: url,
      kind: catalogItem.contentType == CatalogContentType.live
          ? PlayableKind.live
          : PlayableKind.movie,
      posterUrl: catalogItem.contentType == CatalogContentType.movie
          ? catalogItem.artworkUrl
          : null,
      channelLogoUrl: catalogItem.contentType == CatalogContentType.live
          ? catalogItem.artworkUrl
          : null,
      durationSeconds: catalogItem.durationSeconds,
      resumePosition: resume == null
          ? Duration.zero
          : Duration(seconds: resume.positionSeconds),
    ),
    history: catalogItem.contentType == CatalogContentType.live
        ? WatchHistoryUpdate(
            itemId: catalogItem.id,
            itemType: PlayableContentType.live,
            providerId: catalogItem.providerId,
            title: catalogItem.title,
            subtitle: subtitle,
            artworkUrl: catalogItem.artworkUrl,
            durationSeconds: catalogItem.durationSeconds,
          )
        : null,
  );
}

Future<List<PlayableItem>> _episodePlayableItems(
  WidgetRef ref, {
  required List<CatalogEpisode> episodes,
  String? fallbackPosterUrl,
}) async {
  final items = <PlayableItem>[];
  for (final episode in episodes.where(catalogEpisodeHasPlayableStream)) {
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

bool catalogEpisodeHasPlayableStream(CatalogEpisode episode) {
  return _hasPlayableStream(
    streamUrl: episode.streamUrl,
    streamJson: episode.streamJson,
  );
}

bool _hasPlayableStream({String? streamUrl, String? streamJson}) {
  return streamUrl?.trim().isNotEmpty == true ||
      streamJson?.trim().isNotEmpty == true;
}

String? externalSeriesIdFromCatalogId(String providerId, String itemId) {
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
