import '../../app/section_state.dart';
import '../../catalog/catalog_models.dart';
import '../catalog/item_grid.dart';

enum HomeRowKind {
  continueWatching,
  recentLive,
  latestMovies,
  latestSeries,
  favorites,
  pinnedCategories,
}

class HomeRow {
  const HomeRow({
    required this.kind,
    required this.title,
    this.cards = const [],
    this.categories = const [],
  });

  final HomeRowKind kind;
  final String title;
  final List<CatalogCardItem> cards;
  final List<HomeCategoryTile> categories;

  bool get isEmpty => cards.isEmpty && categories.isEmpty;
}

class HomeCategoryTile {
  const HomeCategoryTile({
    required this.id,
    required this.providerId,
    required this.contentType,
    required this.section,
    required this.name,
    required this.itemCount,
  });

  final String id;
  final String providerId;
  final CatalogContentType contentType;
  final VelaSection section;
  final String name;
  final int itemCount;
}
