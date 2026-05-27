import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class XtreamClient {
  XtreamClient({
    required XtreamCredentials credentials,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : credentials = credentials.normalized(),
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null;

  final XtreamCredentials credentials;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final Duration timeout;

  Future<Map<String, dynamic>> getPlayerApiInfo() async {
    final data = await _getJson();
    if (data is! Map<String, dynamic>) {
      throw const XtreamClientException(
        'Xtream server returned an unexpected response',
      );
    }
    _throwIfInvalidLogin(data);
    _throwIfErrorResponse(data);
    return data;
  }

  Future<List<XtreamCategory>> getLiveCategories() {
    return _getCategories('get_live_categories');
  }

  Future<List<XtreamLiveStream>> getLiveStreams() async {
    final data = await _getJson(action: 'get_live_streams');
    _throwIfInvalidLogin(data);
    _throwIfErrorResponse(data);
    if (data is! List) {
      throw const XtreamClientException(
        'Xtream server returned an unexpected response',
      );
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(XtreamLiveStream.fromJson)
        .toList();
  }

  Future<List<XtreamCategory>> getVodCategories() {
    return _getCategories('get_vod_categories');
  }

  Future<List<XtreamVodStream>> getVodStreams() async {
    final data = await _getJson(action: 'get_vod_streams');
    _throwIfInvalidLogin(data);
    _throwIfErrorResponse(data);
    if (data is! List) {
      throw const XtreamClientException(
        'Xtream server returned an unexpected response',
      );
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(XtreamVodStream.fromJson)
        .toList();
  }

  Future<List<XtreamCategory>> getSeriesCategories() {
    return _getCategories('get_series_categories');
  }

  Future<List<XtreamSeriesItem>> getSeries() async {
    final data = await _getJson(action: 'get_series');
    _throwIfInvalidLogin(data);
    _throwIfErrorResponse(data);
    if (data is! List) {
      throw const XtreamClientException(
        'Xtream server returned an unexpected response',
      );
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(XtreamSeriesItem.fromJson)
        .toList();
  }

  Future<XtreamSeriesInfo> getSeriesInfo(String seriesId) async {
    final data = await _getJson(
      action: 'get_series_info',
      extraParams: {'series_id': seriesId},
    );
    if (data is! Map<String, dynamic>) {
      throw const XtreamClientException(
        'Xtream server returned an unexpected response',
      );
    }
    _throwIfInvalidLogin(data);
    _throwIfErrorResponse(data);
    _validateSeriesInfoResponse(data);
    return XtreamSeriesInfo.fromJson(data);
  }

  String buildLiveStreamUrl(
    String streamId, {
    String containerExtension = 'ts',
  }) {
    return _buildStreamUrl('live', streamId, containerExtension);
  }

  String buildMovieStreamUrl(
    String streamId, {
    String containerExtension = 'mp4',
  }) {
    return _buildStreamUrl('movie', streamId, containerExtension);
  }

  String buildSeriesStreamUrl(
    String streamId, {
    String containerExtension = 'mp4',
  }) {
    return _buildStreamUrl('series', streamId, containerExtension);
  }

  Uri buildApiUri({
    String? action,
    Map<String, String> extraParams = const {},
  }) {
    final uri = Uri.parse(credentials.serverUrl);
    final query = <String, String>{
      'username': credentials.username,
      'password': credentials.password,
      ...extraParams,
    };
    if (action != null) {
      query['action'] = action;
    }
    return uri.replace(
      pathSegments: [..._basePathSegments(uri), 'player_api.php'],
      queryParameters: query,
    );
  }

  void close() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<List<XtreamCategory>> _getCategories(String action) async {
    final data = await _getJson(action: action);
    _throwIfInvalidLogin(data);
    _throwIfErrorResponse(data);
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(XtreamCategory.fromJson)
        .toList();
  }

  Future<dynamic> _getJson({
    String? action,
    Map<String, String> extraParams = const {},
  }) async {
    final uri = buildApiUri(action: action, extraParams: extraParams);
    late http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const XtreamClientException('Xtream server could not be reached');
    } on http.ClientException {
      throw const XtreamClientException('Xtream server could not be reached');
    } catch (_) {
      throw const XtreamClientException('Xtream server could not be reached');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw XtreamClientException(
        'Provider server rejected the Xtream API request with HTTP ${response.statusCode}',
      );
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw const XtreamClientException(
        'Xtream server returned an unexpected response',
      );
    }
  }

  String _buildStreamUrl(
    String contentPath,
    String streamId,
    String containerExtension,
  ) {
    final uri = Uri.parse(credentials.serverUrl);
    return uri
        .replace(
          pathSegments: [
            ..._basePathSegments(uri),
            contentPath,
            credentials.username,
            credentials.password,
            '$streamId.$containerExtension',
          ],
        )
        .toString();
  }
}

class XtreamCredentials {
  const XtreamCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  final String serverUrl;
  final String username;
  final String password;

  XtreamCredentials normalized() {
    return XtreamCredentials(
      serverUrl: normalizeXtreamServerUrl(serverUrl),
      username: username.trim(),
      password: password.trim(),
    );
  }

  @override
  String toString() {
    return 'XtreamCredentials('
        'serverUrl: ${serverUrl.isEmpty ? null : '<redacted>'}, '
        'username: ${username.isEmpty ? null : '<redacted>'}, '
        'password: ${password.isEmpty ? null : '<redacted>'}'
        ')';
  }
}

class XtreamClientException implements Exception {
  const XtreamClientException(this.message);

  final String message;

  @override
  String toString() => message;
}

class XtreamCategory {
  const XtreamCategory({required this.id, required this.name});

  factory XtreamCategory.fromJson(Map<String, dynamic> json) {
    return XtreamCategory(
      id: _stringValue(json['category_id']) ?? '',
      name: _stringValue(json['category_name']) ?? 'Uncategorized',
    );
  }

  final String id;
  final String name;

  bool get isValid => id.isNotEmpty && name.trim().isNotEmpty;
}

class XtreamLiveStream {
  const XtreamLiveStream({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.epgChannelId,
    this.categoryId,
    this.categoryName,
    this.containerExtension,
    this.directSource,
  });

  factory XtreamLiveStream.fromJson(Map<String, dynamic> json) {
    return XtreamLiveStream(
      streamId: _stringValue(json['stream_id']) ?? '',
      name: _stringValue(json['name']) ?? '',
      streamIcon: _httpUrlValue(json['stream_icon']),
      epgChannelId: _stringValue(json['epg_channel_id']),
      categoryId: _stringValue(json['category_id']),
      categoryName: _stringValue(json['category_name']),
      containerExtension: _containerExtension(json['container_extension']),
      directSource: _httpUrlValue(json['direct_source']),
    );
  }

  final String streamId;
  final String name;
  final String? streamIcon;
  final String? epgChannelId;
  final String? categoryId;
  final String? categoryName;
  final String? containerExtension;
  final String? directSource;
}

class XtreamVodStream {
  const XtreamVodStream({
    required this.streamId,
    required this.name,
    this.streamIcon,
    this.categoryId,
    this.containerExtension,
    this.rating,
    this.year,
    this.releaseDate,
    this.directSource,
  });

  factory XtreamVodStream.fromJson(Map<String, dynamic> json) {
    return XtreamVodStream(
      streamId: _stringValue(json['stream_id']) ?? '',
      name: _stringValue(json['name']) ?? '',
      streamIcon: _httpUrlValue(json['stream_icon']),
      categoryId: _stringValue(json['category_id']),
      containerExtension: _containerExtension(json['container_extension']),
      rating: _stringValue(json['rating']),
      year: _yearValue(json['year']),
      releaseDate: _yearValue(json['releaseDate']),
      directSource: _httpUrlValue(json['direct_source']),
    );
  }

  final String streamId;
  final String name;
  final String? streamIcon;
  final String? categoryId;
  final String? containerExtension;
  final String? rating;
  final int? year;
  final int? releaseDate;
  final String? directSource;
}

class XtreamSeriesItem {
  const XtreamSeriesItem({
    required this.seriesId,
    required this.name,
    this.cover,
    this.categoryId,
  });

  factory XtreamSeriesItem.fromJson(Map<String, dynamic> json) {
    return XtreamSeriesItem(
      seriesId: _stringValue(json['series_id']) ?? '',
      name: _stringValue(json['name']) ?? '',
      cover: _httpUrlValue(json['cover']),
      categoryId: _stringValue(json['category_id']),
    );
  }

  final String seriesId;
  final String name;
  final String? cover;
  final String? categoryId;
}

class XtreamSeriesInfo {
  const XtreamSeriesInfo({required this.seasons, required this.episodes});

  factory XtreamSeriesInfo.fromJson(Map<String, dynamic> json) {
    return XtreamSeriesInfo(
      seasons: _parseSeasons(json['seasons']),
      episodes: _parseEpisodes(json['episodes']),
    );
  }

  final List<XtreamSeason> seasons;
  final List<XtreamEpisode> episodes;
}

class XtreamSeason {
  const XtreamSeason({
    required this.seasonNumber,
    this.name,
    this.overview,
    this.cover,
  });

  factory XtreamSeason.fromJson(Map<String, dynamic> json) {
    return XtreamSeason(
      seasonNumber:
          _positiveInt(json['season_number']) ??
          _positiveInt(json['season']) ??
          _positiveInt(json['id']) ??
          1,
      name: _stringValue(json['name']),
      overview: _stringValue(json['overview']),
      cover: _httpUrlValue(json['cover']),
    );
  }

  final int seasonNumber;
  final String? name;
  final String? overview;
  final String? cover;
}

class XtreamEpisode {
  const XtreamEpisode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    this.containerExtension,
    this.durationSeconds,
    this.description,
    this.artworkUrl,
  });

  factory XtreamEpisode.fromJson(
    Map<String, dynamic> json, {
    required int fallbackSeasonNumber,
  }) {
    final info = json['info'] is Map<String, dynamic>
        ? json['info'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return XtreamEpisode(
      id: _stringValue(json['id']) ?? '',
      seasonNumber:
          _positiveInt(json['season']) ??
          _positiveInt(json['season_number']) ??
          fallbackSeasonNumber,
      episodeNumber: _positiveInt(json['episode_num']) ?? 0,
      title: _stringValue(json['title']) ?? '',
      containerExtension: _containerExtension(json['container_extension']),
      durationSeconds:
          _durationSeconds(info['duration_secs']) ??
          _durationSeconds(info['duration']),
      description:
          _stringValue(info['plot']) ?? _stringValue(info['description']),
      artworkUrl: _httpUrlValue(info['movie_image']),
    );
  }

  final String id;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String? containerExtension;
  final int? durationSeconds;
  final String? description;
  final String? artworkUrl;
}

String normalizeXtreamServerUrl(String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }
  final normalizedPath = uri.path.replaceAll(RegExp(r'/+$'), '');
  return uri
      .replace(path: normalizedPath, query: null, fragment: null)
      .toString()
      .replaceAll(RegExp(r'/+$'), '');
}

List<String> _basePathSegments(Uri uri) {
  return uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
}

void _throwIfInvalidLogin(dynamic data) {
  if (data is! Map<String, dynamic>) {
    return;
  }
  final userInfo = data['user_info'];
  if (userInfo is! Map<String, dynamic>) {
    return;
  }
  final auth = userInfo['auth'];
  final status = _stringValue(userInfo['status'])?.toLowerCase();
  if (auth == 0 || auth == '0' || status == 'disabled' || status == 'expired') {
    throw const XtreamClientException(
      'Xtream login failed. Check the username, password, server URL, and port.',
    );
  }
}

void _throwIfErrorResponse(dynamic data) {
  if (data is! Map<String, dynamic>) {
    return;
  }
  final error = _stringValue(data['error']) ?? _stringValue(data['message']);
  final result = data['result'];
  final success = data['success'];
  final status = _stringValue(data['status'])?.toLowerCase();
  if (error != null ||
      result == false ||
      result == 0 ||
      _isFalseText(result) ||
      success == false ||
      success == 0 ||
      _isFalseText(success) ||
      status == 'error' ||
      status == 'failed' ||
      status == 'failure') {
    throw const XtreamClientException(
      'Xtream server returned an error response',
    );
  }
}

void _validateSeriesInfoResponse(Map<String, dynamic> data) {
  if (!_hasMeaningfulEpisodes(data['episodes'])) {
    throw const XtreamClientException(
      'Xtream server returned incomplete series information',
    );
  }
}

bool _hasMeaningfulEpisodes(dynamic value) {
  if (value is List) {
    return value.any((episode) => episode is Map<String, dynamic>);
  }
  if (value is Map<String, dynamic>) {
    return value.values.any((seasonEpisodes) {
      return seasonEpisodes is List &&
          seasonEpisodes.any((episode) => episode is Map<String, dynamic>);
    });
  }
  return false;
}

bool _isFalseText(dynamic value) {
  final text = _stringValue(value)?.toLowerCase();
  return text == 'false' || text == '0';
}

List<XtreamSeason> _parseSeasons(dynamic value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(XtreamSeason.fromJson)
      .toList();
}

List<XtreamEpisode> _parseEpisodes(dynamic value) {
  final episodes = <XtreamEpisode>[];
  if (value is List) {
    for (final episode in value.whereType<Map<String, dynamic>>()) {
      episodes.add(XtreamEpisode.fromJson(episode, fallbackSeasonNumber: 1));
    }
    return episodes;
  }
  if (value is! Map<String, dynamic>) {
    return const [];
  }
  for (final entry in value.entries) {
    final rawSeason = entry.value;
    if (rawSeason is! List) {
      continue;
    }
    final fallbackSeason = _positiveInt(entry.key) ?? 1;
    for (final episode in rawSeason.whereType<Map<String, dynamic>>()) {
      episodes.add(
        XtreamEpisode.fromJson(episode, fallbackSeasonNumber: fallbackSeason),
      );
    }
  }
  return episodes;
}

String? _stringValue(dynamic value) {
  if (value is! String && value is! num) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _httpUrlValue(dynamic value) {
  final text = _stringValue(value);
  if (text == null) {
    return null;
  }
  final uri = Uri.tryParse(text);
  if (uri == null || !uri.hasScheme) {
    return null;
  }
  return uri.scheme == 'http' || uri.scheme == 'https' ? uri.toString() : null;
}

String? _containerExtension(dynamic value) {
  final text = _stringValue(value);
  if (text == null) {
    return null;
  }
  final normalized = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return normalized.isEmpty ? null : normalized;
}

int? _yearValue(dynamic value) {
  final text = _stringValue(value);
  if (text == null) {
    return null;
  }
  final match = RegExp(r'\b(19|20)\d{2}\b').firstMatch(text);
  return match == null ? null : int.parse(match.group(0)!);
}

int? _positiveInt(dynamic value) {
  final text = _stringValue(value);
  if (text == null) {
    return null;
  }
  final number = int.tryParse(text);
  return number != null && number > 0 ? number : null;
}

int? _durationSeconds(dynamic value) {
  final text = _stringValue(value);
  if (text == null) {
    return null;
  }
  final seconds = int.tryParse(text);
  if (seconds != null) {
    return seconds > 0 ? seconds : null;
  }
  final parts = text.split(':').map(int.tryParse).toList();
  if (parts.any((part) => part == null || part < 0)) {
    return null;
  }
  if (parts.length == 3) {
    return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
  }
  if (parts.length == 2) {
    return parts[0]! * 60 + parts[1]!;
  }
  return null;
}
