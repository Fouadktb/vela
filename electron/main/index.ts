import { BrowserWindow, app } from "electron";
import { importM3uProvider } from "./imports/importM3uProvider.js";
import { registerIpcHandlers } from "./ipc/registerIpcHandlers.js";
import { openInExternalPlayer } from "./playback/externalPlayer.js";
import { createMpvController } from "./playback/mpvController.js";
import { createCatalogRepository } from "./storage/catalogRepository.js";
import { openAppDatabase } from "./storage/database.js";
import { createProviderRepository } from "./storage/providerRepository.js";
import { createMainWindow } from "./windows/createMainWindow.js";

app.setName("IPTV Player");

async function boot(): Promise<void> {
  await app.whenReady();

  const db = openAppDatabase();
  const providerRepository = createProviderRepository(db);
  const catalogRepository = createCatalogRepository(db);
  const mpvController = createMpvController({
    catalogRepository,
    onStateChange: () => undefined
  });

  createMainWindow();
  const emitToRenderer = (channel: string, payload: unknown) => {
    for (const window of BrowserWindow.getAllWindows()) {
      if (!window.isDestroyed() && !window.webContents.isDestroyed()) {
        window.webContents.send(channel, payload);
      }
    }
  };

  registerIpcHandlers({
    emitToRenderer,
    providerRepository,
    catalogRepository,
    importM3uProvider,
    mpvController,
    openInExternalPlayer
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
