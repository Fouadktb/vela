import { useEffect, useRef, useState } from "react";
import { iptvApi } from "../../app/api";
import type { PlaybackState } from "../../../shared/playback/types";
import { getSeekSecondsForDoubleClick } from "./playerGestures";
import { PlayerControls } from "./PlayerControls";

const doubleTapMaxMs = 350;
const doubleTapMaxXDistance = 48;

interface TapSnapshot {
  clientX: number;
  half: "left" | "right";
  pointerType: string;
  timeStamp: number;
}

export function PlayerOverlayApp() {
  const [state, setState] = useState<PlaybackState | null>(null);
  const lastTapRef = useRef<TapSnapshot | null>(null);

  useEffect(() => {
    let isMounted = true;

    iptvApi.playback
      .getState()
      .then((nextState) => {
        if (isMounted) {
          setState(nextState);
        }
      })
      .catch(() => {
        if (isMounted) {
          setState(null);
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
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        void iptvApi.playback.stop();
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const canSeek = Boolean(state?.isSeekable && (state.status === "playing" || state.status === "paused"));

  return (
    <main
      className="player-overlay-shell"
      aria-label="Vela theater player"
      onDoubleClick={(event) => {
        if (event.target instanceof HTMLElement && event.target.closest("button, .player-controls")) {
          return;
        }
        const offsetSeconds = getSeekSecondsForDoubleClick({
          clientX: event.clientX,
          left: 0,
          width: window.innerWidth,
          isSeekable: canSeek
        });
        if (offsetSeconds !== 0) {
          void iptvApi.playback.seek({ offsetSeconds });
        }
      }}
      onPointerUp={(event) => {
        if (
          event.pointerType === "mouse" ||
          (event.target instanceof HTMLElement && event.target.closest("button, .player-controls"))
        ) {
          return;
        }

        const nextTap: TapSnapshot = {
          clientX: event.clientX,
          half: event.clientX < window.innerWidth / 2 ? "left" : "right",
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
          left: 0,
          width: window.innerWidth,
          isSeekable: canSeek
        });
        if (offsetSeconds !== 0) {
          void iptvApi.playback.seek({ offsetSeconds });
        }
      }}
    >
      <div className="player-overlay-gradient" aria-hidden="true" />
      {state?.status === "loading" ? <div className="player-overlay-status">Loading playback</div> : null}
      {state?.status === "error" && state.errorMessage ? (
        <div className="player-overlay-status error">{state.errorMessage}</div>
      ) : null}
      <PlayerControls state={state} />
    </main>
  );
}

function isDoubleTapMatch(previousTap: TapSnapshot, nextTap: TapSnapshot): boolean {
  if (nextTap.timeStamp - previousTap.timeStamp > doubleTapMaxMs) {
    return false;
  }

  if (previousTap.pointerType !== nextTap.pointerType) {
    return false;
  }

  return previousTap.half === nextTap.half || Math.abs(previousTap.clientX - nextTap.clientX) <= doubleTapMaxXDistance;
}
