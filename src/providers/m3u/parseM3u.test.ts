import { describe, expect, it } from "vitest";
import { parseM3u } from "./parseM3u";

describe("parseM3u", () => {
  it("parses extended M3U channels into normalized channel drafts", () => {
    const input = `#EXTM3U
#EXTINF:-1 tvg-id="bbc.one" tvg-logo="https://logo.test/bbc.png" group-title="News",BBC One
https://stream.test/bbc.m3u8
#EXTINF:-1 tvg-id="sky.sports" group-title="Sports",Sky Sports
https://stream.test/sky.ts`;

    const result = parseM3u(input, {
      providerId: "provider-1",
      nowIso: "2026-05-26T12:00:00.000Z"
    });

    expect(result.channels).toHaveLength(2);
    expect(result.channels[0]).toMatchObject({
      id: "provider-1:live:bbc-one",
      providerId: "provider-1",
      name: "BBC One",
      logoUrl: "https://logo.test/bbc.png",
      category: "News",
      epgChannelId: "bbc.one",
      stream: {
        providerType: "m3u",
        url: "https://stream.test/bbc.m3u8"
      },
      lastSeenAt: "2026-05-26T12:00:00.000Z"
    });
    expect(result.channels[1].category).toBe("Sports");
    expect(result.diagnostics).toEqual([]);
  });

  it("skips malformed entries and records diagnostics", () => {
    const input = `#EXTM3U
#EXTINF:-1 group-title="News",No URL
#EXTINF:-1,Valid Channel
https://stream.test/valid.m3u8`;

    const result = parseM3u(input, {
      providerId: "provider-1",
      nowIso: "2026-05-26T12:00:00.000Z"
    });

    expect(result.channels).toHaveLength(1);
    expect(result.channels[0].name).toBe("Valid Channel");
    expect(result.diagnostics).toContainEqual({
      line: 2,
      message: "EXTINF entry has no following stream URL"
    });
  });
});
