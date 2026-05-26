import type { CatalogItemType } from "../catalog/types.js";

export interface PlayRequest {
  itemType: CatalogItemType;
  itemId: string;
}

export type PlaybackStatus = "idle" | "loading" | "playing" | "paused" | "error";

export interface PlaybackState {
  status: PlaybackStatus;
  itemId: string | null;
  itemType: CatalogItemType | null;
  title: string | null;
  positionSeconds: number;
  durationSeconds: number | null;
  isSeekable: boolean;
  errorMessage: string | null;
}

export interface SeekRequest {
  seconds: number;
}
