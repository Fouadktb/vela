import 'dart:convert';

import '../../catalog/catalog_models.dart';
import '../provider_models.dart';
import 'xtream_client.dart';

class XtreamImporter {
  const XtreamImporter(this.client);

  final XtreamClient client;

  Future<XtreamImportResult> importProvider({
    required String providerId,
    ProviderImportProgressCallback? onProgress,
  }) async {
    _emitProgress(
      onProgress,
      ProviderImportStage.validating,
      'Validating Xtream account',
    );
    await client.getPlayerApiInfo();

    final liveCategoriesFuture = client.getLiveCategories();
    final liveStreamsFuture = client.getLiveStreams();
    final vodCategoriesFuture = client.getVodCategories();
    final vodStreamsFuture = client.getVodStreams();
    final seriesCategoriesFuture = client.getSeriesCategories();
    final seriesItemsFuture = client.getSeries();

    _emitProgress(
      onProgress,
      ProviderImportStage.live,
      'Loading live TV catalog',
    );
    final liveCategories = await liveCategoriesFuture;
    final liveStreams = await liveStreamsFuture;
    _emitProgress(
      onProgress,
      ProviderImportStage.live,
      'Loaded live TV catalog',
      current: liveStreams.length,
      total: liveStreams.length,
    );

    _emitProgress(
      onProgress,
      ProviderImportStage.movies,
      'Loading movie catalog',
    );
    final vodCategories = await vodCategoriesFuture;
    final vodStreams = await vodStreamsFuture;
    _emitProgress(
      onProgress,
      ProviderImportStage.movies,
      'Loaded movie catalog',
      current: vodStreams.length,
      total: vodStreams.length,
    );

    _emitProgress(
      onProgress,
      ProviderImportStage.series,
      'Loading series catalog',
    );
    final seriesCategories = await seriesCategoriesFuture;
    final seriesItems = await seriesItemsFuture;
    _emitProgress(
      onProgress,
      ProviderImportStage.series,
      'Loaded series catalog',
      current: seriesItems.length,
      total: seriesItems.length,
    );

    final categories = <CatalogCategoryInput>[
      ..._categoryInputs(providerId, CatalogContentType.live, liveCategories),
      ..._categoryInputs(providerId, CatalogContentType.movie, vodCategories),
      ..._categoryInputs(
        providerId,
        CatalogContentType.series,
        seriesCategories,
      ),
    ];
    final liveCategoryNames = _categoryMap(liveCategories);
    final vodCategoryNames = _categoryMap(vodCategories);
    final seriesCategoryNames = _categoryMap(seriesCategories);

    final items = <CatalogItemInput>[
      for (final stream in liveStreams)
        if (stream.streamId.isNotEmpty)
          _liveItem(providerId, stream, liveCategoryNames),
      for (final stream in vodStreams)
        if (stream.streamId.isNotEmpty)
          _movieItem(providerId, stream, vodCategoryNames),
      for (final item in seriesItems)
        if (item.seriesId.isNotEmpty)
          _seriesCatalogItem(providerId, item, seriesCategoryNames),
    ];
    final series = <SeriesInput>[];
    final seriesWithIds = seriesItems
        .where((item) => item.seriesId.isNotEmpty)
        .toList();

    for (final item in seriesWithIds) {
      final seriesItemId = _seriesItemId(providerId, item.seriesId);
      series.add(
        SeriesInput(
          id: seriesItemId,
          providerId: providerId,
          catalogItemId: seriesItemId,
          title: item.name.isEmpty ? 'Series ${item.seriesId}' : item.name,
          externalId: item.seriesId,
          posterUrl: item.cover,
        ),
      );
    }

    return XtreamImportResult(
      snapshot: ProviderCatalogSnapshot(
        providerId: providerId,
        categories: categories,
        items: items,
        series: series,
        refreshedEpisodeSeriesIds: const {},
      ),
    );
  }
}

void _emitProgress(
  ProviderImportProgressCallback? onProgress,
  ProviderImportStage stage,
  String message, {
  int? current,
  int? total,
}) {
  onProgress?.call(
    ProviderImportProgress(
      stage: stage,
      message: message,
      current: current,
      total: total,
    ),
  );
}

class XtreamImportResult {
  const XtreamImportResult({required this.snapshot, this.warningMessage});

  final ProviderCatalogSnapshot snapshot;
  final String? warningMessage;
}

List<CatalogCategoryInput> _categoryInputs(
  String providerId,
  CatalogContentType contentType,
  List<XtreamCategory> categories,
) {
  return [
    for (final category in categories)
      if (category.isValid)
        CatalogCategoryInput(
          providerId: providerId,
          contentType: contentType,
          name: category.name,
          externalId: category.id,
        ),
  ];
}

Map<String, String> _categoryMap(List<XtreamCategory> categories) {
  return {
    for (final category in categories)
      if (category.isValid) category.id: category.name,
  };
}

