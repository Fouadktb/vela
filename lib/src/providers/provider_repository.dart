import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../catalog/catalog_database.dart';
import '../catalog/catalog_models.dart';
import '../catalog/catalog_repository.dart';
import 'provider_models.dart';

class ProviderHealth {
  const ProviderHealth({
    required this.provider,
    required this.stats,
    required this.isEnabled,
    this.latestRun,
    this.nextRefreshAtMs,
  });

  final IptvProvider provider;
  final ProviderCatalogStats stats;
  final ProviderRefreshRun? latestRun;
  final int? nextRefreshAtMs;
  final bool isEnabled;

  bool get hasImportedCatalog => stats.hasImportedCatalog;

  bool get latestRefreshFailed {
    return latestRun?.status == ProviderRefreshStatus.failed ||
        provider.lastRefreshStatus == ProviderRefreshStatus.failed;
  }
}

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

  Stream<List<ProviderHealth>> watchProviderHealth() {
    return _providerHealthQuery().watch().map(_mapProviderHealthRows);
  }

  Future<ProviderRefreshRun?> latestRefreshRun(String providerId) async {
    final row =
        await (_db.select(_db.providerRefreshRuns)
              ..where((run) => run.providerId.equals(providerId))
              ..orderBy([(run) => OrderingTerm.desc(run.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _refreshRunFromRow(row);
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

  Future<void> updateProviderHealthSettings({
    required String providerId,
    required String name,
    required bool refreshEnabled,
    required int refreshIntervalMinutes,
  }) async {
    await (_db.update(
      _db.catalogProviders,
    )..where((row) => row.id.equals(providerId))).write(
      CatalogProvidersCompanion(
        name: Value(name.trim()),
        autoRefreshEnabled: Value(refreshEnabled),
        autoRefreshIntervalMinutes: Value(
          _validIntervalMinutes(refreshIntervalMinutes),
        ),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
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

  Future<void> replaceSeriesEpisodeDetails({
    required String providerId,
    required String seriesId,
    required List<SeasonInput> seasons,
    required List<EpisodeInput> episodes,
  }) {
    return _catalogRepository.replaceSeriesEpisodeDetails(
      providerId: providerId,
      seriesId: seriesId,
      seasons: seasons,
      episodes: episodes,
    );
  }

  Future<void> updateCatalogItemDetails(CatalogItemDetailsInput input) {
    return _catalogRepository.updateCatalogItemDetails(input);
  }

  Future<void> updateSeriesDetails(SeriesDetailsInput input) {
    return _catalogRepository.updateSeriesDetails(input);
  }

  Future<void> replaceProviderEpg({
    required String providerId,
    required List<EpgProgramInput> programs,
  }) {
    return _catalogRepository.replaceProviderEpg(
      providerId: providerId,
      programs: programs,
    );
  }

  Future<bool> hasAnyEpgPrograms(String providerId) {
    return _catalogRepository.hasAnyEpgPrograms(providerId);
  }

  Future<void> clearProviderCatalog(String providerId) {
    return _catalogRepository.clearProviderCatalog(providerId);
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

  Selectable<QueryRow> _providerHealthQuery() {
    return _db.customSelect(
      '''
      SELECT p.*,
             r.id AS run_id,
             r.provider_id AS run_provider_id,
             r.status AS last_refresh_status,
             r.error_message AS last_refresh_message,
             r.started_at AS run_started_at,
             r.finished_at AS run_finished_at,
             r.item_count AS run_item_count,
             (SELECT COUNT(*)
              FROM catalog_items
              WHERE provider_id = p.id
                AND content_type = ?
                AND is_stale = 0) AS live_count,
             (SELECT COUNT(*)
              FROM catalog_items
              WHERE provider_id = p.id
                AND content_type = ?
                AND is_stale = 0) AS movie_count,
             (SELECT COUNT(*)
              FROM catalog_items
              WHERE provider_id = p.id
                AND content_type = ?
                AND is_stale = 0) AS series_count,
             (SELECT COUNT(*)
              FROM episodes
              WHERE provider_id = p.id
                AND is_stale = 0) AS episode_count,
             (SELECT COUNT(*)
              FROM epg_programs
              WHERE provider_id = p.id) AS epg_program_count
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
      variables: [
        Variable<String>(CatalogContentType.live.name),
        Variable<String>(CatalogContentType.movie.name),
        Variable<String>(CatalogContentType.series.name),
      ],
      readsFrom: {
        _db.catalogProviders,
        _db.providerRefreshRuns,
        _db.catalogItems,
        _db.episodes,
        _db.epgPrograms,
      },
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

List<ProviderHealth> _mapProviderHealthRows(List<QueryRow> rows) {
  return rows.map(_providerHealthFromRow).toList();
}

ProviderHealth _providerHealthFromRow(QueryRow row) {
  final provider = _providerFromRow(row, redactSource: true);
  return ProviderHealth(
    provider: provider,
    stats: ProviderCatalogStats(
      liveCount: row.read<int>('live_count'),
      movieCount: row.read<int>('movie_count'),
      seriesCount: row.read<int>('series_count'),
      episodeCount: row.read<int>('episode_count'),
      epgProgramCount: row.read<int>('epg_program_count'),
    ),
    latestRun: _refreshRunFromQueryRow(row),
    nextRefreshAtMs: provider.nextRefreshAt?.millisecondsSinceEpoch,
    isEnabled: row.read<bool>('is_enabled'),
  );
}

IptvProvider _providerFromRow(QueryRow row, {bool redactSource = false}) {
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
    serverUrl: !redactSource && type == ProviderType.xtream
        ? row.read<String>('source')
        : null,
    username: redactSource ? null : row.readNullable<String>('username'),
    password: redactSource ? null : row.readNullable<String>('password'),
    m3uUrl: !redactSource && type == ProviderType.m3uUrl
        ? row.read<String>('source')
        : null,
    localFilePath: !redactSource && type == ProviderType.m3uFile
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

ProviderRefreshRun _refreshRunFromRow(ProviderRefreshRunRow row) {
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

ProviderRefreshRun? _refreshRunFromQueryRow(QueryRow row) {
  final id = row.readNullable<String>('run_id');
  final providerId = row.readNullable<String>('run_provider_id');
  final status = row.readNullable<String>('last_refresh_status');
  final startedAt = row.readNullable<int>('run_started_at');
  if (id == null || providerId == null || status == null || startedAt == null) {
    return null;
  }
  return ProviderRefreshRun(
    id: id,
    providerId: providerId,
    status: ProviderRefreshStatus.fromDb(status),
    startedAtMs: startedAt,
    finishedAtMs: row.readNullable<int>('run_finished_at'),
    itemCount: row.readNullable<int>('run_item_count') ?? 0,
    errorMessage: row.readNullable<String>('last_refresh_message'),
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
