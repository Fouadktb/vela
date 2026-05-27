import { BrowserWindow, app } from "electron";
import path from "node:path";
import type { ImportProgress, Provider } from "../../src/shared/providers/types.js";
import { importM3uProvider } from "./imports/importM3uProvider.js";
import {
  importXtreamLivePrograms,
  importXtreamProvider,
  importXtreamSeriesEpisodes
} from "./imports/importXtreamProvider.js";
import { registerIpcHandlers } from "./ipc/registerIpcHandlers.js";
import { openInExternalPlayer } from "./playback/externalPlayer.js";
import { createMpvController } from "./playback/mpvController.js";
import { ipcChannels } from "../../src/shared/ipc/types.js";
import { createCatalogRepository } from "./storage/catalogRepository.js";
import { openAppDatabase } from "./storage/database.js";
import { createProviderRepository } from "./storage/providerRepository.js";
import { createMainWindow } from "./windows/createMainWindow.js";

app.setName("Vela");
app.setPath("userData", path.join(app.getPath("appData"), "IPTV Player"));

async function boot(): Promise<void> {
  await app.whenReady();

  const db = openAppDatabase();
  const providerRepository = createProviderRepository(db);
  const catalogRepository = createCatalogRepository(db);
  const emitToRenderer = (channel: string, payload: unknown) => {
    for (const window of BrowserWindow.getAllWindows()) {
      if (!window.isDestroyed() && !window.webContents.isDestroyed()) {
        window.webContents.send(channel, payload);
      }
    }
  };
  const mpvController = createMpvController({
    catalogRepository,
    onStateChange: (state) => emitToRenderer(ipcChannels.playbackState, state)
  });

  createMainWindow();

  registerIpcHandlers({
    emitToRenderer,
    providerRepository,
    catalogRepository,
    importM3uProvider,
    importXtreamProvider,
    importXtreamSeriesEpisodes,
    importXtreamLivePrograms,
    mpvController,
    openInExternalPlayer
  });

  void refreshStaleProviders({
    providerRepository,
    catalogRepository,
    emitToRenderer
  });

  app.on("before-quit", () => {
    void mpvController.stop();
  });

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
}

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});

void boot();

async function refreshStaleProviders(deps: {
  providerRepository: ReturnType<typeof createProviderRepository>;
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  emitToRenderer(channel: string, payload: unknown): void;
}): Promise<void> {
  for (const provider of deps.providerRepository.list().filter(isProviderDueForAutoRefresh)) {
    try {
      await refreshProvider(provider, deps);
    } catch {
      // Importers already emit a sanitized failure message; keep startup non-blocking.
    }
  }
}

function isProviderDueForAutoRefresh(provider: Provider, nowMs: number = Date.now()): boolean {
  if (!provider.autoRefreshEnabled) {
    return false;
  }

  if (!provider.lastRefreshAt) {
    return true;
  }

  const lastRefreshMs = Date.parse(provider.lastRefreshAt);
  if (!Number.isFinite(lastRefreshMs)) {
    return true;
  }

  return nowMs - lastRefreshMs >= provider.autoRefreshIntervalHours * 60 * 60 * 1000;
}

async function refreshProvider(
  provider: Provider,
  deps: {
    providerRepository: ReturnType<typeof createProviderRepository>;
    catalogRepository: ReturnType<typeof createCatalogRepository>;
    emitToRenderer(channel: string, payload: unknown): void;
  }
): Promise<void> {
  const importDeps = {
    providerRepository: deps.providerRepository,
    catalogRepository: deps.catalogRepository,
    emitProgress: (progress: ImportProgress) => deps.emitToRenderer(ipcChannels.providersImportProgress, progress)
  };

  if (provider.type === "m3u") {
    await importM3uProvider(provider, importDeps);
    return;
  }

  await importXtreamProvider(provider, importDeps);
}
