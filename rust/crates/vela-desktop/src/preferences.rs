//! Pure compatibility helpers for Flutter's per-item playback track settings.
use serde_json::{Value, json};
use vela_player::Track;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Selection {
    KeepAuto,
    Off,
    Track(i64),
    /// Track discovery has not produced tracks of the requested type yet.
    Pending,
}

/// The prefix and every present scope are individually URI-component encoded,
/// exactly as PlaybackPreferencesRepository.settingsKeyFor in the Flutter app.
pub fn key(
    provider: &str,
    kind: &str,
    series: Option<&str>,
    season: Option<&str>,
    id: &str,
) -> String {
    [
        Some("playback_track_preferences"),
        Some(provider),
        Some(kind),
        series,
        season,
        Some(id),
    ]
    .into_iter()
    .flatten()
    .map(vela_core::imports::m3u::encode_component)
    .collect::<Vec<_>>()
    .join(":")
}

fn kind_names(kind: &str) -> Option<(&'static str, &'static str)> {
    match kind {
        "audio" => Some(("audio", "audio")),
        "sub" | "subtitle" => Some(("sub", "subtitle")),
        "video" => Some(("video", "video")),
        _ => None,
    }
}
fn normalized(text: &str) -> String {
    text.trim().to_lowercase()
}
fn matches_text(a: &str, b: &str) -> bool {
    normalized(a) == normalized(b)
}
fn matches_language(track: &Track, language: Option<&str>) -> bool {
    match (track.language.as_deref(), language) {
        (Some(a), Some(b)) if !a.trim().is_empty() && !b.trim().is_empty() => matches_text(a, b),
        _ => false,
    }
}

struct Preference<'a> {
    id: &'a str,
    title: &'a str,
    language: Option<&'a str>,
}
fn preference(value: &Value) -> Option<Preference<'_>> {
    let id = value.get("id")?.as_str()?;
    let title = value.get("title")?.as_str()?;
    let language = value.get("language").and_then(Value::as_str);
    // Mirrors Dart's isValid. Malformed fields do not suppress global defaults.
    if id.is_empty() && title.is_empty() && language.is_none() {
        return None;
    }
    Some(Preference {
        id,
        title,
        language,
    })
}

pub fn resolve(
    kind: &str,
    tracks: &[Track],
    raw: Option<&str>,
    default: Option<&str>,
) -> Selection {
    let Some((player_kind, json_kind)) = kind_names(kind) else {
        return Selection::KeepAuto;
    };
    let tracks: Vec<_> = tracks
        .iter()
        .filter(|track| track.kind == player_kind && track.id > 0)
        .collect();
    let value = raw.and_then(|raw| serde_json::from_str::<Value>(raw).ok());
    if let Some(pref) = value
        .as_ref()
        .and_then(|v| v.get(json_kind))
        .and_then(preference)
    {
        if matches!(normalized(pref.id).as_str(), "no" | "off") || matches_text(pref.title, "Off") {
            return Selection::Off;
        }
        if normalized(pref.id) == "auto" || (pref.id.is_empty() && matches_text(pref.title, "Auto"))
        {
            return Selection::KeepAuto;
        }
        if tracks.is_empty() {
            return Selection::Pending;
        }
        // IDs are scoped by track type. Do not parse a malformed string ID into
        // an integer (e.g. "02"), which would change legacy matching semantics.
        let selected = tracks
            .iter()
            .find(|track| track.id.to_string() == pref.id)
            .or_else(|| {
                tracks.iter().find(|track| {
                    matches_language(track, pref.language) && matches_text(&track.title, pref.title)
                })
            })
            .or_else(|| {
                tracks
                    .iter()
                    .find(|track| matches_language(track, pref.language))
            })
            .or_else(|| {
                tracks.iter().find(|track| {
                    !pref.title.trim().is_empty() && matches_text(&track.title, pref.title)
                })
            });
        if let Some(track) = selected {
            return Selection::Track(track.id);
        }
    }
    resolve_default(player_kind, &tracks, default)
}

