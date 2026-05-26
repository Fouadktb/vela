import type { LiveChannel } from "../catalog/types.js";
import type { PlayRequest, PlaybackState, SeekRequest } from "../playback/types.js";
import type { CreateM3uProviderInput, ImportProgress, Provider } from "../providers/types.js";

export interface IptvApi {
  providers: {
    list(): Promise<Provider[]>;
    createM3u(input: CreateM3uProviderInput): Promise<Provider>;
    refresh(providerId: string): Promise<void>;
    onImportProgress(callback: (progress: ImportProgress) => void): () => void;
  };
  catalog: {
    listLiveChannels(query: string, category: string | null): Promise<LiveChannel[]>;
    toggleFavorite(itemId: string, itemType: "live"): Promise<void>;
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
  providersRefresh: "providers:refresh",
  providersImportProgress: "providers:importProgress",
  catalogListLiveChannels: "catalog:listLiveChannels",
  catalogToggleFavorite: "catalog:toggleFavorite",
  playbackPlay: "playback:play",
  playbackPause: "playback:pause",
  playbackStop: "playback:stop",
  playbackSeek: "playback:seek",
  playbackOpenExternal: "playback:openExternal",
  playbackGetState: "playback:getState",
  playbackState: "playback:state"
} as const;
