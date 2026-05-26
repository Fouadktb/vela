import type {
  EpisodeView,
  LiveChannelView,
  MovieView,
  RecentlyWatchedItemView,
  SeriesView
} from "../catalog/types.js";
import type { PlayRequest, PlaybackState, SeekRequest } from "../playback/types.js";
import type {
  CreateM3uProviderInput,
  CreateXtreamProviderInput,
  ImportProgress,
  ProviderSummary
} from "../providers/types.js";

export interface IptvApi {
  providers: {
    list(): Promise<ProviderSummary[]>;
    createM3u(input: CreateM3uProviderInput): Promise<ProviderSummary>;
    createXtream(input: CreateXtreamProviderInput): Promise<ProviderSummary>;
    refresh(providerId: string): Promise<void>;
    delete(providerId: string): Promise<void>;
    onImportProgress(callback: (progress: ImportProgress) => void): () => void;
  };
  catalog: {
    listLiveChannels(query: string, category: string | null): Promise<LiveChannelView[]>;
    listLiveCategories(): Promise<string[]>;
    listMovies(query: string, category: string | null): Promise<MovieView[]>;
    listMovieCategories(): Promise<string[]>;
    listSeries(query: string, category: string | null): Promise<SeriesView[]>;
    listSeriesCategories(): Promise<string[]>;
    listEpisodesForSeries(seriesId: string): Promise<EpisodeView[]>;
    listRecentlyWatched(): Promise<RecentlyWatchedItemView[]>;
    toggleFavorite(itemId: string, itemType: "live" | "movie" | "series"): Promise<void>;
  };
  playback: {
    play(request: PlayRequest): Promise<void>;
    pause(): Promise<void>;
    stop(): Promise<void>;
    seek(request: SeekRequest): Promise<void>;
    openExternal(request: PlayRequest): Promise<void>;
    getState(): Promise<PlaybackState>;
    onState(callback: (state: PlaybackState) => void): () => void;
  };
}

export const ipcChannels = {
  providersList: "providers:list",
  providersCreateM3u: "providers:createM3u",
  providersCreateXtream: "providers:createXtream",
  providersRefresh: "providers:refresh",
  providersDelete: "providers:delete",
  providersImportProgress: "providers:importProgress",
  catalogListLiveChannels: "catalog:listLiveChannels",
  catalogListLiveCategories: "catalog:listLiveCategories",
  catalogListMovies: "catalog:listMovies",
  catalogListMovieCategories: "catalog:listMovieCategories",
  catalogListSeries: "catalog:listSeries",
  catalogListSeriesCategories: "catalog:listSeriesCategories",
  catalogListEpisodesForSeries: "catalog:listEpisodesForSeries",
  catalogListRecentlyWatched: "catalog:listRecentlyWatched",
  catalogToggleFavorite: "catalog:toggleFavorite",
  playbackPlay: "playback:play",
  playbackPause: "playback:pause",
  playbackStop: "playback:stop",
  playbackSeek: "playback:seek",
  playbackOpenExternal: "playback:openExternal",
  playbackGetState: "playback:getState",
  playbackState: "playback:state"
} as const;
