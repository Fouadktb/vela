import { spawn } from "node:child_process";
import type { PlayRequest } from "../../../src/shared/playback/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";

export function buildExternalPlayerArgs(url: string): string[] {
  return [url];
}

export async function openInExternalPlayer(
  request: PlayRequest,
  catalogRepository?: ReturnType<typeof createCatalogRepository>
): Promise<void> {
  if (!catalogRepository) {
    throw new Error("Catalog repository is required to open external playback");
  }
  if (request.itemType !== "live") {
    throw new Error(`Unsupported external playback item type: ${request.itemType}`);
  }

  const channel = catalogRepository.getLiveChannel(request.itemId);
  if (!channel) {
    throw new Error(`Live channel not found: ${request.itemId}`);
  }

  const url = channel.stream.url;
  if (!url) {
    throw new Error(`No playable stream for live channel: ${request.itemId}`);
  }

  const player = process.env.IPTV_EXTERNAL_PLAYER || "mpv";
  const child = spawn(player, buildExternalPlayerArgs(url), {
    detached: true,
    stdio: "ignore"
  });
  child.unref();
  catalogRepository.markRecentlyWatched(channel.id, "live");
}
