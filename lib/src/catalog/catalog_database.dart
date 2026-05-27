import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'catalog_database.g.dart';

int _nowMs() => DateTime.now().millisecondsSinceEpoch;

class SensitiveText {
  const SensitiveText(this.value);

  final String value;

  @override
  String toString() => '<redacted>';
}

class SensitiveTextConverter extends TypeConverter<SensitiveText, String> {
  const SensitiveTextConverter();

  @override
  SensitiveText fromSql(String fromDb) {
    return SensitiveText(fromDb);
  }

  @override
  String toSql(SensitiveText value) {
    return value.value;
  }
}

@DataClassName('CatalogProviderRow')
class CatalogProviders extends Table {
  @override
  String get tableName => 'providers';

  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get source => text()();
  TextColumn get sourceKind => text().nullable()();
  TextColumn get username =>
      text().map(const SensitiveTextConverter()).nullable()();
  TextColumn get password =>
      text().map(const SensitiveTextConverter()).nullable()();
  IntColumn get createdAt => integer().clientDefault(_nowMs)();
  IntColumn get updatedAt => integer().clientDefault(_nowMs)();
  IntColumn get lastRefreshAt => integer().nullable()();
  BoolColumn get autoRefreshEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get autoRefreshIntervalMinutes =>
      integer().withDefault(const Constant(1440))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (type IN ('m3u', 'xtream'))",
    "CHECK (source_kind IS NULL OR source_kind IN ('url', 'file'))",
    'CHECK (auto_refresh_interval_minutes BETWEEN 1 AND 10080)',
  ];
}

@DataClassName('ProviderRefreshRunRow')
class ProviderRefreshRuns extends Table {
  @override
  String get tableName => 'provider_refresh_runs';

  TextColumn get id => text()();
  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get status => text()();
  IntColumn get startedAt => integer().clientDefault(_nowMs)();
  IntColumn get finishedAt => integer().nullable()();
  IntColumn get itemCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('running', 'succeeded', 'failed'))",
    'CHECK (item_count >= 0)',
  ];
}

@DataClassName('CategoryRow')
class Categories extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get contentType => text()();
  TextColumn get externalId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  IntColumn get itemCount => integer().withDefault(const Constant(0))();
  IntColumn get lastSeenAt => integer().clientDefault(_nowMs)();
  BoolColumn get isStale => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {providerId, contentType, id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {providerId, contentType, normalizedName},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (content_type IN ('live', 'movie', 'series'))",
    'CHECK (item_count >= 0)',
  ];
}

@DataClassName('CatalogItemRow')
class CatalogItems extends Table {
  @override
  String get tableName => 'catalog_items';

  TextColumn get id => text()();
  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get contentType => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get normalizedTitle => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  TextColumn get streamUrl => text().nullable()();
  TextColumn get streamJson => text().nullable()();
  TextColumn get externalId => text().nullable()();
  IntColumn get year => integer().nullable()();
  TextColumn get rating => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get epgChannelId => text().nullable()();
  TextColumn get containerExtension => text().nullable()();
  IntColumn get createdAt => integer().clientDefault(_nowMs)();
  IntColumn get updatedAt => integer().clientDefault(_nowMs)();
  IntColumn get lastSeenAt => integer().clientDefault(_nowMs)();
  BoolColumn get isStale => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {providerId, contentType, id};

  @override
  List<String> get customConstraints => [
    "CHECK (content_type IN ('live', 'movie', 'series'))",
    'CHECK (duration_seconds IS NULL OR duration_seconds >= 0)',
  ];
}

@DataClassName('SeriesRow')
class Series extends Table {
  @override
  String get tableName => 'series';

  TextColumn get id => text()();
  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get catalogItemId => text().nullable()();
  TextColumn get externalId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get normalizedTitle => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterUrl => text().nullable()();
  TextColumn get backdropUrl => text().nullable()();
  IntColumn get updatedAt => integer().clientDefault(_nowMs)();
  IntColumn get lastSeenAt => integer().clientDefault(_nowMs)();
  BoolColumn get isStale => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {providerId, id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {providerId, catalogItemId},
  ];
}

@DataClassName('SeasonRow')
class Seasons extends Table {
  @override
  String get tableName => 'seasons';

  TextColumn get id => text()();
  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get seriesId => text()();
  IntColumn get seasonNumber => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterUrl => text().nullable()();
  IntColumn get updatedAt => integer().clientDefault(_nowMs)();
  IntColumn get lastSeenAt => integer().clientDefault(_nowMs)();
  BoolColumn get isStale => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {providerId, seriesId, id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {providerId, seriesId, seasonNumber},
  ];
}

@DataClassName('EpisodeRow')
class Episodes extends Table {
  @override
  String get tableName => 'episodes';

  TextColumn get id => text()();
  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get seriesId => text()();
  TextColumn get seasonId => text()();
  IntColumn get seasonNumber => integer()();
  IntColumn get episodeNumber => integer()();
  TextColumn get title => text()();
  TextColumn get normalizedTitle => text()();
  TextColumn get description => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  TextColumn get streamUrl => text().nullable()();
  TextColumn get streamJson => text().nullable()();
  TextColumn get externalId => text().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get createdAt => integer().clientDefault(_nowMs)();
  IntColumn get updatedAt => integer().clientDefault(_nowMs)();
  IntColumn get lastSeenAt => integer().clientDefault(_nowMs)();
  BoolColumn get isStale => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {providerId, seriesId, seasonId, id};

  @override
  List<String> get customConstraints => [
    'CHECK (season_number >= 0)',
    'CHECK (episode_number >= 0)',
    'CHECK (duration_seconds IS NULL OR duration_seconds >= 0)',
  ];
}

