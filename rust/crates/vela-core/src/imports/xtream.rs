use super::{http, m3u};
use crate::models::*;
use anyhow::{Result, anyhow, bail};
use reqwest::blocking::Client;
use serde_json::{Value, json};
use std::collections::{BTreeMap, BTreeSet};
use url::Url;

pub fn text(value: &Value) -> Option<String> {
    match value {
        Value::String(s) => Some(s.trim().to_owned()).filter(|s| !s.is_empty()),
        Value::Number(n) => Some(n.to_string()),
        _ => None,
    }
}
fn field(v: &Value, key: &str) -> Option<String> {
    text(&v[key])
}
fn http_url(v: &Value) -> Option<String> {
    text(v).and_then(|s| http::checked_url(&s).ok().map(|u| u.to_string()))
}
fn integer(v: &Value) -> Option<i64> {
    text(v)?.parse().ok()
}
fn positive(v: &Value) -> Option<i64> {
    integer(v).filter(|n| *n > 0)
}
fn extension(v: &Value, default: &str) -> String {
    text(v)
        .map(|s| {
            s.to_lowercase()
                .chars()
                .filter(char::is_ascii_alphanumeric)
                .collect::<String>()
        })
        .filter(|s| !s.is_empty())
        .unwrap_or(default.into())
}
fn year(v: &Value) -> Option<i64> {
    static YEAR: std::sync::LazyLock<regex::Regex> =
        std::sync::LazyLock::new(|| regex::Regex::new(r"\b(19|20)\d{2}\b").unwrap());
    let text = text(v)?;
    YEAR.find(&text)?.as_str().parse().ok()
}
fn duration(v: &Value) -> Option<i64> {
    let s = text(v)?;
    if let Ok(n) = s.parse::<i64>() {
        return Some(n).filter(|n| *n > 0);
    }
    let p = s
        .split(':')
        .map(str::parse::<i64>)
        .collect::<std::result::Result<Vec<_>, _>>()
        .ok()?;
    if !(2..=3).contains(&p.len()) || p.iter().any(|n| *n < 0) {
        return None;
    }
    p.into_iter()
        .try_fold(0i64, |n, x| n.checked_mul(60)?.checked_add(x))
}

pub fn endpoint(provider: &Provider, name: &str) -> Result<Url> {
    let mut url = http::checked_url(&provider.source)?;
    url.set_query(None);
    url.set_fragment(None);
    {
        let mut parts = url
            .path_segments_mut()
            .map_err(|_| anyhow!("Xtream server URL is invalid"))?;
        parts.pop_if_empty();
        parts.push(name);
    }
    Ok(url)
}
fn credentials(provider: &Provider) -> Result<(&str, &str)> {
    let username = provider
        .username
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("Xtream username is missing"))?;
    let password = provider
        .password
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("Xtream password is missing"))?;
    Ok((username, password))
}
pub fn authenticated_endpoint(provider: &Provider, name: &str) -> Result<Url> {
    let (username, password) = credentials(provider)?;
    let mut url = endpoint(provider, name)?;
    url.query_pairs_mut()
        .append_pair("username", username)
        .append_pair("password", password);
    Ok(url)
}
pub fn stream_url(provider: &Provider, kind: &str, id: &str, extension: &str) -> Result<String> {
    let (username, password) = credentials(provider)?;
    let mut url = http::checked_url(&provider.source)?;
    url.set_query(None);
    url.set_fragment(None);
    let folder = match kind {
        "live" => "live",
        "movie" => "movie",
        "series" | "episode" => "series",
        _ => bail!("Unsupported stream type"),
    };
    {
        let mut path = url
            .path_segments_mut()
            .map_err(|_| anyhow!("Xtream server URL is invalid"))?;
        path.pop_if_empty();
        path.push(folder)
            .push(username)
            .push(password)
            .push(&format!("{id}.{extension}"));
    }
    Ok(url.to_string())
}
pub fn resolve_stream_url(provider: &Provider, stream_json: &str, kind: &str) -> Result<String> {
    let data: Value = serde_json::from_str(stream_json)
        .map_err(|_| anyhow!("Saved stream metadata is invalid"))?;
    let id = field(&data, "streamId").ok_or_else(|| anyhow!("Saved stream ID is missing"))?;
    let ext = extension(
        &data["containerExtension"],
        if kind == "live" { "ts" } else { "mp4" },
    );
    stream_url(provider, kind, &id, &ext)
}
fn stream_json(id: &str, extension: &str) -> String {
    json!({"providerType":"xtream","streamId":id,"containerExtension":extension}).to_string()
}

