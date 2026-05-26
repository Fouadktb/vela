import { Buffer } from "node:buffer";
import type { Episode, LiveChannel, LiveProgram, Movie, Series } from "../../../src/shared/catalog/types.js";
import {
  buildXtreamApiUrl,
  buildXtreamLiveStreamUrl,
  buildXtreamMovieStreamUrl,
  buildXtreamSeriesStreamUrl,
  type CreateXtreamProviderInput,
  type ImportProgress,
  type Provider
} from "../../../src/shared/providers/types.js";
import type { createCatalogRepository } from "../storage/catalogRepository.js";
import type { createProviderRepository } from "../storage/providerRepository.js";

interface ImportXtreamProviderDeps {
  providerRepository: ReturnType<typeof createProviderRepository>;
  catalogRepository: ReturnType<typeof createCatalogRepository>;
  emitProgress(progress: ImportProgress): void;
}

interface ImportXtreamSeriesEpisodesDeps {
  catalogRepository: ReturnType<typeof createCatalogRepository>;
}

interface ImportXtreamLiveProgramsDeps {
  catalogRepository: ReturnType<typeof createCatalogRepository>;
}

interface XtreamLiveStreamResponse {
  name?: unknown;
  stream_id?: unknown;
  stream_icon?: unknown;
  epg_channel_id?: unknown;
  category_id?: unknown;
  category_name?: unknown;
  container_extension?: unknown;
  direct_source?: unknown;
}

interface XtreamCategoryResponse {
  category_id?: unknown;
  category_name?: unknown;
}

interface XtreamVodStreamResponse {
  name?: unknown;
  stream_id?: unknown;
  stream_icon?: unknown;
  category_id?: unknown;
  container_extension?: unknown;
  rating?: unknown;
  year?: unknown;
  releaseDate?: unknown;
  direct_source?: unknown;
}

interface XtreamSeriesResponse {
  name?: unknown;
  series_id?: unknown;
  cover?: unknown;
  category_id?: unknown;
}

interface XtreamEpisodeResponse {
  id?: unknown;
  episode_num?: unknown;
  title?: unknown;
  container_extension?: unknown;
  info?: unknown;
  season?: unknown;
}

interface XtreamEpisodeInfoResponse {
  duration?: unknown;
  duration_secs?: unknown;
}

interface XtreamShortEpgResponse {
  epg_listings?: unknown;
}

interface XtreamEpgListingResponse {
  id?: unknown;
  title?: unknown;
  description?: unknown;
  start?: unknown;
  end?: unknown;
  stop?: unknown;
  start_timestamp?: unknown;
  stop_timestamp?: unknown;
  end_timestamp?: unknown;
}

type XtreamFailureKind =
  | "empty"
  | "http"
  | "invalid-credentials"
  | "invalid-source"
  | "network"
  | "unexpected-response";

const xtreamFetchTimeoutMs = 15_000;

class XtreamImportFailure extends Error {
  constructor(
    readonly kind: XtreamFailureKind,
    readonly status?: number
  ) {
    super(kind);
  }
}