CatalogItemInput _liveItem(
  String providerId,
  XtreamLiveStream stream,
  Map<String, String> categories,
) {
  final extension = stream.containerExtension ?? 'ts';
  return CatalogItemInput(
    id: _liveItemId(providerId, stream.streamId),
    providerId: providerId,
    contentType: CatalogContentType.live,
    title: stream.name.isEmpty ? 'Channel ${stream.streamId}' : stream.name,
    categoryId: stream.categoryId,
    categoryName:
        (stream.categoryId == null ? null : categories[stream.categoryId]) ??
        stream.categoryName ??
        'Uncategorized',
    artworkUrl: stream.streamIcon,
    streamJson: _streamJson(
      providerType: 'xtream',
      streamId: stream.streamId,
      containerExtension: extension,
    ),
    externalId: stream.streamId,
    epgChannelId: stream.epgChannelId,
    containerExtension: extension,
  );
}

CatalogItemInput _movieItem(
  String providerId,
  XtreamVodStream stream,
  Map<String, String> categories,
) {
  final extension = stream.containerExtension ?? 'mp4';
  return CatalogItemInput(
    id: _movieItemId(providerId, stream.streamId),
    providerId: providerId,
    contentType: CatalogContentType.movie,
    title: stream.name.isEmpty ? 'Movie ${stream.streamId}' : stream.name,
    categoryId: stream.categoryId,
    categoryName:
        (stream.categoryId == null ? null : categories[stream.categoryId]) ??
        'Uncategorized',
    artworkUrl: stream.streamIcon,
    streamJson: _streamJson(
      providerType: 'xtream',
      streamId: stream.streamId,
      containerExtension: extension,
    ),
    externalId: stream.streamId,
    year: stream.year ?? stream.releaseDate,
    rating: stream.rating,
    containerExtension: extension,
  );
}

CatalogItemInput _seriesCatalogItem(
  String providerId,
  XtreamSeriesItem item,
  Map<String, String> categories,
) {
  return CatalogItemInput(
    id: _seriesItemId(providerId, item.seriesId),
    providerId: providerId,
    contentType: CatalogContentType.series,
    title: item.name.isEmpty ? 'Series ${item.seriesId}' : item.name,
    categoryId: item.categoryId,
    categoryName:
        (item.categoryId == null ? null : categories[item.categoryId]) ??
        'Uncategorized',
    artworkUrl: item.cover,
    externalId: item.seriesId,
  );
}

String _streamJson({
  required String providerType,
  required String streamId,
  required String containerExtension,
}) {
  return jsonEncode({
    'providerType': providerType,
    'streamId': streamId,
    'containerExtension': containerExtension,
  });
}

String _liveItemId(String providerId, String streamId) {
  return '$providerId:live:$streamId';
}

String _movieItemId(String providerId, String streamId) {
  return '$providerId:movie:$streamId';
}

String _seriesItemId(String providerId, String seriesId) {
  return '$providerId:series:$seriesId';
}

String _episodeItemId(String providerId, String episodeId) {
  return '$providerId:episode:$episodeId';
}

XtreamSeriesEpisodeDetails xtreamSeriesEpisodeDetails({
  required String providerId,
  required String seriesItemId,
  required XtreamSeriesInfo info,
}) {
  final seasons = <SeasonInput>[];
  final episodes = <EpisodeInput>[];
  final seasonByNumber = {
    for (final season in info.seasons) season.seasonNumber: season,
  };
  final episodeSeasonNumbers = info.episodes
      .map((episode) => episode.seasonNumber)
      .toSet();
  final allSeasonNumbers = <int>{
    ...seasonByNumber.keys,
    ...episodeSeasonNumbers,
  }.toList()..sort();

  for (final seasonNumber in allSeasonNumbers) {
    final season = seasonByNumber[seasonNumber];
    seasons.add(
      SeasonInput(
        id: seasonNumber.toString(),
        providerId: providerId,
        seriesId: seriesItemId,
        seasonNumber: seasonNumber,
        title: season?.name ?? 'Season $seasonNumber',
        overview: season?.overview,
        posterUrl: season?.cover,
      ),
    );
  }

  for (final episode in info.episodes) {
    if (episode.id.isEmpty) {
      continue;
    }
    final extension = episode.containerExtension ?? 'mp4';
    episodes.add(
      EpisodeInput(
        id: _episodeItemId(providerId, episode.id),
        providerId: providerId,
        seriesId: seriesItemId,
        seasonId: episode.seasonNumber.toString(),
        seasonNumber: episode.seasonNumber,
        episodeNumber: episode.episodeNumber,
        title: episode.title.isEmpty
            ? 'Episode ${episode.episodeNumber == 0 ? episode.id : episode.episodeNumber}'
            : episode.title,
        description: episode.description,
        artworkUrl: episode.artworkUrl,
        streamJson: _streamJson(
          providerType: 'xtream',
          streamId: episode.id,
          containerExtension: extension,
        ),
        externalId: episode.id,
        durationSeconds: episode.durationSeconds,
      ),
    );
  }

  return XtreamSeriesEpisodeDetails(seasons: seasons, episodes: episodes);
}

class XtreamSeriesEpisodeDetails {
  const XtreamSeriesEpisodeDetails({
    required this.seasons,
    required this.episodes,
  });

  final List<SeasonInput> seasons;
  final List<EpisodeInput> episodes;
}
