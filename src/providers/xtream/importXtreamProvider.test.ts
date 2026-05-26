import { describe, expect, it, vi } from "vitest";
import {
  importXtreamLivePrograms,
  importXtreamProvider,
  importXtreamSeriesEpisodes
} from "../../../electron/main/imports/importXtreamProvider.js";
import type { LiveChannel, Series } from "../../shared/catalog/types.js";
import type { ImportProgress, Provider } from "../../shared/providers/types.js";

describe("importXtreamProvider", () => {
  it("imports live channels from the Xtream player API", async () => {
    const fetch = vi
      .spyOn(globalThis, "fetch")
      .mockResolvedValueOnce(
        new Response(JSON.stringify([{ category_id: "10", category_name: "News" }]), { status: 200 })
      )
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify([
            {
              name: "City News",
              stream_id: 123,
              stream_icon: "https://images.example.test/news.png",
              epg_channel_id: "city.news",
              category_id: "10"
            }
          ]),
          { status: 200 }
        )
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify([{ category_id: "20", category_name: "Movies" }]), { status: 200 })
      )
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify([
            {
              name: "City Movie",
              stream_id: 456,
              stream_icon: "https://images.example.test/movie.png",
              category_id: "20",
              container_extension: "mp4",
              rating: "7.4",
              year: "2025"
            }
          ]),
          { status: 200 }
        )
      )
      .mockResolvedValueOnce(
        new Response(JSON.stringify([{ category_id: "30", category_name: "Series" }]), { status: 200 })
      )
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify([
            {
              name: "City Series",
              series_id: 789,
              cover: "https://images.example.test/series.png",
              category_id: "30"
            }
          ]),
          { status: 200 }
        )
      );
    const replaceLiveChannelsForProvider = vi.fn();
    const replaceMoviesForProvider = vi.fn();
    const replaceSeriesForProvider = vi.fn();
    const markRefreshed = vi.fn();
    const progress: ImportProgress[] = [];

    await importXtreamProvider(xtreamProvider(), {
      providerRepository: { markRefreshed } as never,
      catalogRepository: { replaceLiveChannelsForProvider, replaceMoviesForProvider, replaceSeriesForProvider } as never,
      emitProgress: (event) => progress.push(event)
    });

    expect(fetch).toHaveBeenNthCalledWith(
      1,
      "https://panel.example.test/player_api.php?username=user&password=pass&action=get_live_categories",
      expect.any(Object)
    );
    expect(fetch).toHaveBeenNthCalledWith(
      2,
      "https://panel.example.test/player_api.php?username=user&password=pass&action=get_live_streams",
      expect.any(Object)
    );
    expect(replaceLiveChannelsForProvider).toHaveBeenCalledWith("provider-xtream", [
      expect.objectContaining({
        id: "provider-xtream:live:123",
        name: "City News",
        logoUrl: "https://images.example.test/news.png",
        category: "News",
        stream: {
          providerType: "xtream",
          url: "https://panel.example.test/live/user/pass/123.ts",
          streamId: "123",
          containerExtension: "ts"
        }
      })
    ]);
    expect(replaceMoviesForProvider).toHaveBeenCalledWith("provider-xtream", [
      expect.objectContaining({
        id: "provider-xtream:movie:456",
        title: "City Movie",
        posterUrl: "https://images.example.test/movie.png",
        category: "Movies",
        year: 2025,
        rating: "7.4",
        stream: {
          providerType: "xtream",
          url: "https://panel.example.test/movie/user/pass/456.mp4",
          streamId: "456",
          containerExtension: "mp4"
        }
      })
    ]);
    expect(replaceSeriesForProvider).toHaveBeenCalledWith("provider-xtream", [
      expect.objectContaining({
        id: "provider-xtream:series:789",
        title: "City Series",
        posterUrl: "https://images.example.test/series.png",
        category: "Series"
      })
    ]);
    expect(markRefreshed).toHaveBeenCalledWith("provider-xtream");
    expect(progress.at(-1)?.message).toBe("Imported 1 live channel, 1 movie, and 1 series");
  });

  it("turns rejected Xtream API requests into a clear safe error", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue({ ok: false, status: 884 } as Response);
    const progress: ImportProgress[] = [];

    await expect(
      importXtreamProvider(xtreamProvider(), {
        providerRepository: { markRefreshed: () => undefined } as never,
        catalogRepository: {
          replaceLiveChannelsForProvider: () => undefined,
          replaceMoviesForProvider: () => undefined,
          replaceSeriesForProvider: () => undefined
        } as never,
        emitProgress: (event) => progress.push(event)
      })
    ).rejects.toThrow("Provider server rejected the Xtream API request with HTTP 884");

    expect(progress.at(-1)?.message).toBe("Provider server rejected the Xtream API request with HTTP 884");
    expect(progress.map((event) => event.message).join("\n")).not.toContain("user");
    expect(progress.map((event) => event.message).join("\n")).not.toContain("pass");
  });

  it("imports episodes for a selected series on demand", async () => {
    const fetch = vi.spyOn(globalThis, "fetch").mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          episodes: {
            "1": [
              {
                id: 555,
                episode_num: 2,
                title: "The Second",
                container_extension: "mp4",
                info: {
                  duration_secs: "1800"
                }
              }
            ]
          }
        }),
        { status: 200 }
      )
    );
    const replaceEpisodesForSeries = vi.fn();

    const episodes = await importXtreamSeriesEpisodes(xtreamProvider(), series(), {
      catalogRepository: { replaceEpisodesForSeries } as never
    });

    expect(fetch).toHaveBeenCalledWith(
      "https://panel.example.test/player_api.php?username=user&password=pass&action=get_series_info&series_id=789",
      expect.any(Object)
    );
    expect(episodes).toEqual([
      expect.objectContaining({
        id: "provider-xtream:episode:555",
        providerId: "provider-xtream",
        seriesId: "provider-xtream:series:789",
        seasonNumber: 1,
        episodeNumber: 2,
        title: "The Second",
        durationSeconds: 1800,
        stream: {
          providerType: "xtream",
          url: "https://panel.example.test/series/user/pass/555.mp4",
          streamId: "555",
          containerExtension: "mp4"
        }
      })
    ]);
    expect(replaceEpisodesForSeries).toHaveBeenCalledWith("provider-xtream", "provider-xtream:series:789", episodes);
  });

  it("imports short EPG programs for a selected live channel on demand", async () => {
    const fetch = vi.spyOn(globalThis, "fetch").mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          epg_listings: [
            {
              id: "program-1",
              title: Buffer.from("Midday News", "utf8").toString("base64"),
              description: Buffer.from("Headlines and weather.", "utf8").toString("base64"),
              start_timestamp: "1779796800",
              stop_timestamp: "1779798600"
            }
          ]
        }),
        { status: 200 }
      )
    );
    const replaceLiveProgramsForChannel = vi.fn();

    const programs = await importXtreamLivePrograms(xtreamProvider(), liveChannel(), {
      catalogRepository: { replaceLiveProgramsForChannel } as never
    });

    expect(fetch).toHaveBeenCalledWith(
      "https://panel.example.test/player_api.php?username=user&password=pass&action=get_short_epg&stream_id=123&limit=12",
      expect.any(Object)
    );
    expect(programs).toEqual([
      {
        id: "provider-xtream:live:123:1779796800",
        providerId: "provider-xtream",
        channelId: "provider-xtream:live:123",
        title: "Midday News",
        description: "Headlines and weather.",
        startAt: "2026-05-26T12:00:00.000Z",
        endAt: "2026-05-26T12:30:00.000Z"
      }
    ]);
    expect(replaceLiveProgramsForChannel).toHaveBeenCalledWith(
      "provider-xtream",
      "provider-xtream:live:123",
      programs
    );
  });
});

function xtreamProvider(): Provider {
  return {
    id: "provider-xtream",
    type: "xtream",
    name: "Xtream",
    source: "https://panel.example.test",
    username: "user",
    password: "pass",
    createdAt: "2026-05-26T08:00:00.000Z",
    updatedAt: "2026-05-26T08:00:00.000Z",
    lastRefreshAt: null
  };
}

function series(): Series {
  return {
    type: "series",
    id: "provider-xtream:series:789",
    providerId: "provider-xtream",
    title: "City Series",
    posterUrl: null,
    category: "Series",
    lastSeenAt: "2026-05-26T08:00:00.000Z",
    isFavorite: false
  };
}

function liveChannel(): LiveChannel {
  return {
    type: "live",
    id: "provider-xtream:live:123",
    providerId: "provider-xtream",
    name: "City News",
    logoUrl: null,
    category: "News",
    stream: {
      providerType: "xtream",
      url: "https://panel.example.test/live/user/pass/123.ts",
      streamId: "123",
      containerExtension: "ts"
    },
    epgChannelId: "city.news",
    lastSeenAt: "2026-05-26T08:00:00.000Z",
    isFavorite: false
  };
}
