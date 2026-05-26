const Module = require("node:module");
const path = require("node:path");

const exposedApis = new Map();
const originalLoad = Module._load;

Module._load = function loadWithElectronMock(request, parent, isMain) {
  if (request === "electron") {
    return {
      contextBridge: {
        exposeInMainWorld(name, api) {
          exposedApis.set(name, api);
        }
      },
      ipcRenderer: {
        invoke() {
          return Promise.resolve();
        },
        on() {
          return this;
        },
        off() {
          return this;
        }
      }
    };
  }

  return originalLoad.call(this, request, parent, isMain);
};

try {
  require(path.join(__dirname, "../dist-electron/electron/preload/index.js"));
} finally {
  Module._load = originalLoad;
}

const iptvApi = exposedApis.get("iptv");

if (
  !iptvApi?.providers?.createM3u ||
  !iptvApi?.providers?.createXtream ||
  !iptvApi?.providers?.delete ||
  !iptvApi?.catalog?.listLiveCategories ||
  !iptvApi?.catalog?.listMovies ||
  !iptvApi?.catalog?.listSeries ||
  !iptvApi?.catalog?.listEpisodesForSeries ||
  !iptvApi?.catalog?.listRecentlyWatched ||
  !iptvApi?.playback
) {
  throw new Error("Electron preload did not expose the expected iptv API");
}

console.log("Preload can be loaded by Electron and exposes window.iptv");
