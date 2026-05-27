enum PlayableKind { live, movie, episode }

class PlayableItem {
  const PlayableItem({
    required this.id,
    required this.providerId,
    required this.title,
    required this.streamUrl,
    required this.kind,
    this.subtitle,
    this.posterUrl,
    this.channelLogoUrl,
    this.seriesId,
    this.seasonId,
    this.seasonNumber,
    this.episodeNumber,
    this.durationSeconds,
    this.resumePosition = Duration.zero,
    this.nextEpisode,
    this.episodeRailItems = const [],
  });

  final String id;
  final String providerId;
  final String title;
  final String? subtitle;
  final String streamUrl;
  final PlayableKind kind;
  final String? posterUrl;
  final String? channelLogoUrl;
  final String? seriesId;
  final String? seasonId;
  final int? seasonNumber;
  final int? episodeNumber;
  final int? durationSeconds;
  final Duration resumePosition;
  final PlayableItem? nextEpisode;
  final List<PlayableItem> episodeRailItems;

  bool get hasNextEpisode => nextEpisode != null;

  PlayableItem copyWith({
    String? id,
    String? providerId,
    String? title,
    String? subtitle,
    String? streamUrl,
    PlayableKind? kind,
    String? posterUrl,
    String? channelLogoUrl,
    String? seriesId,
    String? seasonId,
    int? seasonNumber,
    int? episodeNumber,
    int? durationSeconds,
    Duration? resumePosition,
    PlayableItem? nextEpisode,
    List<PlayableItem>? episodeRailItems,
  }) {
    return PlayableItem(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      streamUrl: streamUrl ?? this.streamUrl,
      kind: kind ?? this.kind,
      posterUrl: posterUrl ?? this.posterUrl,
      channelLogoUrl: channelLogoUrl ?? this.channelLogoUrl,
      seriesId: seriesId ?? this.seriesId,
      seasonId: seasonId ?? this.seasonId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      resumePosition: resumePosition ?? this.resumePosition,
      nextEpisode: nextEpisode ?? this.nextEpisode,
      episodeRailItems: episodeRailItems ?? this.episodeRailItems,
    );
  }
}
