use anyhow::Result;
use rusqlite::Connection;
use vela_core::{
    migration,
    store::{catalog_key, category_id},
    *,
};

fn provider(id: &str) -> Provider {
    Provider {
        id: id.into(),
        name: format!("Provider {id}"),
        kind: "m3u".into(),
        source: "https://example.test/list.m3u".into(),
        is_enabled: true,
        auto_refresh_enabled: true,
        auto_refresh_interval_minutes: 1440,
        ..Default::default()
    }
}
fn item(provider: &str, id: &str, title: &str) -> CatalogItem {
    CatalogItem {
        id: id.into(),
        provider_id: provider.into(),
        content_type: "movie".into(),
        title: title.into(),
        category_name: Some("Films & More".into()),
        stream_url: Some("https://example.test/movie.ts".into()),
        ..Default::default()
    }
}
fn snapshot(provider: &str, items: Vec<CatalogItem>) -> ImportSnapshot {
    ImportSnapshot {
        provider_id: provider.into(),
        items,
        ..Default::default()
    }
}

#[test]
fn volume_settings_and_history_survive_reopen() -> Result<()> {
    let temp = tempfile::tempdir()?;
    let path = temp.path().join("catalog.sqlite");
    {
        let store = Store::open(&path)?;
        store.upsert_provider(&provider("p"))?;
        store.save_volume(VolumePreferences {
            volume: 0.0,
            last_audible_volume: 31.0,
        })?;
        store.set_setting("language", "de")?;
        store.save_progress(&PlaybackProgress {
            provider_id: "p".into(),
            item_id: "film".into(),
            item_type: "movie".into(),
            title: "A Film".into(),
            position_seconds: 53,
            duration_seconds: Some(100),
            completion_percentage: 0.53,
            ..Default::default()
        })?;
    }
    let store = Store::open(&path)?;
    let volume = store.volume()?;
    assert_eq!(volume.volume, 0.0);
    assert_eq!(volume.last_audible_volume, 31.0);
    assert_eq!(store.setting("language")?.as_deref(), Some("de"));
    assert_eq!(
        store
            .resume("p", "movie", "film", None, None)?
            .unwrap()
            .position_seconds,
        53
    );
    assert_eq!(store.recent_history(20)?.len(), 1);
    store.integrity_check()?;
    Ok(())
}

#[test]
fn catalog_refresh_is_atomic_paginated_and_preserves_user_data() -> Result<()> {
    let store = Store::open(":memory:")?;
    store.upsert_provider(&provider("p"))?;
    let a = item("p", "a", "100%_ Great");
    let b = item("p", "b", "Beta");
    store.replace_catalog(&snapshot("p", vec![a.clone(), b.clone()]))?;
    assert!(store.toggle_favorite(&a)?);
    let page = store.catalog(&CatalogQuery {
        search: "%_".into(),
        limit: 1,
        ..Default::default()
    })?;
    assert_eq!(page.total, 1);
    assert_eq!(page.items[0].id, "a");
    assert!(page.items[0].is_favorite);
    let categories = store.categories(Some("p"), "movie")?;
    assert_eq!(categories[0].id, category_id("p", "movie", "Films & More"));
    assert_eq!(categories[0].item_count, 2);
    let page = store.catalog(&CatalogQuery {
        limit: 1,
        offset: 1,
        ..Default::default()
    })?;
    assert_eq!(page.total, 2);
    assert_eq!(page.items[0].id, "b");
    let mut invalid = snapshot("p", vec![item("p", "c", "New")]);
    invalid
        .items
        .push(item("wrong-provider", "d", "Wrong scope"));
    assert!(store.replace_catalog(&invalid).is_err());
    assert_eq!(store.catalog(&CatalogQuery::default())?.total, 2);
    // A SQL constraint failure after earlier rows were inserted also rolls back.
    let mut broken = item("p", "z", "Bad duration");
    broken.duration_seconds = Some(-5);
    assert!(
        store
            .replace_catalog(&snapshot("p", vec![item("p", "c", "New"), broken]))
            .is_err()
    );
    assert_eq!(store.catalog(&CatalogQuery::default())?.total, 2);
    store.replace_catalog(&snapshot("p", vec![a.clone()]))?;
    assert_eq!(store.catalog(&CatalogQuery::default())?.total, 1);
    assert!(store.item("p", "movie", "a")?.unwrap().is_favorite);
    assert!(store.item("p", "movie", "b")?.is_none());
    store.delete_provider("p")?;
    assert!(store.providers()?.is_empty());
    assert!(store.catalog(&CatalogQuery::default())?.items.is_empty());
    Ok(())
}

