import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../catalog/catalog_models.dart';

class CategoryList extends StatefulWidget {
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
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(CategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController
        ..text = widget.searchQuery
        ..selection = TextSelection.collapsed(
          offset: widget.searchQuery.length,
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.searchQuery.trim().toLowerCase();
    final orderedCategories = _favoritePinnedCategories(widget.categories);
    final visibleCategories = query.isEmpty
        ? orderedCategories
        : orderedCategories.where((category) {
            return category.name.toLowerCase().contains(query);
          }).toList();
    final reorderDisabled = query.isNotEmpty;
    final totalCount = widget.categories.fold<int>(
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
                controller: _searchController,
                onChanged: widget.onSearchChanged,
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
              active: widget.selectedCategoryId == null,
              favorite: false,
              onSelect: () => widget.onSelect(null),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final category = visibleCategories[index];
                  final canMoveUp =
                      !reorderDisabled &&
                      index > 0 &&
                      visibleCategories[index - 1].isFavorite ==
                          category.isFavorite;
                  final canMoveDown =
                      !reorderDisabled &&
                      index < visibleCategories.length - 1 &&
                      visibleCategories[index + 1].isFavorite ==
                          category.isFavorite;
                  return _CategoryRow(
                    label: category.name,
                    count: category.itemCount,
                    active: widget.selectedCategoryId == category.id,
                    favorite: category.isFavorite,
                    onSelect: () => widget.onSelect(category.id),
                    onToggleFavorite: () => widget.onToggleFavorite(category),
                    reorderDisabled: reorderDisabled,
                    onMoveUp: canMoveUp
                        ? () => widget.onMove(category, -1)
                        : null,
                    onMoveDown: canMoveDown
                        ? () => widget.onMove(category, 1)
                        : null,
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

List<CatalogCategory> _favoritePinnedCategories(
  List<CatalogCategory> categories,
) {
  return [
    ...categories.where((category) => category.isFavorite),
    ...categories.where((category) => !category.isFavorite),
  ];
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
                  child: Tooltip(
                    message: label,
                    waitDuration: const Duration(milliseconds: 450),
                    child: Text(
                      label,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  count.toString(),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF8E8980),
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (onToggleFavorite != null)
                _CategoryIconButton(
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
                _CategoryIconButton(
                  tooltip: reorderDisabled
                      ? 'Clear category search to reorder'
                      : 'Move up',
                  onPressed: onMoveUp,
                  icon: const Icon(LucideIcons.chevronUp, size: 15),
                ),
                _CategoryIconButton(
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

class _CategoryIconButton extends StatelessWidget {
  const _CategoryIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 36),
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
