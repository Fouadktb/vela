use crate::{migration, models::*};
use anyhow::{Context, Result, ensure};
use rusqlite::{Connection, OptionalExtension, Row, params, params_from_iter, types::Value};
use std::{
    collections::{BTreeMap, HashSet},
    path::{Path, PathBuf},
    time::Duration,
};

pub struct Store {
    connection: Connection,
    path: PathBuf,
    pub migrated_from: Option<PathBuf>,
}

impl Store {
    pub fn open_default() -> Result<Self> {
        let path = migration::default_database_path()?;
        let candidates = match std::env::var_os("VELA_LEGACY_DATABASE") {
            Some(source) => {
                let source = PathBuf::from(source);
                ensure!(source.is_file(), "Explicit legacy catalog does not exist");
                vec![source]
            }
            None => migration::legacy_candidates(),
        };
        let migrated_from = migration::migrate_if_needed(&path, &candidates)?;
        let mut store = Self::open(path)?;
        store.migrated_from = migrated_from;
        Ok(store)
    }

    /// Adopt a user-selected legacy catalog without modifying process-global
    /// environment or replacing an already-created native catalog.
    pub fn open_with_legacy(source: &Path) -> Result<Self> {
        Self::open_with_legacy_at(&migration::default_database_path()?, source)
    }

    /// Explicit destination variant for portable data directories and tests.
    pub fn open_with_legacy_at(destination: &Path, source: &Path) -> Result<Self> {
        ensure!(source.is_file(), "Selected legacy catalog does not exist");
        let migrated_from = migration::migrate_if_needed(destination, &[source.to_owned()])?;
        let mut store = Self::open(destination)?;
        store.migrated_from = migrated_from;
        Ok(store)
    }

    pub fn open(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref();
        if let Some(parent) = path.parent().filter(|p| !p.as_os_str().is_empty()) {
            std::fs::create_dir_all(parent)?;
        }
        // Inspect before making any change; future schemas must never be reset.
        if path.exists() {
            migration::validate(&migration::readonly(path)?)?;
        }
        let connection = Connection::open(path)?;
        if path != Path::new(":memory:") {
            migration::restrict_permissions(path)?;
        }
        connection.busy_timeout(Duration::from_secs(10))?;
        let version: i64 = connection.pragma_query_value(None, "user_version", |r| r.get(0))?;
        if version == 0 {
            connection.execute_batch(migration::SCHEMA)?;
        } else if version < migration::SCHEMA_VERSION {
            migration::upgrade(&connection, version)?;
        }
        connection.execute_batch(
            "PRAGMA foreign_keys = ON; PRAGMA journal_mode = WAL; PRAGMA synchronous = NORMAL;",
        )?;
        // Index-only maintenance also applies to adopted/existing schema-v4
        // catalogs; it does not require a table schema/version migration.
        connection.execute_batch(SERIES_EXTERNAL_INDEX)?;
        connection.execute_batch("CREATE INDEX IF NOT EXISTS idx_playback_positions_series ON playback_positions(provider_id,item_type,series_id,updated_at DESC)")?;
        Ok(Self {
            connection,
            path: path.to_owned(),
            migrated_from: None,
        })
    }

