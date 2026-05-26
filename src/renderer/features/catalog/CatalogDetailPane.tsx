import { useEffect, useMemo, useState } from "react";
import { CalendarClock, Heart, Play, RefreshCw } from "lucide-react";
import type { EpisodeView, LiveProgramView } from "../../../shared/catalog/types";
import type { CatalogCardItem } from "./CatalogGrid";

interface CatalogDetailItem extends CatalogCardItem {
  itemType: "live" | "movie" | "series" | "episode";
  eyebrow: string;
  isFavorite: boolean;
  canPlay: boolean;
  canFavorite: boolean;
}

interface CatalogDetailPaneProps {
  item: CatalogDetailItem | null;
  episodes: EpisodeView[];
  livePrograms: LiveProgramView[];
  isLoadingEpisodes: boolean;
  isLoadingPrograms: boolean;
  onPlay(itemId: string): void;
  onPlayEpisode(itemId: string): void;
  onToggleFavorite(itemId: string): void;
  onRefreshProvider(): void;
}

const initialVisibleEpisodeCount = 8;
const visibleEpisodeIncrement = 8;

export function CatalogDetailPane({
  item,
  episodes,
  livePrograms,
  isLoadingEpisodes,
  isLoadingPrograms,
  onPlay,
  onPlayEpisode,
  onToggleFavorite,
  onRefreshProvider
}: CatalogDetailPaneProps) {
  const [visibleEpisodeCount, setVisibleEpisodeCount] = useState(initialVisibleEpisodeCount);
  const visibleEpisodes = useMemo(() => episodes.slice(0, visibleEpisodeCount), [episodes, visibleEpisodeCount]);

  useEffect(() => {
    setVisibleEpisodeCount(initialVisibleEpisodeCount);
  }, [item?.id, episodes]);

  if (!item) {
    return (
      <aside className="detail-pane">
        <div className="empty-state compact">Select an item to see actions.</div>
      </aside>
    );
  }

  return (
    <aside className="detail-pane">
      <div className="poster-frame">
        {item.artworkUrl ? <img src={item.artworkUrl} alt="" /> : <span>{item.title}</span>}
      </div>
      <p className="eyebrow">{item.eyebrow}</p>
      <h2 title={item.title}>{item.title}</h2>
      <p className="detail-category">{item.subtitle || "Uncategorized"}</p>
      <div className="detail-actions">
        {item.canPlay ? (
          <button type="button" onClick={() => onPlay(item.id)}>
            <Play size={17} aria-hidden="true" />
            <span>Play</span>
          </button>
        ) : null}
        {item.canFavorite ? (
          <button type="button" onClick={() => onToggleFavorite(item.id)} aria-pressed={item.isFavorite}>
            <Heart size={17} fill={item.isFavorite ? "currentColor" : "none"} aria-hidden="true" />
            <span>{item.isFavorite ? "Favorited" : "Favorite"}</span>
          </button>
        ) : null}
        <button type="button" onClick={onRefreshProvider}>
          <RefreshCw size={17} aria-hidden="true" />
          <span>Refresh</span>
        </button>
      </div>
      {item.itemType === "series" ? (
        <div className="episode-list">
          <p className="eyebrow">Episodes</p>
          {isLoadingEpisodes ? <div className="episode-state">Loading episodes</div> : null}
          {!isLoadingEpisodes && episodes.length === 0 ? <div className="episode-state">No episodes found</div> : null}
          {visibleEpisodes.map((episode) => (
            <button className="episode-button" key={episode.id} type="button" onClick={() => onPlayEpisode(episode.id)}>
              <Play size={15} aria-hidden="true" />
              <span>{formatEpisodeCode(episode)}</span>
              <strong title={episode.title}>{episode.title}</strong>
            </button>
          ))}
          {visibleEpisodes.length < episodes.length ? (
            <button
              className="episode-more-button"
              type="button"
              onClick={() => setVisibleEpisodeCount((current) => Math.min(current + visibleEpisodeIncrement, episodes.length))}
            >
              Load more episodes
            </button>
          ) : null}
        </div>
      ) : null}
      {item.itemType === "live" ? (
        <div className="live-schedule">
          <p className="eyebrow">Schedule</p>
          {isLoadingPrograms ? <div className="episode-state">Loading schedule</div> : null}
          {!isLoadingPrograms && livePrograms.length === 0 ? (
            <div className="episode-state">No schedule found for this channel.</div>
          ) : null}
          {livePrograms.map((program) => (
            <article className={program.isCurrent ? "program-row current" : "program-row"} key={program.id}>
              <CalendarClock size={15} aria-hidden="true" />
              <div>
                <span>{program.isCurrent ? "Now on" : formatProgramTime(program.startAt)}</span>
                <strong>{program.title}</strong>
                {program.description ? <small>{program.description}</small> : null}
              </div>
            </article>
          ))}
        </div>
      ) : null}
    </aside>
  );
}

function formatEpisodeCode(episode: EpisodeView): string {
  return `S${episode.seasonNumber} E${episode.episodeNumber}`;
}

function formatProgramTime(startAt: string): string {
  return new Intl.DateTimeFormat(undefined, {
    hour: "2-digit",
    minute: "2-digit"
  }).format(new Date(startAt));
}