fn resolve_default(kind: &str, tracks: &[&Track], default: Option<&str>) -> Selection {
    let value = normalized(default.unwrap_or(if kind == "sub" { "Off" } else { "Auto" }));
    match value.as_str() {
        "off" | "no" if kind == "sub" => Selection::Off,
        "" | "auto" => Selection::KeepAuto,
        "original" => tracks
            .iter()
            .find(|track| matches_text(&track.title, "Original"))
            .map(|track| Selection::Track(track.id))
            .unwrap_or(Selection::KeepAuto),
        language => {
            if tracks.is_empty() {
                return Selection::Pending;
            }
            let language_match = |track: &&&Track| {
                let lang = track
                    .language
                    .as_deref()
                    .map(normalized)
                    .unwrap_or_default();
                if language == "english" {
                    lang == "en"
                        || lang == "eng"
                        || lang == "english"
                        || lang.starts_with("en-")
                        || lang.starts_with("en_")
                } else {
                    lang == language
                }
            };
            tracks
                .iter()
                .find(language_match)
                .or_else(|| {
                    tracks
                        .iter()
                        .find(|track| matches_text(&track.title, language))
                })
                .map(|track| Selection::Track(track.id))
                .unwrap_or(Selection::KeepAuto)
        }
    }
}

/// Update one track while retaining other per-item choices and unknown fields.
/// `None` means subtitles Off, or automatic selection for audio/video.
pub fn update(raw: Option<&str>, kind: &str, track: Option<&Track>) -> String {
    let mut object = raw
        .and_then(|raw| serde_json::from_str::<Value>(raw).ok())
        .and_then(|value| value.as_object().cloned())
        .unwrap_or_default();
    if let Some((player_kind, json_kind)) = kind_names(kind) {
        let value = match track {
            Some(track) if track.kind == player_kind && track.id > 0 => {
                let mut value = json!({"id":track.id.to_string(),"title":track.title});
                if let Some(language) = &track.language {
                    value["language"] = Value::String(language.clone());
                }
                Some(value)
            }
            Some(_) => None,
            None if player_kind == "sub" => Some(json!({"id":"no","title":"Off"})),
            None => Some(json!({"id":"auto","title":"Auto"})),
        };
        if let Some(value) = value {
            object.insert(json_kind.into(), value);
        }
    }
    Value::Object(object).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    fn track(kind: &str, id: i64, title: &str, language: Option<&str>) -> Track {
        Track {
            kind: kind.into(),
            id,
            title: title.into(),
            language: language.map(str::to_owned),
            selected: false,
        }
    }
    #[test]
    fn scoped_keys_match_dart_encode_component_and_omit_only_nulls() {
        assert_eq!(
            key("p:é", "episode", Some("series/a"), Some(""), "id ?#!~*'()"),
            "playback_track_preferences:p%3A%C3%A9:episode:series%2Fa::id%20%3F%23!~*'()"
        );
        assert_eq!(
            key("p", "movie", None, None, "movie:42"),
            "playback_track_preferences:p:movie:movie%3A42"
        );
        assert_ne!(
            key("p", "episode", Some("a"), Some("1"), "42"),
            key("p", "episode", Some("b"), Some("1"), "42")
        );
    }
    #[test]
    fn actual_flutter_sqlite_preferences_restore_and_survive_merged_update() {
        let directory =
            std::env::temp_dir().join(format!("vela-track-fixture-{}", uuid::Uuid::new_v4()));
        std::fs::create_dir(&directory).unwrap();
        let path = directory.join("catalog.sqlite");
        std::fs::write(
            &path,
            include_bytes!("../../vela-core/tests/fixtures/flutter_schema4.sqlite"),
        )
        .unwrap();
        {
            let store = vela_core::Store::open(&path).unwrap();
            let stored = store
                .setting(&key("fixture", "movie", None, None, "movie"))
                .unwrap()
                .unwrap();
            let tracks = [
                track("audio", 2, "German", Some("de")),
                track("sub", 2, "English", Some("en")),
            ];
            assert_eq!(
                resolve("audio", &tracks, Some(&stored), Some("English")),
                Selection::Track(2)
            );
            let saved = update(Some(&stored), "sub", None);
            assert_eq!(
                resolve("audio", &tracks, Some(&saved), Some("Auto")),
                Selection::Track(2)
            );
            assert_eq!(
                resolve("sub", &[], Some(&saved), Some("English")),
                Selection::Off
            );
            let before: Value = serde_json::from_str(&stored).unwrap();
            let after: Value = serde_json::from_str(&saved).unwrap();
            assert_eq!(before["audio"], after["audio"]);
        }
        std::fs::remove_dir_all(directory).unwrap();
    }
    #[test]
    fn prefers_exact_ids_then_metadata_with_track_kind_scoping() {
        let tracks = [
            track("sub", 2, "English", Some("en")),
            track("audio", 2, "German", Some("de")),
            track("audio", 3, "Main", Some("en")),
            track("audio", 4, "Commentary", Some("en")),
        ];
        assert_eq!(
            resolve(
                "audio",
                &tracks,
                Some(r#"{"audio":{"id":"2","title":"English","language":"en"}}"#),
                None
            ),
            Selection::Track(2)
        );
        assert_eq!(
            resolve(
                "audio",
                &tracks,
                Some(r#"{"audio":{"id":"99","title":" Commentary ","language":" EN "}}"#),
                None
            ),
            Selection::Track(4)
        );
        assert_eq!(
            resolve(
                "audio",
                &tracks,
                Some(r#"{"audio":{"id":"99","title":"Missing","language":"en"}}"#),
                None
            ),
            Selection::Track(3)
        );
        assert_eq!(
            resolve(
                "audio",
                &tracks,
                Some(r#"{"audio":{"id":"99","title":"German"}}"#),
                None
            ),
            Selection::Track(2)
        );
    }
    #[test]
    fn malformed_preferences_use_global_defaults_without_false_id_matches() {
        let tracks = [
            track("audio", 2, "German", Some("de")),
            track("audio", 3, "Main", Some("eng")),
        ];
        for raw in [
            "not json",
            "[]",
            r#"{"audio":{"id":2,"title":"German"}}"#,
            r#"{"audio":{"id":"02","title":"Missing"}}"#,
        ] {
            assert_eq!(
                resolve("audio", &tracks, Some(raw), Some("English")),
                Selection::Track(3)
            );
        }
        assert_eq!(resolve("sub", &tracks, None, None), Selection::Off);
        assert_eq!(resolve("video", &tracks, None, None), Selection::KeepAuto);
    }
    #[test]
    fn waits_for_the_right_track_kind_and_handles_auto_off_defaults() {
        let subtitle = [track("sub", 1, "English", Some("en"))];
        assert_eq!(
            resolve(
                "audio",
                &subtitle,
                Some(r#"{"audio":{"id":"2","title":"German"}}"#),
                None
            ),
            Selection::Pending
        );
        assert_eq!(
            resolve("audio", &[], None, Some("English")),
            Selection::Pending
        );
        assert_eq!(
            resolve("audio", &[], None, Some("Original")),
            Selection::KeepAuto
        );
        assert_eq!(
            resolve(
                "sub",
                &[],
                Some(r#"{"subtitle":{"id":"auto","title":"Auto"}}"#),
                Some("Off")
            ),
            Selection::KeepAuto
        );
        assert_eq!(
            resolve(
                "sub",
                &[],
                Some(r#"{"subtitle":{"id":"no","title":"Off"}}"#),
                Some("English")
            ),
            Selection::Off
        );
        assert_eq!(
            resolve("subtitle", &subtitle, None, Some("English")),
            Selection::Track(1)
        );
    }
    #[test]
    fn updates_roundtrip_each_kind_without_erasing_other_choices() {
        let audio = track("audio", 7, "Main", Some("en-US"));
        let sub = track("sub", 8, "English CC", Some("en"));
        let video = track("video", 1, "Video 1", None);
        let raw = update(
            Some(r#"{"future_setting":{"enabled":true}}"#),
            "audio",
            Some(&audio),
        );
        let raw = update(Some(&raw), "sub", Some(&sub));
        let raw = update(Some(&raw), "video", Some(&video));
        let tracks = [audio, sub, video];
        assert_eq!(
            resolve("audio", &tracks, Some(&raw), None),
            Selection::Track(7)
        );
        assert_eq!(
            resolve("sub", &tracks, Some(&raw), None),
            Selection::Track(8)
        );
        assert_eq!(
            resolve("video", &tracks, Some(&raw), None),
            Selection::Track(1)
        );
        assert_eq!(
            serde_json::from_str::<Value>(&raw).unwrap()["future_setting"]["enabled"],
            true
        );
        assert_eq!(update(Some(&raw), "audio", Some(&tracks[1])), raw);
        assert_eq!(
            resolve(
                "audio",
                &tracks,
                Some(&update(Some(&raw), "audio", None)),
                None
            ),
            Selection::KeepAuto
        );
        assert!(
            serde_json::from_str::<Value>(&update(Some("invalid"), "sub", None))
                .unwrap()
                .is_object()
        );
    }
}
