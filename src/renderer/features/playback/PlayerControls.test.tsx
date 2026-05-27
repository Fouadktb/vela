import { act, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { PlaybackState } from "../../../shared/playback/types";
import { PlayerControls } from "./PlayerControls";

const mockApi = vi.hoisted(() => ({
  playback: {
    play: vi.fn(),
    resolve: vi.fn(),
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
  itemId: "channel-1",
  itemType: "live",
  title: "City News",
  positionSeconds: 0,
  durationSeconds: null,
  isSeekable: true,
  videoTracks: [],
  audioTracks: [],
  subtitleTracks: [],
  selectedVideoTrackId: null,
  selectedAudioTrackId: null,
  selectedSubtitleTrackId: null,
  errorMessage: null
};

describe("PlayerControls", () => {
  let onStateCallback: ((state: PlaybackState) => void) | null;

  beforeEach(() => {
    onStateCallback = null;
    mockApi.playback.getState.mockResolvedValue(playingState);
    mockApi.playback.onState.mockImplementation((callback) => {
      onStateCallback = callback;
      return vi.fn();
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it("seeks with a right-side touch double tap on the control surface", async () => {
    render(<PlayerControls />);

    const controls = await screen.findByRole("toolbar", { name: "Playback controls" });
    vi.spyOn(controls, "getBoundingClientRect").mockReturnValue({
      x: 0,
      y: 0,
      width: 200,
      height: 80,
      top: 0,
      right: 200,
      bottom: 80,
      left: 0,
      toJSON: () => ({})
    });

    firePointerUp(controls, { clientX: 150, pointerId: 1, pointerType: "touch" });
    firePointerUp(controls, { clientX: 150, pointerId: 1, pointerType: "touch" });

    await waitFor(() => expect(mockApi.playback.seek).toHaveBeenCalledWith({ offsetSeconds: 10 }));
  });

  it("does not seek when double tapping playback buttons", async () => {
    render(<PlayerControls />);

    const button = await screen.findByRole("button", { name: "Pause playback" });

    firePointerUp(button, { clientX: 150, pointerId: 1, pointerType: "touch" });
    firePointerUp(button, { clientX: 150, pointerId: 1, pointerType: "touch" });

    expect(mockApi.playback.seek).not.toHaveBeenCalled();
  });

  it("does not seek when touch taps move between halves", async () => {
    render(<PlayerControls />);

    const controls = await screen.findByRole("toolbar", { name: "Playback controls" });
    vi.spyOn(controls, "getBoundingClientRect").mockReturnValue({
      x: 0,
      y: 0,
      width: 200,
      height: 80,
      top: 0,
      right: 200,
      bottom: 80,
      left: 0,
      toJSON: () => ({})
    });

    firePointerUp(controls, { clientX: 40, pointerId: 1, pointerType: "touch" });
    firePointerUp(controls, { clientX: 160, pointerId: 1, pointerType: "touch" });

    expect(mockApi.playback.seek).not.toHaveBeenCalled();
  });

  it("seeks when touch double taps use different pointer ids", async () => {
    render(<PlayerControls />);

    const controls = await screen.findByRole("toolbar", { name: "Playback controls" });
    vi.spyOn(controls, "getBoundingClientRect").mockReturnValue({
      x: 0,
      y: 0,
      width: 200,
      height: 80,
      top: 0,
      right: 200,
      bottom: 80,
      left: 0,
      toJSON: () => ({})
    });

    firePointerUp(controls, { clientX: 150, pointerId: 1, pointerType: "touch" });
    firePointerUp(controls, { clientX: 150, pointerId: 2, pointerType: "touch" });

    await waitFor(() => expect(mockApi.playback.seek).toHaveBeenCalledWith({ offsetSeconds: 10 }));
  });

  it("seeks from window ArrowRight while controls are mounted", async () => {
    render(<PlayerControls />);
    await screen.findByRole("toolbar", { name: "Playback controls" });

    fireEvent.keyDown(window, { key: "ArrowRight" });

    expect(mockApi.playback.seek).toHaveBeenCalledWith({ offsetSeconds: 10 });
  });

  it("does not steal arrow keys from text inputs", async () => {
    render(
      <>
        <input aria-label="Search" />
        <PlayerControls />
      </>
    );
    await screen.findByRole("toolbar", { name: "Playback controls" });

    screen.getByLabelText("Search").focus();
    fireEvent.keyDown(window, { key: "ArrowLeft" });

    expect(mockApi.playback.seek).not.toHaveBeenCalled();
  });

  it("does not seek from window arrow keys when playback is not seekable", async () => {
    mockApi.playback.getState.mockResolvedValue({ ...playingState, isSeekable: false });
    render(<PlayerControls />);
    await screen.findByRole("toolbar", { name: "Playback controls" });

    fireEvent.keyDown(window, { key: "ArrowRight" });

    expect(mockApi.playback.seek).not.toHaveBeenCalled();
  });

  it("does not enable seek buttons for a seekable error state", async () => {
    mockApi.playback.getState.mockResolvedValue({
      ...playingState,
      status: "error",
      isSeekable: true,
      errorMessage: "Playback failed."
    });
    render(<PlayerControls />);

    expect((await screen.findByRole<HTMLButtonElement>("button", { name: "Seek back 10 seconds" })).disabled).toBe(
      true
    );
    expect(screen.getByRole<HTMLButtonElement>("button", { name: "Seek forward 10 seconds" }).disabled).toBe(true);
  });

  it("does not seek from window arrow keys for a seekable error state", async () => {
    mockApi.playback.getState.mockResolvedValue({
      ...playingState,
      status: "error",
      isSeekable: true,
      errorMessage: "Playback failed."
    });
    render(<PlayerControls />);
    await screen.findByRole("toolbar", { name: "Playback controls" });

    fireEvent.keyDown(window, { key: "ArrowRight" });

    expect(mockApi.playback.seek).not.toHaveBeenCalled();
  });

  it("updates keyboard seeking when playback state changes", async () => {
    mockApi.playback.getState.mockResolvedValue({ ...playingState, isSeekable: false });
    render(<PlayerControls />);
    await screen.findByRole("toolbar", { name: "Playback controls" });

    act(() => {
      onStateCallback?.(playingState);
    });
    await waitFor(() => {
      expect(screen.getByRole<HTMLButtonElement>("button", { name: "Seek back 10 seconds" }).disabled).toBe(false);
    });

    fireEvent.keyDown(window, { key: "ArrowLeft" });

    expect(mockApi.playback.seek).toHaveBeenCalledWith({ offsetSeconds: -10 });
  });

  it("opens track menus and selects video, audio, and subtitle tracks", async () => {
    mockApi.playback.getState.mockResolvedValue({
      ...playingState,
      videoTracks: [
        {
          id: 1,
          type: "video",
          title: "Main Video",
          language: null,
          isDefault: true,
          isSelected: true
        },
        {
          id: 4,
          type: "video",
          title: "Alternate Angle",
          language: null,
          isDefault: false,
          isSelected: false
        }
      ],
      audioTracks: [
        {
          id: 1,
          type: "audio",
          title: "English Stereo",
          language: "eng",
          isDefault: true,
          isSelected: true
        },
        {
          id: 2,
          type: "audio",
          title: "Director Commentary",
          language: "eng",
          isDefault: false,
          isSelected: false
        }
      ],
      subtitleTracks: [
        {
          id: 3,
          type: "subtitle",
          title: "English CC",
          language: "eng",
          isDefault: false,
          isSelected: true
        }
      ],
      selectedVideoTrackId: 1,
      selectedAudioTrackId: 1,
      selectedSubtitleTrackId: 3
    });
    render(<PlayerControls />);

    fireEvent.click(await screen.findByRole("button", { name: "Video: Main Video" }));
    fireEvent.click(screen.getByRole("menuitemradio", { name: "Alternate Angle" }));
    fireEvent.click(await screen.findByRole("button", { name: "Audio: English Stereo" }));
    fireEvent.click(screen.getByRole("menuitemradio", { name: "Director Commentary" }));
    fireEvent.click(screen.getByRole("button", { name: "Subtitles: English CC" }));
    fireEvent.click(screen.getByRole("menuitemradio", { name: "Subtitles off" }));

    expect(mockApi.playback.selectVideoTrack).toHaveBeenCalledWith(4);
    expect(mockApi.playback.selectAudioTrack).toHaveBeenCalledWith(2);
    expect(mockApi.playback.selectSubtitleTrack).toHaveBeenCalledWith(null);
  });

  it("keeps track menus visible while mpv metadata is still loading", async () => {
    render(<PlayerControls />);

    fireEvent.click(await screen.findByRole("button", { name: "Video: Detecting tracks" }));
    expect(screen.getByRole<HTMLButtonElement>("menuitem", { name: "Detecting video tracks" }).disabled).toBe(true);

    fireEvent.click(screen.getByRole("button", { name: "Audio: Detecting tracks" }));
    expect(screen.getByRole<HTMLButtonElement>("menuitem", { name: "Detecting audio tracks" }).disabled).toBe(true);

    fireEvent.click(screen.getByRole("button", { name: "Subtitles: Off" }));
    expect(screen.getByRole("menuitemradio", { name: "Subtitles off" })).not.toBeNull();
    expect(screen.getByRole<HTMLButtonElement>("menuitem", { name: "No subtitle tracks" }).disabled).toBe(true);
  });
});

function firePointerUp(
  element: Element,
  init: {
    clientX: number;
    pointerId: number;
    pointerType: string;
  }
): void {
  const event = new Event("pointerup", { bubbles: true, cancelable: true });
  Object.defineProperties(event, {
    clientX: { value: init.clientX },
    pointerId: { value: init.pointerId },
    pointerType: { value: init.pointerType }
  });

  fireEvent(element, event);
}
