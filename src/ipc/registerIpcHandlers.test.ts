import { beforeEach, describe, expect, it, vi } from "vitest";
import { ipcChannels } from "../shared/ipc/types.js";
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
});
