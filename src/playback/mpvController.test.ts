import { describe, expect, it } from "vitest";
import { EventEmitter } from "node:events";
import {
  buildExternalPlayerArgs,
  waitForExternalPlayerLaunch
} from "../../electron/main/playback/externalPlayer.js";
import {
  buildMpvArgs,
  buildMpvIpcCommand,
  buildMpvIpcPath,
  resolveMpvExecutablePath,
  sanitizePlaybackDiagnostic
} from "../../electron/main/playback/mpvController.js";

describe("mpv playback helpers", () => {
  it("builds mpv launch arguments for a stream", () => {
    expect(
      buildMpvArgs({
        ipcPath: "/tmp/iptv-player-mpv.sock",
        url: "https://example.test/live.m3u8",
        title: "BBC One"
      })
    ).toEqual([
      "--force-window=yes",
      "--idle=no",
      "--input-ipc-server=/tmp/iptv-player-mpv.sock",
      "--title=BBC One",
      "https://example.test/live.m3u8"
    ]);
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
