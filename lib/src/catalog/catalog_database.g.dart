// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_database.dart';

// ignore_for_file: type=lint
class $CatalogProvidersTable extends CatalogProviders
    with TableInfo<$CatalogProvidersTable, CatalogProviderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogProvidersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceKindMeta = const VerificationMeta(
    'sourceKind',
  );
  @override
  late final GeneratedColumn<String> sourceKind = GeneratedColumn<String>(
    'source_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SensitiveText?, String> username =
      GeneratedColumn<String>(
        'username',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SensitiveText?>(
        $CatalogProvidersTable.$converterusernamen,
      );
  @override
  late final GeneratedColumnWithTypeConverter<SensitiveText?, String> password =
      GeneratedColumn<String>(
        'password',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SensitiveText?>(
        $CatalogProvidersTable.$converterpasswordn,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _lastRefreshAtMeta = const VerificationMeta(
    'lastRefreshAt',
  );
  @override
  late final GeneratedColumn<int> lastRefreshAt = GeneratedColumn<int>(
    'last_refresh_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoRefreshEnabledMeta =
      const VerificationMeta('autoRefreshEnabled');
  @override
  late final GeneratedColumn<bool> autoRefreshEnabled = GeneratedColumn<bool>(
    'auto_refresh_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_refresh_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoRefreshIntervalMinutesMeta =
      const VerificationMeta('autoRefreshIntervalMinutes');
  @override
  late final GeneratedColumn<int> autoRefreshIntervalMinutes =
      GeneratedColumn<int>(
        'auto_refresh_interval_minutes',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1440),
      );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    name,
    source,
    sourceKind,
    username,
    password,
    createdAt,
    updatedAt,
    lastRefreshAt,
    autoRefreshEnabled,
    autoRefreshIntervalMinutes,
    isEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogProviderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_kind')) {
      context.handle(
        _sourceKindMeta,
        sourceKind.isAcceptableOrUnknown(data['source_kind']!, _sourceKindMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_refresh_at')) {
      context.handle(
        _lastRefreshAtMeta,
        lastRefreshAt.isAcceptableOrUnknown(
          data['last_refresh_at']!,
          _lastRefreshAtMeta,
        ),
      );
    }
    if (data.containsKey('auto_refresh_enabled')) {
      context.handle(
        _autoRefreshEnabledMeta,
        autoRefreshEnabled.isAcceptableOrUnknown(
          data['auto_refresh_enabled']!,
          _autoRefreshEnabledMeta,
        ),
      );
    }
    if (data.containsKey('auto_refresh_interval_minutes')) {
      context.handle(
        _autoRefreshIntervalMinutesMeta,
        autoRefreshIntervalMinutes.isAcceptableOrUnknown(
          data['auto_refresh_interval_minutes']!,
          _autoRefreshIntervalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogProviderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogProviderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_kind'],
      ),
      username: $CatalogProvidersTable.$converterusernamen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}username'],
        ),
      ),
      password: $CatalogProvidersTable.$converterpasswordn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}password'],
        ),
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastRefreshAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_refresh_at'],
      ),
      autoRefreshEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_refresh_enabled'],
      )!,
      autoRefreshIntervalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}auto_refresh_interval_minutes'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
    );
  }

  @override
  $CatalogProvidersTable createAlias(String alias) {
    return $CatalogProvidersTable(attachedDatabase, alias);
  }

  static TypeConverter<SensitiveText, String> $converterusername =
      const SensitiveTextConverter();
  static TypeConverter<SensitiveText?, String?> $converterusernamen =
      NullAwareTypeConverter.wrap($converterusername);
  static TypeConverter<SensitiveText, String> $converterpassword =
      const SensitiveTextConverter();
  static TypeConverter<SensitiveText?, String?> $converterpasswordn =
      NullAwareTypeConverter.wrap($converterpassword);
}

class CatalogProviderRow extends DataClass
    implements Insertable<CatalogProviderRow> {
  final String id;
  final String type;
  final String name;
  final String source;
  final String? sourceKind;
  final SensitiveText? username;
  final SensitiveText? password;
  final int createdAt;
  final int updatedAt;
  final int? lastRefreshAt;
  final bool autoRefreshEnabled;
  final int autoRefreshIntervalMinutes;
  final bool isEnabled;
  const CatalogProviderRow({
    required this.id,
    required this.type,
    required this.name,
    required this.source,
    this.sourceKind,
    this.username,
    this.password,
    required this.createdAt,
    required this.updatedAt,
    this.lastRefreshAt,
    required this.autoRefreshEnabled,
    required this.autoRefreshIntervalMinutes,
    required this.isEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceKind != null) {
      map['source_kind'] = Variable<String>(sourceKind);
    }
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(
        $CatalogProvidersTable.$converterusernamen.toSql(username),
      );
    }
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(
        $CatalogProvidersTable.$converterpasswordn.toSql(password),
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || lastRefreshAt != null) {
      map['last_refresh_at'] = Variable<int>(lastRefreshAt);
    }
    map['auto_refresh_enabled'] = Variable<bool>(autoRefreshEnabled);
    map['auto_refresh_interval_minutes'] = Variable<int>(
      autoRefreshIntervalMinutes,
    );
    map['is_enabled'] = Variable<bool>(isEnabled);
    return map;
  }

  CatalogProvidersCompanion toCompanion(bool nullToAbsent) {
    return CatalogProvidersCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      source: Value(source),
      sourceKind: sourceKind == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKind),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastRefreshAt: lastRefreshAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefreshAt),
      autoRefreshEnabled: Value(autoRefreshEnabled),
      autoRefreshIntervalMinutes: Value(autoRefreshIntervalMinutes),
      isEnabled: Value(isEnabled),
    );
  }

  factory CatalogProviderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogProviderRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      source: serializer.fromJson<String>(json['source']),
      sourceKind: serializer.fromJson<String?>(json['sourceKind']),
      username: serializer.fromJson<SensitiveText?>(json['username']),
      password: serializer.fromJson<SensitiveText?>(json['password']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastRefreshAt: serializer.fromJson<int?>(json['lastRefreshAt']),
      autoRefreshEnabled: serializer.fromJson<bool>(json['autoRefreshEnabled']),
      autoRefreshIntervalMinutes: serializer.fromJson<int>(
        json['autoRefreshIntervalMinutes'],
      ),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'source': serializer.toJson<String>(source),
      'sourceKind': serializer.toJson<String?>(sourceKind),
      'username': serializer.toJson<SensitiveText?>(username),
      'password': serializer.toJson<SensitiveText?>(password),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastRefreshAt': serializer.toJson<int?>(lastRefreshAt),
      'autoRefreshEnabled': serializer.toJson<bool>(autoRefreshEnabled),
      'autoRefreshIntervalMinutes': serializer.toJson<int>(
        autoRefreshIntervalMinutes,
      ),
      'isEnabled': serializer.toJson<bool>(isEnabled),
    };
  }

  CatalogProviderRow copyWith({
    String? id,
    String? type,
    String? name,
    String? source,
    Value<String?> sourceKind = const Value.absent(),
    Value<SensitiveText?> username = const Value.absent(),
    Value<SensitiveText?> password = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> lastRefreshAt = const Value.absent(),
    bool? autoRefreshEnabled,
    int? autoRefreshIntervalMinutes,
    bool? isEnabled,
  }) => CatalogProviderRow(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    source: source ?? this.source,
    sourceKind: sourceKind.present ? sourceKind.value : this.sourceKind,
    username: username.present ? username.value : this.username,
    password: password.present ? password.value : this.password,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastRefreshAt: lastRefreshAt.present
        ? lastRefreshAt.value
        : this.lastRefreshAt,
    autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
    autoRefreshIntervalMinutes:
        autoRefreshIntervalMinutes ?? this.autoRefreshIntervalMinutes,
    isEnabled: isEnabled ?? this.isEnabled,
  );
  CatalogProviderRow copyWithCompanion(CatalogProvidersCompanion data) {
    return CatalogProviderRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      source: data.source.present ? data.source.value : this.source,
      sourceKind: data.sourceKind.present
          ? data.sourceKind.value
          : this.sourceKind,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastRefreshAt: data.lastRefreshAt.present
          ? data.lastRefreshAt.value
          : this.lastRefreshAt,
      autoRefreshEnabled: data.autoRefreshEnabled.present
          ? data.autoRefreshEnabled.value
          : this.autoRefreshEnabled,
      autoRefreshIntervalMinutes: data.autoRefreshIntervalMinutes.present
          ? data.autoRefreshIntervalMinutes.value
          : this.autoRefreshIntervalMinutes,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogProviderRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastRefreshAt: $lastRefreshAt, ')
          ..write('autoRefreshEnabled: $autoRefreshEnabled, ')
          ..write('autoRefreshIntervalMinutes: $autoRefreshIntervalMinutes, ')
          ..write('isEnabled: $isEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    name,
    source,
    sourceKind,
    username,
    password,
    createdAt,
    updatedAt,
    lastRefreshAt,
    autoRefreshEnabled,
    autoRefreshIntervalMinutes,
    isEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogProviderRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.source == this.source &&
          other.sourceKind == this.sourceKind &&
          other.username == this.username &&
          other.password == this.password &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastRefreshAt == this.lastRefreshAt &&
          other.autoRefreshEnabled == this.autoRefreshEnabled &&
          other.autoRefreshIntervalMinutes == this.autoRefreshIntervalMinutes &&
          other.isEnabled == this.isEnabled);
}