export async function importXtreamProvider(provider: Provider, deps: ImportXtreamProviderDeps): Promise<void> {
  try {
    const account = toXtreamAccount(provider);

    deps.emitProgress({
      providerId: provider.id,
      phase: "fetching",
      message: "Loading Xtream live channels",
      current: 0,
      total: 3
    });

    const liveCategories = await loadCategories(account, "get_live_categories");
    const streams = await loadLiveStreams(account);
    const movieCategories = await loadCategories(account, "get_vod_categories");
    const movieStreams = await loadVodStreams(account);
    const seriesCategories = await loadCategories(account, "get_series_categories");
    const seriesItems = await loadSeries(account);
    const nowIso = new Date().toISOString();
    const channels = streams
      .map((stream) => toLiveChannel(provider.id, account, stream, liveCategories, nowIso))
      .filter((channel): channel is LiveChannel => channel !== null);
    const movies = movieStreams
      .map((stream) => toMovie(provider.id, account, stream, movieCategories, nowIso))
      .filter((movie): movie is Movie => movie !== null);
    const series = seriesItems
      .map((item) => toSeries(provider.id, item, seriesCategories, nowIso))
      .filter((item): item is Series => item !== null);

    if (channels.length === 0 && movies.length === 0 && series.length === 0) {
      throw new XtreamImportFailure("empty");
    }

    deps.emitProgress({
      providerId: provider.id,
      phase: "saving",
      message: `Saving ${channels.length} live, ${movies.length} movies, and ${series.length} series`,
      current: 2,
      total: 3
    });

    deps.catalogRepository.replaceLiveChannelsForProvider(provider.id, channels);
    deps.catalogRepository.replaceMoviesForProvider(provider.id, movies);
    deps.catalogRepository.replaceSeriesForProvider(provider.id, series);
    deps.providerRepository.markRefreshed(provider.id);

    deps.emitProgress({
      providerId: provider.id,
      phase: "complete",
      message: `Imported ${formatCount(channels.length, "live channel")}, ${formatCount(movies.length, "movie")}, and ${formatCount(series.length, "series", "series")}`,
      current: 3,
      total: 3
    });
  } catch (error) {
    const message = toSafeXtreamImportErrorMessage(error);
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

export async function importXtreamSeriesEpisodes(
  provider: Provider,
  series: Series,
  deps: ImportXtreamSeriesEpisodesDeps
): Promise<Episode[]> {
  try {
    const account = toXtreamAccount(provider);
    const seriesStreamId = toXtreamSeriesStreamId(series);
    const data = await loadXtreamJson(account, "get_series_info", { series_id: seriesStreamId });
    const nowIso = new Date().toISOString();
    const episodes = flattenXtreamEpisodes(data)
      .map(({ episode, seasonNumber }) => toEpisode(provider.id, account, series.id, episode, seasonNumber, nowIso))
      .filter((episode): episode is Episode => episode !== null);

    deps.catalogRepository.replaceEpisodesForSeries(provider.id, series.id, episodes);
    return episodes;
  } catch (error) {
    throw new Error(toSafeXtreamImportErrorMessage(error));
  }
}

export async function importXtreamLivePrograms(
  provider: Provider,
  channel: LiveChannel,
  deps: ImportXtreamLiveProgramsDeps
): Promise<LiveProgram[]> {
  try {
    const account = toXtreamAccount(provider);
    const streamId = toXtreamLiveStreamId(channel);
    const data = await loadXtreamJson(account, "get_short_epg", { stream_id: streamId, limit: "12" });
    const listings = flattenXtreamEpgListings(data);
    const programs = listings
      .map((listing) => toLiveProgram(provider.id, channel.id, streamId, listing))
      .filter((program): program is LiveProgram => program !== null);

    deps.catalogRepository.replaceLiveProgramsForChannel(provider.id, channel.id, programs);
    return programs;
  } catch (error) {
    throw new Error(toSafeXtreamImportErrorMessage(error));
  }
}

export function toSafeXtreamImportErrorMessage(error: unknown): string {
  if (error instanceof XtreamImportFailure) {
    if (error.kind === "empty") {
      return "Xtream account did not return any live channels, movies, or series";
    }
    if (error.kind === "http") {
      return `Provider server rejected the Xtream API request with HTTP ${error.status ?? "error"}`;
    }
    if (error.kind === "invalid-credentials") {
      return "Xtream login failed. Check the username, password, server URL, and port.";
    }
    if (error.kind === "invalid-source") {
      return "Xtream provider details are incomplete";
    }
    if (error.kind === "network") {
      return "Xtream server could not be reached";
    }
    if (error.kind === "unexpected-response") {
      return "Xtream server returned an unexpected response";
    }
  }

  return "Xtream import failed";
}

async function loadCategories(account: CreateXtreamProviderInput, action: string): Promise<Map<string, string>> {
  const data = await loadXtreamJson(account, action);
  if (!Array.isArray(data)) {
    return new Map();
  }

  const categories = new Map<string, string>();
  for (const rawCategory of data.filter(isRecord) as XtreamCategoryResponse[]) {
    const id = toNonEmptyString(rawCategory.category_id);
    const name = toNonEmptyString(rawCategory.category_name);
    if (id && name) {
      categories.set(id, name);
    }
  }

  return categories;
}

async function loadLiveStreams(account: CreateXtreamProviderInput): Promise<XtreamLiveStreamResponse[]> {
  const data = await loadXtreamJson(account, "get_live_streams");
  if (Array.isArray(data)) {
    return data.filter(isRecord);
  }

  if (isInvalidLoginResponse(data)) {
    throw new XtreamImportFailure("invalid-credentials");
  }

  throw new XtreamImportFailure("unexpected-response");
}

async function loadVodStreams(account: CreateXtreamProviderInput): Promise<XtreamVodStreamResponse[]> {
  const data = await loadXtreamJson(account, "get_vod_streams");
  if (Array.isArray(data)) {
    return data.filter(isRecord);
  }

  if (isInvalidLoginResponse(data)) {
    throw new XtreamImportFailure("invalid-credentials");
  }

  throw new XtreamImportFailure("unexpected-response");
}

async function loadSeries(account: CreateXtreamProviderInput): Promise<XtreamSeriesResponse[]> {
  const data = await loadXtreamJson(account, "get_series");
  if (Array.isArray(data)) {
    return data.filter(isRecord);
  }

  if (isInvalidLoginResponse(data)) {
    throw new XtreamImportFailure("invalid-credentials");
  }

  throw new XtreamImportFailure("unexpected-response");
}

async function loadXtreamJson(
  account: CreateXtreamProviderInput,
  action: string,
  extraParams: Record<string, string> = {}
): Promise<unknown> {
  const abortController = new AbortController();
  const timeout = setTimeout(() => abortController.abort(), xtreamFetchTimeoutMs);
  let response: Response;

  try {
    response = await fetch(buildXtreamApiUrl(account, action, extraParams), {
      signal: abortController.signal
    });
  } catch {
    clearTimeout(timeout);
    throw new XtreamImportFailure("network");
  }

  if (!response.ok) {
    clearTimeout(timeout);
    throw new XtreamImportFailure("http", response.status);
  }

  try {
    return await response.json();
  } catch (error) {
    if (error instanceof XtreamImportFailure) {
      throw error;
    }
    throw new XtreamImportFailure("unexpected-response");
  } finally {
    clearTimeout(timeout);
  }
}

function toXtreamAccount(provider: Provider): CreateXtreamProviderInput {
  if (provider.type !== "xtream" || !provider.username || !provider.password) {
    throw new XtreamImportFailure("invalid-source");
  }

  return {
    name: provider.name,
    serverUrl: provider.source,
    username: provider.username,
    password: provider.password
  };
}

function toXtreamSeriesStreamId(series: Series): string {
  const marker = ":series:";
  const markerIndex = series.id.indexOf(marker);
  const streamId = markerIndex >= 0 ? series.id.slice(markerIndex + marker.length) : "";
  if (!streamId) {
    throw new XtreamImportFailure("invalid-source");
  }

  return streamId;
}

function toXtreamLiveStreamId(channel: LiveChannel): string {
  const streamId = toNonEmptyString(channel.stream.streamId);
  if (streamId) {
    return streamId;
  }

  const marker = ":live:";
  const markerIndex = channel.id.indexOf(marker);
  const fallbackStreamId = markerIndex >= 0 ? channel.id.slice(markerIndex + marker.length) : "";
  if (!fallbackStreamId) {
    throw new XtreamImportFailure("invalid-source");
  }

  return fallbackStreamId;
}

function toLiveChannel(
  providerId: string,
  account: CreateXtreamProviderInput,
  stream: XtreamLiveStreamResponse,
  categories: Map<string, string>,
  nowIso: string
): LiveChannel | null {
  const streamId = toNonEmptyString(stream.stream_id);
  if (!streamId) {
    return null;
  }

  const name = toNonEmptyString(stream.name) ?? `Channel ${streamId}`;
  const containerExtension = toSafeContainerExtension(stream.container_extension) ?? "ts";
  const directSource = toHttpUrlString(stream.direct_source);
  const streamUrl = directSource ?? buildXtreamLiveStreamUrl(account, streamId, containerExtension);
  const categoryId = toNonEmptyString(stream.category_id);

  return {
    type: "live",
    id: `${providerId}:live:${streamId}`,
    providerId,
    name,
    logoUrl: toHttpUrlString(stream.stream_icon),
    stream: {
      providerType: "xtream",
      url: streamUrl,
      streamId,
      containerExtension
    },
    epgChannelId: toNonEmptyString(stream.epg_channel_id),
    category: (categoryId ? categories.get(categoryId) : null) ?? toNonEmptyString(stream.category_name) ?? "Uncategorized",
    lastSeenAt: nowIso,
    isFavorite: false
  };
}

function toMovie(
  providerId: string,
  account: CreateXtreamProviderInput,
  stream: XtreamVodStreamResponse,
  categories: Map<string, string>,
  nowIso: string
): Movie | null {
  const streamId = toNonEmptyString(stream.stream_id);
  if (!streamId) {
    return null;
  }

  const title = toNonEmptyString(stream.name) ?? `Movie ${streamId}`;
  const containerExtension = toSafeContainerExtension(stream.container_extension) ?? "mp4";
  const directSource = toHttpUrlString(stream.direct_source);
  const streamUrl = directSource ?? buildXtreamMovieStreamUrl(account, streamId, containerExtension);
  const categoryId = toNonEmptyString(stream.category_id);

  return {
    type: "movie",
    id: `${providerId}:movie:${streamId}`,
    providerId,
    title,
    posterUrl: toHttpUrlString(stream.stream_icon),
    category: (categoryId ? categories.get(categoryId) : null) ?? "Uncategorized",
    year: toYear(stream.year) ?? toYear(stream.releaseDate),
    rating: toNonEmptyString(stream.rating),
    stream: {
      providerType: "xtream",
      url: streamUrl,
      streamId,
      containerExtension
    },
    lastSeenAt: nowIso,
    isFavorite: false
  };
}

function toSeries(
  providerId: string,
  item: XtreamSeriesResponse,
  categories: Map<string, string>,
  nowIso: string
): Series | null {
  const seriesId = toNonEmptyString(item.series_id);
  if (!seriesId) {
    return null;
  }

  const categoryId = toNonEmptyString(item.category_id);

  return {
    type: "series",
    id: `${providerId}:series:${seriesId}`,
    providerId,
    title: toNonEmptyString(item.name) ?? `Series ${seriesId}`,
    posterUrl: toHttpUrlString(item.cover),
    category: (categoryId ? categories.get(categoryId) : null) ?? "Uncategorized",
    lastSeenAt: nowIso,
    isFavorite: false
  };
}

function toEpisode(
  providerId: string,
  account: CreateXtreamProviderInput,
  seriesId: string,
  episode: XtreamEpisodeResponse,
  fallbackSeasonNumber: number,
  nowIso: string
): Episode | null {
  const streamId = toNonEmptyString(episode.id);
  if (!streamId) {
    return null;
  }

  const info = isRecord(episode.info) ? (episode.info as XtreamEpisodeInfoResponse) : {};
  const containerExtension = toSafeContainerExtension(episode.container_extension) ?? "mp4";
  const streamUrl = buildXtreamSeriesStreamUrl(account, streamId, containerExtension);
  const seasonNumber = toPositiveInteger(episode.season) ?? fallbackSeasonNumber;
  const episodeNumber = toPositiveInteger(episode.episode_num) ?? 0;
  const title = toNonEmptyString(episode.title) ?? `Episode ${episodeNumber || streamId}`;

  return {
    type: "episode",
    id: `${providerId}:episode:${streamId}`,
    providerId,
    seriesId,
    seasonNumber,
    episodeNumber,
    title,
    durationSeconds: toDurationSeconds(info.duration_secs) ?? toDurationSeconds(info.duration),
    progressSeconds: 0,
    stream: {
      providerType: "xtream",
      url: streamUrl,
      streamId,
      containerExtension
    }
  };
}

function flattenXtreamEpisodes(data: unknown): Array<{ episode: XtreamEpisodeResponse; seasonNumber: number }> {
  if (!isRecord(data)) {
    throw new XtreamImportFailure("unexpected-response");
  }

  const rawEpisodes = data.episodes;
  if (Array.isArray(rawEpisodes)) {
    return rawEpisodes.filter(isRecord).map((episode) => ({
      episode,
      seasonNumber: toPositiveInteger((episode as XtreamEpisodeResponse).season) ?? 1
    }));
  }

  if (!isRecord(rawEpisodes)) {
    return [];
  }

  const episodes: Array<{ episode: XtreamEpisodeResponse; seasonNumber: number }> = [];
  for (const [seasonKey, rawSeasonEpisodes] of Object.entries(rawEpisodes)) {
    if (!Array.isArray(rawSeasonEpisodes)) {
      continue;
    }
    const seasonNumber = toPositiveInteger(seasonKey) ?? 1;
    for (const rawEpisode of rawSeasonEpisodes) {
      if (isRecord(rawEpisode)) {
        episodes.push({ episode: rawEpisode, seasonNumber });
      }
    }
  }

  return episodes;
}

function flattenXtreamEpgListings(data: unknown): XtreamEpgListingResponse[] {
  if (Array.isArray(data)) {
    return data.filter(isRecord);
  }

  if (!isRecord(data)) {
    throw new XtreamImportFailure("unexpected-response");
  }

  const rawListings = (data as XtreamShortEpgResponse).epg_listings;
  return Array.isArray(rawListings) ? rawListings.filter(isRecord) : [];
}

function toLiveProgram(
  providerId: string,
  channelId: string,
  streamId: string,
  listing: XtreamEpgListingResponse
): LiveProgram | null {
  const startAt =
    toIsoFromUnixSeconds(listing.start_timestamp) ??
    toIsoFromXtreamDate(listing.start);
  const endAt =
    toIsoFromUnixSeconds(listing.stop_timestamp) ??
    toIsoFromUnixSeconds(listing.end_timestamp) ??
    toIsoFromXtreamDate(listing.end) ??
    toIsoFromXtreamDate(listing.stop);

  if (!startAt || !endAt || endAt <= startAt) {
    return null;
  }

  const title = decodeMaybeBase64(listing.title) ?? "Program";
  const description = decodeMaybeBase64(listing.description);
  const rawId = toNonEmptyString(listing.start_timestamp) ?? toNonEmptyString(listing.id) ?? startAt;

  return {
    id: `${providerId}:live:${streamId}:${rawId}`,
    providerId,
    channelId,
    title,
    description,
    startAt,
    endAt
  };
}

function isInvalidLoginResponse(value: unknown): boolean {
  if (!isRecord(value)) {
    return false;
  }

  const userInfo = value.user_info;
  if (!isRecord(userInfo)) {
    return false;
  }

  return userInfo.auth === 0 || userInfo.auth === "0" || userInfo.status === "Disabled" || userInfo.status === "Expired";
}

function toNonEmptyString(value: unknown): string | null {
  if (typeof value !== "string" && typeof value !== "number") {
    return null;
  }

  const text = String(value).trim();
  return text.length > 0 ? text : null;
}

function toHttpUrlString(value: unknown): string | null {
  const text = toNonEmptyString(value);
  if (!text) {
    return null;
  }

  try {
    const url = new URL(text);
    return url.protocol === "http:" || url.protocol === "https:" ? url.toString() : null;
  } catch {
    return null;
  }
}

function toSafeContainerExtension(value: unknown): string | null {
  const text = toNonEmptyString(value);
  if (!text) {
    return null;
  }

  const normalized = text.toLowerCase().replace(/[^a-z0-9]/g, "");
  return normalized || null;
}

function toYear(value: unknown): number | null {
  const text = toNonEmptyString(value);
  if (!text) {
    return null;
  }

  const match = /\b(19|20)\d{2}\b/.exec(text);
  if (!match) {
    return null;
  }

  return Number(match[0]);
}

function toPositiveInteger(value: unknown): number | null {
  const text = toNonEmptyString(value);
  if (!text) {
    return null;
  }

  const number = Number.parseInt(text, 10);
  return Number.isInteger(number) && number > 0 ? number : null;
}

function toDurationSeconds(value: unknown): number | null {
  const text = toNonEmptyString(value);
  if (!text) {
    return null;
  }

  if (/^\d+$/.test(text)) {
    const seconds = Number.parseInt(text, 10);
    return seconds > 0 ? seconds : null;
  }

  const parts = text.split(":").map((part) => Number.parseInt(part, 10));
  if (parts.some((part) => !Number.isInteger(part) || part < 0)) {
    return null;
  }
  if (parts.length === 3) {
    return parts[0] * 3600 + parts[1] * 60 + parts[2];
  }
  if (parts.length === 2) {
    return parts[0] * 60 + parts[1];
  }

  return null;
}

function toIsoFromUnixSeconds(value: unknown): string | null {
  const text = toNonEmptyString(value);
  if (!text || !/^\d+$/.test(text)) {
    return null;
  }

  const date = new Date(Number.parseInt(text, 10) * 1000);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function toIsoFromXtreamDate(value: unknown): string | null {
  const text = toNonEmptyString(value);
  if (!text) {
    return null;
  }

  const normalized = /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}/.test(text) ? `${text.replace(" ", "T")}Z` : text;
  const date = new Date(normalized);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function decodeMaybeBase64(value: unknown): string | null {
  const text = toNonEmptyString(value);
  if (!text) {
    return null;
  }

  const normalized = text.replace(/\s+/g, "");
  const looksBase64 = normalized.length % 4 === 0 && /^[A-Za-z0-9+/]+={0,2}$/.test(normalized);
  if (!looksBase64) {
    return text;
  }

  try {
    const decoded = Buffer.from(normalized, "base64").toString("utf8").trim();
    if (decoded && !decoded.includes("\uFFFD") && /[\p{L}\p{N}]/u.test(decoded)) {
      return decoded;
    }
  } catch {
    return text;
  }

  return text;
}

function formatCount(count: number, singular: string, plural: string = `${singular}s`): string {
  return `${count} ${count === 1 ? singular : plural}`;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
