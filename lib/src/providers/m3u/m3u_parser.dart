import '../../catalog/catalog_models.dart';

class M3uParser {
  const M3uParser();

  M3uParseResult parse(String input, {required String providerId}) {
    return parseLines(input.split(RegExp(r'\r?\n')), providerId: providerId);
  }

  M3uParseResult parseLines(
    Iterable<String> lines, {
    required String providerId,
    void Function(int line, int entries)? onProgress,
  }) {
    final diagnostics = <M3uParseDiagnostic>[];
    final entries = <M3uPlaylistEntry>[];
    final slugCounts = <String, int>{};
    _ExtInfDraft? pending;

    var lineNumber = 0;
    for (final rawLine in lines) {
      lineNumber += 1;
      pending = _parseLine(
        providerId: providerId,
        rawLine: rawLine,
        lineNumber: lineNumber,
        pending: pending,
        slugCounts: slugCounts,
        diagnostics: diagnostics,
        entries: entries,
      );
      if (lineNumber % 10000 == 0) {
        onProgress?.call(lineNumber, entries.length);
      }
    }

    if (pending != null) {
      diagnostics.add(
        M3uParseDiagnostic(
          line: pending.line,
          message: 'EXTINF entry has no following stream URL',
        ),
      );
    }

    return M3uParseResult(
      entries: entries,
      diagnostics: diagnostics,
      snapshot: _snapshotFor(providerId, entries),
    );
  }

  Future<M3uParseResult> parseStream(
    Stream<String> lines, {
    required String providerId,
    void Function(int line, int entries)? onProgress,
  }) async {
    final diagnostics = <M3uParseDiagnostic>[];
    final entries = <M3uPlaylistEntry>[];
    final slugCounts = <String, int>{};
    _ExtInfDraft? pending;
    var lineNumber = 0;

    await for (final rawLine in lines) {
      lineNumber += 1;
      pending = _parseLine(
        providerId: providerId,
        rawLine: rawLine,
        lineNumber: lineNumber,
        pending: pending,
        slugCounts: slugCounts,
        diagnostics: diagnostics,
        entries: entries,
      );
      if (lineNumber % 10000 == 0) {
        onProgress?.call(lineNumber, entries.length);
      }
    }

    if (pending != null) {
      diagnostics.add(
        M3uParseDiagnostic(
          line: pending.line,
          message: 'EXTINF entry has no following stream URL',
        ),
      );
    }
    onProgress?.call(lineNumber, entries.length);

    return M3uParseResult(
      entries: entries,
      diagnostics: diagnostics,
      snapshot: _snapshotFor(providerId, entries),
    );
  }
}

_ExtInfDraft? _parseLine({
  required String providerId,
  required String rawLine,
  required int lineNumber,
  required _ExtInfDraft? pending,
  required Map<String, int> slugCounts,
  required List<M3uParseDiagnostic> diagnostics,
  required List<M3uPlaylistEntry> entries,
}) {
  final line = (lineNumber == 1 ? rawLine.replaceFirst('\uFEFF', '') : rawLine)
      .trim();
  if (line.isEmpty || line == '#EXTM3U') {
    return pending;
  }

  if (line.startsWith('#EXTINF:')) {
    if (pending != null) {
      diagnostics.add(
        M3uParseDiagnostic(
          line: pending.line,
          message: 'EXTINF entry has no following stream URL',
        ),
      );
    }
    return _parseExtInf(line, lineNumber);
  }

  if (line.startsWith('#')) {
    return pending;
  }

  if (pending == null) {
    diagnostics.add(
      M3uParseDiagnostic(
        line: lineNumber,
        message: 'Stream URL has no preceding EXTINF metadata',
      ),
    );
    return null;
  }

  final slug = _allocateSlug(pending, slugCounts);
  final entry = _entryFromDraft(providerId, pending, line, slug);
  if (entry == null) {
    diagnostics.add(
      M3uParseDiagnostic(
        line: pending.line,
        message: 'EXTINF entry is missing a playable title or URL',
      ),
    );
  } else {
    entries.add(entry);
  }
  return null;
}

class M3uParseResult {
  const M3uParseResult({
    required this.entries,
    required this.diagnostics,
    required this.snapshot,
  });

  final List<M3uPlaylistEntry> entries;
  final List<M3uParseDiagnostic> diagnostics;
  final ProviderCatalogSnapshot snapshot;
}

class M3uParseDiagnostic {
  const M3uParseDiagnostic({required this.line, required this.message});

  final int line;
  final String message;
}

