import { BrowserWindow, app } from "electron";
import { createMainWindow } from "./windows/createMainWindow.js";

app.setName("IPTV Player");

async function boot(): Promise<void> {
  await app.whenReady();
  createMainWindow();

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
