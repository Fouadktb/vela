import { describe, expect, it } from "vitest";
import { getPreferredInAppEngine } from "../../electron/main/playback/resolvePlaybackSource";

describe("resolvePlaybackSource", () => {
  it("chooses in-app engines for browser and transmuxable streams", () => {
    expect(getPreferredInAppEngine("http://example.test/live/abc/123.ts", "live")).toBe("mpegts");
    expect(getPreferredInAppEngine("http://example.test/channel.m3u8", "live")).toBe("hls");
    expect(getPreferredInAppEngine("http://example.test/movie.mp4", "movie")).toBe("native");
  });

  it("uses fallback for containers that Chromium cannot reliably play", () => {
    expect(getPreferredInAppEngine("http://example.test/movie.mkv", "movie")).toBe("fallback");
    expect(getPreferredInAppEngine("http://example.test/movie.avi", "movie")).toBe("fallback");
  });
});
