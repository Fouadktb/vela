//! Non-destructive adoption of the Flutter catalog. SQLite's backup API includes
//! committed WAL pages; copying the main database file alone would lose data.
use anyhow::{Context, Result, bail, ensure};
use rusqlite::{Connection, OpenFlags, backup::Backup};
use std::{
    collections::BTreeMap,
    path::{Path, PathBuf},
    time::Duration,
};

pub const SCHEMA_VERSION: i64 = 4;
pub const SCHEMA: &str = include_str!("schema.sql");
pub const TABLES: &[&str] = &[
    "providers",
    "provider_refresh_runs",
    "categories",
    "catalog_items",
    "series",
    "seasons",
    "episodes",
    "epg_programs",
    "favorite_items",
    "favorite_categories",
    "category_order",
    "watch_history",
    "playback_positions",
    "app_settings",
];

pub fn default_database_path() -> Result<PathBuf> {
    if let Some(directory) = std::env::var_os("VELA_DATA_DIR") {
        return Ok(PathBuf::from(directory).join("vela_catalog.sqlite"));
    }
    let dirs = directories::ProjectDirs::from("com", "fouadktb", "Vela")
        .context("Cannot determine the Vela application data directory")?;
    Ok(dirs.data_local_dir().join("vela_catalog.sqlite"))
}

pub fn legacy_candidates() -> Vec<PathBuf> {
    let mut paths = Vec::new();
    if let Some(user) = directories::UserDirs::new() {
        if let Some(documents) = user.document_dir() {
            paths.push(documents.join("vela_catalog.sqlite"));
        }
        // Sandboxed Flutter macOS releases use a container Documents directory.
        paths.push(
            user.home_dir()
                .join("Library/Containers/com.fouadktb.vela/Data/Documents/vela_catalog.sqlite"),
        );
    }
    paths
}

pub fn readonly(path: &Path) -> Result<Connection> {
    let connection = Connection::open_with_flags(path, OpenFlags::SQLITE_OPEN_READ_ONLY)
        .with_context(|| format!("Cannot read catalog {}", path.display()))?;
    connection.busy_timeout(Duration::from_secs(10))?;
    Ok(connection)
}

pub fn validate(connection: &Connection) -> Result<i64> {
    let version: i64 = connection.pragma_query_value(None, "user_version", |r| r.get(0))?;
    ensure!(
        (1..=SCHEMA_VERSION).contains(&version),
        "Catalog schema {version} is unsupported; expected version 1 through {SCHEMA_VERSION}"
    );
    let integrity: String = connection.query_row("PRAGMA integrity_check", [], |r| r.get(0))?;
    ensure!(
        integrity == "ok",
        "Catalog integrity check failed: {integrity}"
    );
    let reference = Connection::open_in_memory()?;
    reference.execute_batch(SCHEMA)?;
    for table in TABLES {
        if version < 4 && *table == "epg_programs" {
            continue;
        }
        let actual = columns(connection, table)?;
        ensure!(!actual.is_empty(), "Catalog is missing table {table}");
        for (column, kind) in columns(&reference, table)? {
            if version < 2 && column == "auto_refresh_interval_minutes" {
                continue;
            }
            if version < 3 && column == "completion_percentage" {
                continue;
            }
            ensure!(
                actual
                    .get(&column)
                    .is_some_and(|v| v.eq_ignore_ascii_case(&kind)),
                "Catalog table {table} has missing or incompatible column {column}"
            );
        }
    }
    let mut fk = connection.prepare("PRAGMA foreign_key_check")?;
    ensure!(
        !fk.exists([])?,
        "Catalog contains broken provider references"
    );
    Ok(version)
}

fn columns(connection: &Connection, table: &str) -> Result<BTreeMap<String, String>> {
    let mut statement = connection.prepare(&format!("PRAGMA table_info(\"{table}\")"))?;
    Ok(statement
        .query_map([], |r| Ok((r.get(1)?, r.get(2)?)))?
        .collect::<rusqlite::Result<_>>()?)
}

pub fn row_counts(connection: &Connection) -> Result<BTreeMap<String, i64>> {
    let mut counts = BTreeMap::new();
    for table in TABLES {
        if !columns(connection, table)?.is_empty() {
            counts.insert(
                (*table).to_owned(),
                connection.query_row(&format!("SELECT COUNT(*) FROM \"{table}\""), [], |r| {
                    r.get(0)
                })?,
            );
        }
    }
    Ok(counts)
}

