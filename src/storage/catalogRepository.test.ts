import Database from "better-sqlite3";
import { describe, expect, it } from "vitest";
import { createSchema } from "../../electron/main/storage/database";
import { createCatalogRepository } from "../../electron/main/storage/catalogRepository";
import type { Episode, LiveChannel, LiveProgram, Movie, Series } from "../shared/catalog/types";

function channel(overrides: Partial<LiveChannel> = {}): LiveChannel {
  return {
    type: "live",
    id: "provider-1:live:bbc-one",
    providerId: "provider-1",
    name: "BBC One",
    logoUrl: null,
    category: "News",
    stream: {
      providerType: "m3u",
      url: "https://stream.test/bbc.m3u8"
    },
    epgChannelId: "bbc.one",
    lastSeenAt: "2026-05-26T12:00:00.000Z",
    isFavorite: false,
    ...overrides
  };
}

function movie(overrides: Partial<Movie> = {}): Movie {
  return {
    type: "movie",
    id: "provider-1:movie:movie-1",
    providerId: "provider-1",
    title: "City Movie",
    posterUrl: null,
    category: "Action",
    year: 2025,
    rating: "7.1",
    stream: {
      providerType: "xtream",
      url: "https://stream.test/movie.mp4",
      streamId: "movie-1",
      containerExtension: "mp4"
    },
    lastSeenAt: "2026-05-26T12:00:00.000Z",
    isFavorite: false,
    ...overrides
  };
}

function series(overrides: Partial<Series> = {}): Series {
  return {
    type: "series",
    id: "provider-1:series:series-1",
    providerId: "provider-1",
    title: "City Series",
    posterUrl: null,
    category: "Drama",
    lastSeenAt: "2026-05-26T12:00:00.000Z",
    isFavorite: false,
    ...overrides
  };
}

function episode(overrides: Partial<Episode> = {}): Episode {
  return {
    type: "episode",
    id: "provider-1:episode:episode-1",
    providerId: "provider-1",
    seriesId: "provider-1:series:series-1",
    seasonNumber: 1,
    episodeNumber: 1,
    title: "Pilot",
    durationSeconds: 1800,
    progressSeconds: 0,
    stream: {
      providerType: "xtream",
      url: "https://stream.test/episode.mp4",
      streamId: "episode-1",
      containerExtension: "mp4"
    },
    ...overrides
  };
}

function liveProgram(overrides: Partial<LiveProgram> = {}): LiveProgram {
  return {
    id: "provider-1:live:bbc-one:2026-05-26T12:00:00.000Z",
    providerId: "provider-1",
    channelId: "provider-1:live:bbc-one",
    title: "Midday News",
    description: "Headlines and weather.",
    startAt: "2026-05-26T12:00:00.000Z",
    endAt: "2026-05-26T12:30:00.000Z",
    ...overrides
  };
}

