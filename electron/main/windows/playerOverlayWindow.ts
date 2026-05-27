import { BrowserWindow, screen } from "electron";
import path from "node:path";

let playerOverlayWindow: BrowserWindow | null = null;

interface CreatePlayerOverlayWindowControllerOptions {
  onUserClose?(): void;
  onDismiss?(): void;
}

export interface PlayerOverlayWindowController {
  open(): void;
  raise(): void;
  close(): void;
  destroy(): void;
}

export function createPlayerOverlayWindowController(
  options: CreatePlayerOverlayWindowControllerOptions = {}
): PlayerOverlayWindowController {
  return {
    open() {
      const window = ensurePlayerOverlayWindow(options);
      if (window.isMinimized()) {
        window.restore();
      }
      window.show();
      window.focus();
      window.moveTop();
    },
    raise() {
      if (!playerOverlayWindow || playerOverlayWindow.isDestroyed()) {
        return;
      }
      playerOverlayWindow.show();
      playerOverlayWindow.focus();
      playerOverlayWindow.moveTop();
    },
    close() {
      if (!playerOverlayWindow || playerOverlayWindow.isDestroyed()) {
        playerOverlayWindow = null;
        return;
      }
      playerOverlayWindow.hide();
      options.onDismiss?.();
    },
    destroy() {
      if (!playerOverlayWindow || playerOverlayWindow.isDestroyed()) {
        playerOverlayWindow = null;
        return;
      }
      const window = playerOverlayWindow;
      playerOverlayWindow = null;
      window.destroy();
    }
  };
}

function ensurePlayerOverlayWindow(options: CreatePlayerOverlayWindowControllerOptions): BrowserWindow {
  if (playerOverlayWindow && !playerOverlayWindow.isDestroyed()) {
    return playerOverlayWindow;
  }

  const display = screen.getPrimaryDisplay();
  const bounds = display.bounds;
  const preloadPath = path.join(__dirname, "../../preload/index.js");

  playerOverlayWindow = new BrowserWindow({
    x: bounds.x,
    y: bounds.y,
    width: bounds.width,
    height: bounds.height,
    minWidth: 720,
    minHeight: 420,
    title: "Vela Player",
    frame: false,
    transparent: true,
    backgroundColor: "#00000000",
    hasShadow: false,
    fullscreenable: true,
    skipTaskbar: false,
    alwaysOnTop: true,
    webPreferences: {
      preload: preloadPath,
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
      backgroundThrottling: false
    }
  });

  playerOverlayWindow.setAlwaysOnTop(true, "screen-saver");
  playerOverlayWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
  playerOverlayWindow.setMenuBarVisibility(false);

  const devServerUrl = process.env.VITE_DEV_SERVER_URL;
  if (devServerUrl) {
    void playerOverlayWindow.loadURL(`${devServerUrl}/#player-overlay`);
  } else {
    void playerOverlayWindow.loadFile(path.join(__dirname, "../../../../dist/index.html"), {
      hash: "player-overlay"
    });
  }

  playerOverlayWindow.on("close", (event) => {
    event.preventDefault();
    playerOverlayWindow?.hide();
    options.onUserClose?.();
  });

  playerOverlayWindow.on("closed", () => {
    playerOverlayWindow = null;
  });

  return playerOverlayWindow;
}
