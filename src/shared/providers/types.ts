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

export interface CreateXtreamProviderInput {
  name: string;
  serverUrl: string;
  username: string;
  password: string;
}

const maxProviderNameLength = 100;
const maxProviderSourceLength = 4096;
const maxProviderCredentialLength = 1024;

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

export function validateCreateXtreamProviderInput(input: unknown): CreateXtreamProviderInput {
  if (!isRecord(input)) {
    throw new Error("Invalid Xtream provider input");
  }

  const name = typeof input.name === "string" ? input.name.trim() : "";
  const serverUrl = typeof input.serverUrl === "string" ? normalizeXtreamServerUrl(input.serverUrl) : "";
  const username = typeof input.username === "string" ? input.username.trim() : "";
  const password = typeof input.password === "string" ? input.password.trim() : "";

  if (name.length === 0 || name.length > maxProviderNameLength) {
    throw new Error("Invalid Xtream provider input");
  }

  if (serverUrl.length === 0 || serverUrl.length > maxProviderSourceLength || !isHttpServerUrl(serverUrl)) {
    throw new Error("Invalid Xtream provider input");
  }

  if (
    username.length === 0 ||
    username.length > maxProviderCredentialLength ||
    password.length === 0 ||
    password.length > maxProviderCredentialLength
  ) {
    throw new Error("Invalid Xtream provider input");
  }

  return { name, serverUrl, username, password };
}

export function buildXtreamM3uPlaylistUrl(input: CreateXtreamProviderInput): string {
  const url = new URL("/get.php", input.serverUrl);
  url.searchParams.set("username", input.username);
  url.searchParams.set("password", input.password);
  url.searchParams.set("type", "m3u_plus");
  url.searchParams.set("output", "ts");
  return url.toString();
}

export function buildXtreamApiUrl(
  input: CreateXtreamProviderInput,
  action?: string,
  extraParams: Record<string, string> = {}
): string {
  const url = new URL("/player_api.php", input.serverUrl);
  url.searchParams.set("username", input.username);
  url.searchParams.set("password", input.password);
  if (action) {
    url.searchParams.set("action", action);
  }
  for (const [key, value] of Object.entries(extraParams)) {
    url.searchParams.set(key, value);
  }
  return url.toString();
}

export function buildXtreamLiveStreamUrl(
  input: CreateXtreamProviderInput,
  streamId: string,
  containerExtension: string = "ts"
): string {
  return buildXtreamStreamUrl(input, "live", streamId, containerExtension);
}

export function buildXtreamMovieStreamUrl(
  input: CreateXtreamProviderInput,
  streamId: string,
  containerExtension: string = "mp4"
): string {
  return buildXtreamStreamUrl(input, "movie", streamId, containerExtension);
}

export function buildXtreamSeriesStreamUrl(
  input: CreateXtreamProviderInput,
  streamId: string,
  containerExtension: string = "mp4"
): string {
  return buildXtreamStreamUrl(input, "series", streamId, containerExtension);
}

function buildXtreamStreamUrl(
  input: CreateXtreamProviderInput,
  contentPath: "live" | "movie" | "series",
  streamId: string,
  containerExtension: string
): string {
  const encodedUsername = encodeURIComponent(input.username);
  const encodedPassword = encodeURIComponent(input.password);
  const encodedStreamId = encodeURIComponent(streamId);
  const encodedExtension = encodeURIComponent(containerExtension);
  const url = new URL(
    `/${contentPath}/${encodedUsername}/${encodedPassword}/${encodedStreamId}.${encodedExtension}`,
    input.serverUrl
  );
  return url.toString();
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

function isHttpServerUrl(source: string): boolean {
  try {
    const url = new URL(source);
    return (url.protocol === "http:" || url.protocol === "https:") && Boolean(url.hostname);
  } catch {
    return false;
  }
}

function normalizeXtreamServerUrl(source: string): string {
  const trimmed = source.trim();
  if (!trimmed) {
    return "";
  }

  try {
    const url = new URL(trimmed);
    url.pathname = url.pathname.replace(/\/+$/, "");
    url.search = "";
    url.hash = "";
    return url.toString().replace(/\/$/, "");
  } catch {
    return trimmed;
  }
}

function isAbsoluteFilePath(source: string): boolean {
  return source.startsWith("/") || /^[a-zA-Z]:[\\/]/.test(source) || source.startsWith("\\\\");
}
