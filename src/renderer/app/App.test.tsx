import "@testing-library/jest-dom/vitest";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type {
  CategoryView,
  EpisodeView,
  LiveChannelView,
  LiveProgramView,
  MovieView,
  RecentlyWatchedItemView,
  SeriesView
} from "../../shared/catalog/types";
import type { PlaybackState } from "../../shared/playback/types";
import type { ImportProgress, ProviderSummary } from "../../shared/providers/types";
import { App } from "./App";

const mockApi = vi.hoisted(() => ({
  providers: {
    list: vi.fn<() => Promise<ProviderSummary[]>>(),
    createM3u: vi.fn(),
    createXtream: vi.fn(),
    refresh: vi.fn(),
    updateAutoRefresh: vi.fn(),
    delete: vi.fn(),
    onImportProgress: vi.fn()
  },
  catalog: {
    listLiveChannels: vi.fn<(query: string, category: string | null) => Promise<LiveChannelView[]>>(),
    listLiveCategories: vi.fn<() => Promise<string[]>>(),
    listCategoryViews: vi.fn<(contentType: "live" | "movie" | "series") => Promise<CategoryView[]>>(),
    toggleCategoryPin: vi.fn<(contentType: "live" | "movie" | "series", category: string) => Promise<void>>(),
    reorderPinnedCategories: vi.fn<(contentType: "live" | "movie" | "series", categories: string[]) => Promise<void>>(),
    listLivePrograms: vi.fn<(channelId: string) => Promise<LiveProgramView[]>>(),
    listMovies: vi.fn<(query: string, category: string | null) => Promise<MovieView[]>>(),
    listMovieCategories: vi.fn<() => Promise<string[]>>(),
    listSeries: vi.fn<(query: string, category: string | null) => Promise<SeriesView[]>>(),
    listSeriesCategories: vi.fn<() => Promise<string[]>>(),
    listEpisodesForSeries: vi.fn<(seriesId: string) => Promise<EpisodeView[]>>(),
    listRecentlyWatched: vi.fn<() => Promise<RecentlyWatchedItemView[]>>(),
    toggleFavorite: vi.fn()
  },
  playback: {
    play: vi.fn(),
    resolve: vi.fn(),
    pause: vi.fn(),
    stop: vi.fn(),
    seek: vi.fn(),
    selectAudioTrack: vi.fn(),
    selectSubtitleTrack: vi.fn(),
    openExternal: vi.fn(),
    getState: vi.fn<() => Promise<PlaybackState>>(),
    onState: vi.fn()
  }
}));

vi.mock("./api", () => ({
  iptvApi: mockApi
}));

const provider: ProviderSummary = {
  id: "provider-1",
  type: "xtream",
  name: "Xtream Account",
  createdAt: "2026-05-26T08:00:00.000Z",
  updatedAt: "2026-05-26T08:00:00.000Z",
  lastRefreshAt: "2026-05-26T08:10:00.000Z",
    autoRefreshEnabled: true,
    autoRefreshIntervalHours: 24
};

const liveChannel: LiveChannelView = {
  type: "live",
  id: "provider-1:live:101",
  providerId: provider.id,
  name: "City News",
  logoUrl: null,
  category: "News",
  epgChannelId: null,
  lastSeenAt: "2026-05-26T08:00:00.000Z",
  isFavorite: false
};

const movie: MovieView = {
  type: "movie",
  id: "provider-1:movie:201",
  providerId: provider.id,
  title: "The City Movie",
  posterUrl: null,
  category: "Action",
  year: 2025,
  rating: "7.2",
  lastSeenAt: "2026-05-26T08:00:00.000Z",
  isFavorite: true
};

const series: SeriesView = {
  type: "series",
  id: "provider-1:series:301",
  providerId: provider.id,
  title: "The City Series",
  posterUrl: null,
  category: "Drama",
  lastSeenAt: "2026-05-26T08:00:00.000Z",
  isFavorite: false
};

const episode: EpisodeView = {
  type: "episode",
  id: "provider-1:episode:401",
  providerId: provider.id,
  seriesId: series.id,
  seasonNumber: 1,
  episodeNumber: 1,
  title: "Pilot",
  durationSeconds: 1800,
  progressSeconds: 0
};

const recentEpisode: RecentlyWatchedItemView = {
  id: episode.id,
  itemType: "episode",
  providerId: provider.id,
  title: "Pilot",
  subtitle: "S1 E1 | The City Series",
  artworkUrl: null,
  lastWatchedAt: "2026-05-26T08:30:00.000Z"
};

const idlePlaybackState: PlaybackState = {
  status: "idle",
  itemId: null,
  itemType: null,
  title: null,
  positionSeconds: 0,
  durationSeconds: null,
  isSeekable: false,
  audioTracks: [],
  subtitleTracks: [],
  selectedAudioTrackId: null,
  selectedSubtitleTrackId: null,
  errorMessage: null
};

