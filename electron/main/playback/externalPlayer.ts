import { spawn } from "node:child_process";
import type { EventEmitter } from "node:events";
import type { PlayRequest } from "../../../src/shared/playback/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";

const externalPlayerLaunchTimeoutMs = 1_500;

export function buildExternalPlayerArgs(url: string): string[] {
  return [url];
}

export function waitForExternalPlayerLaunch(child: EventEmitter, timeoutMs = externalPlayerLaunchTimeoutMs): Promise<void> {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      cleanup();
      reject(new Error("External player failed to launch"));
    }, timeoutMs);

    const cleanup = () => {
      clearTimeout(timeout);
      child.removeListener("spawn", onSpawn);
      child.removeListener("error", onError);
    };

    const onSpawn = () => {
      cleanup();
      resolve();
    };

    const onError = () => {
      cleanup();
      reject(new Error("External player failed to launch"));
    };

    child.once("spawn", onSpawn);
    child.once("error", onError);
  });
}

export async function openInExternalPlayer(
  request: PlayRequest,
  catalogRepository?: ReturnType<typeof createCatalogRepository>
): Promise<void> {
  if (!catalogRepository) {
    throw new Error("Catalog repository is required to open external playback");
  }
  if (request.itemType !== "live" && request.itemType !== "movie" && request.itemType !== "episode") {
    throw new Error(`Unsupported external playback item type: ${request.itemType}`);
  }

  const item =
    request.itemType === "live"
      ? catalogRepository.getLiveChannel(request.itemId)
      : request.itemType === "movie"
        ? catalogRepository.getMovie(request.itemId)
        : catalogRepository.getEpisode(request.itemId);
  if (!item) {
    throw new Error(`Catalog item not found: ${request.itemId}`);
  }

  const url = item.stream.url;
  if (!url) {
    throw new Error(`No playable stream for catalog item: ${request.itemId}`);
  }

  const player = process.env.IPTV_EXTERNAL_PLAYER || "mpv";
  let child: ReturnType<typeof spawn>;
  try {
    child = spawn(player, buildExternalPlayerArgs(url), {
      detached: true,
      stdio: "ignore"
    });
  } catch {
    throw new Error("External player failed to launch");
  }

  await waitForExternalPlayerLaunch(child);
  child.unref();
  catalogRepository.markRecentlyWatched(item.id, request.itemType);
}
