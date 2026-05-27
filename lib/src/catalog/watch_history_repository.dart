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
                completed: Value(update.completed),
                lastWatchedAt: Value(watchedAt),
              ),
            );
      } else {
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
                completed: Value(update.completed),
                lastWatchedAt: Value(watchedAt),
                watchCount: Value(existing.watchCount + 1),
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
      completed: row.completed,
      updatedAtMs: row.updatedAt,
    );
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
    completed: row.completed,
    lastWatchedAtMs: row.lastWatchedAt,
    watchCount: row.watchCount,
  );
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;