    pub fn path(&self) -> &Path {
        &self.path
    }
    pub fn backup_to(&self, destination: &Path) -> Result<()> {
        ensure!(
            !destination.exists(),
            "Backup destination already exists; choose a new file"
        );
        let parent = destination
            .parent()
            .filter(|p| !p.as_os_str().is_empty())
            .unwrap_or(Path::new("."));
        std::fs::create_dir_all(parent)?;
        let staged = parent.join(format!(".vela-backup-{}.sqlite", uuid::Uuid::new_v4()));
        let result = (|| -> Result<()> {
            let mut backup = Connection::open(&staged)?;
            migration::restrict_permissions(&staged)?;
            rusqlite::backup::Backup::new(&self.connection, &mut backup)?.run_to_completion(
                128,
                Duration::from_millis(5),
                None,
            )?;
            migration::validate(&backup)?;
            backup.close().map_err(|(_, error)| error)?;
            // FlushFileBuffers on Windows requires a writable handle. Reopen
            // the finished copy without truncating or modifying its contents.
            std::fs::OpenOptions::new()
                .write(true)
                .open(&staged)?
                .sync_all()?;
            std::fs::hard_link(&staged, destination)?;
            Ok(())
        })();
        let _ = std::fs::remove_file(&staged);
        result
    }
    pub fn providers(&self) -> Result<Vec<Provider>> {
        collect(
            &self.connection,
            "SELECT * FROM providers ORDER BY name COLLATE NOCASE, id",
            [],
            provider_row,
        )
    }
    pub fn provider(&self, id: &str) -> Result<Option<Provider>> {
        Ok(self
            .connection
            .query_row("SELECT * FROM providers WHERE id=?", [id], provider_row)
            .optional()?)
    }
    pub fn upsert_provider(&self, p: &Provider) -> Result<()> {
        ensure!(
            !p.id.trim().is_empty() && !p.name.trim().is_empty() && !p.source.trim().is_empty(),
            "Provider ID, name and source are required"
        );
        ensure!(
            ["m3u", "xtream"].contains(&p.kind.as_str()),
            "Unsupported provider type"
        );
        ensure!(
            (1..=10080).contains(&p.auto_refresh_interval_minutes),
            "Invalid refresh interval"
        );
        let now = now_ms();
        self.connection.execute("INSERT INTO providers (id,type,name,source,source_kind,username,password,created_at,updated_at,last_refresh_at,auto_refresh_enabled,auto_refresh_interval_minutes,is_enabled)
            VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?8,?9,?10,?11,?12)
            ON CONFLICT(id) DO UPDATE SET type=excluded.type,name=excluded.name,source=excluded.source,source_kind=excluded.source_kind,username=excluded.username,password=excluded.password,updated_at=excluded.updated_at,auto_refresh_enabled=excluded.auto_refresh_enabled,auto_refresh_interval_minutes=excluded.auto_refresh_interval_minutes,is_enabled=excluded.is_enabled",
            params![p.id,p.kind,p.name.trim(),p.source.trim(),p.source_kind,p.username,p.password,now,p.last_refresh_at,p.auto_refresh_enabled,p.auto_refresh_interval_minutes,p.is_enabled])?;
        Ok(())
    }
    pub fn delete_provider(&self, id: &str) -> Result<()> {
        self.connection
            .execute("DELETE FROM providers WHERE id=?", [id])?;
        Ok(())
    }

    pub fn record_refresh_start(&self, provider: &str) -> Result<String> {
        let id = uuid::Uuid::new_v4().to_string();
        self.connection.execute("INSERT INTO provider_refresh_runs(id,provider_id,status,started_at) VALUES(?,?,'running',?)",params![id,provider,now_ms()])?;
        Ok(id)
    }

    /// Caller-provided error messages must already be redacted for display.
    pub fn finish_refresh(&self, run_id: &str, item_count: i64, error: Option<&str>) -> Result<()> {
        ensure!(item_count >= 0, "Refresh item count cannot be negative");
        let status = if error.is_some() {
            "failed"
        } else {
            "succeeded"
        };
        let updated=self.connection.execute("UPDATE provider_refresh_runs SET status=?,finished_at=?,item_count=?,error_message=? WHERE id=? AND status='running'",params![status,now_ms(),item_count,error,run_id])?;
        ensure!(
            updated == 1,
            "Refresh run does not exist or has already finished"
        );
        Ok(())
    }

    pub fn catalog(&self, query: &CatalogQuery) -> Result<CatalogPage> {
        let mut conditions = vec!["i.is_stale=0".to_owned()];
        let mut values: Vec<Value> = Vec::new();
        for (column, value) in [
            ("i.provider_id", &query.provider_id),
            ("i.content_type", &query.content_type),
            ("i.category_id", &query.category_id),
        ] {
            if let Some(value) = value {
                conditions.push(format!("{column}=?"));
                values.push(value.clone().into());
            }
        }
        if query.favorites_only {
            conditions.push("EXISTS (SELECT 1 FROM favorite_items f WHERE f.provider_id=i.provider_id AND f.item_type=i.content_type AND f.catalog_key=i.id)".to_owned());
        }
        let normalized = normalize(&query.search);
        if !normalized.is_empty() {
            conditions.push(r"(i.normalized_title LIKE ? ESCAPE '\' OR lower(COALESCE(i.subtitle,'')) LIKE ? ESCAPE '\')".to_owned());
            let pattern = format!(
                "%{}%",
                normalized
                    .replace('\\', "\\\\")
                    .replace('%', "\\%")
                    .replace('_', "\\_")
            );
            values.push(pattern.clone().into());
            values.push(pattern.into());
        }
        let predicate = conditions.join(" AND ");
        let total: i64 = self.connection.query_row(
            &format!("SELECT COUNT(*) FROM catalog_items i WHERE {predicate}"),
            params_from_iter(&values),
            |r| r.get(0),
        )?;
        let limit = if query.limit == 0 {
            100
        } else {
            query.limit.min(500)
        };
        values.push((limit as i64).into());
        values.push((query.offset.min(i64::MAX as usize) as i64).into());
        let order = if query.latest_first {
            "i.created_at DESC,i.updated_at DESC,i.id"
        } else {
            "i.normalized_title,i.provider_id,i.content_type,i.id"
        };
        let sql = format!("SELECT i.*, c.name AS category_name, EXISTS(SELECT 1 FROM favorite_items f WHERE f.provider_id=i.provider_id AND f.item_type=i.content_type AND f.catalog_key=i.id) AS is_favorite
            FROM catalog_items i LEFT JOIN categories c ON c.provider_id=i.provider_id AND c.content_type=i.content_type AND c.id=i.category_id
            WHERE {predicate} ORDER BY {order} LIMIT ? OFFSET ?");
        let items = collect(&self.connection, &sql, params_from_iter(&values), item_row)?;
        Ok(CatalogPage {
            items,
            total: total as usize,
        })
    }
    pub fn item(&self, provider: &str, kind: &str, id: &str) -> Result<Option<CatalogItem>> {
        Ok(self.connection.query_row("SELECT i.*,c.name category_name, EXISTS(SELECT 1 FROM favorite_items f WHERE f.provider_id=i.provider_id AND f.item_type=i.content_type AND f.catalog_key=i.id) is_favorite FROM catalog_items i LEFT JOIN categories c ON c.provider_id=i.provider_id AND c.content_type=i.content_type AND c.id=i.category_id WHERE i.provider_id=? AND i.content_type=? AND i.id=? AND i.is_stale=0", params![provider,kind,id], item_row).optional()?)
    }
    pub fn update_item_metadata(&self, item: &CatalogItem) -> Result<()> {
        ensure!(
            item.duration_seconds.is_none_or(|d| d >= 0),
            "Invalid media duration"
        );
        let clean = |value: &Option<String>| {
            value
                .as_deref()
                .map(str::trim)
                .filter(|s| !s.is_empty())
                .map(str::to_owned)
        };
        let updated=self.connection.execute("UPDATE catalog_items SET description=COALESCE(?1,description),artwork_url=COALESCE(?2,artwork_url),year=COALESCE(?3,year),rating=COALESCE(?4,rating),duration_seconds=COALESCE(?5,duration_seconds),updated_at=?6 WHERE provider_id=?7 AND content_type=?8 AND id=?9 AND is_stale=0",params![clean(&item.description),clean(&item.artwork_url),item.year,clean(&item.rating),item.duration_seconds,now_ms(),item.provider_id,item.content_type,item.id])?;
        ensure!(updated == 1, "Metadata item is outside the active catalog");
        Ok(())
    }
    pub fn categories(&self, provider: Option<&str>, kind: &str) -> Result<Vec<Category>> {
        collect(
            &self.connection,
            "SELECT c.*, o.sort_order, f.category_id IS NOT NULL AS is_favorite FROM categories c LEFT JOIN category_order o ON o.provider_id=c.provider_id AND o.content_type=c.content_type AND o.category_id=c.id LEFT JOIN favorite_categories f ON f.provider_id=c.provider_id AND f.content_type=c.content_type AND f.category_id=c.id WHERE c.content_type=?1 AND c.is_stale=0 AND (?2 IS NULL OR c.provider_id=?2) ORDER BY o.sort_order IS NULL,o.sort_order,f.category_id IS NULL,c.normalized_name,c.provider_id,c.id",
            params![kind, provider],
            |r| {
                Ok(Category {
                    id: r.get("id")?,
                    provider_id: r.get("provider_id")?,
                    content_type: r.get("content_type")?,
                    name: r.get("name")?,
                    external_id: r.get("external_id")?,
                    item_count: r.get("item_count")?,
                    is_favorite: r.get("is_favorite")?,
                    sort_order: r.get("sort_order")?,
                })
            },
        )
    }
    pub fn toggle_favorite(&self, item: &CatalogItem) -> Result<bool> {
        ensure!(
            self.item(&item.provider_id, &item.content_type, &item.id)?
                .is_some(),
            "Favorite item is outside the active catalog"
        );
        let tx = self.connection.unchecked_transaction()?;
        let removed = tx.execute(
            "DELETE FROM favorite_items WHERE provider_id=? AND item_type=? AND catalog_key=?",
            params![item.provider_id, item.content_type, item.id],
        )?;
        if removed == 0 {
            tx.execute("INSERT INTO favorite_items(provider_id,item_type,catalog_key,item_id,created_at) VALUES(?,?,?,?,?)", params![item.provider_id,item.content_type,item.id,item.id,now_ms()])?;
        }
        tx.commit()?;
        Ok(removed == 0)
    }
    pub fn toggle_category_favorite(
        &self,
        provider: &str,
        kind: &str,
        category: &str,
    ) -> Result<bool> {
        let tx = self.connection.unchecked_transaction()?;
        ensure!(tx.query_row("SELECT EXISTS(SELECT 1 FROM categories WHERE provider_id=? AND content_type=? AND id=? AND is_stale=0)", params![provider,kind,category], |r| r.get::<_,bool>(0))?, "Unknown category");
        let removed = tx.execute("DELETE FROM favorite_categories WHERE provider_id=? AND content_type=? AND category_id=?", params![provider,kind,category])?;
        if removed == 0 {
            tx.execute("INSERT INTO favorite_categories(provider_id,content_type,category_id,created_at) VALUES(?,?,?,?)", params![provider,kind,category,now_ms()])?;
        }
        tx.commit()?;
        Ok(removed == 0)
    }
    pub fn reorder_categories(&self, provider: &str, kind: &str, ids: &[String]) -> Result<()> {
        let tx = self.connection.unchecked_transaction()?;
        tx.execute(
            "DELETE FROM category_order WHERE provider_id=? AND content_type=?",
            params![provider, kind],
        )?;
        for (index, id) in ids.iter().enumerate() {
            ensure!(tx.query_row("SELECT EXISTS(SELECT 1 FROM categories WHERE provider_id=? AND content_type=? AND id=? AND is_stale=0)",params![provider,kind,id],|r|r.get::<_,bool>(0))?,"Unknown category in order");
            tx.execute("INSERT INTO category_order(provider_id,content_type,category_id,sort_order,updated_at) VALUES(?,?,?,?,?)",params![provider,kind,id,index as i64,now_ms()])?;
        }
        tx.commit()?;
        Ok(())
    }

    pub fn settings(&self) -> Result<BTreeMap<String, String>> {
        Ok(collect(
            &self.connection,
            "SELECT key,value FROM app_settings",
            [],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )?
        .into_iter()
        .collect())
    }
    pub fn setting(&self, key: &str) -> Result<Option<String>> {
        Ok(self
            .connection
            .query_row("SELECT value FROM app_settings WHERE key=?", [key], |r| {
                r.get(0)
            })
            .optional()?)
    }
    pub fn set_setting(&self, key: &str, value: &str) -> Result<()> {
        self.connection.execute("INSERT INTO app_settings(key,value,updated_at) VALUES(?,?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value,updated_at=excluded.updated_at",params![key,value,now_ms()])?;
        Ok(())
    }
    pub fn volume(&self) -> Result<VolumePreferences> {
        let mut volume: VolumePreferences = self
            .setting("playback_output_volume")?
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();
        if !volume.volume.is_finite() {
            volume.volume = 100.0;
        }
        volume.volume = volume.volume.clamp(0.0, 100.0);
        if !volume.last_audible_volume.is_finite() || volume.last_audible_volume <= 0.0 {
            volume.last_audible_volume = if volume.volume > 0.0 {
                volume.volume
            } else {
                100.0
            };
        }
        volume.last_audible_volume = volume.last_audible_volume.clamp(0.0, 100.0);
        Ok(volume)
    }
    pub fn save_volume(&self, volume: VolumePreferences) -> Result<()> {
        ensure!(
            volume.volume.is_finite() && volume.last_audible_volume.is_finite(),
            "Volume must be finite"
        );
        ensure!(
            (0.0..=100.0).contains(&volume.volume)
                && (0.0..=100.0).contains(&volume.last_audible_volume)
                && volume.last_audible_volume > 0.0,
            "Volume is outside the supported range"
        );
        self.set_setting("playback_output_volume", &serde_json::to_string(&volume)?)
    }

    pub fn save_progress(&self, progress: &PlaybackProgress) -> Result<()> {
        ensure!(
            ["live", "movie", "episode"].contains(&progress.item_type.as_str()),
            "Invalid playable content type"
        );
        ensure!(
            progress.position_seconds >= 0 && progress.duration_seconds.is_none_or(|d| d >= 0),
            "Invalid playback timeline"
        );
        let key = catalog_key(
            &progress.item_type,
            &progress.item_id,
            progress.series_id.as_deref(),
            progress.season_id.as_deref(),
        )?;
        let completion = if progress.completed {
            1.0
        } else if progress.completion_percentage.is_finite() {
            progress.completion_percentage.clamp(0.0, 1.0)
        } else {
            0.0
        };
        let watched = if progress.last_watched_at > 0 {
            progress.last_watched_at
        } else {
            now_ms()
        };
        let tx = self.connection.unchecked_transaction()?;
        tx.execute("INSERT INTO watch_history(catalog_key,item_id,item_type,provider_id,title,subtitle,artwork_url,series_id,season_id,position_seconds,duration_seconds,completion_percentage,completed,last_watched_at,watch_count) VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15) ON CONFLICT(provider_id,item_type,catalog_key) DO UPDATE SET title=excluded.title,subtitle=excluded.subtitle,artwork_url=excluded.artwork_url,position_seconds=excluded.position_seconds,duration_seconds=excluded.duration_seconds,completion_percentage=excluded.completion_percentage,completed=excluded.completed,last_watched_at=excluded.last_watched_at,watch_count=MAX(watch_history.watch_count,excluded.watch_count)",params![key,progress.item_id,progress.item_type,progress.provider_id,progress.title,progress.subtitle,progress.artwork_url,progress.series_id,progress.season_id,progress.position_seconds,progress.duration_seconds,completion,progress.completed,watched,progress.watch_count.max(1)])?;
        tx.execute("INSERT INTO playback_positions(provider_id,catalog_key,item_id,item_type,series_id,season_id,position_seconds,duration_seconds,completion_percentage,completed,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(provider_id,item_type,catalog_key) DO UPDATE SET position_seconds=excluded.position_seconds,duration_seconds=excluded.duration_seconds,completion_percentage=excluded.completion_percentage,completed=excluded.completed,updated_at=excluded.updated_at",params![progress.provider_id,key,progress.item_id,progress.item_type,progress.series_id,progress.season_id,progress.position_seconds,progress.duration_seconds,completion,progress.completed,watched])?;
        tx.commit()?;
        Ok(())
    }
    pub fn recent_history(&self, limit: usize) -> Result<Vec<PlaybackProgress>> {
        collect(
            &self.connection,
            "SELECT * FROM watch_history ORDER BY last_watched_at DESC LIMIT ?",
            [limit.min(1000) as i64],
            progress_row,
        )
    }
    pub fn resume(
        &self,
        provider: &str,
        kind: &str,
        id: &str,
        series: Option<&str>,
        season: Option<&str>,
    ) -> Result<Option<PlaybackProgress>> {
        let key = catalog_key(kind, id, series, season)?;
        Ok(self.connection.query_row("SELECT p.provider_id,p.catalog_key,p.item_id,p.item_type,COALESCE(h.title,c.title,p.item_id) AS title,h.subtitle,h.artwork_url,p.series_id,p.season_id,p.position_seconds,p.duration_seconds,p.completion_percentage,p.completed,p.updated_at AS last_watched_at,COALESCE(h.watch_count,1) AS watch_count FROM playback_positions p LEFT JOIN watch_history h ON p.provider_id=h.provider_id AND p.item_type=h.item_type AND p.catalog_key=h.catalog_key LEFT JOIN catalog_items c ON c.provider_id=p.provider_id AND c.content_type=p.item_type AND c.id=p.item_id WHERE p.provider_id=? AND p.item_type=? AND p.catalog_key=? AND p.completed=0 AND p.position_seconds>0",params![provider,kind,key],progress_row).optional()?)
    }
    pub fn clear_provider_history(&self, provider: Option<&str>) -> Result<()> {
        let tx = self.connection.unchecked_transaction()?;
        for table in ["watch_history", "playback_positions"] {
            tx.execute(
                &format!("DELETE FROM {table} WHERE (?1 IS NULL OR provider_id=?1)"),
                [provider],
            )?;
        }
        tx.commit()?;
        Ok(())
    }

    pub fn clear_history(&self) -> Result<()> {
        self.clear_provider_history(None)
    }

    /// Complete, authoritative detail-page progress, including positions older
    /// than the bounded Home/Recent history lists and rows without history.
    pub fn detail_positions(
        &self,
        provider: &str,
        kind: &str,
        id: &str,
    ) -> Result<Vec<PlaybackProgress>> {
        ensure!(
            ["movie", "series", "live"].contains(&kind),
            "Invalid detail content type"
        );
        let playable_kind = if kind == "series" { "episode" } else { kind };
        let scope = if kind == "series" {
            "p.series_id=?3"
        } else {
            "p.item_id=?3"
        };
        collect(
            &self.connection,
            &format!(
                "SELECT p.provider_id,p.catalog_key,p.item_id,p.item_type,COALESCE(h.title,i.title,e.title,p.item_id) AS title,h.subtitle,COALESCE(h.artwork_url,i.artwork_url,e.artwork_url) AS artwork_url,p.series_id,p.season_id,p.position_seconds,p.duration_seconds,p.completion_percentage,p.completed,p.updated_at AS last_watched_at,COALESCE(h.watch_count,1) AS watch_count FROM playback_positions p LEFT JOIN watch_history h ON h.provider_id=p.provider_id AND h.item_type=p.item_type AND h.catalog_key=p.catalog_key LEFT JOIN catalog_items i ON i.provider_id=p.provider_id AND i.content_type=p.item_type AND i.id=p.item_id LEFT JOIN episodes e ON e.provider_id=p.provider_id AND e.series_id=p.series_id AND e.season_id=p.season_id AND e.id=p.item_id WHERE p.provider_id=?1 AND p.item_type=?2 AND {scope} ORDER BY p.updated_at DESC,p.catalog_key"
            ),
            params![provider, playable_kind, id],
            progress_row,
        )
    }

    pub fn replace_catalog(&self, snapshot: &CatalogSnapshot) -> Result<()> {
        ensure!(
            self.provider(&snapshot.provider_id)?.is_some(),
            "Import provider does not exist"
        );
        let provider = &snapshot.provider_id;
        for id in snapshot
            .categories
            .iter()
            .map(|i| &i.provider_id)
            .chain(snapshot.items.iter().map(|i| &i.provider_id))
            .chain(snapshot.series.iter().map(|i| &i.provider_id))
            .chain(snapshot.seasons.iter().map(|i| &i.provider_id))
            .chain(snapshot.episodes.iter().map(|i| &i.provider_id))
            .chain(snapshot.epg.iter().map(|i| &i.provider_id))
        {
            ensure!(
                id == provider,
                "Import contains records outside its provider scope"
            );
        }
        let now = now_ms();
        let tx = self.connection.unchecked_transaction()?;
        for table in ["categories", "catalog_items", "series"] {
            tx.execute(
                &format!("UPDATE {table} SET is_stale=1 WHERE provider_id=?"),
                [provider],
            )?;
        }
        let mut categories: BTreeMap<(String, String), Category> = BTreeMap::new();
        for category in &snapshot.categories {
            ensure!(!category.name.trim().is_empty(), "Empty category name");
            categories.insert(
                (category.content_type.clone(), normalize(&category.name)),
                category.clone(),
            );
        }
        let mut category_counts: BTreeMap<(String, String), i64> = BTreeMap::new();
        for item in &snapshot.items {
            if let Some(name) = item
                .category_name
                .as_deref()
                .filter(|s| !s.trim().is_empty())
            {
                let category = categories
                    .entry((item.content_type.clone(), normalize(name)))
                    .or_insert_with(|| Category {
                        provider_id: provider.clone(),
                        content_type: item.content_type.clone(),
                        name: name.trim().to_owned(),
                        ..Default::default()
                    });
                let _ = category;
                *category_counts
                    .entry((item.content_type.clone(), normalize(name)))
                    .or_default() += 1;
            }
        }
        for category in categories.values() {
            let id = category_id(provider, &category.content_type, &category.name);
            tx.execute("INSERT INTO categories(id,provider_id,content_type,external_id,name,normalized_name,item_count,last_seen_at,is_stale) VALUES(?,?,?,?,?,?,?,?,0) ON CONFLICT(provider_id,content_type,id) DO UPDATE SET external_id=excluded.external_id,name=excluded.name,normalized_name=excluded.normalized_name,item_count=excluded.item_count,last_seen_at=excluded.last_seen_at,is_stale=0",params![id,provider,category.content_type,category.external_id,category.name.trim(),normalize(&category.name),category_counts.get(&(category.content_type.clone(),normalize(&category.name))).copied().unwrap_or(category.item_count),now])?;
        }
        for item in &snapshot.items {
            upsert_item(&tx, item, now)?;
        }
        for series in &snapshot.series {
            upsert_series(&tx, series, now)?;
        }
        // Every series catalog entry must have a resolvable metadata row.
        let series_ids: HashSet<&str> = snapshot
            .series
            .iter()
            .flat_map(|s| std::iter::once(s.id.as_str()).chain(s.catalog_item_id.as_deref()))
            .collect();
        for item in snapshot.items.iter().filter(|i| i.content_type == "series") {
            if !series_ids.contains(item.id.as_str()) {
                upsert_series(
                    &tx,
                    &Series {
                        id: item.id.clone(),
                        provider_id: provider.clone(),
                        catalog_item_id: Some(item.id.clone()),
                        title: item.title.clone(),
                        overview: item.description.clone(),
                        poster_url: item.artwork_url.clone(),
                        external_id: item.external_id.clone(),
                        ..Default::default()
                    },
                    now,
                )?;
            }
        }
        for table in ["seasons", "episodes"] {
            // Rows belonging to removed series become stale; surviving caches stay active.
            tx.execute(&format!("UPDATE {table} SET is_stale=CASE WHEN EXISTS(SELECT 1 FROM series s WHERE s.provider_id={table}.provider_id AND s.id={table}.series_id AND s.is_stale=0) THEN is_stale ELSE 1 END WHERE provider_id=?"),[provider])?;
            for series in &snapshot.refreshed_episode_series_ids {
                tx.execute(
                    &format!("UPDATE {table} SET is_stale=1 WHERE provider_id=? AND series_id=?"),
                    params![provider, series],
                )?;
            }
        }
        for season in &snapshot.seasons {
            upsert_season(&tx, season, now)?;
        }
        for episode in &snapshot.episodes {
            upsert_episode(&tx, episode, now)?;
        }
        if !snapshot.epg.is_empty() {
            replace_epg_on(&tx, provider, &snapshot.epg, now)?;
        }
        tx.execute(
            "UPDATE providers SET last_refresh_at=?,updated_at=? WHERE id=?",
            params![now, now, provider],
        )?;
        tx.commit()?;
        Ok(())
    }
    pub fn replace_series_details(&self, details: &SeriesDetails) -> Result<()> {
        let provider = &details.series.provider_id;
        let canonical = resolve_series(&self.connection, provider, &details.series.id)?;
        for season in &details.seasons {
            ensure!(
                &season.provider_id == provider
                    && (season.series_id == details.series.id || season.series_id == canonical),
                "Season is outside series scope"
            );
        }
        for episode in &details.episodes {
            ensure!(
                &episode.provider_id == provider
                    && (episode.series_id == details.series.id || episode.series_id == canonical),
                "Episode is outside series scope"
            );
        }
        let tx = self.connection.unchecked_transaction()?;
        let now = now_ms();
        let mut series = details.series.clone();
        series.id = canonical.clone();
        if series.catalog_item_id.is_none() {
            series.catalog_item_id = Some(canonical.clone());
        }
        upsert_series(&tx, &series, now)?;
        tx.execute("UPDATE catalog_items SET description=COALESCE(?,description),artwork_url=COALESCE(?,artwork_url),updated_at=? WHERE provider_id=? AND content_type='series' AND id=?",params![series.overview,series.poster_url,now,provider,canonical])?;
        for table in ["seasons", "episodes"] {
            tx.execute(
                &format!("UPDATE {table} SET is_stale=1 WHERE provider_id=? AND series_id=?"),
                params![provider, canonical],
            )?;
        }
        for season in &details.seasons {
            let mut s = season.clone();
            s.series_id = canonical.clone();
            upsert_season(&tx, &s, now)?;
        }
        for episode in &details.episodes {
            let mut e = episode.clone();
            e.series_id = canonical.clone();
            upsert_episode(&tx, &e, now)?;
        }
        tx.commit()?;
        Ok(())
    }
    pub fn series_details(&self, provider: &str, series_id: &str) -> Result<Option<SeriesDetails>> {
        let series=self.connection.query_row("SELECT * FROM series WHERE provider_id=?1 AND (id=?2 OR catalog_item_id=?2 OR external_id=?2) AND is_stale=0 LIMIT 1",params![provider,series_id],series_row).optional()?;
        let Some(series) = series else {
            return Ok(None);
        };
        let seasons = collect(
            &self.connection,
            "SELECT * FROM seasons WHERE provider_id=? AND series_id=? AND is_stale=0 ORDER BY season_number",
            params![provider, series.id],
            season_row,
        )?;
        let episodes = collect(
            &self.connection,
            "SELECT * FROM episodes WHERE provider_id=? AND series_id=? AND is_stale=0 ORDER BY season_number,episode_number,id",
            params![provider, series.id],
            episode_row,
        )?;
        Ok(Some(SeriesDetails {
            series,
            seasons,
            episodes,
        }))
    }
    pub fn replace_epg(&self, provider: &str, programs: &[EpgProgram]) -> Result<()> {
        let tx = self.connection.unchecked_transaction()?;
        replace_epg_on(&tx, provider, programs, now_ms())?;
        tx.commit()?;
        Ok(())
    }
    pub fn episodes(&self, provider: &str, series: &str) -> Result<Vec<Episode>> {
        Ok(self
            .series_details(provider, series)?
            .map(|d| d.episodes)
            .unwrap_or_default())
    }
    pub fn epg(
        &self,
        provider: &str,
        channels: &[String],
        from: i64,
        to: i64,
    ) -> Result<Vec<EpgProgram>> {
        if channels.is_empty() {
            return Ok(Vec::new());
        }
        ensure!(channels.len() <= 500, "Guide request exceeds 500 channels");
        let mut values = vec![
            Value::Text(provider.to_owned()),
            Value::Integer(from),
            Value::Integer(to),
        ];
        for channel in channels {
            values.push(channel.clone().into());
        }
        let placeholders = vec!["?"; channels.len()].join(",");
        collect(
            &self.connection,
            &format!(
                "SELECT * FROM epg_programs WHERE provider_id=? AND end_at>? AND start_at<? AND channel_id IN ({placeholders}) ORDER BY start_at"
            ),
            params_from_iter(&values),
            |r| {
                Ok(EpgProgram {
                    provider_id: r.get("provider_id")?,
                    channel_id: r.get("channel_id")?,
                    start_at: r.get("start_at")?,
                    end_at: r.get("end_at")?,
                    title: r.get("title")?,
                    description: r.get("description")?,
                    category: r.get("category")?,
                })
            },
        )
    }
    pub fn clear_catalog_cache(&self) -> Result<()> {
        let tx = self.connection.unchecked_transaction()?;
        for table in [
            "provider_refresh_runs",
            "epg_programs",
            "episodes",
            "seasons",
            "series",
            "catalog_items",
            "categories",
        ] {
            tx.execute(&format!("DELETE FROM {table}"), [])?;
        }
        tx.execute("UPDATE providers SET last_refresh_at=NULL", [])?;
        tx.commit()?;
        Ok(())
    }
    pub fn reset_app_data(&self) -> Result<()> {
        let tx = self.connection.unchecked_transaction()?;
        tx.execute("DELETE FROM providers", [])?;
        tx.execute("DELETE FROM app_settings", [])?;
        tx.commit()?;
        Ok(())
    }
    pub fn integrity_check(&self) -> Result<()> {
        migration::validate(&self.connection)?;
        Ok(())
    }
}