fn check_response(data: &Value) -> Result<()> {
    let user = &data["user_info"];
    if text(&user["auth"]).as_deref() == Some("0")
        || matches!(
            text(&user["status"]).map(|s| s.to_lowercase()).as_deref(),
            Some("disabled" | "expired")
        )
    {
        bail!("Xtream login failed. Check account details and server URL.");
    }
    let failed = |v: &Value| {
        v == &Value::Bool(false)
            || text(v).is_some_and(|s| s == "0" || s.eq_ignore_ascii_case("false"))
    };
    if field(data, "error").is_some()
        || field(data, "message").is_some()
        || failed(&data["result"])
        || failed(&data["success"])
        || matches!(
            field(data, "status").map(|s| s.to_lowercase()).as_deref(),
            Some("error" | "failed" | "failure")
        )
    {
        bail!("Xtream server returned an error response");
    }
    Ok(())
}
fn request(
    client: &Client,
    provider: &Provider,
    action: Option<&str>,
    extra: Option<(&str, &str)>,
) -> Result<Value> {
    request_with_progress(
        client,
        provider,
        action,
        extra,
        "Downloading provider data",
        &mut |_| {},
    )
}

fn request_with_progress(
    client: &Client,
    provider: &Provider,
    action: Option<&str>,
    extra: Option<(&str, &str)>,
    stage: &str,
    progress: &mut dyn FnMut(super::ImportProgress),
) -> Result<Value> {
    let mut url = authenticated_endpoint(provider, "player_api.php")?;
    if let Some(action) = action {
        url.query_pairs_mut().append_pair("action", action);
    }
    if let Some((key, value)) = extra {
        url.query_pairs_mut().append_pair(key, value);
    }
    let bytes = http::get_with_progress(client, url, stage, progress)?;
    let data: Value = serde_json::from_slice(&bytes)
        .map_err(|_| anyhow!("Xtream server returned invalid JSON"))?;
    check_response(&data)?;
    Ok(data)
}
fn list_with_progress(
    client: &Client,
    p: &Provider,
    action: &str,
    stage: &str,
    progress: &mut dyn FnMut(super::ImportProgress),
) -> Result<Vec<Value>> {
    let data = request_with_progress(client, p, Some(action), None, stage, progress)?;
    data.as_array()
        .cloned()
        .ok_or_else(|| anyhow!("Xtream server returned an unexpected catalog response"))
}

pub fn import(client: &Client, provider: &Provider) -> Result<ImportSnapshot> {
    import_with_progress(client, provider, &mut |_| {})
}

pub fn import_with_progress(
    client: &Client,
    provider: &Provider,
    progress: &mut dyn FnMut(super::ImportProgress),
) -> Result<ImportSnapshot> {
    match import_api(client, provider, progress) {
        Ok(snapshot) => Ok(snapshot),
        Err(error) if error.downcast_ref::<http::HttpStatusError>().is_some() => {
            // Match the legacy app: some providers reject player_api.php while
            // allowing their generated playlist endpoint. Login/JSON errors do
            // not trigger this fallback and cannot silently change catalog IDs.
            let mut url = authenticated_endpoint(provider, "get.php")?;
            url.query_pairs_mut()
                .append_pair("type", "m3u_plus")
                .append_pair("output", "ts");
            let bytes =
                http::get_with_progress(client, url, "Downloading fallback playlist", progress)?;
            m3u::parse_with_progress(&String::from_utf8_lossy(&bytes), &provider.id, progress)
        }
        Err(error) => Err(error),
    }
}

