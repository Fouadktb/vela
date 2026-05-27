import { useEffect } from "react";
import { iptvApi } from "../../app/api";
import type { PlayRequest } from "../../../shared/playback/types";

interface PlaybackLauncherProps {
  request: PlayRequest | null;
  onConsumed(): void;
}

export function PlaybackLauncher({ request, onConsumed }: PlaybackLauncherProps) {
  useEffect(() => {
    if (!request) {
      return;
    }

    let isCancelled = false;

    iptvApi.playback
      .play(request)
      .catch(() => undefined)
      .finally(() => {
        if (!isCancelled) {
          onConsumed();
        }
      });

    return () => {
      isCancelled = true;
    };
  }, [onConsumed, request?.itemId, request?.itemType]);

  return null;
}
