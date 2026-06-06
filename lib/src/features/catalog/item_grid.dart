import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../catalog/catalog_models.dart';

class CatalogCardItem {
  const CatalogCardItem({
    required this.id,
    required this.providerId,
    required this.contentType,
    required this.title,
    required this.canPlay,
    this.externalId,
    this.subtitle,
    this.description,
    this.artworkUrl,
    this.streamUrl,
    this.streamJson,
    this.year,
    this.rating,
    this.durationSeconds,
    this.epgChannelId,
    this.epgSummary,
    this.recentItemType,
    this.seriesId,
    this.seasonId,
    this.resumePositionSeconds = 0,
    this.resumeDurationSeconds,
    this.seriesPlaybackLabel,
    this.seriesPlaybackSummary,
    this.isFavorite = false,
    this.isRecent = false,
  });

  final String id;
  final String providerId;
  final CatalogContentType contentType;
  final String title;
  final String? externalId;
  final String? subtitle;
  final String? description;
  final String? artworkUrl;
  final String? streamUrl;
  final String? streamJson;
  final int? year;
  final String? rating;
  final int? durationSeconds;
  final String? epgChannelId;
  final String? epgSummary;
  final PlayableContentType? recentItemType;
  final String? seriesId;
  final String? seasonId;
  final int resumePositionSeconds;
  final int? resumeDurationSeconds;
  final String? seriesPlaybackLabel;
  final String? seriesPlaybackSummary;
  final bool isFavorite;
  final bool isRecent;
  final bool canPlay;

  bool get hasArtwork => artworkUrl?.trim().isNotEmpty == true;
  bool get hasResume {
    return contentType != CatalogContentType.live && resumePositionSeconds > 0;
  }

  bool get hasSeriesPlaybackAction {
    return contentType == CatalogContentType.series &&
        seriesPlaybackLabel?.trim().isNotEmpty == true;
  }

  bool get hasPlaybackProgress {
    return hasResume || hasSeriesPlaybackAction;
  }

  bool get hasResumeProgress {
    return hasResume && (resumeDurationSeconds ?? durationSeconds ?? 0) > 0;
  }

  double get resumeProgress {
    final duration = resumeDurationSeconds ?? durationSeconds;
    if (duration == null || duration <= 0) return 0;
    return (resumePositionSeconds / duration).clamp(0, 1).toDouble();
  }

  CatalogCardItem copyWith({
    String? id,
    String? providerId,
    CatalogContentType? contentType,
    String? title,
    String? externalId,
    String? subtitle,
    String? description,
    String? artworkUrl,
    String? streamUrl,
    String? streamJson,
    int? year,
    String? rating,
    int? durationSeconds,
    String? epgChannelId,
    String? epgSummary,
    PlayableContentType? recentItemType,
    String? seriesId,
    String? seasonId,
    int? resumePositionSeconds,
    int? resumeDurationSeconds,
    String? seriesPlaybackLabel,
    String? seriesPlaybackSummary,
    bool? isFavorite,
    bool? isRecent,
    bool? canPlay,
  }) {
    return CatalogCardItem(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      externalId: externalId ?? this.externalId,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      streamJson: streamJson ?? this.streamJson,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      epgSummary: epgSummary ?? this.epgSummary,
      recentItemType: recentItemType ?? this.recentItemType,
      seriesId: seriesId ?? this.seriesId,
      seasonId: seasonId ?? this.seasonId,
      resumePositionSeconds:
          resumePositionSeconds ?? this.resumePositionSeconds,
      resumeDurationSeconds:
          resumeDurationSeconds ?? this.resumeDurationSeconds,
      seriesPlaybackLabel: seriesPlaybackLabel ?? this.seriesPlaybackLabel,
      seriesPlaybackSummary:
          seriesPlaybackSummary ?? this.seriesPlaybackSummary,
      isFavorite: isFavorite ?? this.isFavorite,
      isRecent: isRecent ?? this.isRecent,
      canPlay: canPlay ?? this.canPlay,
    );
  }
}

class ItemGrid extends StatefulWidget {
  const ItemGrid({
    required this.items,
    required this.selectedItemId,
    required this.onSelect,
    required this.onOpen,
    super.key,
  });

  final List<CatalogCardItem> items;
  final String? selectedItemId;
  final ValueChanged<String> onSelect;
  final ValueChanged<CatalogCardItem> onOpen;

  @override
  State<ItemGrid> createState() => _ItemGridState();
}

class _ItemGridState extends State<ItemGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useList = width < 1220;

    return Scrollbar(
      controller: _scrollController,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 0, 18, 28),
            sliver: useList
                ? SliverList.separated(
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return _ListTileItem(
                        item: item,
                        selected: item.id == widget.selectedItemId,
                        onSelect: () => widget.onSelect(item.id),
                        onOpen: item.canPlay ? () => widget.onOpen(item) : null,
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemCount: widget.items.length,
                  )
                : SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 174,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return _GridCard(
                        item: item,
                        selected: item.id == widget.selectedItemId,
                        onSelect: () => widget.onSelect(item.id),
                        onOpen: item.canPlay ? () => widget.onOpen(item) : null,
                      );
                    },
                    itemCount: widget.items.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.item,
    required this.selected,
    required this.onSelect,
    required this.onOpen,
  });

  final CatalogCardItem item;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : const Color(0xFF292D31);

    return Material(
      color: selected ? const Color(0xFF1F211E) : const Color(0xFF151719),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onSelect,
        onDoubleTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Artwork(item: item)),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _secondaryLabel(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFA9A39A),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListTileItem extends StatelessWidget {
  const _ListTileItem({
    required this.item,
    required this.selected,
    required this.onSelect,
    required this.onOpen,
  });

  final CatalogCardItem item;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected ? const Color(0xFF1F211E) : const Color(0xFF151719),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onSelect,
        onDoubleTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : const Color(0xFF292D31),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(width: 56, child: _Artwork(item: item)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _secondaryLabel(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (item.isFavorite)
                Icon(
                  LucideIcons.star,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.item});

  final CatalogCardItem item;

  @override
  Widget build(BuildContext context) {
    final isLive = item.contentType == CatalogContentType.live;
    final icon = switch (item.contentType) {
      CatalogContentType.live => LucideIcons.tv,
      CatalogContentType.movie => LucideIcons.film,
      CatalogContentType.series => LucideIcons.library,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF0F1113)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.hasArtwork)
              Image.network(
                item.artworkUrl!,
                fit: isLive ? BoxFit.contain : BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Icon(icon, color: const Color(0xFF716D66), size: 30),
              )
            else
              Icon(icon, color: const Color(0xFF716D66), size: 30),
            if (item.canPlay)
              const Positioned(right: 8, bottom: 8, child: _PlayDot()),
            if (item.hasResumeProgress)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  value: item.resumeProgress,
                  backgroundColor: const Color(0x66000000),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayDot extends StatelessWidget {
  const _PlayDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Padding(
        padding: EdgeInsets.all(5),
        child: Icon(LucideIcons.play, size: 12, color: Color(0xFF0C0D0E)),
      ),
    );
  }
}

String _contentLabel(CatalogContentType type) {
  return switch (type) {
    CatalogContentType.live => 'Live channel',
    CatalogContentType.movie => 'Movie',
    CatalogContentType.series => 'Series',
  };
}

String _secondaryLabel(CatalogCardItem item) {
  return item.epgSummary ??
      item.seriesPlaybackSummary ??
      item.subtitle ??
      _contentLabel(item.contentType);
}