class M3uPlaylistEntry {
  const M3uPlaylistEntry({
    required this.id,
    required this.providerId,
    required this.contentType,
    required this.title,
    required this.streamUrl,
    required this.categoryName,
    this.logoUrl,
    this.epgChannelId,
    this.externalId,
    this.containerExtension,
    this.seriesTitle,
    this.seasonNumber,
    this.episodeNumber,
  });

  final String id;
  final String providerId;
  final CatalogContentType contentType;
  final String title;
  final String streamUrl;
  final String categoryName;
  final String? logoUrl;
  final String? epgChannelId;
  final String? externalId;
  final String? containerExtension;
  final String? seriesTitle;
  final int? seasonNumber;
  final int? episodeNumber;
}

class _ExtInfDraft {
  const _ExtInfDraft({
    required this.line,
    required this.name,
    required this.attributes,
  });

  final int line;
  final String name;
  final Map<String, String> attributes;
}

_ExtInfDraft _parseExtInf(String line, int lineNumber) {
  final commaIndex = _findExtInfNameDelimiter(line);
  final metadata = commaIndex >= 0 ? line.substring(0, commaIndex) : line;
  final name = commaIndex >= 0
      ? line.substring(commaIndex + 1).trim()
      : 'Unnamed Channel';
  final attributes = <String, String>{};
  final attributePattern = RegExp(r'([\w-]+)="([^"]*)"');
  for (final match in attributePattern.allMatches(metadata)) {
    attributes[match.group(1)!] = match.group(2) ?? '';
  }

  return _ExtInfDraft(
    line: lineNumber,
    name: name.isEmpty ? 'Unnamed Channel' : name,
    attributes: attributes,
  );
}

int _findExtInfNameDelimiter(String line) {
  var isQuoted = false;
  for (var index = 0; index < line.length; index += 1) {
    final char = line[index];
    if (char == '"') {
      isQuoted = !isQuoted;
      continue;
    }
    if (char == ',' && !isQuoted) {
      return index;
    }
  }
  return -1;
}

M3uPlaylistEntry? _entryFromDraft(
  String providerId,
  _ExtInfDraft draft,
  String url,
  String slug,
) {
  final streamUrl = url.trim();
  if (streamUrl.isEmpty) {
    return null;
  }
  final title = _firstNonEmpty([
    draft.attributes['tvg-name'],
    draft.attributes['title'],
    draft.name,
  ]);
  if (title == null) {
    return null;
  }
  final categoryName =
      _firstNonEmpty([draft.attributes['group-title']]) ?? 'Uncategorized';
  final episodeParts = _parseEpisodeParts(title);
  final contentType = _inferContentType(
    title: title,
    category: categoryName,
    url: streamUrl,
    hasEpisodeMetadata: episodeParts != null,
  );
  final itemId = '$providerId:${contentType.name}:$slug';

  return M3uPlaylistEntry(
    id: itemId,
    providerId: providerId,
    contentType: contentType,
    title: title,
    streamUrl: streamUrl,
    categoryName: categoryName,
    logoUrl: _firstNonEmpty([draft.attributes['tvg-logo']]),
    epgChannelId: _firstNonEmpty([draft.attributes['tvg-id']]),
    externalId: _firstNonEmpty([draft.attributes['tvg-id'], slug]),
    containerExtension: _containerExtensionFromUrl(streamUrl),
    seriesTitle: episodeParts?.seriesTitle,
    seasonNumber: episodeParts?.seasonNumber,
    episodeNumber: episodeParts?.episodeNumber,
  );
}

