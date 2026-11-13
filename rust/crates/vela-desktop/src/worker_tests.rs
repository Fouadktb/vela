//! Integration tests of the real command queue and SQLite worker. No native
//! window, installed library, environment mutation, or public network needed.
use crate::worker::{Command, Event, PlaybackTarget, ViewData, Worker};
use anyhow::Result;
use eframe::egui;
use std::{
    io::{Read, Write},
    net::TcpListener,
    path::Path,
    sync::mpsc,
    thread,
    time::{Duration, Instant},
};
use vela_core::*;

fn provider(id: &str) -> Provider {
    Provider {
        id: id.into(),
        name: format!("Test {id}"),
        kind: "m3u".into(),
        source: "https://fixture.invalid/list.m3u".into(),
        is_enabled: true,
        auto_refresh_enabled: false,
        auto_refresh_interval_minutes: 1440,
        ..Default::default()
    }
}
fn start(path: &Path) -> Worker {
    let worker = Worker::test_new(egui::Context::default(), path.to_owned());
    match worker
        .rx
        .recv_timeout(Duration::from_secs(10))
        .expect("worker must report startup")
    {
        Event::Ready(actual) => assert_eq!(actual, path),
        Event::Fatal(error) | Event::Error(error) => panic!("worker startup failed: {error}"),
        _ => panic!("first worker event must be Ready"),
    }
    worker
}
fn until(worker: &Worker, predicate: impl Fn(&Event) -> bool) -> Event {
    let deadline = Instant::now() + Duration::from_secs(10);
    loop {
        let event = worker
            .rx
            .recv_timeout(deadline.saturating_duration_since(Instant::now()))
            .expect("worker response timed out");
        if predicate(&event) {
            return event;
        }
        if let Event::Fatal(error) | Event::Error(error) = event {
            panic!("unexpected worker error: {error}");
        }
    }
}
fn load(worker: &Worker, token: u64, query: CatalogQuery) -> ViewData {
    worker.send(Command::Load(token, query));
    match until(
        worker,
        |event| matches!(event,Event::View(actual,_) if *actual==token),
    ) {
        Event::View(_, data) => data,
        _ => unreachable!(),
    }
}

#[test]
fn ordered_shutdown_flushes_latest_volume_mute_settings_and_progress() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("worker.sqlite");
    let mut worker = start(&path);
    worker.send(Command::SaveProvider(provider("p")));
    worker.send(Command::Setting("language".into(), "de".into()));
    for value in 1..=100 {
        worker.send(Command::Volume(VolumePreferences {
            volume: f64::from(value),
            last_audible_volume: f64::from(value),
        }));
    }
    worker.send(Command::Volume(VolumePreferences {
        volume: 0.0,
        last_audible_volume: 37.0,
    }));
    worker.send(Command::Progress(PlaybackProgress {
        provider_id: "p".into(),
        item_id: "film".into(),
        item_type: "movie".into(),
        title: "Film".into(),
        position_seconds: 133,
        duration_seconds: Some(1000),
        ..Default::default()
    }));
    // No acknowledgement waits: shutdown itself must drain earlier commands.
    worker.shutdown();
    let store = Store::open(&path)?;
    let volume = store.volume()?;
    assert_eq!(volume.volume, 0.0);
    assert_eq!(volume.last_audible_volume, 37.0);
    assert_eq!(store.setting("language")?.as_deref(), Some("de"));
    assert_eq!(
        store
            .resume("p", "movie", "film", None, None)?
            .unwrap()
            .position_seconds,
        133
    );
    drop(store);
    let reopened = start(&path);
    let data = load(&reopened, 1, CatalogQuery::default());
    let restored: VolumePreferences = serde_json::from_str(
        data.settings
            .get("playback_output_volume")
            .expect("saved volume setting"),
    )?;
    assert_eq!(restored.volume, 0.0);
    assert_eq!(restored.last_audible_volume, 37.0);
    assert_eq!(data.history[0].position_seconds, 133);
    Ok(())
}

#[test]
fn dropping_worker_preserves_pending_last_volume_choice() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("worker.sqlite");
    {
        let worker = start(&path);
        worker.send(Command::Volume(VolumePreferences {
            volume: 24.0,
            last_audible_volume: 24.0,
        }));
        worker.send(Command::Volume(VolumePreferences {
            volume: 62.0,
            last_audible_volume: 62.0,
        }));
    }
    assert_eq!(Store::open(&path)?.volume()?.volume, 62.0);
    Ok(())
}

