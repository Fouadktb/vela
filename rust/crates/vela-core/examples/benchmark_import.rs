//! Synthetic parser, real SQLite transaction and bounded-page benchmark.
//! cargo run --release --manifest-path rust/Cargo.toml -p vela-core --example benchmark_import -- [series-count]
use anyhow::{Context, Result, ensure};
use std::{
    fmt::Write,
    path::{Path, PathBuf},
    time::{Duration, Instant},
};
use vela_core::{CatalogQuery, Provider, Store, imports::m3u, migration};

const EPISODES_PER_SERIES: usize = 5;
const RUNS: usize = 5;
const PAGE_SIZE: usize = 60;

struct TemporaryDirectory(PathBuf);
impl TemporaryDirectory {
    fn create() -> Result<Self> {
        let path =
            std::env::temp_dir().join(format!("vela-import-benchmark-{}", uuid::Uuid::new_v4()));
        std::fs::create_dir(&path).context("Could not create a benchmark temporary directory")?;
        Ok(Self(path))
    }
    fn cleanup(self) -> Result<()> {
        std::fs::remove_dir_all(&self.0)
            .context("Could not remove the benchmark temporary directory")
    }
}
impl Drop for TemporaryDirectory {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

fn median(mut durations: Vec<Duration>) -> Duration {
    durations.sort_unstable();
    durations[durations.len() / 2]
}
fn milliseconds(duration: Duration) -> f64 {
    duration.as_secs_f64() * 1000.0
}
fn checked_snapshot(input: &str, series_count: usize) -> Result<vela_core::ImportSnapshot> {
    let snapshot = m3u::parse(std::hint::black_box(input), "benchmark")?;
    ensure!(
        snapshot.items.len() == series_count
            && snapshot.series.len() == series_count
            && snapshot.seasons.len() == series_count
            && snapshot.episodes.len() == series_count * EPISODES_PER_SERIES,
        "Parser lost catalog or episode records"
    );
    Ok(snapshot)
}

fn benchmark(path: &Path, series_count: usize) -> Result<()> {
    let mut input = String::with_capacity(series_count * EPISODES_PER_SERIES * 120);
    input.push_str("#EXTM3U\n");
    for series in 0..series_count {
        for episode in 1..=EPISODES_PER_SERIES {
            writeln!(
                input,
                "#EXTINF:-1 group-title=\"Series\",Show {series} S01E0{episode}\nhttps://example.invalid/series/{series}/{episode}.mp4"
            )?;
        }
    }
    drop(checked_snapshot(&input, series_count)?); // Warm regular expressions and allocator.
    let mut parse_times = Vec::with_capacity(RUNS);
    for _ in 0..RUNS {
        let start = Instant::now();
        let snapshot = checked_snapshot(&input, series_count)?;
        parse_times.push(start.elapsed());
        std::hint::black_box(snapshot);
    }
    let snapshot = checked_snapshot(&input, series_count)?;
    let store = Store::open(path)?;
    store.upsert_provider(&Provider {
        id: "benchmark".into(),
        name: "Synthetic benchmark provider".into(),
        kind: "m3u".into(),
        source: "synthetic.m3u".into(),
        source_kind: Some("file".into()),
        is_enabled: true,
        auto_refresh_interval_minutes: 1440,
        ..Default::default()
    })?;
    let start = Instant::now();
    store.replace_catalog(&snapshot)?;
    let initial_import = start.elapsed();
    let mut refresh_times = Vec::with_capacity(RUNS);
    for _ in 0..RUNS {
        let start = Instant::now();
        store.replace_catalog(&snapshot)?;
        refresh_times.push(start.elapsed());
    }
    store.integrity_check()?;
    let connection = migration::readonly(path)?;
    let counts = migration::row_counts(&connection)?;
    ensure!(
        counts["catalog_items"] == series_count as i64
            && counts["series"] == series_count as i64
            && counts["seasons"] == series_count as i64
            && counts["episodes"] == (series_count * EPISODES_PER_SERIES) as i64,
        "SQLite import row counts do not match the parsed snapshot"
    );
    let expected_matches = (0..series_count)
        .filter(|i| i.to_string().starts_with('9'))
        .count();
    let query = CatalogQuery {
        provider_id: Some("benchmark".into()),
        content_type: Some("series".into()),
        search: "Show 9".into(),
        limit: PAGE_SIZE,
        ..Default::default()
    };
    let mut search_times = Vec::with_capacity(RUNS);
    let first = store.catalog(&query)?; // Warm page/count statements and OS cache.
    for _ in 0..RUNS {
        let start = Instant::now();
        let page = store.catalog(&query)?;
        search_times.push(start.elapsed());
        ensure!(
            page.total == expected_matches && page.items.len() == expected_matches.min(PAGE_SIZE),
            "Search count or page bound is incorrect"
        );
    }
    let second = store.catalog(&CatalogQuery {
        offset: PAGE_SIZE,
        ..query
    })?;
    ensure!(
        second.total == expected_matches
            && second.items.len() == expected_matches.saturating_sub(PAGE_SIZE).min(PAGE_SIZE),
        "The second page has incorrect bounds"
    );
    ensure!(
        first
            .items
            .iter()
            .all(|a| second.items.iter().all(|b| a.id != b.id)),
        "Consecutive pages overlap"
    );
    println!(
        "Synthetic M3U: {series_count} series, {} episodes, {} bytes",
        series_count * EPISODES_PER_SERIES,
        input.len()
    );
    println!(
        "Parser: {:.3} ms median ({RUNS} runs after one warmup)",
        milliseconds(median(parse_times))
    );
    println!(
        "SQLite initial import: {:.3} ms (one committed transaction)",
        milliseconds(initial_import)
    );
    println!(
        "SQLite refresh: {:.3} ms median ({RUNS} committed transactions after initial import)",
        milliseconds(median(refresh_times))
    );
    println!(
        "SQLite paged search: {:.3} ms median ({RUNS} warm queries; total count + up to {PAGE_SIZE} rows)",
        milliseconds(median(search_times))
    );
    println!(
        "Verified: {} catalog items, {} seasons, {} episodes; {expected_matches} search matches; integrity and foreign keys passed",
        counts["catalog_items"], counts["seasons"], counts["episodes"]
    );
    println!(
        "No network requests or installed Vela data were used. Temporary database will be removed."
    );
    Ok(())
}

fn main() -> Result<()> {
    let args: Vec<_> = std::env::args().skip(1).collect();
    ensure!(args.len() <= 1, "Usage: benchmark_import [series-count]");
    let series_count = args
        .first()
        .map(|s| s.parse::<usize>())
        .transpose()
        .context("series-count must be an integer")?
        .unwrap_or(10_000);
    ensure!(
        (1..=100_000).contains(&series_count),
        "series-count must be between 1 and 100000"
    );
    let directory = TemporaryDirectory::create()?;
    let result = benchmark(&directory.0.join("catalog.sqlite"), series_count);
    let cleanup = directory.cleanup();
    result?;
    cleanup
}
