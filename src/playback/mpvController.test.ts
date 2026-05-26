import { describe, expect, it } from "vitest";
import { buildExternalPlayerArgs } from "../../electron/main/playback/externalPlayer.js";
import { buildMpvArgs, buildMpvIpcCommand } from "../../electron/main/playback/mpvController.js";

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

  it("builds newline-delimited JSON IPC commands", () => {
    expect(buildMpvIpcCommand(["seek", 10, "relative"])).toBe('{"command":["seek",10,"relative"]}\n');
  });

  it("builds external player arguments without exposing extra data", () => {
    expect(buildExternalPlayerArgs("https://example.test/live.m3u8")).toEqual(["https://example.test/live.m3u8"]);
  });
});
