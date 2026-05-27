import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../catalog/catalog_database.dart';
import '../catalog/catalog_models.dart';
import '../catalog/catalog_repository.dart';
import '../catalog/category_repository.dart';
import '../catalog/watch_history_repository.dart';
import '../providers/provider_models.dart';
import '../providers/provider_refresh_service.dart';
import '../providers/provider_repository.dart';
import 'section_state.dart';

const _providerCacheDuration = Duration(minutes: 10);

final navigationControllerProvider =
    ChangeNotifierProvider<NavigationController>((ref) {
      return NavigationController();
    });

final catalogDatabaseProvider = Provider<CatalogDatabase>((ref) {
  final database = CatalogDatabase();
  ref.onDispose(database.close);
  return database;
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(catalogDatabaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(catalogDatabaseProvider));
});

final watchHistoryRepositoryProvider = Provider<WatchHistoryRepository>((ref) {
  return WatchHistoryRepository(ref.watch(catalogDatabaseProvider));
});

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  return ProviderRepository(
    ref.watch(catalogDatabaseProvider),
    ref.watch(catalogRepositoryProvider),
  );
});

final providerRefreshServiceProvider = Provider<ProviderRefreshService>((ref) {
  final service = ProviderRefreshService(
    providerRepository: ref.watch(providerRepositoryProvider),
  )..startIntervalRefresh();
  ref.onDispose(() {
    service.stopIntervalRefresh();
    service.dispose();
  });
  return service;
});

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository(ref.watch(catalogDatabaseProvider));
});

final providersProvider = StreamProvider<List<IptvProvider>>((ref) {
  return ref.watch(providerRepositoryProvider).watchProviders();
});

final categoriesProvider = StreamProvider.autoDispose
    .family<List<CatalogCategory>, CategoryQuery>((ref, query) {
      _keepAutoDisposeProviderWarm(ref);
      return ref
          .watch(categoryRepositoryProvider)
          .watchCategories(
            providerId: query.providerId,
            contentType: query.contentType,
            favoritesOnly: query.favoritesOnly,
          );
    });

final catalogItemsProvider = StreamProvider.autoDispose
    .family<List<CatalogItem>, CatalogItemsQuery>((ref, query) {
      _keepAutoDisposeProviderWarm(ref);
      return ref
          .watch(catalogRepositoryProvider)
          .watchItems(
            providerId: query.providerId,
            section: query.section,
            categoryId: query.categoryId,
            favoritesOnly: query.favoritesOnly,
          );
    });

final epgProgramsProvider = StreamProvider.autoDispose
    .family<List<EpgProgram>, EpgProgramsQuery>((ref, query) {
      _keepAutoDisposeProviderWarm(ref);
      return ref
          .watch(catalogRepositoryProvider)
          .watchEpgPrograms(
            providerId: query.providerId,
            channelIds: query.channelIds,
            fromMs: query.fromMs,
            toMs: query.toMs,
          );
    });

final recentlyWatchedProvider = StreamProvider<List<WatchHistoryEntry>>((ref) {
  return ref.watch(watchHistoryRepositoryProvider).watchRecentlyWatched();
});

final appSettingsProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(appSettingsRepositoryProvider).watchSettings();
});

class NavigationController extends ChangeNotifier {
  VelaSection _selectedSection = VelaSection.live;
  final Map<VelaSection, SectionState> _states = {
    for (final section in VelaSection.values) section: const SectionState(),
  };

  VelaSection get selectedSection => _selectedSection;

  SectionState get activeState => stateFor(_selectedSection);

  SectionState stateFor(VelaSection section) {
    return _states[section] ?? const SectionState();
  }

  void selectSection(VelaSection section) {
    if (_selectedSection == section) {
      return;
    }
    _selectedSection = section;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _updateActive(activeState.copyWith(searchQuery: value));
  }

  void setCategorySearchQuery(String value) {
    _updateActive(activeState.copyWith(categorySearchQuery: value));
  }

  void selectCategory(String? categoryId) {
    _updateActive(
      activeState.copyWith(
        selectedCategoryId: categoryId,
        clearCategory: categoryId == null,
        clearSelectedItem: true,
      ),
    );
  }

  void selectItem(String? itemId) {
    _updateActive(
      activeState.copyWith(
        selectedItemId: itemId,
        clearSelectedItem: itemId == null,
      ),
    );
  }

  void _updateActive(SectionState next) {
    _states[_selectedSection] = next;
    notifyListeners();
  }
}

void _keepAutoDisposeProviderWarm(Ref ref) {
  final link = ref.keepAlive();
  Timer? disposeTimer;

  ref.onCancel(() {
    disposeTimer = Timer(_providerCacheDuration, link.close);
  });
  ref.onResume(() {
    disposeTimer?.cancel();
    disposeTimer = null;
  });
  ref.onDispose(() {
    disposeTimer?.cancel();
  });
}

class CategoryQuery {
  const CategoryQuery({
    required this.contentType,
    this.providerId,
    this.favoritesOnly = false,
  });

  final CatalogContentType contentType;
  final String? providerId;
  final bool favoritesOnly;

  @override
  bool operator ==(Object other) {
    return other is CategoryQuery &&
        other.contentType == contentType &&
        other.providerId == providerId &&
        other.favoritesOnly == favoritesOnly;
  }

  @override
  int get hashCode => Object.hash(contentType, providerId, favoritesOnly);
}

class CatalogItemsQuery {
  const CatalogItemsQuery({
    required this.section,
    this.providerId,
    this.categoryId,
    this.favoritesOnly = false,
  });

  final CatalogContentType section;
  final String? providerId;
  final String? categoryId;
  final bool favoritesOnly;

  @override
  bool operator ==(Object other) {
    return other is CatalogItemsQuery &&
        other.section == section &&
        other.providerId == providerId &&
        other.categoryId == categoryId &&
        other.favoritesOnly == favoritesOnly;
  }

  @override
  int get hashCode {
    return Object.hash(section, providerId, categoryId, favoritesOnly);
  }
}

class EpgProgramsQuery {
  const EpgProgramsQuery({
    required this.providerId,
    required this.channelIds,
    required this.fromMs,
    required this.toMs,
  });

  final String providerId;
  final List<String> channelIds;
  final int fromMs;
  final int toMs;

  @override
  bool operator ==(Object other) {
    return other is EpgProgramsQuery &&
        other.providerId == providerId &&
        listEquals(other.channelIds, channelIds) &&
        other.fromMs == fromMs &&
        other.toMs == toMs;
  }

  @override
  int get hashCode =>
      Object.hash(providerId, Object.hashAll(channelIds), fromMs, toMs);
}

class AppSettingsRepository {
  AppSettingsRepository(this._db);

  final CatalogDatabase _db;

  Stream<Map<String, String>> watchSettings() {
    return _db.select(_db.appSettings).watch().map((rows) {
      return {for (final row in rows) row.key: row.value};
    });
  }

  Future<void> setValue(String key, String value) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }
}
