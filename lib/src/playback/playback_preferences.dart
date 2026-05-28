import 'dart:convert';

import '../app/navigation_controller.dart';
import 'playable_item.dart';
import 'track_models.dart';

class PlaybackPreferencesRepository {
  PlaybackPreferencesRepository(this._settings);

  final AppSettingsRepository _settings;

  Future<PlaybackTrackPreferences?> load(PlayableItem item) async {
    final settings = await _settings.watchSettings().first;
    final raw = settings[settingsKeyFor(item)];
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return PlaybackTrackPreferences.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> saveAudioTrack(PlayableItem item, PlaybackAudioTrack track) {
    return _save(
      item,
      (preferences) => preferences.copyWith(
        audio: PlaybackTrackPreference(
          id: track.id,
          title: track.title,
          language: track.language,
        ),
      ),
    );
  }

  Future<void> saveSubtitleTrack(
    PlayableItem item,
    PlaybackSubtitleTrack track,
  ) {
    return _save(
      item,
      (preferences) => preferences.copyWith(
        subtitle: PlaybackTrackPreference(
          id: track.id,
          title: track.title,
          language: track.language,
        ),
      ),
    );
  }

  Future<void> saveSubtitlesOff(PlayableItem item) {
    return _save(
      item,
      (preferences) => preferences.copyWith(
        subtitle: const PlaybackTrackPreference(id: 'no', title: 'Off'),
      ),
    );
  }

  Future<void> saveVideoTrack(PlayableItem item, PlaybackVideoTrack track) {
    return _save(
      item,
      (preferences) => preferences.copyWith(
        video: PlaybackTrackPreference(
          id: track.id,
          title: track.title,
          language: track.language,
        ),
      ),
    );
  }

  String settingsKeyFor(PlayableItem item) {
    return [
      'playback_track_preferences',
      item.providerId,
      item.kind.name,
      item.seriesId,
      item.seasonId,
      item.id,
    ].whereType<String>().map(_encodeKeyPart).join(':');
  }

  Future<void> _save(
    PlayableItem item,
    PlaybackTrackPreferences Function(PlaybackTrackPreferences preferences)
    update,
  ) async {
    final current = await load(item) ?? const PlaybackTrackPreferences();
    final next = update(current);
    await _settings.setValue(settingsKeyFor(item), jsonEncode(next.toJson()));
  }
}

class PlaybackTrackPreferences {
  const PlaybackTrackPreferences({this.audio, this.subtitle, this.video});

  factory PlaybackTrackPreferences.fromJson(Map<String, Object?> json) {
    return PlaybackTrackPreferences(
      audio: PlaybackTrackPreference.maybeFromJson(json['audio']),
      subtitle: PlaybackTrackPreference.maybeFromJson(json['subtitle']),
      video: PlaybackTrackPreference.maybeFromJson(json['video']),
    );
  }

  final PlaybackTrackPreference? audio;
  final PlaybackTrackPreference? subtitle;
  final PlaybackTrackPreference? video;

  bool get isEmpty => audio == null && subtitle == null && video == null;

  PlaybackTrackPreferences copyWith({
    PlaybackTrackPreference? audio,
    PlaybackTrackPreference? subtitle,
    PlaybackTrackPreference? video,
  }) {
    return PlaybackTrackPreferences(
      audio: audio ?? this.audio,
      subtitle: subtitle ?? this.subtitle,
      video: video ?? this.video,
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (audio != null) 'audio': audio!.toJson(),
      if (subtitle != null) 'subtitle': subtitle!.toJson(),
      if (video != null) 'video': video!.toJson(),
    };
  }
}

class PlaybackTrackPreference {
  const PlaybackTrackPreference({
    required this.id,
    required this.title,
    this.language,
  });

  static PlaybackTrackPreference? maybeFromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final id = value['id'];
    final title = value['title'];
    final language = value['language'];
    if (id is! String || title is! String) {
      return null;
    }
    return PlaybackTrackPreference(
      id: id,
      title: title,
      language: language is String ? language : null,
    );
  }

  final String id;
  final String title;
  final String? language;

  bool get isValid => id.isNotEmpty || title.isNotEmpty || language != null;
  bool get isSubtitlesOff => id == 'no' || id == 'off' || title == 'Off';

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      if (language != null) 'language': language,
    };
  }
}

PlaybackAudioTrack? resolvePreferredAudioTrack(
  List<PlaybackAudioTrack> tracks,
  PlaybackTrackPreference? preference,
) {
  if (preference == null || !preference.isValid) return null;
  return _resolvePreferredTrack(
    tracks,
    preference,
    idFor: (track) => track.id,
    titleFor: (track) => track.title,
    languageFor: (track) => track.language,
  );
}

PlaybackSubtitleTrack? resolvePreferredSubtitleTrack(
  List<PlaybackSubtitleTrack> tracks,
  PlaybackTrackPreference? preference,
) {
  if (preference == null || !preference.isValid || preference.isSubtitlesOff) {
    return null;
  }
  return _resolvePreferredTrack(
    tracks,
    preference,
    idFor: (track) => track.id,
    titleFor: (track) => track.title,
    languageFor: (track) => track.language,
  );
}

PlaybackVideoTrack? resolvePreferredVideoTrack(
  List<PlaybackVideoTrack> tracks,
  PlaybackTrackPreference? preference,
) {
  if (preference == null || !preference.isValid) return null;
  return _resolvePreferredTrack(
    tracks,
    preference,
    idFor: (track) => track.id,
    titleFor: (track) => track.title,
    languageFor: (track) => track.language,
  );
}

T? _resolvePreferredTrack<T>(
  List<T> tracks,
  PlaybackTrackPreference preference, {
  required String Function(T track) idFor,
  required String Function(T track) titleFor,
  required String? Function(T track) languageFor,
}) {
  for (final track in tracks) {
    if (idFor(track) == preference.id) return track;
  }

  for (final track in tracks) {
    if (_sameOptionalText(languageFor(track), preference.language) &&
        _sameRequiredText(titleFor(track), preference.title)) {
      return track;
    }
  }

  for (final track in tracks) {
    if (preference.language != null &&
        _sameOptionalText(languageFor(track), preference.language)) {
      return track;
    }
  }

  for (final track in tracks) {
    if (_sameRequiredText(titleFor(track), preference.title)) return track;
  }

  return null;
}

bool _sameRequiredText(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}

bool _sameOptionalText(String? left, String? right) {
  final normalizedLeft = left?.trim().toLowerCase();
  final normalizedRight = right?.trim().toLowerCase();
  return normalizedLeft != null &&
      normalizedLeft.isNotEmpty &&
      normalizedLeft == normalizedRight;
}

String _encodeKeyPart(String value) => Uri.encodeComponent(value);
