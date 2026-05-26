import { contextBridge, ipcRenderer } from "electron";
import { ipcChannels, type IptvApi } from "../../src/shared/ipc/types.js";
import type { ImportProgress } from "../../src/shared/providers/types.js";
import type { PlaybackState } from "../../src/shared/playback/types.js";

const api: IptvApi = {
  providers: {
    list: () => ipcRenderer.invoke(ipcChannels.providersList),
    createM3u: (input) => ipcRenderer.invoke(ipcChannels.providersCreateM3u, input),
    refresh: (providerId) => ipcRenderer.invoke(ipcChannels.providersRefresh, providerId),
    onImportProgress: (callback) => {
      const listener = (_event: Electron.IpcRendererEvent, progress: ImportProgress) => callback(progress);
      ipcRenderer.on(ipcChannels.providersImportProgress, listener);
      return () => ipcRenderer.off(ipcChannels.providersImportProgress, listener);
    }
  },
  catalog: {
    listLiveChannels: (query, category) =>
      ipcRenderer.invoke(ipcChannels.catalogListLiveChannels, { query, category }),
    toggleFavorite: (itemId, itemType) =>
      ipcRenderer.invoke(ipcChannels.catalogToggleFavorite, { itemId, itemType })
  },
  playback: {
    play: (request) => ipcRenderer.invoke(ipcChannels.playbackPlay, request),
    pause: () => ipcRenderer.invoke(ipcChannels.playbackPause),
    stop: () => ipcRenderer.invoke(ipcChannels.playbackStop),
    seek: (request) => ipcRenderer.invoke(ipcChannels.playbackSeek, request),
    openExternal: (request) => ipcRenderer.invoke(ipcChannels.playbackOpenExternal, request),
    getState: () => ipcRenderer.invoke(ipcChannels.playbackGetState),
    onState: (callback) => {
      const listener = (_event: Electron.IpcRendererEvent, state: PlaybackState) => callback(state);
      ipcRenderer.on(ipcChannels.playbackState, listener);
      return () => ipcRenderer.off(ipcChannels.playbackState, listener);
    }
  }
};

contextBridge.exposeInMainWorld("iptv", api);