@DataClassName('FavoriteItemRow')
class FavoriteItems extends Table {
  @override
  String get tableName => 'favorite_items';

  TextColumn get catalogKey => text()();
  TextColumn get itemId => text()();
  TextColumn get itemType => text()();
  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get seriesId => text().nullable()();
  TextColumn get seasonId => text().nullable()();
  IntColumn get createdAt => integer().clientDefault(_nowMs)();

  @override
  Set<Column<Object>> get primaryKey => {providerId, itemType, catalogKey};

  @override
  List<String> get customConstraints => [
    "CHECK (item_type IN ('live', 'movie', 'series', 'episode'))",
  ];
}

@DataClassName('FavoriteCategoryRow')
class FavoriteCategories extends Table {
  @override
  String get tableName => 'favorite_categories';

  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get contentType => text()();
  TextColumn get categoryId => text()();
  IntColumn get createdAt => integer().clientDefault(_nowMs)();

  @override
  Set<Column<Object>> get primaryKey => {providerId, contentType, categoryId};

  @override
  List<String> get customConstraints => [
    "CHECK (content_type IN ('live', 'movie', 'series'))",
  ];
}

@DataClassName('CategoryOrderRow')
class CategoryOrder extends Table {
  @override
  String get tableName => 'category_order';

  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get contentType => text()();
  TextColumn get categoryId => text()();
  IntColumn get sortOrder => integer()();
  IntColumn get updatedAt => integer().clientDefault(_nowMs)();

  @override
  Set<Column<Object>> get primaryKey => {providerId, contentType, categoryId};

  @override
  List<String> get customConstraints => [
    "CHECK (content_type IN ('live', 'movie', 'series'))",
    'CHECK (sort_order >= 0)',
  ];
}

@DataClassName('WatchHistoryRow')
class WatchHistory extends Table {
  @override
  String get tableName => 'watch_history';

  TextColumn get catalogKey => text()();
  TextColumn get itemId => text()();
  TextColumn get itemType => text()();
  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  TextColumn get seriesId => text().nullable()();
  TextColumn get seasonId => text().nullable()();
  IntColumn get positionSeconds => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get lastWatchedAt => integer().clientDefault(_nowMs)();
  IntColumn get watchCount => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {providerId, itemType, catalogKey};

  @override
  List<String> get customConstraints => [
    "CHECK (item_type IN ('live', 'movie', 'episode'))",
    'CHECK (position_seconds >= 0)',
    'CHECK (duration_seconds IS NULL OR duration_seconds >= 0)',
    'CHECK (watch_count >= 1)',
  ];
}

@DataClassName('PlaybackPositionRow')
class PlaybackPositions extends Table {
  @override
  String get tableName => 'playback_positions';

  TextColumn get providerId =>
      text().references(CatalogProviders, #id, onDelete: KeyAction.cascade)();
  TextColumn get catalogKey => text()();
  TextColumn get itemId => text()();
  TextColumn get itemType => text()();
  TextColumn get seriesId => text().nullable()();
  TextColumn get seasonId => text().nullable()();
  IntColumn get positionSeconds => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer().clientDefault(_nowMs)();

  @override
  Set<Column<Object>> get primaryKey => {providerId, itemType, catalogKey};

  @override
  List<String> get customConstraints => [
    "CHECK (item_type IN ('live', 'movie', 'episode'))",
    'CHECK (position_seconds >= 0)',
    'CHECK (duration_seconds IS NULL OR duration_seconds >= 0)',
  ];
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer().clientDefault(_nowMs)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    CatalogProviders,
    ProviderRefreshRuns,
    Categories,
    CatalogItems,
    Series,
    Seasons,
    Episodes,
    FavoriteItems,
    FavoriteCategories,
    CategoryOrder,
    WatchHistory,
    PlaybackPositions,
    AppSettings,
  ],
)
class CatalogDatabase extends _$CatalogDatabase {
  CatalogDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'vela_catalog'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(
          catalogProviders,
          catalogProviders.autoRefreshIntervalMinutes,
        );
        await customStatement(
          'UPDATE providers '
          'SET auto_refresh_interval_minutes = auto_refresh_interval_hours * 60 '
          'WHERE auto_refresh_interval_hours IS NOT NULL',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _createIndexes();
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_catalog_items_provider_content '
      'ON catalog_items(provider_id, content_type, is_stale)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_catalog_items_provider_category '
      'ON catalog_items(provider_id, content_type, category_id, is_stale)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_catalog_items_normalized_title '
      'ON catalog_items(normalized_title)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_provider_content '
      'ON categories(provider_id, content_type, is_stale)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_categories_normalized_name '
      'ON categories(normalized_name)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_favorite_items_lookup '
      'ON favorite_items(provider_id, item_type, catalog_key)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_favorite_categories_lookup '
      'ON favorite_categories(provider_id, content_type, category_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_watch_history_last_watched '
      'ON watch_history(last_watched_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_watch_history_provider_last_watched '
      'ON watch_history(provider_id, last_watched_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_playback_positions_lookup '
      'ON playback_positions(provider_id, item_type, catalog_key)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_series_provider_title '
      'ON series(provider_id, normalized_title, is_stale)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_series_provider_catalog_item '
      'ON series(provider_id, catalog_item_id, is_stale)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_seasons_series_number '
      'ON seasons(provider_id, series_id, season_number, is_stale)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_episodes_series_season_episode '
      'ON episodes(provider_id, series_id, season_number, episode_number, '
      'is_stale)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_episodes_normalized_title '
      'ON episodes(normalized_title)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_provider_refresh_runs_provider_started '
      'ON provider_refresh_runs(provider_id, started_at DESC)',
    );
  }
}
