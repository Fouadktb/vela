import { act, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { PlaybackState } from "../../../shared/playback/types";
import { PlayerControls } from "./PlayerControls";

const mockApi = vi.hoisted(() => ({
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

    fireEvent.pointerUp(controls, { clientX: 150, pointerType: "touch" });
    fireEvent.pointerUp(controls, { clientX: 150, pointerType: "touch" });

    await waitFor(() => expect(mockApi.playback.seek).toHaveBeenCalledWith({ offsetSeconds: 10 }));
  });

  it("does not seek when double tapping playback buttons", async () => {
    render(<PlayerControls />);

    const button = await screen.findByRole("button", { name: "Pause playback" });

    fireEvent.pointerUp(button, { clientX: 150, pointerType: "touch" });
    fireEvent.pointerUp(button, { clientX: 150, pointerType: "touch" });

    expect(mockApi.playback.seek).not.toHaveBeenCalled();
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
});
