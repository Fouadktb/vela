export type ProviderType = "m3u" | "xtream";

export interface Provider {
  id: string;
  type: ProviderType;
  name: string;
  source: string;
  username: string | null;
  password: string | null;
  createdAt: string;
  updatedAt: string;
  lastRefreshAt: string | null;
}

export interface ProviderSummary {
  id: string;
  type: ProviderType;
  name: string;
  createdAt: string;
  updatedAt: string;
  lastRefreshAt: string | null;
}

export function toProviderSummary(provider: Provider): ProviderSummary {
  return {
    id: provider.id,
    type: provider.type,
    name: provider.name,
    createdAt: provider.createdAt,
    updatedAt: provider.updatedAt,
    lastRefreshAt: provider.lastRefreshAt
  };
}

export interface CreateM3uProviderInput {
  name: string;
  source: string;
  sourceKind: "url" | "file";
}

const maxProviderNameLength = 100;
const maxProviderSourceLength = 4096;

export function validateCreateM3uProviderInput(input: unknown): CreateM3uProviderInput {
  if (!isRecord(input)) {
    throw new Error("Invalid M3U provider input");
  }

  const name = typeof input.name === "string" ? input.name.trim() : "";
  const source = typeof input.source === "string" ? input.source.trim() : "";
  const sourceKind = input.sourceKind;

  if (name.length === 0 || name.length > maxProviderNameLength) {
    throw new Error("Invalid M3U provider input");
  }

  if (source.length === 0 || source.length > maxProviderSourceLength) {
    throw new Error("Invalid M3U provider input");
  }

  if (sourceKind !== "url" && sourceKind !== "file") {
    throw new Error("Invalid M3U provider input");
  }

  if (sourceKind === "url" && !isHttpPlaylistUrl(source)) {
    throw new Error("Invalid M3U provider input");
  }

  if (sourceKind === "file" && !isAbsoluteFilePath(source)) {
    throw new Error("Invalid M3U provider input");
  }

  return { name, source, sourceKind };
}

export interface ImportProgress {
  providerId: string;
  phase: "fetching" | "parsing" | "saving" | "complete" | "failed";
  message: string;
  current: number;
  total: number;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isHttpPlaylistUrl(source: string): boolean {
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
