//! Blocking provider workers. Call these functions on a background thread, never
//! in the UI's paint/event callback. Provider errors are deliberately redacted.
mod http;
pub mod m3u;
pub mod xmltv;
pub mod xtream;

use crate::models::{CatalogItem, EpgProgram, ImportSnapshot, Provider, SeriesDetails};
use anyhow::{Result, anyhow, bail};
use std::{
    fs::File,
    io::Cursor,
    time::{Duration, Instant},
};
pub use xtream::resolve_stream_url;

/// Progress for actual work on the importing thread. Stages never contain
/// provider addresses or account information. Byte totals describe raw source
/// bytes; decompression and parsing are separate stages.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ImportProgress {
    pub stage: String,
    pub completed: u64,
    pub total: Option<u64>,
    pub unit: String,
}

/// Bounds callback traffic while always reporting stage start and final count.
struct ProgressMeter<'a> {
    callback: &'a mut dyn FnMut(ImportProgress),
    stage: &'a str,
    unit: &'a str,
    total: Option<u64>,
    step: u64,
    last_count: u64,
    last_at: Instant,
}
impl<'a> ProgressMeter<'a> {
    fn new(
        stage: &'a str,
        unit: &'a str,
        total: Option<u64>,
        step: u64,
        callback: &'a mut dyn FnMut(ImportProgress),
    ) -> Self {
        let mut meter = Self {
            callback,
            stage,
            unit,
            total,
            step,
            last_count: 0,
            last_at: Instant::now(),
        };
        meter.emit(0);
        meter
    }
    fn emit(&mut self, count: u64) {
        (self.callback)(ImportProgress {
            stage: self.stage.into(),
            completed: count,
            total: self.total,
            unit: self.unit.into(),
        });
        self.last_count = count;
        self.last_at = Instant::now();
    }
    fn set(&mut self, count: u64) {
        if count.saturating_sub(self.last_count) >= self.step
            || self.last_at.elapsed() >= Duration::from_millis(200)
        {
            self.emit(count);
        }
    }
    fn finish(&mut self, count: u64) {
        if count != self.last_count {
            self.emit(count);
        }
    }
}

pub fn import_provider(provider: &Provider) -> Result<ImportSnapshot> {
    import_provider_with_progress(provider, &mut |_| {})
}

pub fn import_provider_with_progress(
    provider: &Provider,
    progress: &mut impl FnMut(ImportProgress),
) -> Result<ImportSnapshot> {
    if provider.id.trim().is_empty() {
        bail!("Provider ID is missing");
    }
    match provider.kind.as_str() {
        "xtream" => xtream::import_with_progress(&http::client()?, provider, progress),
        "m3u" => {
            let bytes = if provider.source_kind.as_deref() == Some("file") {
                let file = File::open(&provider.source)
                    .map_err(|_| anyhow!("Local playlist file could not be read"))?;
                let length = file.metadata().ok().map(|metadata| metadata.len());
                let raw = http::read_limited_with_progress(
                    file,
                    length,
                    "Reading playlist file",
                    progress,
                )?;
                http::decode_with_progress(raw, progress)?
            } else {
                http::get_with_progress(
                    &http::client()?,
                    http::checked_url(&provider.source)?,
                    "Downloading playlist",
                    progress,
                )?
            };
            m3u::parse_with_progress(&String::from_utf8_lossy(&bytes), &provider.id, progress)
        }
        _ => bail!("Unsupported provider type"),
    }
}
pub fn fetch_series(
    provider: &Provider,
    external_id: &str,
    series_id: &str,
) -> Result<SeriesDetails> {
    if provider.kind != "xtream" {
        bail!("This provider has no separate episode catalog");
    }
    xtream::fetch_series(&http::client()?, provider, external_id, series_id)
}
pub fn fetch_movie(provider: &Provider, external_id: &str, item_id: &str) -> Result<CatalogItem> {
    if provider.kind != "xtream" {
        bail!("This provider has no separate movie details");
    }
    xtream::fetch_movie(&http::client()?, provider, external_id, item_id)
}
pub fn fetch_epg(provider: &Provider) -> Result<Vec<EpgProgram>> {
    let url = if provider.kind == "xtream" {
        xtream::authenticated_endpoint(provider, "xmltv.php")?
    } else {
        if provider.source_kind.as_deref() == Some("file") {
            bail!("No remote channel guide is configured");
        }
        let source = http::checked_url(&provider.source)?;
        let has_credentials = source.query_pairs().any(|(key, _)| key == "username")
            && source.query_pairs().any(|(key, _)| key == "password");
        if !has_credentials {
            bail!("Playlist URL does not include a channel guide source");
        }
        let mut guide = source.clone();
        let parent = source
            .path()
            .rsplit_once('/')
            .map(|(parent, _)| parent)
            .unwrap_or("");
        guide.set_path(&format!("{parent}/xmltv.php"));
        let pairs: Vec<_> = source
            .query_pairs()
            .filter(|(k, _)| matches!(k.as_ref(), "username" | "password"))
            .map(|(k, v)| (k.into_owned(), v.into_owned()))
            .collect();
        guide.set_query(None);
        guide.query_pairs_mut().extend_pairs(pairs);
        guide
    };
    let bytes = http::get(&http::client()?, url)?;
    xmltv::parse(
        Cursor::new(bytes),
        &provider.id,
        chrono::Utc::now().timestamp_millis(),
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    #[test]
    fn local_compressed_import_reports_source_bytes_then_parsed_entries() {
        let playlist = b"#EXTM3U\n#EXTINF:-1,News\nhttps://example.test/live.ts\n#EXTINF:-1,Show S01E01\nhttps://example.test/episode.mp4\n";
        let mut encoder = flate2::write::GzEncoder::new(Vec::new(), flate2::Compression::default());
        encoder.write_all(playlist).unwrap();
        let compressed = encoder.finish().unwrap();
        let mut file = tempfile::NamedTempFile::new().unwrap();
        file.write_all(&compressed).unwrap();
        let provider = Provider {
            id: "fixture".into(),
            kind: "m3u".into(),
            source_kind: Some("file".into()),
            source: file.path().to_str().unwrap().into(),
            ..Default::default()
        };
        let mut events = Vec::new();
        let snapshot =
            import_provider_with_progress(&provider, &mut |event| events.push(event)).unwrap();
        let source = events
            .iter()
            .rev()
            .find(|event| event.stage == "Reading playlist file")
            .unwrap();
        assert_eq!(
            (source.completed, source.total),
            (compressed.len() as u64, Some(compressed.len() as u64))
        );
        let parsed = events.last().unwrap();
        assert_eq!(parsed.stage, "Parsing playlist");
        assert_eq!(parsed.completed, 2);
        assert_eq!(parsed.total, None);
        assert_eq!(snapshot.items.len(), 2);
        assert_eq!(snapshot.episodes.len(), 1);
        let old_api = import_provider(&provider).unwrap();
        assert_eq!(
            serde_json::to_value(snapshot).unwrap(),
            serde_json::to_value(old_api).unwrap()
        );
    }
}