#[test]
fn worker_pagination_and_episode_history_keep_scoped_identity() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("worker.sqlite");
    let store = Store::open(&path)?;
    store.upsert_provider(&provider("p"))?;
    let movies = (0..3)
        .map(|index| CatalogItem {
            id: format!("film-{index}"),
            provider_id: "p".into(),
            content_type: "movie".into(),
            title: format!("Film {index}"),
            ..Default::default()
        })
        .collect();
    let mut snapshot = ImportSnapshot {
        provider_id: "p".into(),
        items: movies,
        ..Default::default()
    };
    for show in ["show:a", "show/b"] {
        snapshot.items.push(CatalogItem {
            id: show.into(),
            provider_id: "p".into(),
            content_type: "series".into(),
            title: show.into(),
            ..Default::default()
        });
    }
    store.replace_catalog(&snapshot)?;
    let mut expected_history = None;
    for (show, position) in [("show:a", 10), ("show/b", 80)] {
        let episode = Episode {
            id: "shared:episode".into(),
            provider_id: "p".into(),
            series_id: show.into(),
            season_id: "1".into(),
            season_number: 1,
            episode_number: 1,
            title: format!("Episode from {show}"),
            stream_url: Some(format!("https://fixture.invalid/{position}.ts")),
            ..Default::default()
        };
        store.replace_series_details(&SeriesDetails {
            series: Series {
                id: show.into(),
                provider_id: "p".into(),
                catalog_item_id: Some(show.into()),
                title: show.into(),
                ..Default::default()
            },
            seasons: vec![Season {
                provider_id: "p".into(),
                series_id: show.into(),
                season_number: 1,
                ..Default::default()
            }],
            episodes: vec![episode],
        })?;
        let progress = PlaybackProgress {
            provider_id: "p".into(),
            item_id: "shared:episode".into(),
            item_type: "episode".into(),
            series_id: Some(show.into()),
            season_id: Some("1".into()),
            title: format!("Episode from {show}"),
            position_seconds: position,
            last_watched_at: 1700000000000 + position,
            ..Default::default()
        };
        store.save_progress(&progress)?;
        if show == "show/b" {
            expected_history = Some(progress);
        }
    }
    drop(store);
    let worker = start(&path);
    let data = load(
        &worker,
        42,
        CatalogQuery {
            content_type: Some("movie".into()),
            limit: 1,
            offset: 1,
            ..Default::default()
        },
    );
    assert_eq!(data.page.total, 3);
    assert_eq!(data.page.items.len(), 1);
    assert_eq!(data.page.items[0].id, "film-1");
    assert_eq!(data.history.len(), 2);
    let mut history = expected_history.unwrap();
    // A history row retained by the UI can predate newer persisted progress.
    // Resuming must consult SQLite rather than replaying the stale UI snapshot.
    history.position_seconds = 3;
    worker.send(Command::ResumeHistory(history));
    match until(&worker, |event| matches!(event, Event::Prepared(..))) {
        Event::Prepared(target, Some(progress)) => {
            assert_eq!(target.series_id.as_deref(), Some("show/b"));
            assert_eq!(target.season_id.as_deref(), Some("1"));
            assert_eq!(target.key(), "show%2Fb:1:shared%3Aepisode");
            assert_eq!(
                target.item.stream_url.as_deref(),
                Some("https://fixture.invalid/80.ts")
            );
            assert_eq!(progress.position_seconds, 80);
            worker.send(Command::Prepare(PlaybackTarget {
                generation: 0,
                item: target.item,
                series_id: Some("show:a".into()),
                season_id: Some("1".into()),
            }));
        }
        _ => panic!("expected a resumable episode target"),
    }
    match until(&worker, |event| matches!(event, Event::Prepared(..))) {
        Event::Prepared(_, Some(progress)) => assert_eq!(progress.position_seconds, 10),
        _ => panic!("expected the other series' independent resume position"),
    }
    Ok(())
}

#[test]
fn failed_http_refresh_keeps_catalog_and_records_persisted_failure() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("worker.sqlite");
    let listener = TcpListener::bind("127.0.0.1:0")?;
    let address = listener.local_addr()?;
    let (stop_tx, stop_rx) = mpsc::channel();
    listener.set_nonblocking(true)?;
    let server = thread::spawn(move || {
        let deadline = Instant::now() + Duration::from_secs(10);
        while Instant::now() < deadline {
            match listener.accept() {
                Ok((mut stream, _)) => {
                    stream.set_nonblocking(false).unwrap();
                    stream
                        .set_read_timeout(Some(Duration::from_secs(2)))
                        .unwrap();
                    let mut buffer = [0u8; 4096];
                    let _ = stream.read(&mut buffer);
                    stream.write_all(b"HTTP/1.1 503 Service Unavailable\r\nContent-Length: 0\r\nConnection: close\r\n\r\n").unwrap();
                }
                Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => {
                    if stop_rx.recv_timeout(Duration::from_millis(5)).is_ok() {
                        return;
                    }
                }
                Err(error) => panic!("fixture server failed: {error}"),
            }
        }
    });
    let mut p = provider("p");
    p.source = format!("http://{address}/playlist.m3u");
    let store = Store::open(&path)?;
    store.upsert_provider(&p)?;
    store.replace_catalog(&ImportSnapshot {
        provider_id: "p".into(),
        items: vec![CatalogItem {
            id: "kept".into(),
            provider_id: "p".into(),
            content_type: "live".into(),
            title: "Existing channel".into(),
            stream_url: Some("https://fixture.invalid/kept.ts".into()),
            ..Default::default()
        }],
        ..Default::default()
    })?;
    drop(store);
    let mut worker = start(&path);
    worker.send(Command::Refresh(p));
    let error = match until(&worker, |event| matches!(event, Event::Error(_))) {
        Event::Error(error) => error,
        _ => unreachable!(),
    };
    assert!(!error.is_empty());
    let data = load(&worker, 9, CatalogQuery::default());
    assert_eq!(data.page.total, 1);
    assert_eq!(data.page.items[0].id, "kept");
    worker.shutdown();
    let _ = stop_tx.send(());
    server.join().expect("fixture server must exit");
    let raw = rusqlite::Connection::open(&path)?;
    let result:(String,i64,Option<String>)=raw.query_row("SELECT status,item_count,error_message FROM provider_refresh_runs ORDER BY started_at DESC LIMIT 1",[],|row|Ok((row.get(0)?,row.get(1)?,row.get(2)?)))?;
    assert_eq!(result.0, "failed");
    assert_eq!(result.1, 0);
    assert!(result.2.is_some());
    Ok(())
}

#[test]
fn invalid_existing_database_reports_fatal_and_remains_untouched() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("unreadable.sqlite");
    let original = b"invalid existing catalog must never become an empty library";
    std::fs::write(&path, original)?;
    let mut worker = Worker::test_new(egui::Context::default(), path.clone());
    match worker.rx.recv_timeout(Duration::from_secs(10))? {
        Event::Fatal(error) => assert!(error.contains("left untouched")),
        _ => panic!("an invalid catalog must block worker startup"),
    }
    worker.shutdown();
    assert_eq!(std::fs::read(&path)?, original);
    Ok(())
}

