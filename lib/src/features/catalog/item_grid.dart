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
    this.subtitle,
    this.description,
    this.artworkUrl,
    this.streamUrl,
    this.streamJson,
    this.year,
    this.rating,
    this.durationSeconds,
    this.epgSummary,
    this.recentItemType,
    this.seriesId,
    this.seasonId,
    this.isFavorite = false,
    this.isRecent = false,
  });

  final String id;
  final String providerId;
  final CatalogContentType contentType;
  final String title;
  final String? subtitle;
  final String? description;
  final String? artworkUrl;
  final String? streamUrl;
  final String? streamJson;
  final int? year;
  final String? rating;
  final int? durationSeconds;
  final String? epgSummary;
  final PlayableContentType? recentItemType;
  final String? seriesId;
  final String? seasonId;
  final bool isFavorite;
  final bool isRecent;
  final bool canPlay;

  bool get hasArtwork => artworkUrl?.trim().isNotEmpty == true;
}

class ItemGrid extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useList = width < 1220;

    return Scrollbar(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 0, 18, 28),
            sliver: useList
                ? SliverList.separated(
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ListTileItem(
                        item: item,
                        selected: item.id == selectedItemId,
                        onSelect: () => onSelect(item.id),
                        onOpen: item.canPlay ? () => onOpen(item) : null,
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemCount: items.length,
                  )
                : SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 196,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _GridCard(
                        item: item,
                        selected: item.id == selectedItemId,
                        onSelect: () => onSelect(item.id),
                        onOpen: item.canPlay ? () => onOpen(item) : null,
                      );
                    },
                    itemCount: items.length,
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
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Artwork(item: item)),
                const SizedBox(height: 10),
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
                  item.subtitle ?? _contentLabel(item.contentType),
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
          height: 78,
          padding: const EdgeInsets.all(8),
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
              SizedBox(width: 64, child: _Artwork(item: item)),
              const SizedBox(width: 12),
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
                      item.epgSummary ??
                          item.subtitle ??
                          _contentLabel(item.contentType),
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
