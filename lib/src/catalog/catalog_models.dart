enum CatalogProviderType {
  m3u,
  xtream;

  static CatalogProviderType fromDb(String value) {
    return CatalogProviderType.values.byName(value);
  }
}

enum CatalogContentType {
  live,
  movie,
  series;

  static CatalogContentType fromDb(String value) {
    return CatalogContentType.values.byName(value);
  }
}

enum PlayableContentType {
  live,
  movie,
  episode;

  static PlayableContentType fromDb(String value) {
    return PlayableContentType.values.byName(value);
  }
}

enum FavoriteItemType {
  live,
  movie,
  series,
  episode;

  static FavoriteItemType fromDb(String value) {
    return FavoriteItemType.values.byName(value);
  }

  static FavoriteItemType fromCatalog(CatalogContentType value) {
    return switch (value) {
      CatalogContentType.live => FavoriteItemType.live,
      CatalogContentType.movie => FavoriteItemType.movie,
      CatalogContentType.series => FavoriteItemType.series,
    };
  }
}

enum ProviderRefreshStatus {
  running,
  succeeded,
  failed;

  static ProviderRefreshStatus fromDb(String value) {
    return ProviderRefreshStatus.values.byName(value);
  }
}

String normalizeCatalogText(String value) {
  return value.trim().toLowerCase();
}

String favoriteCatalogKey({
  required String itemId,
  required FavoriteItemType itemType,
  String? seriesId,
  String? seasonId,
}) {
  return _scopedCatalogKey(
    itemId: itemId,
    isEpisode: itemType == FavoriteItemType.episode,
    seriesId: seriesId,
    seasonId: seasonId,
  );
}

String playbackCatalogKey({
  required String itemId,
  required PlayableContentType itemType,
  String? seriesId,
  String? seasonId,
}) {
  return _scopedCatalogKey(
    itemId: itemId,
    isEpisode: itemType == PlayableContentType.episode,
    seriesId: seriesId,
    seasonId: seasonId,
  );
}

String _scopedCatalogKey({
  required String itemId,
  required bool isEpisode,
  String? seriesId,
  String? seasonId,
}) {
  if (!isEpisode) {
    return itemId;
  }

  final normalizedSeriesId = seriesId?.trim();
  final normalizedSeasonId = seasonId?.trim();
  if (normalizedSeriesId == null ||
      normalizedSeriesId.isEmpty ||
      normalizedSeasonId == null ||
      normalizedSeasonId.isEmpty) {
    throw ArgumentError('Episode user data requires series and season scope');
  }

  return [
    Uri.encodeComponent(normalizedSeriesId),
    Uri.encodeComponent(normalizedSeasonId),
    Uri.encodeComponent(itemId),
  ].join(':');
}

class CatalogProvider {
  const CatalogProvider({
    required this.id,
    required this.type,
    required this.name,
    required this.source,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.sourceKind,
    this.username,
    this.password,
    this.lastRefreshAtMs,
    this.autoRefreshEnabled = true,
    this.autoRefreshIntervalMinutes = 24 * 60,
    this.isEnabled = true,
  });

  final String id;
  final CatalogProviderType type;
  final String name;
  final String source;
  final String? sourceKind;
  final String? username;
  final String? password;
  final int createdAtMs;
  final int updatedAtMs;
  final int? lastRefreshAtMs;
  final bool autoRefreshEnabled;
  final int autoRefreshIntervalMinutes;
  final bool isEnabled;
}

class CatalogProviderInput {
  const CatalogProviderInput({
    required this.id,
    required this.type,
    required this.name,
    required this.source,
    this.sourceKind,
    this.username,
    this.password,
    this.autoRefreshEnabled = true,
    this.autoRefreshIntervalMinutes = 24 * 60,
    this.isEnabled = true,
  });

  final String id;
  final CatalogProviderType type;
  final String name;
  final String source;
  final String? sourceKind;
  final String? username;
  final String? password;
  final bool autoRefreshEnabled;
  final int autoRefreshIntervalMinutes;
  final bool isEnabled;
}

