import '../catalog/catalog_models.dart';

enum ProviderType {
  xtream,
  m3uUrl,
  m3uFile;

  bool get isM3u => this == ProviderType.m3uUrl || this == ProviderType.m3uFile;
}

class IptvProvider {
  const IptvProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.isEnabled,
    required this.refreshEnabled,
    required this.refreshIntervalMinutes,
    this.serverUrl,
    this.username,
    this.password,
    this.m3uUrl,
    this.localFilePath,
    this.lastRefreshAt,
    this.nextRefreshAt,
    this.lastRefreshStatus,
    this.lastRefreshMessage,
  });

  final String id;
  final String name;
  final ProviderType type;
  final bool isEnabled;
  final String? serverUrl;
  final String? username;
  final String? password;
  final String? m3uUrl;
  final String? localFilePath;
  final bool refreshEnabled;
  final int refreshIntervalMinutes;
  final DateTime? lastRefreshAt;
  final DateTime? nextRefreshAt;
  final ProviderRefreshStatus? lastRefreshStatus;
  final String? lastRefreshMessage;

  String? get source {
    return switch (type) {
      ProviderType.xtream => serverUrl,
      ProviderType.m3uUrl => m3uUrl,
      ProviderType.m3uFile => localFilePath,
    };
  }

  bool get canRefresh {
    if (!isEnabled) {
      return false;
    }
    final source = this.source;
    if (source == null || source.trim().isEmpty) {
      return false;
    }
    if (type == ProviderType.xtream) {
      return username?.trim().isNotEmpty == true &&
          password?.trim().isNotEmpty == true;
    }
    return true;
  }

  bool get isRefreshStale {
    if (!refreshEnabled) {
      return false;
    }
    final next = nextRefreshAt;
    return next == null || !next.isAfter(DateTime.now());
  }

  bool get hasImportedCatalog => lastRefreshAt != null;

  IptvProvider copyWith({
    String? id,
    String? name,
    ProviderType? type,
    bool? isEnabled,
    String? serverUrl,
    String? username,
    String? password,
    String? m3uUrl,
    String? localFilePath,
    bool? refreshEnabled,
    int? refreshIntervalMinutes,
    DateTime? lastRefreshAt,
    DateTime? nextRefreshAt,
    ProviderRefreshStatus? lastRefreshStatus,
    String? lastRefreshMessage,
  }) {
    return IptvProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      m3uUrl: m3uUrl ?? this.m3uUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      refreshEnabled: refreshEnabled ?? this.refreshEnabled,
      refreshIntervalMinutes:
          refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      nextRefreshAt: nextRefreshAt ?? this.nextRefreshAt,
      lastRefreshStatus: lastRefreshStatus ?? this.lastRefreshStatus,
      lastRefreshMessage: lastRefreshMessage ?? this.lastRefreshMessage,
    );
  }

  @override
  String toString() {
    return 'IptvProvider('
        'id: $id, '
        'name: $name, '
        'type: $type, '
        'isEnabled: $isEnabled, '
        'serverUrl: ${serverUrl == null ? null : '<redacted>'}, '
        'username: ${username == null ? null : '<redacted>'}, '
        'password: ${password == null ? null : '<redacted>'}, '
        'm3uUrl: ${m3uUrl == null ? null : '<redacted>'}, '
        'localFilePath: ${localFilePath == null ? null : '<redacted>'}, '
        'refreshEnabled: $refreshEnabled, '
        'refreshIntervalMinutes: $refreshIntervalMinutes, '
        'lastRefreshAt: $lastRefreshAt, '
        'nextRefreshAt: $nextRefreshAt, '
        'lastRefreshStatus: $lastRefreshStatus, '
        'lastRefreshMessage: $lastRefreshMessage'
        ')';
  }
}

class ProviderInput {
  const ProviderInput({
    required this.name,
    required this.type,
    this.id,
    this.serverUrl,
    this.username,
    this.password,
    this.m3uUrl,
    this.localFilePath,
    this.isEnabled = true,
    this.refreshEnabled = true,
    this.refreshIntervalMinutes = 24 * 60,
  });

  final String? id;
  final String name;
  final ProviderType type;
  final String? serverUrl;
  final String? username;
  final String? password;
  final String? m3uUrl;
  final String? localFilePath;
  final bool isEnabled;
  final bool refreshEnabled;
  final int refreshIntervalMinutes;

  @override
  String toString() {
    return 'ProviderInput('
        'id: $id, '
        'name: $name, '
        'type: $type, '
        'serverUrl: ${serverUrl == null ? null : '<redacted>'}, '
        'username: ${username == null ? null : '<redacted>'}, '
        'password: ${password == null ? null : '<redacted>'}, '
        'm3uUrl: ${m3uUrl == null ? null : '<redacted>'}, '
        'localFilePath: ${localFilePath == null ? null : '<redacted>'}, '
        'isEnabled: $isEnabled, '
        'refreshEnabled: $refreshEnabled, '
        'refreshIntervalMinutes: $refreshIntervalMinutes'
        ')';
  }
}

class ProviderRefreshSummary {
  const ProviderRefreshSummary({
    required this.providerId,
    required this.status,
    required this.itemCount,
    this.message,
    this.startedAt,
    this.finishedAt,
  });

  final String providerId;
  final ProviderRefreshStatus status;
  final int itemCount;
  final String? message;
  final DateTime? startedAt;
  final DateTime? finishedAt;
}

enum ProviderImportStage {
  validating,
  live,
  movies,
  series,
  epg,
  indexing,
  done,
  failed,
}

class ProviderImportProgress {
  const ProviderImportProgress({
    required this.stage,
    required this.message,
    this.current,
    this.total,
  });

  final ProviderImportStage stage;
  final String message;
  final int? current;
  final int? total;
}

typedef ProviderImportProgressCallback =
    void Function(ProviderImportProgress progress);

class ProviderRefreshFailure implements Exception {
  const ProviderRefreshFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

DateTime? dateTimeFromMs(int? value) {
  return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
}

int? msFromDateTime(DateTime? value) {
  return value?.millisecondsSinceEpoch;
}
