import "@testing-library/jest-dom/vitest";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { PlaybackState } from "../../../shared/playback/types";
import { PlayerOverlayApp } from "./PlayerOverlayApp";

const mockApi = vi.hoisted(() => ({
  playback: {
    play: vi.fn(),
    pause: vi.fn(),
    stop: vi.fn(),
    seek: vi.fn(),
    selectVideoTrack: vi.fn(),
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

const playingState: PlaybackState = {
  status: "playing",
  itemId: "movie-1",
  itemType: "movie",
  title: "Theater Movie",
  positionSeconds: 12,
  durationSeconds: 600,
  isSeekable: true,
  videoTracks: [],
  audioTracks: [],
  subtitleTracks: [],
  selectedVideoTrackId: null,
  selectedAudioTrackId: null,
  selectedSubtitleTrackId: null,
  errorMessage: null
};

describe("PlayerOverlayApp", () => {
  beforeEach(() => {
    mockApi.playback.getState.mockResolvedValue(playingState);
    mockApi.playback.onState.mockReturnValue(vi.fn());
    mockApi.playback.stop.mockResolvedValue(undefined);
    mockApi.playback.seek.mockResolvedValue(undefined);
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("renders Vela theater controls from mpv playback state", async () => {
    render(<PlayerOverlayApp />);

    expect(await screen.findByRole("toolbar", { name: "Playback controls" })).toBeInTheDocument();
    expect(screen.getByText("Theater Movie")).toBeInTheDocument();
  });

  it("seeks from the full theater surface and stops on Escape", async () => {
    render(<PlayerOverlayApp />);

    const shell = await screen.findByLabelText("Vela theater player");
    vi.spyOn(window, "innerWidth", "get").mockReturnValue(200);

    fireEvent.doubleClick(shell, { clientX: 150 });
    fireEvent.keyDown(window, { key: "Escape" });

    await waitFor(() => expect(mockApi.playback.seek).toHaveBeenCalledWith({ offsetSeconds: 10 }));
    expect(mockApi.playback.stop).toHaveBeenCalled();
  });
});
