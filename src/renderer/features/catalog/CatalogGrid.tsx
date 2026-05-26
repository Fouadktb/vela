import { useEffect, useMemo, useState } from "react";

export interface CatalogCardItem {
  id: string;
  title: string;
  subtitle: string;
  artworkUrl: string | null;
}

interface CatalogGridProps {
  items: CatalogCardItem[];
  selectedItemId: string | null;
  isLoading?: boolean;
  emptyMessage: string;
  onSelect(itemId: string): void;
}

const initialVisibleItemCount = 120;
const visibleItemIncrement = 120;

function getInitials(name: string) {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("");
}

export function CatalogGrid({ items, selectedItemId, isLoading = false, emptyMessage, onSelect }: CatalogGridProps) {
  const [visibleCount, setVisibleCount] = useState(initialVisibleItemCount);
  const visibleItems = useMemo(() => items.slice(0, visibleCount), [items, visibleCount]);

  useEffect(() => {
    setVisibleCount(initialVisibleItemCount);
  }, [items]);

  if (isLoading && items.length === 0) {
    return (
      <div className="catalog-grid" aria-label="Loading catalog">
        {Array.from({ length: 8 }, (_, index) => (
          <div className="channel-card skeleton" key={index} />
        ))}
      </div>
    );
  }

  if (items.length === 0) {
    return <div className="empty-state">{emptyMessage}</div>;
  }

  return (
    <div className="catalog-list">
      <div className="catalog-grid">
        {visibleItems.map((item) => (
          <button
            className={item.id === selectedItemId ? "channel-card selected" : "channel-card"}
            key={item.id}
            type="button"
            onClick={() => onSelect(item.id)}
          >
            <span className="channel-logo">
              {item.artworkUrl ? <img src={item.artworkUrl} alt="" loading="lazy" /> : getInitials(item.title)}
            </span>
            <span className="channel-meta">
              <strong title={item.title}>{item.title}</strong>
              <span title={item.subtitle}>{item.subtitle || "Uncategorized"}</span>
            </span>
          </button>
        ))}
      </div>
      {visibleItems.length < items.length ? (
        <button
          className="load-more-button"
          type="button"
          onClick={() => setVisibleCount((current) => Math.min(current + visibleItemIncrement, items.length))}
        >
          Load more
        </button>
      ) : null}
    </div>
  );
}
