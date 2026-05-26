export type CatalogItemType = "live" | "movie" | "series" | "episode";
export type PlayableCatalogItemType = Exclude<CatalogItemType, "series">;

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

export type CatalogItem = LiveChannel | Movie | Series | Episode;
