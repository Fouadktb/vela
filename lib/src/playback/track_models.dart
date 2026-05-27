class PlaybackAudioTrack {
  const PlaybackAudioTrack({
    required this.id,
    required this.title,
    required this.language,
    required this.isSelected,
    required this.isExternal,
  });

  final String id;
  final String title;
  final String? language;
  final bool isSelected;
  final bool isExternal;
}

class PlaybackSubtitleTrack {
  const PlaybackSubtitleTrack({
    required this.id,
    required this.title,
    required this.language,
    required this.isSelected,
    required this.isExternal,
  });

  final String id;
  final String title;
  final String? language;
  final bool isSelected;
  final bool isExternal;
}

class PlaybackVideoTrack {
  const PlaybackVideoTrack({
    required this.id,
    required this.title,
    required this.language,
    required this.isSelected,
    required this.isExternal,
  });

  final String id;
  final String title;
  final String? language;
  final bool isSelected;
  final bool isExternal;
}
