import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../catalog/catalog_models.dart';
import '../providers/provider_models.dart';

IconData iconForContentType(CatalogContentType type) {
  return switch (type) {
    CatalogContentType.live => LucideIcons.tv,
    CatalogContentType.movie => LucideIcons.film,
    CatalogContentType.series => LucideIcons.library,
  };
}

IconData iconForProviderType(ProviderType type) {
  return switch (type) {
    ProviderType.xtream => LucideIcons.server,
    ProviderType.m3uUrl => LucideIcons.link,
    ProviderType.m3uFile => LucideIcons.fileVideo,
  };
}

IconData iconForFavorite(bool isFavorite) {
  return isFavorite ? LucideIcons.star : LucideIcons.star;
}
