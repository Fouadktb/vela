import type { IptvApi } from "../../shared/ipc/types";

declare global {
  interface Window {
    iptv?: IptvApi;
  }
}

export function getIptvApi(): IptvApi {
  if (!window.iptv) {
    return unavailableIptvApi;
  }

  return window.iptv;
}

function unavailable(): Promise<never> {
  return Promise.reject(new Error("IPTV preload API is unavailable. Restart the app and try again."));
}

const unavailableIptvApi: IptvApi = {
  providers: {
    list: unavailable,
    createM3u: unavailable,
    createXtream: unavailable,
    refresh: unavailable,
    updateAutoRefresh: unavailable,
    delete: unavailable,
    onImportProgress: () => () => undefined
  },
  catalog: {
    listLiveChannels: unavailable,
    listLiveCategories: unavailable,
    listCategoryViews: unavailable,
    toggleCategoryPin: unavailable,
    reorderPinnedCategories: unavailable,
    listLivePrograms: unavailable,
    listMovies: unavailable,
    listMovieCategories: unavailable,
    listSeries: unavailable,
    listSeriesCategories: unavailable,
    listEpisodesForSeries: unavailable,
    listRecentlyWatched: unavailable,
    toggleFavorite: unavailable
  },
  playback: {
    play: unavailable,
    pause: unavailable,
    stop: unavailable,
    seek: unavailable,
    selectVideoTrack: unavailable,
    selectAudioTrack: unavailable,
    selectSubtitleTrack: unavailable,
    openExternal: unavailable,
    getState: unavailable,
    onState: () => () => undefined
  }
};

export const iptvApi = getIptvApi();
