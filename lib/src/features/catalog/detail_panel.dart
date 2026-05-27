import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../catalog/catalog_models.dart';
import 'item_grid.dart';

class DetailPanel extends StatelessWidget {
  const DetailPanel({
    required this.item,
    required this.seriesEpisodes,
    required this.epgPrograms,
    required this.onPlay,
    required this.onRestart,
    required this.onOpenEpisode,
    required this.onOpenDetails,
    required this.onToggleFavorite,
    super.key,
  });

  final CatalogCardItem? item;
  final AsyncValue<List<CatalogEpisode>> seriesEpisodes;
  final AsyncValue<List<EpgProgram>> epgPrograms;
  final ValueChanged<CatalogCardItem> onPlay;
  final ValueChanged<CatalogCardItem> onRestart;
  final void Function(CatalogCardItem item, CatalogEpisode episode)
  onOpenEpisode;
  final ValueChanged<CatalogCardItem> onOpenDetails;
  final ValueChanged<CatalogCardItem> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final selected = item;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF111315),
        border: Border(left: BorderSide(color: Color(0xFF292D31))),
      ),
      child: SafeArea(
        left: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 22, 22),
          child: selected == null
              ? const _NoSelection()
              : _SelectedDetails(
                  item: selected,
                  seriesEpisodes: seriesEpisodes,
                  epgPrograms: epgPrograms,
                  onPlay: selected.canPlay ? () => onPlay(selected) : null,
                  onRestart: selected.canPlay && selected.hasResume
                      ? () => onRestart(selected)
                      : null,
                  onOpenEpisode: (episode) => onOpenEpisode(selected, episode),
                  onOpenDetails: selected.contentType == CatalogContentType.live
                      ? null
                      : () => onOpenDetails(selected),
                  onToggleFavorite: () => onToggleFavorite(selected),
                ),
        ),
      ),
    );
  }
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.panelRight,
          size: 36,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Text(
          'Select an item',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Details and playback controls stay here while the catalog scrolls.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SelectedDetails extends StatelessWidget {
  const _SelectedDetails({
    required this.item,
    required this.seriesEpisodes,
    required this.epgPrograms,
    required this.onPlay,
    required this.onRestart,
    required this.onOpenEpisode,
    required this.onOpenDetails,
    required this.onToggleFavorite,
  });

  final CatalogCardItem item;
  final AsyncValue<List<CatalogEpisode>> seriesEpisodes;
  final AsyncValue<List<EpgProgram>> epgPrograms;
  final VoidCallback? onPlay;
  final VoidCallback? onRestart;
  final ValueChanged<CatalogEpisode> onOpenEpisode;
  final VoidCallback? onOpenDetails;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterHeight = item.contentType == CatalogContentType.live
        ? 112.0
        : 230.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: posterHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0C0D0E),
                        ),
                        child: item.hasArtwork
                            ? Image.network(
                                item.artworkUrl!,
                                fit: item.contentType == CatalogContentType.live
                                    ? BoxFit.contain
                                    : BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _FallbackIcon(item: item),
                              )
                            : _FallbackIcon(item: item),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _typeLabel(item),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.year != null)
                        _MetaChip(label: item.year.toString()),
                      if (item.rating?.trim().isNotEmpty == true)
                        _MetaChip(label: 'Rating ${item.rating}'),
                      if (item.durationSeconds != null)
                        _MetaChip(label: _duration(item.durationSeconds!)),
                      if (item.isFavorite) const _MetaChip(label: 'Favorite'),
                    ],
                  ),
                  if (item.epgSummary?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _InfoBlock(title: 'Now', body: item.epgSummary!),
                  ],
                  if (item.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _InfoBlock(title: 'Overview', body: item.description!),
                  ],
                  if (item.hasResume) ...[
                    const SizedBox(height: 16),
                    _ResumeBlock(item: item),
                  ],
                  if (item.contentType == CatalogContentType.live) ...[
                    const SizedBox(height: 18),
                    _ScheduleBlock(programs: epgPrograms),
                  ],
                  if (item.contentType == CatalogContentType.series) ...[
                    const SizedBox(height: 18),
                    _SeriesEpisodeBlock(
                      episodes: seriesEpisodes,
                      onOpenEpisode: onOpenEpisode,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ActionBar(
          item: item,
          onPlay: onPlay,
          onRestart: onRestart,
          onOpenDetails: onOpenDetails,
          onToggleFavorite: onToggleFavorite,
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.item,
    required this.onPlay,
    required this.onRestart,
    required this.onOpenDetails,
    required this.onToggleFavorite,
  });

  final CatalogCardItem item;
  final VoidCallback? onPlay;
  final VoidCallback? onRestart;
  final VoidCallback? onOpenDetails;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onPlay,
                icon: const Icon(LucideIcons.play, size: 18),
                label: Text(
                  _primaryActionLabel(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: item.isFavorite ? 'Remove favorite' : 'Add favorite',
              onPressed: onToggleFavorite,
              icon: Icon(
                LucideIcons.star,
                color: item.isFavorite
                    ? theme.colorScheme.primary
                    : const Color(0xFFD7D0C6),
              ),
            ),
          ],
        ),
        if (onOpenDetails != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onOpenDetails,
            icon: const Icon(LucideIcons.panelTopOpen, size: 18),
            label: const Text(
              'Open Details',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (onRestart != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRestart,
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: const Text(
              'Restart',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduleBlock extends StatelessWidget {
  const _ScheduleBlock({required this.programs});

  final AsyncValue<List<EpgProgram>> programs;

  @override
  Widget build(BuildContext context) {
    return programs.when(
      data: (items) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final current = _currentProgram(items, nowMs);
        final upcoming = items
            .where((program) => program.startAtMs > nowMs)
            .take(4)
            .toList();
        if (current == null && upcoming.isEmpty) {
          return const _PanelNotice(
            icon: LucideIcons.calendarClock,
            title: 'No schedule available',
            body: 'This provider did not return guide data for this channel.',
          );
        }

        return _PanelSection(
          title: 'Channel schedule',
          child: Column(
            children: [
              if (current != null)
                _ScheduleRow(program: current, isCurrent: true),
              for (final program in upcoming)
                _ScheduleRow(program: program, isCurrent: false),
            ],
          ),
        );
      },
      loading: () => const _PanelNotice(
        icon: LucideIcons.calendarClock,
        title: 'Loading schedule',
        body: 'Checking the provider guide for this channel.',
      ),
      error: (_, _) => const _PanelNotice(
        icon: LucideIcons.calendarX,
        title: 'Schedule unavailable',
        body: 'The provider guide could not be loaded.',
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.program, required this.isCurrent});

  final EpgProgram program;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF1F211E) : const Color(0xFF16191B),
        border: Border.all(
          color: isCurrent
              ? theme.colorScheme.primary
              : const Color(0xFF292D31),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCurrent ? LucideIcons.radio : LucideIcons.clock3,
            size: 17,
            color: isCurrent
                ? theme.colorScheme.primary
                : const Color(0xFFA9A39A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrent ? 'On now' : _timeRange(program),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : const Color(0xFFA9A39A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  program.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                if (program.description?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    program.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesEpisodeBlock extends StatefulWidget {
  const _SeriesEpisodeBlock({
    required this.episodes,
    required this.onOpenEpisode,
  });

  final AsyncValue<List<CatalogEpisode>> episodes;
  final ValueChanged<CatalogEpisode> onOpenEpisode;

  @override
  State<_SeriesEpisodeBlock> createState() => _SeriesEpisodeBlockState();
}

class _SeriesEpisodeBlockState extends State<_SeriesEpisodeBlock> {
  int? _selectedSeason;

  @override
  Widget build(BuildContext context) {
    return widget.episodes.when(
      data: (episodes) {
        final playable = episodes.where(_episodeCanPlay).toList();
        if (playable.isEmpty) {
          return const _PanelNotice(
            icon: LucideIcons.listVideo,
            title: 'Episodes unavailable',
            body: 'Episode details are still loading or not available.',
          );
        }

        final seasons = playable.map((episode) => episode.seasonNumber).toSet();
        final sortedSeasons = seasons.toList()..sort();
        final selectedSeason =
            _selectedSeason != null && sortedSeasons.contains(_selectedSeason)
            ? _selectedSeason!
            : sortedSeasons.first;
        final visible = playable
            .where((episode) => episode.seasonNumber == selectedSeason)
            .toList();

        return _PanelSection(
          title: 'Episodes',
          trailing: _SeasonSelect(
            seasons: sortedSeasons,
            selectedSeason: selectedSeason,
            onChanged: (season) => setState(() => _selectedSeason = season),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final episode = visible[index];
                return _EpisodeRow(
                  episode: episode,
                  onOpen: () => widget.onOpenEpisode(episode),
                );
              },
            ),
          ),
        );
      },
      loading: () => const _PanelNotice(
        icon: LucideIcons.listVideo,
        title: 'Loading episodes',
        body: 'Fetching seasons and episodes for this series.',
      ),
      error: (_, _) => const _PanelNotice(
        icon: LucideIcons.listX,
        title: 'Episodes unavailable',
        body: 'The provider did not return episode details.',
      ),
    );
  }
}

class _SeasonSelect extends StatelessWidget {
  const _SeasonSelect({
    required this.seasons,
    required this.selectedSeason,
    required this.onChanged,
  });

  final List<int> seasons;
  final int selectedSeason;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0D0E),
        border: Border.all(color: const Color(0xFF34383C)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedSeason,
            isDense: true,
            borderRadius: BorderRadius.circular(8),
            dropdownColor: const Color(0xFF151719),
            icon: const Icon(LucideIcons.chevronDown, size: 16),
            items: [
              for (final season in seasons)
                DropdownMenuItem(value: season, child: Text('Season $season')),
            ],
            onChanged: (season) {
              if (season != null) {
                onChanged(season);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode, required this.onOpen});

  final CatalogEpisode episode;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: const Color(0xFF16191B),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(LucideIcons.play, size: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _episodeSubtitle(episode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFA9A39A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _PanelNotice extends StatelessWidget {
  const _PanelNotice({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16191B),
        border: Border.all(color: const Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeBlock extends StatelessWidget {
  const _ResumeBlock({required this.item});

  final CatalogCardItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = item.hasResumeProgress
        ? (item.resumeProgress * 100).round().clamp(1, 100)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progress == null
              ? 'Resume from ${_duration(item.resumePositionSeconds)}'
              : '$progress% watched',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        if (item.hasResumeProgress) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: item.resumeProgress,
              backgroundColor: const Color(0xFF292D31),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.item});

  final CatalogCardItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.contentType) {
      CatalogContentType.live => LucideIcons.tv,
      CatalogContentType.movie => LucideIcons.film,
      CatalogContentType.series => LucideIcons.library,
    };
    return Center(child: Icon(icon, size: 42, color: const Color(0xFF716D66)));
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D20),
        border: Border.all(color: const Color(0xFF34383C)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFD7D0C6),
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

String _primaryActionLabel(CatalogCardItem item) {
  if (!item.canPlay) {
    return 'Unavailable';
  }
  if (item.hasResume) {
    final episodePrefix = _resumeEpisodePrefix(item);
    if (episodePrefix != null) {
      return 'Resume $episodePrefix';
    }
    return item.resumePositionSeconds < 60
        ? 'Resume'
        : 'Resume ${_duration(item.resumePositionSeconds)}';
  }
  if (item.contentType == CatalogContentType.series) {
    return 'Play First Episode';
  }
  return 'Play';
}

String? _resumeEpisodePrefix(CatalogCardItem item) {
  if (item.contentType != CatalogContentType.series) {
    return null;
  }
  final subtitle = item.subtitle?.trim();
  if (subtitle == null || !subtitle.startsWith('S')) {
    return null;
  }
  return subtitle.split('/').first.trim();
}

String _typeLabel(CatalogCardItem item) {
  if (item.isRecent) return 'Recently watched';
  return switch (item.contentType) {
    CatalogContentType.live => 'Live channel',
    CatalogContentType.movie => 'Movie',
    CatalogContentType.series => 'Series',
  };
}

String _duration(int seconds) {
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

String _timeRange(EpgProgram program) {
  final format = DateFormat.Hm();
  final start = DateTime.fromMillisecondsSinceEpoch(program.startAtMs);
  final end = DateTime.fromMillisecondsSinceEpoch(program.endAtMs);
  return '${format.format(start)} - ${format.format(end)}';
}

String _episodeSubtitle(CatalogEpisode episode) {
  final parts = <String>[
    'S${episode.seasonNumber} E${episode.episodeNumber}',
    if (episode.durationSeconds != null) _duration(episode.durationSeconds!),
  ];
  return parts.join(' / ');
}

EpgProgram? _currentProgram(List<EpgProgram> programs, int timestampMs) {
  for (final program in programs) {
    if (program.isAiringAt(timestampMs)) {
      return program;
    }
  }
  return null;
}

bool _episodeCanPlay(CatalogEpisode episode) {
  return episode.streamUrl?.trim().isNotEmpty == true ||
      episode.streamJson?.trim().isNotEmpty == true;
}
