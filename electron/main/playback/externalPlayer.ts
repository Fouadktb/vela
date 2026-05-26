import type { PlayRequest } from "../../../src/shared/playback/types.js";

export async function openInExternalPlayer(_request: PlayRequest): Promise<void> {
  return Promise.resolve();
}
