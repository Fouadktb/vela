import type {
  InAppPlaybackEngine,
  PlayRequest,
  ResolvedPlaybackSource
} from "../../../src/shared/playback/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";

type CatalogRepository = ReturnType<typeof createCatalogRepository>;

export function resolvePlaybackSource(
  request: PlayRequest,
  catalogRepository: CatalogRepository
): ResolvedPlaybackSource {
  if (request.itemType !== "live" && request.itemType !== "movie" && request.itemType !== "episode") {
    throw new Error(`Unsupported playback item type: ${request.itemType}`);
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

  catalogRepository.markRecentlyWatched(item.id, request.itemType);

  return {
    itemId: item.id,
    itemType: request.itemType,
    title: getPlaybackTitle(item),
    url,
    isLive: request.itemType === "live",
    preferredEngine: getPreferredInAppEngine(url, request.itemType)
  };
}

export function getPreferredInAppEngine(url: string, itemType: PlayRequest["itemType"]): InAppPlaybackEngine {
  const normalizedUrl = url.toLowerCase();
  const pathname = getUrlPathname(normalizedUrl);

  if (pathname.endsWith(".m3u8") || normalizedUrl.includes("application/vnd.apple.mpegurl")) {
    return "hls";
  }

  if (pathname.endsWith(".ts") || pathname.endsWith(".m2ts") || pathname.endsWith(".mts")) {
    return "mpegts";
  }

  if (itemType === "live" && (pathname.includes("/live/") || normalizedUrl.includes("output=ts"))) {
    return "mpegts";
  }

  if (pathname.endsWith(".mkv") || pathname.endsWith(".avi")) {
    return "fallback";
  }

  return "native";
}

function getPlaybackTitle(item: ReturnType<CatalogRepository["getLiveChannel"]> | ReturnType<CatalogRepository["getMovie"]> | ReturnType<CatalogRepository["getEpisode"]>): string {
  if (!item) {
    return "Playback";
  }

  if (item.type === "live") {
    return item.name;
  }

  if (item.type === "episode") {
    return `S${item.seasonNumber} E${item.episodeNumber} ${item.title}`;
  }

  return item.title;
}

function getUrlPathname(url: string): string {
  try {
    return new URL(url).pathname.toLowerCase();
  } catch {
    return url;
  }
}
