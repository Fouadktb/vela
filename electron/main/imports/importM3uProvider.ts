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

type ImportFailureKind = "http" | "local-read" | "network";

class ImportFailure extends Error {
  constructor(
    readonly kind: ImportFailureKind,
    readonly status?: number
  ) {
    super(kind);
  }
}

export async function importM3uProvider(provider: Provider, deps: ImportM3uProviderDeps): Promise<void> {
  try {
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
  } catch (error) {
    const message = toSafeImportErrorMessage(error);
    deps.emitProgress({
      providerId: provider.id,
      phase: "failed",
      message,
      current: 0,
      total: 3
    });
    throw new Error(message);
  }
}

export function toSafeImportErrorMessage(error: unknown): string {
  if (error instanceof ImportFailure) {
    if (error.kind === "http") {
      return `Playlist request failed with HTTP ${error.status ?? "error"}`;
    }
    if (error.kind === "local-read") {
      return "Local playlist file could not be read";
    }
    if (error.kind === "network") {
      return "Playlist could not be loaded";
    }
  }

  return "Playlist import failed";
}

async function loadPlaylist(source: string): Promise<string> {
  if (/^https?:\/\//i.test(source)) {
    let response: Response;
    try {
      response = await fetch(source);
    } catch {
      throw new ImportFailure("network");
    }
    if (!response.ok) {
      throw new ImportFailure("http", response.status);
    }
    return response.text();
  }

  try {
    return await fs.readFile(source, "utf8");
  } catch {
    throw new ImportFailure("local-read");
  }
}