#[test]
fn play_series_resumes_scoped_season_then_advances_and_replays_without_rewriting_history()
-> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("series-worker.sqlite");
    let store = Store::open(&path)?;
    store.upsert_provider(&provider("p"))?;
    let show = CatalogItem {
        id: "show:scoped".into(),
        provider_id: "p".into(),
        content_type: "series".into(),
        title: "Scoped Show".into(),
        ..Default::default()
    };
    store.replace_catalog(&ImportSnapshot {
        provider_id: "p".into(),
        items: vec![show.clone()],
        ..Default::default()
    })?;
    let seasons = (1..=2)
        .map(|season| Season {
            provider_id: "p".into(),
            series_id: show.id.clone(),
            season_number: season,
            ..Default::default()
        })
        .collect();
    let mut episodes = Vec::new();
    for season in 1..=2 {
        for (number, id) in [(1, "shared:episode"), (2, "shared:next")] {
            episodes.push(Episode {
                id: id.into(),
                provider_id: "p".into(),
                series_id: show.id.clone(),
                season_id: season.to_string(),
                season_number: season,
                episode_number: number,
                title: format!("Season {season} episode {number}"),
                stream_url: Some(format!("https://fixture.invalid/s{season}e{number}.ts")),
                ..Default::default()
            });
        }
    }
    store.replace_series_details(&SeriesDetails {
        series: Series {
            id: show.id.clone(),
            provider_id: "p".into(),
            catalog_item_id: Some(show.id.clone()),
            title: show.title.clone(),
            ..Default::default()
        },
        seasons,
        episodes,
    })?;
    for (season, position, watched) in [("1", 12, 1700000000010), ("2", 45, 1700000000020)] {
        store.save_progress(&PlaybackProgress {
            provider_id: "p".into(),
            item_id: "shared:episode".into(),
            item_type: "episode".into(),
            series_id: Some(show.id.clone()),
            season_id: Some(season.into()),
            title: format!("Season {season} episode 1"),
            position_seconds: position,
            last_watched_at: watched,
            ..Default::default()
        })?;
    }
    drop(store);
    let mut worker = start(&path);
    worker.send(Command::PlaySeries(show.clone()));
    match until(&worker, |event| matches!(event, Event::PlaybackQueue(..))) {
        Event::PlaybackQueue(_, queue) => {
            assert_eq!(queue.len(), 4);
            assert_eq!(queue[0].season_id, "1");
            assert_eq!(queue[2].season_id, "2");
        }
        _ => unreachable!(),
    }
    let mut current = match until(&worker, |event| matches!(event, Event::Prepared(..))) {
        Event::Prepared(target, Some(progress)) => {
            assert_eq!(target.series_id.as_deref(), Some("show:scoped"));
            assert_eq!(target.season_id.as_deref(), Some("2"));
            assert_eq!(target.item.id, "shared:episode");
            assert_eq!(
                target.item.stream_url.as_deref(),
                Some("https://fixture.invalid/s2e1.ts")
            );
            assert_eq!(target.key(), "show%3Ascoped:2:shared%3Aepisode");
            assert_eq!(progress.catalog_key, target.key());
            assert_eq!(progress.position_seconds, 45);
            progress
        }
        _ => panic!("PlaySeries must emit the saved second-season episode and resume"),
    };
    current.completed = true;
    current.last_watched_at += 10;
    worker.send(Command::Progress(current));
    worker.send(Command::PlaySeries(show.clone()));
    match until(&worker, |event| matches!(event, Event::Prepared(..))) {
        Event::Prepared(target, Some(progress)) => {
            assert_eq!(target.season_id.as_deref(), Some("1"));
            assert_eq!(progress.position_seconds, 12);
        }
        _ => panic!("an older valid resumable position takes priority over completed episodes"),
    }
    worker.send(Command::Progress(PlaybackProgress {
        provider_id: "p".into(),
        item_id: "shared:episode".into(),
        item_type: "episode".into(),
        series_id: Some(show.id.clone()),
        season_id: Some("1".into()),
        completed: true,
        last_watched_at: 1700000000010,
        ..Default::default()
    }));
    worker.send(Command::PlaySeries(show.clone()));
    match until(&worker, |event| matches!(event, Event::Prepared(..))) {
        Event::Prepared(target, resume) => {
            assert_eq!(target.season_id.as_deref(), Some("2"));
            assert_eq!(target.item.id, "shared:next");
            assert_eq!(
                target.item.stream_url.as_deref(),
                Some("https://fixture.invalid/s2e2.ts")
            );
            assert!(resume.is_none());
        }
        _ => unreachable!(),
    }
    worker.send(Command::Progress(PlaybackProgress {
        provider_id: "p".into(),
        item_id: "shared:next".into(),
        item_type: "episode".into(),
        series_id: Some(show.id.clone()),
        season_id: Some("2".into()),
        title: "Season 2 episode 2".into(),
        completed: true,
        last_watched_at: 1700000000040,
        ..Default::default()
    }));
    worker.send(Command::PlaySeries(show));
    match until(&worker, |event| matches!(event, Event::Prepared(..))) {
        Event::Prepared(target, resume) => {
            assert_eq!(target.season_id.as_deref(), Some("2"));
            assert_eq!(target.item.id, "shared:next");
            assert_eq!(
                target.item.stream_url.as_deref(),
                Some("https://fixture.invalid/s2e2.ts")
            );
            assert!(
                resume.is_none(),
                "last completed episode must replay without wrapping"
            );
        }
        _ => unreachable!(),
    }
    worker.shutdown();
    let store = Store::open(&path)?;
    let history = store.recent_history(20)?;
    assert_eq!(
        history.len(),
        3,
        "choosing playback must not rewrite the history to a series-level identity"
    );
    assert!(
        history
            .iter()
            .all(|p| p.item_type == "episode" && p.series_id.as_deref() == Some("show:scoped"))
    );
    assert!(
        history
            .iter()
            .any(|p| p.catalog_key == "show%3Ascoped:1:shared%3Aepisode" && p.completed)
    );
    assert!(
        history
            .iter()
            .any(|p| p.catalog_key == "show%3Ascoped:2:shared%3Aepisode" && p.completed)
    );
    Ok(())
}

