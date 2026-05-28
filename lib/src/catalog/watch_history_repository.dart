import 'package:drift/drift.dart';

import 'catalog_database.dart';
import 'catalog_models.dart';

class WatchHistoryRepository {
  WatchHistoryRepository(this._db);

  final CatalogDatabase _db;

  Stream<List<WatchHistoryEntry>> watchRecentlyWatched({int limit = 300}) {
    final query = _db.select(_db.watchHistory)
      ..orderBy([(history) => OrderingTerm.desc(history.lastWatchedAt)])
      ..limit(limit);

    return query.watch().map((rows) => rows.map(_toWatchHistoryEntry).toList());
  }

  Future<List<WatchHistoryEntry>> listRecentlyWatched({int limit = 300}) async {
    final query = _db.select(_db.watchHistory)
      ..orderBy([(history) => OrderingTerm.desc(history.lastWatchedAt)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_toWatchHistoryEntry).toList();
  }

  Future<int> recentlyWatchedCount() async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS count FROM watch_history',
          readsFrom: {_db.watchHistory},
        )
        .getSingle();
    return row.read<int>('count');
  }

  Future<List<Map<String, Object?>>> exportWatchHistory() async {
    final query = _db.select(_db.watchHistory)
      ..orderBy([(history) => OrderingTerm.desc(history.lastWatchedAt)]);
    final rows = await query.get();
    return rows.map(_watchHistoryToJson).toList();
  }

  Future<List<Map<String, Object?>>> exportPlaybackPositions() async {
    final query = _db.select(_db.playbackPositions)
      ..orderBy([(position) => OrderingTerm.desc(position.updatedAt)]);
    final rows = await query.get();
    return rows.map(_playbackPositionToJson).toList();
  }

  Future<void> clearRecentlyWatched({String? providerId}) async {
    await _db.transaction(() async {
      if (providerId == null) {
        await _db.delete(_db.watchHistory).go();
        await _db.delete(_db.playbackPositions).go();
        return;
      }

      await (_db.delete(
        _db.watchHistory,
      )..where((row) => row.providerId.equals(providerId))).go();
      await (_db.delete(
        _db.playbackPositions,
      )..where((row) => row.providerId.equals(providerId))).go();
    });
  }

  Future<void> addOrUpdateWatchHistory(WatchHistoryUpdate update) async {
    final watchedAt = update.watchedAtMs ?? _nowMs();
    final completionPercentage = update.completed
        ? 1.0
        : _normalizedCompletionPercentage(update.completionPercentage);
    final catalogKey = playbackCatalogKey(
      itemId: update.itemId,
      itemType: update.itemType,
      seriesId: update.seriesId,
      seasonId: update.seasonId,
    );

    await _db.transaction(() async {
      final existing =
          await (_db.select(_db.watchHistory)..where(
                (history) =>
                    history.providerId.equals(update.providerId) &
                    history.itemType.equals(update.itemType.name) &
                    history.catalogKey.equals(catalogKey),
              ))
              .getSingleOrNull();

      if (existing == null) {
        await _db
            .into(_db.watchHistory)
            .insert(
              WatchHistoryCompanion.insert(
                catalogKey: catalogKey,
                itemId: update.itemId,
                itemType: update.itemType.name,
                providerId: update.providerId,
                title: update.title,
                subtitle: Value(update.subtitle),
                artworkUrl: Value(update.artworkUrl),
                seriesId: Value(update.seriesId),
                seasonId: Value(update.seasonId),
                positionSeconds: Value(update.positionSeconds),
                durationSeconds: Value(update.durationSeconds),
                completionPercentage: Value(completionPercentage),
                completed: Value(update.completed),
                lastWatchedAt: Value(watchedAt),
              ),
            );
      } else {
        final watchCount = update.incrementWatchCount
            ? existing.watchCount + 1
            : existing.watchCount;
        await (_db.update(_db.watchHistory)..where(
              (history) =>
                  history.providerId.equals(update.providerId) &
                  history.itemType.equals(update.itemType.name) &
                  history.catalogKey.equals(catalogKey),
            ))
            .write(
              WatchHistoryCompanion(
                providerId: Value(update.providerId),
                title: Value(update.title),
                subtitle: Value(update.subtitle),
                artworkUrl: Value(update.artworkUrl),
                seriesId: Value(update.seriesId),
                seasonId: Value(update.seasonId),
                positionSeconds: Value(update.positionSeconds),
                durationSeconds: Value(update.durationSeconds),
                completionPercentage: Value(completionPercentage),
                completed: Value(update.completed),
                lastWatchedAt: Value(watchedAt),
                watchCount: Value(watchCount),
              ),
            );
      }

      await _db
          .into(_db.playbackPositions)
          .insertOnConflictUpdate(
            PlaybackPositionsCompanion.insert(
              providerId: update.providerId,
              catalogKey: catalogKey,
              itemId: update.itemId,
              itemType: update.itemType.name,
              seriesId: Value(update.seriesId),
              seasonId: Value(update.seasonId),
              positionSeconds: Value(update.positionSeconds),
              durationSeconds: Value(update.durationSeconds),
              completionPercentage: Value(completionPercentage),
              completed: Value(update.completed),
              updatedAt: Value(watchedAt),
            ),
          );
    });
  }

  Future<PlaybackPosition?> lookupResumePosition({
    required String providerId,
    required String itemId,
    required PlayableContentType itemType,
    String? seriesId,
    String? seasonId,
  }) async {
    final catalogKey = playbackCatalogKey(
      itemId: itemId,
      itemType: itemType,
      seriesId: seriesId,
      seasonId: seasonId,
    );
    final row =
        await (_db.select(_db.playbackPositions)..where(
              (position) =>
                  position.providerId.equals(providerId) &
                  position.itemType.equals(itemType.name) &
                  position.catalogKey.equals(catalogKey),
            ))
            .getSingleOrNull();

    if (row == null || row.completed || row.positionSeconds <= 0) {
      return null;
    }

    return PlaybackPosition(
      providerId: row.providerId,
      itemId: row.itemId,
      itemType: PlayableContentType.fromDb(row.itemType),
      seriesId: row.seriesId,
      seasonId: row.seasonId,
      positionSeconds: row.positionSeconds,
      durationSeconds: row.durationSeconds,
      completionPercentage: row.completionPercentage,
      completed: row.completed,
      updatedAtMs: row.updatedAt,
    );
  }

  Future<PlaybackPosition?> lookupLatestResumeForSeries({
    required String providerId,
    required String seriesId,
  }) async {
    final row =
        await (_db.select(_db.playbackPositions)
              ..where(
                (position) =>
                    position.providerId.equals(providerId) &
                    position.itemType.equals(PlayableContentType.episode.name) &
                    position.seriesId.equals(seriesId) &
                    position.completed.equals(false) &
                    position.positionSeconds.isBiggerThanValue(0),
              )
              ..orderBy([(position) => OrderingTerm.desc(position.updatedAt)])
              ..limit(1))
            .getSingleOrNull();

    if (row == null) return null;

    return PlaybackPosition(
      providerId: row.providerId,
      itemId: row.itemId,
      itemType: PlayableContentType.fromDb(row.itemType),
      seriesId: row.seriesId,
      seasonId: row.seasonId,
      positionSeconds: row.positionSeconds,
      durationSeconds: row.durationSeconds,
      completionPercentage: row.completionPercentage,
      completed: row.completed,
      updatedAtMs: row.updatedAt,
    );
  }

  Future<PlaybackPosition?> lookupLatestPositionForSeries({
    required String providerId,
    required String seriesId,
  }) async {
    final row =
        await (_db.select(_db.playbackPositions)
              ..where(
                (position) =>
                    position.providerId.equals(providerId) &
                    position.itemType.equals(PlayableContentType.episode.name) &
                    position.seriesId.equals(seriesId) &
                    (position.completed.equals(true) |
                        position.positionSeconds.isBiggerThanValue(0)),
              )
              ..orderBy([(position) => OrderingTerm.desc(position.updatedAt)])
              ..limit(1))
            .getSingleOrNull();

    return row == null ? null : _toPlaybackPosition(row);
  }

  Future<Map<({String providerId, String itemId}), PlaybackPosition>>
  listActiveResumePositions({
    required PlayableContentType itemType,
    Iterable<String>? providerIds,
  }) async {
    final ids = _normalizedProviderIds(providerIds);
    final query = _db.select(_db.playbackPositions)
      ..where((position) {
        Expression<bool> predicate =
            position.itemType.equals(itemType.name) &
            position.completed.equals(false) &
            position.positionSeconds.isBiggerThanValue(0);
        if (ids.isNotEmpty) {
          predicate = predicate & position.providerId.isIn(ids);
        }
        return predicate;
      });
    final rows = await query.get();

    return {
      for (final row in rows)
        (providerId: row.providerId, itemId: row.itemId): _toPlaybackPosition(
          row,
        ),
    };
  }

  Future<Map<({String providerId, String seriesId}), PlaybackPosition>>
  listLatestResumePositionsBySeries({Iterable<String>? providerIds}) async {
    final ids = _normalizedProviderIds(providerIds);
    final query = _db.select(_db.playbackPositions)
      ..where((position) {
        Expression<bool> predicate =
            position.itemType.equals(PlayableContentType.episode.name) &
            position.completed.equals(false) &
            position.positionSeconds.isBiggerThanValue(0);
        if (ids.isNotEmpty) {
          predicate = predicate & position.providerId.isIn(ids);
        }
        return predicate;
      })
      ..orderBy([(position) => OrderingTerm.desc(position.updatedAt)]);
    final rows = await query.get();
    final positions =
        <({String providerId, String seriesId}), PlaybackPosition>{};

    for (final row in rows) {
      final seriesId = row.seriesId;
      if (seriesId == null || seriesId.trim().isEmpty) {
        continue;
      }
      final key = (providerId: row.providerId, seriesId: seriesId);
      positions.putIfAbsent(key, () => _toPlaybackPosition(row));
    }

    return positions;
  }

  Future<Map<({String providerId, String seriesId}), PlaybackPosition>>
  listLatestPositionsBySeries({Iterable<String>? providerIds}) async {
    final ids = _normalizedProviderIds(providerIds);
    final query = _db.select(_db.playbackPositions)
      ..where((position) {
        Expression<bool> predicate =
            position.itemType.equals(PlayableContentType.episode.name) &
            (position.completed.equals(true) |
                position.positionSeconds.isBiggerThanValue(0));
        if (ids.isNotEmpty) {
          predicate = predicate & position.providerId.isIn(ids);
        }
        return predicate;
      })
      ..orderBy([(position) => OrderingTerm.desc(position.updatedAt)]);
    final rows = await query.get();
    final positions =
        <({String providerId, String seriesId}), PlaybackPosition>{};

    for (final row in rows) {
      final seriesId = row.seriesId;
      if (seriesId == null || seriesId.trim().isEmpty) {
        continue;
      }
      final key = (providerId: row.providerId, seriesId: seriesId);
      positions.putIfAbsent(key, () => _toPlaybackPosition(row));
    }

    return positions;
  }

  Future<List<PlaybackPosition>> listEpisodePositionsForSeries({
    required String providerId,
    required String seriesId,
  }) async {
    final grouped = await listEpisodePositionsBySeries(
      seriesKeys: [(providerId: providerId, seriesId: seriesId)],
    );
    return grouped[(providerId: providerId, seriesId: seriesId)] ??
        const <PlaybackPosition>[];
  }

  Future<Map<({String providerId, String seriesId}), List<PlaybackPosition>>>
  listEpisodePositionsBySeries({
    required Iterable<({String providerId, String seriesId})> seriesKeys,
  }) async {
    final keys = {
      for (final key in seriesKeys)
        if (key.providerId.trim().isNotEmpty && key.seriesId.trim().isNotEmpty)
          (providerId: key.providerId, seriesId: key.seriesId),
    };
    if (keys.isEmpty) {
      return <({String providerId, String seriesId}), List<PlaybackPosition>>{};
    }

    final providerIds = keys.map((key) => key.providerId).toSet();
    final query = _db.select(_db.playbackPositions)
      ..where((position) {
        return position.itemType.equals(PlayableContentType.episode.name) &
            position.providerId.isIn(providerIds) &
            (position.completed.equals(true) |
                position.positionSeconds.isBiggerThanValue(0));
      })
      ..orderBy([(position) => OrderingTerm.desc(position.updatedAt)]);
    final rows = await query.get();
    final grouped =
        <({String providerId, String seriesId}), List<PlaybackPosition>>{};

    for (final row in rows) {
      final seriesId = row.seriesId;
      if (seriesId == null || seriesId.trim().isEmpty) {
        continue;
      }
      final key = (providerId: row.providerId, seriesId: seriesId);
      if (!keys.contains(key)) {
        continue;
      }
      grouped.putIfAbsent(key, () => []).add(_toPlaybackPosition(row));
    }

    return grouped;
  }

  Stream<List<PlaybackPosition>> watchEpisodePositionsForSeries({
    required String providerId,
    required String seriesId,
  }) {
    final query = _db.select(_db.playbackPositions)
      ..where(
        (position) =>
            position.providerId.equals(providerId) &
            position.itemType.equals(PlayableContentType.episode.name) &
            position.seriesId.equals(seriesId),
      )
      ..orderBy([(position) => OrderingTerm.desc(position.updatedAt)]);

    return query.watch().map((rows) => rows.map(_toPlaybackPosition).toList());
  }

  Future<void> clearResumePosition({
    required String providerId,
    required String itemId,
    required PlayableContentType itemType,
    String? seriesId,
    String? seasonId,
  }) async {
    final catalogKey = playbackCatalogKey(
      itemId: itemId,
      itemType: itemType,
      seriesId: seriesId,
      seasonId: seasonId,
    );
    await (_db.delete(_db.playbackPositions)..where(
          (position) =>
              position.providerId.equals(providerId) &
              position.itemType.equals(itemType.name) &
              position.catalogKey.equals(catalogKey),
        ))
        .go();
  }
}

