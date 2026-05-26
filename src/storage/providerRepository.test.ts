import Database from "better-sqlite3";
import { describe, expect, it } from "vitest";
import { createSchema } from "../../electron/main/storage/database";
import { createProviderRepository } from "../../electron/main/storage/providerRepository";

function createTestRepository() {
  const db = new Database(":memory:");
  createSchema(db);
  return {
    db,
    repo: createProviderRepository(db)
  };
}

describe("providerRepository", () => {
  it("stores and returns an internal m3u provider with source and null credentials", () => {
    const { repo } = createTestRepository();

    const provider = repo.createM3u({
      name: "Main playlist",
      source: "https://example.test/playlist.m3u",
      sourceKind: "url"
    });

    expect(provider).toMatchObject({
      type: "m3u",
      name: "Main playlist",
      source: "https://example.test/playlist.m3u",
      username: null,
      password: null,
      lastRefreshAt: null
    });
    expect(provider.id).toEqual(expect.any(String));
    expect(provider.createdAt).toEqual(expect.any(String));
    expect(provider.updatedAt).toBe(provider.createdAt);
  });

  it("stores and returns an xtream provider with server and credentials", () => {
    const { repo } = createTestRepository();

    const provider = repo.createXtream({
      name: "Xtream Account",
      serverUrl: "https://panel.example.test:8443",
      username: "my-user",
      password: "my-password"
    });

    expect(provider).toMatchObject({
      type: "xtream",
      name: "Xtream Account",
      source: "https://panel.example.test:8443",
      username: "my-user",
      password: "my-password",
      lastRefreshAt: null
    });
    expect(provider.id).toEqual(expect.any(String));
    expect(repo.get(provider.id)).toEqual(provider);
  });

  it("lists providers ordered by creation time ascending", () => {
    const { db, repo } = createTestRepository();

    const older = repo.createM3u({ name: "Older", source: "https://older.test/list.m3u", sourceKind: "url" });
    const newer = repo.createM3u({ name: "Newer", source: "https://newer.test/list.m3u", sourceKind: "url" });
    db.prepare("UPDATE providers SET created_at = ? WHERE id = ?").run("2026-05-26T10:00:00.000Z", newer.id);
    db.prepare("UPDATE providers SET created_at = ? WHERE id = ?").run("2026-05-26T09:00:00.000Z", older.id);

    expect(repo.list().map((provider) => provider.id)).toEqual([older.id, newer.id]);
  });

  it("gets providers by id and returns null for missing providers", () => {
    const { repo } = createTestRepository();
    const provider = repo.createM3u({
      name: "Main playlist",
      source: "https://example.test/playlist.m3u",
      sourceKind: "url"
    });

    expect(repo.get(provider.id)).toEqual(provider);
    expect(repo.get("missing")).toBeNull();
  });

  it("marks providers refreshed with refresh and update timestamps", () => {
    const { db, repo } = createTestRepository();
    const provider = repo.createM3u({
      name: "Main playlist",
      source: "https://example.test/playlist.m3u",
      sourceKind: "url"
    });
    db.prepare("UPDATE providers SET updated_at = ? WHERE id = ?").run("2026-05-26T09:00:00.000Z", provider.id);

    repo.markRefreshed(provider.id);

    const refreshed = repo.get(provider.id);
    expect(refreshed?.lastRefreshAt).toEqual(expect.any(String));
    expect(refreshed?.lastRefreshAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
    expect(refreshed?.updatedAt).toEqual(refreshed?.lastRefreshAt);
    expect(refreshed?.updatedAt).not.toBe("2026-05-26T09:00:00.000Z");
  });

  it("deletes a provider and its live catalog rows", () => {
    const { db, repo } = createTestRepository();
    const provider = repo.createM3u({
      name: "Main playlist",
      source: "https://example.test/playlist.m3u",
      sourceKind: "url"
    });
    db.prepare(`
      INSERT INTO live_channels (
        id, provider_id, name, logo_url, category, stream_json, epg_channel_id, last_seen_at, stale
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)
    `).run(
      `${provider.id}:live:news`,
      provider.id,
      "News",
      null,
      "News",
      JSON.stringify({ providerType: "m3u", url: "https://stream.test/news.m3u8" }),
      null,
      "2026-05-26T09:00:00.000Z"
    );
    db.prepare("INSERT INTO favorites (item_id, item_type, created_at) VALUES (?, 'live', ?)").run(
      `${provider.id}:live:news`,
      "2026-05-26T09:01:00.000Z"
    );
    db.prepare("INSERT INTO recently_watched (item_id, item_type, last_watched_at) VALUES (?, 'live', ?)").run(
      `${provider.id}:live:news`,
      "2026-05-26T09:02:00.000Z"
    );

    repo.delete(provider.id);

    expect(repo.get(provider.id)).toBeNull();
    expect(db.prepare("SELECT COUNT(*) AS count FROM live_channels WHERE provider_id = ?").get(provider.id)).toEqual({
      count: 0
    });
    expect(db.prepare("SELECT COUNT(*) AS count FROM favorites").get()).toEqual({ count: 0 });
    expect(db.prepare("SELECT COUNT(*) AS count FROM recently_watched").get()).toEqual({ count: 0 });
  });
});