fn now_ms() -> i64 {
    chrono::Utc::now().timestamp_millis()
}
fn normalize(text: &str) -> String {
    text.trim().to_lowercase()
}
/// Dart Uri.encodeComponent compatibility (its unescaped set includes !'()*).
pub fn encode_component(text: &str) -> String {
    let mut out = String::new();
    for byte in text.bytes() {
        if byte.is_ascii_alphanumeric() || b"-_.!~*'()".contains(&byte) {
            out.push(byte as char)
        } else {
            use std::fmt::Write;
            write!(&mut out, "%{byte:02X}").expect("writing to String");
        }
    }
    out
}
pub fn category_id(provider: &str, kind: &str, name: &str) -> String {
    format!("{provider}:{kind}:{}", encode_component(&normalize(name)))
}
pub fn catalog_key(
    kind: &str,
    id: &str,
    series: Option<&str>,
    season: Option<&str>,
) -> Result<String> {
    if kind != "episode" {
        return Ok(id.to_owned());
    }
    let series = series
        .filter(|s| !s.trim().is_empty())
        .context("Episode requires a series scope")?;
    let season = season
        .filter(|s| !s.trim().is_empty())
        .context("Episode requires a season scope")?;
    Ok(format!(
        "{}:{}:{}",
        encode_component(series.trim()),
        encode_component(season.trim()),
        encode_component(id)
    ))
}
fn collect<T, P: rusqlite::Params, F: FnMut(&Row<'_>) -> rusqlite::Result<T>>(
    connection: &Connection,
    sql: &str,
    params: P,
    map: F,
) -> Result<Vec<T>> {
    Ok(connection
        .prepare_cached(sql)?
        .query_map(params, map)?
        .collect::<rusqlite::Result<Vec<_>>>()?)
}
fn provider_row(r: &Row<'_>) -> rusqlite::Result<Provider> {
    Ok(Provider {
        id: r.get("id")?,
        name: r.get("name")?,
        kind: r.get("type")?,
        source: r.get("source")?,
        source_kind: r.get("source_kind")?,
        username: r.get("username")?,
        password: r.get("password")?,
        is_enabled: r.get("is_enabled")?,
        auto_refresh_enabled: r.get("auto_refresh_enabled")?,
        auto_refresh_interval_minutes: r.get("auto_refresh_interval_minutes")?,
        last_refresh_at: r.get("last_refresh_at")?,
    })
}
fn item_row(r: &Row<'_>) -> rusqlite::Result<CatalogItem> {
    Ok(CatalogItem {
        id: r.get("id")?,
        provider_id: r.get("provider_id")?,
        content_type: r.get("content_type")?,
        title: r.get("title")?,
        category_id: r.get("category_id")?,
        category_name: r.get("category_name")?,
        subtitle: r.get("subtitle")?,
        description: r.get("description")?,
        artwork_url: r.get("artwork_url")?,
        stream_url: r.get("stream_url")?,
        stream_json: r.get("stream_json")?,
        external_id: r.get("external_id")?,
        year: r.get("year")?,
        rating: r.get("rating")?,
        duration_seconds: r.get("duration_seconds")?,
        epg_channel_id: r.get("epg_channel_id")?,
        container_extension: r.get("container_extension")?,
        is_favorite: r.get("is_favorite")?,
    })
}
fn progress_row(r: &Row<'_>) -> rusqlite::Result<PlaybackProgress> {
    Ok(PlaybackProgress {
        provider_id: r.get("provider_id")?,
        catalog_key: r.get("catalog_key")?,
        item_id: r.get("item_id")?,
        item_type: r.get("item_type")?,
        title: r.get("title")?,
        subtitle: r.get("subtitle")?,
        artwork_url: r.get("artwork_url")?,
        series_id: r.get("series_id")?,
        season_id: r.get("season_id")?,
        position_seconds: r.get("position_seconds")?,
        duration_seconds: r.get("duration_seconds")?,
        completion_percentage: r.get("completion_percentage")?,
        completed: r.get("completed")?,
        last_watched_at: r.get("last_watched_at")?,
        watch_count: r.get("watch_count")?,
    })
}
fn series_row(r: &Row<'_>) -> rusqlite::Result<Series> {
    Ok(Series {
        id: r.get("id")?,
        provider_id: r.get("provider_id")?,
        catalog_item_id: r.get("catalog_item_id")?,
        external_id: r.get("external_id")?,
        title: r.get("title")?,
        overview: r.get("overview")?,
        poster_url: r.get("poster_url")?,
        backdrop_url: r.get("backdrop_url")?,
    })
}
fn season_row(r: &Row<'_>) -> rusqlite::Result<Season> {
    Ok(Season {
        id: r.get("id")?,
        provider_id: r.get("provider_id")?,
        series_id: r.get("series_id")?,
        season_number: r.get("season_number")?,
        title: r.get("title")?,
        overview: r.get("overview")?,
        poster_url: r.get("poster_url")?,
    })
}
fn episode_row(r: &Row<'_>) -> rusqlite::Result<Episode> {
    Ok(Episode {
        id: r.get("id")?,
        provider_id: r.get("provider_id")?,
        series_id: r.get("series_id")?,
        season_id: r.get("season_id")?,
        season_number: r.get("season_number")?,
        episode_number: r.get("episode_number")?,
        title: r.get("title")?,
        description: r.get("description")?,
        artwork_url: r.get("artwork_url")?,
        stream_url: r.get("stream_url")?,
        stream_json: r.get("stream_json")?,
        external_id: r.get("external_id")?,
        duration_seconds: r.get("duration_seconds")?,
    })
}
fn upsert_item(c: &Connection, i: &CatalogItem, now: i64) -> Result<()> {
    ensure!(
        !i.id.is_empty() && !i.title.trim().is_empty(),
        "Item ID and title required"
    );
    let category = i
        .category_name
        .as_deref()
        .filter(|n| !n.trim().is_empty())
        .map(|n| category_id(&i.provider_id, &i.content_type, n))
        .or_else(|| i.category_id.clone());
    c.prepare_cached("INSERT INTO catalog_items(id,provider_id,content_type,category_id,title,normalized_title,subtitle,description,artwork_url,stream_url,stream_json,external_id,year,rating,duration_seconds,epg_channel_id,container_extension,created_at,updated_at,last_seen_at,is_stale) VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?18,?18,0) ON CONFLICT(provider_id,content_type,id) DO UPDATE SET category_id=excluded.category_id,title=excluded.title,normalized_title=excluded.normalized_title,subtitle=excluded.subtitle,description=COALESCE(excluded.description,catalog_items.description),artwork_url=COALESCE(excluded.artwork_url,catalog_items.artwork_url),stream_url=excluded.stream_url,stream_json=excluded.stream_json,external_id=excluded.external_id,year=COALESCE(excluded.year,catalog_items.year),rating=COALESCE(excluded.rating,catalog_items.rating),duration_seconds=COALESCE(excluded.duration_seconds,catalog_items.duration_seconds),epg_channel_id=excluded.epg_channel_id,container_extension=excluded.container_extension,updated_at=excluded.updated_at,last_seen_at=excluded.last_seen_at,is_stale=0")?.execute(params![i.id,i.provider_id,i.content_type,category,i.title.trim(),normalize(&i.title),i.subtitle,i.description,i.artwork_url,i.stream_url,i.stream_json,i.external_id,i.year,i.rating,i.duration_seconds,i.epg_channel_id,i.container_extension,now])?;
    Ok(())
}
fn upsert_series(c: &Connection, s: &Series, now: i64) -> Result<()> {
    let id = s
        .catalog_item_id
        .as_deref()
        .filter(|s| !s.is_empty())
        .unwrap_or(&s.id);
    c.prepare_cached("INSERT INTO series(id,provider_id,catalog_item_id,external_id,title,normalized_title,overview,poster_url,backdrop_url,updated_at,last_seen_at,is_stale) VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?10,0) ON CONFLICT(provider_id,id) DO UPDATE SET catalog_item_id=COALESCE(excluded.catalog_item_id,series.catalog_item_id),external_id=COALESCE(excluded.external_id,series.external_id),title=excluded.title,normalized_title=excluded.normalized_title,overview=COALESCE(excluded.overview,series.overview),poster_url=COALESCE(excluded.poster_url,series.poster_url),backdrop_url=COALESCE(excluded.backdrop_url,series.backdrop_url),updated_at=excluded.updated_at,last_seen_at=excluded.last_seen_at,is_stale=0")?.execute(params![id,s.provider_id,s.catalog_item_id,s.external_id,s.title,normalize(&s.title),s.overview,s.poster_url,s.backdrop_url,now])?;
    Ok(())
}
const SERIES_EXTERNAL_INDEX: &str = "CREATE INDEX IF NOT EXISTS idx_series_provider_external ON series(provider_id, external_id, is_stale, id)";
const SERIES_LOOKUPS: [&str; 3] = [
    "SELECT id FROM series WHERE provider_id=?1 AND id=?2 AND is_stale=0 ORDER BY id LIMIT 1",
    "SELECT id FROM series WHERE provider_id=?1 AND catalog_item_id=?2 AND is_stale=0 ORDER BY id LIMIT 1",
    "SELECT id FROM series WHERE provider_id=?1 AND external_id=?2 AND is_stale=0 ORDER BY id LIMIT 1",
];
fn resolve_series(c: &Connection, provider: &str, id: &str) -> Result<String> {
    // Resolve canonical primary keys before aliases. An OR across these columns
    // scans a provider's series for every imported season/episode instead of
    // seeking the indexed key, making a large catalog import quadratic.
    for sql in SERIES_LOOKUPS {
        if let Some(canonical) = c
            .prepare_cached(sql)?
            .query_row(params![provider, id], |r| r.get(0))
            .optional()?
        {
            return Ok(canonical);
        }
    }
    anyhow::bail!("Series is not in the active provider scope")
}