describe("catalogRepository", () => {
  it("upserts and searches live channels", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);

    expect(repo.listLiveChannels("", null)).toHaveLength(1);
    expect(repo.listLiveChannels("bbc", null)[0].name).toBe("BBC One");
    expect(repo.listLiveChannels("news", null)[0].name).toBe("BBC One");
    expect(repo.listLiveChannels("", "News")).toHaveLength(1);
    expect(repo.listLiveChannels("", "Sports")).toHaveLength(0);
  });

  it("lists live categories independently from current channel filters", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([
      channel({ id: "provider-1:live:bbc-one", name: "BBC One", category: "News" }),
      channel({ id: "provider-1:live:espn", name: "ESPN", category: "Sports" }),
      channel({ id: "provider-1:live:movies", name: "Movies Live", category: "Entertainment" })
    ]);

    expect(repo.listLiveCategories()).toEqual(["Entertainment", "News", "Sports"]);
  });

  it("lists category views with item counts, pinned categories first, and manual pinned order", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([
      channel({ id: "provider-1:live:bbc-one", name: "BBC One", category: "News" }),
      channel({ id: "provider-1:live:sky-news", name: "Sky News", category: "News" }),
      channel({ id: "provider-1:live:espn", name: "ESPN", category: "Sports" }),
      channel({ id: "provider-1:live:movies", name: "Movies Live", category: "Entertainment" })
    ]);

    expect(repo.listCategoryViews("live")).toEqual([
      { contentType: "live", name: "Entertainment", itemCount: 1, isPinned: false, sortOrder: null },
      { contentType: "live", name: "News", itemCount: 2, isPinned: false, sortOrder: null },
      { contentType: "live", name: "Sports", itemCount: 1, isPinned: false, sortOrder: null }
    ]);

    repo.toggleCategoryPin("live", "Sports");
    repo.toggleCategoryPin("live", "News");
    repo.reorderPinnedCategories("live", ["News", "Sports"]);

    expect(repo.listCategoryViews("live")).toEqual([
      { contentType: "live", name: "News", itemCount: 2, isPinned: true, sortOrder: 0 },
      { contentType: "live", name: "Sports", itemCount: 1, isPinned: true, sortOrder: 1 },
      { contentType: "live", name: "Entertainment", itemCount: 1, isPinned: false, sortOrder: null }
    ]);
  });

  it("replaces, searches, and favorites movies", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.replaceMoviesForProvider("provider-1", [
      movie(),
      movie({ id: "provider-1:movie:movie-2", title: "Quiet Drama", category: "Drama" })
    ]);
    repo.toggleFavorite("provider-1:movie:movie-2", "movie");

    expect(repo.listMovies("drama", null).map((item) => item.title)).toEqual(["Quiet Drama"]);
    expect(repo.listMovieCategories()).toEqual(["Action", "Drama"]);
    expect(repo.getMovie("provider-1:movie:movie-2")?.isFavorite).toBe(true);
  });

  it("replaces, searches, and favorites series", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.replaceSeriesForProvider("provider-1", [
      series(),
      series({ id: "provider-1:series:series-2", title: "Sports Stories", category: "Documentary" })
    ]);
    repo.toggleFavorite("provider-1:series:series-2", "series");

    expect(repo.listSeries("documentary", null).map((item) => item.title)).toEqual(["Sports Stories"]);
    expect(repo.listSeriesCategories()).toEqual(["Documentary", "Drama"]);
    expect(repo.getSeries("provider-1:series:series-2")?.isFavorite).toBe(true);
  });

  it("replaces and lists episodes for a series", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.replaceEpisodesForSeries("provider-1", "provider-1:series:series-1", [
      episode({ id: "provider-1:episode:episode-2", episodeNumber: 2, title: "Second" }),
      episode()
    ]);

    expect(repo.listEpisodesForSeries("provider-1:series:series-1").map((item) => item.title)).toEqual([
      "Pilot",
      "Second"
    ]);
    expect(repo.getEpisode("provider-1:episode:episode-2")?.stream.url).toBe("https://stream.test/episode.mp4");
  });

  it("stores and lists live programs with current/next schedule state", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);
    repo.replaceLiveProgramsForChannel("provider-1", "provider-1:live:bbc-one", [
      liveProgram({
        id: "provider-1:live:bbc-one:2026-05-26T11:30:00.000Z",
        title: "Morning Review",
        startAt: "2026-05-26T11:30:00.000Z",
        endAt: "2026-05-26T12:00:00.000Z"
      }),
      liveProgram(),
      liveProgram({
        id: "provider-1:live:bbc-one:2026-05-26T12:30:00.000Z",
        title: "World Report",
        description: null,
        startAt: "2026-05-26T12:30:00.000Z",
        endAt: "2026-05-26T13:00:00.000Z"
      })
    ]);

    expect(repo.listLiveProgramsForChannel("provider-1:live:bbc-one", "2026-05-26T12:10:00.000Z")).toEqual([
      {
        id: "provider-1:live:bbc-one:2026-05-26T12:00:00.000Z",
        channelId: "provider-1:live:bbc-one",
        title: "Midday News",
        description: "Headlines and weather.",
        startAt: "2026-05-26T12:00:00.000Z",
        endAt: "2026-05-26T12:30:00.000Z",
        isCurrent: true
      },
      {
        id: "provider-1:live:bbc-one:2026-05-26T12:30:00.000Z",
        channelId: "provider-1:live:bbc-one",
        title: "World Report",
        description: null,
        startAt: "2026-05-26T12:30:00.000Z",
        endAt: "2026-05-26T13:00:00.000Z",
        isCurrent: false
      }
    ]);
  });

  it("lists recently watched live, movie, and episode items without stream data", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);
    repo.replaceMoviesForProvider("provider-1", [movie()]);
    repo.replaceSeriesForProvider("provider-1", [series()]);
    repo.replaceEpisodesForSeries("provider-1", "provider-1:series:series-1", [episode()]);
    repo.markRecentlyWatched("provider-1:live:bbc-one", "live");
    repo.markRecentlyWatched("provider-1:movie:movie-1", "movie");
    repo.markRecentlyWatched("provider-1:episode:episode-1", "episode");
    db.prepare("UPDATE recently_watched SET last_watched_at = ? WHERE item_id = ?").run(
      "2026-05-26T12:00:00.000Z",
      "provider-1:live:bbc-one"
    );
    db.prepare("UPDATE recently_watched SET last_watched_at = ? WHERE item_id = ?").run(
      "2026-05-26T12:01:00.000Z",
      "provider-1:movie:movie-1"
    );
    db.prepare("UPDATE recently_watched SET last_watched_at = ? WHERE item_id = ?").run(
      "2026-05-26T12:02:00.000Z",
      "provider-1:episode:episode-1"
    );

    expect(repo.listRecentlyWatched()).toEqual([
      {
        id: "provider-1:episode:episode-1",
        itemType: "episode",
        providerId: "provider-1",
        title: "Pilot",
        subtitle: "S1 E1 | City Series",
        artworkUrl: null,
        lastWatchedAt: "2026-05-26T12:02:00.000Z"
      },
      {
        id: "provider-1:movie:movie-1",
        itemType: "movie",
        providerId: "provider-1",
        title: "City Movie",
        subtitle: "Action | 2025 | Rating 7.1",
        artworkUrl: null,
        lastWatchedAt: "2026-05-26T12:01:00.000Z"
      },
      {
        id: "provider-1:live:bbc-one",
        itemType: "live",
        providerId: "provider-1",
        title: "BBC One",
        subtitle: "News",
        artworkUrl: null,
        lastWatchedAt: "2026-05-26T12:00:00.000Z"
      }
    ]);
  });

  it("preserves favorites when channels are refreshed", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);
    repo.toggleFavorite("provider-1:live:bbc-one", "live");
    repo.upsertLiveChannels([channel({ name: "BBC One HD" })]);

    expect(repo.listLiveChannels("bbc", null)[0]).toMatchObject({
      name: "BBC One HD",
      isFavorite: true
    });
  });

  it("does not return stale live channels by id or list", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);
    db.prepare("UPDATE live_channels SET stale = 1 WHERE id = ?").run("provider-1:live:bbc-one");

    expect(repo.getLiveChannel("provider-1:live:bbc-one")).toBeNull();
    expect(repo.listLiveChannels("", null)).toHaveLength(0);
  });

  it("stales missing provider channels when replacing a refreshed playlist", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([
      channel(),
      channel({
        id: "provider-1:live:bbc-two",
        name: "BBC Two",
        stream: {
          providerType: "m3u",
          url: "https://stream.test/bbc-two.m3u8"
        }
      }),
      channel({
        id: "provider-2:live:world-news",
        providerId: "provider-2",
        name: "World News",
        stream: {
          providerType: "m3u",
          url: "https://stream.test/world-news.m3u8"
        }
      })
    ]);

    repo.replaceLiveChannelsForProvider("provider-1", [channel({ name: "BBC One HD" })]);

    expect(repo.getLiveChannel("provider-1:live:bbc-one")?.name).toBe("BBC One HD");
    expect(repo.getLiveChannel("provider-1:live:bbc-two")).toBeNull();
    expect(repo.getLiveChannel("provider-2:live:world-news")?.name).toBe("World News");
  });
});
