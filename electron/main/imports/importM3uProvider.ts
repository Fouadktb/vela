import fs from "node:fs/promises";
import { parseM3u } from "../../../src/providers/m3u/parseM3u.js";
import type { ImportProgress, Provider } from "../../../src/shared/providers/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";
import type { createProviderRepository } from "../storage/providerRepository.js";

interface ImportM3uProviderDeps {
  providerRepository: ReturnType<typeof createProviderRepository>;
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  emitProgress(progress: ImportProgress): void;
}

export async function importM3uProvider(provider: Provider, deps: ImportM3uProviderDeps): Promise<void> {
  deps.emitProgress({
    providerId: provider.id,
    phase: "fetching",
    message: "Loading playlist",
    current: 0,
    total: 3
  });

  const playlist = await loadPlaylist(provider.source);

  deps.emitProgress({
    providerId: provider.id,
    phase: "parsing",
    message: "Parsing playlist",
    current: 1,
    total: 3
  });

  const parsed = parseM3u(playlist, {
    providerId: provider.id,
    nowIso: new Date().toISOString()
  });

  deps.emitProgress({
    providerId: provider.id,
    phase: "saving",
    message: `Saving ${parsed.channels.length} channels`,
    current: 2,
    total: 3
  });

  deps.catalogRepository.upsertLiveChannels(parsed.channels);
  deps.providerRepository.markRefreshed(provider.id);

  deps.emitProgress({
    providerId: provider.id,
    phase: "complete",
    message: `Imported ${parsed.channels.length} channels`,
    current: 3,
    total: 3
  });
}

async function loadPlaylist(source: string): Promise<string> {
  if (/^https?:\/\//i.test(source)) {
    const response = await fetch(source);
    if (!response.ok) {
      throw new Error(`Playlist request failed with HTTP ${response.status}`);
    }
    return response.text();
  }

  return fs.readFile(source, "utf8");
}
