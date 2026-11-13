-- SQLite schema version 4, compatible with the Flutter catalog.
CREATE TABLE IF NOT EXISTS providers (
  id TEXT NOT NULL,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  source TEXT NOT NULL,
  source_kind TEXT,
  username TEXT,
  password TEXT,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  last_refresh_at INTEGER,
  auto_refresh_enabled INTEGER NOT NULL DEFAULT 1,
  auto_refresh_interval_minutes INTEGER NOT NULL DEFAULT 1440,
  is_enabled INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  CHECK (type IN ('m3u', 'xtream')),
  CHECK (source_kind IS NULL OR source_kind IN ('url', 'file')),
  CHECK (auto_refresh_interval_minutes BETWEEN 1 AND 10080)
);

CREATE TABLE IF NOT EXISTS provider_refresh_runs (
  id TEXT NOT NULL,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  started_at INTEGER NOT NULL DEFAULT 0,
  finished_at INTEGER,
  item_count INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  PRIMARY KEY (id),
  CHECK (status IN ('running', 'succeeded', 'failed')),
  CHECK (item_count >= 0)
);

CREATE TABLE IF NOT EXISTS categories (
  id TEXT NOT NULL,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL,
  external_id TEXT,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  item_count INTEGER NOT NULL DEFAULT 0,
  last_seen_at INTEGER NOT NULL DEFAULT 0,
  is_stale INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, content_type, id),
  UNIQUE (provider_id, content_type, normalized_name),
  CHECK (content_type IN ('live', 'movie', 'series')),
  CHECK (item_count >= 0)
);

CREATE TABLE IF NOT EXISTS catalog_items (
  id TEXT NOT NULL,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL,
  category_id TEXT,
  title TEXT NOT NULL,
  normalized_title TEXT NOT NULL,
  subtitle TEXT,
  description TEXT,
  artwork_url TEXT,
  stream_url TEXT,
  stream_json TEXT,
  external_id TEXT,
  year INTEGER,
  rating TEXT,
  duration_seconds INTEGER,
  epg_channel_id TEXT,
  container_extension TEXT,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  last_seen_at INTEGER NOT NULL DEFAULT 0,
  is_stale INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, content_type, id),
  CHECK (content_type IN ('live', 'movie', 'series')),
  CHECK (duration_seconds IS NULL OR duration_seconds >= 0)
);

CREATE TABLE IF NOT EXISTS series (
  id TEXT NOT NULL,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  catalog_item_id TEXT,
  external_id TEXT,
  title TEXT NOT NULL,
  normalized_title TEXT NOT NULL,
  overview TEXT,
  poster_url TEXT,
  backdrop_url TEXT,
  updated_at INTEGER NOT NULL DEFAULT 0,
  last_seen_at INTEGER NOT NULL DEFAULT 0,
  is_stale INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, id),
  UNIQUE (provider_id, catalog_item_id)
);

CREATE TABLE IF NOT EXISTS seasons (
  id TEXT NOT NULL,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  series_id TEXT NOT NULL,
  season_number INTEGER NOT NULL,
  title TEXT,
  overview TEXT,
  poster_url TEXT,
  updated_at INTEGER NOT NULL DEFAULT 0,
  last_seen_at INTEGER NOT NULL DEFAULT 0,
  is_stale INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, series_id, id),
  UNIQUE (provider_id, series_id, season_number)
);

CREATE TABLE IF NOT EXISTS episodes (
  id TEXT NOT NULL,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  series_id TEXT NOT NULL,
  season_id TEXT NOT NULL,
  season_number INTEGER NOT NULL,
  episode_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  normalized_title TEXT NOT NULL,
  description TEXT,
  artwork_url TEXT,
  stream_url TEXT,
  stream_json TEXT,
  external_id TEXT,
  duration_seconds INTEGER,
  created_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  last_seen_at INTEGER NOT NULL DEFAULT 0,
  is_stale INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, series_id, season_id, id),
  CHECK (season_number >= 0),
  CHECK (episode_number >= 0),
  CHECK (duration_seconds IS NULL OR duration_seconds >= 0)
);

