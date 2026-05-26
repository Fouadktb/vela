import type { LiveChannel } from "../../shared/catalog/types.js";

interface ParseM3uOptions {
  providerId: string;
  nowIso: string;
}

interface ParseDiagnostic {
  line: number;
  message: string;
}

interface ParseM3uResult {
  channels: LiveChannel[];
  diagnostics: ParseDiagnostic[];
}

interface ExtInfDraft {
  line: number;
  name: string;
  attributes: Record<string, string>;
}

export function parseM3u(input: string, options: ParseM3uOptions): ParseM3uResult {
  const lines = input.split(/\r?\n/);
  const diagnostics: ParseDiagnostic[] = [];
  const channels: LiveChannel[] = [];
  const slugCounts = new Map<string, number>();
  let pending: ExtInfDraft | null = null;

  for (let index = 0; index < lines.length; index += 1) {
    const rawLine = lines[index];
    const lineNumber = index + 1;
    const line = rawLine.trim();

    if (!line || line === "#EXTM3U") {
      continue;
    }

    if (line.startsWith("#EXTINF:")) {
      if (pending) {
        diagnostics.push({
          line: pending.line,
          message: "EXTINF entry has no following stream URL"
        });
      }
      pending = parseExtInf(line, lineNumber);
      continue;
    }

    if (line.startsWith("#")) {
      continue;
    }

    if (!pending) {
      diagnostics.push({
        line: lineNumber,
        message: "Stream URL has no preceding EXTINF metadata"
      });
      continue;
    }

    const slug = allocateSlug(pending, slugCounts);
    channels.push(toLiveChannel(pending, line, options, slug));
    pending = null;
  }

  if (pending) {
    diagnostics.push({
      line: pending.line,
      message: "EXTINF entry has no following stream URL"
    });
  }

  return { channels, diagnostics };
}

function parseExtInf(line: string, lineNumber: number): ExtInfDraft {
  const commaIndex = line.lastIndexOf(",");
  const metadata = commaIndex >= 0 ? line.slice(0, commaIndex) : line;
  const name = commaIndex >= 0 ? line.slice(commaIndex + 1).trim() : "Unnamed Channel";
  const attributes: Record<string, string> = {};

  for (const match of metadata.matchAll(/([\w-]+)="([^"]*)"/g)) {
    attributes[match[1]] = match[2];
  }

  return {
    line: lineNumber,
    name: name || "Unnamed Channel",
    attributes
  };
}

function toLiveChannel(
  draft: ExtInfDraft,
  url: string,
  options: ParseM3uOptions,
  slug: string
): LiveChannel {
  return {
    type: "live",
    id: `${options.providerId}:live:${slug}`,
    providerId: options.providerId,
    name: draft.name,
    logoUrl: draft.attributes["tvg-logo"] || null,
    category: draft.attributes["group-title"] || "Uncategorized",
    stream: {
      providerType: "m3u",
      url
    },
    epgChannelId: draft.attributes["tvg-id"] || null,
    lastSeenAt: options.nowIso,
    isFavorite: false
  };
}

function allocateSlug(draft: ExtInfDraft, slugCounts: Map<string, number>): string {
  const baseSlug = slugify(draft.name) || `channel-${draft.line}`;
  const nextCount = (slugCounts.get(baseSlug) || 0) + 1;
  slugCounts.set(baseSlug, nextCount);

  return nextCount === 1 ? baseSlug : `${baseSlug}-${nextCount}`;
}

function slugify(value: string): string {
  return value
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80);
}
