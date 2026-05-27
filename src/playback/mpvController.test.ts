import { describe, expect, it, vi } from "vitest";
import { EventEmitter } from "node:events";
import type { PlaybackState } from "../shared/playback/types";
import {
  buildExternalPlayerArgs,
  waitForExternalPlayerLaunch
} from "../../electron/main/playback/externalPlayer.js";
import {
  buildMpvArgs,
  buildMpvIpcCommand,
  buildMpvIpcPath,
  resolveMpvExecutablePath,
  sanitizePlaybackDiagnostic,
  toPlaybackTrackState
} from "../../electron/main/playback/mpvController.js";

describe("mpv playback helpers", () => {
  it("builds mpv launch arguments for a stream", () => {
    const args = buildMpvArgs({
      ipcPath: "/tmp/iptv-player-mpv.sock",
      url: "https://example.test/live.m3u8",
      title: "BBC One",
      platform: "linux"
    });

    expect(args).toEqual(
      expect.arrayContaining([
        "--no-config",
        "--player-operation-mode=pseudo-gui",
        "--force-window=immediate",
        "--fs=yes",
        "--border=no",
        "--hwdec=auto-safe",
        "--osc=no",
        "--osd-level=0",
        "--input-default-bindings=no",
        "--input-ipc-server=/tmp/iptv-player-mpv.sock",
        "--title=BBC One"
      ])
    );
    expect(args.at(-1)).toBe("https://example.test/live.m3u8");
  });

  it("disables mpv's own UI because Vela renders the theater controls", () => {
    const args = buildMpvArgs({
      ipcPath: "/tmp/iptv-player-mpv.sock",
      url: "https://example.test/live.m3u8",
      title: "BBC One",
      platform: "linux"
    });

    expect(args).toContain("--osc=no");
    expect(args).toContain("--osd-level=0");
    expect(args).toContain("--input-default-bindings=no");
    expect(args.some((arg) => arg.startsWith("--script-opts=osc-"))).toBe(false);
  });

  it("adds macOS player-window material options only on macOS", () => {
    const macArgs = buildMpvArgs({
      ipcPath: "/tmp/iptv-player-mpv.sock",
      url: "https://example.test/live.m3u8",
      title: "BBC One",
      platform: "darwin"
    });
    const windowsArgs = buildMpvArgs({
      ipcPath: "\\\\.\\pipe\\iptv-player-mpv-1",
      url: "https://example.test/live.m3u8",
      title: "BBC One",
      platform: "win32"
    });

    expect(macArgs).toContain("--macos-app-activation-policy=accessory");
    expect(macArgs).toContain("--focus-on=never");
    expect(windowsArgs.some((arg) => arg.startsWith("--macos-"))).toBe(false);
  });

  it("prefers an explicit mpv path before PATH lookup", () => {
    expect(
      resolveMpvExecutablePath({
        env: { MPV_PATH: "/Applications/mpv.app/Contents/MacOS/mpv", PATH: "/usr/bin" },
        platform: "darwin",
        resourcesPath: "/Applications/IPTV Player.app/Contents/Resources",
        existsSync: () => false
      })
    ).toBe("/Applications/mpv.app/Contents/MacOS/mpv");
  });

  it("finds common macOS mpv install paths when Finder does not provide a shell PATH", () => {
    expect(
      resolveMpvExecutablePath({
        env: { PATH: "/usr/bin:/bin" },
        platform: "darwin",
        resourcesPath: "/Applications/IPTV Player.app/Contents/Resources",
        existsSync: (candidate) => candidate === "/opt/homebrew/bin/mpv"
      })
    ).toBe("/opt/homebrew/bin/mpv");
  });

  it("prefers the bundled macOS mpv.app before system paths", () => {
    const resourcesPath = "/Applications/IPTV Player.app/Contents/Resources";
    const bundledMpvPath = `${resourcesPath}/bin/mpv/darwin/mpv.app/Contents/MacOS/mpv`;

    expect(
      resolveMpvExecutablePath({
        env: { PATH: "/usr/bin:/bin" },
        platform: "darwin",
        resourcesPath,
        existsSync: (candidate) => candidate === bundledMpvPath || candidate === "/opt/homebrew/bin/mpv"
      })
    ).toBe(bundledMpvPath);
  });

  it("finds common Windows mpv install paths before PATH lookup", () => {
    expect(
      resolveMpvExecutablePath({
        env: { ProgramFiles: "C:\\Program Files", PATH: "C:\\Windows\\System32" },
        platform: "win32",
        resourcesPath: "C:\\Users\\me\\AppData\\Local\\Programs\\IPTV Player\\resources",
        existsSync: (candidate) => candidate === "C:\\Program Files\\mpv\\mpv.exe"
      })
    ).toBe("C:\\Program Files\\mpv\\mpv.exe");
  });

  it("prefers the bundled Windows mpv before system paths", () => {
    const resourcesPath = "C:\\Users\\me\\AppData\\Local\\Programs\\IPTV Player\\resources";
    const bundledMpvPath = `${resourcesPath}\\bin\\mpv\\win32\\mpv.exe`;

    expect(
      resolveMpvExecutablePath({
        env: { ProgramFiles: "C:\\Program Files", PATH: "C:\\Windows\\System32" },
        platform: "win32",
        resourcesPath,
        existsSync: (candidate) => candidate === bundledMpvPath || candidate === "C:\\Program Files\\mpv\\mpv.exe"
      })
    ).toBe(bundledMpvPath);
  });

  it("detects when mpv is unavailable instead of failing with a generic spawn error", () => {
    expect(
      resolveMpvExecutablePath({
        env: { PATH: "/usr/bin" },
        platform: "darwin",
        resourcesPath: "/Applications/IPTV Player.app/Contents/Resources",
        existsSync: () => false
      })
    ).toBeNull();
  });

  it("builds newline-delimited JSON IPC commands", () => {
    expect(buildMpvIpcCommand(["seek", 10, "relative"])).toBe('{"command":["seek",10,"relative"]}\n');
  });

  it("normalizes mpv video, audio, and subtitle tracks for renderer menus", () => {
    expect(
      toPlaybackTrackState(
        [
          { id: 1, type: "video", title: "Main Video", default: true, selected: true },
          { id: 1, type: "audio", title: "English Stereo", lang: "eng", default: true, selected: false },
          { id: 2, type: "audio", title: "Director Commentary", lang: "eng", default: false, selected: true },
          { id: 3, type: "sub", title: "English CC", lang: "eng", selected: false }
        ],
        1,
        2,
        "no"
      )
    ).toEqual({
      videoTracks: [
        {
          id: 1,
          type: "video",
          title: "Main Video",
          language: null,
          isDefault: true,
          isSelected: true
        }
      ],
      audioTracks: [
        {
          id: 1,
          type: "audio",
          title: "English Stereo",
          language: "eng",
          isDefault: true,
          isSelected: false
        },
        {
          id: 2,
          type: "audio",
          title: "Director Commentary",
          language: "eng",
          isDefault: false,
          isSelected: true
        }
      ],
      subtitleTracks: [
        {
          id: 3,
          type: "subtitle",
          title: "English CC",
          language: "eng",
          isDefault: false,
          isSelected: false
        }
      ],
      selectedVideoTrackId: 1,
      selectedAudioTrackId: 2,
      selectedSubtitleTrackId: null
    });
  });

  it("builds Windows-safe mpv named pipe paths", () => {
    expect(buildMpvIpcPath("win32", "abc-123")).toBe("\\\\.\\pipe\\iptv-player-mpv-abc-123");
  });

  it("builds filesystem mpv IPC socket paths for POSIX platforms", () => {
    expect(buildMpvIpcPath("darwin", "abc-123")).toMatch(/\/iptv-player-mpv-abc-123\.sock$/);
  });

  it("redacts URLs and common secret query values from diagnostics", () => {
    const diagnostic = sanitizePlaybackDiagnostic(
      "stream failed https://user:pass@example.test/live.m3u8?username=bob&password=hunter2&token=abc&expires=123"
    );

    expect(diagnostic).not.toContain("example.test");
    expect(diagnostic).not.toContain("hunter2");
    expect(diagnostic).not.toContain("bob");
    expect(diagnostic).not.toContain("abc");
    expect(diagnostic).not.toContain("123");
    expect(diagnostic).toContain("[URL REDACTED]");
  });

  it("redacts bare secret key-value pairs from diagnostics", () => {
    const diagnostic = sanitizePlaybackDiagnostic("mpv failed username=bob password=hunter2 session=abc123");

    expect(diagnostic).not.toContain("bob");
    expect(diagnostic).not.toContain("hunter2");
    expect(diagnostic).not.toContain("abc123");
    expect(diagnostic).toContain("username=REDACTED");
    expect(diagnostic).toContain("password=REDACTED");
    expect(diagnostic).toContain("session=REDACTED");
  });

  it("caps sanitized diagnostics", () => {
    expect(sanitizePlaybackDiagnostic("x".repeat(1_000))).toHaveLength(300);
  });

  it("keeps video and audio track metadata when mpv has no subtitle selection", async () => {
    vi.resetModules();
    vi.useFakeTimers();
    const originalMpvPath = process.env.MPV_PATH;
    process.env.MPV_PATH = "/usr/bin/mpv-test";

    class MockChildProcess extends EventEmitter {
      public killed = false;
      public stderr = new EventEmitter();

      kill(): boolean {
        this.killed = true;
        this.emit("exit", null, "SIGTERM");
        return true;
      }
    }

    let childProcess: MockChildProcess | null = null;
    const spawnMock = vi.fn(() => {
      childProcess = new MockChildProcess();
      return childProcess;
    });
    vi.doMock("node:child_process", () => ({
      default: { spawn: spawnMock },
      spawn: spawnMock
    }));
    const createConnectionMock = vi.fn(() => createMockMpvSocket());
    vi.doMock("node:net", () => ({
      default: { createConnection: createConnectionMock },
      createConnection: createConnectionMock
    }));

    try {
      const { createMpvController } = await import("../../electron/main/playback/mpvController.js");
      const stateChanges: PlaybackState[] = [];
      const playerWindow = {
        open: vi.fn(),
        raise: vi.fn(),
        close: vi.fn()
      };
      const catalogRepository = {
        getLiveChannel: vi.fn(() => ({
          id: "live-1",
          type: "live",
          name: "BBC One",
          stream: { url: "https://example.test/live.m3u8" }
        })),
        getMovie: vi.fn(),
        getEpisode: vi.fn(),
        markRecentlyWatched: vi.fn()
      };
      const controller = createMpvController({
        catalogRepository: catalogRepository as never,
        onStateChange: (state) => {
          stateChanges.push(state);
        },
        playerWindow
      });

      await controller.play({ itemId: "live-1", itemType: "live" });
      expect(childProcess).toBeInstanceOf(MockChildProcess);
      (childProcess as unknown as MockChildProcess).emit("spawn");
      await vi.advanceTimersByTimeAsync(400);

      const stateWithTracks = [...stateChanges]
        .reverse()
        .find((state) => state.videoTracks.length > 0 || state.audioTracks.length > 0);

      expect(stateWithTracks?.videoTracks).toHaveLength(1);
      expect(stateWithTracks?.audioTracks).toHaveLength(1);
      expect(stateWithTracks?.subtitleTracks).toHaveLength(0);

      await controller.stop();
    } finally {
      vi.useRealTimers();
      vi.doUnmock("node:child_process");
      vi.doUnmock("node:net");
      if (originalMpvPath === undefined) {
        delete process.env.MPV_PATH;
      } else {
        process.env.MPV_PATH = originalMpvPath;
      }
    }
  });

  it("waits for the mpv process to exit before dismissing the theater window on stop", async () => {
    vi.resetModules();
    const originalMpvPath = process.env.MPV_PATH;
    process.env.MPV_PATH = "/usr/bin/mpv-test";

    class MockChildProcess extends EventEmitter {
      public killed = false;
      public stderr = new EventEmitter();

      kill(): boolean {
        this.killed = true;
        return true;
      }
    }

    let childProcess: MockChildProcess | null = null;
    const spawnMock = vi.fn(() => {
      childProcess = new MockChildProcess();
      return childProcess;
    });
    vi.doMock("node:child_process", () => ({
      default: { spawn: spawnMock },
      spawn: spawnMock
    }));

    try {
      const { createMpvController } = await import("../../electron/main/playback/mpvController.js");
      const playerWindow = {
        open: vi.fn(),
        raise: vi.fn(),
        close: vi.fn()
      };
      const catalogRepository = {
        getLiveChannel: vi.fn(() => ({
          id: "live-1",
          type: "live",
          name: "BBC One",
          stream: { url: "https://example.test/live.m3u8" }
        })),
        getMovie: vi.fn(),
        getEpisode: vi.fn(),
        markRecentlyWatched: vi.fn()
      };
      const controller = createMpvController({
        catalogRepository: catalogRepository as never,
        onStateChange: vi.fn(),
        playerWindow
      });

      await controller.play({ itemId: "live-1", itemType: "live" });
      expect(childProcess).toBeInstanceOf(MockChildProcess);
      (childProcess as unknown as MockChildProcess).emit("spawn");

      await controller.stop();

      expect(playerWindow.close).not.toHaveBeenCalled();

      (childProcess as unknown as MockChildProcess).emit("exit", null, "SIGTERM");

      expect(playerWindow.close).toHaveBeenCalledTimes(1);
    } finally {
      vi.doUnmock("node:child_process");
      if (originalMpvPath === undefined) {
        delete process.env.MPV_PATH;
      } else {
        process.env.MPV_PATH = originalMpvPath;
      }
    }
  });

  it("builds external player arguments without exposing extra data", () => {
    expect(buildExternalPlayerArgs("https://example.test/live.m3u8")).toEqual(["https://example.test/live.m3u8"]);
  });

  it("rejects when an external player launch fails", async () => {
    const child = new EventEmitter();

    const launch = waitForExternalPlayerLaunch(child, 100);
    child.emit("error", new Error("spawn ENOENT https://example.test/live.m3u8?password=hunter2"));

    await expect(launch).rejects.toThrow("External player failed to launch");
  });
});

function createMockMpvSocket(): EventEmitter & {
  write(data: string): boolean;
  end(data?: string, callback?: () => void): void;
  destroy(): void;
} {
  const socket = new EventEmitter() as EventEmitter & {
    write(data: string): boolean;
    end(data?: string, callback?: () => void): void;
    destroy(): void;
  };
  socket.write = (data: string) => {
    const request = JSON.parse(data) as { request_id: number; command: [string, string] };
    const propertyName = request.command[1];
    const response =
      propertyName === "track-list"
        ? {
            request_id: request.request_id,
            error: "success",
            data: [
              { id: 1, type: "video", title: "Main Video", selected: true },
              { id: 1, type: "audio", title: "English", selected: true }
            ]
          }
        : propertyName === "vid" || propertyName === "aid"
          ? { request_id: request.request_id, error: "success", data: 1 }
          : { request_id: request.request_id, error: "property unavailable" };

    queueMicrotask(() => {
      socket.emit("data", Buffer.from(`${JSON.stringify(response)}\n`));
    });
    return true;
  };
  socket.end = (_data?: string, callback?: () => void) => {
    callback?.();
  };
  socket.destroy = () => undefined;

  queueMicrotask(() => {
    socket.emit("connect");
  });

  return socket;
}
