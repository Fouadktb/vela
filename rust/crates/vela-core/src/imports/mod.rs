//! Blocking provider workers. Call these functions on a background thread, never
//! in the UI's paint/event callback. Provider errors are deliberately redacted.
mod http;
pub mod m3u;
pub mod xmltv;
pub mod xtream;

use crate::models::{CatalogItem, EpgProgram, ImportSnapshot, Provider, SeriesDetails};
use anyhow::{Result, anyhow, bail};
use std::{fs::File, io::Cursor};
pub use xtream::resolve_stream_url;

pub fn import_provider(provider: &Provider) -> Result<ImportSnapshot> {
    if provider.id.trim().is_empty() {
        bail!("Provider ID is missing");
    }
    match provider.kind.as_str() {
        "xtream" => xtream::import(&http::client()?, provider),
        "m3u" => {
            let bytes = if provider.source_kind.as_deref() == Some("file") {
                let file = File::open(&provider.source)
                    .map_err(|_| anyhow!("Local playlist file could not be read"))?;
                http::decode_if_gzip(http::read_limited(file)?)?
            } else {
                http::get(&http::client()?, http::checked_url(&provider.source)?)?
            };
            m3u::parse(&String::from_utf8_lossy(&bytes), &provider.id)
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
