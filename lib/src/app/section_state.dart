import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../catalog/catalog_models.dart';

enum VelaSection {
  home('Home', LucideIcons.house),
  live('Live', LucideIcons.tv),
  movies('Movies', LucideIcons.film),
  series('Series', LucideIcons.library),
  favorites('Favorites', LucideIcons.star),
  recent('Recent', LucideIcons.history),
  settings('Settings', LucideIcons.settings);

  const VelaSection(this.label, this.icon);

  final String label;
  final IconData icon;

  CatalogContentType? get contentType {
    return switch (this) {
      VelaSection.live => CatalogContentType.live,
      VelaSection.movies => CatalogContentType.movie,
      VelaSection.series => CatalogContentType.series,
      VelaSection.home ||
      VelaSection.favorites ||
      VelaSection.recent ||
      VelaSection.settings => null,
    };
  }

  String get eyebrow {
    return switch (this) {
      VelaSection.home => 'Home',
      VelaSection.settings => 'Preferences',
      VelaSection.recent => 'History',
      _ => 'Catalog',
    };
  }

  String get searchPlaceholder {
    return switch (this) {
      VelaSection.home => 'Search everything',
      VelaSection.live => 'Search channels',
      VelaSection.movies => 'Search movies',
      VelaSection.series => 'Search series',
      VelaSection.favorites => 'Search favorites',
      VelaSection.recent => 'Search recently watched',
      VelaSection.settings => 'Search settings',
    };
  }

  String get emptyTitle {
    return switch (this) {
      VelaSection.home => 'No home rows yet',
      VelaSection.live => 'No live channels',
      VelaSection.movies => 'No movies',
      VelaSection.series => 'No series',
      VelaSection.favorites => 'No favorites yet',
      VelaSection.recent => 'Nothing watched yet',
      VelaSection.settings => 'No providers yet',
    };
  }
}

class SectionState {
  const SectionState({
    this.searchQuery = '',
    this.categorySearchQuery = '',
    this.selectedCategoryId,
    this.selectedItemId,
  });

  final String searchQuery;
  final String categorySearchQuery;
  final String? selectedCategoryId;
  final String? selectedItemId;

  SectionState copyWith({
    String? searchQuery,
    String? categorySearchQuery,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? selectedItemId,
    bool clearSelectedItem = false,
  }) {
    return SectionState(
      searchQuery: searchQuery ?? this.searchQuery,
      categorySearchQuery: categorySearchQuery ?? this.categorySearchQuery,
      selectedCategoryId: clearCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
      selectedItemId: clearSelectedItem
          ? null
          : selectedItemId ?? this.selectedItemId,
    );
  }
}