#[test]
fn series_refresh_retains_cached_episodes_and_scoped_progress() -> Result<()> {
    let store = Store::open(":memory:")?;
    store.upsert_provider(&provider("p"))?;
    let mut show = item("p", "show", "A Show");
    show.content_type = "series".into();
    store.replace_catalog(&snapshot("p", vec![show.clone()]))?;
    let details = SeriesDetails {
        series: Series {
            id: "show".into(),
            provider_id: "p".into(),
            catalog_item_id: Some("show".into()),
            title: "A Show".into(),
            ..Default::default()
        },
        seasons: vec![Season {
            id: "upstream-season".into(),
            provider_id: "p".into(),
            series_id: "show".into(),
            season_number: 1,
            ..Default::default()
        }],
        episodes: vec![Episode {
            id: "episode".into(),
            provider_id: "p".into(),
            series_id: "show".into(),
            season_id: "upstream-season".into(),
            season_number: 1,
            episode_number: 1,
            title: "Pilot".into(),
            ..Default::default()
        }],
    };
    store.replace_series_details(&details)?;
    assert_eq!(store.episodes("p", "show")?[0].season_id, "1");
    store.replace_catalog(&snapshot("p", vec![show.clone()]))?;
    assert_eq!(
        store.episodes("p", "show")?.len(),
        1,
        "provider refresh must retain lazy-loaded episode cache"
    );
    for series in ["show", "other:show"] {
        store.save_progress(&PlaybackProgress {
            provider_id: "p".into(),
            item_id: "episode".into(),
            item_type: "episode".into(),
            series_id: Some(series.into()),
            season_id: Some("1".into()),
            title: "Pilot".into(),
            position_seconds: 10,
            ..Default::default()
        })?;
    }
    assert_eq!(store.recent_history(20)?.len(), 2);
    assert_eq!(
        catalog_key("episode", "id:a", Some("show/a"), Some("1"))?,
        "show%2Fa:1:id%3Aa"
    );
    let mut refreshed = snapshot("p", vec![show]);
    refreshed.refreshed_episode_series_ids.push("show".into());
    store.replace_catalog(&refreshed)?;
    assert!(store.episodes("p", "show")?.is_empty());
    Ok(())
}

