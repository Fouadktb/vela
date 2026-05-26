import type { PlaybackState, PlayRequest, SeekRequest } from "../../../src/shared/playback/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";

interface CreateMpvControllerOptions {
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  onStateChange(state: PlaybackState): void;
}

export function createMpvController(_options: CreateMpvControllerOptions) {
  const state: PlaybackState = {
    status: "idle",
    itemId: null,
    itemType: null,
    title: null,
    positionSeconds: 0,
    durationSeconds: null,
    isSeekable: false,
    errorMessage: null
  };

  return {
    play(_request: PlayRequest): Promise<void> {
      return Promise.resolve();
    },
    pause(): Promise<void> {
      return Promise.resolve();
    },
    stop(): Promise<void> {
      return Promise.resolve();
    },
    seek(_request: SeekRequest): Promise<void> {
      return Promise.resolve();
    },
    getState(): PlaybackState {
      return state;
    }
  };
}
