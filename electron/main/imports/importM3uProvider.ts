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

type ImportFailureKind = "empty" | "http" | "invalid-source" | "local-read" | "network" | "too-large";

const playlistFetchTimeoutMs = 15_000;
const maxPlaylistBytes = 20 * 1024 * 1024;

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

    if (parsed.channels.length === 0) {
      throw new ImportFailure("empty");
    }

    deps.emitProgress({
      providerId: provider.id,
      phase: "saving",
      message: `Saving ${parsed.channels.length} channels`,
      current: 2,
      total: 3
    });

    deps.catalogRepository.replaceLiveChannelsForProvider(provider.id, parsed.channels);
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
    if (error.kind === "empty") {
      return "Playlist did not contain any playable channels";
    }
    if (error.kind === "http") {
      return `Playlist request failed with HTTP ${error.status ?? "error"}`;
    }
    if (error.kind === "invalid-source") {
      return "Playlist source is not supported";
    }
    if (error.kind === "local-read") {
      return "Local playlist file could not be read";
    }
    if (error.kind === "network") {
      return "Playlist could not be loaded";
    }
    if (error.kind === "too-large") {
      return "Playlist is too large to import";
    }
  }

  return "Playlist import failed";
}

async function loadPlaylist(source: string): Promise<string> {
  if (isHttpSource(source)) {
    const abortController = new AbortController();
    const timeout = setTimeout(() => abortController.abort(), playlistFetchTimeoutMs);
    let response: Response;
    try {
      response = await fetch(source, { signal: abortController.signal });
    } catch {
      clearTimeout(timeout);
      throw new ImportFailure("network");
    }

    if (!response.ok) {
      clearTimeout(timeout);
      throw new ImportFailure("http", response.status);
    }

    const contentLength = response.headers.get("content-length");
    if (contentLength && Number(contentLength) > maxPlaylistBytes) {
      clearTimeout(timeout);
      throw new ImportFailure("too-large");
    }

    try {
      return await readResponseTextWithLimit(response);
    } finally {
      clearTimeout(timeout);
    }
  }

  if (!isAbsoluteFilePath(source)) {
    throw new ImportFailure("invalid-source");
  }

  try {
    const stat = await fs.stat(source);
    if (stat.size > maxPlaylistBytes) {
      throw new ImportFailure("too-large");
    }
    return await fs.readFile(source, "utf8");
  } catch (error) {
    if (error instanceof ImportFailure) {
      throw error;
    }
    throw new ImportFailure("local-read");
  }
}

async function readResponseTextWithLimit(response: Response): Promise<string> {
  if (!response.body) {
    const text = await response.text();
    if (Buffer.byteLength(text, "utf8") > maxPlaylistBytes) {
      throw new ImportFailure("too-large");
    }
    return text;
  }

  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let bytesRead = 0;

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }
      bytesRead += value.byteLength;
      if (bytesRead > maxPlaylistBytes) {
        throw new ImportFailure("too-large");
      }
      chunks.push(value);
    }
  } catch (error) {
    if (error instanceof ImportFailure) {
      throw error;
    }
    throw new ImportFailure("network");
  } finally {
    reader.releaseLock();
  }

  return Buffer.concat(chunks).toString("utf8");
}

function isHttpSource(source: string): boolean {
  try {
    const url = new URL(source);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
}

function isAbsoluteFilePath(source: string): boolean {
  return source.startsWith("/") || /^[a-zA-Z]:[\\/]/.test(source) || source.startsWith("\\\\");
}
