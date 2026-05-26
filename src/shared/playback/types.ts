import type { PlayableCatalogItemType } from "../catalog/types.js";

export interface PlayRequest {
  itemType: PlayableCatalogItemType;
  itemId: string;
}

export type PlaybackStatus = "idle" | "loading" | "playing" | "paused" | "error";

export interface PlaybackState {
  status: PlaybackStatus;
  itemId: string | null;
  itemType: PlayableCatalogItemType | null;
  title: string | null;
  positionSeconds: number;
  durationSeconds: number | null;
  isSeekable: boolean;
  errorMessage: string | null;
}

export interface SeekRequest {
  offsetSeconds: number;
}
