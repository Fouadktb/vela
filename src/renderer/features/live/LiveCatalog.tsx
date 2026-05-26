import type { LiveChannelView } from "../../../shared/catalog/types";

interface LiveCatalogProps {
  channels: LiveChannelView[];
  selectedChannelId: string | null;
  isLoading?: boolean;
  onSelect(channelId: string): void;
}

function getInitials(name: string) {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("");
}

export function LiveCatalog({ channels, selectedChannelId, isLoading = false, onSelect }: LiveCatalogProps) {
  if (isLoading && channels.length === 0) {
    return (
      <div className="catalog-grid" aria-label="Loading live channels">
        {Array.from({ length: 8 }, (_, index) => (
          <div className="channel-card skeleton" key={index} />
        ))}
      </div>
    );
  }

  if (channels.length === 0) {
    return <div className="empty-state">No live channels match the current filters.</div>;
  }

  return (
    <div className="catalog-grid">
      {channels.map((channel) => (
        <button
          className={channel.id === selectedChannelId ? "channel-card selected" : "channel-card"}
          key={channel.id}
          type="button"
          onClick={() => onSelect(channel.id)}
        >
          <span className="channel-logo">
            {channel.logoUrl ? <img src={channel.logoUrl} alt="" loading="lazy" /> : getInitials(channel.name)}
          </span>
          <span className="channel-meta">
            <strong title={channel.name}>{channel.name}</strong>
            <span title={channel.category}>{channel.category || "Uncategorized"}</span>
          </span>
        </button>
      ))}
    </div>
  );
}
