import { ChevronDown, ChevronUp, Pin, PinOff, Search } from "lucide-react";
import { useMemo, useState } from "react";
import type { CategoryContentType, CategoryView } from "../../../shared/catalog/types";

interface CategoryRailProps {
  allLabel: string;
  categories: CategoryView[];
  contentType: CategoryContentType | null;
  selectedCategory: string | null;
  onSelect(category: string | null): void;
  onTogglePin(contentType: CategoryContentType, category: string): void;
  onReorderPinned(contentType: CategoryContentType, categories: string[]): void;
}

export function CategoryRail({
  allLabel,
  categories,
  contentType,
  selectedCategory,
  onSelect,
  onTogglePin,
  onReorderPinned
}: CategoryRailProps) {
  const [categoryQuery, setCategoryQuery] = useState("");
  const pinnedCategories = categories.filter((category) => category.isPinned).map((category) => category.name);
  const canManageCategories = contentType !== null;
  const normalizedQuery = categoryQuery.trim().toLowerCase();
  const visibleCategories = useMemo(
    () =>
      normalizedQuery
        ? categories.filter((category) => category.name.toLowerCase().includes(normalizedQuery))
        : categories,
    [categories, normalizedQuery]
  );
  const visiblePinnedCategories = visibleCategories.filter((category) => category.isPinned);
  const visibleOtherCategories = visibleCategories.filter((category) => !category.isPinned);

  const movePinnedCategory = (categoryName: string, direction: -1 | 1) => {
    if (!contentType) {
      return;
    }

    const currentIndex = pinnedCategories.indexOf(categoryName);
    const nextIndex = currentIndex + direction;
    if (currentIndex < 0 || nextIndex < 0 || nextIndex >= pinnedCategories.length) {
      return;
    }

    const nextPinnedCategories = [...pinnedCategories];
    const [category] = nextPinnedCategories.splice(currentIndex, 1);
    nextPinnedCategories.splice(nextIndex, 0, category);
    onReorderPinned(contentType, nextPinnedCategories);
  };

  return (
    <aside className="category-panel" aria-label="Categories">
      <div className="category-panel-heading">
        <div>
          <p className="eyebrow">Categories</p>
          <strong>{categories.length}</strong>
        </div>
        <div className="category-search">
          <Search size={15} aria-hidden="true" />
          <input
            aria-label="Search categories"
            placeholder="Find category"
            value={categoryQuery}
            onChange={(event) => setCategoryQuery(event.target.value)}
          />
        </div>
      </div>
      <button
        className={selectedCategory === null ? "category-row all active" : "category-row all"}
        aria-pressed={selectedCategory === null}
        type="button"
        onClick={() => onSelect(null)}
      >
        <span>{allLabel}</span>
        <small>{formatItemCount(categories.reduce((total, category) => total + category.itemCount, 0))}</small>
      </button>
      <div className="category-list">
        {visiblePinnedCategories.length > 0 ? <span className="category-group-label">Pinned</span> : null}
        {visiblePinnedCategories.map((category) => (
          <CategoryRow
            category={category}
            contentType={contentType}
            isSelected={selectedCategory === category.name}
            key={category.name}
            pinnedIndex={pinnedCategories.indexOf(category.name)}
            pinnedTotal={pinnedCategories.length}
            canManageCategories={canManageCategories}
            onMovePinned={movePinnedCategory}
            onSelect={onSelect}
            onTogglePin={onTogglePin}
          />
        ))}

        {visibleOtherCategories.length > 0 ? <span className="category-group-label">All categories</span> : null}
        {visibleOtherCategories.map((category) => (
          <CategoryRow
            category={category}
            contentType={contentType}
            isSelected={selectedCategory === category.name}
            key={category.name}
            pinnedIndex={-1}
            pinnedTotal={pinnedCategories.length}
            canManageCategories={canManageCategories}
            onMovePinned={movePinnedCategory}
            onSelect={onSelect}
            onTogglePin={onTogglePin}
          />
        ))}
        {visibleCategories.length === 0 ? <div className="category-empty">No categories match.</div> : null}
      </div>
    </aside>
  );
}

interface CategoryRowProps {
  category: CategoryView;
  contentType: CategoryContentType | null;
  isSelected: boolean;
  pinnedIndex: number;
  pinnedTotal: number;
  canManageCategories: boolean;
  onMovePinned(categoryName: string, direction: -1 | 1): void;
  onSelect(category: string): void;
  onTogglePin(contentType: CategoryContentType, category: string): void;
}

function CategoryRow({
  category,
  contentType,
  isSelected,
  pinnedIndex,
  pinnedTotal,
  canManageCategories,
  onMovePinned,
  onSelect,
  onTogglePin
}: CategoryRowProps) {
  const shellClassName = [
    "category-row-shell",
    category.isPinned ? "pinned" : null,
    isSelected ? "active" : null
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div className={shellClassName}>
      <button
        type="button"
        className={isSelected ? "category-row active" : "category-row"}
        aria-label={`${category.name} category`}
        aria-pressed={isSelected}
        onClick={() => onSelect(category.name)}
      >
        <span>{category.name || "Uncategorized"}</span>
        <small>{formatItemCount(category.itemCount)}</small>
      </button>
      {canManageCategories ? (
        <div className="category-row-tools" aria-label={`${category.name} category tools`}>
          {category.isPinned ? (
            <>
              <button
                type="button"
                className="icon-button mini"
                aria-label={`Move ${category.name} category up`}
                disabled={pinnedIndex <= 0}
                title="Move pinned category up"
                onClick={() => onMovePinned(category.name, -1)}
              >
                <ChevronUp size={14} aria-hidden="true" />
              </button>
              <button
                type="button"
                className="icon-button mini"
                aria-label={`Move ${category.name} category down`}
                disabled={pinnedIndex < 0 || pinnedIndex >= pinnedTotal - 1}
                title="Move pinned category down"
                onClick={() => onMovePinned(category.name, 1)}
              >
                <ChevronDown size={14} aria-hidden="true" />
              </button>
            </>
          ) : null}
          <button
            type="button"
            className="icon-button mini"
            aria-label={`${category.isPinned ? "Unpin" : "Pin"} ${category.name} category`}
            title={category.isPinned ? "Unpin category" : "Pin category"}
            onClick={() => {
              if (contentType) {
                onTogglePin(contentType, category.name);
              }
            }}
          >
            {category.isPinned ? <PinOff size={14} aria-hidden="true" /> : <Pin size={14} aria-hidden="true" />}
          </button>
        </div>
      ) : null}
    </div>
  );
}

function formatItemCount(count: number): string {
  return count === 1 ? "1 item" : `${count} items`;
}
