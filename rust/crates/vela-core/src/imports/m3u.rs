use crate::models::{CatalogItem, Category, Episode, ImportSnapshot, Season, Series};
use anyhow::{Result, bail};
use regex::Regex;
use std::{
    collections::{BTreeMap, HashMap, HashSet},
    sync::LazyLock,
};

static ATTR: LazyLock<Regex> = LazyLock::new(|| Regex::new(r#"([\w-]+)="([^"]*)"#).unwrap());
static EPISODE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"(?i)^(.*?)\s*[-_. ]*s(\d{1,2})\s*e(\d{1,3})\b").unwrap());
static MOVIE: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"\b(movie|movies|vod|film|films|cinema)\b|\.(mp4|mkv|avi|mov|m4v)(\?|$)").unwrap()
});
static SERIES: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"\b(series|tv series)\b").unwrap());
static SLUG: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"[^a-z0-9]+").unwrap());

pub fn slug(value: &str) -> String {
    let value = SLUG
        .replace_all(&value.to_lowercase(), "-")
        .trim_matches('-')
        .to_owned();
    if value.is_empty() {
        "item".into()
    } else {
        value.chars().take(80).collect()
    }
}

/// Stable URI component encoding used by Dart's Uri.encodeComponent.
pub fn encode_component(value: &str) -> String {
    let mut result = String::new();
    for byte in value.bytes() {
        if byte.is_ascii_alphanumeric() || b"-_.!~*'()".contains(&byte) {
            result.push(byte as char);
        } else {
            result.push_str(&format!("%{byte:02X}"));
        }
    }
    result
}

pub fn category_id(provider_id: &str, kind: &str, name: &str) -> String {
    format!(
        "{provider_id}:{kind}:{}",
        encode_component(&name.trim().to_lowercase())
    )
}

fn nonempty(value: Option<&String>) -> Option<String> {
    value
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(str::to_owned)
}

struct Draft {
    name: String,
    attrs: HashMap<String, String>,
}

fn metadata(line: &str) -> Draft {
    let mut quoted = false;
    let delimiter = line.char_indices().find_map(|(i, c)| {
        if c == '"' {
            quoted = !quoted;
        }
        if c == ',' && !quoted { Some(i) } else { None }
    });
    let (raw, name) = delimiter
        .map(|i| (&line[..i], line[i + 1..].trim()))
        .unwrap_or((line, "Unnamed Channel"));
    Draft {
        name: if name.is_empty() {
            "Unnamed Channel".into()
        } else {
            name.into()
        },
        attrs: ATTR
            .captures_iter(raw)
            .map(|c| (c[1].into(), c[2].into()))
            .collect(),
    }
}

