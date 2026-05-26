import { act, renderHook, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { LiveChannelView } from "../../shared/catalog/types";
import type { ImportProgress, ProviderSummary } from "../../shared/providers/types";
import { useAppData } from "./useAppData";

const mockApi = vi.hoisted(() => ({
  providers: {
    list: vi.fn<() => Promise<ProviderSummary[]>>(),
    createM3u: vi.fn(),
    refresh: vi.fn(),
    onImportProgress: vi.fn()
  },
  catalog: {
    listLiveChannels: vi.fn<(query: string, category: string | null) => Promise<LiveChannelView[]>>(),
    toggleFavorite: vi.fn()
  },
  playback: {
    play: vi.fn(),
    pause: vi.fn(),
    stop: vi.fn(),
    seek: vi.fn(),
    openExternal: vi.fn(),
    getState: vi.fn(),
    onState: vi.fn()
  }
}));

vi.mock("./api", () => ({
  iptvApi: mockApi
}));

const provider: ProviderSummary = {
  id: "provider-1",
  type: "m3u",
  name: "Local M3U",
  createdAt: "2026-05-26T08:00:00.000Z",
  updatedAt: "2026-05-26T08:00:00.000Z",
  lastRefreshAt: null
};

const newsChannel: LiveChannelView = {
  type: "live",
  id: "live-news",
  providerId: provider.id,
  name: "City News",
  logoUrl: null,
  category: "News",
  epgChannelId: null,
  lastSeenAt: "2026-05-26T08:00:00.000Z",
  isFavorite: false
};

const sportChannel: LiveChannelView = {
  type: "live",
  id: "live-sport",
  providerId: provider.id,
  name: "Match Live",
  logoUrl: null,
  category: "Sports",
  epgChannelId: null,
  lastSeenAt: "2026-05-26T08:00:00.000Z",
  isFavorite: true
};

describe("useAppData", () => {
  let importProgressCallback: ((progress: ImportProgress) => void) | null;

  beforeEach(() => {
    importProgressCallback = null;
    mockApi.providers.list.mockResolvedValue([provider]);
    mockApi.providers.onImportProgress.mockImplementation((callback) => {
      importProgressCallback = callback;
      return vi.fn();
    });
    mockApi.catalog.listLiveChannels.mockImplementation(async (query) =>
      query ? [sportChannel] : [newsChannel, sportChannel]
    );
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("keeps the selected channel coherent when a filter removes the current selection", async () => {
    const { result } = renderHook(() => useAppData());

    await waitFor(() => expect(result.current.selectedChannel?.id).toBe(newsChannel.id));

    act(() => {
      result.current.setSelectedChannelId(newsChannel.id);
      result.current.setQuery("match");
    });

    await waitFor(() => expect(result.current.selectedChannel?.id).toBe(sportChannel.id));
    expect(result.current.categories).toEqual(["Sports"]);
  });

  it("reloads providers and channels when an import completes", async () => {
    const { result } = renderHook(() => useAppData());

    await waitFor(() => expect(result.current.providers).toEqual([provider]));

    await act(async () => {
      importProgressCallback?.({
        providerId: provider.id,
        phase: "complete",
        message: "Import complete",
        current: 1,
        total: 1
      });
    });

    await waitFor(() => expect(mockApi.providers.list).toHaveBeenCalledTimes(2));
    expect(mockApi.catalog.listLiveChannels).toHaveBeenCalledTimes(2);
    expect(result.current.statusMessage).toBe("Import complete");
  });
});
