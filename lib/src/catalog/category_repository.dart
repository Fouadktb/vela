import 'package:drift/drift.dart';

import 'catalog_database.dart';
import 'catalog_models.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final CatalogDatabase _db;

  Stream<List<CatalogCategory>> watchLiveCategories({
    String? providerId,
    bool favoritesOnly = false,
  }) {
    return watchCategories(
      providerId: providerId,
      contentType: CatalogContentType.live,
      favoritesOnly: favoritesOnly,
    );
  }

  Stream<List<CatalogCategory>> watchMovieCategories({
    String? providerId,
    bool favoritesOnly = false,
  }) {
    return watchCategories(
      providerId: providerId,
      contentType: CatalogContentType.movie,
      favoritesOnly: favoritesOnly,
    );
  }

  Stream<List<CatalogCategory>> watchSeriesCategories({
    String? providerId,
    bool favoritesOnly = false,
  }) {
    return watchCategories(
      providerId: providerId,
      contentType: CatalogContentType.series,
      favoritesOnly: favoritesOnly,
    );
  }

  Stream<List<CatalogCategory>> watchCategories({
    String? providerId,
    required CatalogContentType contentType,
    bool favoritesOnly = false,
  }) {
    return _selectCategories(
      providerId: providerId,
      contentType: contentType,
      favoritesOnly: favoritesOnly,
    ).watch().map(_mapCategoryRows);
  }

  Future<bool> toggleCategoryFavorite({
    required String providerId,
    required CatalogContentType contentType,
    required String categoryId,
  }) async {
    return _db.transaction(() async {
      final existing =
          await (_db.select(_db.favoriteCategories)..where(
                (favorite) =>
                    favorite.providerId.equals(providerId) &
                    favorite.contentType.equals(contentType.name) &
                    favorite.categoryId.equals(categoryId),
              ))
              .getSingleOrNull();

      if (existing != null) {
        await (_db.delete(_db.favoriteCategories)..where(
              (favorite) =>
                  favorite.providerId.equals(providerId) &
                  favorite.contentType.equals(contentType.name) &
                  favorite.categoryId.equals(categoryId),
            ))
            .go();
        return false;
      }

      if (!await _categoryExists(
        providerId: providerId,
        contentType: contentType,
        categoryId: categoryId,
      )) {
        throw ArgumentError('Favorite category is not in provider scope');
      }

      await _db
          .into(_db.favoriteCategories)
          .insert(
            FavoriteCategoriesCompanion.insert(
              providerId: providerId,
              contentType: contentType.name,
              categoryId: categoryId,
              createdAt: Value(_nowMs()),
            ),
          );
      return true;
    });
  }

  Future<void> reorderCategories({
    required String providerId,
    required CatalogContentType contentType,
    required List<String> categoryIds,
  }) async {
    final uniqueIds = {
      for (final id in categoryIds)
        if (id.trim().isNotEmpty) id.trim(),
    }.toList();
    final now = _nowMs();

    await _db.transaction(() async {
      for (final categoryId in uniqueIds) {
        if (!await _categoryExists(
          providerId: providerId,
          contentType: contentType,
          categoryId: categoryId,
        )) {
          throw ArgumentError('Category order item is not in provider scope');
        }
      }

      await (_db.delete(_db.categoryOrder)..where(
            (order) =>
                order.providerId.equals(providerId) &
                order.contentType.equals(contentType.name),
          ))
          .go();

      for (var index = 0; index < uniqueIds.length; index += 1) {
        await _db
            .into(_db.categoryOrder)
            .insert(
              CategoryOrderCompanion.insert(
                providerId: providerId,
                contentType: contentType.name,
                categoryId: uniqueIds[index],
                sortOrder: index,
                updatedAt: Value(now),
              ),
            );
      }
    });
  }

  Selectable<QueryRow> _selectCategories({
    required CatalogContentType contentType,
    String? providerId,
    bool favoritesOnly = false,
  }) {
    final where = <String>['c.content_type = ?', 'c.is_stale = 0'];
    final variables = <Variable>[Variable<String>(contentType.name)];

    if (providerId != null) {
      where.add('c.provider_id = ?');
      variables.add(Variable<String>(providerId));
    }
    if (favoritesOnly) {
      where.add('fc.category_id IS NOT NULL');
    }

    return _db.customSelect(
      '''
      SELECT
        c.*,
        CASE WHEN fc.category_id IS NULL THEN 0 ELSE 1 END AS is_favorite,
        co.sort_order AS sort_order
      FROM categories AS c
      LEFT JOIN favorite_categories AS fc
        ON fc.provider_id = c.provider_id
        AND fc.content_type = c.content_type
        AND fc.category_id = c.id
      LEFT JOIN category_order AS co
        ON co.provider_id = c.provider_id
        AND co.content_type = c.content_type
        AND co.category_id = c.id
      WHERE ${where.join(' AND ')}
      ORDER BY
        CASE WHEN co.sort_order IS NULL THEN 1 ELSE 0 END ASC,
        co.sort_order ASC,
        is_favorite DESC,
        c.normalized_name ASC
      ''',
      variables: variables,
      readsFrom: {_db.categories, _db.favoriteCategories, _db.categoryOrder},
    );
  }

  List<CatalogCategory> _mapCategoryRows(List<QueryRow> rows) {
    return rows.map((row) {
      final category = CategoryRow(
        id: row.read<String>('id'),
        providerId: row.read<String>('provider_id'),
        contentType: row.read<String>('content_type'),
        externalId: row.readNullable<String>('external_id'),
        name: row.read<String>('name'),
        normalizedName: row.read<String>('normalized_name'),
        itemCount: row.read<int>('item_count'),
        lastSeenAt: row.read<int>('last_seen_at'),
        isStale: row.read<bool>('is_stale'),
      );
      return CatalogCategory(
        id: category.id,
        providerId: category.providerId,
        contentType: CatalogContentType.fromDb(category.contentType),
        name: category.name,
        normalizedName: category.normalizedName,
        itemCount: category.itemCount,
        lastSeenAtMs: category.lastSeenAt,
        externalId: category.externalId,
        isFavorite: row.read<int>('is_favorite') == 1,
        sortOrder: row.readNullable<int>('sort_order'),
      );
    }).toList();
  }

  Future<bool> _categoryExists({
    required String providerId,
    required CatalogContentType contentType,
    required String categoryId,
  }) async {
    final row =
        await (_db.select(_db.categories)..where(
              (category) =>
                  category.providerId.equals(providerId) &
                  category.contentType.equals(contentType.name) &
                  category.id.equals(categoryId) &
                  category.isStale.equals(false),
            ))
            .getSingleOrNull();
    return row != null;
  }
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;
