import crypto from "node:crypto";
import type {
  CreateM3uProviderInput,
  CreateXtreamProviderInput,
  Provider
} from "../../../src/shared/providers/types.js";
import type { SqliteDatabase } from "./database.js";

interface ProviderRow {
  id: string;
  type: "m3u" | "xtream";
  name: string;
  source: string;
  username: string | null;
  password: string | null;
  created_at: string;
  updated_at: string;
  last_refresh_at: string | null;
}

export function createProviderRepository(db: SqliteDatabase) {
  return {
    list(): Provider[] {
      const rows = db.prepare("SELECT * FROM providers ORDER BY created_at ASC").all() as ProviderRow[];
      return rows.map(toProvider);
    },
    createM3u(input: CreateM3uProviderInput): Provider {
      const now = new Date().toISOString();
      const provider: Provider = {
        id: crypto.randomUUID(),
        type: "m3u",
        name: input.name,
        source: input.source,
        username: null,
        password: null,
        createdAt: now,
        updatedAt: now,
        lastRefreshAt: null
      };

      db.prepare(`
        INSERT INTO providers (id, type, name, source, username, password, created_at, updated_at, last_refresh_at)
        VALUES (@id, @type, @name, @source, @username, @password, @createdAt, @updatedAt, @lastRefreshAt)
      `).run(provider);

      return provider;
    },
    createXtream(input: CreateXtreamProviderInput): Provider {
      const now = new Date().toISOString();
      const provider: Provider = {
        id: crypto.randomUUID(),
        type: "xtream",
        name: input.name,
        source: input.serverUrl,
        username: input.username,
        password: input.password,
        createdAt: now,
        updatedAt: now,
        lastRefreshAt: null
      };

      db.prepare(`
        INSERT INTO providers (id, type, name, source, username, password, created_at, updated_at, last_refresh_at)
        VALUES (@id, @type, @name, @source, @username, @password, @createdAt, @updatedAt, @lastRefreshAt)
      `).run(provider);

      return provider;
    },
    markRefreshed(providerId: string): void {
      const now = new Date().toISOString();
      db.prepare("UPDATE providers SET last_refresh_at = ?, updated_at = ? WHERE id = ?").run(now, now, providerId);
    },
    get(providerId: string): Provider | null {
      const row = db.prepare("SELECT * FROM providers WHERE id = ?").get(providerId) as ProviderRow | undefined;
      return row ? toProvider(row) : null;
    },
    delete(providerId: string): void {
      const transaction = db.transaction(() => {
        const liveChannelIds = db.prepare("SELECT id FROM live_channels WHERE provider_id = ?").all(providerId) as Array<{
          id: string;
        }>;
        const movieIds = db.prepare("SELECT id FROM movies WHERE provider_id = ?").all(providerId) as Array<{ id: string }>;
        const seriesIds = db.prepare("SELECT id FROM series WHERE provider_id = ?").all(providerId) as Array<{ id: string }>;
        const episodeIds = db.prepare("SELECT id FROM episodes WHERE provider_id = ?").all(providerId) as Array<{ id: string }>;

        for (const { id } of liveChannelIds) {
          deleteCatalogMetadata(id, "live");
        }
        for (const { id } of movieIds) {
          deleteCatalogMetadata(id, "movie");
        }
        for (const { id } of seriesIds) {
          deleteCatalogMetadata(id, "series");
        }
        for (const { id } of episodeIds) {
          deleteCatalogMetadata(id, "episode");
        }

        db.prepare("DELETE FROM live_channels WHERE provider_id = ?").run(providerId);
        db.prepare("DELETE FROM movies WHERE provider_id = ?").run(providerId);
        db.prepare("DELETE FROM series WHERE provider_id = ?").run(providerId);
        db.prepare("DELETE FROM episodes WHERE provider_id = ?").run(providerId);
        db.prepare("DELETE FROM providers WHERE id = ?").run(providerId);
      });

      transaction();
    }
  };

  function deleteCatalogMetadata(itemId: string, itemType: "live" | "movie" | "series" | "episode"): void {
    db.prepare("DELETE FROM favorites WHERE item_id = ? AND item_type = ?").run(itemId, itemType);
    db.prepare("DELETE FROM recently_watched WHERE item_id = ? AND item_type = ?").run(itemId, itemType);
  }
}

function toProvider(row: ProviderRow): Provider {
  return {
    id: row.id,
    type: row.type,
    name: row.name,
    source: row.source,
    username: row.username,
    password: row.password,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    lastRefreshAt: row.last_refresh_at
  };
}