#[test]
fn home_continue_resolves_older_series_and_movies_outside_loaded_catalog_pages() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("home-worker.sqlite");
    let store = Store::open(&path)?;
    store.upsert_provider(&provider("p"))?;
    let mut items = (0..80)
        .map(|index| CatalogItem {
            id: format!("film-{index:03}"),
            provider_id: "p".into(),
            content_type: "movie".into(),
            title: format!("A Movie {index:03}"),
            ..Default::default()
        })
        .collect::<Vec<_>>();
    items.extend((0..40).map(|index| CatalogItem {
        id: format!("series-{index:03}"),
        provider_id: "p".into(),
        content_type: "series".into(),
        title: format!("B Series {index:03}"),
        ..Default::default()
    }));
    items.push(CatalogItem {
        id: "old-film".into(),
        provider_id: "p".into(),
        content_type: "movie".into(),
        title: "Z Old Movie".into(),
        stream_url: Some("https://fixture.invalid/old-movie.ts".into()),
        ..Default::default()
    });
    items.push(CatalogItem {
        id: "old:series".into(),
        provider_id: "p".into(),
        content_type: "series".into(),
        title: "Z Old Series".into(),
        description: Some("Resolved series metadata".into()),
        ..Default::default()
    });
    store.replace_catalog(&ImportSnapshot {
        provider_id: "p".into(),
        items,
        ..Default::default()
    })?;
    store.replace_series_details(&SeriesDetails {
        series: Series {
            id: "old:series".into(),
            provider_id: "p".into(),
            catalog_item_id: Some("old:series".into()),
            title: "Z Old Series".into(),
            ..Default::default()
        },
        seasons: vec![Season {
            provider_id: "p".into(),
            series_id: "old:series".into(),
            season_number: 2,
            ..Default::default()
        }],
        episodes: vec![Episode {
            id: "old:episode".into(),
            provider_id: "p".into(),
            series_id: "old:series".into(),
            season_id: "2".into(),
            season_number: 2,
            episode_number: 1,
            title: "Old Series Pilot".into(),
            ..Default::default()
        }],
    })?;
    store.save_progress(&PlaybackProgress {
        provider_id: "p".into(),
        item_id: "old-film".into(),
        item_type: "movie".into(),
        title: "Old movie history title".into(),
        position_seconds: 17,
        last_watched_at: 1700000000010,
        ..Default::default()
    })?;
    store.save_progress(&PlaybackProgress {
        provider_id: "p".into(),
        item_id: "old:episode".into(),
        item_type: "episode".into(),
        series_id: Some("old:series".into()),
        season_id: Some("2".into()),
        title: "Old episode history title".into(),
        position_seconds: 61,
        last_watched_at: 1700000000020,
        ..Default::default()
    })?;
    // Simulate entries imported long before the rest of this library. Series
    // metadata enrichment above legitimately updates its timestamp, so the
    // fixture must set both import and metadata dates to their old values.
    rusqlite::Connection::open(&path)?.execute("UPDATE catalog_items SET created_at=1700000000000,updated_at=1700000000000 WHERE id IN ('old-film','old:series')",[])?;
    drop(store);
    let worker = start(&path);
    let data = load(
        &worker,
        500,
        CatalogQuery {
            limit: 60,
            ..Default::default()
        },
    );
    assert_eq!(data.page.items.len(), 60);
    assert!(
        data.page
            .items
            .iter()
            .all(|i| i.id != "old:series" && i.id != "old-film")
    );
    assert!(data.latest_movies.iter().all(|i| i.id != "old-film"));
    assert!(data.latest_series.iter().all(|i| i.id != "old:series"));
    assert_eq!(data.home_continue.len(), 2);
    let (series, progress) = &data.home_continue[0];
    assert_eq!(series.content_type, "series");
    assert_eq!(series.id, "old:series");
    assert_eq!(series.title, "Z Old Series");
    assert_eq!(
        series.description.as_deref(),
        Some("Resolved series metadata")
    );
    assert_eq!(progress.item_type, "episode");
    assert_eq!(progress.item_id, "old:episode");
    assert_eq!(progress.series_id.as_deref(), Some("old:series"));
    assert_eq!(progress.season_id.as_deref(), Some("2"));
    assert_eq!(progress.position_seconds, 61);
    let (movie, progress) = &data.home_continue[1];
    assert_eq!(movie.id, "old-film");
    assert_eq!(movie.title, "Z Old Movie");
    assert_eq!(
        movie.stream_url.as_deref(),
        Some("https://fixture.invalid/old-movie.ts")
    );
    assert_eq!(progress.position_seconds, 17);
    Ok(())
}

#[test]
fn late_series_playback_cannot_replace_a_newer_movie_or_canceled_request() -> Result<()> {
    use crate::worker::Origin;
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("worker.sqlite");
    let store = Store::open(&path)?;
    let p = provider("p");
    store.upsert_provider(&p)?;
    drop(store);
    let worker = start(&path);
    let old_generation = worker.generation();
    worker.send(Command::Prepare(PlaybackTarget::catalog(CatalogItem {
        id: "new-movie".into(),
        provider_id: "p".into(),
        content_type: "movie".into(),
        ..Default::default()
    })));
    // A network failure from the superseded series must also be discarded.
    worker.complete_for_test(
        old_generation,
        Command::PlaySeriesFetched(
            Origin {
                provider: p.clone(),
                revision: 0,
            },
            Err(anyhow::anyhow!("stale series request")),
        ),
    );
    match until(&worker, |event| matches!(event, Event::Prepared(..))) {
        Event::Prepared(target, _) => {
            assert_eq!(target.item.id, "new-movie");
            assert_eq!(target.generation, worker.generation());
        }
        _ => unreachable!(),
    }
    load(&worker, 801, CatalogQuery::default()); // fence behind stale completion
    let canceled_generation = worker.generation();
    worker.send(Command::CancelPlayback);
    worker.complete_for_test(
        canceled_generation,
        Command::PlaySeriesFetched(
            Origin {
                provider: p,
                revision: 0,
            },
            Err(anyhow::anyhow!("canceled request")),
        ),
    );
    load(&worker, 802, CatalogQuery::default());
    Ok(())
}

