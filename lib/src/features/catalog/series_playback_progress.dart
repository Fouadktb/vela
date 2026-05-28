import '../../catalog/catalog_models.dart';

enum SeriesPlaybackActionKind { resume, continueNext, replay }

class SeriesPlaybackAction {
  const SeriesPlaybackAction({
    required this.kind,
    required this.episode,
    this.resume,
  });

  final SeriesPlaybackActionKind kind;
  final CatalogEpisode episode;
  final PlaybackPosition? resume;

  String get primaryLabel {
    final episodeLabel = seriesEpisodeLabel(episode);
    return switch (kind) {
      SeriesPlaybackActionKind.resume => 'Resume $episodeLabel',
      SeriesPlaybackActionKind.continueNext => 'Continue $episodeLabel',
      SeriesPlaybackActionKind.replay => 'Replay $episodeLabel',
    };
  }

  String get summaryLabel {
    final episodeLabel = seriesEpisodeLabel(episode);
    return switch (kind) {
      SeriesPlaybackActionKind.resume =>
        resume == null
            ? 'Resume $episodeLabel'
            : 'Resume $episodeLabel from ${compactDuration(resume!.positionSeconds)}',
      SeriesPlaybackActionKind.continueNext => 'Next up $episodeLabel',
      SeriesPlaybackActionKind.replay => 'Last watched $episodeLabel',
    };
  }

  String get subtitle {
    final title = episode.title.trim();
    final label = seriesEpisodeLabel(episode);
    return title.isEmpty ? label : '$label / $title';
  }
}

SeriesPlaybackAction? resolveSeriesPlaybackAction({
  required List<CatalogEpisode> episodes,
  required List<PlaybackPosition> positions,
}) {
  final playable = episodes.where(episodeCanPlay).toList();
  if (playable.isEmpty || positions.isEmpty) {
    return null;
  }

  final resume = latestResumablePosition(positions);
  if (resume != null) {
    final episode = episodeForPosition(playable, resume);
    if (episode != null) {
      return SeriesPlaybackAction(
        kind: SeriesPlaybackActionKind.resume,
        episode: episode,
        resume: resume,
      );
    }
  }

  final latest = latestPlaybackPosition(positions);
  if (latest == null || (!latest.completed && latest.positionSeconds <= 0)) {
    return null;
  }

  final latestEpisode = episodeForPosition(playable, latest);
  if (latestEpisode == null) {
    return null;
  }

  if (latest.completed) {
    final next = nextPlayableEpisodeAfter(playable, latestEpisode);
    if (next != null) {
      return SeriesPlaybackAction(
        kind: SeriesPlaybackActionKind.continueNext,
        episode: next,
      );
    }
    return SeriesPlaybackAction(
      kind: SeriesPlaybackActionKind.replay,
      episode: latestEpisode,
    );
  }

  return SeriesPlaybackAction(
    kind: SeriesPlaybackActionKind.resume,
    episode: latestEpisode,
    resume: latest,
  );
}

PlaybackPosition? latestResumablePosition(List<PlaybackPosition> positions) {
  final resumable =
      positions
          .where(
            (position) => !position.completed && position.positionSeconds > 0,
          )
          .toList()
        ..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
  return resumable.isEmpty ? null : resumable.first;
}

PlaybackPosition? latestPlaybackPosition(List<PlaybackPosition> positions) {
  final meaningful =
      positions
          .where(
            (position) => position.completed || position.positionSeconds > 0,
          )
          .toList()
        ..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
  return meaningful.isEmpty ? null : meaningful.first;
}

CatalogEpisode? episodeForPosition(
  List<CatalogEpisode> episodes,
  PlaybackPosition position,
) {
  return episodes
      .where((episode) => matchesEpisodePosition(episode, position))
      .firstOrNull;
}

CatalogEpisode? nextPlayableEpisodeAfter(
  List<CatalogEpisode> episodes,
  CatalogEpisode current,
) {
  final sorted = episodes.where(episodeCanPlay).toList()
    ..sort((a, b) {
      final season = a.seasonNumber.compareTo(b.seasonNumber);
      if (season != 0) return season;
      final episode = a.episodeNumber.compareTo(b.episodeNumber);
      if (episode != 0) return episode;
      return a.normalizedTitle.compareTo(b.normalizedTitle);
    });
  final index = sorted.indexWhere(
    (episode) =>
        episode.id == current.id && episode.seasonId == current.seasonId,
  );
  if (index < 0 || index + 1 >= sorted.length) {
    return null;
  }
  return sorted[index + 1];
}

Map<String, PlaybackPosition> positionsByEpisode(
  List<PlaybackPosition> positions,
) {
  final byEpisode = <String, PlaybackPosition>{};
  for (final position in positions) {
    final key = episodePositionKey(position.seasonId, position.itemId);
    final existing = byEpisode[key];
    if (existing == null || position.updatedAtMs > existing.updatedAtMs) {
      byEpisode[key] = position;
    }
  }
  return byEpisode;
}

bool matchesEpisodePosition(CatalogEpisode episode, PlaybackPosition position) {
  return episode.id == position.itemId &&
      (position.seasonId == null || episode.seasonId == position.seasonId);
}

String episodePositionKey(String? seasonId, String itemId) {
  return '${seasonId ?? ''}|$itemId';
}

String catalogEpisodePositionKey(CatalogEpisode episode) {
  return episodePositionKey(episode.seasonId, episode.id);
}

String seriesEpisodeLabel(CatalogEpisode episode) {
  return 'S${episode.seasonNumber} E${episode.episodeNumber}';
}

String compactDuration(int seconds) {
  if (seconds < 60) {
    return '1m';
  }
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours <= 0) {
    return '${minutes}m';
  }
  return '${hours}h ${minutes}m';
}

bool episodeCanPlay(CatalogEpisode episode) {
  return episode.streamUrl?.trim().isNotEmpty == true ||
      episode.streamJson?.trim().isNotEmpty == true;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