class ProviderRefreshRun {
  const ProviderRefreshRun({
    required this.id,
    required this.providerId,
    required this.status,
    required this.startedAtMs,
    this.finishedAtMs,
    this.itemCount = 0,
    this.errorMessage,
  });

  final String id;
  final String providerId;
  final ProviderRefreshStatus status;
  final int startedAtMs;
  final int? finishedAtMs;
  final int itemCount;
  final String? errorMessage;
}

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.providerId,
    required this.contentType,
    required this.name,
    required this.normalizedName,
    required this.itemCount,
    required this.lastSeenAtMs,
    this.externalId,
    this.isFavorite = false,
    this.sortOrder,
  });

  final String id;
  final String providerId;
  final CatalogContentType contentType;
  final String name;
  final String normalizedName;
  final int itemCount;
  final int lastSeenAtMs;
  final String? externalId;
  final bool isFavorite;
  final int? sortOrder;
}

class CatalogCategoryInput {
  const CatalogCategoryInput({
    required this.providerId,
    required this.contentType,
    required this.name,
    this.id,
    this.externalId,
    this.itemCount,
  });

  final String? id;
  final String providerId;
  final CatalogContentType contentType;
  final String name;
  final String? externalId;
  final int? itemCount;
}

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.providerId,
    required this.contentType,
    required this.title,
    required this.normalizedTitle,
    required this.updatedAtMs,
    required this.lastSeenAtMs,
    this.categoryId,
    this.subtitle,
    this.description,
    this.artworkUrl,
    this.streamUrl,
    this.streamJson,
    this.externalId,
    this.year,
    this.rating,
    this.durationSeconds,
    this.epgChannelId,
    this.containerExtension,
    this.isFavorite = false,
  });

  final String id;
  final String providerId;
  final CatalogContentType contentType;
  final String? categoryId;
  final String title;
  final String normalizedTitle;
  final String? subtitle;
  final String? description;
  final String? artworkUrl;
  final String? streamUrl;
  final String? streamJson;
  final String? externalId;
  final int? year;
  final String? rating;
  final int? durationSeconds;
  final String? epgChannelId;
  final String? containerExtension;
  final int updatedAtMs;
  final int lastSeenAtMs;
  final bool isFavorite;
}

class CatalogItemInput {
  const CatalogItemInput({
    required this.id,
    required this.providerId,
    required this.contentType,
    required this.title,
    this.categoryId,
    this.categoryName,
    this.subtitle,
    this.description,
    this.artworkUrl,
    this.streamUrl,
    this.streamJson,
    this.externalId,
    this.year,
    this.rating,
    this.durationSeconds,
    this.epgChannelId,
    this.containerExtension,
  });

  final String id;
  final String providerId;
  final CatalogContentType contentType;
  final String title;
  final String? categoryId;
  final String? categoryName;
  final String? subtitle;
  final String? description;
  final String? artworkUrl;
  final String? streamUrl;
  final String? streamJson;
  final String? externalId;
  final int? year;
  final String? rating;
  final int? durationSeconds;
  final String? epgChannelId;
  final String? containerExtension;
}

class SeriesInput {
  const SeriesInput({
    required this.id,
    required this.providerId,
    required this.title,
    this.catalogItemId,
    this.externalId,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
  });

  final String id;
  final String providerId;
  final String? catalogItemId;
  final String title;
  final String? externalId;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
}

class SeasonInput {
  const SeasonInput({
    required this.id,
    required this.providerId,
    required this.seriesId,
    required this.seasonNumber,
    this.title,
    this.overview,
    this.posterUrl,
  });

  final String id;
  final String providerId;
  final String seriesId;
  final int seasonNumber;
  final String? title;
  final String? overview;
  final String? posterUrl;
}

class EpisodeInput {
  const EpisodeInput({
    required this.id,
    required this.providerId,
    required this.seriesId,
    required this.seasonId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    this.description,
    this.artworkUrl,
    this.streamUrl,
    this.streamJson,
    this.externalId,
    this.durationSeconds,
  });

