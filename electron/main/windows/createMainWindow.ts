import { BrowserWindow } from "electron";
import path from "node:path";

let mediaCorsHeadersRegistered = false;

export function createMainWindow(): BrowserWindow {
  const preloadPath = path.join(__dirname, "../../preload/index.js");

  const window = new BrowserWindow({
    width: 1280,
    height: 820,
    minWidth: 980,
    minHeight: 640,
    title: "Vela",
    backgroundColor: "#111111",
    webPreferences: {
      preload: preloadPath,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  registerMediaCorsHeaders(window);

  const devServerUrl = process.env.VITE_DEV_SERVER_URL;
  if (devServerUrl) {
    void window.loadURL(devServerUrl);
    if (process.env.OPEN_DEVTOOLS === "1") {
      window.webContents.openDevTools({ mode: "detach" });
    }
  } else {
    void window.loadFile(path.join(__dirname, "../../../../dist/index.html"));
  }

  return window;
}

function registerMediaCorsHeaders(window: BrowserWindow): void {
  if (mediaCorsHeadersRegistered) {
    return;
  }
  mediaCorsHeadersRegistered = true;

  window.webContents.session.webRequest.onHeadersReceived(
    {
      urls: ["http://*/*", "https://*/*"]
    },
    (details, callback) => {
      const responseHeaders = {
        ...details.responseHeaders,
        "Access-Control-Allow-Headers": ["*"],
        "Access-Control-Allow-Methods": ["GET, HEAD, OPTIONS"],
        "Access-Control-Allow-Origin": ["*"]
      };
      callback({ responseHeaders });
    }
  );
}
