import Database from "better-sqlite3";
import { describe, expect, it } from "vitest";
import { createSchema } from "../../electron/main/storage/database";
import { createCatalogRepository } from "../../electron/main/storage/catalogRepository";
import type { LiveChannel } from "../shared/catalog/types";

function channel(overrides: Partial<LiveChannel> = {}): LiveChannel {
  return {
    type: "live",
    id: "provider-1:live:bbc-one",
    providerId: "provider-1",
    name: "BBC One",
    logoUrl: null,
    category: "News",
    stream: {
      providerType: "m3u",
      url: "https://stream.test/bbc.m3u8"
    },
    epgChannelId: "bbc.one",
    lastSeenAt: "2026-05-26T12:00:00.000Z",
    isFavorite: false,
    ...overrides
  };
}

describe("catalogRepository", () => {
  it("upserts and searches live channels", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);

    expect(repo.listLiveChannels("", null)).toHaveLength(1);
    expect(repo.listLiveChannels("bbc", null)[0].name).toBe("BBC One");
    expect(repo.listLiveChannels("", "News")).toHaveLength(1);
    expect(repo.listLiveChannels("", "Sports")).toHaveLength(0);
  });

  it("preserves favorites when channels are refreshed", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);
    repo.toggleFavorite("provider-1:live:bbc-one", "live");
    repo.upsertLiveChannels([channel({ name: "BBC One HD" })]);

    expect(repo.listLiveChannels("bbc", null)[0]).toMatchObject({
      name: "BBC One HD",
      isFavorite: true
    });
  });

  it("does not return stale live channels by id or list", () => {
    const db = new Database(":memory:");
    createSchema(db);
    const repo = createCatalogRepository(db);

    repo.upsertLiveChannels([channel()]);
    db.prepare("UPDATE live_channels SET stale = 1 WHERE id = ?").run("provider-1:live:bbc-one");

    expect(repo.getLiveChannel("provider-1:live:bbc-one")).toBeNull();
    expect(repo.listLiveChannels("", null)).toHaveLength(0);
  });
});