  final String id;
  final String providerId;
  final String seriesId;
  final String seasonId;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String? description;
  final String? artworkUrl;
  final String? streamUrl;
  final String? streamJson;
  final String? externalId;
  final int? durationSeconds;
}

class CatalogSeries {
  const CatalogSeries({
    required this.id,
    required this.providerId,
    required this.title,
    required this.normalizedTitle,
    required this.updatedAtMs,
    required this.lastSeenAtMs,
    this.catalogItemId,
    this.externalId,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
  });

  final String id;
  final String providerId;
  final String? catalogItemId;
  final String title;
  final String normalizedTitle;
  final String? externalId;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final int updatedAtMs;
  final int lastSeenAtMs;
}

class CatalogEpisode {
  const CatalogEpisode({
    required this.id,
    required this.providerId,
    required this.seriesId,
    required this.seasonId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.normalizedTitle,
    required this.updatedAtMs,
    required this.lastSeenAtMs,
    this.description,
    this.artworkUrl,
    this.streamUrl,
    this.streamJson,
    this.externalId,
    this.durationSeconds,
  });

  final String id;
  final String providerId;
  final String seriesId;
  final String seasonId;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String normalizedTitle;
  final String? description;
  final String? artworkUrl;
  final String? streamUrl;
  final String? streamJson;
  final String? externalId;
  final int? durationSeconds;
  final int updatedAtMs;
  final int lastSeenAtMs;
}

class ProviderCatalogSnapshot {
  const ProviderCatalogSnapshot({
    required this.providerId,
    this.categories = const [],
    this.items = const [],
    this.series = const [],
    this.seasons = const [],
    this.episodes = const [],
    this.refreshedAtMs,
  });

  final String providerId;
  final List<CatalogCategoryInput> categories;
  final List<CatalogItemInput> items;
  final List<SeriesInput> series;
  final List<SeasonInput> seasons;
  final List<EpisodeInput> episodes;
  final int? refreshedAtMs;
}

class WatchHistoryEntry {
  const WatchHistoryEntry({
    required this.itemId,
    required this.itemType,
    required this.providerId,
    required this.title,
    required this.lastWatchedAtMs,
    required this.watchCount,
    this.subtitle,
    this.artworkUrl,
    this.seriesId,
    this.seasonId,
    this.positionSeconds = 0,
    this.durationSeconds,
    this.completed = false,
  });

  final String itemId;
  final PlayableContentType itemType;
  final String providerId;
  final String title;
  final String? subtitle;
  final String? artworkUrl;
  final String? seriesId;
  final String? seasonId;
  final int positionSeconds;
  final int? durationSeconds;
  final bool completed;
  final int lastWatchedAtMs;
  final int watchCount;
}

class WatchHistoryUpdate {
  const WatchHistoryUpdate({
    required this.itemId,
    required this.itemType,
    required this.providerId,
    required this.title,
    this.subtitle,
    this.artworkUrl,
    this.seriesId,
    this.seasonId,
    this.positionSeconds = 0,
    this.durationSeconds,
    this.completed = false,
    this.watchedAtMs,
  });

  final String itemId;
  final PlayableContentType itemType;
  final String providerId;
  final String title;
  final String? subtitle;
  final String? artworkUrl;
  final String? seriesId;
  final String? seasonId;
  final int positionSeconds;
  final int? durationSeconds;
  final bool completed;
  final int? watchedAtMs;
}

class PlaybackPosition {
  const PlaybackPosition({
    required this.providerId,
    required this.itemId,
    required this.itemType,
    required this.positionSeconds,
    required this.updatedAtMs,
    this.seriesId,
    this.seasonId,
    this.durationSeconds,
    this.completed = false,
  });

  final String providerId;
  final String itemId;
  final PlayableContentType itemType;
  final String? seriesId;
  final String? seasonId;
  final int positionSeconds;
  final int? durationSeconds;
  final bool completed;
  final int updatedAtMs;
}
