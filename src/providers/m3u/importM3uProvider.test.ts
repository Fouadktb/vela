import { describe, expect, it } from "vitest";
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
        catalogRepository: { upsertLiveChannels: () => undefined } as never,
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
});