fn upsert_season(c: &Connection, s: &Season, now: i64) -> Result<()> {
    ensure!(s.season_number >= 0, "Invalid season number");
    let series = resolve_series(c, &s.provider_id, &s.series_id)?;
    c.prepare_cached("INSERT INTO seasons(id,provider_id,series_id,season_number,title,overview,poster_url,updated_at,last_seen_at,is_stale) VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?8,0) ON CONFLICT(provider_id,series_id,id) DO UPDATE SET season_number=excluded.season_number,title=excluded.title,overview=excluded.overview,poster_url=excluded.poster_url,updated_at=excluded.updated_at,last_seen_at=excluded.last_seen_at,is_stale=0")?.execute(params![s.season_number.to_string(),s.provider_id,series,s.season_number,s.title,s.overview,s.poster_url,now])?;
    Ok(())
}
fn upsert_episode(c: &Connection, e: &Episode, now: i64) -> Result<()> {
    let series = resolve_series(c, &e.provider_id, &e.series_id)?;
    let season:String=c.query_row("SELECT id FROM seasons WHERE provider_id=?1 AND series_id=?2 AND (id=?3 OR season_number=?4) AND is_stale=0 ORDER BY id=?3 DESC LIMIT 1",params![e.provider_id,series,e.season_id,e.season_number],|r|r.get(0)).optional()?.context("Episode season is outside provider scope")?;
    c.prepare_cached("INSERT INTO episodes(id,provider_id,series_id,season_id,season_number,episode_number,title,normalized_title,description,artwork_url,stream_url,stream_json,external_id,duration_seconds,created_at,updated_at,last_seen_at,is_stale) VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?15,?15,0) ON CONFLICT(provider_id,series_id,season_id,id) DO UPDATE SET season_number=excluded.season_number,episode_number=excluded.episode_number,title=excluded.title,normalized_title=excluded.normalized_title,description=excluded.description,artwork_url=excluded.artwork_url,stream_url=excluded.stream_url,stream_json=excluded.stream_json,external_id=excluded.external_id,duration_seconds=excluded.duration_seconds,updated_at=excluded.updated_at,last_seen_at=excluded.last_seen_at,is_stale=0")?.execute(params![e.id,e.provider_id,series,season,e.season_number,e.episode_number,e.title,normalize(&e.title),e.description,e.artwork_url,e.stream_url,e.stream_json,e.external_id,e.duration_seconds,now])?;
    Ok(())
}
fn replace_epg_on(c: &Connection, provider: &str, programs: &[EpgProgram], now: i64) -> Result<()> {
    ensure!(
        programs.iter().all(|p| p.provider_id == provider
            && p.end_at > p.start_at
            && !p.channel_id.trim().is_empty()
            && !p.title.trim().is_empty()),
        "Invalid or out-of-scope EPG entry"
    );
    c.execute("DELETE FROM epg_programs WHERE provider_id=?", [provider])?;
    let mut statement=c.prepare_cached("INSERT INTO epg_programs(provider_id,channel_id,start_at,end_at,title,description,category,imported_at) VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(provider_id,channel_id,start_at) DO UPDATE SET end_at=excluded.end_at,title=excluded.title,description=excluded.description,category=excluded.category,imported_at=excluded.imported_at")?;
    for p in programs {
        statement.execute(params![
            provider,
            p.channel_id,
            p.start_at,
            p.end_at,
            p.title,
            p.description,
            p.category,
            now
        ])?;
    }
    Ok(())
}