List<String> _normalizedProviderIds(Iterable<String>? providerIds) {
  return providerIds
          ?.where((value) => value.trim().isNotEmpty)
          .toSet()
          .toList(growable: false) ??
      const [];
}

PlaybackPosition _toPlaybackPosition(PlaybackPositionRow row) {
  return PlaybackPosition(
    providerId: row.providerId,
    itemId: row.itemId,
    itemType: PlayableContentType.fromDb(row.itemType),
    seriesId: row.seriesId,
    seasonId: row.seasonId,
    positionSeconds: row.positionSeconds,
    durationSeconds: row.durationSeconds,
    completionPercentage: row.completionPercentage,
    completed: row.completed,
    updatedAtMs: row.updatedAt,
  );
}

WatchHistoryEntry _toWatchHistoryEntry(WatchHistoryRow row) {
  return WatchHistoryEntry(
    itemId: row.itemId,
    itemType: PlayableContentType.fromDb(row.itemType),
    providerId: row.providerId,
    title: row.title,
    subtitle: row.subtitle,
    artworkUrl: row.artworkUrl,
    seriesId: row.seriesId,
    seasonId: row.seasonId,
    positionSeconds: row.positionSeconds,
    durationSeconds: row.durationSeconds,
    completionPercentage: row.completionPercentage,
    completed: row.completed,
    lastWatchedAtMs: row.lastWatchedAt,
    watchCount: row.watchCount,
  );
}

