import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../catalog/catalog_database.dart';
import '../catalog/catalog_models.dart';
import '../catalog/catalog_repository.dart';
import 'provider_models.dart';

class ProviderRepository {
  ProviderRepository(this._db, this._catalogRepository);

  final CatalogDatabase _db;
  final CatalogRepository _catalogRepository;

  Stream<List<IptvProvider>> watchProviders() {
    return _providersQuery().watch().map(_mapProviderRows);
  }

  Future<List<IptvProvider>> listProviders() async {
    final rows = await _providersQuery().get();
    return _mapProviderRows(rows);
  }

  Future<IptvProvider?> getProvider(String id) async {
    final rows = await _providerQuery(id).get();
    if (rows.isEmpty) {
      return null;
    }
    return _providerFromRow(rows.single);
  }

  Future<IptvProvider> createOrUpdateProvider(ProviderInput input) async {
    final id = input.id?.trim().isNotEmpty == true
        ? input.id!.trim()
        : providerIdFor(input);
    final existing = await (_db.select(
      _db.catalogProviders,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    final now = DateTime.now().millisecondsSinceEpoch;
    final source = _sourceFor(input);
    final row = CatalogProvidersCompanion.insert(
      id: id,
      type: _catalogProviderType(input.type).name,
      name: input.name.trim(),
      source: source,
      sourceKind: Value(_sourceKindFor(input.type)),
      username: Value(_sensitive(input.username)),
      password: Value(_sensitive(input.password)),
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
      lastRefreshAt: Value(existing?.lastRefreshAt),
      autoRefreshEnabled: Value(input.refreshEnabled),
      autoRefreshIntervalMinutes: Value(
        _validIntervalMinutes(input.refreshIntervalMinutes),
      ),
      isEnabled: const Value(true),
    );

    await _db.into(_db.catalogProviders).insertOnConflictUpdate(row);
    return (await getProvider(id))!;
  }

  Future<void> updateRefreshSettings({
    required String providerId,
    required bool enabled,
    required int intervalMinutes,
  }) async {
    await (_db.update(
      _db.catalogProviders,
    )..where((row) => row.id.equals(providerId))).write(
      CatalogProvidersCompanion(
        autoRefreshEnabled: Value(enabled),
        autoRefreshIntervalMinutes: Value(
          _validIntervalMinutes(intervalMinutes),
        ),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<ProviderRefreshRun> createRefreshRun(String providerId) {
    final runId =
        '$providerId:refresh:${DateTime.now().microsecondsSinceEpoch}';
    return _catalogRepository.createRefreshRun(
      id: runId,
      providerId: providerId,
    );
  }

  Future<void> finishRefreshRun({
    required String runId,
    required ProviderRefreshStatus status,
    int itemCount = 0,
    String? message,
  }) async {
    await _catalogRepository.finishRefreshRun(
      id: runId,
      status: status,
      itemCount: itemCount,
      errorMessage: _safeStatusMessage(message),
    );
  }

  Future<void> replaceProviderCatalog(ProviderCatalogSnapshot snapshot) {
    return _catalogRepository.replaceProviderCatalog(snapshot);
  }

  Future<void> deleteProvider(String providerId) {
    return _catalogRepository.deleteProvider(providerId);
  }

  Selectable<QueryRow> _providersQuery() {
    return _db.customSelect(
      '''
      SELECT p.*,
             r.status AS last_refresh_status,
             r.error_message AS last_refresh_message,
             r.started_at AS run_started_at,
             r.finished_at AS run_finished_at,
             r.item_count AS run_item_count
      FROM providers AS p
      LEFT JOIN provider_refresh_runs AS r
        ON r.id = (
          SELECT id
          FROM provider_refresh_runs
          WHERE provider_id = p.id
          ORDER BY started_at DESC
          LIMIT 1
        )
      ORDER BY p.name ASC
      ''',
      readsFrom: {_db.catalogProviders, _db.providerRefreshRuns},
    );
  }

  Selectable<QueryRow> _providerQuery(String id) {
    return _db.customSelect(
      '''
      SELECT p.*,
             r.status AS last_refresh_status,
             r.error_message AS last_refresh_message,
             r.started_at AS run_started_at,
             r.finished_at AS run_finished_at,
             r.item_count AS run_item_count
      FROM providers AS p
      LEFT JOIN provider_refresh_runs AS r
        ON r.id = (
          SELECT id
          FROM provider_refresh_runs
          WHERE provider_id = p.id
          ORDER BY started_at DESC
          LIMIT 1
        )
      WHERE p.id = ?
      LIMIT 1
      ''',
      variables: [Variable<String>(id)],
      readsFrom: {_db.catalogProviders, _db.providerRefreshRuns},
    );
  }
}

String providerIdFor(ProviderInput input) {
  final source = _sourceFor(input);
  final nameSlug = _slugify(input.name);
  final slug = nameSlug.isEmpty ? input.type.name : nameSlug;
  return '${input.type.name}:$slug:${_stableHash(source)}';
}

List<IptvProvider> _mapProviderRows(List<QueryRow> rows) {
  return rows.map(_providerFromRow).toList();
}

IptvProvider _providerFromRow(QueryRow row) {
  final type = _providerTypeFromDb(
    row.read<String>('type'),
    row.readNullable<String>('source_kind'),
  );
  final lastRefreshAt = dateTimeFromMs(
    row.readNullable<int>('last_refresh_at'),
  );
  final intervalMinutes = row.read<int>('auto_refresh_interval_minutes');

  return IptvProvider(
    id: row.read<String>('id'),
    name: row.read<String>('name'),
    type: type,
    serverUrl: type == ProviderType.xtream ? row.read<String>('source') : null,
    username: row.readNullable<String>('username'),
    password: row.readNullable<String>('password'),
    m3uUrl: type == ProviderType.m3uUrl ? row.read<String>('source') : null,
    localFilePath: type == ProviderType.m3uFile
        ? row.read<String>('source')
        : null,
    refreshEnabled: row.read<bool>('auto_refresh_enabled'),
    refreshIntervalMinutes: intervalMinutes,
    lastRefreshAt: lastRefreshAt,
    nextRefreshAt: lastRefreshAt?.add(Duration(minutes: intervalMinutes)),
    lastRefreshStatus: _statusFromDb(
      row.readNullable<String>('last_refresh_status'),
    ),
    lastRefreshMessage: row.readNullable<String>('last_refresh_message'),
  );
}

ProviderRefreshStatus? _statusFromDb(String? value) {
  if (value == null) {
    return null;
  }
  return ProviderRefreshStatus.fromDb(value);
}

CatalogProviderType _catalogProviderType(ProviderType type) {
  return switch (type) {
    ProviderType.xtream => CatalogProviderType.xtream,
    ProviderType.m3uUrl || ProviderType.m3uFile => CatalogProviderType.m3u,
  };
}

ProviderType _providerTypeFromDb(String type, String? sourceKind) {
  if (type == CatalogProviderType.xtream.name) {
    return ProviderType.xtream;
  }
  return sourceKind == 'file' ? ProviderType.m3uFile : ProviderType.m3uUrl;
}

String? _sourceKindFor(ProviderType type) {
  return switch (type) {
    ProviderType.xtream => null,
    ProviderType.m3uUrl => 'url',
    ProviderType.m3uFile => 'file',
  };
}

String _sourceFor(ProviderInput input) {
  final source = switch (input.type) {
    ProviderType.xtream => input.serverUrl,
    ProviderType.m3uUrl => input.m3uUrl,
    ProviderType.m3uFile => input.localFilePath,
  };
  final clean = source?.trim();
  if (clean == null || clean.isEmpty) {
    throw const ProviderRefreshFailure('Provider source is incomplete');
  }
  return input.type == ProviderType.xtream ? normalizeServerUrl(clean) : clean;
}

String? _clean(String? value) {
  final clean = value?.trim();
  return clean == null || clean.isEmpty ? null : clean;
}

SensitiveText? _sensitive(String? value) {
  final clean = _clean(value);
  return clean == null ? null : SensitiveText(clean);
}

int _validIntervalMinutes(int minutes) {
  return math.max(1, math.min(10080, minutes));
}

String? _safeStatusMessage(String? message) {
  final clean = message?.trim();
  if (clean == null || clean.isEmpty) {
    return null;
  }
  return clean.length <= 500 ? clean : clean.substring(0, 500);
}

String normalizeServerUrl(String source) {
  final parsed = Uri.tryParse(source.trim());
  if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
    return source.trim().replaceAll(RegExp(r'/+$'), '');
  }
  final normalizedPath = parsed.path.replaceAll(RegExp(r'/+$'), '');
  return parsed
      .replace(path: normalizedPath, query: null, fragment: null)
      .toString()
      .replaceAll(RegExp(r'/+$'), '');
}

String _slugify(String value) {
  final slug = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.length <= 80 ? slug : slug.substring(0, 80);
}

String _stableHash(String value) {
  var hash = 0xcbf29ce484222325;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return hash.toRadixString(16);
}
