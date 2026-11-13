use serde::{Deserialize, Serialize};

#[derive(Clone, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct Provider {
    pub id: String,
    pub name: String,
    /// SQLite-compatible provider type: `m3u` or `xtream`.
    pub kind: String,
    pub source: String,
    pub source_kind: Option<String>,
    pub username: Option<String>,
    pub password: Option<String>,
    pub is_enabled: bool,
    pub auto_refresh_enabled: bool,
    pub auto_refresh_interval_minutes: i64,
    pub last_refresh_at: Option<i64>,
}
impl std::fmt::Debug for Provider {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Provider")
            .field("id", &self.id)
            .field("kind", &self.kind)
            .finish_non_exhaustive()
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct Category {
    pub id: String,
    pub provider_id: String,
    pub content_type: String,
    pub name: String,
    pub external_id: Option<String>,
    pub item_count: i64,
    pub is_favorite: bool,
    pub sort_order: Option<i64>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct CatalogItem {
    pub id: String,
    pub provider_id: String,
    pub content_type: String,
    pub title: String,
    pub category_id: Option<String>,
    pub category_name: Option<String>,
    pub subtitle: Option<String>,
    pub description: Option<String>,
    pub artwork_url: Option<String>,
    pub stream_url: Option<String>,
    pub stream_json: Option<String>,
    pub external_id: Option<String>,
    pub year: Option<i64>,
    pub rating: Option<String>,
    pub duration_seconds: Option<i64>,
    pub epg_channel_id: Option<String>,
    pub container_extension: Option<String>,
    pub is_favorite: bool,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct Series {
    pub id: String,
    pub provider_id: String,
    pub catalog_item_id: Option<String>,
    pub external_id: Option<String>,
    pub title: String,
    pub overview: Option<String>,
    pub poster_url: Option<String>,
    pub backdrop_url: Option<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct Season {
    pub id: String,
    pub provider_id: String,
    pub series_id: String,
    pub season_number: i64,
    pub title: Option<String>,
    pub overview: Option<String>,
    pub poster_url: Option<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct Episode {
    pub id: String,
    pub provider_id: String,
    pub series_id: String,
    pub season_id: String,
    pub season_number: i64,
    pub episode_number: i64,
    pub title: String,
    pub description: Option<String>,
    pub artwork_url: Option<String>,
    pub stream_url: Option<String>,
    pub stream_json: Option<String>,
    pub external_id: Option<String>,
    pub duration_seconds: Option<i64>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct EpgProgram {
    pub provider_id: String,
    pub channel_id: String,
    pub start_at: i64,
    pub end_at: i64,
    pub title: String,
    pub description: Option<String>,
    pub category: Option<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct ImportSnapshot {
    pub provider_id: String,
    pub categories: Vec<Category>,
    pub items: Vec<CatalogItem>,
    pub series: Vec<Series>,
    pub seasons: Vec<Season>,
    pub episodes: Vec<Episode>,
    pub epg: Vec<EpgProgram>,
    pub refreshed_episode_series_ids: Vec<String>,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct SeriesDetails {
    pub series: Series,
    pub seasons: Vec<Season>,
    pub episodes: Vec<Episode>,
}

#[derive(Clone, Debug, Default)]
pub struct CatalogQuery {
    pub provider_id: Option<String>,
    pub content_type: Option<String>,
    pub category_id: Option<String>,
    pub search: String,
    pub favorites_only: bool,
    pub latest_first: bool,
    pub offset: usize,
    pub limit: usize,
}
#[derive(Clone, Debug, Default)]
pub struct CatalogPage {
    pub items: Vec<CatalogItem>,
    pub total: usize,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct PlaybackProgress {
    pub provider_id: String,
    pub catalog_key: String,
    pub item_id: String,
    pub item_type: String,
    pub title: String,
    pub subtitle: Option<String>,
    pub artwork_url: Option<String>,
    pub series_id: Option<String>,
    pub season_id: Option<String>,
    pub position_seconds: i64,
    pub duration_seconds: Option<i64>,
    pub completion_percentage: f64,
    pub completed: bool,
    pub last_watched_at: i64,
    pub watch_count: i64,
}

#[derive(Clone, Copy, Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", default)]
pub struct VolumePreferences {
    pub volume: f64,
    pub last_audible_volume: f64,
}
impl Default for VolumePreferences {
    fn default() -> Self {
        Self {
            volume: 100.0,
            last_audible_volume: 100.0,
        }
    }
}

pub type CatalogSnapshot = ImportSnapshot;