#[test]
fn stale_provider_results_are_discarded_even_after_source_changes_back() -> Result<()> {
    use crate::worker::Origin;
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("worker.sqlite");
    let store = Store::open(&path)?;
    let p = provider("p");
    store.upsert_provider(&p)?;
    store.replace_epg(
        "p",
        &[EpgProgram {
            provider_id: "p".into(),
            channel_id: "channel".into(),
            start_at: 100,
            end_at: 200,
            title: "Current programme".into(),
            ..Default::default()
        }],
    )?;
    drop(store);
    let mut worker = start(&path);
    let mut changed = p.clone();
    changed.source = "https://fixture.invalid/new-account.m3u".into();
    worker.send(Command::SaveProvider(changed));
    worker.send(Command::SaveProvider(p.clone()));
    let origin = Origin {
        provider: p.clone(),
        revision: 0,
    };
    worker.send(Command::SeriesFetched(
        origin.clone(),
        "old-show".into(),
        Ok(SeriesDetails {
            series: Series {
                id: "old-show".into(),
                provider_id: "p".into(),
                ..Default::default()
            },
            ..Default::default()
        }),
    ));
    worker.send(Command::MovieFetched(
        origin.clone(),
        "old-movie".into(),
        Err(anyhow::anyhow!("old metadata failure")),
    ));
    worker.send(Command::EpgFetched(origin.clone(), Ok(vec![])));
    worker.send(Command::PlaySeriesFetched(
        origin.clone(),
        Err(anyhow::anyhow!("old series playback")),
    ));
    load(&worker, 803, CatalogQuery::default());
    worker.send(Command::Guide("p".into(), vec!["channel".into()], 0, 300));
    match until(&worker, |event| matches!(event, Event::Epg(_))) {
        Event::Epg(programmes) => {
            assert_eq!(programmes.len(), 1);
            assert_eq!(programmes[0].title, "Current programme");
        }
        _ => unreachable!(),
    }
    {
        let raw = rusqlite::Connection::open(&path)?;
        let count: i64 = raw.query_row("SELECT count(*) FROM series", [], |r| r.get(0))?;
        assert_eq!(count, 0);
    }
    worker.send(Command::DeleteProvider("p".into()));
    worker.send(Command::SaveProvider(p));
    worker.send(Command::EpgFetched(
        origin,
        Err(anyhow::anyhow!("deleted provider result")),
    ));
    load(&worker, 804, CatalogQuery::default());
    worker.shutdown();
    let store = Store::open(&path)?;
    assert!(store.episodes("p", "old-show")?.is_empty());
    let raw = rusqlite::Connection::open(path)?;
    let count: i64 = raw.query_row("SELECT count(*) FROM series", [], |r| r.get(0))?;
    assert_eq!(count, 0);
    Ok(())
}