#[test]
fn migrated_wal_snapshot_preserves_every_row_and_original() -> Result<()> {
    let temp = tempfile::tempdir()?;
    let source_path = temp.path().join("legacy.sqlite");
    let target = temp.path().join("native.sqlite");
    let source = Connection::open(&source_path)?;
    source.execute_batch(migration::SCHEMA)?;
    source.execute_batch("PRAGMA journal_mode=WAL; PRAGMA wal_autocheckpoint=0;")?;
    source.execute("INSERT INTO providers(id,type,name,source) VALUES('p','m3u','Legacy','https://example.test/list')",[])?;
    source.execute(
        "INSERT INTO app_settings(key,value) VALUES('language','de')",
        [],
    )?;
    source.execute(
        "INSERT INTO app_settings(key,value) VALUES('playback_output_volume',?1)",
        [r#"{"volume":0,"lastAudibleVolume":22}"#],
    )?;
    let original = std::fs::read(&source_path)?;
    let before = migration::row_counts(&source)?;
    assert_eq!(
        migration::migrate_if_needed(&target, std::slice::from_ref(&source_path))?,
        Some(source_path.canonicalize()?)
    );
    assert_eq!(
        std::fs::read(&source_path)?,
        original,
        "original main database must remain untouched"
    );
    let adopted = Connection::open(&target)?;
    assert_eq!(migration::row_counts(&adopted)?, before);
    let store = Store::open(&target)?;
    assert_eq!(store.providers()?.len(), 1);
    assert_eq!(store.volume()?.last_audible_volume, 22.0);
    source.execute(
        "UPDATE app_settings SET value='fr' WHERE key='language'",
        [],
    )?;
    assert_eq!(
        store.setting("language")?.as_deref(),
        Some("de"),
        "adopted copy must be independent"
    );
    Ok(())
}

#[test]
fn migration_refuses_ambiguous_corrupt_and_newer_catalogs() -> Result<()> {
    let temp = tempfile::tempdir()?;
    let a = temp.path().join("a.sqlite");
    let b = temp.path().join("b.sqlite");
    let target = temp.path().join("native.sqlite");
    Connection::open(&a)?.execute_batch(migration::SCHEMA)?;
    Connection::open(&b)?.execute_batch(migration::SCHEMA)?;
    assert!(migration::migrate_if_needed(&target, &[a.clone(), b.clone()]).is_err());
    assert!(!target.exists());
    Connection::open(&a)?.execute_batch("PRAGMA user_version=99")?;
    assert!(migration::migrate_if_needed(&target, std::slice::from_ref(&a)).is_err());
    assert!(!target.exists());
    assert!(Store::open(&a).is_err());
    let corrupt = temp.path().join("corrupt.sqlite");
    std::fs::write(&corrupt, b"not a sqlite database")?;
    assert!(migration::migrate_if_needed(&target, &[corrupt]).is_err());
    assert!(!target.exists());
    // Existing target is never replaced, even with an explicit legacy source.
    std::fs::write(&target, b"existing native file")?;
    assert!(migration::migrate_if_needed(&target, &[b])?.is_none());
    assert_eq!(std::fs::read(&target)?, b"existing native file");
    Ok(())
}

#[test]
fn old_schema_upgrade_happens_only_in_copy() -> Result<()> {
    let temp = tempfile::tempdir()?;
    let source_path = temp.path().join("v1.sqlite");
    let target = temp.path().join("adopted.sqlite");
    let source = Connection::open(&source_path)?;
    let old_schema = migration::SCHEMA
        .replace(
            "auto_refresh_interval_minutes",
            "auto_refresh_interval_hours",
        )
        .replace("DEFAULT 1440", "DEFAULT 24")
        .replace("BETWEEN 1 AND 10080", "BETWEEN 1 AND 168")
        .lines()
        .filter(|line| !line.contains("completion_percentage"))
        .collect::<Vec<_>>()
        .join("\n")
        .replace(
            "CHECK (duration_seconds IS NULL OR duration_seconds >= 0),\n);",
            "CHECK (duration_seconds IS NULL OR duration_seconds >= 0)\n);",
        );
    source.execute_batch(&old_schema)?;
    source.execute_batch("DROP TABLE epg_programs; PRAGMA user_version=1;")?;
    source.execute("INSERT INTO providers(id,type,name,source,auto_refresh_interval_hours) VALUES('p','m3u','Legacy','https://example.test',6)",[])?;
    let original = std::fs::read(&source_path)?;
    migration::migrate_if_needed(&target, std::slice::from_ref(&source_path))?;
    assert_eq!(std::fs::read(&source_path)?, original);
    assert_eq!(
        Store::open(&target)?.providers()?[0].auto_refresh_interval_minutes,
        360
    );
    let version: i64 = source.pragma_query_value(None, "user_version", |r| r.get(0))?;
    assert_eq!(version, 1);
    Ok(())
}

#[test]
fn backup_is_complete_and_never_overwrites() -> Result<()> {
    let temp = tempfile::tempdir()?;
    let store = Store::open(temp.path().join("native.sqlite"))?;
    store.upsert_provider(&provider("p"))?;
    store.set_setting("theme", "dark")?;
    let backup = temp.path().join("backup.sqlite");
    store.backup_to(&backup)?;
    assert_eq!(
        Store::open(&backup)?.setting("theme")?.as_deref(),
        Some("dark")
    );
    assert!(store.backup_to(&backup).is_err());
    Ok(())
}

#[test]
fn epg_replace_and_history_cleanup_are_scoped() -> Result<()> {
    let store = Store::open(":memory:")?;
    store.upsert_provider(&provider("p"))?;
    store.replace_epg(
        "p",
        &[EpgProgram {
            provider_id: "p".into(),
            channel_id: "channel".into(),
            start_at: 100,
            end_at: 200,
            title: "News".into(),
            ..Default::default()
        }],
    )?;
    assert_eq!(store.epg("p", &["channel".into()], 150, 250)?.len(), 1);
    assert!(store.epg("p", &[], 150, 250)?.is_empty());
    let bad = EpgProgram {
        provider_id: "wrong".into(),
        channel_id: "channel".into(),
        start_at: 100,
        end_at: 200,
        title: "Bad".into(),
        ..Default::default()
    };
    assert!(store.replace_epg("p", &[bad]).is_err());
    assert_eq!(store.epg("p", &["channel".into()], 150, 250)?.len(), 1);
    store.clear_history()?;
    assert!(store.recent_history(5)?.is_empty());
    Ok(())
}

#[test]
fn large_catalog_import_keeps_pages_bounded_and_search_complete() -> Result<()> {
    let store = Store::open(":memory:")?;
    store.upsert_provider(&provider("large"))?;
    let items = (0..10_000)
        .map(|index| {
            item(
                "large",
                &format!("item-{index:05}"),
                &format!("Movie {index:05}"),
            )
        })
        .collect();
    let started = std::time::Instant::now();
    store.replace_catalog(&snapshot("large", items))?;
    let import_elapsed = started.elapsed();
    let started = std::time::Instant::now();
    let page = store.catalog(&CatalogQuery {
        limit: 1_000,
        offset: 9_500,
        ..Default::default()
    })?;
    assert_eq!(page.total, 10_000);
    assert_eq!(page.items.len(), 500);
    assert_eq!(page.items[0].id, "item-09500");
    assert_eq!(
        store.categories(Some("large"), "movie")?[0].item_count,
        10_000
    );
    let matching = store.catalog(&CatalogQuery {
        search: "Movie 09999".into(),
        limit: 1,
        ..Default::default()
    })?;
    assert_eq!(matching.total, 1);
    assert_eq!(matching.items[0].id, "item-09999");
    eprintln!(
        "10k import: {import_elapsed:?}; paginated query and search: {:?}",
        started.elapsed()
    );
    Ok(())
}

#[test]
fn real_flutter_drift_fixture_migrates_and_preserves_all_tables() -> Result<()> {
    // This binary was created by the legacy Dart CatalogDatabase and repository
    // APIs, not this crate's schema.sql; it catches mismatched schema contracts.
    let temp = tempfile::tempdir()?;
    let source = temp.path().join("flutter.sqlite");
    let target = temp.path().join("rust.sqlite");
    let fixture = include_bytes!("fixtures/flutter_schema4.sqlite");
    std::fs::write(&source, fixture)?;
    let legacy = migration::readonly(&source)?;
    assert_eq!(migration::validate(&legacy)?, 4);
    let before = migration::row_counts(&legacy)?;
    assert_eq!(before.len(), 14);
    assert!(before.values().all(|count| *count > 0));
    migration::migrate_if_needed(&target, std::slice::from_ref(&source))?;
    assert_eq!(std::fs::read(&source)?, fixture);
    assert_eq!(
        migration::row_counts(&migration::readonly(&target)?)?,
        before
    );
    let store = Store::open(&target)?;
    let p = &store.providers()?[0];
    assert_eq!(p.kind, "xtream");
    assert_eq!(p.username.as_deref(), Some("fake-user"));
    assert_eq!(p.password.as_deref(), Some("fake-password"));
    assert!(
        store
            .item("fixture", "movie", "movie")?
            .unwrap()
            .is_favorite
    );
    let category = &store.categories(Some("fixture"), "movie")?[0];
    assert!(category.is_favorite);
    assert_eq!(category.sort_order, Some(0));
    assert_eq!(category.id, "fixture:movie:films%20%26%20more");
    let episode = &store.episodes("fixture", "series:one")?[0];
    assert_eq!(episode.id, "episode:one");
    assert_eq!(episode.season_id, "1");
    let resume = store
        .resume(
            "fixture",
            "episode",
            "episode:one",
            Some("series:one"),
            Some("1"),
        )?
        .unwrap();
    assert_eq!(resume.catalog_key, "series%3Aone:1:episode%3Aone");
    assert_eq!(resume.position_seconds, 123);
    assert_eq!(store.volume()?.last_audible_volume, 27.0);
    assert_eq!(store.setting("language")?.as_deref(), Some("de"));
    assert!(
        store
            .setting("playback_track_preferences:fixture:movie:movie")?
            .unwrap()
            .contains("German")
    );
    Ok(())
}

#[test]
fn resume_uses_authoritative_position_even_without_history() -> Result<()> {
    let temp = tempfile::tempdir()?;
    let path = temp.path().join("native.sqlite");
    let store = Store::open(&path)?;
    store.upsert_provider(&provider("p"))?;
    store.save_progress(&PlaybackProgress {
        provider_id: "p".into(),
        item_id: "film".into(),
        item_type: "movie".into(),
        title: "A Film".into(),
        position_seconds: 10,
        duration_seconds: Some(100),
        ..Default::default()
    })?;
    let raw = Connection::open(&path)?;
    raw.execute("UPDATE playback_positions SET position_seconds=42, duration_seconds=120,completion_percentage=.35,updated_at=1700000000123",[])?;
    let resume = store.resume("p", "movie", "film", None, None)?.unwrap();
    assert_eq!(resume.position_seconds, 42);
    assert_eq!(resume.duration_seconds, Some(120));
    assert_eq!(resume.completion_percentage, 0.35);
    assert_eq!(resume.last_watched_at, 1700000000123);
    raw.execute("DELETE FROM watch_history", [])?;
    assert_eq!(
        store
            .resume("p", "movie", "film", None, None)?
            .unwrap()
            .position_seconds,
        42
    );
    raw.execute("UPDATE playback_positions SET completed=1", [])?;
    assert!(store.resume("p", "movie", "film", None, None)?.is_none());
    Ok(())
}

#[test]
fn movie_metadata_update_preserves_playback_category_and_favorites() -> Result<()> {
    let store = Store::open(":memory:")?;
    store.upsert_provider(&provider("p"))?;
    let original = item("p", "film", "Original Title");
    store.replace_catalog(&snapshot("p", vec![original.clone()]))?;
    store.toggle_favorite(&original)?;
    let enriched = CatalogItem {
        provider_id: "p".into(),
        content_type: "movie".into(),
        id: "film".into(),
        title: "Should not replace title".into(),
        description: Some("Full overview".into()),
        year: Some(2025),
        rating: Some("8.2".into()),
        duration_seconds: Some(3600),
        ..Default::default()
    };
    store.update_item_metadata(&enriched)?;
    let actual = store.item("p", "movie", "film")?.unwrap();
    assert_eq!(actual.title, original.title);
    assert_eq!(actual.stream_url, original.stream_url);
    assert_eq!(actual.category_name, original.category_name);
    assert_eq!(actual.description.as_deref(), Some("Full overview"));
    assert_eq!(actual.duration_seconds, Some(3600));
    assert!(actual.is_favorite);
    Ok(())
}

#[test]
fn explicit_legacy_choice_adopts_one_source_and_never_replaces_native_data() -> Result<()> {
    let temp = tempfile::tempdir()?;
    let source = temp.path().join("selected.sqlite");
    std::fs::write(&source, include_bytes!("fixtures/flutter_schema4.sqlite"))?;
    let destination = temp.path().join("native.sqlite");
    let store = Store::open_with_legacy_at(&destination, &source)?;
    assert_eq!(
        store.migrated_from.as_deref(),
        Some(source.canonicalize()?.as_path())
    );
    assert_eq!(store.providers()?[0].id, "fixture");
    store.set_setting("language", "fr")?;
    drop(store);
    // Choosing the old source again cannot discard newer native preferences.
    let reopened = Store::open_with_legacy_at(&destination, &source)?;
    assert!(reopened.migrated_from.is_none());
    assert_eq!(reopened.setting("language")?.as_deref(), Some("fr"));
    assert_eq!(
        std::fs::read(&source)?,
        include_bytes!("fixtures/flutter_schema4.sqlite")
    );
    let absent_destination = temp.path().join("not-created.sqlite");
    assert!(
        Store::open_with_legacy_at(&absent_destination, &temp.path().join("absent.sqlite"))
            .is_err()
    );
    assert!(!absent_destination.exists());
    Ok(())
}

#[test]
fn refresh_run_history_survives_restart_and_follows_provider_lifetime() -> Result<()> {
    let temp = tempfile::tempdir()?;
    let path = temp.path().join("native.sqlite");
    let success;
    let failed;
    {
        let store = Store::open(&path)?;
        store.upsert_provider(&provider("p"))?;
        assert!(store.record_refresh_start("missing-provider").is_err());
        success = store.record_refresh_start("p")?;
        failed = store.record_refresh_start("p")?;
        assert_ne!(success, failed);
        let raw = Connection::open(&path)?;
        let started: (String, Option<i64>) = raw.query_row(
            "SELECT status,finished_at FROM provider_refresh_runs WHERE id=?",
            [&success],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )?;
        assert_eq!(started, ("running".into(), None));
        store.finish_refresh(&success, 120, None)?;
        store.finish_refresh(&failed, 0, Some("Provider response was invalid"))?;
        assert!(store.finish_refresh(&success, 999, None).is_err());
    }
    let raw = Connection::open(&path)?;
    let completed: (String, i64, Option<String>, i64) = raw.query_row(
        "SELECT status,item_count,error_message,finished_at FROM provider_refresh_runs WHERE id=?",
        [&success],
        |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?)),
    )?;
    assert_eq!(completed.0, "succeeded");
    assert_eq!(completed.1, 120);
    assert!(completed.2.is_none());
    assert!(completed.3 > 0);
    let failure: (String, String) = raw.query_row(
        "SELECT status,error_message FROM provider_refresh_runs WHERE id=?",
        [&failed],
        |r| Ok((r.get(0)?, r.get(1)?)),
    )?;
    assert_eq!(
        failure,
        ("failed".into(), "Provider response was invalid".into())
    );
    let store = Store::open(&path)?;
    store.delete_provider("p")?;
    let remaining: i64 = raw.query_row("SELECT COUNT(*) FROM provider_refresh_runs", [], |r| {
        r.get(0)
    })?;
    assert_eq!(remaining, 0);
    Ok(())
}

