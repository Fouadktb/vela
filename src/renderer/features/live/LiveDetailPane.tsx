import { Heart, Play, RefreshCw } from "lucide-react";
import type { LiveChannelView } from "../../../shared/catalog/types";

interface LiveDetailPaneProps {
  channel: LiveChannelView | null;
  onPlay(channel: LiveChannelView): void;
  onToggleFavorite(channel: LiveChannelView): void;
  onRefresh(): void;
}

export function LiveDetailPane({ channel, onPlay, onToggleFavorite, onRefresh }: LiveDetailPaneProps) {
  if (!channel) {
    return (
      <aside className="detail-pane">
        <div className="empty-state compact">Select a live channel to see actions.</div>
      </aside>
    );
  }

  return (
    <aside className="detail-pane">
      <div className="poster-frame">
        {channel.logoUrl ? <img src={channel.logoUrl} alt="" /> : <span>{channel.name}</span>}
      </div>
      <p className="eyebrow">Live channel</p>
      <h2 title={channel.name}>{channel.name}</h2>
      <p className="detail-category">{channel.category || "Uncategorized"}</p>
      <div className="detail-actions">
        <button type="button" onClick={() => onPlay(channel)}>
          <Play size={17} aria-hidden="true" />
          <span>Play</span>
        </button>
        <button type="button" onClick={() => onToggleFavorite(channel)} aria-pressed={channel.isFavorite}>
          <Heart size={17} fill={channel.isFavorite ? "currentColor" : "none"} aria-hidden="true" />
          <span>{channel.isFavorite ? "Favorited" : "Favorite"}</span>
        </button>
        <button type="button" onClick={onRefresh}>
          <RefreshCw size={17} aria-hidden="true" />
          <span>Refresh</span>
        </button>
      </div>
    </aside>
  );
}