fn import_api(
    client: &Client,
    provider: &Provider,
    progress: &mut dyn FnMut(super::ImportProgress),
) -> Result<ImportSnapshot> {
    let account =
        request_with_progress(client, provider, None, None, "Checking account", progress)?;
    if !account.is_object() {
        bail!("Xtream server returned an unexpected account response");
    }
    let mut snapshot = ImportSnapshot {
        provider_id: provider.id.clone(),
        ..Default::default()
    };
    for (kind, categories_action, streams_action, id_key) in [
        (
            "live",
            "get_live_categories",
            "get_live_streams",
            "stream_id",
        ),
        (
            "movie",
            "get_vod_categories",
            "get_vod_streams",
            "stream_id",
        ),
        ("series", "get_series_categories", "get_series", "series_id"),
    ] {
        let label = match kind {
            "live" => "live channels",
            "movie" => "movies",
            _ => "series",
        };
        let category_stage = format!("Downloading {label} categories");
        let stream_stage = format!("Downloading {label}");
        // Two requests at a time keeps slow category endpoints from serializing
        // the catalog import without flooding providers with parallel requests.
        // Category progress crosses the thread through a bounded channel; the
        // caller's FnMut is invoked only on the importing thread and need not
        // implement Send. Dropping intermediate events never blocks networking.
        let (sender, receiver) = std::sync::mpsc::sync_channel(8);
        let (category_response, streams) = std::thread::scope(|scope| {
            let categories = scope.spawn(|| {
                let mut final_event = None;
                let result = request_with_progress(
                    client,
                    provider,
                    Some(categories_action),
                    None,
                    &category_stage,
                    &mut |event| {
                        final_event = Some(event.clone());
                        let _ = sender.try_send(event);
                    },
                );
                (result, final_event)
            });
            let streams = list_with_progress(
                client,
                provider,
                streams_action,
                &stream_stage,
                &mut |event| {
                    for category_event in receiver.try_iter() {
                        progress(category_event);
                    }
                    progress(event);
                },
            );
            // A slow category endpoint may outlive the stream request. Keep
            // forwarding its real byte progress while waiting for completion.
            while !categories.is_finished() {
                if let Ok(event) = receiver.recv_timeout(std::time::Duration::from_millis(50)) {
                    progress(event);
                }
            }
            let categories = categories
                .join()
                .map_err(|_| anyhow!("Catalog import worker failed"))?;
            for event in receiver.try_iter() {
                progress(event);
            }
            // Retain the exact final byte count even if the channel was full.
            if let Some(event) = categories.1 {
                progress(event);
            }
            Ok::<_, anyhow::Error>((categories.0?, streams?))
        })?;
        let categories = category_response.as_array().cloned().unwrap_or_default();
        let mut names = BTreeMap::new();
        let parse_category_stage = format!("Reading {label} categories");
        let category_count = categories.len() as u64;
        let mut category_meter = super::ProgressMeter::new(
            &parse_category_stage,
            "categories",
            Some(category_count),
            256,
            progress,
        );
        for (index, c) in categories.into_iter().enumerate() {
            if let (Some(id), Some(name)) = (field(&c, "category_id"), field(&c, "category_name")) {
                names.insert(id.clone(), name.clone());
                snapshot.categories.push(Category {
                    id: m3u::category_id(&provider.id, kind, &name),
                    provider_id: provider.id.clone(),
                    content_type: kind.into(),
                    name,
                    external_id: Some(id),
                    ..Default::default()
                });
            }
            category_meter.set(index as u64 + 1);
        }
        category_meter.finish(category_count);
        let parse_stream_stage = format!("Reading {label}");
        let stream_count = streams.len() as u64;
        let mut meter = super::ProgressMeter::new(
            &parse_stream_stage,
            "items",
            Some(stream_count),
            256,
            progress,
        );
        for (index, stream) in streams.into_iter().enumerate() {
            let Some(external_id) = field(&stream, id_key) else {
                meter.set(index as u64 + 1);
                continue;
            };
            let id = format!("{}:{kind}:{external_id}", provider.id);
            let title = field(&stream, "name").unwrap_or_else(|| {
                format!(
                    "{} {external_id}",
                    match kind {
                        "live" => "Channel",
                        "movie" => "Movie",
                        _ => "Series",
                    }
                )
            });
            let category_name = field(&stream, "category_id")
                .and_then(|k| names.get(&k).cloned())
                .or_else(|| {
                    if kind == "live" {
                        field(&stream, "category_name")
                    } else {
                        None
                    }
                })
                .unwrap_or("Uncategorized".into());
            let ext = extension(
                &stream["container_extension"],
                if kind == "live" { "ts" } else { "mp4" },
            );
            let artwork = http_url(
                &stream[if kind == "series" {
                    "cover"
                } else {
                    "stream_icon"
                }],
            );
            let is_series = kind == "series";
            snapshot.items.push(CatalogItem {
                id: id.clone(),
                provider_id: provider.id.clone(),
                content_type: kind.into(),
                title: title.clone(),
                category_id: Some(m3u::category_id(&provider.id, kind, &category_name)),
                category_name: Some(category_name),
                artwork_url: artwork.clone(),
                external_id: Some(external_id.clone()),
                epg_channel_id: field(&stream, "epg_channel_id"),
                year: year(&stream["year"]).or_else(|| year(&stream["releaseDate"])),
                rating: field(&stream, "rating"),
                stream_url: if is_series {
                    None
                } else {
                    Some(stream_url(provider, kind, &external_id, &ext)?)
                },
                stream_json: if is_series {
                    None
                } else {
                    Some(stream_json(&external_id, &ext))
                },
                container_extension: if is_series { None } else { Some(ext) },
                ..Default::default()
            });
            if is_series {
                snapshot.series.push(Series {
                    id: id.clone(),
                    provider_id: provider.id.clone(),
                    catalog_item_id: Some(id),
                    external_id: Some(external_id),
                    title,
                    poster_url: artwork,
                    ..Default::default()
                });
            }
            meter.set(index as u64 + 1);
        }
        meter.finish(stream_count);
    }
    if snapshot.items.is_empty() {
        bail!("Provider did not return playable items");
    }
    Ok(snapshot)
}