#[test]
fn global_search_round_trip_ignores_then_restores_section_filters_and_recent_scope() -> Result<()> {
    use crate::worker::{global_search_query, toggle_global_search};
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("global-worker.sqlite");
    let store = Store::open(&path)?;
    for id in ["a", "b"] {
        store.upsert_provider(&provider(id))?;
    }
    let favorite = CatalogItem {
        id: "a-film".into(),
        provider_id: "a".into(),
        content_type: "movie".into(),
        category_id: Some("a-category".into()),
        title: "Needle Movie".into(),
        stream_url: Some("https://fixture.invalid/movie.ts".into()),
        ..Default::default()
    };
    store.replace_catalog(&ImportSnapshot {
        provider_id: "a".into(),
        items: vec![
            favorite.clone(),
            CatalogItem {
                id: "hidden-movie".into(),
                provider_id: "a".into(),
                content_type: "movie".into(),
                category_id: Some("a-category".into()),
                title: "Needle Unfavorited".into(),
                ..Default::default()
            },
        ],
        ..Default::default()
    })?;
    store.toggle_favorite(&favorite)?;
    let mut items = (0..12)
        .map(|index| CatalogItem {
            id: format!("b-live-{index}"),
            provider_id: "b".into(),
            content_type: "live".into(),
            title: format!("Needle Live {index:02}"),
            stream_url: Some(format!("https://fixture.invalid/live-{index}.ts")),
            ..Default::default()
        })
        .collect::<Vec<_>>();
    items.push(CatalogItem {
        id: "b-movie".into(),
        provider_id: "b".into(),
        content_type: "movie".into(),
        title: "Another provider's movie".into(),
        subtitle: Some("Needle appears in the subtitle".into()),
        stream_url: Some("https://fixture.invalid/b-movie.ts".into()),
        ..Default::default()
    });
    items.push(CatalogItem {
        id: "b-series".into(),
        provider_id: "b".into(),
        content_type: "series".into(),
        title: "Needle Series".into(),
        ..Default::default()
    });
    store.replace_catalog(&ImportSnapshot {
        provider_id: "b".into(),
        items,
        ..Default::default()
    })?;
    store.replace_series_details(&SeriesDetails {
        series: Series {
            id: "b-series".into(),
            provider_id: "b".into(),
            catalog_item_id: Some("b-series".into()),
            title: "Needle Series".into(),
            ..Default::default()
        },
        seasons: vec![Season {
            provider_id: "b".into(),
            series_id: "b-series".into(),
            season_number: 2,
            ..Default::default()
        }],
        episodes: vec![Episode {
            id: "shared:episode".into(),
            provider_id: "b".into(),
            series_id: "b-series".into(),
            season_id: "2".into(),
            season_number: 2,
            episode_number: 1,
            title: "Needle Pilot".into(),
            stream_url: Some("https://fixture.invalid/season-2-pilot.ts".into()),
            ..Default::default()
        }],
    })?;
    store.save_progress(&PlaybackProgress {
        provider_id: "b".into(),
        item_id: "shared:episode".into(),
        item_type: "episode".into(),
        series_id: Some("b-series".into()),
        season_id: Some("2".into()),
        title: "Needle Pilot".into(),
        position_seconds: 47,
        ..Default::default()
    })?;
    drop(store);
    let worker = start(&path);
    let mut query = CatalogQuery {
        provider_id: Some("a".into()),
        content_type: Some("movie".into()),
        category_id: Some("a-category".into()),
        favorites_only: true,
        search: "Needle".into(),
        limit: 60,
        ..Default::default()
    };
    let section = load(&worker, 700, query.clone());
    assert!(section.global_search.is_none());
    assert_eq!(section.page.total, 1);
    assert_eq!(section.page.items[0].id, "a-film");
    toggle_global_search(&mut query);
    assert_eq!(query.search, "/ Needle");
    assert_eq!(global_search_query(&query.search), Some("Needle"));
    // The UI's preserved filters remain unchanged; only the worker's separate
    // global request ignores them. No irreversible filter reset is involved.
    assert_eq!(query.provider_id.as_deref(), Some("a"));
    assert_eq!(query.content_type.as_deref(), Some("movie"));
    assert_eq!(query.category_id.as_deref(), Some("a-category"));
    assert!(query.favorites_only);
    let global = load(&worker, 701, query.clone())
        .global_search
        .expect("slash prefix must activate grouped search");
    assert_eq!(global.query, "Needle");
    assert_eq!(
        global.groups.iter().map(|g| g.title).collect::<Vec<_>>(),
        vec!["Live", "Movies", "Series", "Favorites", "Recent"]
    );
    assert!(global.groups.iter().all(|g| g.results.len() <= 8));
    assert_eq!(global.groups[0].results.len(), 8);
    assert!(
        global.groups[1]
            .results
            .iter()
            .any(|r| r.item.provider_id == "b" && r.item.id == "b-movie"),
        "global search must include other providers and subtitle matches"
    );
    assert!(
        global.groups[1]
            .results
            .iter()
            .any(|r| r.item.id == "hidden-movie"),
        "global search must ignore section's favorites-only filter"
    );
    assert_eq!(global.groups[3].results.len(), 1);
    assert_eq!(global.groups[3].results[0].item.id, "a-film");
    let recent = &global.groups[4].results[0];
    assert_eq!(recent.item.content_type, "series");
    assert_eq!(recent.item.id, "b-series");
    let progress = recent
        .progress
        .clone()
        .expect("recent result retains scoped playback identity");
    assert_eq!(progress.provider_id, "b");
    assert_eq!(progress.series_id.as_deref(), Some("b-series"));
    assert_eq!(progress.season_id.as_deref(), Some("2"));
    worker.send(Command::ResumeHistory(progress));
    match until(&worker, |event| matches!(event, Event::Prepared(..))) {
        Event::Prepared(target, Some(resume)) => {
            assert_eq!(target.item.id, "shared:episode");
            assert_eq!(target.season_id.as_deref(), Some("2"));
            assert_eq!(
                target.item.stream_url.as_deref(),
                Some("https://fixture.invalid/season-2-pilot.ts")
            );
            assert_eq!(resume.position_seconds, 47);
        }
        _ => panic!("global Recent action must preserve episode scope"),
    }
    toggle_global_search(&mut query);
    assert_eq!(query.search, "Needle");
    let restored = load(&worker, 702, query.clone());
    assert!(restored.global_search.is_none());
    assert_eq!(restored.page.total, 1);
    assert_eq!(restored.page.items[0].id, "a-film");
    // Typing a prefix directly uses the identical path as the globe toggle.
    query.search = "   /   Needle ".into();
    let typed = load(&worker, 703, query.clone()).global_search.unwrap();
    assert_eq!(typed.groups.len(), 5);
    query.search = "/".into();
    let prompt = load(&worker, 704, query.clone()).global_search.unwrap();
    assert!(prompt.query.is_empty());
    assert!(prompt.groups.is_empty());
    query.search = "/ impossible phrase".into();
    let empty = load(&worker, 705, query).global_search.unwrap();
    assert!(empty.groups.is_empty());
    Ok(())
}

#[test]
fn departing_episode_progress_refreshes_only_the_current_generation_series_rail() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("rail-progress.sqlite");
    let store = Store::open(&path)?;
    store.upsert_provider(&provider("p"))?;
    store.replace_catalog(&imports::m3u::parse("#EXTM3U\n#EXTINF:-1,A S01E01\nhttps://fixture.invalid/a1.mp4\n#EXTINF:-1,A S01E02\nhttps://fixture.invalid/a2.mp4\n#EXTINF:-1,B S01E01\nhttps://fixture.invalid/b1.mp4\n", "p")?)?;
    let a = store.episodes("p", "p:series:a")?;
    let b = store.episodes("p", "p:series:b")?;
    assert_eq!(a.len(), 2);
    assert_eq!(b.len(), 1);
    drop(store);
    let worker = start(&path);
    for episode in [&a[0], &a[1]] {
        worker.send(Command::Prepare(PlaybackTarget::episode(episode)));
        until(&worker, |event| matches!(event, Event::Prepared(..)));
    }
    let progress = |episode: &Episode, seconds| PlaybackProgress {
        provider_id: episode.provider_id.clone(),
        item_id: episode.id.clone(),
        item_type: "episode".into(),
        series_id: Some(episode.series_id.clone()),
        season_id: Some(episode.season_id.clone()),
        title: episode.title.clone(),
        position_seconds: seconds,
        duration_seconds: Some(60),
        last_watched_at: 1_700_000_000_000 + seconds,
        ..Default::default()
    };
    // This is the UI's actual order: Prepare(new) completes, then the old
    // player's final Progress write arrives from Event::Prepared handling.
    worker.send(Command::Progress(progress(&a[0], 17)));
    match until(&worker, |event| {
        matches!(event, Event::PlaybackPositions(..))
    }) {
        Event::PlaybackPositions(generation, positions) => {
            assert_eq!(generation, worker.generation());
            assert_eq!(positions.len(), 1);
            assert_eq!(positions[0].item_id, a[0].id);
            assert_eq!(positions[0].position_seconds, 17);
        }
        _ => unreachable!(),
    }
    worker.send(Command::Prepare(PlaybackTarget::episode(&b[0])));
    until(&worker, |event| matches!(event, Event::Prepared(..)));
    worker.send(Command::Progress(progress(&a[1], 9)));
    match until(&worker, |event| {
        matches!(event, Event::PlaybackPositions(..))
    }) {
        Event::PlaybackPositions(generation, positions) => {
            assert_eq!(generation, worker.generation());
            assert!(
                positions.is_empty(),
                "departing series A must not overwrite series B's rail"
            );
        }
        _ => unreachable!(),
    }
    worker.send(Command::CancelPlayback);
    worker.send(Command::Progress(progress(&b[0], 5)));
    worker.send(Command::Load(911, CatalogQuery::default()));
    loop {
        match worker.rx.recv_timeout(Duration::from_secs(10))? {
            Event::View(911, _) => break,
            Event::PlaybackPositions(..) => panic!("closed playback must not receive rail updates"),
            Event::Error(error) | Event::Fatal(error) => panic!("worker failed: {error}"),
            _ => {}
        }
    }
    Ok(())
}

