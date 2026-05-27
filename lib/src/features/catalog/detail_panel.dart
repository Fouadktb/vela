import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../catalog/catalog_models.dart';
import 'item_grid.dart';

class DetailPanel extends StatelessWidget {
  const DetailPanel({
    required this.item,
    required this.onPlay,
    required this.onRestart,
    required this.onToggleFavorite,
    required this.onRefreshProvider,
    super.key,
  });

  final CatalogCardItem? item;
  final ValueChanged<CatalogCardItem> onPlay;
  final ValueChanged<CatalogCardItem> onRestart;
  final ValueChanged<CatalogCardItem> onToggleFavorite;
  final VoidCallback onRefreshProvider;

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
                  onPlay: selected.canPlay ? () => onPlay(selected) : null,
                  onRestart: selected.canPlay && selected.hasResume
                      ? () => onRestart(selected)
                      : null,
                  onToggleFavorite: () => onToggleFavorite(selected),
                  onRefreshProvider: onRefreshProvider,
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
    required this.onPlay,
    required this.onRestart,
    required this.onToggleFavorite,
    required this.onRefreshProvider,
  });

  final CatalogCardItem item;
  final VoidCallback? onPlay;
  final VoidCallback? onRestart;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRefreshProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterHeight = item.contentType == CatalogContentType.live
        ? 118.0
        : 260.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: posterHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFF0C0D0E)),
              child: item.hasArtwork
                  ? Image.network(
                      item.artworkUrl!,
                      fit: item.contentType == CatalogContentType.live
                          ? BoxFit.contain
                          : BoxFit.cover,
                      errorBuilder: (_, _, _) => _FallbackIcon(item: item),
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
            if (item.year != null) _MetaChip(label: item.year.toString()),
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
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onPlay,
                icon: const Icon(LucideIcons.play, size: 18),
                label: Text(
                  !item.canPlay
                      ? 'Unavailable'
                      : item.hasResume
                      ? 'Resume ${_duration(item.resumePositionSeconds)}'
                      : item.contentType == CatalogContentType.series
                      ? 'Play First Episode'
                      : 'Play',
                ),
              ),
            ),
            if (onRestart != null) ...[
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(LucideIcons.rotateCcw, size: 18),
                label: const Text('Restart'),
              ),
            ],
            const SizedBox(width: 10),
            IconButton(
              tooltip: item.isFavorite ? 'Remove favorite' : 'Add favorite',
              onPressed: onToggleFavorite,
              icon: Icon(
                LucideIcons.star,
                color: item.isFavorite
                    ? theme.colorScheme.primary
                    : const Color(0xFFD7D0C6),
              ),
            ),
            IconButton(
              tooltip: 'Refresh provider',
              onPressed: onRefreshProvider,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
            ),
          ],
        ),
      ],
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

String _typeLabel(CatalogCardItem item) {
  if (item.isRecent) return 'Recently watched';
  return switch (item.contentType) {
    CatalogContentType.live => 'Live channel',
    CatalogContentType.movie => 'Movie',
    CatalogContentType.series => 'Series',
  };
}

String _duration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours <= 0) {
    return '${minutes}m';
  }
  return '${hours}h ${minutes}m';
}
