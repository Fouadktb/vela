import { BrowserWindow } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function createMainWindow(): BrowserWindow {
  const preloadPath = path.join(__dirname, "../../preload/index.js");

  const window = new BrowserWindow({
    width: 1280,
    height: 820,
    minWidth: 980,
    minHeight: 640,
    title: "IPTV Player",
    backgroundColor: "#111111",
    webPreferences: {
      preload: preloadPath,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  const devServerUrl = process.env.VITE_DEV_SERVER_URL;
  if (devServerUrl) {
    void window.loadURL(devServerUrl);
    window.webContents.openDevTools({ mode: "detach" });
  } else {
    void window.loadFile(path.join(__dirname, "../../../../dist/index.html"));
  }

  return window;
}
