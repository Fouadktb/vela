enum PlayableKind { live, movie, episode }

class PlayableItem {
  const PlayableItem({
    required this.id,
    required this.title,
    required this.streamUrl,
    required this.kind,
    this.subtitle,
    this.posterUrl,
    this.channelLogoUrl,
    this.seriesId,
    this.seasonNumber,
    this.episodeNumber,
    this.nextEpisode,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String streamUrl;
  final PlayableKind kind;
  final String? posterUrl;
  final String? channelLogoUrl;
  final String? seriesId;
  final int? seasonNumber;
  final int? episodeNumber;
  final PlayableItem? nextEpisode;

  bool get hasNextEpisode => nextEpisode != null;
}
