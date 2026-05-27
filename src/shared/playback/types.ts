import type { PlayableCatalogItemType } from "../catalog/types.js";

export interface PlayRequest {
  itemType: PlayableCatalogItemType;
  itemId: string;
}

export type PlaybackStatus = "idle" | "loading" | "playing" | "paused" | "error";

export interface PlaybackTrack {
  id: number;
  type: "video" | "audio" | "subtitle";
  title: string;
  language: string | null;
  isDefault: boolean;
  isSelected: boolean;
}

export interface PlaybackState {
  status: PlaybackStatus;
  itemId: string | null;
  itemType: PlayableCatalogItemType | null;
  title: string | null;
  positionSeconds: number;
  durationSeconds: number | null;
  isSeekable: boolean;
  videoTracks: PlaybackTrack[];
  audioTracks: PlaybackTrack[];
  subtitleTracks: PlaybackTrack[];
  selectedVideoTrackId: number | null;
  selectedAudioTrackId: number | null;
  selectedSubtitleTrackId: number | null;
  errorMessage: string | null;
}

export interface SeekRequest {
  offsetSeconds: number;
}
