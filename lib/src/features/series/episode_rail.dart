import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../playback/playable_item.dart';

class EpisodeRail extends StatefulWidget {
  const EpisodeRail({
    required this.currentItem,
    required this.items,
    required this.onSelect,
    super.key,
  });

  final PlayableItem currentItem;
  final List<PlayableItem> items;
  final ValueChanged<PlayableItem> onSelect;

  @override
  State<EpisodeRail> createState() => _EpisodeRailState();
}

class _EpisodeRailState extends State<EpisodeRail> {
  final ScrollController _scrollController = ScrollController();
  String? _lastScrolledKey;

  @override
  void initState() {
    super.initState();
    _scheduleScrollToCurrent();
  }

  @override
  void didUpdateWidget(covariant EpisodeRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentItem.id != widget.currentItem.id ||
        oldWidget.currentItem.seasonId != widget.currentItem.seasonId ||
        oldWidget.items.length != widget.items.length) {
      _scheduleScrollToCurrent();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.length < 2) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0C0D0E),
        border: Border(top: BorderSide(color: Color(0xFF292D31))),
      ),
      child: SizedBox(
        height: 156,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Text(
                'Episodes',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFE8E0D4),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _EpisodeTile(
                    item: item,
                    selected:
                        item.id == widget.currentItem.id &&
                        item.seasonId == widget.currentItem.seasonId,
                    onTap: () => widget.onSelect(item),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemCount: widget.items.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleScrollToCurrent() {
    final key = _positionKey(widget.currentItem);
    if (_lastScrolledKey == key) {
      return;
    }
    _lastScrolledKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final index = widget.items.indexWhere(
        (item) =>
            item.id == widget.currentItem.id &&
            item.seasonId == widget.currentItem.seasonId,
      );
      if (index < 0) {
        return;
      }
      final viewport = _scrollController.position.viewportDimension;
      final max = _scrollController.position.maxScrollExtent;
      final target = (index * 246.0 - (viewport / 2) + 118)
          .clamp(0.0, max)
          .toDouble();
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

String _positionKey(PlayableItem item) {
  return '${item.seasonId ?? ''}|${item.id}';
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final PlayableItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : const Color(0xFF34383C);

    return SizedBox(
      width: 236,
      child: Material(
        color: selected ? const Color(0xFF1F211E) : const Color(0xFF151719),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F1113),
                        ),
                        child: item.posterUrl?.trim().isNotEmpty == true
                            ? Image.network(
                                item.posterUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const _EpisodeFallback(),
                              )
                            : const _EpisodeFallback(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subtitle ?? 'Episode',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFE8E0D4),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeFallback extends StatelessWidget {
  const _EpisodeFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(LucideIcons.clapperboard, color: Color(0xFF716D66), size: 28),
    );
  }
}
