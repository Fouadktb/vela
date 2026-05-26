import type { LiveChannel } from "../../../src/shared/catalog/types.js";
import type { SqliteDatabase } from "./database.js";

interface LiveChannelRow {
  id: string;
  provider_id: string;
  name: string;
  logo_url: string | null;
  category: string;
  stream_json: string;
  epg_channel_id: string | null;
  last_seen_at: string;
  is_favorite: 0 | 1;
}

export function createCatalogRepository(db: SqliteDatabase) {
  return {
    upsertLiveChannels(channels: LiveChannel[]): void {
      const statement = db.prepare(`
        INSERT INTO live_channels (
          id, provider_id, name, logo_url, category, stream_json, epg_channel_id, last_seen_at, stale
        ) VALUES (
          @id, @providerId, @name, @logoUrl, @category, @streamJson, @epgChannelId, @lastSeenAt, 0
        )
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          logo_url = excluded.logo_url,
          category = excluded.category,
          stream_json = excluded.stream_json,
          epg_channel_id = excluded.epg_channel_id,
          last_seen_at = excluded.last_seen_at,
          stale = 0
      `);

      const transaction = db.transaction((items: LiveChannel[]) => {
        for (const item of items) {
          statement.run({
            id: item.id,
            providerId: item.providerId,
            name: item.name,
            logoUrl: item.logoUrl,
            category: item.category,
            streamJson: JSON.stringify(item.stream),
            epgChannelId: item.epgChannelId,
            lastSeenAt: item.lastSeenAt
          });
        }
      });

      transaction(channels);
    },
    listLiveChannels(query: string, category: string | null): LiveChannel[] {
      const normalizedQuery = `%${query.trim().toLowerCase()}%`;
      const rows = db.prepare(`
        SELECT
          live_channels.*,
          CASE WHEN favorites.item_id IS NULL THEN 0 ELSE 1 END AS is_favorite
        FROM live_channels
        LEFT JOIN favorites
          ON favorites.item_id = live_channels.id
          AND favorites.item_type = 'live'
        WHERE stale = 0
          AND lower(name) LIKE ?
          AND (? IS NULL OR category = ?)
        ORDER BY is_favorite DESC, name ASC
      `).all(normalizedQuery, category, category) as LiveChannelRow[];

      return rows.map(toLiveChannel);
    },
    getLiveChannel(itemId: string): LiveChannel | null {
      const row = db.prepare(`
        SELECT
          live_channels.*,
          CASE WHEN favorites.item_id IS NULL THEN 0 ELSE 1 END AS is_favorite
        FROM live_channels
        LEFT JOIN favorites
          ON favorites.item_id = live_channels.id
          AND favorites.item_type = 'live'
        WHERE live_channels.id = ?
      `).get(itemId) as LiveChannelRow | undefined;

      return row ? toLiveChannel(row) : null;
    },
    toggleFavorite(itemId: string, itemType: "live"): void {
      const existing = db.prepare("SELECT item_id FROM favorites WHERE item_id = ? AND item_type = ?").get(itemId, itemType);

      if (existing) {
        db.prepare("DELETE FROM favorites WHERE item_id = ? AND item_type = ?").run(itemId, itemType);
        return;
      }

      db.prepare("INSERT INTO favorites (item_id, item_type, created_at) VALUES (?, ?, ?)").run(
        itemId,
        itemType,
        new Date().toISOString()
      );
    },
    markRecentlyWatched(itemId: string, itemType: "live"): void {
      db.prepare(`
        INSERT INTO recently_watched (item_id, item_type, last_watched_at)
        VALUES (?, ?, ?)
        ON CONFLICT(item_id, item_type) DO UPDATE SET last_watched_at = excluded.last_watched_at
      `).run(itemId, itemType, new Date().toISOString());
    }
  };
}

function toLiveChannel(row: LiveChannelRow): LiveChannel {
  return {
    type: "live",
    id: row.id,
    providerId: row.provider_id,
    name: row.name,
    logoUrl: row.logo_url,
    category: row.category,
    stream: JSON.parse(row.stream_json) as LiveChannel["stream"],
    epgChannelId: row.epg_channel_id,
    lastSeenAt: row.last_seen_at,
    isFavorite: row.is_favorite === 1
  };
}