pub fn fetch_series(
    client: &Client,
    provider: &Provider,
    external_id: &str,
    series_id: &str,
) -> Result<SeriesDetails> {
    let data = request(
        client,
        provider,
        Some("get_series_info"),
        Some(("series_id", external_id)),
    )?;
    parse_series(provider, external_id, series_id, &data)
}

pub fn parse_series(
    provider: &Provider,
    external_id: &str,
    series_id: &str,
    data: &Value,
) -> Result<SeriesDetails> {
    check_response(data)?;
    let info = &data["info"];
    let first_url = |v: &Value| {
        v.as_array()
            .and_then(|a| a.iter().find_map(http_url))
            .or_else(|| http_url(v))
    };
    let mut details = SeriesDetails {
        series: Series {
            id: series_id.into(),
            provider_id: provider.id.clone(),
            catalog_item_id: Some(series_id.into()),
            external_id: Some(external_id.into()),
            title: field(info, "name")
                .or_else(|| field(info, "title"))
                .or_else(|| field(data, "name"))
                .unwrap_or(format!("Series {external_id}")),
            overview: field(info, "plot")
                .or_else(|| field(info, "description"))
                .or_else(|| field(info, "overview")),
            poster_url: http_url(&info["cover"])
                .or_else(|| http_url(&info["movie_image"]))
                .or_else(|| http_url(&data["cover"])),
            backdrop_url: first_url(&info["backdrop_path"])
                .or_else(|| first_url(&info["backdrop"]))
                .or_else(|| first_url(&data["backdrop_path"])),
        },
        ..Default::default()
    };
    let mut seasons = BTreeMap::new();
    if let Some(list) = data["seasons"].as_array() {
        for season in list {
            let number = positive(&season["season_number"])
                .or_else(|| positive(&season["season"]))
                .or_else(|| positive(&season["id"]))
                .unwrap_or(1);
            seasons.insert(
                number,
                Season {
                    id: number.to_string(),
                    provider_id: provider.id.clone(),
                    series_id: series_id.into(),
                    season_number: number,
                    title: field(season, "name"),
                    overview: field(season, "overview"),
                    poster_url: http_url(&season["cover"]),
                },
            );
        }
    }
    let mut episode_groups = Vec::new();
    match &data["episodes"] {
        Value::Array(list) => episode_groups.push((1, list)),
        Value::Object(groups) => {
            for (season, list) in groups {
                if let Some(list) = list.as_array() {
                    episode_groups.push((
                        season.parse::<i64>().ok().filter(|n| *n > 0).unwrap_or(1),
                        list,
                    ));
                }
            }
        }
        _ => bail!("Xtream server returned incomplete series information"),
    }
    let mut seen = BTreeSet::new();
    for (fallback, list) in episode_groups {
        for episode in list {
            let Some(external_id) = field(episode, "id") else {
                continue;
            };
            let season = positive(&episode["season"])
                .or_else(|| positive(&episode["season_number"]))
                .unwrap_or(fallback);
            if !seen.insert((season, external_id.clone())) {
                continue;
            }
            let number = positive(&episode["episode_num"]).unwrap_or(0);
            let meta = &episode["info"];
            let ext = extension(&episode["container_extension"], "mp4");
            seasons.entry(season).or_insert_with(|| Season {
                id: season.to_string(),
                provider_id: provider.id.clone(),
                series_id: series_id.into(),
                season_number: season,
                title: Some(format!("Season {season}")),
                ..Default::default()
            });
            details.episodes.push(Episode {
                id: format!("{}:episode:{external_id}", provider.id),
                provider_id: provider.id.clone(),
                series_id: series_id.into(),
                season_id: season.to_string(),
                season_number: season,
                episode_number: number,
                title: field(episode, "title").unwrap_or_else(|| {
                    format!(
                        "Episode {}",
                        if number == 0 {
                            external_id.clone()
                        } else {
                            number.to_string()
                        }
                    )
                }),
                description: field(meta, "plot").or_else(|| field(meta, "description")),
                artwork_url: http_url(&meta["movie_image"]),
                duration_seconds: duration(&meta["duration_secs"])
                    .or_else(|| duration(&meta["duration"])),
                stream_url: Some(stream_url(provider, "episode", &external_id, &ext)?),
                stream_json: Some(stream_json(&external_id, &ext)),
                external_id: Some(external_id),
            });
        }
    }
    if details.episodes.is_empty() {
        bail!("Xtream server returned incomplete series information");
    }
    details.seasons = seasons.into_values().collect();
    details
        .episodes
        .sort_by_key(|e| (e.season_number, e.episode_number));
    Ok(details)
}