const liveCategoryViews: CategoryView[] = [
  { contentType: "live", name: "News", itemCount: 1, isPinned: false, sortOrder: null },
  { contentType: "live", name: "Sports", itemCount: 12, isPinned: false, sortOrder: null }
];

const movieCategoryViews: CategoryView[] = [
  { contentType: "movie", name: "Action", itemCount: 1, isPinned: false, sortOrder: null }
];

const seriesCategoryViews: CategoryView[] = [
  { contentType: "series", name: "Drama", itemCount: 1, isPinned: false, sortOrder: null }
];

const livePrograms: LiveProgramView[] = [
  {
    id: "provider-1:live:101:2026-05-26T08:00:00.000Z",
    channelId: liveChannel.id,
    title: "Morning News",
    description: "Local headlines.",
    startAt: "2026-05-26T08:00:00.000Z",
    endAt: "2026-05-26T08:30:00.000Z",
    isCurrent: true
  },
  {
    id: "provider-1:live:101:2026-05-26T08:30:00.000Z",
    channelId: liveChannel.id,
    title: "Market Watch",
    description: null,
    startAt: "2026-05-26T08:30:00.000Z",
    endAt: "2026-05-26T09:00:00.000Z",
    isCurrent: false
  }
];

describe("App catalog navigation", () => {
  beforeEach(() => {
    vi.spyOn(window, "confirm").mockReturnValue(true);
    mockApi.providers.list.mockResolvedValue([provider]);
    mockApi.providers.onImportProgress.mockImplementation((_callback: (progress: ImportProgress) => void) => vi.fn());
    mockApi.catalog.listLiveChannels.mockResolvedValue([liveChannel]);
    mockApi.catalog.listLiveCategories.mockResolvedValue(["News"]);
    mockApi.catalog.listCategoryViews.mockImplementation(async (contentType) => {
      if (contentType === "movie") {
        return movieCategoryViews;
      }
      if (contentType === "series") {
        return seriesCategoryViews;
      }
      return liveCategoryViews;
    });
    mockApi.catalog.toggleCategoryPin.mockResolvedValue(undefined);
    mockApi.catalog.reorderPinnedCategories.mockResolvedValue(undefined);
    mockApi.catalog.listLivePrograms.mockResolvedValue(livePrograms);
    mockApi.catalog.listMovies.mockResolvedValue([movie]);
    mockApi.catalog.listMovieCategories.mockResolvedValue(["Action"]);
    mockApi.catalog.listSeries.mockResolvedValue([series]);
    mockApi.catalog.listSeriesCategories.mockResolvedValue(["Drama"]);
    mockApi.catalog.listEpisodesForSeries.mockResolvedValue([episode]);
    mockApi.catalog.listRecentlyWatched.mockResolvedValue([recentEpisode]);
    mockApi.catalog.toggleFavorite.mockResolvedValue(undefined);
    mockApi.providers.delete.mockResolvedValue(undefined);
    mockApi.providers.refresh.mockResolvedValue(undefined);
    mockApi.providers.updateAutoRefresh.mockResolvedValue({
      ...provider,
      autoRefreshEnabled: false
    });
    mockApi.playback.play.mockResolvedValue(undefined);
    mockApi.playback.resolve.mockImplementation(async (request) => ({
      itemId: request.itemId,
      itemType: request.itemType,
      title: "Resolved playback",
      url: "http://example.test/video.mkv",
      isLive: request.itemType === "live",
      preferredEngine: "fallback"
    }));
    mockApi.playback.getState.mockResolvedValue(idlePlaybackState);
    mockApi.playback.onState.mockReturnValue(vi.fn());
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.clearAllMocks();
  });

  it("opens movies, series, and favorites as real catalog sections", async () => {
    render(<App />);

    await waitFor(() => expect(screen.getByRole("heading", { name: "Live TV" })).toBeInTheDocument());

    fireEvent.click(screen.getByRole("button", { name: "Movies" }));
    await waitFor(() => expect(screen.getByRole("heading", { name: "Movies" })).toBeInTheDocument());
    expect(screen.getByPlaceholderText("Search movies")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /The City Movie/ })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Series" }));
    await waitFor(() => expect(screen.getByRole("heading", { name: "Series" })).toBeInTheDocument());
    expect(screen.getByPlaceholderText("Search series")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /The City Series/ })).toBeInTheDocument();
    await waitFor(() => expect(screen.getByRole("button", { name: /S1 E1 Pilot/ })).toBeInTheDocument());

    fireEvent.click(screen.getByRole("button", { name: "Favorites" }));
    await waitFor(() => expect(screen.getByRole("heading", { name: "Favorites" })).toBeInTheDocument());
    expect(screen.getByPlaceholderText("Search favorites")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /The City Movie/ })).toBeInTheDocument();
  });

  it("uses category-first browsing with category pinning instead of a select", async () => {
    render(<App />);

    await waitFor(() => expect(screen.getByRole("heading", { name: "Live TV" })).toBeInTheDocument());

    expect(screen.queryByLabelText("Category")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "News category" })).toBeInTheDocument();

    fireEvent.change(screen.getByLabelText("Search categories"), { target: { value: "spo" } });
    expect(screen.queryByRole("button", { name: "News category" })).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Sports category" })).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("Search categories"), { target: { value: "" } });

    fireEvent.click(screen.getByRole("button", { name: "Pin News category" }));

    await waitFor(() => expect(mockApi.catalog.toggleCategoryPin).toHaveBeenCalledWith("live", "News"));
  });

  it("loads a live channel schedule into the detail pane", async () => {
    render(<App />);

    await waitFor(() => expect(screen.getByRole("heading", { name: "Live TV" })).toBeInTheDocument());

    expect(mockApi.catalog.listLivePrograms).toHaveBeenCalledWith(liveChannel.id);
    expect(await screen.findByText("Now on")).toBeInTheDocument();
    expect(screen.getByText("Morning News")).toBeInTheDocument();
    expect(screen.getByText("Market Watch")).toBeInTheDocument();
  });

  it("resets search and category filters when switching sections", async () => {
    render(<App />);

    await waitFor(() => expect(screen.getByRole("heading", { name: "Live TV" })).toBeInTheDocument());
    fireEvent.change(screen.getByPlaceholderText("Search live channels"), { target: { value: "city" } });
    fireEvent.click(screen.getByRole("button", { name: "News category" }));
    fireEvent.change(screen.getByLabelText("Search categories"), { target: { value: "spo" } });

    fireEvent.click(screen.getByRole("button", { name: "Movies" }));

    await waitFor(() => expect(screen.getByRole("heading", { name: "Movies" })).toBeInTheDocument());
    expect(screen.getByPlaceholderText<HTMLInputElement>("Search movies").value).toBe("");
    expect(screen.getByLabelText<HTMLInputElement>("Search categories").value).toBe("");
    await waitFor(() => expect(mockApi.catalog.listMovies).toHaveBeenLastCalledWith("", null));
  });

  it("starts movie playback from the selected movie detail pane", async () => {
    render(<App />);

    await waitFor(() => expect(screen.getByRole("heading", { name: "Live TV" })).toBeInTheDocument());
    fireEvent.click(screen.getByRole("button", { name: "Movies" }));
    await waitFor(() => expect(screen.getByRole("button", { name: /The City Movie/ })).toBeInTheDocument());

    fireEvent.click(screen.getByRole("button", { name: "Play" }));

    await waitFor(() => expect(mockApi.playback.play).toHaveBeenCalledWith({
      itemType: "movie",
      itemId: movie.id
    }));
  });

  it("starts episode playback from the selected series detail pane", async () => {
    render(<App />);

    await waitFor(() => expect(screen.getByRole("heading", { name: "Live TV" })).toBeInTheDocument());
    fireEvent.click(screen.getByRole("button", { name: "Series" }));
    await waitFor(() => expect(screen.getByRole("button", { name: /S1 E1 Pilot/ })).toBeInTheDocument());

    fireEvent.click(screen.getByRole("button", { name: /S1 E1 Pilot/ }));

    expect(mockApi.catalog.listEpisodesForSeries).toHaveBeenCalledWith(series.id);
    await waitFor(() => expect(mockApi.playback.play).toHaveBeenCalledWith({
      itemType: "episode",
      itemId: episode.id
    }));
  });

  it("shows recently watched items and plays the selected entry", async () => {
    render(<App />);

    await waitFor(() => expect(screen.getByRole("heading", { name: "Live TV" })).toBeInTheDocument());
    fireEvent.click(screen.getByRole("button", { name: "Recently Watched" }));

    await waitFor(() => expect(screen.getByRole("heading", { name: "Recently Watched" })).toBeInTheDocument());
    expect(screen.getByPlaceholderText("Search recently watched")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /Pilot/ })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Play" }));

    await waitFor(() => expect(mockApi.playback.play).toHaveBeenCalledWith({
      itemType: "episode",
      itemId: episode.id
    }));
  });

  it("manages multiple providers from settings", async () => {
    render(<App />);

    await waitFor(() => expect(screen.getByRole("heading", { name: "Live TV" })).toBeInTheDocument());
    fireEvent.click(screen.getByRole("button", { name: "Settings" }));

    await waitFor(() => expect(screen.getByRole("heading", { name: "Settings" })).toBeInTheDocument());
    expect(screen.getByRole("heading", { name: "1 configured" })).toBeInTheDocument();
    expect(screen.getByText("Xtream Account")).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Add an M3U provider" })).toBeInTheDocument();

    fireEvent.click(screen.getByLabelText("Auto-refresh"));
    await waitFor(() =>
      expect(mockApi.providers.updateAutoRefresh).toHaveBeenCalledWith({
        providerId: provider.id,
        enabled: false,
        intervalHours: 24
      })
    );

    fireEvent.click(screen.getByRole("button", { name: "Delete Xtream Account" }));

    await waitFor(() => expect(mockApi.providers.delete).toHaveBeenCalledWith(provider.id));
    expect(mockApi.providers.list).toHaveBeenCalled();
  });
});
