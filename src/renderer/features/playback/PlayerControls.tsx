import { FastForward, Pause, Play, Rewind, Square } from "lucide-react";
import { useEffect, useState } from "react";
import type { KeyboardEvent, MouseEvent } from "react";
import { iptvApi } from "../../app/api";
import type { PlaybackState } from "../../../shared/playback/types";
import { getSeekSecondsForDoubleClick } from "./playerGestures";

export function PlayerControls() {
  const [state, setState] = useState<PlaybackState | null>(null);

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

  if (!state || state.status === "idle") {
    return null;
  }

  const seekBy = (offsetSeconds: -10 | 10) => {
    if (state.isSeekable) {
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
      isSeekable: state.isSeekable
    });

    if (offsetSeconds !== 0) {
      void iptvApi.playback.seek({ offsetSeconds });
    }
  };

  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (!state.isSeekable) {
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

  const isPlaying = state.status === "playing";
  const canTogglePlayPause = state.status === "playing" || state.status === "paused";
  const playPauseLabel = isPlaying ? "Pause playback" : "Resume playback";

  return (
    <div
      className="player-controls"
      onDoubleClick={handleDoubleClick}
      onKeyDown={handleKeyDown}
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
          disabled={!state.isSeekable}
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
          disabled={!state.isSeekable}
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