#[test]
fn m3u_refresh_removes_missing_episodes_and_seasons() -> Result<()> {
    let temp = tempfile::tempdir()?;
    let store = Store::open(temp.path().join("catalog.sqlite"))?;
    store.upsert_provider(&provider("p"))?;
    let first = imports::m3u::parse(
        "#EXTM3U\n#EXTINF:-1,Show S01E01\nhttps://example.test/1.mp4\n#EXTINF:-1,Show S02E01\nhttps://example.test/2.mp4\n",
        "p",
    )?;
    let series_id = first.series[0].id.clone();
    store.replace_catalog(&first)?;
    assert_eq!(store.episodes("p", &series_id)?.len(), 2);
    let refreshed = imports::m3u::parse(
        "#EXTM3U\n#EXTINF:-1,Show S01E01\nhttps://example.test/1.mp4\n",
        "p",
    )?;
    store.replace_catalog(&refreshed)?;
    let remaining = store.episodes("p", &series_id)?;
    assert_eq!(remaining.len(), 1);
    assert_eq!(remaining[0].season_number, 1);
    Ok(())
}

#[test]
fn detail_positions_restore_all_scoped_episode_progress_beyond_recent_history() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("detail.sqlite");
    let store = Store::open(&path)?;
    for id in ["a", "b"] {
        store.upsert_provider(&provider(id))?;
    }
    for (provider_id, series, season, position) in [
        ("a", "show", "1", 11),
        ("a", "show", "2", 22),
        ("a", "other", "1", 33),
        ("b", "show", "1", 44),
    ] {
        store.save_progress(&PlaybackProgress {
            provider_id: provider_id.into(),
            item_id: "shared".into(),
            item_type: "episode".into(),
            series_id: Some(series.into()),
            season_id: Some(season.into()),
            title: "Pilot".into(),
            position_seconds: position,
            last_watched_at: 1700000000000 + position,
            ..Default::default()
        })?;
    }
    for index in 0..230 {
        store.save_progress(&PlaybackProgress {
            provider_id: "a".into(),
            item_id: format!("movie-{index}"),
            item_type: "movie".into(),
            title: "Newer history".into(),
            position_seconds: 5,
            last_watched_at: 1800000000000 + index,
            ..Default::default()
        })?;
    }
    assert!(
        store
            .recent_history(200)?
            .iter()
            .all(|p| p.item_type == "movie")
    );
    // Position rows are authoritative even when history is absent or older.
    let raw = Connection::open(&path)?;
    raw.execute(
        "DELETE FROM watch_history WHERE provider_id='a' AND item_type='episode'",
        [],
    )?;
    raw.execute("UPDATE playback_positions SET position_seconds=91,completion_percentage=.91,completed=0 WHERE provider_id='a' AND series_id='show' AND season_id='2'",[])?;
    let positions = store.detail_positions("a", "series", "show")?;
    assert_eq!(positions.len(), 2);
    assert!(
        positions
            .iter()
            .all(|p| p.provider_id == "a" && p.series_id.as_deref() == Some("show"))
    );
    assert!(
        positions
            .iter()
            .any(|p| p.season_id.as_deref() == Some("1") && p.position_seconds == 11)
    );
    assert!(positions.iter().any(|p| p.season_id.as_deref() == Some("2")
        && p.position_seconds == 91
        && p.completion_percentage == 0.91));
    assert_eq!(store.detail_positions("a", "movie", "movie-100")?.len(), 1);
    assert!(store.detail_positions("a", "movie", "absent")?.is_empty());
    drop(raw);
    drop(store);
    assert_eq!(
        Store::open(&path)?
            .detail_positions("a", "series", "show")?
            .len(),
        2
    );
    Ok(())
}