/// Upgrade only the adopted copy, using the same migrations as Flutter.
pub fn upgrade(connection: &Connection, version: i64) -> Result<()> {
    ensure!(
        version <= SCHEMA_VERSION,
        "Refusing to downgrade a newer catalog"
    );
    connection.execute_batch("BEGIN IMMEDIATE")?;
    let result = (|| -> Result<()> {
        if version < 2 {
            connection.execute_batch(
                "ALTER TABLE providers ADD COLUMN auto_refresh_interval_minutes INTEGER NOT NULL DEFAULT 1440;
                 UPDATE providers SET auto_refresh_interval_minutes = auto_refresh_interval_hours * 60
                 WHERE auto_refresh_interval_hours IS NOT NULL;",
            )?;
        }
        if version < 3 {
            for table in ["watch_history", "playback_positions"] {
                connection.execute_batch(&format!(
                    "ALTER TABLE {table} ADD COLUMN completion_percentage REAL NOT NULL DEFAULT 0;
                     UPDATE {table} SET completion_percentage = CASE WHEN completed = 1 THEN 1
                     WHEN duration_seconds > 0 THEN MIN(1.0, CAST(position_seconds AS REAL) / duration_seconds)
                     ELSE 0 END;",
                ))?;
            }
        }
        connection.execute_batch(SCHEMA)?;
        Ok(())
    })();
    match result {
        Ok(()) => {
            connection.execute_batch("COMMIT")?;
            Ok(())
        }
        Err(error) => {
            let _ = connection.execute_batch("ROLLBACK");
            Err(error)
        }
    }
}

/// Returns the source path when a catalog was migrated. An existing native
/// catalog always wins. Multiple legacy catalogs require an explicit choice.
pub fn migrate_if_needed(target: &Path, candidates: &[PathBuf]) -> Result<Option<PathBuf>> {
    if target.exists() {
        return Ok(None);
    }
    let mut sources = Vec::new();
    for candidate in candidates {
        match std::fs::metadata(candidate) {
            Ok(metadata) => {
                ensure!(
                    metadata.is_file(),
                    "Legacy catalog path is not a file: {}",
                    candidate.display()
                );
                let canonical = candidate.canonicalize()?;
                if !sources.contains(&canonical) {
                    sources.push(canonical);
                }
            }
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            Err(error) => {
                return Err(error).with_context(|| {
                    format!(
                        "Cannot inspect legacy catalog {}; refusing to start with an empty library",
                        candidate.display()
                    )
                });
            }
        }
    }
    if sources.is_empty() {
        return Ok(None);
    }
    if sources.len() != 1 {
        bail!(
            "Multiple legacy Vela catalogs found; select a source explicitly before migration: {}",
            sources
                .iter()
                .map(|p| p.display().to_string())
                .collect::<Vec<_>>()
                .join(", ")
        );
    }
    let source_path = &sources[0];
    let source = readonly(source_path)?;
    // Hold one read snapshot for validation, counts, and backup while other
    // processes may still be writing to the old app's database.
    source.execute_batch("BEGIN DEFERRED")?;
    let version = validate(&source)?;
    let counts = row_counts(&source)?;
    let parent = target
        .parent()
        .context("Catalog path has no parent directory")?;
    std::fs::create_dir_all(parent)?;
    let stage = parent.join(format!(".vela-migration-{}.sqlite", uuid::Uuid::new_v4()));
    let result = (|| -> Result<()> {
        let mut adopted = Connection::open(&stage)?;
        restrict_permissions(&stage)?;
        Backup::new(&source, &mut adopted)?.run_to_completion(
            128,
            Duration::from_millis(5),
            None,
        )?;
        ensure!(
            row_counts(&adopted)? == counts,
            "Catalog row counts changed during backup"
        );
        upgrade(&adopted, version)?;
        validate(&adopted)?;
        for (table, before) in counts {
            let after: i64 =
                adopted.query_row(&format!("SELECT COUNT(*) FROM \"{table}\""), [], |r| {
                    r.get(0)
                })?;
            ensure!(before == after, "Migration changed {table} row count");
        }
        adopted.close().map_err(|(_, error)| error)?;
        std::fs::File::open(&stage)?.sync_all()?;
        // Unlike rename(), hard_link() never replaces an existing target.
        std::fs::hard_link(&stage, target)
            .context("Cannot publish migrated catalog without replacing a file")?;
        Ok(())
    })();
    let _ = std::fs::remove_file(&stage);
    result?;
    Ok(Some(source_path.clone()))
}

pub fn restrict_permissions(path: &Path) -> Result<()> {
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        std::fs::set_permissions(path, std::fs::Permissions::from_mode(0o600))?;
    }
    Ok(())
}
