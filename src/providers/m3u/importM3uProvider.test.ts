import fs from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it, vi } from "vitest";
import { importM3uProvider } from "../../../electron/main/imports/importM3uProvider.js";
import type { ImportProgress, Provider } from "../../shared/providers/types.js";

describe("importM3uProvider", () => {
  it("sanitizes local file import failures and emits failed progress", async () => {
    const provider: Provider = {
      id: "provider-1",
      type: "m3u",
      name: "Local playlist",
      source: "/tmp/private/user:secret/playlist.m3u",
      username: null,
      password: null,
      createdAt: "2026-05-26T00:00:00.000Z",
      updatedAt: "2026-05-26T00:00:00.000Z",
      lastRefreshAt: null
    };
    const progress: ImportProgress[] = [];

    await expect(
      importM3uProvider(provider, {
        providerRepository: { markRefreshed: () => undefined } as never,
        catalogRepository: { replaceLiveChannelsForProvider: () => undefined } as never,
        emitProgress: (event) => progress.push(event)
      })
    ).rejects.toThrow("Local playlist file could not be read");

    expect(progress.at(-1)).toEqual({
      providerId: "provider-1",
      phase: "failed",
      message: "Local playlist file could not be read",
      current: 0,
      total: 3
    });
    expect(progress.map((event) => event.message).join("\n")).not.toContain(provider.source);
  });

  it("replaces provider channels on successful import", async () => {
    const playlistPath = await writeTempPlaylist(`#EXTM3U
#EXTINF:-1 tvg-id="city.news" group-title="News",City News
https://stream.test/city-news.m3u8
`);
    const provider = providerWithSource(playlistPath);
    const replaceLiveChannelsForProvider = vi.fn();
    const markRefreshed = vi.fn();

    await importM3uProvider(provider, {
      providerRepository: { markRefreshed } as never,
      catalogRepository: { replaceLiveChannelsForProvider } as never,
      emitProgress: () => undefined
    });

    expect(replaceLiveChannelsForProvider).toHaveBeenCalledWith(
      provider.id,
      expect.arrayContaining([
        expect.objectContaining({
          id: "provider-1:live:city-news",
          name: "City News",
          providerId: provider.id
        })
      ])
    );
    expect(markRefreshed).toHaveBeenCalledWith(provider.id);
  });

  it("rejects unsupported playlist sources without exposing the source", async () => {
    const provider = providerWithSource("relative-playlist.m3u");
    const progress: ImportProgress[] = [];

    await expect(
      importM3uProvider(provider, {
        providerRepository: { markRefreshed: () => undefined } as never,
        catalogRepository: { replaceLiveChannelsForProvider: () => undefined } as never,
        emitProgress: (event) => progress.push(event)
      })
    ).rejects.toThrow("Playlist source is not supported");

    expect(progress.at(-1)?.message).toBe("Playlist source is not supported");
    expect(progress.map((event) => event.message).join("\n")).not.toContain(provider.source);
  });

  it("rejects empty playlists", async () => {
    const provider = providerWithSource(await writeTempPlaylist("#EXTM3U\n"));
    const replaceLiveChannelsForProvider = vi.fn();
    const markRefreshed = vi.fn();

    await expect(
      importM3uProvider(provider, {
        providerRepository: { markRefreshed } as never,
        catalogRepository: { replaceLiveChannelsForProvider } as never,
        emitProgress: () => undefined
      })
    ).rejects.toThrow("Playlist did not contain any playable channels");

    expect(replaceLiveChannelsForProvider).not.toHaveBeenCalled();
    expect(markRefreshed).not.toHaveBeenCalled();
  });
});

function providerWithSource(source: string): Provider {
  return {
    id: "provider-1",
    type: "m3u",
    name: "Local playlist",
    source,
    username: null,
    password: null,
    createdAt: "2026-05-26T00:00:00.000Z",
    updatedAt: "2026-05-26T00:00:00.000Z",
    lastRefreshAt: null
  };
}

async function writeTempPlaylist(content: string): Promise<string> {
  const directory = await fs.mkdtemp(join(tmpdir(), "iptv-player-test-"));
  const playlistPath = join(directory, "playlist.m3u");
  await fs.writeFile(playlistPath, content, "utf8");
  return playlistPath;
}