#[test]
fn live_channels_never_resume_old_positions_when_reopened_from_history() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("live-start.sqlite");
    let store = Store::open(&path)?;
    store.upsert_provider(&provider("p"))?;
    let item = CatalogItem {
        id: "channel".into(),
        provider_id: "p".into(),
        content_type: "live".into(),
        title: "Channel".into(),
        stream_url: Some("https://fixture.invalid/live.ts".into()),
        ..Default::default()
    };
    store.replace_catalog(&ImportSnapshot {
        provider_id: "p".into(),
        items: vec![item.clone()],
        ..Default::default()
    })?;
    let progress = PlaybackProgress {
        provider_id: "p".into(),
        item_id: item.id.clone(),
        item_type: "live".into(),
        title: item.title.clone(),
        position_seconds: 35,
        duration_seconds: Some(100),
        ..Default::default()
    };
    store.save_progress(&progress)?;
    drop(store);
    let worker = start(&path);
    for command in [
        Command::Prepare(PlaybackTarget::catalog(item)),
        Command::ResumeHistory(progress),
    ] {
        worker.send(command);
        match until(&worker, |event| matches!(event, Event::Prepared(..))) {
            Event::Prepared(target, resume) => {
                assert_eq!(target.item.content_type, "live");
                assert!(
                    resume.is_none(),
                    "live channel startup must not seek to an old timestamp"
                );
            }
            _ => unreachable!(),
        }
    }
    assert_eq!(
        Store::open(path)?.recent_history(1)?[0].position_seconds,
        35
    );
    Ok(())
}

struct HeldImport {
    provider: Provider,
    started: mpsc::Receiver<()>,
    release: Option<mpsc::Sender<()>>,
    join: Option<thread::JoinHandle<()>>,
}
impl HeldImport {
    fn new(id: &str, status: u16) -> Result<Self> {
        let listener = TcpListener::bind("127.0.0.1:0")?;
        listener.set_nonblocking(true)?;
        let address = listener.local_addr()?;
        let (started_tx, started) = mpsc::channel();
        let (release_tx, release_rx) = mpsc::channel();
        let join = thread::spawn(move || {
            let deadline = Instant::now() + Duration::from_secs(10);
            let mut stream = loop {
                match listener.accept() {
                    Ok((stream, _)) => break stream,
                    Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => {
                        assert!(Instant::now() < deadline, "Import did not start");
                        thread::sleep(Duration::from_millis(2));
                    }
                    Err(error) => panic!("Synthetic import failed: {error}"),
                }
            };
            stream.set_nonblocking(false).unwrap();
            stream
                .set_read_timeout(Some(Duration::from_secs(10)))
                .unwrap();
            use std::io::{BufRead, BufReader};
            let mut reader = BufReader::new(stream.try_clone().unwrap());
            let mut request = String::new();
            loop {
                request.clear();
                assert!(reader.read_line(&mut request).unwrap() > 0);
                if request == "\r\n" {
                    break;
                }
            }
            started_tx.send(()).unwrap();
            release_rx.recv_timeout(Duration::from_secs(15)).unwrap();
            let body = "#EXTM3U\n#EXTINF:-1,Imported channel\nhttps://fixture.invalid/live.ts\n";
            write!(
                stream,
                "HTTP/1.1 {status} Test\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                body.len()
            )
            .unwrap();
        });
        let mut provider = provider(id);
        provider.source = format!("http://{address}/playlist");
        Ok(Self {
            provider,
            started,
            release: Some(release_tx),
            join: Some(join),
        })
    }
    fn start(&self, worker: &Worker) -> Result<()> {
        worker.send(Command::Refresh(self.provider.clone()));
        self.started.recv_timeout(Duration::from_secs(10))?;
        Ok(())
    }
    fn release(&mut self) {
        if let Some(release) = self.release.take() {
            let _ = release.send(());
        }
    }
}
impl Drop for HeldImport {
    fn drop(&mut self) {
        self.release();
        if let Some(join) = self.join.take() {
            let _ = join.join();
        }
    }
}
fn while_importing(worker: &Worker, predicate: impl Fn(&Event) -> bool) -> Event {
    let deadline = Instant::now() + Duration::from_secs(10);
    loop {
        let event = worker
            .rx
            .recv_timeout(deadline.saturating_duration_since(Instant::now()))
            .expect("Foreground work must finish while imports are held");
        assert!(
            !matches!(event, Event::Busy(false)),
            "Import status ended while an import was still held"
        );
        if predicate(&event) {
            return event;
        }
        if let Event::Error(error) | Event::Fatal(error) = event {
            panic!("Foreground work was blocked: {error}");
        }
    }
}

