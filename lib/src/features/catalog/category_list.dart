import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../catalog/catalog_models.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({
    required this.categories,
    required this.searchQuery,
    required this.selectedCategoryId,
    required this.onSearchChanged,
    required this.onSelect,
    required this.onToggleFavorite,
    required this.onMove,
    super.key,
  });

  final List<CatalogCategory> categories;
  final String searchQuery;
  final String? selectedCategoryId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onSelect;
  final ValueChanged<CatalogCategory> onToggleFavorite;
  final void Function(CatalogCategory category, int delta) onMove;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final visibleCategories = query.isEmpty
        ? categories
        : categories.where((category) {
            return category.name.toLowerCase().contains(query);
          }).toList();
    final reorderDisabled = query.isNotEmpty;
    final totalCount = categories.fold<int>(
      0,
      (count, category) => count + category.itemCount,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF111315),
        border: Border(right: BorderSide(color: Color(0xFF292D31))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Categories',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Text(
                  totalCount.toString(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFA9A39A),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: TextField(
                onChanged: onSearchChanged,
                controller: TextEditingController(text: searchQuery)
                  ..selection = TextSelection.collapsed(
                    offset: searchQuery.length,
                  ),
                decoration: const InputDecoration(
                  hintText: 'Search categories',
                  prefixIcon: Icon(LucideIcons.search, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _CategoryRow(
              label: 'All',
              count: totalCount,
              active: selectedCategoryId == null,
              favorite: false,
              onSelect: () => onSelect(null),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final category = visibleCategories[index];
                  return _CategoryRow(
                    label: category.name,
                    count: category.itemCount,
                    active: selectedCategoryId == category.id,
                    favorite: category.isFavorite,
                    onSelect: () => onSelect(category.id),
                    onToggleFavorite: () => onToggleFavorite(category),
                    reorderDisabled: reorderDisabled,
                    onMoveUp: reorderDisabled || index == 0
                        ? null
                        : () => onMove(category, -1),
                    onMoveDown:
                        reorderDisabled || index == visibleCategories.length - 1
                        ? null
                        : () => onMove(category, 1),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemCount: visibleCategories.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.count,
    required this.active,
    required this.favorite,
    required this.onSelect,
    this.onToggleFavorite,
    this.reorderDisabled = false,
    this.onMoveUp,
    this.onMoveDown,
  });

  final String label;
  final int count;
  final bool active;
  final bool favorite;
  final VoidCallback onSelect;
  final VoidCallback? onToggleFavorite;
  final bool reorderDisabled;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = active
        ? theme.colorScheme.primary
        : const Color(0xFFD7D0C6);

    return Material(
      color: active ? const Color(0xFF25211A) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              Text(
                count.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF8E8980),
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 4),
              if (onToggleFavorite != null)
                IconButton(
                  tooltip: favorite
                      ? 'Unfavorite category'
                      : 'Favorite category',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    LucideIcons.star,
                    size: 15,
                    color: favorite
                        ? theme.colorScheme.primary
                        : const Color(0xFF716D66),
                  ),
                ),
              if (onMoveUp != null ||
                  onMoveDown != null ||
                  reorderDisabled) ...[
                IconButton(
                  tooltip: reorderDisabled
                      ? 'Clear category search to reorder'
                      : 'Move up',
                  onPressed: onMoveUp,
                  icon: const Icon(LucideIcons.chevronUp, size: 15),
                ),
                IconButton(
                  tooltip: reorderDisabled
                      ? 'Clear category search to reorder'
                      : 'Move down',
                  onPressed: onMoveDown,
                  icon: const Icon(LucideIcons.chevronDown, size: 15),
                ),
              ] else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