/// Compatibility helper used by playback targets. Incomplete episode scopes
/// must be validated by save_progress/catalog_key before writing user data.
pub fn playback_catalog_key(item_id: &str, series: Option<&str>, season: Option<&str>) -> String {
    match (series, season) {
        (Some(series), Some(season)) => format!(
            "{}:{}:{}",
            encode_component(series.trim()),
            encode_component(season.trim()),
            encode_component(item_id)
        ),
        _ => item_id.to_owned(),
    }
}

#[cfg(test)]
mod series_lookup_tests {
    use super::*;
    use rusqlite::StatementStatus;

    fn seeded(count: usize) -> Connection {
        let connection = Connection::open_in_memory().unwrap();
        connection.execute_batch(migration::SCHEMA).unwrap();
        connection.execute("INSERT INTO providers(id,type,name,source) VALUES('p','m3u','Synthetic','synthetic')",[]).unwrap();
        {
            let tx = connection.unchecked_transaction().unwrap();
            let mut statement=tx.prepare("INSERT INTO series(id,provider_id,catalog_item_id,external_id,title,normalized_title) VALUES(?1,'p',?2,?3,'Show','show')").unwrap();
            for index in 0..count {
                statement
                    .execute(params![
                        format!("series-{index:05}"),
                        format!("catalog-{index:05}"),
                        format!("external-{index:05}")
                    ])
                    .unwrap();
            }
            drop(statement);
            tx.commit().unwrap();
        }
        connection
    }

