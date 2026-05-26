import { FastForward, Pause, Play, Rewind, Square } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import type { MouseEvent, PointerEvent } from "react";
import { iptvApi } from "../../app/api";
import type { PlaybackState } from "../../../shared/playback/types";
import { getSeekSecondsForDoubleClick } from "./playerGestures";

const DOUBLE_TAP_MAX_MS = 350;
const DOUBLE_TAP_MAX_X_DISTANCE = 48;

interface TapSnapshot {
  clientX: number;
  half: "left" | "right";
  pointerType: string;
  timeStamp: number;
}

export function PlayerControls() {
  const [state, setState] = useState<PlaybackState | null>(null);
  const lastTapRef = useRef<TapSnapshot | null>(null);

  useEffect(() => {
    let isMounted = true;

    iptvApi.playback.getState().then((nextState) => {
      if (isMounted) {
        setState(nextState);
      }
    });

    const unsubscribe = iptvApi.playback.onState((nextState) => {
      setState(nextState);
    });

    return () => {
      isMounted = false;
      unsubscribe();
    };
  }, []);

  useEffect(() => {
    if (!state || !canSeekPlayback(state)) {
      return;
    }

    const handleWindowKeyDown = (event: globalThis.KeyboardEvent) => {
      if (isEditableTarget(event.target) || isEditableTarget(document.activeElement)) {
        return;
      }

      if (event.key === "ArrowLeft") {
        event.preventDefault();
        void iptvApi.playback.seek({ offsetSeconds: -10 });
      }

      if (event.key === "ArrowRight") {
        event.preventDefault();
        void iptvApi.playback.seek({ offsetSeconds: 10 });
      }
    };

    window.addEventListener("keydown", handleWindowKeyDown);

    return () => {
      window.removeEventListener("keydown", handleWindowKeyDown);
    };
  }, [state?.isSeekable, state?.status]);

  if (!state || state.status === "idle") {
    return null;
  }

  const seekBy = (offsetSeconds: -10 | 10) => {
    if (canSeekPlayback(state)) {
      void iptvApi.playback.seek({ offsetSeconds });
    }
  };

  const handleDoubleClick = (event: MouseEvent<HTMLDivElement>) => {
    if (event.target instanceof HTMLElement && event.target.closest("button")) {
      return;
    }

    const bounds = event.currentTarget.getBoundingClientRect();
    const offsetSeconds = getSeekSecondsForDoubleClick({
      clientX: event.clientX,
      left: bounds.left,
      width: bounds.width,
      isSeekable: canSeekPlayback(state)
    });

    if (offsetSeconds !== 0) {
      void iptvApi.playback.seek({ offsetSeconds });
    }
  };

  const handlePointerUp = (event: PointerEvent<HTMLDivElement>) => {
    if (event.pointerType === "mouse" || isButtonEventTarget(event.target)) {
      return;
    }

    const bounds = event.currentTarget.getBoundingClientRect();
    const nextTap: TapSnapshot = {
      clientX: event.clientX,
      half: getTapHalf(event.clientX, bounds.left, bounds.width),
      pointerType: event.pointerType,
      timeStamp: event.timeStamp
    };
    const previousTap = lastTapRef.current;
    lastTapRef.current = nextTap;

    if (!previousTap || !isDoubleTapMatch(previousTap, nextTap)) {
      return;
    }

    lastTapRef.current = null;
    const offsetSeconds = getSeekSecondsForDoubleClick({
      clientX: event.clientX,
      left: bounds.left,
      width: bounds.width,
      isSeekable: canSeekPlayback(state)
    });

    if (offsetSeconds !== 0) {
      void iptvApi.playback.seek({ offsetSeconds });
    }
  };

  const isPlaying = state.status === "playing";
  const canTogglePlayPause = state.status === "playing" || state.status === "paused";
  const canSeek = canSeekPlayback(state);
  const playPauseLabel = isPlaying ? "Pause playback" : "Resume playback";

  return (
    <div
      className="player-controls"
      onDoubleClick={handleDoubleClick}
      onPointerUp={handlePointerUp}
      role="toolbar"
      aria-label="Playback controls"
      tabIndex={0}
    >
      <div className="player-controls-meta">
        <span className="player-controls-title" title={state.title ?? "Playback"}>
          {state.title ?? "Playback"}
        </span>
        {state.errorMessage ? <span className="player-controls-error">{state.errorMessage}</span> : null}
      </div>

      <div className="player-controls-actions">
        <button
          aria-label="Seek back 10 seconds"
          className="icon-button"
          disabled={!canSeek}
          title="Seek back 10 seconds"
          type="button"
          onClick={() => seekBy(-10)}
        >
          <Rewind size={18} aria-hidden="true" />
        </button>
        <button
          aria-label={playPauseLabel}
          className="icon-button primary"
          disabled={!canTogglePlayPause}
          title={playPauseLabel}
          type="button"
          onClick={() => void iptvApi.playback.pause()}
        >
          {isPlaying ? <Pause size={18} aria-hidden="true" /> : <Play size={18} aria-hidden="true" />}
        </button>
        <button
          aria-label="Stop playback"
          className="icon-button"
          title="Stop playback"
          type="button"
          onClick={() => void iptvApi.playback.stop()}
        >
          <Square size={18} aria-hidden="true" />
        </button>
        <button
          aria-label="Seek forward 10 seconds"
          className="icon-button"
          disabled={!canSeek}
          title="Seek forward 10 seconds"
          type="button"
          onClick={() => seekBy(10)}
        >
          <FastForward size={18} aria-hidden="true" />
        </button>
      </div>
    </div>
  );
}

function canSeekPlayback(state: PlaybackState): boolean {
  return state.isSeekable && (state.status === "playing" || state.status === "paused");
}

function getTapHalf(clientX: number, left: number, width: number): "left" | "right" {
  return clientX < left + width / 2 ? "left" : "right";
}

function isDoubleTapMatch(previousTap: TapSnapshot, nextTap: TapSnapshot): boolean {
  if (nextTap.timeStamp - previousTap.timeStamp > DOUBLE_TAP_MAX_MS) {
    return false;
  }

  if (previousTap.pointerType !== nextTap.pointerType) {
    return false;
  }

  return previousTap.half === nextTap.half || Math.abs(previousTap.clientX - nextTap.clientX) <= DOUBLE_TAP_MAX_X_DISTANCE;
}

function isButtonEventTarget(target: EventTarget): boolean {
  return target instanceof HTMLElement && Boolean(target.closest("button"));
}

function isEditableTarget(target: EventTarget | null): boolean {
  if (!(target instanceof HTMLElement)) {
    return false;
  }

  if (target.isContentEditable || target.closest("[contenteditable='true']")) {
    return true;
  }

  return target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement || target instanceof HTMLSelectElement;
}
