import 'package:drift/drift.dart';

import 'catalog_database.dart';
import 'catalog_models.dart';

class CatalogRepository {
  CatalogRepository(this._db);

  final CatalogDatabase _db;

  Stream<List<CatalogProvider>> watchProviders() {
    final query = _db.select(_db.catalogProviders)
      ..orderBy([(provider) => OrderingTerm.asc(provider.name)]);

    return query.watch().map((rows) => rows.map(_toProvider).toList());
  }

  Future<List<CatalogProvider>> listProviders() async {
    final query = _db.select(_db.catalogProviders)
      ..orderBy([(provider) => OrderingTerm.asc(provider.name)]);
    final rows = await query.get();
    return rows.map(_toProvider).toList();
  }

  Future<CatalogProvider?> getProvider(String id) async {
    final row = await (_db.select(
      _db.catalogProviders,
    )..where((provider) => provider.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toProvider(row);
  }

  Future<CatalogProvider> createOrUpdateProvider(
    CatalogProviderInput input,
  ) async {
    final now = _nowMs();
    final existing = await getProvider(input.id);
    final row = CatalogProvidersCompanion.insert(
      id: input.id,
      type: input.type.name,
      name: input.name.trim(),
      source: input.source.trim(),
      sourceKind: Value(input.sourceKind),
      username: Value(_sensitive(input.username)),
      password: Value(_sensitive(input.password)),
      createdAt: Value(existing?.createdAtMs ?? now),
      updatedAt: Value(now),
      lastRefreshAt: Value(existing?.lastRefreshAtMs),
      autoRefreshEnabled: Value(input.autoRefreshEnabled),
      autoRefreshIntervalMinutes: Value(input.autoRefreshIntervalMinutes),
      isEnabled: Value(input.isEnabled),
    );

    await _db.into(_db.catalogProviders).insertOnConflictUpdate(row);
    return (await getProvider(input.id))!;
  }

  Future<void> upsertProvider(CatalogProvider provider) async {
    await _db
        .into(_db.catalogProviders)
        .insertOnConflictUpdate(
          CatalogProvidersCompanion.insert(
            id: provider.id,
            type: provider.type.name,
            name: provider.name,
            source: provider.source,
            sourceKind: Value(provider.sourceKind),
            username: Value(_sensitive(provider.username)),
            password: Value(_sensitive(provider.password)),
            createdAt: Value(provider.createdAtMs),
            updatedAt: Value(provider.updatedAtMs),
            lastRefreshAt: Value(provider.lastRefreshAtMs),
            autoRefreshEnabled: Value(provider.autoRefreshEnabled),
            autoRefreshIntervalMinutes: Value(
              provider.autoRefreshIntervalMinutes,
            ),
            isEnabled: Value(provider.isEnabled),
          ),
        );
  }

  Future<void> deleteProvider(String id) async {
    await (_db.delete(
      _db.catalogProviders,
    )..where((provider) => provider.id.equals(id))).go();
  }

  Future<void> clearProviderCatalog(String providerId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.favoriteItems,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.favoriteCategories,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.categoryOrder,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.watchHistory,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.playbackPositions,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.episodes,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.seasons,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.series,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.catalogItems,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.categories,
      )..where((row) => row.providerId.equals(providerId))).go();
    });
  }

  Future<ProviderRefreshRun> createRefreshRun({
    required String id,
    required String providerId,
    int? startedAtMs,
  }) async {
    final row = ProviderRefreshRunsCompanion.insert(
      id: id,
      providerId: providerId,
      status: ProviderRefreshStatus.running.name,
      startedAt: Value(startedAtMs ?? _nowMs()),
    );
    await _db.into(_db.providerRefreshRuns).insert(row);
    return (await (_db.select(
      _db.providerRefreshRuns,
    )..where((run) => run.id.equals(id))).getSingle().then(_toRefreshRun));
  }

  Future<void> finishRefreshRun({
    required String id,
    required ProviderRefreshStatus status,
    int itemCount = 0,
    String? errorMessage,
    int? finishedAtMs,
  }) async {
    await (_db.update(
      _db.providerRefreshRuns,
    )..where((run) => run.id.equals(id))).write(
      ProviderRefreshRunsCompanion(
        status: Value(status.name),
        finishedAt: Value(finishedAtMs ?? _nowMs()),
        itemCount: Value(itemCount),
        errorMessage: Value(errorMessage),
      ),
    );
  }

  Future<void> replaceProviderCatalog(ProviderCatalogSnapshot snapshot) async {
    final now = snapshot.refreshedAtMs ?? _nowMs();
    _validateSnapshot(snapshot);

    await _db.transaction(() async {
      await (_db.update(_db.categories)
            ..where((row) => row.providerId.equals(snapshot.providerId)))
          .write(const CategoriesCompanion(isStale: Value(true)));
      await (_db.update(_db.catalogItems)
            ..where((row) => row.providerId.equals(snapshot.providerId)))
          .write(const CatalogItemsCompanion(isStale: Value(true)));
      await (_db.update(_db.series)
            ..where((row) => row.providerId.equals(snapshot.providerId)))
          .write(const SeriesCompanion(isStale: Value(true)));
      await (_db.update(_db.seasons)
            ..where((row) => row.providerId.equals(snapshot.providerId)))
          .write(const SeasonsCompanion(isStale: Value(true)));
      await (_db.update(_db.episodes)
            ..where((row) => row.providerId.equals(snapshot.providerId)))
          .write(const EpisodesCompanion(isStale: Value(true)));

      final categories = _collectCategories(snapshot);
      for (final category in categories.values) {
        await _upsertCategory(category, now);
      }

      for (final item in snapshot.items) {
        await _upsertCatalogItem(item, now);
      }
      for (final item in snapshot.series) {
        await _upsertSeries(item, now);
      }
      for (final item in snapshot.seasons) {
        await _upsertSeason(item, now);
      }
      for (final item in snapshot.episodes) {
        await _upsertEpisode(item, now);
      }

      await (_db.update(
        _db.catalogProviders,
      )..where((row) => row.id.equals(snapshot.providerId))).write(
        CatalogProvidersCompanion(
          lastRefreshAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Stream<List<CatalogItem>> watchItems({
    String? providerId,
    required CatalogContentType section,
    String? categoryId,
    bool favoritesOnly = false,
  }) {
    return _selectItems(
      providerId: providerId,
      section: section,
      categoryId: categoryId,
      favoritesOnly: favoritesOnly,
      watch: true,
    ).watch().map(_mapItemRows);
  }

  Future<List<CatalogItem>> searchItems({
    String? providerId,
    required CatalogContentType section,
    String? categoryId,
    required String query,
    bool favoritesOnly = false,
  }) async {
    final rows = await _selectItems(
      providerId: providerId,
      section: section,
      categoryId: categoryId,
      searchQuery: query,
      favoritesOnly: favoritesOnly,
      watch: false,
    ).get();
    return _mapItemRows(rows);
  }

  Future<CatalogItem?> getItem({
    required String providerId,
    required CatalogContentType contentType,
    required String id,
  }) async {
    final row =
        await (_db.select(_db.catalogItems)..where(
              (item) =>
                  item.providerId.equals(providerId) &
                  item.contentType.equals(contentType.name) &
                  item.id.equals(id) &
                  item.isStale.equals(false),
            ))
            .getSingleOrNull();
    return row == null ? null : _toCatalogItem(row);
  }

  Future<bool> toggleItemFavorite({
    required String providerId,
    required String itemId,
    required FavoriteItemType itemType,
    String? seriesId,
    String? seasonId,
  }) async {
    final catalogKey = favoriteCatalogKey(
      itemId: itemId,
      itemType: itemType,
      seriesId: seriesId,
      seasonId: seasonId,
    );

    return _db.transaction(() async {
      final existing =
          await (_db.select(_db.favoriteItems)..where(
                (favorite) =>
                    favorite.providerId.equals(providerId) &
                    favorite.itemType.equals(itemType.name) &
                    favorite.catalogKey.equals(catalogKey),
              ))
              .getSingleOrNull();

      if (existing != null) {
        await (_db.delete(_db.favoriteItems)..where(
              (favorite) =>
                  favorite.providerId.equals(providerId) &
                  favorite.itemType.equals(itemType.name) &
                  favorite.catalogKey.equals(catalogKey),
            ))
            .go();
        return false;
      }

      await _db
          .into(_db.favoriteItems)
          .insert(
            FavoriteItemsCompanion.insert(
              catalogKey: catalogKey,
              itemId: itemId,
              itemType: itemType.name,
              providerId: providerId,
              seriesId: Value(seriesId),
              seasonId: Value(seasonId),
              createdAt: Value(_nowMs()),
            ),
          );
      return true;
    });
  }

  Stream<CatalogSeries?> watchSeriesForCatalogItem({
    required String providerId,
    required String catalogItemId,
  }) {
    final query = _db.select(_db.series)
      ..where(
        (series) =>
            series.providerId.equals(providerId) &
            series.catalogItemId.equals(catalogItemId) &
            series.isStale.equals(false),
      )
      ..limit(1);

    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toSeries(row),
    );
  }

  Stream<List<CatalogEpisode>> watchEpisodesForCatalogItem({
    required String providerId,
    required String catalogItemId,
  }) {
    return _selectEpisodesForCatalogItem(
      providerId: providerId,
      catalogItemId: catalogItemId,
    ).watch().map((rows) => rows.map(_episodeFromQueryRow).toList());
  }

  Stream<List<CatalogEpisode>> watchEpisodesForSeries({
    required String providerId,
    required String seriesId,
  }) {
    final query = _db.select(_db.episodes)
      ..where(
        (episode) =>
            episode.providerId.equals(providerId) &
            episode.seriesId.equals(seriesId) &
            episode.isStale.equals(false),
      )
      ..orderBy([
        (episode) => OrderingTerm.asc(episode.seasonNumber),
        (episode) => OrderingTerm.asc(episode.episodeNumber),
        (episode) => OrderingTerm.asc(episode.normalizedTitle),
      ]);

    return query.watch().map((rows) => rows.map(_toEpisode).toList());
  }

  Future<List<CatalogEpisode>> listEpisodesForSeries({
    required String providerId,
    required String seriesId,
  }) async {
    final query = _db.select(_db.episodes)
      ..where(
        (episode) =>
            episode.providerId.equals(providerId) &
            episode.seriesId.equals(seriesId) &
            episode.isStale.equals(false),
      )
      ..orderBy([
        (episode) => OrderingTerm.asc(episode.seasonNumber),
        (episode) => OrderingTerm.asc(episode.episodeNumber),
        (episode) => OrderingTerm.asc(episode.normalizedTitle),
      ]);

    final rows = await query.get();
    return rows.map(_toEpisode).toList();
  }

  Selectable<QueryRow> _selectEpisodesForCatalogItem({
    required String providerId,
    required String catalogItemId,
  }) {
    return _db.customSelect(
      '''
      SELECT e.*
      FROM episodes AS e
      JOIN series AS s
        ON s.provider_id = e.provider_id
        AND s.id = e.series_id
      WHERE s.provider_id = ?
        AND s.catalog_item_id = ?
        AND s.is_stale = 0
        AND e.is_stale = 0
      ORDER BY e.season_number ASC, e.episode_number ASC, e.normalized_title ASC
      ''',
      variables: [
        Variable<String>(providerId),
        Variable<String>(catalogItemId),
      ],
      readsFrom: {_db.episodes, _db.series},
    );
  }

  Selectable<QueryRow> _selectItems({
    required CatalogContentType section,
    required bool watch,
    String? providerId,
    String? categoryId,
    String? searchQuery,
    bool favoritesOnly = false,
  }) {
    final where = <String>['i.content_type = ?', 'i.is_stale = 0'];
    final variables = <Variable>[Variable<String>(section.name)];

    if (providerId != null) {
      where.add('i.provider_id = ?');
      variables.add(Variable<String>(providerId));
    }
    if (categoryId != null) {
      where.add('i.category_id = ?');
      variables.add(Variable<String>(categoryId));
    }

    final normalizedQuery = normalizeCatalogText(searchQuery ?? '');
    if (normalizedQuery.isNotEmpty) {
      where.add('(i.normalized_title LIKE ? OR i.title LIKE ?)');
      variables
        ..add(Variable<String>('%$normalizedQuery%'))
        ..add(Variable<String>('%${searchQuery!.trim()}%'));
    }

    if (favoritesOnly) {
      where.add('fi.item_id IS NOT NULL');
    }

    return _db.customSelect(
      '''
      SELECT i.*, CASE WHEN fi.item_id IS NULL THEN 0 ELSE 1 END AS is_favorite
      FROM catalog_items AS i
      LEFT JOIN favorite_items AS fi
        ON fi.provider_id = i.provider_id
        AND fi.item_id = i.id
        AND fi.item_type = i.content_type
      WHERE ${where.join(' AND ')}
      ORDER BY is_favorite DESC, i.normalized_title ASC
      ''',
      variables: variables,
      readsFrom: {_db.catalogItems, _db.favoriteItems},
    );
  }

  List<CatalogItem> _mapItemRows(List<QueryRow> rows) {
    return rows.map((row) {
      final item = CatalogItemRow(
        id: row.read<String>('id'),
        providerId: row.read<String>('provider_id'),
        contentType: row.read<String>('content_type'),
        categoryId: row.readNullable<String>('category_id'),
        title: row.read<String>('title'),
        normalizedTitle: row.read<String>('normalized_title'),
        subtitle: row.readNullable<String>('subtitle'),
        description: row.readNullable<String>('description'),
        artworkUrl: row.readNullable<String>('artwork_url'),
        streamUrl: row.readNullable<String>('stream_url'),
        streamJson: row.readNullable<String>('stream_json'),
        externalId: row.readNullable<String>('external_id'),
        year: row.readNullable<int>('year'),
        rating: row.readNullable<String>('rating'),
        durationSeconds: row.readNullable<int>('duration_seconds'),
        epgChannelId: row.readNullable<String>('epg_channel_id'),
        containerExtension: row.readNullable<String>('container_extension'),
        createdAt: row.read<int>('created_at'),
        updatedAt: row.read<int>('updated_at'),
        lastSeenAt: row.read<int>('last_seen_at'),
        isStale: row.read<bool>('is_stale'),
      );
      return _toCatalogItem(
        item,
        isFavorite: row.read<int>('is_favorite') == 1,
      );
    }).toList();
  }

  Map<String, CatalogCategoryInput> _collectCategories(
    ProviderCatalogSnapshot snapshot,
  ) {
    final categories = <String, CatalogCategoryInput>{};

    for (final category in snapshot.categories) {
      final normalizedName = normalizeCatalogText(category.name);
      if (normalizedName.isEmpty) {
        continue;
      }
      categories[_categoryKey(
            category.providerId,
            category.contentType,
            normalizedName,
          )] =
          category;
    }

    final counts = <String, int>{};
    for (final item in snapshot.items) {
      final categoryName = item.categoryName?.trim();
      if (categoryName == null || categoryName.isEmpty) {
        continue;
      }

      final normalizedName = normalizeCatalogText(categoryName);
      final key = _categoryKey(
        item.providerId,
        item.contentType,
        normalizedName,
      );
      counts[key] = (counts[key] ?? 0) + 1;
      categories.putIfAbsent(
        key,
        () => CatalogCategoryInput(
          providerId: item.providerId,
          contentType: item.contentType,
          name: categoryName,
        ),
      );
    }

    return categories.map((key, category) {
      final normalizedName = normalizeCatalogText(category.name);
      return MapEntry(
        key,
        CatalogCategoryInput(
          id: category.id,
          providerId: category.providerId,
          contentType: category.contentType,
          name: category.name,
          externalId: category.externalId,
          itemCount:
              category.itemCount ??
              counts[_categoryKey(
                category.providerId,
                category.contentType,
                normalizedName,
              )] ??
              0,
        ),
      );
    });
  }

  Future<void> _upsertCategory(
    CatalogCategoryInput input,
    int lastSeenAt,
  ) async {
    final normalizedName = normalizeCatalogText(input.name);
    final categoryId = catalogCategoryId(
      input.providerId,
      input.contentType,
      input.name,
    );
    await _db
        .into(_db.categories)
        .insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: categoryId,
            providerId: input.providerId,
            contentType: input.contentType.name,
            name: input.name.trim(),
            normalizedName: normalizedName,
            externalId: Value(input.externalId ?? input.id),
            itemCount: Value(input.itemCount ?? 0),
            lastSeenAt: Value(lastSeenAt),
            isStale: const Value(false),
          ),
        );
  }

  Future<void> _upsertCatalogItem(CatalogItemInput input, int now) async {
    final categoryId = await _resolveCategoryId(input);

    await _db
        .into(_db.catalogItems)
        .insertOnConflictUpdate(
          CatalogItemsCompanion.insert(
            id: input.id,
            providerId: input.providerId,
            contentType: input.contentType.name,
            title: input.title.trim(),
            normalizedTitle: normalizeCatalogText(input.title),
            categoryId: Value(categoryId),
            subtitle: Value(input.subtitle),
            description: Value(input.description),
            artworkUrl: Value(input.artworkUrl),
            streamUrl: Value(input.streamUrl),
            streamJson: Value(input.streamJson),
            externalId: Value(input.externalId),
            year: Value(input.year),
            rating: Value(input.rating),
            durationSeconds: Value(input.durationSeconds),
            epgChannelId: Value(input.epgChannelId),
            containerExtension: Value(input.containerExtension),
            updatedAt: Value(now),
            lastSeenAt: Value(now),
            isStale: const Value(false),
          ),
        );
  }

  Future<void> _upsertSeries(SeriesInput input, int now) async {
    if (input.catalogItemId != null &&
        !await _catalogItemExists(
          providerId: input.providerId,
          contentType: CatalogContentType.series,
          itemId: input.catalogItemId!,
        )) {
      throw ArgumentError('Series catalog item is not in provider scope');
    }

    final seriesId = _seriesRowId(input);
    await _db
        .into(_db.series)
        .insertOnConflictUpdate(
          SeriesCompanion.insert(
            id: seriesId,
            providerId: input.providerId,
            title: input.title.trim(),
            normalizedTitle: normalizeCatalogText(input.title),
            catalogItemId: Value(input.catalogItemId),
            externalId: Value(input.id),
            overview: Value(input.overview),
            posterUrl: Value(input.posterUrl),
            backdropUrl: Value(input.backdropUrl),
            updatedAt: Value(now),
            lastSeenAt: Value(now),
            isStale: const Value(false),
          ),
        );
  }

  Future<void> _upsertSeason(SeasonInput input, int now) async {
    final seriesId = await _resolveSeriesId(
      providerId: input.providerId,
      seriesId: input.seriesId,
    );
    final seasonId = _seasonRowId(input);

    await _db
        .into(_db.seasons)
        .insertOnConflictUpdate(
          SeasonsCompanion.insert(
            id: seasonId,
            providerId: input.providerId,
            seriesId: seriesId,
            seasonNumber: input.seasonNumber,
            title: Value(input.title),
            overview: Value(input.overview),
            posterUrl: Value(input.posterUrl),
            updatedAt: Value(now),
            lastSeenAt: Value(now),
            isStale: const Value(false),
          ),
        );
  }

  Future<void> _upsertEpisode(EpisodeInput input, int now) async {
    final seriesId = await _resolveSeriesId(
      providerId: input.providerId,
      seriesId: input.seriesId,
    );
    final seasonId = await _resolveSeasonId(
      providerId: input.providerId,
      seriesId: seriesId,
      seasonId: input.seasonId,
      seasonNumber: input.seasonNumber,
    );

    await _db
        .into(_db.episodes)
        .insertOnConflictUpdate(
          EpisodesCompanion.insert(
            id: input.id,
            providerId: input.providerId,
            seriesId: seriesId,
            seasonId: seasonId,
            seasonNumber: input.seasonNumber,
            episodeNumber: input.episodeNumber,
            title: input.title.trim(),
            normalizedTitle: normalizeCatalogText(input.title),
            description: Value(input.description),
            artworkUrl: Value(input.artworkUrl),
            streamUrl: Value(input.streamUrl),
            streamJson: Value(input.streamJson),
            externalId: Value(input.externalId),
            durationSeconds: Value(input.durationSeconds),
            updatedAt: Value(now),
            lastSeenAt: Value(now),
            isStale: const Value(false),
          ),
        );
  }

  Future<String?> _resolveCategoryId(CatalogItemInput input) async {
    final categoryName = input.categoryName?.trim();
    if (categoryName != null && categoryName.isNotEmpty) {
      final row =
          await (_db.select(_db.categories)..where(
                (category) =>
                    category.providerId.equals(input.providerId) &
                    category.contentType.equals(input.contentType.name) &
                    category.normalizedName.equals(
                      normalizeCatalogText(categoryName),
                    ) &
                    category.isStale.equals(false),
              ))
              .getSingleOrNull();
      if (row != null) {
        return row.id;
      }
    }

    final sourceCategoryId = input.categoryId?.trim();
    if (sourceCategoryId == null || sourceCategoryId.isEmpty) {
      if (categoryName != null && categoryName.isNotEmpty) {
        throw ArgumentError('Catalog item category is not in provider scope');
      }
      return null;
    }

    final row =
        await (_db.select(_db.categories)..where(
              (category) =>
                  category.providerId.equals(input.providerId) &
                  category.contentType.equals(input.contentType.name) &
                  (category.id.equals(sourceCategoryId) |
                      category.externalId.equals(sourceCategoryId)) &
                  category.isStale.equals(false),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw ArgumentError('Catalog item category is not in provider scope');
    }

    return row.id;
  }

  Future<bool> _catalogItemExists({
    required String providerId,
    required CatalogContentType contentType,
    required String itemId,
  }) async {
    final row =
        await (_db.select(_db.catalogItems)..where(
              (item) =>
                  item.providerId.equals(providerId) &
                  item.contentType.equals(contentType.name) &
                  item.id.equals(itemId) &
                  item.isStale.equals(false),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<String> _resolveSeriesId({
    required String providerId,
    required String seriesId,
  }) async {
    final row =
        await (_db.select(_db.series)..where(
              (series) =>
                  series.providerId.equals(providerId) &
                  (series.id.equals(seriesId) |
                      series.externalId.equals(seriesId)) &
                  series.isStale.equals(false),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw ArgumentError('Series is not in provider scope');
    }

    return row.id;
  }

  Future<String> _resolveSeasonId({
    required String providerId,
    required String seriesId,
    required String seasonId,
    required int seasonNumber,
  }) async {
    final row =
        await (_db.select(_db.seasons)..where(
              (season) =>
                  season.providerId.equals(providerId) &
                  season.seriesId.equals(seriesId) &
                  (season.id.equals(seasonId) |
                      season.seasonNumber.equals(seasonNumber)) &
                  season.isStale.equals(false),
            ))
            .getSingleOrNull();
    if (row == null) {
      throw ArgumentError('Season is not in provider scope');
    }

    return row.id;
  }
}

String _seriesRowId(SeriesInput input) {
  final catalogItemId = input.catalogItemId?.trim();
  if (catalogItemId != null && catalogItemId.isNotEmpty) {
    return catalogItemId;
  }

  return input.id;
}

String _seasonRowId(SeasonInput input) {
  return input.seasonNumber.toString();
}

String catalogCategoryId(
  String providerId,
  CatalogContentType contentType,
  String name,
) {
  final normalizedName = Uri.encodeComponent(normalizeCatalogText(name));
  return '$providerId:${contentType.name}:$normalizedName';
}

String _categoryKey(
  String providerId,
  CatalogContentType contentType,
  String normalizedName,
) {
  return '$providerId|${contentType.name}|$normalizedName';
}

void _validateSnapshot(ProviderCatalogSnapshot snapshot) {
  final providerId = snapshot.providerId;
  for (final category in snapshot.categories) {
    if (category.providerId != providerId) {
      throw ArgumentError('Cannot replace categories across providers');
    }
  }
  for (final item in snapshot.items) {
    if (item.providerId != providerId) {
      throw ArgumentError('Cannot replace catalog items across providers');
    }
  }
  for (final item in snapshot.series) {
    if (item.providerId != providerId) {
      throw ArgumentError('Cannot replace series across providers');
    }
  }
  for (final item in snapshot.seasons) {
    if (item.providerId != providerId) {
      throw ArgumentError('Cannot replace seasons across providers');
    }
  }
  for (final item in snapshot.episodes) {
    if (item.providerId != providerId) {
      throw ArgumentError('Cannot replace episodes across providers');
    }
  }
}

CatalogProvider _toProvider(CatalogProviderRow row) {
  return CatalogProvider(
    id: row.id,
    type: CatalogProviderType.fromDb(row.type),
    name: row.name,
    source: row.source,
    sourceKind: row.sourceKind,
    username: row.username?.value,
    password: row.password?.value,
    createdAtMs: row.createdAt,
    updatedAtMs: row.updatedAt,
    lastRefreshAtMs: row.lastRefreshAt,
    autoRefreshEnabled: row.autoRefreshEnabled,
    autoRefreshIntervalMinutes: row.autoRefreshIntervalMinutes,
    isEnabled: row.isEnabled,
  );
}

SensitiveText? _sensitive(String? value) {
  final clean = value?.trim();
  return clean == null || clean.isEmpty ? null : SensitiveText(clean);
}

ProviderRefreshRun _toRefreshRun(ProviderRefreshRunRow row) {
  return ProviderRefreshRun(
    id: row.id,
    providerId: row.providerId,
    status: ProviderRefreshStatus.fromDb(row.status),
    startedAtMs: row.startedAt,
    finishedAtMs: row.finishedAt,
    itemCount: row.itemCount,
    errorMessage: row.errorMessage,
  );
}

CatalogItem _toCatalogItem(CatalogItemRow row, {bool isFavorite = false}) {
  return CatalogItem(
    id: row.id,
    providerId: row.providerId,
    contentType: CatalogContentType.fromDb(row.contentType),
    categoryId: row.categoryId,
    title: row.title,
    normalizedTitle: row.normalizedTitle,
    subtitle: row.subtitle,
    description: row.description,
    artworkUrl: row.artworkUrl,
    streamUrl: row.streamUrl,
    streamJson: row.streamJson,
    externalId: row.externalId,
    year: row.year,
    rating: row.rating,
    durationSeconds: row.durationSeconds,
    epgChannelId: row.epgChannelId,
    containerExtension: row.containerExtension,
    updatedAtMs: row.updatedAt,
    lastSeenAtMs: row.lastSeenAt,
    isFavorite: isFavorite,
  );
}

CatalogSeries _toSeries(SeriesRow row) {
  return CatalogSeries(
    id: row.id,
    providerId: row.providerId,
    catalogItemId: row.catalogItemId,
    title: row.title,
    normalizedTitle: row.normalizedTitle,
    externalId: row.externalId,
    overview: row.overview,
    posterUrl: row.posterUrl,
    backdropUrl: row.backdropUrl,
    updatedAtMs: row.updatedAt,
    lastSeenAtMs: row.lastSeenAt,
  );
}

CatalogEpisode _toEpisode(EpisodeRow row) {
  return CatalogEpisode(
    id: row.id,
    providerId: row.providerId,
    seriesId: row.seriesId,
    seasonId: row.seasonId,
    seasonNumber: row.seasonNumber,
    episodeNumber: row.episodeNumber,
    title: row.title,
    normalizedTitle: row.normalizedTitle,
    description: row.description,
    artworkUrl: row.artworkUrl,
    streamUrl: row.streamUrl,
    streamJson: row.streamJson,
    externalId: row.externalId,
    durationSeconds: row.durationSeconds,
    updatedAtMs: row.updatedAt,
    lastSeenAtMs: row.lastSeenAt,
  );
}

CatalogEpisode _episodeFromQueryRow(QueryRow row) {
  return _toEpisode(
    EpisodeRow(
      id: row.read<String>('id'),
      providerId: row.read<String>('provider_id'),
      seriesId: row.read<String>('series_id'),
      seasonId: row.read<String>('season_id'),
      seasonNumber: row.read<int>('season_number'),
      episodeNumber: row.read<int>('episode_number'),
      title: row.read<String>('title'),
      normalizedTitle: row.read<String>('normalized_title'),
      description: row.readNullable<String>('description'),
      artworkUrl: row.readNullable<String>('artwork_url'),
      streamUrl: row.readNullable<String>('stream_url'),
      streamJson: row.readNullable<String>('stream_json'),
      externalId: row.readNullable<String>('external_id'),
      durationSeconds: row.readNullable<int>('duration_seconds'),
      createdAt: row.read<int>('created_at'),
      updatedAt: row.read<int>('updated_at'),
      lastSeenAt: row.read<int>('last_seen_at'),
      isStale: row.read<bool>('is_stale'),
    ),
  );
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;