    #[test]
    fn indexed_lookups_have_bounded_work_as_catalog_grows() {
        for count in [10, 10_000] {
            let connection = seeded(count);
            for (sql, column, key) in [
                (
                    SERIES_LOOKUPS[0],
                    "AND id=?",
                    format!("series-{:05}", count - 1),
                ),
                (
                    SERIES_LOOKUPS[1],
                    "catalog_item_id=?",
                    format!("catalog-{:05}", count - 1),
                ),
                (
                    SERIES_LOOKUPS[2],
                    "external_id=?",
                    format!("external-{:05}", count - 1),
                ),
            ] {
                assert_eq!(
                    resolve_series(&connection, "p", &key).unwrap(),
                    format!("series-{:05}", count - 1)
                );
                let plan: String = connection
                    .prepare(&format!("EXPLAIN QUERY PLAN {sql}"))
                    .unwrap()
                    .query_map(params!["p", key], |row| row.get::<_, String>(3))
                    .unwrap()
                    .collect::<rusqlite::Result<Vec<_>>>()
                    .unwrap()
                    .join("; ");
                assert!(
                    plan.contains(column),
                    "Lookup does not seek its key: {plan}"
                );
                let mut statement = connection.prepare(sql).unwrap();
                statement.reset_status(StatementStatus::VmStep);
                let _: String = statement
                    .query_row(params!["p", key], |row| row.get(0))
                    .unwrap();
                // VM operation counts test scaling without wall-clock flakiness.
                assert!(
                    statement.get_status(StatementStatus::VmStep) < 200,
                    "Lookup scans catalog records: {plan}"
                );
            }
        }
    }

