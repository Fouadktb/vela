export type CatalogItemType = "live" | "movie" | "series" | "episode";
export type PlayableCatalogItemType = Exclude<CatalogItemType, "series">;
export type CategoryContentType = "live" | "movie" | "series";

export interface StreamResolverData {
  providerType: "m3u" | "xtream";
  url?: string;
  streamId?: string;
  containerExtension?: string;
}

export interface LiveChannel {
  type: "live";
  id: string;
  providerId: string;
  name: string;
  logoUrl: string | null;
  category: string;
  stream: StreamResolverData;
  epgChannelId: string | null;
  lastSeenAt: string;
  isFavorite: boolean;
}

export interface CategoryView {
  contentType: CategoryContentType;
  name: string;
  itemCount: number;
  isPinned: boolean;
  sortOrder: number | null;
}

export interface LiveProgram {
  id: string;
  providerId: string;
  channelId: string;
  title: string;
  description: string | null;
  startAt: string;
  endAt: string;
}

export type LiveProgramView = Omit<LiveProgram, "providerId"> & {
  isCurrent: boolean;
};

export function toLiveProgramView(program: LiveProgram, nowIso: string = new Date().toISOString()): LiveProgramView {
  const { providerId: _providerId, ...view } = program;
  return {
    ...view,
    isCurrent: program.startAt <= nowIso && program.endAt > nowIso
  };
}

export type LiveChannelView = Omit<LiveChannel, "stream">;

export function toLiveChannelView(channel: LiveChannel): LiveChannelView {
  const { stream: _stream, ...view } = channel;
  return view;
}

export interface Movie {
  type: "movie";
  id: string;
  providerId: string;
  title: string;
  posterUrl: string | null;
  category: string;
  year: number | null;
  rating: string | null;
  stream: StreamResolverData;
  lastSeenAt: string;
  isFavorite: boolean;
}

export type MovieView = Omit<Movie, "stream">;

export function toMovieView(movie: Movie): MovieView {
  const { stream: _stream, ...view } = movie;
  return view;
}

export interface Series {
  type: "series";
  id: string;
  providerId: string;
  title: string;
  posterUrl: string | null;
  category: string;
  lastSeenAt: string;
  isFavorite: boolean;
}

export type SeriesView = Series;

export function toSeriesView(series: Series): SeriesView {
  return series;
}

export interface Episode {
  type: "episode";
  id: string;
  providerId: string;
  seriesId: string;
  seasonNumber: number;
  episodeNumber: number;
  title: string;
  durationSeconds: number | null;
  progressSeconds: number;
  stream: StreamResolverData;
}

export type EpisodeView = Omit<Episode, "stream">;

export function toEpisodeView(episode: Episode): EpisodeView {
  const { stream: _stream, ...view } = episode;
  return view;
}

export interface RecentlyWatchedItemView {
  id: string;
  itemType: "live" | "movie" | "episode";
  providerId: string;
  title: string;
  subtitle: string;
  artworkUrl: string | null;
  lastWatchedAt: string;
}

export type CatalogItem = LiveChannel | Movie | Series | Episode;
