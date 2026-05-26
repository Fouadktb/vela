import Database from "better-sqlite3";
import { createRequire } from "node:module";
import path from "node:path";

export type SqliteDatabase = Database.Database;

export function openAppDatabase(): SqliteDatabase {
  const require = createRequire(import.meta.url);
  const { app } = require("electron") as typeof import("electron");
  const dbPath = path.join(app.getPath("userData"), "iptv-player.sqlite");
  const db = new Database(dbPath);
  createSchema(db);
  return db;
}

export function createSchema(db: SqliteDatabase): void {
  db.exec(`
    PRAGMA journal_mode = WAL;

    CREATE TABLE IF NOT EXISTS providers (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      name TEXT NOT NULL,
      source TEXT NOT NULL,
      username TEXT,
      password TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      last_refresh_at TEXT
    );

    CREATE TABLE IF NOT EXISTS live_channels (
      id TEXT PRIMARY KEY,
      provider_id TEXT NOT NULL,
      name TEXT NOT NULL,
      logo_url TEXT,
      category TEXT NOT NULL,
      stream_json TEXT NOT NULL,
      epg_channel_id TEXT,
      last_seen_at TEXT NOT NULL,
      stale INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS favorites (
      item_id TEXT NOT NULL,
      item_type TEXT NOT NULL,
      created_at TEXT NOT NULL,
      PRIMARY KEY (item_id, item_type)
    );

    CREATE TABLE IF NOT EXISTS recently_watched (
      item_id TEXT NOT NULL,
      item_type TEXT NOT NULL,
      last_watched_at TEXT NOT NULL,
      PRIMARY KEY (item_id, item_type)
    );

    CREATE INDEX IF NOT EXISTS idx_live_channels_provider ON live_channels(provider_id);
    CREATE INDEX IF NOT EXISTS idx_live_channels_category ON live_channels(category);
    CREATE INDEX IF NOT EXISTS idx_live_channels_name ON live_channels(name);
  `);
}