Map<String, Object?> _watchHistoryToJson(WatchHistoryRow row) {
  return {
    'provider_id': row.providerId,
    'catalog_key': row.catalogKey,
    'item_id': row.itemId,
    'item_type': row.itemType,
    'title': row.title,
    'subtitle': row.subtitle,
    'series_id': row.seriesId,
    'season_id': row.seasonId,
    'position_seconds': row.positionSeconds,
    'duration_seconds': row.durationSeconds,
    'completion_percentage': row.completionPercentage,
    'completed': row.completed,
    'last_watched_at_ms': row.lastWatchedAt,
    'watch_count': row.watchCount,
  };
}

Map<String, Object?> _playbackPositionToJson(PlaybackPositionRow row) {
  return {
    'provider_id': row.providerId,
    'catalog_key': row.catalogKey,
    'item_id': row.itemId,
    'item_type': row.itemType,
    'series_id': row.seriesId,
    'season_id': row.seasonId,
    'position_seconds': row.positionSeconds,
    'duration_seconds': row.durationSeconds,
    'completion_percentage': row.completionPercentage,
    'completed': row.completed,
    'updated_at_ms': row.updatedAt,
  };
}

double _normalizedCompletionPercentage(double value) {
  if (value.isNaN || value.isInfinite) return 0;
  return value.clamp(0, 1).toDouble();
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;
