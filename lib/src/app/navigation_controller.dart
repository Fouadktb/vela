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
const defaultCategorySidebarWidth = 320.0;
const minCategorySidebarWidth = 240.0;
const maxCategorySidebarWidth = 520.0;

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
            limit: query.limit,
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

final liveGuideEpgProgramsProvider = StreamProvider.autoDispose
    .family<List<EpgProgram>, ProviderDayEpgProgramsQuery>((ref, query) {
      _keepAutoDisposeProviderWarm(ref);
      final database = ref.watch(catalogDatabaseProvider);
      final dayEndMs =
          query.dayStartMs + const Duration(days: 1).inMilliseconds;
      final statement = database.select(database.epgPrograms)
        ..where(
          (row) =>
              row.providerId.equals(query.providerId) &
              row.endAt.isBiggerOrEqualValue(query.dayStartMs) &
              row.startAt.isSmallerOrEqualValue(dayEndMs),
        )
        ..orderBy([
          (row) => OrderingTerm.asc(row.channelId),
          (row) => OrderingTerm.asc(row.startAt),
        ]);
      return statement.watch().map((rows) => rows.map(_toEpgProgram).toList());
    });

final recentlyWatchedProvider = StreamProvider<List<WatchHistoryEntry>>((ref) {
  return ref.watch(watchHistoryRepositoryProvider).watchRecentlyWatched();
});

final appSettingsProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(appSettingsRepositoryProvider).watchSettings();
});

enum LiveCatalogViewMode { list, guide }

class NavigationController extends ChangeNotifier {
  VelaSection _selectedSection = VelaSection.live;
  LiveCatalogViewMode _liveViewMode = LiveCatalogViewMode.list;
  int _liveGuideDayStartMs = _startOfTodayMs();
  double _categorySidebarWidth = defaultCategorySidebarWidth;
  final Map<VelaSection, SectionState> _states = {
    for (final section in VelaSection.values) section: const SectionState(),
  };

  VelaSection get selectedSection => _selectedSection;

  LiveCatalogViewMode get liveViewMode => _liveViewMode;

  int get liveGuideDayStartMs => _liveGuideDayStartMs;

  double get categorySidebarWidth => _categorySidebarWidth;

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

  void setLiveViewMode(LiveCatalogViewMode mode) {
    if (_liveViewMode == mode) {
      return;
    }
    _liveViewMode = mode;
    notifyListeners();
  }

  void setLiveGuideDayStartMs(int dayStartMs) {
    if (_liveGuideDayStartMs == dayStartMs) {
      return;
    }
    _liveGuideDayStartMs = dayStartMs;
    notifyListeners();
  }

  void setCategorySidebarWidth(double width) {
    final next = width
        .clamp(minCategorySidebarWidth, maxCategorySidebarWidth)
        .toDouble();
    if ((next - _categorySidebarWidth).abs() < 0.5) {
      return;
    }
    _categorySidebarWidth = next;
    notifyListeners();
  }

  void _updateActive(SectionState next) {
    _states[_selectedSection] = next;
    notifyListeners();
  }
}

EpgProgram _toEpgProgram(EpgProgramRow row) {
  return EpgProgram(
    providerId: row.providerId,
    channelId: row.channelId,
    startAtMs: row.startAt,
    endAtMs: row.endAt,
    title: row.title,
    description: row.description,
    category: row.category,
  );
}

int _startOfTodayMs() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
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
    this.limit,
  });

  final CatalogContentType section;
  final String? providerId;
  final String? categoryId;
  final bool favoritesOnly;
  final int? limit;

  @override
  bool operator ==(Object other) {
    return other is CatalogItemsQuery &&
        other.section == section &&
        other.providerId == providerId &&
        other.categoryId == categoryId &&
        other.favoritesOnly == favoritesOnly &&
        other.limit == limit;
  }

  @override
  int get hashCode {
    return Object.hash(section, providerId, categoryId, favoritesOnly, limit);
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

class ProviderDayEpgProgramsQuery {
  const ProviderDayEpgProgramsQuery({
    required this.providerId,
    required this.dayStartMs,
  });

  final String providerId;
  final int dayStartMs;

  @override
  bool operator ==(Object other) {
    return other is ProviderDayEpgProgramsQuery &&
        other.providerId == providerId &&
        other.dayStartMs == dayStartMs;
  }

  @override
  int get hashCode => Object.hash(providerId, dayStartMs);
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