pub fn parse(input: &str, provider_id: &str) -> Result<ImportSnapshot> {
    if input.len() as u64 > super::http::MAX_IMPORT_BYTES {
        bail!("Playlist exceeds the 256 MiB import limit");
    }
    let mut snapshot = ImportSnapshot {
        provider_id: provider_id.into(),
        ..Default::default()
    };
    let mut pending = None;
    let mut slugs = HashMap::<String, usize>::new();
    let mut categories = BTreeMap::<String, Category>::new();
    let mut series = BTreeMap::<String, Series>::new();
    let mut seasons = BTreeMap::<String, Season>::new();
    let mut seen_series = HashSet::new();
    // split includes classic Mac CR as well as LF/CRLF, matching LineSplitter.
    for line in input
        .trim_start_matches('\u{feff}')
        .split(['\r', '\n'])
        .map(str::trim)
    {
        if line.is_empty() {
            continue;
        }
        if line.starts_with("#EXTINF:") {
            pending = Some(metadata(line));
            continue;
        }
        if line.starts_with('#') {
            continue;
        }
        let Some(draft) = pending.take() else {
            continue;
        };
        let title = nonempty(draft.attrs.get("tvg-name"))
            .or_else(|| nonempty(draft.attrs.get("title")))
            .unwrap_or(draft.name.clone());
        let category =
            nonempty(draft.attrs.get("group-title")).unwrap_or_else(|| "Uncategorized".into());
        let base = slug(&nonempty(draft.attrs.get("tvg-id")).unwrap_or(draft.name));
        let count = slugs.entry(base.clone()).or_default();
        *count += 1;
        let allocated = if *count == 1 {
            base
        } else {
            format!("{base}-{count}")
        };
        let episode = EPISODE.captures(&title);
        let text = format!("{title} {category} {line}").to_lowercase();
        let kind = if episode.is_some() {
            "series"
        } else if !SERIES.is_match(&text) && MOVIE.is_match(&text) {
            "movie"
        } else {
            "live"
        };
        let id = format!("{provider_id}:{kind}:{allocated}");
        let cat_id = category_id(provider_id, kind, &category);
        categories.insert(
            cat_id.clone(),
            Category {
                id: cat_id.clone(),
                provider_id: provider_id.into(),
                content_type: kind.into(),
                name: category.clone(),
                ..Default::default()
            },
        );
        let artwork = nonempty(draft.attrs.get("tvg-logo"));
        let external = nonempty(draft.attrs.get("tvg-id")).or(Some(allocated));
        if let Some(parts) = episode {
            let series_title = if parts[1].trim().is_empty() {
                "Series"
            } else {
                parts[1].trim()
            };
            let series_id = format!("{provider_id}:series:{}", slug(series_title));
            let season_number: i64 = parts[2].parse().unwrap_or(0);
            let episode_number: i64 = parts[3].parse().unwrap_or(0);
            let season_id = season_number.to_string();
            if seen_series.insert(series_id.clone()) {
                snapshot.items.push(CatalogItem {
                    id: series_id.clone(),
                    provider_id: provider_id.into(),
                    content_type: "series".into(),
                    title: series_title.into(),
                    category_id: Some(cat_id),
                    category_name: Some(category),
                    artwork_url: artwork.clone(),
                    external_id: Some(slug(series_title)),
                    ..Default::default()
                });
            }
            series.insert(
                series_id.clone(),
                Series {
                    id: series_id.clone(),
                    provider_id: provider_id.into(),
                    catalog_item_id: Some(series_id.clone()),
                    title: series_title.into(),
                    poster_url: artwork.clone(),
                    ..Default::default()
                },
            );
            seasons.insert(
                format!("{series_id}:{season_id}"),
                Season {
                    id: season_id.clone(),
                    provider_id: provider_id.into(),
                    series_id: series_id.clone(),
                    season_number,
                    title: Some(format!("Season {season_number}")),
                    ..Default::default()
                },
            );
            snapshot.episodes.push(Episode {
                id,
                provider_id: provider_id.into(),
                series_id,
                season_id,
                season_number,
                episode_number,
                title,
                artwork_url: artwork,
                stream_url: Some(line.into()),
                external_id: external,
                ..Default::default()
            });
        } else {
            let extension = url::Url::parse(line).ok().and_then(|u| {
                u.path()
                    .rsplit('.')
                    .next()
                    .filter(|s| {
                        (2..=5).contains(&s.len()) && s.bytes().all(|b| b.is_ascii_alphanumeric())
                    })
                    .map(|s| s.to_lowercase())
            });
            snapshot.items.push(CatalogItem {
                id,
                provider_id: provider_id.into(),
                content_type: kind.into(),
                title,
                category_id: Some(cat_id),
                category_name: Some(category),
                artwork_url: artwork,
                stream_url: Some(line.into()),
                external_id: external,
                epg_channel_id: nonempty(draft.attrs.get("tvg-id")),
                container_extension: extension,
                ..Default::default()
            });
        }
    }
    snapshot.categories = categories.into_values().collect();
    snapshot.series = series.into_values().collect();
    snapshot.refreshed_episode_series_ids = snapshot
        .series
        .iter()
        .map(|series| series.id.clone())
        .collect();
    snapshot.seasons = seasons.into_values().collect();
    if snapshot.items.is_empty() {
        bail!("Playlist did not contain playable items");
    }
    Ok(snapshot)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn stable_ids_quoted_commas_and_series_dedup() {
        let s = parse("\u{feff}#EXTM3U\r\n#EXTINF:-1 tvg-id=\"news\" tvg-name=\"News, World\" group-title=\"Live TV\",Fallback\r\nhttps://test/live.ts\n#EXTINF:-1,Show S01E01\nhttps://test/1.mp4\n#EXTINF:-1,Show S01E02\nhttps://test/2.mp4\n#EXTINF:-1 tvg-id=\"news\",News\nhttps://test/live2.ts", "p").unwrap();
        assert_eq!(s.items.len(), 3);
        assert_eq!(s.series.len(), 1);
        assert_eq!(s.episodes.len(), 2);
        assert_eq!(s.items[0].id, "p:live:news");
        assert_eq!(s.items[0].title, "News, World");
        assert_eq!(s.items[0].category_id.as_deref(), Some("p:live:live%20tv"));
        assert_eq!(s.items[1].id, "p:series:show");
        assert_eq!(s.items[2].id, "p:live:news-2");
        assert_eq!(s.episodes[0].id, "p:series:show-s01e01");
    }
    #[test]
    fn large_playlist_keeps_every_episode() {
        let input: String = (0..5000)
            .flat_map(|s| {
                (1..=2).map(move |e| {
                    format!("#EXTINF:-1,Show {s} S01E0{e}\nhttps://test/{s}/{e}.mp4\n")
                })
            })
            .collect();
        let snapshot = parse(&input, "p").unwrap();
        assert_eq!(snapshot.items.len(), 5000);
        assert_eq!(snapshot.episodes.len(), 10000);
    }
    #[test]
    fn category_encoding_matches_dart() {
        assert_eq!(
            category_id("p", "live", "  A/B + É  "),
            "p:live:a%2Fb%20%2B%20%C3%A9"
        );
    }
}
