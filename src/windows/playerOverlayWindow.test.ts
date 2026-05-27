import { EventEmitter } from "node:events";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

class MockBrowserWindow extends EventEmitter {
  public destroyed = false;
  public hide = vi.fn();
  public show = vi.fn();
  public focus = vi.fn();
  public moveTop = vi.fn();
  public restore = vi.fn();
  public loadURL = vi.fn();
  public loadFile = vi.fn();
  public setAlwaysOnTop = vi.fn();
  public setVisibleOnAllWorkspaces = vi.fn();
  public setMenuBarVisibility = vi.fn();

  isDestroyed(): boolean {
    return this.destroyed;
  }

  isMinimized(): boolean {
    return false;
  }

  close(): void {
    let wasPrevented = false;
    const event = {
      preventDefault: vi.fn(() => {
        wasPrevented = true;
      })
    };

    this.emit("close", event);

    if (!wasPrevented) {
      this.destroyed = true;
      this.emit("closed");
    }
  }
}

describe("playerOverlayWindow", () => {
  let windows: MockBrowserWindow[];

  beforeEach(() => {
    vi.resetModules();
    windows = [];
    vi.doMock("electron", () => ({
      BrowserWindow: class extends MockBrowserWindow {
        constructor() {
          super();
          windows.push(this);
        }
      },
      screen: {
        getPrimaryDisplay: () => ({
          bounds: { x: 0, y: 0, width: 1280, height: 720 }
        })
      }
    }));
  });

  afterEach(() => {
    vi.doUnmock("electron");
  });

  it("treats a user close as a player stop request instead of destroying the app surface", async () => {
    const onUserClose = vi.fn();
    const { createPlayerOverlayWindowController } = await import(
      "../../electron/main/windows/playerOverlayWindow.js"
    );
    const controller = createPlayerOverlayWindowController({ onUserClose });

    controller.open();
    windows[0].close();

    expect(windows[0].hide).toHaveBeenCalled();
    expect(windows[0].destroyed).toBe(false);
    expect(onUserClose).toHaveBeenCalledTimes(1);
  });

  it("hides controller-owned closes and returns focus to the app without re-entering the user close callback", async () => {
    const onUserClose = vi.fn();
    const onDismiss = vi.fn();
    const { createPlayerOverlayWindowController } = await import(
      "../../electron/main/windows/playerOverlayWindow.js"
    );
    const controller = createPlayerOverlayWindowController({ onUserClose, onDismiss });

    controller.open();
    controller.close();

    expect(windows[0].hide).toHaveBeenCalled();
    expect(windows[0].destroyed).toBe(false);
    expect(onUserClose).not.toHaveBeenCalled();
    expect(onDismiss).toHaveBeenCalledTimes(1);
  });
});