ProviderCatalogSnapshot _snapshotFor(
  String providerId,
  List<M3uPlaylistEntry> entries,
) {
  final categories = <String, CatalogCategoryInput>{};
  final items = <CatalogItemInput>[];
  final series = <String, SeriesInput>{};
  final seasons = <String, SeasonInput>{};
  final episodes = <EpisodeInput>[];

  for (final entry in entries) {
    categories[_categoryKey(
      entry.contentType,
      entry.categoryName,
    )] = CatalogCategoryInput(
      providerId: providerId,
      contentType: entry.contentType,
      name: entry.categoryName,
    );

    if (entry.contentType == CatalogContentType.series) {
      final seriesTitle = entry.seriesTitle ?? entry.title;
      final seriesSlug = _slugify(seriesTitle);
      final seriesItemId = '$providerId:series:$seriesSlug';
      categories[_categoryKey(
        CatalogContentType.series,
        entry.categoryName,
      )] = CatalogCategoryInput(
        providerId: providerId,
        contentType: CatalogContentType.series,
        name: entry.categoryName,
      );
      if (!items.any((item) => item.id == seriesItemId)) {
        items.add(
          CatalogItemInput(
            id: seriesItemId,
            providerId: providerId,
            contentType: CatalogContentType.series,
            title: seriesTitle,
            categoryName: entry.categoryName,
            artworkUrl: entry.logoUrl,
            externalId: seriesSlug,
          ),
        );
      }
      series[seriesItemId] = SeriesInput(
        id: seriesItemId,
        providerId: providerId,
        catalogItemId: seriesItemId,
        title: seriesTitle,
        posterUrl: entry.logoUrl,
      );
      final seasonNumber = entry.seasonNumber;
      final episodeNumber = entry.episodeNumber;
      if (seasonNumber != null && episodeNumber != null) {
        final seasonId = seasonNumber.toString();
        seasons['$seriesItemId:$seasonId'] = SeasonInput(
          id: seasonId,
          providerId: providerId,
          seriesId: seriesItemId,
          seasonNumber: seasonNumber,
          title: 'Season $seasonNumber',
        );
        episodes.add(
          EpisodeInput(
            id: entry.id,
            providerId: providerId,
            seriesId: seriesItemId,
            seasonId: seasonId,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            title: entry.title,
            artworkUrl: entry.logoUrl,
            streamUrl: entry.streamUrl,
            externalId: entry.externalId,
          ),
        );
      }
      continue;
    }

    items.add(
      CatalogItemInput(
        id: entry.id,
        providerId: providerId,
        contentType: entry.contentType,
        title: entry.title,
        categoryName: entry.categoryName,
        artworkUrl: entry.logoUrl,
        streamUrl: entry.streamUrl,
        externalId: entry.externalId,
        epgChannelId: entry.epgChannelId,
        containerExtension: entry.containerExtension,
      ),
    );
  }

  return ProviderCatalogSnapshot(
    providerId: providerId,
    categories: categories.values.toList(),
    items: items,
    series: series.values.toList(),
    seasons: seasons.values.toList(),
    episodes: episodes,
  );
}

CatalogContentType _inferContentType({
  required String title,
  required String category,
  required String url,
  required bool hasEpisodeMetadata,
}) {
  if (hasEpisodeMetadata) {
    return CatalogContentType.series;
  }

  final text = '$title $category $url'.toLowerCase();
  if (RegExp(r'\b(series|tv series)\b').hasMatch(text)) {
    return CatalogContentType.live;
  }
  if (RegExp(r'\b(movie|movies|vod|film|films|cinema)\b').hasMatch(text) ||
      RegExp(r'\.(mp4|mkv|avi|mov|m4v)(\?|$)').hasMatch(text)) {
    return CatalogContentType.movie;
  }
  return CatalogContentType.live;
}

_EpisodeParts? _parseEpisodeParts(String title) {
  final match = RegExp(
    r'^(.*?)\s*[-_. ]*s(\d{1,2})\s*e(\d{1,3})\b',
    caseSensitive: false,
  ).firstMatch(title);
  if (match == null) {
    return null;
  }
  final seriesTitle = match.group(1)?.trim();
  return _EpisodeParts(
    seriesTitle: seriesTitle == null || seriesTitle.isEmpty
        ? 'Series'
        : seriesTitle,
    seasonNumber: int.parse(match.group(2)!),
    episodeNumber: int.parse(match.group(3)!),
  );
}

class _EpisodeParts {
  const _EpisodeParts({
    required this.seriesTitle,
    required this.seasonNumber,
    required this.episodeNumber,
  });

  final String seriesTitle;
  final int seasonNumber;
  final int episodeNumber;
}

String _allocateSlug(_ExtInfDraft draft, Map<String, int> slugCounts) {
  final baseSlug = _slugify(
    _firstNonEmpty([draft.attributes['tvg-id'], draft.name]) ??
        'channel-${draft.line}',
  );
  final count = (slugCounts[baseSlug] ?? 0) + 1;
  slugCounts[baseSlug] = count;
  return count == 1 ? baseSlug : '$baseSlug-$count';
}

String _slugify(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) {
    return 'item';
  }
  return slug.length <= 80 ? slug : slug.substring(0, 80);
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final clean = value?.trim();
    if (clean != null && clean.isNotEmpty) {
      return clean;
    }
  }
  return null;
}

String? _containerExtensionFromUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  final match = RegExp(r'\.([a-z0-9]{2,5})$').firstMatch(path);
  return match?.group(1);
}

String _categoryKey(CatalogContentType contentType, String name) {
  return '${contentType.name}:${name.trim().toLowerCase()}';
}