#[test]
fn foreground_content_loads_while_two_imports_are_held() -> Result<()> {
    let temporary = tempfile::tempdir()?;
    let path = temporary.path().join("concurrent.sqlite");
    let mut first = HeldImport::new("background-one", 200)?;
    let mut second = HeldImport::new("background-two", 200)?;
    let listener = TcpListener::bind("127.0.0.1:0")?;
    let address = listener.local_addr()?;
    let metadata = thread::spawn(move || {
        use std::io::{BufRead, BufReader};
        for _ in 0..3 {
            let (mut stream, _) = listener.accept().unwrap();
            stream
                .set_read_timeout(Some(Duration::from_secs(10)))
                .unwrap();
            let mut reader = BufReader::new(stream.try_clone().unwrap());
            let mut line = String::new();
            reader.read_line(&mut line).unwrap();
            let target = line.split_whitespace().nth(1).unwrap();
            let url = url::Url::parse(&format!("http://localhost{target}")).unwrap();
            let query: std::collections::HashMap<_, _> = url.query_pairs().into_owned().collect();
            loop {
                line.clear();
                reader.read_line(&mut line).unwrap();
                if line == "\r\n" || line.is_empty() {
                    break;
                }
            }
            let body = if query["action"] == "get_vod_info" {
                serde_json::json!({"info":{"name":"Movie","plot":"Ready during import","movie_image":"https://fixture.invalid/poster.jpg"},"movie_data":{"container_extension":"mp4"}})
            } else {
                serde_json::json!({"info":{"name":"Series"},"episodes":{"1":[{"id":format!("{}-episode",query["series_id"]),"title":"Episode one","episode_num":1}]}})
            }.to_string();
            write!(
                stream,
                "HTTP/1.1 200 OK\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                body.len()
            )
            .unwrap();
        }
    });
    let mut foreground = provider("foreground");
    foreground.kind = "xtream".into();
    foreground.source = format!("http://{address}");
    foreground.username = Some("synthetic".into());
    foreground.password = Some("synthetic".into());
    let item = |kind: &str, id: &str| CatalogItem {
        id: id.into(),
        provider_id: foreground.id.clone(),
        content_type: kind.into(),
        title: id.into(),
        external_id: Some(id.into()),
        ..Default::default()
    };
    let movie = item("movie", "movie");
    let details = item("series", "details");
    let playback = item("series", "playback");
    {
        let store = Store::open(&path)?;
        for p in [&first.provider, &second.provider, &foreground] {
            store.upsert_provider(p)?;
        }
        store.replace_catalog(&ImportSnapshot {
            provider_id: foreground.id.clone(),
            items: vec![movie.clone(), details.clone(), playback.clone()],
            ..Default::default()
        })?;
    }
    let worker = start(&path);
    first.start(&worker)?;
    second.start(&worker)?;
    worker.send(Command::Movie(foreground.clone(), movie));
    match while_importing(
        &worker,
        |event| matches!(event,Event::Metadata(item) if item.artwork_url.is_some()),
    ) {
        Event::Metadata(item) => {
            assert_eq!(item.description.as_deref(), Some("Ready during import"))
        }
        _ => unreachable!(),
    }
    worker.send(Command::Series(foreground, details));
    while_importing(
        &worker,
        |event| matches!(event,Event::Series(_,_,episodes) if !episodes.is_empty()),
    );
    worker.send(Command::PlaySeries(playback));
    match while_importing(&worker, |event| matches!(event, Event::Prepared(..))) {
        Event::Prepared(target, _) => assert_eq!(target.series_id.as_deref(), Some("playback")),
        _ => unreachable!(),
    }
    metadata.join().unwrap();
    first.release();
    while_importing(
        &worker,
        |event| matches!(event,Event::Message(message) if message.starts_with("Imported ")),
    );
    while_importing(&worker, |event| matches!(event, Event::Busy(true)));
    // Busy(true) after the first completion is published only after its commit.
    assert_eq!(
        Store::open(&path)?
            .catalog(&CatalogQuery {
                provider_id: Some(first.provider.id.clone()),
                ..Default::default()
            })?
            .total,
        1
    );
    second.release();
    until(&worker, |event| matches!(event, Event::Busy(false)));
    assert_eq!(
        Store::open(path)?
            .catalog(&CatalogQuery {
                provider_id: Some(second.provider.id.clone()),
                ..Default::default()
            })?
            .total,
        1
    );
    Ok(())
}

#[test]
fn failed_and_deleted_imports_release_busy_only_when_all_jobs_finish() -> Result<()> {
    for deleted in [false, true] {
        let temporary = tempfile::tempdir()?;
        let path = temporary.path().join("busy.sqlite");
        let mut first = HeldImport::new("first", if deleted { 200 } else { 500 })?;
        let mut second = HeldImport::new("second", 200)?;
        {
            let store = Store::open(&path)?;
            store.upsert_provider(&first.provider)?;
            store.upsert_provider(&second.provider)?;
        }
        let worker = start(&path);
        first.start(&worker)?;
        second.start(&worker)?;
        // Drain both start notifications before examining completion status.
        while_importing(&worker, |e| matches!(e, Event::Busy(true)));
        while_importing(&worker, |e| matches!(e, Event::Busy(true)));
        if deleted {
            worker.send(Command::DeleteProvider(first.provider.id.clone()));
            while_importing(
                &worker,
                |e| matches!(e,Event::Message(message) if message.starts_with("Provider and")),
            );
        }
        first.release();
        while_importing(&worker, |e| matches!(e, Event::Busy(true)));
        if !deleted {
            until(&worker, |e| matches!(e, Event::Error(_)));
        }
        second.release();
        until(&worker, |e| matches!(e, Event::Busy(false)));
    }
    Ok(())
}