pub fn fetch_movie(
    client: &Client,
    provider: &Provider,
    external_id: &str,
    item_id: &str,
) -> Result<CatalogItem> {
    let data = request(
        client,
        provider,
        Some("get_vod_info"),
        Some(("vod_id", external_id)),
    )?;
    let info = &data["info"];
    let movie = &data["movie_data"];
    let ext = extension(&movie["container_extension"], "mp4");
    Ok(CatalogItem {
        id: item_id.into(),
        provider_id: provider.id.clone(),
        content_type: "movie".into(),
        title: field(info, "name")
            .or_else(|| field(info, "title"))
            .or_else(|| field(movie, "name"))
            .unwrap_or_default(),
        description: field(info, "plot")
            .or_else(|| field(info, "description"))
            .or_else(|| field(info, "overview")),
        artwork_url: http_url(&info["movie_image"])
            .or_else(|| http_url(&info["cover_big"]))
            .or_else(|| http_url(&info["cover"]))
            .or_else(|| http_url(&movie["stream_icon"])),
        rating: field(info, "rating"),
        year: year(&info["releasedate"])
            .or_else(|| year(&info["releaseDate"]))
            .or_else(|| year(&info["year"])),
        duration_seconds: duration(&info["duration_secs"]).or_else(|| duration(&info["duration"])),
        external_id: Some(external_id.into()),
        stream_url: Some(stream_url(provider, "movie", external_id, &ext)?),
        stream_json: Some(stream_json(external_id, &ext)),
        container_extension: Some(ext),
        ..Default::default()
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    fn provider() -> Provider {
        Provider {
            id: "p".into(),
            source: "https://example.test/base/".into(),
            username: Some("u/name".into()),
            password: Some("p?&word".into()),
            ..Default::default()
        }
    }
    #[test]
    fn encodes_credentials_and_preserves_base_path() {
        let p = provider();
        let url = stream_url(&p, "movie", "42", "mkv").unwrap();
        assert_eq!(
            url,
            "https://example.test/base/movie/u%2Fname/p%3F&word/42.mkv"
        );
        let api = authenticated_endpoint(&p, "player_api.php").unwrap();
        let pairs: std::collections::HashMap<_, _> = api.query_pairs().into_owned().collect();
        assert_eq!(pairs["password"], "p?&word");
        assert_eq!(api.path(), "/base/player_api.php");
    }
    #[test]
    fn parses_mixed_episode_ids_and_keeps_legacy_keys() {
        let data = json!({"info":{"name":"Show"},"episodes":{"2":[{"id":42,"episode_num":"3","title":"Episode","container_extension":"mkv","info":{"duration":"01:02:03"}}]}});
        let details = parse_series(&provider(), "99", "p:series:99", &data).unwrap();
        assert_eq!(details.episodes[0].id, "p:episode:42");
        assert_eq!(details.episodes[0].season_id, "2");
        assert_eq!(details.episodes[0].duration_seconds, Some(3723));
        assert_eq!(details.seasons[0].season_number, 2);
    }
    #[test]
    fn metadata_normalization_matches_legacy_boundaries() {
        assert_eq!(year(&json!("2026-11-13")), Some(2026));
        assert_eq!(year(&json!("20261113")), None);
        assert_eq!(duration(&json!("00:00")), Some(0));
        assert_eq!(duration(&json!(0)), None);
        assert_eq!(duration(&json!("-1:00")), None);
    }
    #[test]
    fn never_echoes_account_response_errors() {
        let data = json!({"error":"password secret URL"});
        let error = check_response(&data).unwrap_err().to_string();
        assert!(!error.contains("secret"));
        assert!(check_response(&json!({"user_info":{"auth":"0"}})).is_err());
        assert!(check_response(&json!({"success":false})).is_err());
    }
}

#[cfg(test)]
mod integration_tests {
    use super::*;
    use std::{
        io::{BufRead, BufReader, Write},
        net::TcpListener,
        thread,
        time::{Duration, Instant},
    };

    fn server(responses: Vec<(u16, String)>) -> (Provider, thread::JoinHandle<Vec<String>>) {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        listener.set_nonblocking(true).unwrap();
        let address = listener.local_addr().unwrap();
        let worker = thread::spawn(move || {
            let mut targets = Vec::new();
            let deadline = Instant::now() + Duration::from_secs(10);
            let mut responses: Vec<_> = responses.into_iter().enumerate().collect();
            while !responses.is_empty() {
                let mut stream = loop {
                    match listener.accept() {
                        Ok((stream, _)) => break stream,
                        Err(e) if e.kind() == std::io::ErrorKind::WouldBlock => {
                            assert!(
                                Instant::now() < deadline,
                                "Provider did not make the expected request"
                            );
                            thread::sleep(Duration::from_millis(2));
                        }
                        Err(e) => panic!("Test server failed: {e}"),
                    }
                };
                // Accepted sockets can inherit nonblocking mode on macOS.
                // The fixture reader waits for a complete HTTP request line.
                stream.set_nonblocking(false).unwrap();
                stream
                    .set_read_timeout(Some(Duration::from_secs(5)))
                    .unwrap();
                let mut reader = BufReader::new(stream.try_clone().unwrap());
                let mut line = String::new();
                reader.read_line(&mut line).unwrap();
                let target = line.split_whitespace().nth(1).unwrap().to_owned();
                let action = Url::parse(&format!("http://localhost{target}"))
                    .unwrap()
                    .query_pairs()
                    .find(|(key, _)| key == "action")
                    .map(|(_, v)| v.into_owned());
                let expected_index = match action.as_deref() {
                    Some("get_live_categories") => 1,
                    Some("get_live_streams") => 2,
                    Some("get_vod_categories") => 3,
                    Some("get_vod_streams") => 4,
                    Some("get_series_categories") => 5,
                    Some("get_series") => 6,
                    _ => {
                        if target.starts_with("/base/get.php") {
                            1
                        } else {
                            0
                        }
                    }
                };
                let index = responses
                    .iter()
                    .position(|(index, _)| *index == expected_index)
                    .unwrap();
                let (_, (status, body)) = responses.remove(index);
                targets.push(target);
                loop {
                    line.clear();
                    reader.read_line(&mut line).unwrap();
                    if line == "\r\n" || line.is_empty() {
                        break;
                    }
                }
                write!(stream,"HTTP/1.1 {status} Test\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",body.len()).unwrap();
            }
            targets
        });
        (
            Provider {
                id: "legacy-provider".into(),
                kind: "xtream".into(),
                source: format!("http://{address}/base"),
                username: Some("account".into()),
                password: Some("credential&value".into()),
                ..Default::default()
            },
            worker,
        )
    }
    #[test]
    fn imports_real_http_api_and_preserves_category_and_item_keys() {
        let (p, server) = server(vec![
            (
                200,
                json!({"user_info":{"auth":1,"status":"Active"}}).to_string(),
            ),
            (
                200,
                json!([{"category_id":1,"category_name":"Live TV"}]).to_string(),
            ),
            (
                200,
                json!([{"stream_id":"42","name":"News","category_id":"1","epg_channel_id":"news"}])
                    .to_string(),
            ),
            (200, "[]".into()),
            (
                200,
                json!([{"stream_id":43,"name":"Movie","container_extension":"mkv"}]).to_string(),
            ),
            (200, "[]".into()),
            (200, json!([{"series_id":44,"name":"Series"}]).to_string()),
        ]);
        let mut progress = Vec::new();
        let callback_thread = std::thread::current().id();
        let snapshot = import_with_progress(&http::client().unwrap(), &p, &mut |event| {
            assert_eq!(std::thread::current().id(), callback_thread);
            progress.push(event);
        })
        .unwrap();
        for stage in [
            "Checking account",
            "Downloading live channels categories",
            "Downloading live channels",
            "Downloading movies categories",
            "Downloading movies",
            "Downloading series categories",
            "Downloading series",
        ] {
            let final_event = progress
                .iter()
                .rev()
                .find(|event| event.stage == stage)
                .unwrap();
            assert!(final_event.completed > 0);
            assert_eq!(final_event.total, Some(final_event.completed));
            assert_eq!(final_event.unit, "bytes");
        }
        for (stage, total) in [
            ("Reading live channels categories", 1),
            ("Reading live channels", 1),
            ("Reading movies categories", 0),
            ("Reading movies", 1),
            ("Reading series categories", 0),
            ("Reading series", 1),
        ] {
            let final_event = progress
                .iter()
                .rev()
                .find(|event| event.stage == stage)
                .unwrap();
            assert_eq!(
                (final_event.completed, final_event.total),
                (total, Some(total))
            );
        }
        assert!(
            progress
                .iter()
                .all(|event| !event.stage.contains("account=")
                    && !event.stage.contains("credential")
                    && !event.stage.contains("http"))
        );
        let targets = server.join().unwrap();
        assert_eq!(targets.len(), 7);
        assert!(
            targets
                .iter()
                .all(|t| t.contains("password=credential%26value"))
        );
        assert_eq!(
            snapshot
                .items
                .iter()
                .map(|i| i.id.as_str())
                .collect::<Vec<_>>(),
            [
                "legacy-provider:live:42",
                "legacy-provider:movie:43",
                "legacy-provider:series:44"
            ]
        );
        assert_eq!(
            snapshot.items[0].category_id.as_deref(),
            Some("legacy-provider:live:live%20tv")
        );
        assert!(
            snapshot.items[1]
                .stream_url
                .as_ref()
                .unwrap()
                .ends_with("/movie/account/credential&value/43.mkv")
        );
        assert_eq!(
            snapshot.series[0].catalog_item_id.as_deref(),
            Some("legacy-provider:series:44")
        );
    }
    #[test]
    fn http_rejection_falls_back_to_generated_playlist() {
        let (p, server) = server(vec![
            (403, "denied".into()),
            (
                200,
                "#EXTM3U\n#EXTINF:-1 tvg-id=\"n\",News\nhttps://example.test/live.ts".into(),
            ),
        ]);
        let snapshot = import(&http::client().unwrap(), &p).unwrap();
        let targets = server.join().unwrap();
        assert_eq!(snapshot.items[0].id, "legacy-provider:live:n");
        assert!(targets[1].starts_with("/base/get.php?"));
        assert!(targets[1].contains("type=m3u_plus"));
    }
    #[test]
    fn bad_login_never_falls_back_or_exposes_credentials() {
        let (p, server) = server(vec![(
            200,
            json!({"user_info":{"auth":"0","status":"Expired"}}).to_string(),
        )]);
        let error = import(&http::client().unwrap(), &p)
            .unwrap_err()
            .to_string();
        assert_eq!(server.join().unwrap().len(), 1);
        assert!(!error.contains("credential"));
    }
}