class CatalogProvidersCompanion extends UpdateCompanion<CatalogProviderRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> name;
  final Value<String> source;
  final Value<String?> sourceKind;
  final Value<SensitiveText?> username;
  final Value<SensitiveText?> password;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> lastRefreshAt;
  final Value<bool> autoRefreshEnabled;
  final Value<int> autoRefreshIntervalMinutes;
  final Value<bool> isEnabled;
  final Value<int> rowid;
  const CatalogProvidersCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceKind = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastRefreshAt = const Value.absent(),
    this.autoRefreshEnabled = const Value.absent(),
    this.autoRefreshIntervalMinutes = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogProvidersCompanion.insert({
    required String id,
    required String type,
    required String name,
    required String source,
    this.sourceKind = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastRefreshAt = const Value.absent(),
    this.autoRefreshEnabled = const Value.absent(),
    this.autoRefreshIntervalMinutes = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       name = Value(name),
       source = Value(source);
  static Insertable<CatalogProviderRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? source,
    Expression<String>? sourceKind,
    Expression<String>? username,
    Expression<String>? password,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? lastRefreshAt,
    Expression<bool>? autoRefreshEnabled,
    Expression<int>? autoRefreshIntervalMinutes,
    Expression<bool>? isEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (source != null) 'source': source,
      if (sourceKind != null) 'source_kind': sourceKind,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastRefreshAt != null) 'last_refresh_at': lastRefreshAt,
      if (autoRefreshEnabled != null)
        'auto_refresh_enabled': autoRefreshEnabled,
      if (autoRefreshIntervalMinutes != null)
        'auto_refresh_interval_minutes': autoRefreshIntervalMinutes,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogProvidersCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? name,
    Value<String>? source,
    Value<String?>? sourceKind,
    Value<SensitiveText?>? username,
    Value<SensitiveText?>? password,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? lastRefreshAt,
    Value<bool>? autoRefreshEnabled,
    Value<int>? autoRefreshIntervalMinutes,
    Value<bool>? isEnabled,
    Value<int>? rowid,
  }) {
    return CatalogProvidersCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      source: source ?? this.source,
      sourceKind: sourceKind ?? this.sourceKind,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      autoRefreshIntervalMinutes:
          autoRefreshIntervalMinutes ?? this.autoRefreshIntervalMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceKind.present) {
      map['source_kind'] = Variable<String>(sourceKind.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(
        $CatalogProvidersTable.$converterusernamen.toSql(username.value),
      );
    }
    if (password.present) {
      map['password'] = Variable<String>(
        $CatalogProvidersTable.$converterpasswordn.toSql(password.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastRefreshAt.present) {
      map['last_refresh_at'] = Variable<int>(lastRefreshAt.value);
    }
    if (autoRefreshEnabled.present) {
      map['auto_refresh_enabled'] = Variable<bool>(autoRefreshEnabled.value);
    }
    if (autoRefreshIntervalMinutes.present) {
      map['auto_refresh_interval_minutes'] = Variable<int>(
        autoRefreshIntervalMinutes.value,
      );
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogProvidersCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('sourceKind: $sourceKind, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastRefreshAt: $lastRefreshAt, ')
          ..write('autoRefreshEnabled: $autoRefreshEnabled, ')
          ..write('autoRefreshIntervalMinutes: $autoRefreshIntervalMinutes, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderRefreshRunsTable extends ProviderRefreshRuns
    with TableInfo<$ProviderRefreshRunsTable, ProviderRefreshRunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderRefreshRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    status,
    startedAt,
    finishedAt,
    itemCount,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_refresh_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderRefreshRunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderRefreshRunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderRefreshRunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at'],
      ),
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $ProviderRefreshRunsTable createAlias(String alias) {
    return $ProviderRefreshRunsTable(attachedDatabase, alias);
  }
}

class ProviderRefreshRunRow extends DataClass
    implements Insertable<ProviderRefreshRunRow> {
  final String id;
  final String providerId;
  final String status;
  final int startedAt;
  final int? finishedAt;
  final int itemCount;
  final String? errorMessage;
  const ProviderRefreshRunRow({
    required this.id,
    required this.providerId,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    required this.itemCount,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    map['item_count'] = Variable<int>(itemCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  ProviderRefreshRunsCompanion toCompanion(bool nullToAbsent) {
    return ProviderRefreshRunsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      status: Value(status),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      itemCount: Value(itemCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory ProviderRefreshRunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderRefreshRunRow(
      id: serializer.fromJson<String>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerId': serializer.toJson<String>(providerId),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<int>(startedAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
      'itemCount': serializer.toJson<int>(itemCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  ProviderRefreshRunRow copyWith({
    String? id,
    String? providerId,
    String? status,
    int? startedAt,
    Value<int?> finishedAt = const Value.absent(),
    int? itemCount,
    Value<String?> errorMessage = const Value.absent(),
  }) => ProviderRefreshRunRow(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    itemCount: itemCount ?? this.itemCount,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  ProviderRefreshRunRow copyWithCompanion(ProviderRefreshRunsCompanion data) {
    return ProviderRefreshRunRow(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderRefreshRunRow(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('itemCount: $itemCount, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    status,
    startedAt,
    finishedAt,
    itemCount,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderRefreshRunRow &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.itemCount == this.itemCount &&
          other.errorMessage == this.errorMessage);
}

class ProviderRefreshRunsCompanion
    extends UpdateCompanion<ProviderRefreshRunRow> {
  final Value<String> id;
  final Value<String> providerId;
  final Value<String> status;
  final Value<int> startedAt;
  final Value<int?> finishedAt;
  final Value<int> itemCount;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const ProviderRefreshRunsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderRefreshRunsCompanion.insert({
    required String id,
    required String providerId,
    required String status,
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerId = Value(providerId),
       status = Value(status);
  static Insertable<ProviderRefreshRunRow> custom({
    Expression<String>? id,
    Expression<String>? providerId,
    Expression<String>? status,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<int>? itemCount,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (itemCount != null) 'item_count': itemCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderRefreshRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? providerId,
    Value<String>? status,
    Value<int>? startedAt,
    Value<int?>? finishedAt,
    Value<int>? itemCount,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return ProviderRefreshRunsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      itemCount: itemCount ?? this.itemCount,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderRefreshRunsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('itemCount: $itemCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _isStaleMeta = const VerificationMeta(
    'isStale',
  );
  @override
  late final GeneratedColumn<bool> isStale = GeneratedColumn<bool>(
    'is_stale',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_stale" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    contentType,
    externalId,
    name,
    normalizedName,
    itemCount,
    lastSeenAt,
    isStale,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('is_stale')) {
      context.handle(
        _isStaleMeta,
        isStale.isAcceptableOrUnknown(data['is_stale']!, _isStaleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, contentType, id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {providerId, contentType, normalizedName},
  ];
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      )!,
      isStale: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_stale'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String providerId;
  final String contentType;
  final String? externalId;
  final String name;
  final String normalizedName;
  final int itemCount;
  final int lastSeenAt;
  final bool isStale;
  const CategoryRow({
    required this.id,
    required this.providerId,
    required this.contentType,
    this.externalId,
    required this.name,
    required this.normalizedName,
    required this.itemCount,
    required this.lastSeenAt,
    required this.isStale,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['item_count'] = Variable<int>(itemCount);
    map['last_seen_at'] = Variable<int>(lastSeenAt);
    map['is_stale'] = Variable<bool>(isStale);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      providerId: Value(providerId),
      contentType: Value(contentType),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      name: Value(name),
      normalizedName: Value(normalizedName),
      itemCount: Value(itemCount),
      lastSeenAt: Value(lastSeenAt),
      isStale: Value(isStale),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      contentType: serializer.fromJson<String>(json['contentType']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      lastSeenAt: serializer.fromJson<int>(json['lastSeenAt']),
      isStale: serializer.fromJson<bool>(json['isStale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerId': serializer.toJson<String>(providerId),
      'contentType': serializer.toJson<String>(contentType),
      'externalId': serializer.toJson<String?>(externalId),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'itemCount': serializer.toJson<int>(itemCount),
      'lastSeenAt': serializer.toJson<int>(lastSeenAt),
      'isStale': serializer.toJson<bool>(isStale),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? providerId,
    String? contentType,
    Value<String?> externalId = const Value.absent(),
    String? name,
    String? normalizedName,
    int? itemCount,
    int? lastSeenAt,
    bool? isStale,
  }) => CategoryRow(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    contentType: contentType ?? this.contentType,
    externalId: externalId.present ? externalId.value : this.externalId,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    itemCount: itemCount ?? this.itemCount,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    isStale: isStale ?? this.isStale,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      isStale: data.isStale.present ? data.isStale.value : this.isStale,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('contentType: $contentType, ')
          ..write('externalId: $externalId, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('itemCount: $itemCount, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    contentType,
    externalId,
    name,
    normalizedName,
    itemCount,
    lastSeenAt,
    isStale,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.contentType == this.contentType &&
          other.externalId == this.externalId &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.itemCount == this.itemCount &&
          other.lastSeenAt == this.lastSeenAt &&
          other.isStale == this.isStale);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> providerId;
  final Value<String> contentType;
  final Value<String?> externalId;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<int> itemCount;
  final Value<int> lastSeenAt;
  final Value<bool> isStale;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.contentType = const Value.absent(),
    this.externalId = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String providerId,
    required String contentType,
    this.externalId = const Value.absent(),
    required String name,
    required String normalizedName,
    this.itemCount = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerId = Value(providerId),
       contentType = Value(contentType),
       name = Value(name),
       normalizedName = Value(normalizedName);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? providerId,
    Expression<String>? contentType,
    Expression<String>? externalId,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<int>? itemCount,
    Expression<int>? lastSeenAt,
    Expression<bool>? isStale,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (contentType != null) 'content_type': contentType,
      if (externalId != null) 'external_id': externalId,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (itemCount != null) 'item_count': itemCount,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (isStale != null) 'is_stale': isStale,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? providerId,
    Value<String>? contentType,
    Value<String?>? externalId,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<int>? itemCount,
    Value<int>? lastSeenAt,
    Value<bool>? isStale,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      contentType: contentType ?? this.contentType,
      externalId: externalId ?? this.externalId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      itemCount: itemCount ?? this.itemCount,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isStale: isStale ?? this.isStale,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (isStale.present) {
      map['is_stale'] = Variable<bool>(isStale.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('contentType: $contentType, ')
          ..write('externalId: $externalId, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('itemCount: $itemCount, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogItemsTable extends CatalogItems
    with TableInfo<$CatalogItemsTable, CatalogItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedTitleMeta = const VerificationMeta(
    'normalizedTitle',
  );
  @override
  late final GeneratedColumn<String> normalizedTitle = GeneratedColumn<String>(
    'normalized_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamUrlMeta = const VerificationMeta(
    'streamUrl',
  );
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
    'stream_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamJsonMeta = const VerificationMeta(
    'streamJson',
  );
  @override
  late final GeneratedColumn<String> streamJson = GeneratedColumn<String>(
    'stream_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgChannelIdMeta = const VerificationMeta(
    'epgChannelId',
  );
  @override
  late final GeneratedColumn<String> epgChannelId = GeneratedColumn<String>(
    'epg_channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _isStaleMeta = const VerificationMeta(
    'isStale',
  );
  @override
  late final GeneratedColumn<bool> isStale = GeneratedColumn<bool>(
    'is_stale',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_stale" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    contentType,
    categoryId,
    title,
    normalizedTitle,
    subtitle,
    description,
    artworkUrl,
    streamUrl,
    streamJson,
    externalId,
    year,
    rating,
    durationSeconds,
    epgChannelId,
    containerExtension,
    createdAt,
    updatedAt,
    lastSeenAt,
    isStale,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('normalized_title')) {
      context.handle(
        _normalizedTitleMeta,
        normalizedTitle.isAcceptableOrUnknown(
          data['normalized_title']!,
          _normalizedTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedTitleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('stream_url')) {
      context.handle(
        _streamUrlMeta,
        streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta),
      );
    }
    if (data.containsKey('stream_json')) {
      context.handle(
        _streamJsonMeta,
        streamJson.isAcceptableOrUnknown(data['stream_json']!, _streamJsonMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('epg_channel_id')) {
      context.handle(
        _epgChannelIdMeta,
        epgChannelId.isAcceptableOrUnknown(
          data['epg_channel_id']!,
          _epgChannelIdMeta,
        ),
      );
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('is_stale')) {
      context.handle(
        _isStaleMeta,
        isStale.isAcceptableOrUnknown(data['is_stale']!, _isStaleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, contentType, id};
  @override
  CatalogItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      normalizedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      streamUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_url'],
      ),
      streamJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_json'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      epgChannelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_channel_id'],
      ),
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      )!,
      isStale: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_stale'],
      )!,
    );
  }

  @override
  $CatalogItemsTable createAlias(String alias) {
    return $CatalogItemsTable(attachedDatabase, alias);
  }
}

class CatalogItemRow extends DataClass implements Insertable<CatalogItemRow> {
  final String id;
  final String providerId;
  final String contentType;
  final String? categoryId;
  final String title;
  final String normalizedTitle;
  final String? subtitle;
  final String? description;
  final String? artworkUrl;
  final String? streamUrl;
  final String? streamJson;
  final String? externalId;
  final int? year;
  final String? rating;
  final int? durationSeconds;
  final String? epgChannelId;
  final String? containerExtension;
  final int createdAt;
  final int updatedAt;
  final int lastSeenAt;
  final bool isStale;
  const CatalogItemRow({
    required this.id,
    required this.providerId,
    required this.contentType,
    this.categoryId,
    required this.title,
    required this.normalizedTitle,
    this.subtitle,
    this.description,
    this.artworkUrl,
    this.streamUrl,
    this.streamJson,
    this.externalId,
    this.year,
    this.rating,
    this.durationSeconds,
    this.epgChannelId,
    this.containerExtension,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
    required this.isStale,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['title'] = Variable<String>(title);
    map['normalized_title'] = Variable<String>(normalizedTitle);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    if (!nullToAbsent || streamUrl != null) {
      map['stream_url'] = Variable<String>(streamUrl);
    }
    if (!nullToAbsent || streamJson != null) {
      map['stream_json'] = Variable<String>(streamJson);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<String>(rating);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    if (!nullToAbsent || epgChannelId != null) {
      map['epg_channel_id'] = Variable<String>(epgChannelId);
    }
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['last_seen_at'] = Variable<int>(lastSeenAt);
    map['is_stale'] = Variable<bool>(isStale);
    return map;
  }

  CatalogItemsCompanion toCompanion(bool nullToAbsent) {
    return CatalogItemsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      contentType: Value(contentType),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      title: Value(title),
      normalizedTitle: Value(normalizedTitle),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      streamUrl: streamUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(streamUrl),
      streamJson: streamJson == null && nullToAbsent
          ? const Value.absent()
          : Value(streamJson),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      epgChannelId: epgChannelId == null && nullToAbsent
          ? const Value.absent()
          : Value(epgChannelId),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSeenAt: Value(lastSeenAt),
      isStale: Value(isStale),
    );
  }

  factory CatalogItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogItemRow(
      id: serializer.fromJson<String>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      contentType: serializer.fromJson<String>(json['contentType']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      title: serializer.fromJson<String>(json['title']),
      normalizedTitle: serializer.fromJson<String>(json['normalizedTitle']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      description: serializer.fromJson<String?>(json['description']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      streamUrl: serializer.fromJson<String?>(json['streamUrl']),
      streamJson: serializer.fromJson<String?>(json['streamJson']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      year: serializer.fromJson<int?>(json['year']),
      rating: serializer.fromJson<String?>(json['rating']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      epgChannelId: serializer.fromJson<String?>(json['epgChannelId']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastSeenAt: serializer.fromJson<int>(json['lastSeenAt']),
      isStale: serializer.fromJson<bool>(json['isStale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerId': serializer.toJson<String>(providerId),
      'contentType': serializer.toJson<String>(contentType),
      'categoryId': serializer.toJson<String?>(categoryId),
      'title': serializer.toJson<String>(title),
      'normalizedTitle': serializer.toJson<String>(normalizedTitle),
      'subtitle': serializer.toJson<String?>(subtitle),
      'description': serializer.toJson<String?>(description),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'streamUrl': serializer.toJson<String?>(streamUrl),
      'streamJson': serializer.toJson<String?>(streamJson),
      'externalId': serializer.toJson<String?>(externalId),
      'year': serializer.toJson<int?>(year),
      'rating': serializer.toJson<String?>(rating),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'epgChannelId': serializer.toJson<String?>(epgChannelId),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastSeenAt': serializer.toJson<int>(lastSeenAt),
      'isStale': serializer.toJson<bool>(isStale),
    };
  }

  CatalogItemRow copyWith({
    String? id,
    String? providerId,
    String? contentType,
    Value<String?> categoryId = const Value.absent(),
    String? title,
    String? normalizedTitle,
    Value<String?> subtitle = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    Value<String?> streamUrl = const Value.absent(),
    Value<String?> streamJson = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> rating = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    Value<String?> epgChannelId = const Value.absent(),
    Value<String?> containerExtension = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    int? lastSeenAt,
    bool? isStale,
  }) => CatalogItemRow(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    contentType: contentType ?? this.contentType,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    title: title ?? this.title,
    normalizedTitle: normalizedTitle ?? this.normalizedTitle,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    description: description.present ? description.value : this.description,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    streamUrl: streamUrl.present ? streamUrl.value : this.streamUrl,
    streamJson: streamJson.present ? streamJson.value : this.streamJson,
    externalId: externalId.present ? externalId.value : this.externalId,
    year: year.present ? year.value : this.year,
    rating: rating.present ? rating.value : this.rating,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    epgChannelId: epgChannelId.present ? epgChannelId.value : this.epgChannelId,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    isStale: isStale ?? this.isStale,
  );
  CatalogItemRow copyWithCompanion(CatalogItemsCompanion data) {
    return CatalogItemRow(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      title: data.title.present ? data.title.value : this.title,
      normalizedTitle: data.normalizedTitle.present
          ? data.normalizedTitle.value
          : this.normalizedTitle,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      description: data.description.present
          ? data.description.value
          : this.description,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      streamJson: data.streamJson.present
          ? data.streamJson.value
          : this.streamJson,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      year: data.year.present ? data.year.value : this.year,
      rating: data.rating.present ? data.rating.value : this.rating,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      epgChannelId: data.epgChannelId.present
          ? data.epgChannelId.value
          : this.epgChannelId,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      isStale: data.isStale.present ? data.isStale.value : this.isStale,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogItemRow(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('contentType: $contentType, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('streamJson: $streamJson, ')
          ..write('externalId: $externalId, ')
          ..write('year: $year, ')
          ..write('rating: $rating, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    providerId,
    contentType,
    categoryId,
    title,
    normalizedTitle,
    subtitle,
    description,
    artworkUrl,
    streamUrl,
    streamJson,
    externalId,
    year,
    rating,
    durationSeconds,
    epgChannelId,
    containerExtension,
    createdAt,
    updatedAt,
    lastSeenAt,
    isStale,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogItemRow &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.contentType == this.contentType &&
          other.categoryId == this.categoryId &&
          other.title == this.title &&
          other.normalizedTitle == this.normalizedTitle &&
          other.subtitle == this.subtitle &&
          other.description == this.description &&
          other.artworkUrl == this.artworkUrl &&
          other.streamUrl == this.streamUrl &&
          other.streamJson == this.streamJson &&
          other.externalId == this.externalId &&
          other.year == this.year &&
          other.rating == this.rating &&
          other.durationSeconds == this.durationSeconds &&
          other.epgChannelId == this.epgChannelId &&
          other.containerExtension == this.containerExtension &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.isStale == this.isStale);
}

class CatalogItemsCompanion extends UpdateCompanion<CatalogItemRow> {
  final Value<String> id;
  final Value<String> providerId;
  final Value<String> contentType;
  final Value<String?> categoryId;
  final Value<String> title;
  final Value<String> normalizedTitle;
  final Value<String?> subtitle;
  final Value<String?> description;
  final Value<String?> artworkUrl;
  final Value<String?> streamUrl;
  final Value<String?> streamJson;
  final Value<String?> externalId;
  final Value<int?> year;
  final Value<String?> rating;
  final Value<int?> durationSeconds;
  final Value<String?> epgChannelId;
  final Value<String?> containerExtension;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> lastSeenAt;
  final Value<bool> isStale;
  final Value<int> rowid;
  const CatalogItemsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.contentType = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.normalizedTitle = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.streamJson = const Value.absent(),
    this.externalId = const Value.absent(),
    this.year = const Value.absent(),
    this.rating = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogItemsCompanion.insert({
    required String id,
    required String providerId,
    required String contentType,
    this.categoryId = const Value.absent(),
    required String title,
    required String normalizedTitle,
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.streamJson = const Value.absent(),
    this.externalId = const Value.absent(),
    this.year = const Value.absent(),
    this.rating = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerId = Value(providerId),
       contentType = Value(contentType),
       title = Value(title),
       normalizedTitle = Value(normalizedTitle);
  static Insertable<CatalogItemRow> custom({
    Expression<String>? id,
    Expression<String>? providerId,
    Expression<String>? contentType,
    Expression<String>? categoryId,
    Expression<String>? title,
    Expression<String>? normalizedTitle,
    Expression<String>? subtitle,
    Expression<String>? description,
    Expression<String>? artworkUrl,
    Expression<String>? streamUrl,
    Expression<String>? streamJson,
    Expression<String>? externalId,
    Expression<int>? year,
    Expression<String>? rating,
    Expression<int>? durationSeconds,
    Expression<String>? epgChannelId,
    Expression<String>? containerExtension,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? lastSeenAt,
    Expression<bool>? isStale,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (contentType != null) 'content_type': contentType,
      if (categoryId != null) 'category_id': categoryId,
      if (title != null) 'title': title,
      if (normalizedTitle != null) 'normalized_title': normalizedTitle,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (streamJson != null) 'stream_json': streamJson,
      if (externalId != null) 'external_id': externalId,
      if (year != null) 'year': year,
      if (rating != null) 'rating': rating,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (epgChannelId != null) 'epg_channel_id': epgChannelId,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (isStale != null) 'is_stale': isStale,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? providerId,
    Value<String>? contentType,
    Value<String?>? categoryId,
    Value<String>? title,
    Value<String>? normalizedTitle,
    Value<String?>? subtitle,
    Value<String?>? description,
    Value<String?>? artworkUrl,
    Value<String?>? streamUrl,
    Value<String?>? streamJson,
    Value<String?>? externalId,
    Value<int?>? year,
    Value<String?>? rating,
    Value<int?>? durationSeconds,
    Value<String?>? epgChannelId,
    Value<String?>? containerExtension,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? lastSeenAt,
    Value<bool>? isStale,
    Value<int>? rowid,
  }) {
    return CatalogItemsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      contentType: contentType ?? this.contentType,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      normalizedTitle: normalizedTitle ?? this.normalizedTitle,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      streamJson: streamJson ?? this.streamJson,
      externalId: externalId ?? this.externalId,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      containerExtension: containerExtension ?? this.containerExtension,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isStale: isStale ?? this.isStale,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (normalizedTitle.present) {
      map['normalized_title'] = Variable<String>(normalizedTitle.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (streamJson.present) {
      map['stream_json'] = Variable<String>(streamJson.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (epgChannelId.present) {
      map['epg_channel_id'] = Variable<String>(epgChannelId.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (isStale.present) {
      map['is_stale'] = Variable<bool>(isStale.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogItemsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('contentType: $contentType, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('streamJson: $streamJson, ')
          ..write('externalId: $externalId, ')
          ..write('year: $year, ')
          ..write('rating: $rating, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesTable extends Series with TableInfo<$SeriesTable, SeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _catalogItemIdMeta = const VerificationMeta(
    'catalogItemId',
  );
  @override
  late final GeneratedColumn<String> catalogItemId = GeneratedColumn<String>(
    'catalog_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedTitleMeta = const VerificationMeta(
    'normalizedTitle',
  );
  @override
  late final GeneratedColumn<String> normalizedTitle = GeneratedColumn<String>(
    'normalized_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta(
    'posterUrl',
  );
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropUrlMeta = const VerificationMeta(
    'backdropUrl',
  );
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
    'backdrop_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _isStaleMeta = const VerificationMeta(
    'isStale',
  );
  @override
  late final GeneratedColumn<bool> isStale = GeneratedColumn<bool>(
    'is_stale',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_stale" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    catalogItemId,
    externalId,
    title,
    normalizedTitle,
    overview,
    posterUrl,
    backdropUrl,
    updatedAt,
    lastSeenAt,
    isStale,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('catalog_item_id')) {
      context.handle(
        _catalogItemIdMeta,
        catalogItemId.isAcceptableOrUnknown(
          data['catalog_item_id']!,
          _catalogItemIdMeta,
        ),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('normalized_title')) {
      context.handle(
        _normalizedTitleMeta,
        normalizedTitle.isAcceptableOrUnknown(
          data['normalized_title']!,
          _normalizedTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedTitleMeta);
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('poster_url')) {
      context.handle(
        _posterUrlMeta,
        posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta),
      );
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(
        _backdropUrlMeta,
        backdropUrl.isAcceptableOrUnknown(
          data['backdrop_url']!,
          _backdropUrlMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('is_stale')) {
      context.handle(
        _isStaleMeta,
        isStale.isAcceptableOrUnknown(data['is_stale']!, _isStaleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {providerId, catalogItemId},
  ];
  @override
  SeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      catalogItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_item_id'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      normalizedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_title'],
      )!,
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      posterUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_url'],
      ),
      backdropUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop_url'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      )!,
      isStale: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_stale'],
      )!,
    );
  }

  @override
  $SeriesTable createAlias(String alias) {
    return $SeriesTable(attachedDatabase, alias);
  }
}

class SeriesRow extends DataClass implements Insertable<SeriesRow> {
  final String id;
  final String providerId;
  final String? catalogItemId;
  final String? externalId;
  final String title;
  final String normalizedTitle;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final int updatedAt;
  final int lastSeenAt;
  final bool isStale;
  const SeriesRow({
    required this.id,
    required this.providerId,
    this.catalogItemId,
    this.externalId,
    required this.title,
    required this.normalizedTitle,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    required this.updatedAt,
    required this.lastSeenAt,
    required this.isStale,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_id'] = Variable<String>(providerId);
    if (!nullToAbsent || catalogItemId != null) {
      map['catalog_item_id'] = Variable<String>(catalogItemId);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    map['title'] = Variable<String>(title);
    map['normalized_title'] = Variable<String>(normalizedTitle);
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    if (!nullToAbsent || backdropUrl != null) {
      map['backdrop_url'] = Variable<String>(backdropUrl);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['last_seen_at'] = Variable<int>(lastSeenAt);
    map['is_stale'] = Variable<bool>(isStale);
    return map;
  }

  SeriesCompanion toCompanion(bool nullToAbsent) {
    return SeriesCompanion(
      id: Value(id),
      providerId: Value(providerId),
      catalogItemId: catalogItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogItemId),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      title: Value(title),
      normalizedTitle: Value(normalizedTitle),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      backdropUrl: backdropUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(backdropUrl),
      updatedAt: Value(updatedAt),
      lastSeenAt: Value(lastSeenAt),
      isStale: Value(isStale),
    );
  }

  factory SeriesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRow(
      id: serializer.fromJson<String>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      catalogItemId: serializer.fromJson<String?>(json['catalogItemId']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      title: serializer.fromJson<String>(json['title']),
      normalizedTitle: serializer.fromJson<String>(json['normalizedTitle']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      backdropUrl: serializer.fromJson<String?>(json['backdropUrl']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastSeenAt: serializer.fromJson<int>(json['lastSeenAt']),
      isStale: serializer.fromJson<bool>(json['isStale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerId': serializer.toJson<String>(providerId),
      'catalogItemId': serializer.toJson<String?>(catalogItemId),
      'externalId': serializer.toJson<String?>(externalId),
      'title': serializer.toJson<String>(title),
      'normalizedTitle': serializer.toJson<String>(normalizedTitle),
      'overview': serializer.toJson<String?>(overview),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'backdropUrl': serializer.toJson<String?>(backdropUrl),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastSeenAt': serializer.toJson<int>(lastSeenAt),
      'isStale': serializer.toJson<bool>(isStale),
    };
  }

  SeriesRow copyWith({
    String? id,
    String? providerId,
    Value<String?> catalogItemId = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    String? title,
    String? normalizedTitle,
    Value<String?> overview = const Value.absent(),
    Value<String?> posterUrl = const Value.absent(),
    Value<String?> backdropUrl = const Value.absent(),
    int? updatedAt,
    int? lastSeenAt,
    bool? isStale,
  }) => SeriesRow(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    catalogItemId: catalogItemId.present
        ? catalogItemId.value
        : this.catalogItemId,
    externalId: externalId.present ? externalId.value : this.externalId,
    title: title ?? this.title,
    normalizedTitle: normalizedTitle ?? this.normalizedTitle,
    overview: overview.present ? overview.value : this.overview,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    backdropUrl: backdropUrl.present ? backdropUrl.value : this.backdropUrl,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    isStale: isStale ?? this.isStale,
  );
  SeriesRow copyWithCompanion(SeriesCompanion data) {
    return SeriesRow(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      catalogItemId: data.catalogItemId.present
          ? data.catalogItemId.value
          : this.catalogItemId,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      title: data.title.present ? data.title.value : this.title,
      normalizedTitle: data.normalizedTitle.present
          ? data.normalizedTitle.value
          : this.normalizedTitle,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      backdropUrl: data.backdropUrl.present
          ? data.backdropUrl.value
          : this.backdropUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      isStale: data.isStale.present ? data.isStale.value : this.isStale,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRow(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('catalogItemId: $catalogItemId, ')
          ..write('externalId: $externalId, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('overview: $overview, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    catalogItemId,
    externalId,
    title,
    normalizedTitle,
    overview,
    posterUrl,
    backdropUrl,
    updatedAt,
    lastSeenAt,
    isStale,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRow &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.catalogItemId == this.catalogItemId &&
          other.externalId == this.externalId &&
          other.title == this.title &&
          other.normalizedTitle == this.normalizedTitle &&
          other.overview == this.overview &&
          other.posterUrl == this.posterUrl &&
          other.backdropUrl == this.backdropUrl &&
          other.updatedAt == this.updatedAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.isStale == this.isStale);
}

class SeriesCompanion extends UpdateCompanion<SeriesRow> {
  final Value<String> id;
  final Value<String> providerId;
  final Value<String?> catalogItemId;
  final Value<String?> externalId;
  final Value<String> title;
  final Value<String> normalizedTitle;
  final Value<String?> overview;
  final Value<String?> posterUrl;
  final Value<String?> backdropUrl;
  final Value<int> updatedAt;
  final Value<int> lastSeenAt;
  final Value<bool> isStale;
  final Value<int> rowid;
  const SeriesCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.catalogItemId = const Value.absent(),
    this.externalId = const Value.absent(),
    this.title = const Value.absent(),
    this.normalizedTitle = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesCompanion.insert({
    required String id,
    required String providerId,
    this.catalogItemId = const Value.absent(),
    this.externalId = const Value.absent(),
    required String title,
    required String normalizedTitle,
    this.overview = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerId = Value(providerId),
       title = Value(title),
       normalizedTitle = Value(normalizedTitle);
  static Insertable<SeriesRow> custom({
    Expression<String>? id,
    Expression<String>? providerId,
    Expression<String>? catalogItemId,
    Expression<String>? externalId,
    Expression<String>? title,
    Expression<String>? normalizedTitle,
    Expression<String>? overview,
    Expression<String>? posterUrl,
    Expression<String>? backdropUrl,
    Expression<int>? updatedAt,
    Expression<int>? lastSeenAt,
    Expression<bool>? isStale,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (catalogItemId != null) 'catalog_item_id': catalogItemId,
      if (externalId != null) 'external_id': externalId,
      if (title != null) 'title': title,
      if (normalizedTitle != null) 'normalized_title': normalizedTitle,
      if (overview != null) 'overview': overview,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (isStale != null) 'is_stale': isStale,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesCompanion copyWith({
    Value<String>? id,
    Value<String>? providerId,
    Value<String?>? catalogItemId,
    Value<String?>? externalId,
    Value<String>? title,
    Value<String>? normalizedTitle,
    Value<String?>? overview,
    Value<String?>? posterUrl,
    Value<String?>? backdropUrl,
    Value<int>? updatedAt,
    Value<int>? lastSeenAt,
    Value<bool>? isStale,
    Value<int>? rowid,
  }) {
    return SeriesCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      externalId: externalId ?? this.externalId,
      title: title ?? this.title,
      normalizedTitle: normalizedTitle ?? this.normalizedTitle,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isStale: isStale ?? this.isStale,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (catalogItemId.present) {
      map['catalog_item_id'] = Variable<String>(catalogItemId.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (normalizedTitle.present) {
      map['normalized_title'] = Variable<String>(normalizedTitle.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (isStale.present) {
      map['is_stale'] = Variable<bool>(isStale.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('catalogItemId: $catalogItemId, ')
          ..write('externalId: $externalId, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('overview: $overview, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeasonsTable extends Seasons with TableInfo<$SeasonsTable, SeasonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta(
    'posterUrl',
  );
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _isStaleMeta = const VerificationMeta(
    'isStale',
  );
  @override
  late final GeneratedColumn<bool> isStale = GeneratedColumn<bool>(
    'is_stale',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_stale" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    seriesId,
    seasonNumber,
    title,
    overview,
    posterUrl,
    updatedAt,
    lastSeenAt,
    isStale,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasons';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeasonRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('poster_url')) {
      context.handle(
        _posterUrlMeta,
        posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('is_stale')) {
      context.handle(
        _isStaleMeta,
        isStale.isAcceptableOrUnknown(data['is_stale']!, _isStaleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, seriesId, id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {providerId, seriesId, seasonNumber},
  ];
  @override
  SeasonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeasonRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      posterUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_url'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      )!,
      isStale: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_stale'],
      )!,
    );
  }

  @override
  $SeasonsTable createAlias(String alias) {
    return $SeasonsTable(attachedDatabase, alias);
  }
}

class SeasonRow extends DataClass implements Insertable<SeasonRow> {
  final String id;
  final String providerId;
  final String seriesId;
  final int seasonNumber;
  final String? title;
  final String? overview;
  final String? posterUrl;
  final int updatedAt;
  final int lastSeenAt;
  final bool isStale;
  const SeasonRow({
    required this.id,
    required this.providerId,
    required this.seriesId,
    required this.seasonNumber,
    this.title,
    this.overview,
    this.posterUrl,
    required this.updatedAt,
    required this.lastSeenAt,
    required this.isStale,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['series_id'] = Variable<String>(seriesId);
    map['season_number'] = Variable<int>(seasonNumber);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['last_seen_at'] = Variable<int>(lastSeenAt);
    map['is_stale'] = Variable<bool>(isStale);
    return map;
  }

  SeasonsCompanion toCompanion(bool nullToAbsent) {
    return SeasonsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      seriesId: Value(seriesId),
      seasonNumber: Value(seasonNumber),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      updatedAt: Value(updatedAt),
      lastSeenAt: Value(lastSeenAt),
      isStale: Value(isStale),
    );
  }

  factory SeasonRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeasonRow(
      id: serializer.fromJson<String>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      title: serializer.fromJson<String?>(json['title']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastSeenAt: serializer.fromJson<int>(json['lastSeenAt']),
      isStale: serializer.fromJson<bool>(json['isStale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerId': serializer.toJson<String>(providerId),
      'seriesId': serializer.toJson<String>(seriesId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'title': serializer.toJson<String?>(title),
      'overview': serializer.toJson<String?>(overview),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastSeenAt': serializer.toJson<int>(lastSeenAt),
      'isStale': serializer.toJson<bool>(isStale),
    };
  }

  SeasonRow copyWith({
    String? id,
    String? providerId,
    String? seriesId,
    int? seasonNumber,
    Value<String?> title = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> posterUrl = const Value.absent(),
    int? updatedAt,
    int? lastSeenAt,
    bool? isStale,
  }) => SeasonRow(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    seriesId: seriesId ?? this.seriesId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    title: title.present ? title.value : this.title,
    overview: overview.present ? overview.value : this.overview,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    isStale: isStale ?? this.isStale,
  );
  SeasonRow copyWithCompanion(SeasonsCompanion data) {
    return SeasonRow(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      title: data.title.present ? data.title.value : this.title,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      isStale: data.isStale.present ? data.isStale.value : this.isStale,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeasonRow(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    seriesId,
    seasonNumber,
    title,
    overview,
    posterUrl,
    updatedAt,
    lastSeenAt,
    isStale,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeasonRow &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.seriesId == this.seriesId &&
          other.seasonNumber == this.seasonNumber &&
          other.title == this.title &&
          other.overview == this.overview &&
          other.posterUrl == this.posterUrl &&
          other.updatedAt == this.updatedAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.isStale == this.isStale);
}

class SeasonsCompanion extends UpdateCompanion<SeasonRow> {
  final Value<String> id;
  final Value<String> providerId;
  final Value<String> seriesId;
  final Value<int> seasonNumber;
  final Value<String?> title;
  final Value<String?> overview;
  final Value<String?> posterUrl;
  final Value<int> updatedAt;
  final Value<int> lastSeenAt;
  final Value<bool> isStale;
  final Value<int> rowid;
  const SeasonsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeasonsCompanion.insert({
    required String id,
    required String providerId,
    required String seriesId,
    required int seasonNumber,
    this.title = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerId = Value(providerId),
       seriesId = Value(seriesId),
       seasonNumber = Value(seasonNumber);
  static Insertable<SeasonRow> custom({
    Expression<String>? id,
    Expression<String>? providerId,
    Expression<String>? seriesId,
    Expression<int>? seasonNumber,
    Expression<String>? title,
    Expression<String>? overview,
    Expression<String>? posterUrl,
    Expression<int>? updatedAt,
    Expression<int>? lastSeenAt,
    Expression<bool>? isStale,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (title != null) 'title': title,
      if (overview != null) 'overview': overview,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (isStale != null) 'is_stale': isStale,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeasonsCompanion copyWith({
    Value<String>? id,
    Value<String>? providerId,
    Value<String>? seriesId,
    Value<int>? seasonNumber,
    Value<String?>? title,
    Value<String?>? overview,
    Value<String?>? posterUrl,
    Value<int>? updatedAt,
    Value<int>? lastSeenAt,
    Value<bool>? isStale,
    Value<int>? rowid,
  }) {
    return SeasonsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      seriesId: seriesId ?? this.seriesId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isStale: isStale ?? this.isStale,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (isStale.present) {
      map['is_stale'] = Variable<bool>(isStale.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes
    with TableInfo<$EpisodesTable, EpisodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedTitleMeta = const VerificationMeta(
    'normalizedTitle',
  );
  @override
  late final GeneratedColumn<String> normalizedTitle = GeneratedColumn<String>(
    'normalized_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamUrlMeta = const VerificationMeta(
    'streamUrl',
  );
  @override
  late final GeneratedColumn<String> streamUrl = GeneratedColumn<String>(
    'stream_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streamJsonMeta = const VerificationMeta(
    'streamJson',
  );
  @override
  late final GeneratedColumn<String> streamJson = GeneratedColumn<String>(
    'stream_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<int> lastSeenAt = GeneratedColumn<int>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _isStaleMeta = const VerificationMeta(
    'isStale',
  );
  @override
  late final GeneratedColumn<bool> isStale = GeneratedColumn<bool>(
    'is_stale',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_stale" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    seriesId,
    seasonId,
    seasonNumber,
    episodeNumber,
    title,
    normalizedTitle,
    description,
    artworkUrl,
    streamUrl,
    streamJson,
    externalId,
    durationSeconds,
    createdAt,
    updatedAt,
    lastSeenAt,
    isStale,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('normalized_title')) {
      context.handle(
        _normalizedTitleMeta,
        normalizedTitle.isAcceptableOrUnknown(
          data['normalized_title']!,
          _normalizedTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedTitleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('stream_url')) {
      context.handle(
        _streamUrlMeta,
        streamUrl.isAcceptableOrUnknown(data['stream_url']!, _streamUrlMeta),
      );
    }
    if (data.containsKey('stream_json')) {
      context.handle(
        _streamJsonMeta,
        streamJson.isAcceptableOrUnknown(data['stream_json']!, _streamJsonMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    if (data.containsKey('is_stale')) {
      context.handle(
        _isStaleMeta,
        isStale.isAcceptableOrUnknown(data['is_stale']!, _isStaleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, seriesId, seasonId, id};
  @override
  EpisodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      normalizedTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      streamUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_url'],
      ),
      streamJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_json'],
      ),
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at'],
      )!,
      isStale: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_stale'],
      )!,
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class EpisodeRow extends DataClass implements Insertable<EpisodeRow> {
  final String id;
  final String providerId;
  final String seriesId;
  final String seasonId;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String normalizedTitle;
  final String? description;
  final String? artworkUrl;
  final String? streamUrl;
  final String? streamJson;
  final String? externalId;
  final int? durationSeconds;
  final int createdAt;
  final int updatedAt;
  final int lastSeenAt;
  final bool isStale;
  const EpisodeRow({
    required this.id,
    required this.providerId,
    required this.seriesId,
    required this.seasonId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.normalizedTitle,
    this.description,
    this.artworkUrl,
    this.streamUrl,
    this.streamJson,
    this.externalId,
    this.durationSeconds,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
    required this.isStale,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['series_id'] = Variable<String>(seriesId);
    map['season_id'] = Variable<String>(seasonId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['title'] = Variable<String>(title);
    map['normalized_title'] = Variable<String>(normalizedTitle);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    if (!nullToAbsent || streamUrl != null) {
      map['stream_url'] = Variable<String>(streamUrl);
    }
    if (!nullToAbsent || streamJson != null) {
      map['stream_json'] = Variable<String>(streamJson);
    }
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['last_seen_at'] = Variable<int>(lastSeenAt);
    map['is_stale'] = Variable<bool>(isStale);
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      providerId: Value(providerId),
      seriesId: Value(seriesId),
      seasonId: Value(seasonId),
      seasonNumber: Value(seasonNumber),
      episodeNumber: Value(episodeNumber),
      title: Value(title),
      normalizedTitle: Value(normalizedTitle),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      streamUrl: streamUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(streamUrl),
      streamJson: streamJson == null && nullToAbsent
          ? const Value.absent()
          : Value(streamJson),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastSeenAt: Value(lastSeenAt),
      isStale: Value(isStale),
    );
  }

  factory EpisodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeRow(
      id: serializer.fromJson<String>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      seasonId: serializer.fromJson<String>(json['seasonId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      title: serializer.fromJson<String>(json['title']),
      normalizedTitle: serializer.fromJson<String>(json['normalizedTitle']),
      description: serializer.fromJson<String?>(json['description']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      streamUrl: serializer.fromJson<String?>(json['streamUrl']),
      streamJson: serializer.fromJson<String?>(json['streamJson']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastSeenAt: serializer.fromJson<int>(json['lastSeenAt']),
      isStale: serializer.fromJson<bool>(json['isStale']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerId': serializer.toJson<String>(providerId),
      'seriesId': serializer.toJson<String>(seriesId),
      'seasonId': serializer.toJson<String>(seasonId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'title': serializer.toJson<String>(title),
      'normalizedTitle': serializer.toJson<String>(normalizedTitle),
      'description': serializer.toJson<String?>(description),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'streamUrl': serializer.toJson<String?>(streamUrl),
      'streamJson': serializer.toJson<String?>(streamJson),
      'externalId': serializer.toJson<String?>(externalId),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastSeenAt': serializer.toJson<int>(lastSeenAt),
      'isStale': serializer.toJson<bool>(isStale),
    };
  }

  EpisodeRow copyWith({
    String? id,
    String? providerId,
    String? seriesId,
    String? seasonId,
    int? seasonNumber,
    int? episodeNumber,
    String? title,
    String? normalizedTitle,
    Value<String?> description = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    Value<String?> streamUrl = const Value.absent(),
    Value<String?> streamJson = const Value.absent(),
    Value<String?> externalId = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    int? lastSeenAt,
    bool? isStale,
  }) => EpisodeRow(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    seriesId: seriesId ?? this.seriesId,
    seasonId: seasonId ?? this.seasonId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    episodeNumber: episodeNumber ?? this.episodeNumber,
    title: title ?? this.title,
    normalizedTitle: normalizedTitle ?? this.normalizedTitle,
    description: description.present ? description.value : this.description,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    streamUrl: streamUrl.present ? streamUrl.value : this.streamUrl,
    streamJson: streamJson.present ? streamJson.value : this.streamJson,
    externalId: externalId.present ? externalId.value : this.externalId,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    isStale: isStale ?? this.isStale,
  );
  EpisodeRow copyWithCompanion(EpisodesCompanion data) {
    return EpisodeRow(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      title: data.title.present ? data.title.value : this.title,
      normalizedTitle: data.normalizedTitle.present
          ? data.normalizedTitle.value
          : this.normalizedTitle,
      description: data.description.present
          ? data.description.value
          : this.description,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      streamUrl: data.streamUrl.present ? data.streamUrl.value : this.streamUrl,
      streamJson: data.streamJson.present
          ? data.streamJson.value
          : this.streamJson,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      isStale: data.isStale.present ? data.isStale.value : this.isStale,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeRow(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('description: $description, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('streamJson: $streamJson, ')
          ..write('externalId: $externalId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    seriesId,
    seasonId,
    seasonNumber,
    episodeNumber,
    title,
    normalizedTitle,
    description,
    artworkUrl,
    streamUrl,
    streamJson,
    externalId,
    durationSeconds,
    createdAt,
    updatedAt,
    lastSeenAt,
    isStale,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeRow &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.seriesId == this.seriesId &&
          other.seasonId == this.seasonId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.title == this.title &&
          other.normalizedTitle == this.normalizedTitle &&
          other.description == this.description &&
          other.artworkUrl == this.artworkUrl &&
          other.streamUrl == this.streamUrl &&
          other.streamJson == this.streamJson &&
          other.externalId == this.externalId &&
          other.durationSeconds == this.durationSeconds &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.isStale == this.isStale);
}

class EpisodesCompanion extends UpdateCompanion<EpisodeRow> {
  final Value<String> id;
  final Value<String> providerId;
  final Value<String> seriesId;
  final Value<String> seasonId;
  final Value<int> seasonNumber;
  final Value<int> episodeNumber;
  final Value<String> title;
  final Value<String> normalizedTitle;
  final Value<String?> description;
  final Value<String?> artworkUrl;
  final Value<String?> streamUrl;
  final Value<String?> streamJson;
  final Value<String?> externalId;
  final Value<int?> durationSeconds;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> lastSeenAt;
  final Value<bool> isStale;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.normalizedTitle = const Value.absent(),
    this.description = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.streamJson = const Value.absent(),
    this.externalId = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required String id,
    required String providerId,
    required String seriesId,
    required String seasonId,
    required int seasonNumber,
    required int episodeNumber,
    required String title,
    required String normalizedTitle,
    this.description = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.streamUrl = const Value.absent(),
    this.streamJson = const Value.absent(),
    this.externalId = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isStale = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerId = Value(providerId),
       seriesId = Value(seriesId),
       seasonId = Value(seasonId),
       seasonNumber = Value(seasonNumber),
       episodeNumber = Value(episodeNumber),
       title = Value(title),
       normalizedTitle = Value(normalizedTitle);
  static Insertable<EpisodeRow> custom({
    Expression<String>? id,
    Expression<String>? providerId,
    Expression<String>? seriesId,
    Expression<String>? seasonId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<String>? title,
    Expression<String>? normalizedTitle,
    Expression<String>? description,
    Expression<String>? artworkUrl,
    Expression<String>? streamUrl,
    Expression<String>? streamJson,
    Expression<String>? externalId,
    Expression<int>? durationSeconds,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? lastSeenAt,
    Expression<bool>? isStale,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonId != null) 'season_id': seasonId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (title != null) 'title': title,
      if (normalizedTitle != null) 'normalized_title': normalizedTitle,
      if (description != null) 'description': description,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (streamUrl != null) 'stream_url': streamUrl,
      if (streamJson != null) 'stream_json': streamJson,
      if (externalId != null) 'external_id': externalId,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (isStale != null) 'is_stale': isStale,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith({
    Value<String>? id,
    Value<String>? providerId,
    Value<String>? seriesId,
    Value<String>? seasonId,
    Value<int>? seasonNumber,
    Value<int>? episodeNumber,
    Value<String>? title,
    Value<String>? normalizedTitle,
    Value<String?>? description,
    Value<String?>? artworkUrl,
    Value<String?>? streamUrl,
    Value<String?>? streamJson,
    Value<String?>? externalId,
    Value<int?>? durationSeconds,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? lastSeenAt,
    Value<bool>? isStale,
    Value<int>? rowid,
  }) {
    return EpisodesCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      seriesId: seriesId ?? this.seriesId,
      seasonId: seasonId ?? this.seasonId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      normalizedTitle: normalizedTitle ?? this.normalizedTitle,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      streamJson: streamJson ?? this.streamJson,
      externalId: externalId ?? this.externalId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isStale: isStale ?? this.isStale,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (normalizedTitle.present) {
      map['normalized_title'] = Variable<String>(normalizedTitle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (streamUrl.present) {
      map['stream_url'] = Variable<String>(streamUrl.value);
    }
    if (streamJson.present) {
      map['stream_json'] = Variable<String>(streamJson.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<int>(lastSeenAt.value);
    }
    if (isStale.present) {
      map['is_stale'] = Variable<bool>(isStale.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('normalizedTitle: $normalizedTitle, ')
          ..write('description: $description, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('streamUrl: $streamUrl, ')
          ..write('streamJson: $streamJson, ')
          ..write('externalId: $externalId, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isStale: $isStale, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteItemsTable extends FavoriteItems
    with TableInfo<$FavoriteItemsTable, FavoriteItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _catalogKeyMeta = const VerificationMeta(
    'catalogKey',
  );
  @override
  late final GeneratedColumn<String> catalogKey = GeneratedColumn<String>(
    'catalog_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  @override
  List<GeneratedColumn> get $columns => [
    catalogKey,
    itemId,
    itemType,
    providerId,
    seriesId,
    seasonId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('catalog_key')) {
      context.handle(
        _catalogKeyMeta,
        catalogKey.isAcceptableOrUnknown(data['catalog_key']!, _catalogKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_catalogKeyMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, itemType, catalogKey};
  @override
  FavoriteItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteItemRow(
      catalogKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_key'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoriteItemsTable createAlias(String alias) {
    return $FavoriteItemsTable(attachedDatabase, alias);
  }
}

class FavoriteItemRow extends DataClass implements Insertable<FavoriteItemRow> {
  final String catalogKey;
  final String itemId;
  final String itemType;
  final String providerId;
  final String? seriesId;
  final String? seasonId;
  final int createdAt;
  const FavoriteItemRow({
    required this.catalogKey,
    required this.itemId,
    required this.itemType,
    required this.providerId,
    this.seriesId,
    this.seasonId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['catalog_key'] = Variable<String>(catalogKey);
    map['item_id'] = Variable<String>(itemId);
    map['item_type'] = Variable<String>(itemType);
    map['provider_id'] = Variable<String>(providerId);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || seasonId != null) {
      map['season_id'] = Variable<String>(seasonId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FavoriteItemsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteItemsCompanion(
      catalogKey: Value(catalogKey),
      itemId: Value(itemId),
      itemType: Value(itemType),
      providerId: Value(providerId),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      seasonId: seasonId == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteItemRow(
      catalogKey: serializer.fromJson<String>(json['catalogKey']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      providerId: serializer.fromJson<String>(json['providerId']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      seasonId: serializer.fromJson<String?>(json['seasonId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'catalogKey': serializer.toJson<String>(catalogKey),
      'itemId': serializer.toJson<String>(itemId),
      'itemType': serializer.toJson<String>(itemType),
      'providerId': serializer.toJson<String>(providerId),
      'seriesId': serializer.toJson<String?>(seriesId),
      'seasonId': serializer.toJson<String?>(seasonId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  FavoriteItemRow copyWith({
    String? catalogKey,
    String? itemId,
    String? itemType,
    String? providerId,
    Value<String?> seriesId = const Value.absent(),
    Value<String?> seasonId = const Value.absent(),
    int? createdAt,
  }) => FavoriteItemRow(
    catalogKey: catalogKey ?? this.catalogKey,
    itemId: itemId ?? this.itemId,
    itemType: itemType ?? this.itemType,
    providerId: providerId ?? this.providerId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    seasonId: seasonId.present ? seasonId.value : this.seasonId,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoriteItemRow copyWithCompanion(FavoriteItemsCompanion data) {
    return FavoriteItemRow(
      catalogKey: data.catalogKey.present
          ? data.catalogKey.value
          : this.catalogKey,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteItemRow(')
          ..write('catalogKey: $catalogKey, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('providerId: $providerId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    catalogKey,
    itemId,
    itemType,
    providerId,
    seriesId,
    seasonId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteItemRow &&
          other.catalogKey == this.catalogKey &&
          other.itemId == this.itemId &&
          other.itemType == this.itemType &&
          other.providerId == this.providerId &&
          other.seriesId == this.seriesId &&
          other.seasonId == this.seasonId &&
          other.createdAt == this.createdAt);
}

class FavoriteItemsCompanion extends UpdateCompanion<FavoriteItemRow> {
  final Value<String> catalogKey;
  final Value<String> itemId;
  final Value<String> itemType;
  final Value<String> providerId;
  final Value<String?> seriesId;
  final Value<String?> seasonId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const FavoriteItemsCompanion({
    this.catalogKey = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.providerId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteItemsCompanion.insert({
    required String catalogKey,
    required String itemId,
    required String itemType,
    required String providerId,
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : catalogKey = Value(catalogKey),
       itemId = Value(itemId),
       itemType = Value(itemType),
       providerId = Value(providerId);
  static Insertable<FavoriteItemRow> custom({
    Expression<String>? catalogKey,
    Expression<String>? itemId,
    Expression<String>? itemType,
    Expression<String>? providerId,
    Expression<String>? seriesId,
    Expression<String>? seasonId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (catalogKey != null) 'catalog_key': catalogKey,
      if (itemId != null) 'item_id': itemId,
      if (itemType != null) 'item_type': itemType,
      if (providerId != null) 'provider_id': providerId,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonId != null) 'season_id': seasonId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteItemsCompanion copyWith({
    Value<String>? catalogKey,
    Value<String>? itemId,
    Value<String>? itemType,
    Value<String>? providerId,
    Value<String?>? seriesId,
    Value<String?>? seasonId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return FavoriteItemsCompanion(
      catalogKey: catalogKey ?? this.catalogKey,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      providerId: providerId ?? this.providerId,
      seriesId: seriesId ?? this.seriesId,
      seasonId: seasonId ?? this.seasonId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (catalogKey.present) {
      map['catalog_key'] = Variable<String>(catalogKey.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteItemsCompanion(')
          ..write('catalogKey: $catalogKey, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('providerId: $providerId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoriteCategoriesTable extends FavoriteCategories
    with TableInfo<$FavoriteCategoriesTable, FavoriteCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    contentType,
    categoryId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, contentType, categoryId};
  @override
  FavoriteCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteCategoryRow(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoriteCategoriesTable createAlias(String alias) {
    return $FavoriteCategoriesTable(attachedDatabase, alias);
  }
}

class FavoriteCategoryRow extends DataClass
    implements Insertable<FavoriteCategoryRow> {
  final String providerId;
  final String contentType;
  final String categoryId;
  final int createdAt;
  const FavoriteCategoryRow({
    required this.providerId,
    required this.contentType,
    required this.categoryId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['content_type'] = Variable<String>(contentType);
    map['category_id'] = Variable<String>(categoryId);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FavoriteCategoriesCompanion toCompanion(bool nullToAbsent) {
    return FavoriteCategoriesCompanion(
      providerId: Value(providerId),
      contentType: Value(contentType),
      categoryId: Value(categoryId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteCategoryRow(
      providerId: serializer.fromJson<String>(json['providerId']),
      contentType: serializer.fromJson<String>(json['contentType']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'contentType': serializer.toJson<String>(contentType),
      'categoryId': serializer.toJson<String>(categoryId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  FavoriteCategoryRow copyWith({
    String? providerId,
    String? contentType,
    String? categoryId,
    int? createdAt,
  }) => FavoriteCategoryRow(
    providerId: providerId ?? this.providerId,
    contentType: contentType ?? this.contentType,
    categoryId: categoryId ?? this.categoryId,
    createdAt: createdAt ?? this.createdAt,
  );
  FavoriteCategoryRow copyWithCompanion(FavoriteCategoriesCompanion data) {
    return FavoriteCategoryRow(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteCategoryRow(')
          ..write('providerId: $providerId, ')
          ..write('contentType: $contentType, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(providerId, contentType, categoryId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteCategoryRow &&
          other.providerId == this.providerId &&
          other.contentType == this.contentType &&
          other.categoryId == this.categoryId &&
          other.createdAt == this.createdAt);
}

class FavoriteCategoriesCompanion extends UpdateCompanion<FavoriteCategoryRow> {
  final Value<String> providerId;
  final Value<String> contentType;
  final Value<String> categoryId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const FavoriteCategoriesCompanion({
    this.providerId = const Value.absent(),
    this.contentType = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoriteCategoriesCompanion.insert({
    required String providerId,
    required String contentType,
    required String categoryId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       contentType = Value(contentType),
       categoryId = Value(categoryId);
  static Insertable<FavoriteCategoryRow> custom({
    Expression<String>? providerId,
    Expression<String>? contentType,
    Expression<String>? categoryId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (contentType != null) 'content_type': contentType,
      if (categoryId != null) 'category_id': categoryId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoriteCategoriesCompanion copyWith({
    Value<String>? providerId,
    Value<String>? contentType,
    Value<String>? categoryId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return FavoriteCategoriesCompanion(
      providerId: providerId ?? this.providerId,
      contentType: contentType ?? this.contentType,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteCategoriesCompanion(')
          ..write('providerId: $providerId, ')
          ..write('contentType: $contentType, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryOrderTable extends CategoryOrder
    with TableInfo<$CategoryOrderTable, CategoryOrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryOrderTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    contentType,
    categoryId,
    sortOrder,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_order';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryOrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, contentType, categoryId};
  @override
  CategoryOrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryOrderRow(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoryOrderTable createAlias(String alias) {
    return $CategoryOrderTable(attachedDatabase, alias);
  }
}

class CategoryOrderRow extends DataClass
    implements Insertable<CategoryOrderRow> {
  final String providerId;
  final String contentType;
  final String categoryId;
  final int sortOrder;
  final int updatedAt;
  const CategoryOrderRow({
    required this.providerId,
    required this.contentType,
    required this.categoryId,
    required this.sortOrder,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['content_type'] = Variable<String>(contentType);
    map['category_id'] = Variable<String>(categoryId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CategoryOrderCompanion toCompanion(bool nullToAbsent) {
    return CategoryOrderCompanion(
      providerId: Value(providerId),
      contentType: Value(contentType),
      categoryId: Value(categoryId),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoryOrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryOrderRow(
      providerId: serializer.fromJson<String>(json['providerId']),
      contentType: serializer.fromJson<String>(json['contentType']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'contentType': serializer.toJson<String>(contentType),
      'categoryId': serializer.toJson<String>(categoryId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CategoryOrderRow copyWith({
    String? providerId,
    String? contentType,
    String? categoryId,
    int? sortOrder,
    int? updatedAt,
  }) => CategoryOrderRow(
    providerId: providerId ?? this.providerId,
    contentType: contentType ?? this.contentType,
    categoryId: categoryId ?? this.categoryId,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CategoryOrderRow copyWithCompanion(CategoryOrderCompanion data) {
    return CategoryOrderRow(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOrderRow(')
          ..write('providerId: $providerId, ')
          ..write('contentType: $contentType, ')
          ..write('categoryId: $categoryId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(providerId, contentType, categoryId, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryOrderRow &&
          other.providerId == this.providerId &&
          other.contentType == this.contentType &&
          other.categoryId == this.categoryId &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class CategoryOrderCompanion extends UpdateCompanion<CategoryOrderRow> {
  final Value<String> providerId;
  final Value<String> contentType;
  final Value<String> categoryId;
  final Value<int> sortOrder;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CategoryOrderCompanion({
    this.providerId = const Value.absent(),
    this.contentType = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryOrderCompanion.insert({
    required String providerId,
    required String contentType,
    required String categoryId,
    required int sortOrder,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       contentType = Value(contentType),
       categoryId = Value(categoryId),
       sortOrder = Value(sortOrder);
  static Insertable<CategoryOrderRow> custom({
    Expression<String>? providerId,
    Expression<String>? contentType,
    Expression<String>? categoryId,
    Expression<int>? sortOrder,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (contentType != null) 'content_type': contentType,
      if (categoryId != null) 'category_id': categoryId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryOrderCompanion copyWith({
    Value<String>? providerId,
    Value<String>? contentType,
    Value<String>? categoryId,
    Value<int>? sortOrder,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoryOrderCompanion(
      providerId: providerId ?? this.providerId,
      contentType: contentType ?? this.contentType,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOrderCompanion(')
          ..write('providerId: $providerId, ')
          ..write('contentType: $contentType, ')
          ..write('categoryId: $categoryId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchHistoryTable extends WatchHistory
    with TableInfo<$WatchHistoryTable, WatchHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _catalogKeyMeta = const VerificationMeta(
    'catalogKey',
  );
  @override
  late final GeneratedColumn<String> catalogKey = GeneratedColumn<String>(
    'catalog_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionSecondsMeta = const VerificationMeta(
    'positionSeconds',
  );
  @override
  late final GeneratedColumn<int> positionSeconds = GeneratedColumn<int>(
    'position_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastWatchedAtMeta = const VerificationMeta(
    'lastWatchedAt',
  );
  @override
  late final GeneratedColumn<int> lastWatchedAt = GeneratedColumn<int>(
    'last_watched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  static const VerificationMeta _watchCountMeta = const VerificationMeta(
    'watchCount',
  );
  @override
  late final GeneratedColumn<int> watchCount = GeneratedColumn<int>(
    'watch_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    catalogKey,
    itemId,
    itemType,
    providerId,
    title,
    subtitle,
    artworkUrl,
    seriesId,
    seasonId,
    positionSeconds,
    durationSeconds,
    completed,
    lastWatchedAt,
    watchCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('catalog_key')) {
      context.handle(
        _catalogKeyMeta,
        catalogKey.isAcceptableOrUnknown(data['catalog_key']!, _catalogKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_catalogKeyMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    }
    if (data.containsKey('position_seconds')) {
      context.handle(
        _positionSecondsMeta,
        positionSeconds.isAcceptableOrUnknown(
          data['position_seconds']!,
          _positionSecondsMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
        _lastWatchedAtMeta,
        lastWatchedAt.isAcceptableOrUnknown(
          data['last_watched_at']!,
          _lastWatchedAtMeta,
        ),
      );
    }
    if (data.containsKey('watch_count')) {
      context.handle(
        _watchCountMeta,
        watchCount.isAcceptableOrUnknown(data['watch_count']!, _watchCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, itemType, catalogKey};
  @override
  WatchHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryRow(
      catalogKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_key'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      ),
      positionSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_seconds'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      lastWatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_watched_at'],
      )!,
      watchCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}watch_count'],
      )!,
    );
  }

  @override
  $WatchHistoryTable createAlias(String alias) {
    return $WatchHistoryTable(attachedDatabase, alias);
  }
}

class WatchHistoryRow extends DataClass implements Insertable<WatchHistoryRow> {
  final String catalogKey;
  final String itemId;
  final String itemType;
  final String providerId;
  final String title;
  final String? subtitle;
  final String? artworkUrl;
  final String? seriesId;
  final String? seasonId;
  final int positionSeconds;
  final int? durationSeconds;
  final bool completed;
  final int lastWatchedAt;
  final int watchCount;
  const WatchHistoryRow({
    required this.catalogKey,
    required this.itemId,
    required this.itemType,
    required this.providerId,
    required this.title,
    this.subtitle,
    this.artworkUrl,
    this.seriesId,
    this.seasonId,
    required this.positionSeconds,
    this.durationSeconds,
    required this.completed,
    required this.lastWatchedAt,
    required this.watchCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['catalog_key'] = Variable<String>(catalogKey);
    map['item_id'] = Variable<String>(itemId);
    map['item_type'] = Variable<String>(itemType);
    map['provider_id'] = Variable<String>(providerId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || seasonId != null) {
      map['season_id'] = Variable<String>(seasonId);
    }
    map['position_seconds'] = Variable<int>(positionSeconds);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['completed'] = Variable<bool>(completed);
    map['last_watched_at'] = Variable<int>(lastWatchedAt);
    map['watch_count'] = Variable<int>(watchCount);
    return map;
  }

  WatchHistoryCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryCompanion(
      catalogKey: Value(catalogKey),
      itemId: Value(itemId),
      itemType: Value(itemType),
      providerId: Value(providerId),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      seasonId: seasonId == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonId),
      positionSeconds: Value(positionSeconds),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      completed: Value(completed),
      lastWatchedAt: Value(lastWatchedAt),
      watchCount: Value(watchCount),
    );
  }

  factory WatchHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryRow(
      catalogKey: serializer.fromJson<String>(json['catalogKey']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      providerId: serializer.fromJson<String>(json['providerId']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      seasonId: serializer.fromJson<String?>(json['seasonId']),
      positionSeconds: serializer.fromJson<int>(json['positionSeconds']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      completed: serializer.fromJson<bool>(json['completed']),
      lastWatchedAt: serializer.fromJson<int>(json['lastWatchedAt']),
      watchCount: serializer.fromJson<int>(json['watchCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'catalogKey': serializer.toJson<String>(catalogKey),
      'itemId': serializer.toJson<String>(itemId),
      'itemType': serializer.toJson<String>(itemType),
      'providerId': serializer.toJson<String>(providerId),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'seriesId': serializer.toJson<String?>(seriesId),
      'seasonId': serializer.toJson<String?>(seasonId),
      'positionSeconds': serializer.toJson<int>(positionSeconds),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'completed': serializer.toJson<bool>(completed),
      'lastWatchedAt': serializer.toJson<int>(lastWatchedAt),
      'watchCount': serializer.toJson<int>(watchCount),
    };
  }

  WatchHistoryRow copyWith({
    String? catalogKey,
    String? itemId,
    String? itemType,
    String? providerId,
    String? title,
    Value<String?> subtitle = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    Value<String?> seriesId = const Value.absent(),
    Value<String?> seasonId = const Value.absent(),
    int? positionSeconds,
    Value<int?> durationSeconds = const Value.absent(),
    bool? completed,
    int? lastWatchedAt,
    int? watchCount,
  }) => WatchHistoryRow(
    catalogKey: catalogKey ?? this.catalogKey,
    itemId: itemId ?? this.itemId,
    itemType: itemType ?? this.itemType,
    providerId: providerId ?? this.providerId,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    seasonId: seasonId.present ? seasonId.value : this.seasonId,
    positionSeconds: positionSeconds ?? this.positionSeconds,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    completed: completed ?? this.completed,
    lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    watchCount: watchCount ?? this.watchCount,
  );
  WatchHistoryRow copyWithCompanion(WatchHistoryCompanion data) {
    return WatchHistoryRow(
      catalogKey: data.catalogKey.present
          ? data.catalogKey.value
          : this.catalogKey,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      positionSeconds: data.positionSeconds.present
          ? data.positionSeconds.value
          : this.positionSeconds,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      completed: data.completed.present ? data.completed.value : this.completed,
      lastWatchedAt: data.lastWatchedAt.present
          ? data.lastWatchedAt.value
          : this.lastWatchedAt,
      watchCount: data.watchCount.present
          ? data.watchCount.value
          : this.watchCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryRow(')
          ..write('catalogKey: $catalogKey, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('providerId: $providerId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('completed: $completed, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('watchCount: $watchCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    catalogKey,
    itemId,
    itemType,
    providerId,
    title,
    subtitle,
    artworkUrl,
    seriesId,
    seasonId,
    positionSeconds,
    durationSeconds,
    completed,
    lastWatchedAt,
    watchCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryRow &&
          other.catalogKey == this.catalogKey &&
          other.itemId == this.itemId &&
          other.itemType == this.itemType &&
          other.providerId == this.providerId &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.artworkUrl == this.artworkUrl &&
          other.seriesId == this.seriesId &&
          other.seasonId == this.seasonId &&
          other.positionSeconds == this.positionSeconds &&
          other.durationSeconds == this.durationSeconds &&
          other.completed == this.completed &&
          other.lastWatchedAt == this.lastWatchedAt &&
          other.watchCount == this.watchCount);
}

class WatchHistoryCompanion extends UpdateCompanion<WatchHistoryRow> {
  final Value<String> catalogKey;
  final Value<String> itemId;
  final Value<String> itemType;
  final Value<String> providerId;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<String?> artworkUrl;
  final Value<String?> seriesId;
  final Value<String?> seasonId;
  final Value<int> positionSeconds;
  final Value<int?> durationSeconds;
  final Value<bool> completed;
  final Value<int> lastWatchedAt;
  final Value<int> watchCount;
  final Value<int> rowid;
  const WatchHistoryCompanion({
    this.catalogKey = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.providerId = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.completed = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.watchCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchHistoryCompanion.insert({
    required String catalogKey,
    required String itemId,
    required String itemType,
    required String providerId,
    required String title,
    this.subtitle = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.completed = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.watchCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : catalogKey = Value(catalogKey),
       itemId = Value(itemId),
       itemType = Value(itemType),
       providerId = Value(providerId),
       title = Value(title);
  static Insertable<WatchHistoryRow> custom({
    Expression<String>? catalogKey,
    Expression<String>? itemId,
    Expression<String>? itemType,
    Expression<String>? providerId,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? artworkUrl,
    Expression<String>? seriesId,
    Expression<String>? seasonId,
    Expression<int>? positionSeconds,
    Expression<int>? durationSeconds,
    Expression<bool>? completed,
    Expression<int>? lastWatchedAt,
    Expression<int>? watchCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (catalogKey != null) 'catalog_key': catalogKey,
      if (itemId != null) 'item_id': itemId,
      if (itemType != null) 'item_type': itemType,
      if (providerId != null) 'provider_id': providerId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonId != null) 'season_id': seasonId,
      if (positionSeconds != null) 'position_seconds': positionSeconds,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (completed != null) 'completed': completed,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
      if (watchCount != null) 'watch_count': watchCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchHistoryCompanion copyWith({
    Value<String>? catalogKey,
    Value<String>? itemId,
    Value<String>? itemType,
    Value<String>? providerId,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<String?>? artworkUrl,
    Value<String?>? seriesId,
    Value<String?>? seasonId,
    Value<int>? positionSeconds,
    Value<int?>? durationSeconds,
    Value<bool>? completed,
    Value<int>? lastWatchedAt,
    Value<int>? watchCount,
    Value<int>? rowid,
  }) {
    return WatchHistoryCompanion(
      catalogKey: catalogKey ?? this.catalogKey,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      seriesId: seriesId ?? this.seriesId,
      seasonId: seasonId ?? this.seasonId,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      watchCount: watchCount ?? this.watchCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (catalogKey.present) {
      map['catalog_key'] = Variable<String>(catalogKey.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (positionSeconds.present) {
      map['position_seconds'] = Variable<int>(positionSeconds.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<int>(lastWatchedAt.value);
    }
    if (watchCount.present) {
      map['watch_count'] = Variable<int>(watchCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryCompanion(')
          ..write('catalogKey: $catalogKey, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('providerId: $providerId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('completed: $completed, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('watchCount: $watchCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackPositionsTable extends PlaybackPositions
    with TableInfo<$PlaybackPositionsTable, PlaybackPositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _catalogKeyMeta = const VerificationMeta(
    'catalogKey',
  );
  @override
  late final GeneratedColumn<String> catalogKey = GeneratedColumn<String>(
    'catalog_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<String> seasonId = GeneratedColumn<String>(
    'season_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionSecondsMeta = const VerificationMeta(
    'positionSeconds',
  );
  @override
  late final GeneratedColumn<int> positionSeconds = GeneratedColumn<int>(
    'position_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    catalogKey,
    itemId,
    itemType,
    seriesId,
    seasonId,
    positionSeconds,
    durationSeconds,
    completed,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackPositionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('catalog_key')) {
      context.handle(
        _catalogKeyMeta,
        catalogKey.isAcceptableOrUnknown(data['catalog_key']!, _catalogKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_catalogKeyMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    }
    if (data.containsKey('position_seconds')) {
      context.handle(
        _positionSecondsMeta,
        positionSeconds.isAcceptableOrUnknown(
          data['position_seconds']!,
          _positionSecondsMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, itemType, catalogKey};
  @override
  PlaybackPositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackPositionRow(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      catalogKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_key'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}season_id'],
      ),
      positionSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_seconds'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaybackPositionsTable createAlias(String alias) {
    return $PlaybackPositionsTable(attachedDatabase, alias);
  }
}

class PlaybackPositionRow extends DataClass
    implements Insertable<PlaybackPositionRow> {
  final String providerId;
  final String catalogKey;
  final String itemId;
  final String itemType;
  final String? seriesId;
  final String? seasonId;
  final int positionSeconds;
  final int? durationSeconds;
  final bool completed;
  final int updatedAt;
  const PlaybackPositionRow({
    required this.providerId,
    required this.catalogKey,
    required this.itemId,
    required this.itemType,
    this.seriesId,
    this.seasonId,
    required this.positionSeconds,
    this.durationSeconds,
    required this.completed,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['catalog_key'] = Variable<String>(catalogKey);
    map['item_id'] = Variable<String>(itemId);
    map['item_type'] = Variable<String>(itemType);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    if (!nullToAbsent || seasonId != null) {
      map['season_id'] = Variable<String>(seasonId);
    }
    map['position_seconds'] = Variable<int>(positionSeconds);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['completed'] = Variable<bool>(completed);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PlaybackPositionsCompanion toCompanion(bool nullToAbsent) {
    return PlaybackPositionsCompanion(
      providerId: Value(providerId),
      catalogKey: Value(catalogKey),
      itemId: Value(itemId),
      itemType: Value(itemType),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      seasonId: seasonId == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonId),
      positionSeconds: Value(positionSeconds),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      completed: Value(completed),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaybackPositionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackPositionRow(
      providerId: serializer.fromJson<String>(json['providerId']),
      catalogKey: serializer.fromJson<String>(json['catalogKey']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      seasonId: serializer.fromJson<String?>(json['seasonId']),
      positionSeconds: serializer.fromJson<int>(json['positionSeconds']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      completed: serializer.fromJson<bool>(json['completed']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'catalogKey': serializer.toJson<String>(catalogKey),
      'itemId': serializer.toJson<String>(itemId),
      'itemType': serializer.toJson<String>(itemType),
      'seriesId': serializer.toJson<String?>(seriesId),
      'seasonId': serializer.toJson<String?>(seasonId),
      'positionSeconds': serializer.toJson<int>(positionSeconds),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'completed': serializer.toJson<bool>(completed),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PlaybackPositionRow copyWith({
    String? providerId,
    String? catalogKey,
    String? itemId,
    String? itemType,
    Value<String?> seriesId = const Value.absent(),
    Value<String?> seasonId = const Value.absent(),
    int? positionSeconds,
    Value<int?> durationSeconds = const Value.absent(),
    bool? completed,
    int? updatedAt,
  }) => PlaybackPositionRow(
    providerId: providerId ?? this.providerId,
    catalogKey: catalogKey ?? this.catalogKey,
    itemId: itemId ?? this.itemId,
    itemType: itemType ?? this.itemType,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    seasonId: seasonId.present ? seasonId.value : this.seasonId,
    positionSeconds: positionSeconds ?? this.positionSeconds,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    completed: completed ?? this.completed,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaybackPositionRow copyWithCompanion(PlaybackPositionsCompanion data) {
    return PlaybackPositionRow(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      catalogKey: data.catalogKey.present
          ? data.catalogKey.value
          : this.catalogKey,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      positionSeconds: data.positionSeconds.present
          ? data.positionSeconds.value
          : this.positionSeconds,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      completed: data.completed.present ? data.completed.value : this.completed,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackPositionRow(')
          ..write('providerId: $providerId, ')
          ..write('catalogKey: $catalogKey, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('completed: $completed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    catalogKey,
    itemId,
    itemType,
    seriesId,
    seasonId,
    positionSeconds,
    durationSeconds,
    completed,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackPositionRow &&
          other.providerId == this.providerId &&
          other.catalogKey == this.catalogKey &&
          other.itemId == this.itemId &&
          other.itemType == this.itemType &&
          other.seriesId == this.seriesId &&
          other.seasonId == this.seasonId &&
          other.positionSeconds == this.positionSeconds &&
          other.durationSeconds == this.durationSeconds &&
          other.completed == this.completed &&
          other.updatedAt == this.updatedAt);
}

class PlaybackPositionsCompanion extends UpdateCompanion<PlaybackPositionRow> {
  final Value<String> providerId;
  final Value<String> catalogKey;
  final Value<String> itemId;
  final Value<String> itemType;
  final Value<String?> seriesId;
  final Value<String?> seasonId;
  final Value<int> positionSeconds;
  final Value<int?> durationSeconds;
  final Value<bool> completed;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PlaybackPositionsCompanion({
    this.providerId = const Value.absent(),
    this.catalogKey = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.completed = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackPositionsCompanion.insert({
    required String providerId,
    required String catalogKey,
    required String itemId,
    required String itemType,
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.completed = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       catalogKey = Value(catalogKey),
       itemId = Value(itemId),
       itemType = Value(itemType);
  static Insertable<PlaybackPositionRow> custom({
    Expression<String>? providerId,
    Expression<String>? catalogKey,
    Expression<String>? itemId,
    Expression<String>? itemType,
    Expression<String>? seriesId,
    Expression<String>? seasonId,
    Expression<int>? positionSeconds,
    Expression<int>? durationSeconds,
    Expression<bool>? completed,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (catalogKey != null) 'catalog_key': catalogKey,
      if (itemId != null) 'item_id': itemId,
      if (itemType != null) 'item_type': itemType,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonId != null) 'season_id': seasonId,
      if (positionSeconds != null) 'position_seconds': positionSeconds,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (completed != null) 'completed': completed,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackPositionsCompanion copyWith({
    Value<String>? providerId,
    Value<String>? catalogKey,
    Value<String>? itemId,
    Value<String>? itemType,
    Value<String?>? seriesId,
    Value<String?>? seasonId,
    Value<int>? positionSeconds,
    Value<int?>? durationSeconds,
    Value<bool>? completed,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlaybackPositionsCompanion(
      providerId: providerId ?? this.providerId,
      catalogKey: catalogKey ?? this.catalogKey,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      seriesId: seriesId ?? this.seriesId,
      seasonId: seasonId ?? this.seasonId,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (catalogKey.present) {
      map['catalog_key'] = Variable<String>(catalogKey.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<String>(seasonId.value);
    }
    if (positionSeconds.present) {
      map['position_seconds'] = Variable<int>(positionSeconds.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackPositionsCompanion(')
          ..write('providerId: $providerId, ')
          ..write('catalogKey: $catalogKey, ')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('completed: $completed, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    clientDefault: _nowMs,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  final int updatedAt;
  const AppSettingRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSettingRow copyWith({String? key, String? value, int? updatedAt}) =>
      AppSettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CatalogDatabase extends GeneratedDatabase {
  _$CatalogDatabase(QueryExecutor e) : super(e);
  $CatalogDatabaseManager get managers => $CatalogDatabaseManager(this);
  late final $CatalogProvidersTable catalogProviders = $CatalogProvidersTable(
    this,
  );
  late final $ProviderRefreshRunsTable providerRefreshRuns =
      $ProviderRefreshRunsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $CatalogItemsTable catalogItems = $CatalogItemsTable(this);
  late final $SeriesTable series = $SeriesTable(this);
  late final $SeasonsTable seasons = $SeasonsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $FavoriteItemsTable favoriteItems = $FavoriteItemsTable(this);
  late final $FavoriteCategoriesTable favoriteCategories =
      $FavoriteCategoriesTable(this);
  late final $CategoryOrderTable categoryOrder = $CategoryOrderTable(this);
  late final $WatchHistoryTable watchHistory = $WatchHistoryTable(this);
  late final $PlaybackPositionsTable playbackPositions =
      $PlaybackPositionsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    catalogProviders,
    providerRefreshRuns,
    categories,
    catalogItems,
    series,
    seasons,
    episodes,
    favoriteItems,
    favoriteCategories,
    categoryOrder,
    watchHistory,
    playbackPositions,
    appSettings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('provider_refresh_runs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('catalog_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('series', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('seasons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('episodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorite_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorite_categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('category_order', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('watch_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_positions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CatalogProvidersTableCreateCompanionBuilder =
    CatalogProvidersCompanion Function({
      required String id,
      required String type,
      required String name,
      required String source,
      Value<String?> sourceKind,
      Value<SensitiveText?> username,
      Value<SensitiveText?> password,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> lastRefreshAt,
      Value<bool> autoRefreshEnabled,
      Value<int> autoRefreshIntervalMinutes,
      Value<bool> isEnabled,
      Value<int> rowid,
    });
typedef $$CatalogProvidersTableUpdateCompanionBuilder =
    CatalogProvidersCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> name,
      Value<String> source,
      Value<String?> sourceKind,
      Value<SensitiveText?> username,
      Value<SensitiveText?> password,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> lastRefreshAt,
      Value<bool> autoRefreshEnabled,
      Value<int> autoRefreshIntervalMinutes,
      Value<bool> isEnabled,
      Value<int> rowid,
    });

final class $$CatalogProvidersTableReferences
    extends
        BaseReferences<
          _$CatalogDatabase,
          $CatalogProvidersTable,
          CatalogProviderRow
        > {
  $$CatalogProvidersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $ProviderRefreshRunsTable,
    List<ProviderRefreshRunRow>
  >
  _providerRefreshRunsRefsTable(_$CatalogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.providerRefreshRuns,
        aliasName: $_aliasNameGenerator(
          db.catalogProviders.id,
          db.providerRefreshRuns.providerId,
        ),
      );

  $$ProviderRefreshRunsTableProcessedTableManager get providerRefreshRunsRefs {
    final manager = $$ProviderRefreshRunsTableTableManager(
      $_db,
      $_db.providerRefreshRuns,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _providerRefreshRunsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CategoriesTable, List<CategoryRow>>
  _categoriesRefsTable(_$CatalogDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: $_aliasNameGenerator(
      db.catalogProviders.id,
      db.categories.providerId,
    ),
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CatalogItemsTable, List<CatalogItemRow>>
  _catalogItemsRefsTable(_$CatalogDatabase db) => MultiTypedResultKey.fromTable(
    db.catalogItems,
    aliasName: $_aliasNameGenerator(
      db.catalogProviders.id,
      db.catalogItems.providerId,
    ),
  );

  $$CatalogItemsTableProcessedTableManager get catalogItemsRefs {
    final manager = $$CatalogItemsTableTableManager(
      $_db,
      $_db.catalogItems,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_catalogItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SeriesTable, List<SeriesRow>> _seriesRefsTable(
    _$CatalogDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.series,
    aliasName: $_aliasNameGenerator(
      db.catalogProviders.id,
      db.series.providerId,
    ),
  );

  $$SeriesTableProcessedTableManager get seriesRefs {
    final manager = $$SeriesTableTableManager(
      $_db,
      $_db.series,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_seriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SeasonsTable, List<SeasonRow>> _seasonsRefsTable(
    _$CatalogDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.seasons,
    aliasName: $_aliasNameGenerator(
      db.catalogProviders.id,
      db.seasons.providerId,
    ),
  );

  $$SeasonsTableProcessedTableManager get seasonsRefs {
    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_seasonsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpisodesTable, List<EpisodeRow>>
  _episodesRefsTable(_$CatalogDatabase db) => MultiTypedResultKey.fromTable(
    db.episodes,
    aliasName: $_aliasNameGenerator(
      db.catalogProviders.id,
      db.episodes.providerId,
    ),
  );

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoriteItemsTable, List<FavoriteItemRow>>
  _favoriteItemsRefsTable(_$CatalogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.favoriteItems,
        aliasName: $_aliasNameGenerator(
          db.catalogProviders.id,
          db.favoriteItems.providerId,
        ),
      );

  $$FavoriteItemsTableProcessedTableManager get favoriteItemsRefs {
    final manager = $$FavoriteItemsTableTableManager(
      $_db,
      $_db.favoriteItems,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoriteItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $FavoriteCategoriesTable,
    List<FavoriteCategoryRow>
  >
  _favoriteCategoriesRefsTable(_$CatalogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.favoriteCategories,
        aliasName: $_aliasNameGenerator(
          db.catalogProviders.id,
          db.favoriteCategories.providerId,
        ),
      );

  $$FavoriteCategoriesTableProcessedTableManager get favoriteCategoriesRefs {
    final manager = $$FavoriteCategoriesTableTableManager(
      $_db,
      $_db.favoriteCategories,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _favoriteCategoriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CategoryOrderTable, List<CategoryOrderRow>>
  _categoryOrderRefsTable(_$CatalogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.categoryOrder,
        aliasName: $_aliasNameGenerator(
          db.catalogProviders.id,
          db.categoryOrder.providerId,
        ),
      );

  $$CategoryOrderTableProcessedTableManager get categoryOrderRefs {
    final manager = $$CategoryOrderTableTableManager(
      $_db,
      $_db.categoryOrder,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoryOrderRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WatchHistoryTable, List<WatchHistoryRow>>
  _watchHistoryRefsTable(_$CatalogDatabase db) => MultiTypedResultKey.fromTable(
    db.watchHistory,
    aliasName: $_aliasNameGenerator(
      db.catalogProviders.id,
      db.watchHistory.providerId,
    ),
  );

  $$WatchHistoryTableProcessedTableManager get watchHistoryRefs {
    final manager = $$WatchHistoryTableTableManager(
      $_db,
      $_db.watchHistory,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_watchHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaybackPositionsTable, List<PlaybackPositionRow>>
  _playbackPositionsRefsTable(_$CatalogDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackPositions,
        aliasName: $_aliasNameGenerator(
          db.catalogProviders.id,
          db.playbackPositions.providerId,
        ),
      );

  $$PlaybackPositionsTableProcessedTableManager get playbackPositionsRefs {
    final manager = $$PlaybackPositionsTableTableManager(
      $_db,
      $_db.playbackPositions,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackPositionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CatalogProvidersTableFilterComposer
    extends Composer<_$CatalogDatabase, $CatalogProvidersTable> {
  $$CatalogProvidersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SensitiveText?, SensitiveText, String>
  get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SensitiveText?, SensitiveText, String>
  get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRefreshAt => $composableBuilder(
    column: $table.lastRefreshAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoRefreshEnabled => $composableBuilder(
    column: $table.autoRefreshEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get autoRefreshIntervalMinutes => $composableBuilder(
    column: $table.autoRefreshIntervalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> providerRefreshRunsRefs(
    Expression<bool> Function($$ProviderRefreshRunsTableFilterComposer f) f,
  ) {
    final $$ProviderRefreshRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.providerRefreshRuns,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderRefreshRunsTableFilterComposer(
            $db: $db,
            $table: $db.providerRefreshRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> catalogItemsRefs(
    Expression<bool> Function($$CatalogItemsTableFilterComposer f) f,
  ) {
    final $$CatalogItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.catalogItems,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogItemsTableFilterComposer(
            $db: $db,
            $table: $db.catalogItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> seriesRefs(
    Expression<bool> Function($$SeriesTableFilterComposer f) f,
  ) {
    final $$SeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableFilterComposer(
            $db: $db,
            $table: $db.series,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> seasonsRefs(
    Expression<bool> Function($$SeasonsTableFilterComposer f) f,
  ) {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> episodesRefs(
    Expression<bool> Function($$EpisodesTableFilterComposer f) f,
  ) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableFilterComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoriteItemsRefs(
    Expression<bool> Function($$FavoriteItemsTableFilterComposer f) f,
  ) {
    final $$FavoriteItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favoriteItems,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteItemsTableFilterComposer(
            $db: $db,
            $table: $db.favoriteItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoriteCategoriesRefs(
    Expression<bool> Function($$FavoriteCategoriesTableFilterComposer f) f,
  ) {
    final $$FavoriteCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favoriteCategories,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.favoriteCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> categoryOrderRefs(
    Expression<bool> Function($$CategoryOrderTableFilterComposer f) f,
  ) {
    final $$CategoryOrderTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categoryOrder,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoryOrderTableFilterComposer(
            $db: $db,
            $table: $db.categoryOrder,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> watchHistoryRefs(
    Expression<bool> Function($$WatchHistoryTableFilterComposer f) f,
  ) {
    final $$WatchHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchHistoryTableFilterComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playbackPositionsRefs(
    Expression<bool> Function($$PlaybackPositionsTableFilterComposer f) f,
  ) {
    final $$PlaybackPositionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackPositions,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackPositionsTableFilterComposer(
            $db: $db,
            $table: $db.playbackPositions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CatalogProvidersTableOrderingComposer
    extends Composer<_$CatalogDatabase, $CatalogProvidersTable> {
  $$CatalogProvidersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRefreshAt => $composableBuilder(
    column: $table.lastRefreshAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoRefreshEnabled => $composableBuilder(
    column: $table.autoRefreshEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get autoRefreshIntervalMinutes => $composableBuilder(
    column: $table.autoRefreshIntervalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogProvidersTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $CatalogProvidersTable> {
  $$CatalogProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SensitiveText?, String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SensitiveText?, String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastRefreshAt => $composableBuilder(
    column: $table.lastRefreshAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoRefreshEnabled => $composableBuilder(
    column: $table.autoRefreshEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get autoRefreshIntervalMinutes => $composableBuilder(
    column: $table.autoRefreshIntervalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  Expression<T> providerRefreshRunsRefs<T extends Object>(
    Expression<T> Function($$ProviderRefreshRunsTableAnnotationComposer a) f,
  ) {
    final $$ProviderRefreshRunsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.providerRefreshRuns,
          getReferencedColumn: (t) => t.providerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProviderRefreshRunsTableAnnotationComposer(
                $db: $db,
                $table: $db.providerRefreshRuns,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> catalogItemsRefs<T extends Object>(
    Expression<T> Function($$CatalogItemsTableAnnotationComposer a) f,
  ) {
    final $$CatalogItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.catalogItems,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> seriesRefs<T extends Object>(
    Expression<T> Function($$SeriesTableAnnotationComposer a) f,
  ) {
    final $$SeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.series,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> seasonsRefs<T extends Object>(
    Expression<T> Function($$SeasonsTableAnnotationComposer a) f,
  ) {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> episodesRefs<T extends Object>(
    Expression<T> Function($$EpisodesTableAnnotationComposer a) f,
  ) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoriteItemsRefs<T extends Object>(
    Expression<T> Function($$FavoriteItemsTableAnnotationComposer a) f,
  ) {
    final $$FavoriteItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favoriteItems,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.favoriteItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoriteCategoriesRefs<T extends Object>(
    Expression<T> Function($$FavoriteCategoriesTableAnnotationComposer a) f,
  ) {
    final $$FavoriteCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.favoriteCategories,
          getReferencedColumn: (t) => t.providerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$FavoriteCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.favoriteCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> categoryOrderRefs<T extends Object>(
    Expression<T> Function($$CategoryOrderTableAnnotationComposer a) f,
  ) {
    final $$CategoryOrderTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categoryOrder,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoryOrderTableAnnotationComposer(
            $db: $db,
            $table: $db.categoryOrder,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> watchHistoryRefs<T extends Object>(
    Expression<T> Function($$WatchHistoryTableAnnotationComposer a) f,
  ) {
    final $$WatchHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playbackPositionsRefs<T extends Object>(
    Expression<T> Function($$PlaybackPositionsTableAnnotationComposer a) f,
  ) {
    final $$PlaybackPositionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.playbackPositions,
          getReferencedColumn: (t) => t.providerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PlaybackPositionsTableAnnotationComposer(
                $db: $db,
                $table: $db.playbackPositions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CatalogProvidersTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $CatalogProvidersTable,
          CatalogProviderRow,
          $$CatalogProvidersTableFilterComposer,
          $$CatalogProvidersTableOrderingComposer,
          $$CatalogProvidersTableAnnotationComposer,
          $$CatalogProvidersTableCreateCompanionBuilder,
          $$CatalogProvidersTableUpdateCompanionBuilder,
          (CatalogProviderRow, $$CatalogProvidersTableReferences),
          CatalogProviderRow,
          PrefetchHooks Function({
            bool providerRefreshRunsRefs,
            bool categoriesRefs,
            bool catalogItemsRefs,
            bool seriesRefs,
            bool seasonsRefs,
            bool episodesRefs,
            bool favoriteItemsRefs,
            bool favoriteCategoriesRefs,
            bool categoryOrderRefs,
            bool watchHistoryRefs,
            bool playbackPositionsRefs,
          })
        > {
  $$CatalogProvidersTableTableManager(
    _$CatalogDatabase db,
    $CatalogProvidersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceKind = const Value.absent(),
                Value<SensitiveText?> username = const Value.absent(),
                Value<SensitiveText?> password = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> lastRefreshAt = const Value.absent(),
                Value<bool> autoRefreshEnabled = const Value.absent(),
                Value<int> autoRefreshIntervalMinutes = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogProvidersCompanion(
                id: id,
                type: type,
                name: name,
                source: source,
                sourceKind: sourceKind,
                username: username,
                password: password,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastRefreshAt: lastRefreshAt,
                autoRefreshEnabled: autoRefreshEnabled,
                autoRefreshIntervalMinutes: autoRefreshIntervalMinutes,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String name,
                required String source,
                Value<String?> sourceKind = const Value.absent(),
                Value<SensitiveText?> username = const Value.absent(),
                Value<SensitiveText?> password = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> lastRefreshAt = const Value.absent(),
                Value<bool> autoRefreshEnabled = const Value.absent(),
                Value<int> autoRefreshIntervalMinutes = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogProvidersCompanion.insert(
                id: id,
                type: type,
                name: name,
                source: source,
                sourceKind: sourceKind,
                username: username,
                password: password,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastRefreshAt: lastRefreshAt,
                autoRefreshEnabled: autoRefreshEnabled,
                autoRefreshIntervalMinutes: autoRefreshIntervalMinutes,
                isEnabled: isEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CatalogProvidersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                providerRefreshRunsRefs = false,
                categoriesRefs = false,
                catalogItemsRefs = false,
                seriesRefs = false,
                seasonsRefs = false,
                episodesRefs = false,
                favoriteItemsRefs = false,
                favoriteCategoriesRefs = false,
                categoryOrderRefs = false,
                watchHistoryRefs = false,
                playbackPositionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (providerRefreshRunsRefs) db.providerRefreshRuns,
                    if (categoriesRefs) db.categories,
                    if (catalogItemsRefs) db.catalogItems,
                    if (seriesRefs) db.series,
                    if (seasonsRefs) db.seasons,
                    if (episodesRefs) db.episodes,
                    if (favoriteItemsRefs) db.favoriteItems,
                    if (favoriteCategoriesRefs) db.favoriteCategories,
                    if (categoryOrderRefs) db.categoryOrder,
                    if (watchHistoryRefs) db.watchHistory,
                    if (playbackPositionsRefs) db.playbackPositions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (providerRefreshRunsRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          ProviderRefreshRunRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._providerRefreshRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).providerRefreshRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (categoriesRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          CategoryRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (catalogItemsRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          CatalogItemRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._catalogItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).catalogItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seriesRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          SeriesRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._seriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).seriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seasonsRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          SeasonRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._seasonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).seasonsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (episodesRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          EpisodeRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._episodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).episodesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (favoriteItemsRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          FavoriteItemRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._favoriteItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).favoriteItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (favoriteCategoriesRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          FavoriteCategoryRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._favoriteCategoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).favoriteCategoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (categoryOrderRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          CategoryOrderRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._categoryOrderRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).categoryOrderRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (watchHistoryRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          WatchHistoryRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._watchHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).watchHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playbackPositionsRefs)
                        await $_getPrefetchedData<
                          CatalogProviderRow,
                          $CatalogProvidersTable,
                          PlaybackPositionRow
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProvidersTableReferences
                              ._playbackPositionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackPositionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CatalogProvidersTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $CatalogProvidersTable,
      CatalogProviderRow,
      $$CatalogProvidersTableFilterComposer,
      $$CatalogProvidersTableOrderingComposer,
      $$CatalogProvidersTableAnnotationComposer,
      $$CatalogProvidersTableCreateCompanionBuilder,
      $$CatalogProvidersTableUpdateCompanionBuilder,
      (CatalogProviderRow, $$CatalogProvidersTableReferences),
      CatalogProviderRow,
      PrefetchHooks Function({
        bool providerRefreshRunsRefs,
        bool categoriesRefs,
        bool catalogItemsRefs,
        bool seriesRefs,
        bool seasonsRefs,
        bool episodesRefs,
        bool favoriteItemsRefs,
        bool favoriteCategoriesRefs,
        bool categoryOrderRefs,
        bool watchHistoryRefs,
        bool playbackPositionsRefs,
      })
    >;
typedef $$ProviderRefreshRunsTableCreateCompanionBuilder =
    ProviderRefreshRunsCompanion Function({
      required String id,
      required String providerId,
      required String status,
      Value<int> startedAt,
      Value<int?> finishedAt,
      Value<int> itemCount,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$ProviderRefreshRunsTableUpdateCompanionBuilder =
    ProviderRefreshRunsCompanion Function({
      Value<String> id,
      Value<String> providerId,
      Value<String> status,
      Value<int> startedAt,
      Value<int?> finishedAt,
      Value<int> itemCount,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

final class $$ProviderRefreshRunsTableReferences
    extends
        BaseReferences<
          _$CatalogDatabase,
          $ProviderRefreshRunsTable,
          ProviderRefreshRunRow
        > {
  $$ProviderRefreshRunsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(
          db.providerRefreshRuns.providerId,
          db.catalogProviders.id,
        ),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProviderRefreshRunsTableFilterComposer
    extends Composer<_$CatalogDatabase, $ProviderRefreshRunsTable> {
  $$ProviderRefreshRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderRefreshRunsTableOrderingComposer
    extends Composer<_$CatalogDatabase, $ProviderRefreshRunsTable> {
  $$ProviderRefreshRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderRefreshRunsTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $ProviderRefreshRunsTable> {
  $$ProviderRefreshRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderRefreshRunsTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $ProviderRefreshRunsTable,
          ProviderRefreshRunRow,
          $$ProviderRefreshRunsTableFilterComposer,
          $$ProviderRefreshRunsTableOrderingComposer,
          $$ProviderRefreshRunsTableAnnotationComposer,
          $$ProviderRefreshRunsTableCreateCompanionBuilder,
          $$ProviderRefreshRunsTableUpdateCompanionBuilder,
          (ProviderRefreshRunRow, $$ProviderRefreshRunsTableReferences),
          ProviderRefreshRunRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$ProviderRefreshRunsTableTableManager(
    _$CatalogDatabase db,
    $ProviderRefreshRunsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderRefreshRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderRefreshRunsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProviderRefreshRunsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderRefreshRunsCompanion(
                id: id,
                providerId: providerId,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                itemCount: itemCount,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String providerId,
                required String status,
                Value<int> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderRefreshRunsCompanion.insert(
                id: id,
                providerId: providerId,
                status: status,
                startedAt: startedAt,
                finishedAt: finishedAt,
                itemCount: itemCount,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProviderRefreshRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable:
                                    $$ProviderRefreshRunsTableReferences
                                        ._providerIdTable(db),
                                referencedColumn:
                                    $$ProviderRefreshRunsTableReferences
                                        ._providerIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProviderRefreshRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $ProviderRefreshRunsTable,
      ProviderRefreshRunRow,
      $$ProviderRefreshRunsTableFilterComposer,
      $$ProviderRefreshRunsTableOrderingComposer,
      $$ProviderRefreshRunsTableAnnotationComposer,
      $$ProviderRefreshRunsTableCreateCompanionBuilder,
      $$ProviderRefreshRunsTableUpdateCompanionBuilder,
      (ProviderRefreshRunRow, $$ProviderRefreshRunsTableReferences),
      ProviderRefreshRunRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String providerId,
      required String contentType,
      Value<String?> externalId,
      required String name,
      required String normalizedName,
      Value<int> itemCount,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> providerId,
      Value<String> contentType,
      Value<String?> externalId,
      Value<String> name,
      Value<String> normalizedName,
      Value<int> itemCount,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$CatalogDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(db.categories.providerId, db.catalogProviders.id),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$CatalogDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$CatalogDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStale =>
      $composableBuilder(column: $table.isStale, builder: (column) => column);

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$CategoriesTableTableManager(_$CatalogDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                providerId: providerId,
                contentType: contentType,
                externalId: externalId,
                name: name,
                normalizedName: normalizedName,
                itemCount: itemCount,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String providerId,
                required String contentType,
                Value<String?> externalId = const Value.absent(),
                required String name,
                required String normalizedName,
                Value<int> itemCount = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                providerId: providerId,
                contentType: contentType,
                externalId: externalId,
                name: name,
                normalizedName: normalizedName,
                itemCount: itemCount,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$CategoriesTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$CategoriesTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$CatalogItemsTableCreateCompanionBuilder =
    CatalogItemsCompanion Function({
      required String id,
      required String providerId,
      required String contentType,
      Value<String?> categoryId,
      required String title,
      required String normalizedTitle,
      Value<String?> subtitle,
      Value<String?> description,
      Value<String?> artworkUrl,
      Value<String?> streamUrl,
      Value<String?> streamJson,
      Value<String?> externalId,
      Value<int?> year,
      Value<String?> rating,
      Value<int?> durationSeconds,
      Value<String?> epgChannelId,
      Value<String?> containerExtension,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });
typedef $$CatalogItemsTableUpdateCompanionBuilder =
    CatalogItemsCompanion Function({
      Value<String> id,
      Value<String> providerId,
      Value<String> contentType,
      Value<String?> categoryId,
      Value<String> title,
      Value<String> normalizedTitle,
      Value<String?> subtitle,
      Value<String?> description,
      Value<String?> artworkUrl,
      Value<String?> streamUrl,
      Value<String?> streamJson,
      Value<String?> externalId,
      Value<int?> year,
      Value<String?> rating,
      Value<int?> durationSeconds,
      Value<String?> epgChannelId,
      Value<String?> containerExtension,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });

final class $$CatalogItemsTableReferences
    extends
        BaseReferences<_$CatalogDatabase, $CatalogItemsTable, CatalogItemRow> {
  $$CatalogItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(
          db.catalogItems.providerId,
          db.catalogProviders.id,
        ),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CatalogItemsTableFilterComposer
    extends Composer<_$CatalogDatabase, $CatalogItemsTable> {
  $$CatalogItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamJson => $composableBuilder(
    column: $table.streamJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogItemsTableOrderingComposer
    extends Composer<_$CatalogDatabase, $CatalogItemsTable> {
  $$CatalogItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamJson => $composableBuilder(
    column: $table.streamJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogItemsTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $CatalogItemsTable> {
  $$CatalogItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumn<String> get streamJson => $composableBuilder(
    column: $table.streamJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStale =>
      $composableBuilder(column: $table.isStale, builder: (column) => column);

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogItemsTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $CatalogItemsTable,
          CatalogItemRow,
          $$CatalogItemsTableFilterComposer,
          $$CatalogItemsTableOrderingComposer,
          $$CatalogItemsTableAnnotationComposer,
          $$CatalogItemsTableCreateCompanionBuilder,
          $$CatalogItemsTableUpdateCompanionBuilder,
          (CatalogItemRow, $$CatalogItemsTableReferences),
          CatalogItemRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$CatalogItemsTableTableManager(
    _$CatalogDatabase db,
    $CatalogItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> normalizedTitle = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> streamUrl = const Value.absent(),
                Value<String?> streamJson = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogItemsCompanion(
                id: id,
                providerId: providerId,
                contentType: contentType,
                categoryId: categoryId,
                title: title,
                normalizedTitle: normalizedTitle,
                subtitle: subtitle,
                description: description,
                artworkUrl: artworkUrl,
                streamUrl: streamUrl,
                streamJson: streamJson,
                externalId: externalId,
                year: year,
                rating: rating,
                durationSeconds: durationSeconds,
                epgChannelId: epgChannelId,
                containerExtension: containerExtension,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String providerId,
                required String contentType,
                Value<String?> categoryId = const Value.absent(),
                required String title,
                required String normalizedTitle,
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> streamUrl = const Value.absent(),
                Value<String?> streamJson = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> rating = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogItemsCompanion.insert(
                id: id,
                providerId: providerId,
                contentType: contentType,
                categoryId: categoryId,
                title: title,
                normalizedTitle: normalizedTitle,
                subtitle: subtitle,
                description: description,
                artworkUrl: artworkUrl,
                streamUrl: streamUrl,
                streamJson: streamJson,
                externalId: externalId,
                year: year,
                rating: rating,
                durationSeconds: durationSeconds,
                epgChannelId: epgChannelId,
                containerExtension: containerExtension,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CatalogItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$CatalogItemsTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$CatalogItemsTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CatalogItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $CatalogItemsTable,
      CatalogItemRow,
      $$CatalogItemsTableFilterComposer,
      $$CatalogItemsTableOrderingComposer,
      $$CatalogItemsTableAnnotationComposer,
      $$CatalogItemsTableCreateCompanionBuilder,
      $$CatalogItemsTableUpdateCompanionBuilder,
      (CatalogItemRow, $$CatalogItemsTableReferences),
      CatalogItemRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$SeriesTableCreateCompanionBuilder =
    SeriesCompanion Function({
      required String id,
      required String providerId,
      Value<String?> catalogItemId,
      Value<String?> externalId,
      required String title,
      required String normalizedTitle,
      Value<String?> overview,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<int> updatedAt,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });
typedef $$SeriesTableUpdateCompanionBuilder =
    SeriesCompanion Function({
      Value<String> id,
      Value<String> providerId,
      Value<String?> catalogItemId,
      Value<String?> externalId,
      Value<String> title,
      Value<String> normalizedTitle,
      Value<String?> overview,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<int> updatedAt,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });

final class $$SeriesTableReferences
    extends BaseReferences<_$CatalogDatabase, $SeriesTable, SeriesRow> {
  $$SeriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(db.series.providerId, db.catalogProviders.id),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SeriesTableFilterComposer
    extends Composer<_$CatalogDatabase, $SeriesTable> {
  $$SeriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogItemId => $composableBuilder(
    column: $table.catalogItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdropUrl => $composableBuilder(
    column: $table.backdropUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesTableOrderingComposer
    extends Composer<_$CatalogDatabase, $SeriesTable> {
  $$SeriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogItemId => $composableBuilder(
    column: $table.catalogItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdropUrl => $composableBuilder(
    column: $table.backdropUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $SeriesTable> {
  $$SeriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get catalogItemId => $composableBuilder(
    column: $table.catalogItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl => $composableBuilder(
    column: $table.backdropUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStale =>
      $composableBuilder(column: $table.isStale, builder: (column) => column);

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $SeriesTable,
          SeriesRow,
          $$SeriesTableFilterComposer,
          $$SeriesTableOrderingComposer,
          $$SeriesTableAnnotationComposer,
          $$SeriesTableCreateCompanionBuilder,
          $$SeriesTableUpdateCompanionBuilder,
          (SeriesRow, $$SeriesTableReferences),
          SeriesRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$SeriesTableTableManager(_$CatalogDatabase db, $SeriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String?> catalogItemId = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> normalizedTitle = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesCompanion(
                id: id,
                providerId: providerId,
                catalogItemId: catalogItemId,
                externalId: externalId,
                title: title,
                normalizedTitle: normalizedTitle,
                overview: overview,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                updatedAt: updatedAt,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String providerId,
                Value<String?> catalogItemId = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                required String title,
                required String normalizedTitle,
                Value<String?> overview = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesCompanion.insert(
                id: id,
                providerId: providerId,
                catalogItemId: catalogItemId,
                externalId: externalId,
                title: title,
                normalizedTitle: normalizedTitle,
                overview: overview,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                updatedAt: updatedAt,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SeriesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$SeriesTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$SeriesTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SeriesTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $SeriesTable,
      SeriesRow,
      $$SeriesTableFilterComposer,
      $$SeriesTableOrderingComposer,
      $$SeriesTableAnnotationComposer,
      $$SeriesTableCreateCompanionBuilder,
      $$SeriesTableUpdateCompanionBuilder,
      (SeriesRow, $$SeriesTableReferences),
      SeriesRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$SeasonsTableCreateCompanionBuilder =
    SeasonsCompanion Function({
      required String id,
      required String providerId,
      required String seriesId,
      required int seasonNumber,
      Value<String?> title,
      Value<String?> overview,
      Value<String?> posterUrl,
      Value<int> updatedAt,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });
typedef $$SeasonsTableUpdateCompanionBuilder =
    SeasonsCompanion Function({
      Value<String> id,
      Value<String> providerId,
      Value<String> seriesId,
      Value<int> seasonNumber,
      Value<String?> title,
      Value<String?> overview,
      Value<String?> posterUrl,
      Value<int> updatedAt,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });

final class $$SeasonsTableReferences
    extends BaseReferences<_$CatalogDatabase, $SeasonsTable, SeasonRow> {
  $$SeasonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(db.seasons.providerId, db.catalogProviders.id),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SeasonsTableFilterComposer
    extends Composer<_$CatalogDatabase, $SeasonsTable> {
  $$SeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeasonsTableOrderingComposer
    extends Composer<_$CatalogDatabase, $SeasonsTable> {
  $$SeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeasonsTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $SeasonsTable> {
  $$SeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStale =>
      $composableBuilder(column: $table.isStale, builder: (column) => column);

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeasonsTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $SeasonsTable,
          SeasonRow,
          $$SeasonsTableFilterComposer,
          $$SeasonsTableOrderingComposer,
          $$SeasonsTableAnnotationComposer,
          $$SeasonsTableCreateCompanionBuilder,
          $$SeasonsTableUpdateCompanionBuilder,
          (SeasonRow, $$SeasonsTableReferences),
          SeasonRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$SeasonsTableTableManager(_$CatalogDatabase db, $SeasonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeasonsCompanion(
                id: id,
                providerId: providerId,
                seriesId: seriesId,
                seasonNumber: seasonNumber,
                title: title,
                overview: overview,
                posterUrl: posterUrl,
                updatedAt: updatedAt,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String providerId,
                required String seriesId,
                required int seasonNumber,
                Value<String?> title = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeasonsCompanion.insert(
                id: id,
                providerId: providerId,
                seriesId: seriesId,
                seasonNumber: seasonNumber,
                title: title,
                overview: overview,
                posterUrl: posterUrl,
                updatedAt: updatedAt,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SeasonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$SeasonsTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$SeasonsTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $SeasonsTable,
      SeasonRow,
      $$SeasonsTableFilterComposer,
      $$SeasonsTableOrderingComposer,
      $$SeasonsTableAnnotationComposer,
      $$SeasonsTableCreateCompanionBuilder,
      $$SeasonsTableUpdateCompanionBuilder,
      (SeasonRow, $$SeasonsTableReferences),
      SeasonRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$EpisodesTableCreateCompanionBuilder =
    EpisodesCompanion Function({
      required String id,
      required String providerId,
      required String seriesId,
      required String seasonId,
      required int seasonNumber,
      required int episodeNumber,
      required String title,
      required String normalizedTitle,
      Value<String?> description,
      Value<String?> artworkUrl,
      Value<String?> streamUrl,
      Value<String?> streamJson,
      Value<String?> externalId,
      Value<int?> durationSeconds,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });
typedef $$EpisodesTableUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<String> id,
      Value<String> providerId,
      Value<String> seriesId,
      Value<String> seasonId,
      Value<int> seasonNumber,
      Value<int> episodeNumber,
      Value<String> title,
      Value<String> normalizedTitle,
      Value<String?> description,
      Value<String?> artworkUrl,
      Value<String?> streamUrl,
      Value<String?> streamJson,
      Value<String?> externalId,
      Value<int?> durationSeconds,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> lastSeenAt,
      Value<bool> isStale,
      Value<int> rowid,
    });

final class $$EpisodesTableReferences
    extends BaseReferences<_$CatalogDatabase, $EpisodesTable, EpisodeRow> {
  $$EpisodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(db.episodes.providerId, db.catalogProviders.id),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpisodesTableFilterComposer
    extends Composer<_$CatalogDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamJson => $composableBuilder(
    column: $table.streamJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$CatalogDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamUrl => $composableBuilder(
    column: $table.streamUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamJson => $composableBuilder(
    column: $table.streamJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isStale => $composableBuilder(
    column: $table.isStale,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get normalizedTitle => $composableBuilder(
    column: $table.normalizedTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streamUrl =>
      $composableBuilder(column: $table.streamUrl, builder: (column) => column);

  GeneratedColumn<String> get streamJson => $composableBuilder(
    column: $table.streamJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isStale =>
      $composableBuilder(column: $table.isStale, builder: (column) => column);

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $EpisodesTable,
          EpisodeRow,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (EpisodeRow, $$EpisodesTableReferences),
          EpisodeRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$EpisodesTableTableManager(_$CatalogDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> seasonId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> normalizedTitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> streamUrl = const Value.absent(),
                Value<String?> streamJson = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion(
                id: id,
                providerId: providerId,
                seriesId: seriesId,
                seasonId: seasonId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                title: title,
                normalizedTitle: normalizedTitle,
                description: description,
                artworkUrl: artworkUrl,
                streamUrl: streamUrl,
                streamJson: streamJson,
                externalId: externalId,
                durationSeconds: durationSeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String providerId,
                required String seriesId,
                required String seasonId,
                required int seasonNumber,
                required int episodeNumber,
                required String title,
                required String normalizedTitle,
                Value<String?> description = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> streamUrl = const Value.absent(),
                Value<String?> streamJson = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> lastSeenAt = const Value.absent(),
                Value<bool> isStale = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion.insert(
                id: id,
                providerId: providerId,
                seriesId: seriesId,
                seasonId: seasonId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                title: title,
                normalizedTitle: normalizedTitle,
                description: description,
                artworkUrl: artworkUrl,
                streamUrl: streamUrl,
                streamJson: streamJson,
                externalId: externalId,
                durationSeconds: durationSeconds,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastSeenAt: lastSeenAt,
                isStale: isStale,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpisodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$EpisodesTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$EpisodesTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $EpisodesTable,
      EpisodeRow,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (EpisodeRow, $$EpisodesTableReferences),
      EpisodeRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$FavoriteItemsTableCreateCompanionBuilder =
    FavoriteItemsCompanion Function({
      required String catalogKey,
      required String itemId,
      required String itemType,
      required String providerId,
      Value<String?> seriesId,
      Value<String?> seasonId,
      Value<int> createdAt,
      Value<int> rowid,
    });
typedef $$FavoriteItemsTableUpdateCompanionBuilder =
    FavoriteItemsCompanion Function({
      Value<String> catalogKey,
      Value<String> itemId,
      Value<String> itemType,
      Value<String> providerId,
      Value<String?> seriesId,
      Value<String?> seasonId,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$FavoriteItemsTableReferences
    extends
        BaseReferences<
          _$CatalogDatabase,
          $FavoriteItemsTable,
          FavoriteItemRow
        > {
  $$FavoriteItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(
          db.favoriteItems.providerId,
          db.catalogProviders.id,
        ),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoriteItemsTableFilterComposer
    extends Composer<_$CatalogDatabase, $FavoriteItemsTable> {
  $$FavoriteItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get catalogKey => $composableBuilder(
    column: $table.catalogKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteItemsTableOrderingComposer
    extends Composer<_$CatalogDatabase, $FavoriteItemsTable> {
  $$FavoriteItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get catalogKey => $composableBuilder(
    column: $table.catalogKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteItemsTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $FavoriteItemsTable> {
  $$FavoriteItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get catalogKey => $composableBuilder(
    column: $table.catalogKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteItemsTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $FavoriteItemsTable,
          FavoriteItemRow,
          $$FavoriteItemsTableFilterComposer,
          $$FavoriteItemsTableOrderingComposer,
          $$FavoriteItemsTableAnnotationComposer,
          $$FavoriteItemsTableCreateCompanionBuilder,
          $$FavoriteItemsTableUpdateCompanionBuilder,
          (FavoriteItemRow, $$FavoriteItemsTableReferences),
          FavoriteItemRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$FavoriteItemsTableTableManager(
    _$CatalogDatabase db,
    $FavoriteItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> catalogKey = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoriteItemsCompanion(
                catalogKey: catalogKey,
                itemId: itemId,
                itemType: itemType,
                providerId: providerId,
                seriesId: seriesId,
                seasonId: seasonId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String catalogKey,
                required String itemId,
                required String itemType,
                required String providerId,
                Value<String?> seriesId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoriteItemsCompanion.insert(
                catalogKey: catalogKey,
                itemId: itemId,
                itemType: itemType,
                providerId: providerId,
                seriesId: seriesId,
                seasonId: seasonId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FavoriteItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$FavoriteItemsTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$FavoriteItemsTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoriteItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $FavoriteItemsTable,
      FavoriteItemRow,
      $$FavoriteItemsTableFilterComposer,
      $$FavoriteItemsTableOrderingComposer,
      $$FavoriteItemsTableAnnotationComposer,
      $$FavoriteItemsTableCreateCompanionBuilder,
      $$FavoriteItemsTableUpdateCompanionBuilder,
      (FavoriteItemRow, $$FavoriteItemsTableReferences),
      FavoriteItemRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$FavoriteCategoriesTableCreateCompanionBuilder =
    FavoriteCategoriesCompanion Function({
      required String providerId,
      required String contentType,
      required String categoryId,
      Value<int> createdAt,
      Value<int> rowid,
    });
typedef $$FavoriteCategoriesTableUpdateCompanionBuilder =
    FavoriteCategoriesCompanion Function({
      Value<String> providerId,
      Value<String> contentType,
      Value<String> categoryId,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$FavoriteCategoriesTableReferences
    extends
        BaseReferences<
          _$CatalogDatabase,
          $FavoriteCategoriesTable,
          FavoriteCategoryRow
        > {
  $$FavoriteCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(
          db.favoriteCategories.providerId,
          db.catalogProviders.id,
        ),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoriteCategoriesTableFilterComposer
    extends Composer<_$CatalogDatabase, $FavoriteCategoriesTable> {
  $$FavoriteCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteCategoriesTableOrderingComposer
    extends Composer<_$CatalogDatabase, $FavoriteCategoriesTable> {
  $$FavoriteCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteCategoriesTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $FavoriteCategoriesTable> {
  $$FavoriteCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteCategoriesTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $FavoriteCategoriesTable,
          FavoriteCategoryRow,
          $$FavoriteCategoriesTableFilterComposer,
          $$FavoriteCategoriesTableOrderingComposer,
          $$FavoriteCategoriesTableAnnotationComposer,
          $$FavoriteCategoriesTableCreateCompanionBuilder,
          $$FavoriteCategoriesTableUpdateCompanionBuilder,
          (FavoriteCategoryRow, $$FavoriteCategoriesTableReferences),
          FavoriteCategoryRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$FavoriteCategoriesTableTableManager(
    _$CatalogDatabase db,
    $FavoriteCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoriteCategoriesCompanion(
                providerId: providerId,
                contentType: contentType,
                categoryId: categoryId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String contentType,
                required String categoryId,
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoriteCategoriesCompanion.insert(
                providerId: providerId,
                contentType: contentType,
                categoryId: categoryId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FavoriteCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable:
                                    $$FavoriteCategoriesTableReferences
                                        ._providerIdTable(db),
                                referencedColumn:
                                    $$FavoriteCategoriesTableReferences
                                        ._providerIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoriteCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $FavoriteCategoriesTable,
      FavoriteCategoryRow,
      $$FavoriteCategoriesTableFilterComposer,
      $$FavoriteCategoriesTableOrderingComposer,
      $$FavoriteCategoriesTableAnnotationComposer,
      $$FavoriteCategoriesTableCreateCompanionBuilder,
      $$FavoriteCategoriesTableUpdateCompanionBuilder,
      (FavoriteCategoryRow, $$FavoriteCategoriesTableReferences),
      FavoriteCategoryRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$CategoryOrderTableCreateCompanionBuilder =
    CategoryOrderCompanion Function({
      required String providerId,
      required String contentType,
      required String categoryId,
      required int sortOrder,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$CategoryOrderTableUpdateCompanionBuilder =
    CategoryOrderCompanion Function({
      Value<String> providerId,
      Value<String> contentType,
      Value<String> categoryId,
      Value<int> sortOrder,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$CategoryOrderTableReferences
    extends
        BaseReferences<
          _$CatalogDatabase,
          $CategoryOrderTable,
          CategoryOrderRow
        > {
  $$CategoryOrderTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(
          db.categoryOrder.providerId,
          db.catalogProviders.id,
        ),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CategoryOrderTableFilterComposer
    extends Composer<_$CatalogDatabase, $CategoryOrderTable> {
  $$CategoryOrderTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoryOrderTableOrderingComposer
    extends Composer<_$CatalogDatabase, $CategoryOrderTable> {
  $$CategoryOrderTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoryOrderTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $CategoryOrderTable> {
  $$CategoryOrderTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoryOrderTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $CategoryOrderTable,
          CategoryOrderRow,
          $$CategoryOrderTableFilterComposer,
          $$CategoryOrderTableOrderingComposer,
          $$CategoryOrderTableAnnotationComposer,
          $$CategoryOrderTableCreateCompanionBuilder,
          $$CategoryOrderTableUpdateCompanionBuilder,
          (CategoryOrderRow, $$CategoryOrderTableReferences),
          CategoryOrderRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$CategoryOrderTableTableManager(
    _$CatalogDatabase db,
    $CategoryOrderTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryOrderTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryOrderTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryOrderTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryOrderCompanion(
                providerId: providerId,
                contentType: contentType,
                categoryId: categoryId,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String contentType,
                required String categoryId,
                required int sortOrder,
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryOrderCompanion.insert(
                providerId: providerId,
                contentType: contentType,
                categoryId: categoryId,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoryOrderTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$CategoryOrderTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$CategoryOrderTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoryOrderTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $CategoryOrderTable,
      CategoryOrderRow,
      $$CategoryOrderTableFilterComposer,
      $$CategoryOrderTableOrderingComposer,
      $$CategoryOrderTableAnnotationComposer,
      $$CategoryOrderTableCreateCompanionBuilder,
      $$CategoryOrderTableUpdateCompanionBuilder,
      (CategoryOrderRow, $$CategoryOrderTableReferences),
      CategoryOrderRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$WatchHistoryTableCreateCompanionBuilder =
    WatchHistoryCompanion Function({
      required String catalogKey,
      required String itemId,
      required String itemType,
      required String providerId,
      required String title,
      Value<String?> subtitle,
      Value<String?> artworkUrl,
      Value<String?> seriesId,
      Value<String?> seasonId,
      Value<int> positionSeconds,
      Value<int?> durationSeconds,
      Value<bool> completed,
      Value<int> lastWatchedAt,
      Value<int> watchCount,
      Value<int> rowid,
    });
typedef $$WatchHistoryTableUpdateCompanionBuilder =
    WatchHistoryCompanion Function({
      Value<String> catalogKey,
      Value<String> itemId,
      Value<String> itemType,
      Value<String> providerId,
      Value<String> title,
      Value<String?> subtitle,
      Value<String?> artworkUrl,
      Value<String?> seriesId,
      Value<String?> seasonId,
      Value<int> positionSeconds,
      Value<int?> durationSeconds,
      Value<bool> completed,
      Value<int> lastWatchedAt,
      Value<int> watchCount,
      Value<int> rowid,
    });

final class $$WatchHistoryTableReferences
    extends
        BaseReferences<_$CatalogDatabase, $WatchHistoryTable, WatchHistoryRow> {
  $$WatchHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(
          db.watchHistory.providerId,
          db.catalogProviders.id,
        ),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WatchHistoryTableFilterComposer
    extends Composer<_$CatalogDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get catalogKey => $composableBuilder(
    column: $table.catalogKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get watchCount => $composableBuilder(
    column: $table.watchCount,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableOrderingComposer
    extends Composer<_$CatalogDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get catalogKey => $composableBuilder(
    column: $table.catalogKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get watchCount => $composableBuilder(
    column: $table.watchCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get catalogKey => $composableBuilder(
    column: $table.catalogKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get watchCount => $composableBuilder(
    column: $table.watchCount,
    builder: (column) => column,
  );

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $WatchHistoryTable,
          WatchHistoryRow,
          $$WatchHistoryTableFilterComposer,
          $$WatchHistoryTableOrderingComposer,
          $$WatchHistoryTableAnnotationComposer,
          $$WatchHistoryTableCreateCompanionBuilder,
          $$WatchHistoryTableUpdateCompanionBuilder,
          (WatchHistoryRow, $$WatchHistoryTableReferences),
          WatchHistoryRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$WatchHistoryTableTableManager(
    _$CatalogDatabase db,
    $WatchHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> catalogKey = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<int> positionSeconds = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> lastWatchedAt = const Value.absent(),
                Value<int> watchCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchHistoryCompanion(
                catalogKey: catalogKey,
                itemId: itemId,
                itemType: itemType,
                providerId: providerId,
                title: title,
                subtitle: subtitle,
                artworkUrl: artworkUrl,
                seriesId: seriesId,
                seasonId: seasonId,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                completed: completed,
                lastWatchedAt: lastWatchedAt,
                watchCount: watchCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String catalogKey,
                required String itemId,
                required String itemType,
                required String providerId,
                required String title,
                Value<String?> subtitle = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<int> positionSeconds = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> lastWatchedAt = const Value.absent(),
                Value<int> watchCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchHistoryCompanion.insert(
                catalogKey: catalogKey,
                itemId: itemId,
                itemType: itemType,
                providerId: providerId,
                title: title,
                subtitle: subtitle,
                artworkUrl: artworkUrl,
                seriesId: seriesId,
                seasonId: seasonId,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                completed: completed,
                lastWatchedAt: lastWatchedAt,
                watchCount: watchCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WatchHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$WatchHistoryTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$WatchHistoryTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WatchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $WatchHistoryTable,
      WatchHistoryRow,
      $$WatchHistoryTableFilterComposer,
      $$WatchHistoryTableOrderingComposer,
      $$WatchHistoryTableAnnotationComposer,
      $$WatchHistoryTableCreateCompanionBuilder,
      $$WatchHistoryTableUpdateCompanionBuilder,
      (WatchHistoryRow, $$WatchHistoryTableReferences),
      WatchHistoryRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$PlaybackPositionsTableCreateCompanionBuilder =
    PlaybackPositionsCompanion Function({
      required String providerId,
      required String catalogKey,
      required String itemId,
      required String itemType,
      Value<String?> seriesId,
      Value<String?> seasonId,
      Value<int> positionSeconds,
      Value<int?> durationSeconds,
      Value<bool> completed,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$PlaybackPositionsTableUpdateCompanionBuilder =
    PlaybackPositionsCompanion Function({
      Value<String> providerId,
      Value<String> catalogKey,
      Value<String> itemId,
      Value<String> itemType,
      Value<String?> seriesId,
      Value<String?> seasonId,
      Value<int> positionSeconds,
      Value<int?> durationSeconds,
      Value<bool> completed,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$PlaybackPositionsTableReferences
    extends
        BaseReferences<
          _$CatalogDatabase,
          $PlaybackPositionsTable,
          PlaybackPositionRow
        > {
  $$PlaybackPositionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CatalogProvidersTable _providerIdTable(_$CatalogDatabase db) =>
      db.catalogProviders.createAlias(
        $_aliasNameGenerator(
          db.playbackPositions.providerId,
          db.catalogProviders.id,
        ),
      );

  $$CatalogProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$CatalogProvidersTableTableManager(
      $_db,
      $_db.catalogProviders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaybackPositionsTableFilterComposer
    extends Composer<_$CatalogDatabase, $PlaybackPositionsTable> {
  $$PlaybackPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get catalogKey => $composableBuilder(
    column: $table.catalogKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProvidersTableFilterComposer get providerId {
    final $$CatalogProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableFilterComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackPositionsTableOrderingComposer
    extends Composer<_$CatalogDatabase, $PlaybackPositionsTable> {
  $$PlaybackPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get catalogKey => $composableBuilder(
    column: $table.catalogKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seasonId => $composableBuilder(
    column: $table.seasonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProvidersTableOrderingComposer get providerId {
    final $$CatalogProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackPositionsTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $PlaybackPositionsTable> {
  $$PlaybackPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get catalogKey => $composableBuilder(
    column: $table.catalogKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get seasonId =>
      $composableBuilder(column: $table.seasonId, builder: (column) => column);

  GeneratedColumn<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CatalogProvidersTableAnnotationComposer get providerId {
    final $$CatalogProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.catalogProviders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProviders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackPositionsTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $PlaybackPositionsTable,
          PlaybackPositionRow,
          $$PlaybackPositionsTableFilterComposer,
          $$PlaybackPositionsTableOrderingComposer,
          $$PlaybackPositionsTableAnnotationComposer,
          $$PlaybackPositionsTableCreateCompanionBuilder,
          $$PlaybackPositionsTableUpdateCompanionBuilder,
          (PlaybackPositionRow, $$PlaybackPositionsTableReferences),
          PlaybackPositionRow,
          PrefetchHooks Function({bool providerId})
        > {
  $$PlaybackPositionsTableTableManager(
    _$CatalogDatabase db,
    $PlaybackPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackPositionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> catalogKey = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<int> positionSeconds = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackPositionsCompanion(
                providerId: providerId,
                catalogKey: catalogKey,
                itemId: itemId,
                itemType: itemType,
                seriesId: seriesId,
                seasonId: seasonId,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                completed: completed,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String catalogKey,
                required String itemId,
                required String itemType,
                Value<String?> seriesId = const Value.absent(),
                Value<String?> seasonId = const Value.absent(),
                Value<int> positionSeconds = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackPositionsCompanion.insert(
                providerId: providerId,
                catalogKey: catalogKey,
                itemId: itemId,
                itemType: itemType,
                seriesId: seriesId,
                seasonId: seasonId,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                completed: completed,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaybackPositionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable:
                                    $$PlaybackPositionsTableReferences
                                        ._providerIdTable(db),
                                referencedColumn:
                                    $$PlaybackPositionsTableReferences
                                        ._providerIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaybackPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $PlaybackPositionsTable,
      PlaybackPositionRow,
      $$PlaybackPositionsTableFilterComposer,
      $$PlaybackPositionsTableOrderingComposer,
      $$PlaybackPositionsTableAnnotationComposer,
      $$PlaybackPositionsTableCreateCompanionBuilder,
      $$PlaybackPositionsTableUpdateCompanionBuilder,
      (PlaybackPositionRow, $$PlaybackPositionsTableReferences),
      PlaybackPositionRow,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$CatalogDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$CatalogDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$CatalogDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$CatalogDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$CatalogDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;

class $CatalogDatabaseManager {
  final _$CatalogDatabase _db;
  $CatalogDatabaseManager(this._db);
  $$CatalogProvidersTableTableManager get catalogProviders =>
      $$CatalogProvidersTableTableManager(_db, _db.catalogProviders);
  $$ProviderRefreshRunsTableTableManager get providerRefreshRuns =>
      $$ProviderRefreshRunsTableTableManager(_db, _db.providerRefreshRuns);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$CatalogItemsTableTableManager get catalogItems =>
      $$CatalogItemsTableTableManager(_db, _db.catalogItems);
  $$SeriesTableTableManager get series =>
      $$SeriesTableTableManager(_db, _db.series);
  $$SeasonsTableTableManager get seasons =>
      $$SeasonsTableTableManager(_db, _db.seasons);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$FavoriteItemsTableTableManager get favoriteItems =>
      $$FavoriteItemsTableTableManager(_db, _db.favoriteItems);
  $$FavoriteCategoriesTableTableManager get favoriteCategories =>
      $$FavoriteCategoriesTableTableManager(_db, _db.favoriteCategories);
  $$CategoryOrderTableTableManager get categoryOrder =>
      $$CategoryOrderTableTableManager(_db, _db.categoryOrder);
  $$WatchHistoryTableTableManager get watchHistory =>
      $$WatchHistoryTableTableManager(_db, _db.watchHistory);
  $$PlaybackPositionsTableTableManager get playbackPositions =>
      $$PlaybackPositionsTableTableManager(_db, _db.playbackPositions);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