CREATE TABLE IF NOT EXISTS epg_programs (
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  channel_id TEXT NOT NULL,
  start_at INTEGER NOT NULL,
  end_at INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT,
  imported_at INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, channel_id, start_at),
  CHECK (end_at > start_at)
);

CREATE TABLE IF NOT EXISTS favorite_items (
  catalog_key TEXT NOT NULL,
  item_id TEXT NOT NULL,
  item_type TEXT NOT NULL,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  series_id TEXT,
  season_id TEXT,
  created_at INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, item_type, catalog_key),
  CHECK (item_type IN ('live', 'movie', 'series', 'episode'))
);

CREATE TABLE IF NOT EXISTS favorite_categories (
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL,
  category_id TEXT NOT NULL,
  created_at INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, content_type, category_id),
  CHECK (content_type IN ('live', 'movie', 'series'))
);

CREATE TABLE IF NOT EXISTS category_order (
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL,
  category_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  updated_at INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, content_type, category_id),
  CHECK (content_type IN ('live', 'movie', 'series')),
  CHECK (sort_order >= 0)
);

CREATE TABLE IF NOT EXISTS watch_history (
  catalog_key TEXT NOT NULL,
  item_id TEXT NOT NULL,
  item_type TEXT NOT NULL,
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  subtitle TEXT,
  artwork_url TEXT,
  series_id TEXT,
  season_id TEXT,
  position_seconds INTEGER NOT NULL DEFAULT 0,
  duration_seconds INTEGER,
  completion_percentage REAL NOT NULL DEFAULT 0,
  completed INTEGER NOT NULL DEFAULT 0,
  last_watched_at INTEGER NOT NULL DEFAULT 0,
  watch_count INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (provider_id, item_type, catalog_key),
  CHECK (item_type IN ('live', 'movie', 'episode')),
  CHECK (position_seconds >= 0),
  CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
  CHECK (completion_percentage BETWEEN 0 AND 1),
  CHECK (watch_count >= 1)
);

CREATE TABLE IF NOT EXISTS playback_positions (
  provider_id TEXT NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
  catalog_key TEXT NOT NULL,
  item_id TEXT NOT NULL,
  item_type TEXT NOT NULL,
  series_id TEXT,
  season_id TEXT,
  position_seconds INTEGER NOT NULL DEFAULT 0,
  duration_seconds INTEGER,
  completion_percentage REAL NOT NULL DEFAULT 0,
  completed INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (provider_id, item_type, catalog_key),
  CHECK (item_type IN ('live', 'movie', 'episode')),
  CHECK (position_seconds >= 0),
  CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
  CHECK (completion_percentage BETWEEN 0 AND 1)
);

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (key)
);
PRAGMA user_version = 4;
CREATE INDEX IF NOT EXISTS idx_catalog_items_provider_content ON catalog_items(provider_id, content_type, is_stale);
CREATE INDEX IF NOT EXISTS idx_catalog_items_provider_category ON catalog_items(provider_id, content_type, category_id, is_stale);
CREATE INDEX IF NOT EXISTS idx_catalog_items_normalized_title ON catalog_items(normalized_title);
CREATE INDEX IF NOT EXISTS idx_categories_provider_content ON categories(provider_id, content_type, is_stale);
CREATE INDEX IF NOT EXISTS idx_favorite_items_lookup ON favorite_items(provider_id, item_type, catalog_key);
CREATE INDEX IF NOT EXISTS idx_watch_history_last_watched ON watch_history(last_watched_at DESC);
CREATE INDEX IF NOT EXISTS idx_playback_positions_lookup ON playback_positions(provider_id, item_type, catalog_key);
CREATE INDEX IF NOT EXISTS idx_series_provider_catalog_item ON series(provider_id, catalog_item_id, is_stale);
CREATE INDEX IF NOT EXISTS idx_series_provider_external ON series(provider_id, external_id, is_stale, id);
CREATE INDEX IF NOT EXISTS idx_episodes_series_season_episode ON episodes(provider_id, series_id, season_number, episode_number, is_stale);
CREATE INDEX IF NOT EXISTS idx_epg_programs_channel_time ON epg_programs(provider_id, channel_id, start_at, end_at);
