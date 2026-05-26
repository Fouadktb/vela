import { beforeEach, describe, expect, it, vi } from "vitest";
import { ipcChannels } from "../shared/ipc/types.js";
import type { LiveChannel, LiveProgramView } from "../shared/catalog/types.js";
import type { Provider } from "../shared/providers/types.js";

const ipcHandlers = new Map<string, (...args: unknown[]) => unknown>();

vi.mock("electron", () => ({
  ipcMain: {
    handle: vi.fn((channel: string, handler: (...args: unknown[]) => unknown) => {
      ipcHandlers.set(channel, handler);
    })
  }
}));

const { registerIpcHandlers } = await import("../../electron/main/ipc/registerIpcHandlers.js");

describe("registerIpcHandlers", () => {
  beforeEach(() => {
    ipcHandlers.clear();
  });

  it("returns the refreshed provider summary after creating and importing an M3U provider", async () => {
    const createdProvider: Provider = {
      id: "provider-1",
      type: "m3u",
      name: "Playlist",
      source: "https://example.test/private.m3u",
      username: "hidden-user",
      password: "hidden-password",
      createdAt: "2026-05-26T08:00:00.000Z",
      updatedAt: "2026-05-26T08:00:00.000Z",
      lastRefreshAt: null
    };
    const refreshedProvider: Provider = {
      ...createdProvider,
      updatedAt: "2026-05-26T08:01:00.000Z",
      lastRefreshAt: "2026-05-26T08:01:00.000Z"
    };

    registerIpcHandlers({
      emitToRenderer: vi.fn(),
      providerRepository: {
        list: vi.fn(),
        createM3u: vi.fn(() => createdProvider),
        get: vi.fn(() => refreshedProvider),
        markRefreshed: vi.fn(),
        delete: vi.fn()
      } as never,
      catalogRepository: {} as never,
      importM3uProvider: vi.fn(async () => undefined) as never,
      importXtreamProvider: vi.fn(async () => undefined) as never,
      importXtreamSeriesEpisodes: vi.fn(async () => []) as never,
      mpvController: {} as never,
      openInExternalPlayer: vi.fn() as never
    });

    const handler = ipcHandlers.get(ipcChannels.providersCreateM3u);
    expect(handler).toBeDefined();

    const result = await handler?.(null, {
      name: "Playlist",
      source: "https://example.test/private.m3u",
      sourceKind: "url"
    });

    expect(result).toEqual({
      id: "provider-1",
      type: "m3u",
      name: "Playlist",
      createdAt: "2026-05-26T08:00:00.000Z",
      updatedAt: "2026-05-26T08:01:00.000Z",
      lastRefreshAt: "2026-05-26T08:01:00.000Z"
    });
    expect(result).not.toHaveProperty("source");
    expect(result).not.toHaveProperty("username");
    expect(result).not.toHaveProperty("password");
  });

  it("deletes a newly-created provider when its initial import fails", async () => {
    const createdProvider: Provider = {
      id: "provider-1",
      type: "m3u",
      name: "Broken playlist",
      source: "https://example.test/broken.m3u",
      username: null,
      password: null,
      createdAt: "2026-05-26T08:00:00.000Z",
      updatedAt: "2026-05-26T08:00:00.000Z",
      lastRefreshAt: null
    };
    const deleteProvider = vi.fn();

    registerIpcHandlers({
      emitToRenderer: vi.fn(),
      providerRepository: {
        list: vi.fn(),
        createM3u: vi.fn(() => createdProvider),
        get: vi.fn(),
        markRefreshed: vi.fn(),
        delete: deleteProvider
      } as never,
      catalogRepository: {} as never,
      importM3uProvider: vi.fn(async () => {
        throw new Error("Playlist could not be loaded");
      }) as never,
      importXtreamProvider: vi.fn(async () => undefined) as never,
      importXtreamSeriesEpisodes: vi.fn(async () => []) as never,
      mpvController: {} as never,
      openInExternalPlayer: vi.fn() as never
    });

    const handler = ipcHandlers.get(ipcChannels.providersCreateM3u);
    await expect(
      handler?.(null, {
        name: "Broken playlist",
        source: "https://example.test/broken.m3u",
        sourceKind: "url"
      })
    ).rejects.toThrow("Playlist could not be loaded");

    expect(deleteProvider).toHaveBeenCalledWith("provider-1");
  });

  it("rejects invalid M3U provider input before privileged import work starts", async () => {
    const createM3u = vi.fn();
    const importM3uProvider = vi.fn();

    registerIpcHandlers({
      emitToRenderer: vi.fn(),
      providerRepository: {
        list: vi.fn(),
        createM3u,
        get: vi.fn(),
        markRefreshed: vi.fn(),
        delete: vi.fn()
      } as never,
      catalogRepository: {} as never,
      importM3uProvider: importM3uProvider as never,
      importXtreamProvider: vi.fn(async () => undefined) as never,
      importXtreamSeriesEpisodes: vi.fn(async () => []) as never,
      mpvController: {} as never,
      openInExternalPlayer: vi.fn() as never
    });

    const handler = ipcHandlers.get(ipcChannels.providersCreateM3u);
    await expect(
      handler?.(null, {
        name: "Bad playlist",
        source: "/tmp/playlist.m3u",
        sourceKind: "url"
      })
    ).rejects.toThrow("Invalid M3U provider input");

    expect(createM3u).not.toHaveBeenCalled();
    expect(importM3uProvider).not.toHaveBeenCalled();
  });

  it("creates an Xtream provider and returns a summary without credentials", async () => {
    const createdProvider: Provider = {
      id: "provider-xtream",
      type: "xtream",
      name: "Xtream Account",
      source: "https://panel.example.test",
      username: "secret-user",
      password: "secret-password",
      createdAt: "2026-05-26T08:00:00.000Z",
      updatedAt: "2026-05-26T08:00:00.000Z",
      lastRefreshAt: null
    };
    const refreshedProvider: Provider = {
      ...createdProvider,
      updatedAt: "2026-05-26T08:01:00.000Z",
      lastRefreshAt: "2026-05-26T08:01:00.000Z"
    };
    const createXtream = vi.fn(() => createdProvider);
    const importXtreamProvider = vi.fn(async () => undefined);

    registerIpcHandlers({
      emitToRenderer: vi.fn(),
      providerRepository: {
        list: vi.fn(),
        createM3u: vi.fn(),
        createXtream,
        get: vi.fn(() => refreshedProvider),
        markRefreshed: vi.fn(),
        delete: vi.fn()
      } as never,
      catalogRepository: {} as never,
      importM3uProvider: vi.fn(async () => undefined) as never,
      importXtreamProvider: importXtreamProvider as never,
      importXtreamSeriesEpisodes: vi.fn(async () => []) as never,
      mpvController: {} as never,
      openInExternalPlayer: vi.fn() as never
    });

    const handler = ipcHandlers.get(ipcChannels.providersCreateXtream);
    expect(handler).toBeDefined();

    const result = await handler?.(null, {
      name: " Xtream Account ",
      serverUrl: "https://panel.example.test/",
      username: " secret-user ",
      password: " secret-password "
    });

    expect(createXtream).toHaveBeenCalledWith({
      name: "Xtream Account",
      serverUrl: "https://panel.example.test",
      username: "secret-user",
      password: "secret-password"
    });
    expect(importXtreamProvider).toHaveBeenCalledWith(
      createdProvider,
      expect.objectContaining({
        providerRepository: expect.any(Object),
        catalogRepository: expect.any(Object)
      })
    );
    expect(result).toEqual({
      id: "provider-xtream",
      type: "xtream",
      name: "Xtream Account",
      createdAt: "2026-05-26T08:00:00.000Z",
      updatedAt: "2026-05-26T08:01:00.000Z",
      lastRefreshAt: "2026-05-26T08:01:00.000Z"
    });
    expect(result).not.toHaveProperty("source");
    expect(result).not.toHaveProperty("username");
    expect(result).not.toHaveProperty("password");
  });

  it("deletes a provider through an explicit provider management IPC call", async () => {
    const deleteProvider = vi.fn();

    registerIpcHandlers({
      emitToRenderer: vi.fn(),
      providerRepository: {
        list: vi.fn(),
        createM3u: vi.fn(),
        createXtream: vi.fn(),
        get: vi.fn(),
        markRefreshed: vi.fn(),
        delete: deleteProvider
      } as never,
      catalogRepository: {
        listRecentlyWatched: vi.fn(() => [])
      } as never,
      importM3uProvider: vi.fn(async () => undefined) as never,
      importXtreamProvider: vi.fn(async () => undefined) as never,
      importXtreamSeriesEpisodes: vi.fn(async () => []) as never,
      mpvController: {} as never,
      openInExternalPlayer: vi.fn() as never
    });

    const handler = ipcHandlers.get(ipcChannels.providersDelete);
    await handler?.(null, "provider-1");

    expect(deleteProvider).toHaveBeenCalledWith("provider-1");
  });

  it("returns recently watched catalog items", () => {
    const listRecentlyWatched = vi.fn(() => [
      {
        id: "provider-1:movie:201",
        itemType: "movie",
        providerId: "provider-1",
        title: "City Movie",
        subtitle: "Action | 2025",
        artworkUrl: null,
        lastWatchedAt: "2026-05-26T08:30:00.000Z"
      }
    ]);

    registerIpcHandlers({
      emitToRenderer: vi.fn(),
      providerRepository: {
        list: vi.fn(),
        createM3u: vi.fn(),
        createXtream: vi.fn(),
        get: vi.fn(),
        markRefreshed: vi.fn(),
        delete: vi.fn()
      } as never,
      catalogRepository: {
        listRecentlyWatched
      } as never,
      importM3uProvider: vi.fn(async () => undefined) as never,
      importXtreamProvider: vi.fn(async () => undefined) as never,
      importXtreamSeriesEpisodes: vi.fn(async () => []) as never,
      mpvController: {} as never,
      openInExternalPlayer: vi.fn() as never
    });

    const handler = ipcHandlers.get(ipcChannels.catalogListRecentlyWatched);
    expect(handler?.()).toEqual([
      {
        id: "provider-1:movie:201",
        itemType: "movie",
        providerId: "provider-1",
        title: "City Movie",
        subtitle: "Action | 2025",
        artworkUrl: null,
        lastWatchedAt: "2026-05-26T08:30:00.000Z"
      }
    ]);
    expect(listRecentlyWatched).toHaveBeenCalled();
  });

  it("manages category pinning and ordering through catalog IPC calls", async () => {
    const listCategoryViews = vi.fn(() => [
      { contentType: "live", name: "News", itemCount: 2, isPinned: true, sortOrder: 0 }
    ]);
    const toggleCategoryPin = vi.fn();
    const reorderPinnedCategories = vi.fn();

    registerIpcHandlers({
      emitToRenderer: vi.fn(),
      providerRepository: {
        list: vi.fn(),
        createM3u: vi.fn(),
        createXtream: vi.fn(),
        get: vi.fn(),
        markRefreshed: vi.fn(),
        delete: vi.fn()
      } as never,
      catalogRepository: {
        listCategoryViews,
        toggleCategoryPin,
        reorderPinnedCategories
      } as never,
      importM3uProvider: vi.fn(async () => undefined) as never,
      importXtreamProvider: vi.fn(async () => undefined) as never,
      importXtreamSeriesEpisodes: vi.fn(async () => []) as never,
      mpvController: {} as never,
      openInExternalPlayer: vi.fn() as never
    });

    expect(await ipcHandlers.get(ipcChannels.catalogListCategoryViews)?.(null, "live")).toEqual([
      { contentType: "live", name: "News", itemCount: 2, isPinned: true, sortOrder: 0 }
    ]);
    await ipcHandlers.get(ipcChannels.catalogToggleCategoryPin)?.(null, {
      contentType: "live",
      category: " News "
    });
    await ipcHandlers.get(ipcChannels.catalogReorderPinnedCategories)?.(null, {
      contentType: "live",
      categories: ["News", "Sports"]
    });

    expect(toggleCategoryPin).toHaveBeenCalledWith("live", "News");
    expect(reorderPinnedCategories).toHaveBeenCalledWith("live", ["News", "Sports"]);
  });

  it("lazy imports Xtream live programs when the local schedule is empty", async () => {
    const channel = liveChannel();
    const provider = xtreamProvider();
    const programs: LiveProgramView[] = [
      {
        id: "provider-xtream:live:123:1779796800",
        channelId: channel.id,
        title: "Midday News",
        description: "Headlines and weather.",
        startAt: "2026-05-26T12:00:00.000Z",
        endAt: "2026-05-26T12:30:00.000Z",
        isCurrent: true
      }
    ];
    const importXtreamLivePrograms = vi.fn(async () => []);
    const listLiveProgramsForChannel = vi.fn().mockReturnValueOnce([]).mockReturnValueOnce(programs);

    registerIpcHandlers({
      emitToRenderer: vi.fn(),
      providerRepository: {
        list: vi.fn(),
        createM3u: vi.fn(),
        createXtream: vi.fn(),
        get: vi.fn(() => provider),
        markRefreshed: vi.fn(),
        delete: vi.fn()
      } as never,
      catalogRepository: {
        getLiveChannel: vi.fn(() => channel),
        listLiveProgramsForChannel
      } as never,
      importM3uProvider: vi.fn(async () => undefined) as never,
      importXtreamProvider: vi.fn(async () => undefined) as never,
      importXtreamSeriesEpisodes: vi.fn(async () => []) as never,
      importXtreamLivePrograms: importXtreamLivePrograms as never,
      mpvController: {} as never,
      openInExternalPlayer: vi.fn() as never
    });

    const result = await ipcHandlers.get(ipcChannels.catalogListLivePrograms)?.(null, channel.id);

    expect(importXtreamLivePrograms).toHaveBeenCalledWith(
      provider,
      channel,
      expect.objectContaining({ catalogRepository: expect.any(Object) })
    );
    expect(result).toEqual(programs);
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