    #[test]
    fn canonical_id_wins_alias_collisions_and_provider_scope_is_preserved() {
        let connection = seeded(10);
        connection
            .execute(
                "UPDATE series SET external_id='series-00009' WHERE id='series-00000'",
                [],
            )
            .unwrap();
        connection
            .execute(
                "UPDATE series SET external_id='ambiguous' WHERE id='series-00001'",
                [],
            )
            .unwrap();
        connection
            .execute(
                "UPDATE series SET catalog_item_id='ambiguous' WHERE id='series-00002'",
                [],
            )
            .unwrap();
        assert_eq!(
            resolve_series(&connection, "p", "series-00009").unwrap(),
            "series-00009"
        );
        assert_eq!(
            resolve_series(&connection, "p", "ambiguous").unwrap(),
            "series-00002"
        );
        assert!(resolve_series(&connection, "other", "series-00009").is_err());
        connection
            .execute("UPDATE series SET is_stale=1 WHERE id='series-00002'", [])
            .unwrap();
        assert_eq!(
            resolve_series(&connection, "p", "ambiguous").unwrap(),
            "series-00001"
        );
    }

    #[test]
    fn existing_schema_four_catalog_gets_external_index_on_open() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("existing.sqlite");
        let connection = Connection::open(&path).unwrap();
        connection.execute_batch(migration::SCHEMA).unwrap();
        connection
            .execute_batch("DROP INDEX idx_series_provider_external")
            .unwrap();
        drop(connection);
        let store = Store::open(&path).unwrap();
        let index_exists:bool=store.connection.query_row("SELECT EXISTS(SELECT 1 FROM sqlite_master WHERE type='index' AND name='idx_series_provider_external')",[],|row|row.get(0)).unwrap();
        assert!(index_exists);
        store.integrity_check().unwrap();
    }
}
