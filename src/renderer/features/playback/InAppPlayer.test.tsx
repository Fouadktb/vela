import "@testing-library/jest-dom/vitest";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { PlaybackState, PlayRequest, ResolvedPlaybackSource } from "../../../shared/playback/types";
import { InAppPlayer } from "./InAppPlayer";

const mockApi = vi.hoisted(() => ({
  playback: {
    play: vi.fn(),
    resolve: vi.fn(),
    pause: vi.fn(),
    stop: vi.fn(),
    seek: vi.fn(),
    selectAudioTrack: vi.fn(),
    selectSubtitleTrack: vi.fn(),
    openExternal: vi.fn(),
    getState: vi.fn(),
    onState: vi.fn()
  }
}));

vi.mock("../../app/api", () => ({
  iptvApi: mockApi
}));

const movieRequest: PlayRequest = {
  itemId: "movie-1",
  itemType: "movie"
};

const movieFallbackSource: ResolvedPlaybackSource = {
  itemId: movieRequest.itemId,
  itemType: movieRequest.itemType,
  title: "Codec Heavy Movie",
  url: "http://example.test/movie.mkv",
  isLive: false,
  preferredEngine: "fallback"
};

const movieNativeSource: ResolvedPlaybackSource = {
  itemId: movieRequest.itemId,
  itemType: movieRequest.itemType,
  title: "Browser Movie",
  url: "http://example.test/movie.mp4",
  isLive: false,
  preferredEngine: "native"
};

const playingState: PlaybackState = {
  status: "playing",
  itemId: movieRequest.itemId,
  itemType: movieRequest.itemType,
  title: movieFallbackSource.title,
  positionSeconds: 0,
  durationSeconds: 600,
  isSeekable: true,
  audioTracks: [],
  subtitleTracks: [],
  selectedAudioTrackId: null,
  selectedSubtitleTrackId: null,
  errorMessage: null
};

describe("InAppPlayer", () => {
  beforeEach(() => {
    vi.spyOn(HTMLMediaElement.prototype, "load").mockImplementation(() => undefined);
    vi.spyOn(HTMLMediaElement.prototype, "pause").mockImplementation(() => undefined);
    vi.spyOn(HTMLMediaElement.prototype, "play").mockResolvedValue(undefined);
    mockApi.playback.play.mockResolvedValue(undefined);
    mockApi.playback.pause.mockResolvedValue(undefined);
    mockApi.playback.stop.mockResolvedValue(undefined);
    mockApi.playback.seek.mockResolvedValue(undefined);
    mockApi.playback.getState.mockResolvedValue(playingState);
    mockApi.playback.onState.mockReturnValue(vi.fn());
  });

  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
    vi.clearAllMocks();
  });

  it("starts fallback playback for unsupported containers behind the same control surface", async () => {
    mockApi.playback.resolve.mockResolvedValue(movieFallbackSource);
    const onClose = vi.fn();

    render(<InAppPlayer request={movieRequest} onClose={onClose} />);

    await waitFor(() => expect(mockApi.playback.play).toHaveBeenCalledWith(movieRequest));
    expect(await screen.findByLabelText("Video player")).toBeInTheDocument();
    expect(await screen.findByRole("toolbar", { name: "Playback controls" })).toBeInTheDocument();
    expect(screen.getAllByText("Codec Heavy Movie")).toHaveLength(2);

    fireEvent.click(await screen.findByRole("button", { name: "Stop playback" }));

    await waitFor(() => expect(mockApi.playback.stop).toHaveBeenCalled());
    expect(onClose).toHaveBeenCalled();
  });

  it("keeps browser-safe sources in app and stops any previous fallback playback", async () => {
    mockApi.playback.resolve.mockResolvedValue(movieNativeSource);

    render(<InAppPlayer request={movieRequest} onClose={vi.fn()} />);

    expect(await screen.findByLabelText("Video player")).toBeInTheDocument();
    await waitFor(() => expect(mockApi.playback.stop).toHaveBeenCalled());
    expect(mockApi.playback.play).not.toHaveBeenCalled();
  });

  it("falls back through the same control surface when native play throws", async () => {
    mockApi.playback.resolve.mockResolvedValue(movieNativeSource);
    vi.spyOn(HTMLMediaElement.prototype, "play").mockImplementation(() => {
      throw new Error("Playback blocked");
    });

    render(<InAppPlayer request={movieRequest} onClose={vi.fn()} />);

    await waitFor(() => expect(mockApi.playback.play).toHaveBeenCalledWith(movieRequest));
    expect(await screen.findByRole("toolbar", { name: "Playback controls" })).toBeInTheDocument();
  });
});
