mod navigation;
mod player;
mod views;
use crate::worker::{Command, Event, PlaybackTarget, ViewData, Worker};
use eframe::{
    egui::{self, Color32, RichText, Vec2},
    glow,
};
use std::{
    collections::BTreeMap,
    path::PathBuf,
    time::{Duration, Instant},
};
use vela_core::*;
use vela_player::Player;

const BG: Color32 = Color32::from_rgb(12, 13, 14);
const PANEL: Color32 = Color32::from_rgb(21, 23, 25);
const ACCENT: Color32 = Color32::from_rgb(231, 184, 91);
const MUTED: Color32 = Color32::from_rgb(169, 163, 154);
const PAGE_SIZE: usize = 60;

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
enum Section {
    Home,
    Live,
    Movies,
    Series,
    Favorites,
    Recent,
    Guide,
    Settings,
}
impl Section {
    fn label(self) -> &'static str {
        match self {
            Self::Home => "Home",
            Self::Live => "Live TV",
            Self::Movies => "Movies",
            Self::Series => "Series",
            Self::Favorites => "Favorites",
            Self::Recent => "Recent",
            Self::Guide => "TV guide",
            Self::Settings => "Settings",
        }
    }
    fn kind(self) -> Option<String> {
        match self {
            Self::Live | Self::Guide => Some("live".into()),
            Self::Movies => Some("movie".into()),
            Self::Series => Some("series".into()),
            _ => None,
        }
    }
}

pub struct VelaApp {
    window_sized: bool,
    update_status: Option<vela_core::updates::ReleaseInfo>,
    update_error: Option<String>,
    checking_update: bool,
    artwork: crate::artwork::Artwork,
    worker: Worker,
    player: Option<Player>,
    player_error: Option<String>,
    fatal: Option<String>,
    db_path: PathBuf,
    ready: bool,
    initialized: bool,
    section: Section,
    browsing_memory: navigation::BrowsingMemory,
    restore_selection: bool,
    query: CatalogQuery,
    token: u64,
    loading: bool,
    providers: Vec<Provider>,
    categories: Vec<Category>,
    page: CatalogPage,
    history: Vec<PlaybackProgress>,
    latest_movies: Vec<CatalogItem>,
    latest_series: Vec<CatalogItem>,
    home_favorites: Vec<CatalogItem>,
    home_continue: Vec<(CatalogItem, PlaybackProgress)>,
    global_search: Option<crate::worker::GlobalSearchResults>,
    home_selected: Option<CatalogItem>,
    selected_catalog: Option<CatalogItem>,
    category_sidebar_width: f32,
    category_search: String,
    live_guide_mode: bool,
    settings_selected_provider: Option<String>,
    settings_adding_provider: bool,
    settings: BTreeMap<String, String>,
    error: Option<String>,
    importing: bool,
    import_jobs: BTreeMap<String, (String, String, imports::ImportProgress)>,
    search_changed: Option<Instant>,
    provider_form: Option<Provider>,
    provider_password_visible: bool,
    delete_provider: Option<Provider>,
    details: Option<CatalogItem>,
    detail_positions: Vec<PlaybackProgress>,
    detail_loading: bool,
    detail_error: Option<String>,
    episodes: Vec<Episode>,
    guide: Vec<EpgProgram>,
    guide_day: i64,
    playing: Option<PlaybackTarget>,
    volume: VolumePreferences,
    controls_last_activity: Instant,
    controls_hidden: bool,
    recent_live_expanded: bool,
    recent_live_channels: Vec<CatalogItem>,
    recent_live_loading: bool,
    recent_live_error: Option<String>,
    seek_position: Option<f64>,
    space_hold: player::SpaceHold,
    player_surface_focus: Option<egui::Id>,
    playback_episodes: Vec<Episode>,
    playback_positions: Vec<PlaybackProgress>,
    rail_scrolled_to: Option<String>,
    ended_handled: bool,
    seek_indicator: Option<(String, Instant)>,
    last_progress: Instant,
    fullscreen: bool,
    speed: f64,
    selected_track: BTreeMap<String, String>,
    confirm_clear_history: bool,
    confirm_clear_provider_history: Option<String>,
    confirm_clear_cache: bool,
    confirm_reset_data: bool,
    sidebar_pinned: bool,
    sidebar_width: f32,
}

impl VelaApp {
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        crate::theme::install(&cc.egui_ctx);
        let (player, player_error) = match Player::new(cc) {
            Ok(p) => (Some(p), None),
            Err(error) => (None, Some(error.to_string())),
        };
        Self {
            window_sized: false,
            update_status: None,
            update_error: None,
            checking_update: true,
            artwork: crate::artwork::Artwork::new(cc.egui_ctx.clone()),
            worker: Worker::new(cc.egui_ctx.clone()),
            player,
            player_error,
            fatal: None,
            db_path: PathBuf::new(),
            ready: false,
            initialized: false,
            section: Section::Home,
            browsing_memory: navigation::BrowsingMemory::default(),
            restore_selection: false,
            query: CatalogQuery {
                limit: PAGE_SIZE,
                ..Default::default()
            },
            token: 0,
            loading: true,
            providers: vec![],
            categories: vec![],
            page: CatalogPage::default(),
            history: vec![],
            latest_movies: vec![],
            latest_series: vec![],
            home_favorites: vec![],
            home_continue: vec![],
            global_search: None,
            home_selected: None,
            selected_catalog: None,
            category_sidebar_width: 280.0,
            category_search: String::new(),
            live_guide_mode: false,
            settings_selected_provider: None,
            settings_adding_provider: false,
            settings: BTreeMap::new(),
            error: None,
            importing: false,
            import_jobs: BTreeMap::new(),
            search_changed: None,
            provider_form: None,
            provider_password_visible: false,
            delete_provider: None,
            details: None,
            detail_positions: vec![],
            detail_loading: false,
            detail_error: None,
            episodes: vec![],
            guide: vec![],
            guide_day: 0,
            playing: None,
            volume: VolumePreferences::default(),
            controls_last_activity: Instant::now(),
            controls_hidden: false,
            recent_live_expanded: true,
            recent_live_channels: vec![],
            recent_live_loading: false,
            recent_live_error: None,
            seek_position: None,
            space_hold: player::SpaceHold::default(),
            player_surface_focus: None,
            playback_episodes: vec![],
            playback_positions: vec![],
            rail_scrolled_to: None,
            ended_handled: false,
            seek_indicator: None,
            last_progress: Instant::now(),
            fullscreen: false,
            speed: 1.0,
            selected_track: BTreeMap::new(),
            confirm_clear_history: false,
            confirm_clear_provider_history: None,
            confirm_clear_cache: false,
            confirm_reset_data: false,
            sidebar_pinned: false,
            sidebar_width: 72.0,
        }
    }
    fn reload(&mut self) {
        if !self.ready {
            return;
        }
        self.token += 1;
        self.loading = true;
        self.worker
            .send(Command::Load(self.token, self.query.clone()));
    }
    fn navigate(&mut self, section: Section) {
        if self.section == section {
            return;
        }
        self.worker.send(Command::CancelPlayback);
        let state = self.browsing_memory.switch(
            self.section,
            section,
            navigation::BrowsingState {
                query: self.query.clone(),
                category_search: self.category_search.clone(),
                selection: self.selected_catalog.take(),
            },
        );
        self.query = state.query;
        self.category_search = state.category_search;
        self.selected_catalog = state.selection;
        self.episodes.clear();
        self.detail_positions.clear();
        self.detail_loading = false;
        self.detail_error = None;
        self.restore_selection = true;
        self.search_changed = None;
        self.page = CatalogPage::default();
        self.categories.clear();
        self.section = section;
        self.reload();
    }
    fn receive(&mut self, ctx: &egui::Context) {
        while let Ok(event) = self.worker.rx.try_recv() {
            match event {
                Event::Ready(path) => {
                    self.db_path = path;
                    self.ready = true;
                    self.worker.send(Command::CheckUpdates);
                    self.reload();
                }
                Event::Fatal(error) => {
                    self.loading = false;
                    self.fatal = Some(error);
                }
                Event::View(token, data) if token == self.token => {
                    let ViewData {
                        providers,
                        categories,
                        page,
                        history,
                        settings,
                        latest_movies,
                        latest_series,
                        home_favorites,
                        home_continue,
                        global_search,
                    } = data;
                    self.global_search = global_search;
                    self.latest_movies = latest_movies;
                    self.latest_series = latest_series;
                    self.home_favorites = home_favorites;
                    self.home_continue = home_continue;
                    self.providers = providers;
                    self.categories = categories;
                    self.page = page;
                    self.history = history;
                    self.settings = settings;
                    self.loading = false;
                    if self.global_search.is_none() {
                        self.selected_catalog =
                            self.selected_catalog.as_ref().and_then(|selected| {
                                self.page
                                    .items
                                    .iter()
                                    .find(|item| {
                                        item.provider_id == selected.provider_id
                                            && item.content_type == selected.content_type
                                            && item.id == selected.id
                                    })
                                    .cloned()
                            });
                    }
                    if std::mem::take(&mut self.restore_selection)
                        && let Some(item) = self.selected_catalog.clone()
                    {
                        self.select_catalog(item);
                    }
                    if !self.initialized {
                        self.sidebar_pinned = self
                            .settings
                            .get("sidebar_pinned")
                            .is_some_and(|value| value == "true");
                        self.category_sidebar_width = self
                            .settings
                            .get("category_sidebar_width")
                            .and_then(|value| value.parse::<f32>().ok())
                            .filter(|value| value.is_finite())
                            .unwrap_or(280.0)
                            .clamp(220.0, 420.0);
                        self.volume = self
                            .settings
                            .get("playback_output_volume")
                            .and_then(|s| serde_json::from_str(s).ok())
                            .unwrap_or_default();
                        self.volume.volume = self.volume.volume.clamp(0.0, 100.0);
                        self.volume.last_audible_volume =
                            self.volume.last_audible_volume.clamp(1.0, 100.0);
                        if let Some(player) = &self.player {
                            let _ = player.set_volume(self.volume.volume);
                        }
                        self.initialized = true;
                    }
                    if self.section == Section::Guide
                        || (self.section == Section::Live && self.live_guide_mode)
                    {
                        self.request_guide();
                    }
                }
                Event::View(_, _) => {}
                Event::Message(message) => {
                    // Success events refresh the library without an inline banner.
                    drop(message);
                    self.error = None;
                    self.reload();
                }
                Event::Error(error) => {
                    self.error = Some(error);
                    self.loading = false;
                }
                Event::Busy(busy) => {
                    self.importing = busy;
                    if !busy {
                        self.import_jobs.clear();
                    }
                }
                Event::ImportStarted(id, name, run) => {
                    self.import_jobs.insert(
                        id,
                        (
                            run,
                            name,
                            imports::ImportProgress {
                                stage: "Connecting".into(),
                                completed: 0,
                                total: None,
                                unit: "items".into(),
                            },
                        ),
                    );
                }
                Event::ImportProgress(id, run, progress) => {
                    if let Some(job) = self.import_jobs.get_mut(&id)
                        && job.0 == run
                    {
                        job.2 = progress;
                    }
                }
                Event::ImportFinished(id, run) => {
                    if self.import_jobs.get(&id).is_some_and(|job| job.0 == run) {
                        self.import_jobs.remove(&id);
                    }
                }
                Event::ResetComplete(backup) => {
                    drop(backup);
                    self.volume = VolumePreferences::default();
                    self.initialized = false;
                    self.home_selected = None;
                    self.selected_catalog = None;
                    self.details = None;
                    self.providers.clear();
                    self.browsing_memory = navigation::BrowsingMemory::default();
                    self.section = Section::Home;
                    self.query = CatalogQuery {
                        limit: PAGE_SIZE,
                        ..Default::default()
                    };
                    self.category_search.clear();
                    self.categories.clear();
                    self.page = CatalogPage::default();
                    self.detail_positions.clear();
                    self.search_changed = None;
                    self.restore_selection = false;
                    self.reload();
                }
                Event::Series(provider, series, episodes) => {
                    if self
                        .details
                        .as_ref()
                        .or(self.selected_catalog.as_ref())
                        .is_some_and(|item| {
                            item.content_type == "series"
                                && item.provider_id == provider
                                && item.id == series
                        })
                    {
                        self.episodes = episodes;
                    }
                }
                Event::Metadata(item) => {
                    if self.details.as_ref().is_some_and(|current| {
                        current.provider_id == item.provider_id
                            && current.content_type == item.content_type
                            && current.id == item.id
                    }) {
                        self.details = Some(item.clone());
                    }
                    if self.selected_catalog.as_ref().is_some_and(|current| {
                        current.provider_id == item.provider_id
                            && current.content_type == item.content_type
                            && current.id == item.id
                    }) {
                        self.selected_catalog = Some(item);
                    }
                }
                Event::DetailPositions(provider, kind, id, result) => {
                    if self
                        .details
                        .as_ref()
                        .or(self.selected_catalog.as_ref())
                        .is_some_and(|item| {
                            item.provider_id == provider
                                && item.content_type == kind
                                && item.id == id
                        })
                    {
                        match result {
                            Ok(positions) => self.detail_positions = positions,
                            Err(error) => self.detail_error = Some(error.to_string()),
                        }
                    }
                }
                Event::DetailStatus(provider, kind, id, loading, error) => {
                    if self
                        .details
                        .as_ref()
                        .or(self.selected_catalog.as_ref())
                        .is_some_and(|item| {
                            item.provider_id == provider
                                && item.content_type == kind
                                && item.id == id
                        })
                    {
                        self.detail_loading = loading;
                        self.detail_error = error;
                    }
                }
                Event::Epg(programs) => self.guide = programs,
                Event::Updates(result) => {
                    self.checking_update = false;
                    match result {
                        Ok(status) => {
                            self.update_status = Some(status);
                            self.update_error = None;
                        }
                        Err(error) => self.update_error = Some(error.to_string()),
                    }
                }
                Event::RecentLiveChannels(generation, provider, current, result) => {
                    if generation == self.worker.generation()
                        && self.playing.as_ref().is_some_and(|target| {
                            target.item.content_type == "live"
                                && target.item.provider_id == provider
                                && target.item.id == current
                        })
                    {
                        self.recent_live_loading = false;
                        match result {
                            Ok(channels) => {
                                self.recent_live_channels = channels;
                                self.recent_live_error = None;
                            }
                            Err(error) => {
                                self.recent_live_channels.clear();
                                self.recent_live_error = Some(error.to_string());
                            }
                        }
                    }
                }
                Event::PlaybackPositions(generation, positions) => {
                    if generation == self.worker.generation() {
                        self.playback_positions = positions;
                    }
                }
                Event::PlaybackQueue(generation, episodes) => {
                    if generation == self.worker.generation() {
                        self.playback_episodes = episodes;
                    }
                }
                Event::Prepared(target, resume) => {
                    if target.generation != self.worker.generation() {
                        continue;
                    }
                    let mut target = *target;
                    self.restore_space_hold();
                    self.persist_progress();
                    let url = target.item.stream_url.clone().or_else(|| {
                        let provider = self
                            .providers
                            .iter()
                            .find(|p| p.id == target.item.provider_id)?;
                        let json = target.item.stream_json.as_deref()?;
                        vela_core::imports::resolve_stream_url(
                            provider,
                            json,
                            &target.item.content_type,
                        )
                        .ok()
                    });
                    if let Some(url) = url {
                        target.item.stream_url = Some(url.clone());
                        if let Some(player) = &self.player {
                            let _ = player.set_volume(self.volume.volume);
                            let _ = player.set_muted(false);
                            match player.open(
                                &url,
                                &[("User-Agent".into(), "VLC/3.0.20 LibVLC/3.0.20".into())],
                                resume
                                    .filter(|p| !p.completed && p.position_seconds > 0)
                                    .map(|p| p.position_seconds as f64),
                            ) {
                                Ok(()) => {
                                    self.playing = Some(target);
                                    self.last_progress = Instant::now();
                                    self.selected_track.clear();
                                    self.ended_handled = false;
                                    self.controls_last_activity = Instant::now();
                                    self.controls_hidden = false;
                                    self.seek_position = None;
                                    self.watch_recent_live();
                                }
                                Err(error) => self.error = Some(error.to_string()),
                            }
                        } else {
                            self.error = self.player_error.clone();
                        }
                    } else {
                        self.error = Some(
                            "This item has no playable stream. Refresh its provider and try again."
                                .into(),
                        );
                    }
                }
            }
        }
        if let Some(changed) = self.search_changed {
            if changed.elapsed() > Duration::from_millis(250) {
                self.search_changed = None;
                self.query.offset = 0;
                self.reload();
            } else {
                ctx.request_repaint_after(Duration::from_millis(100));
            }
        }
    }
    fn request_guide(&self) {
        let provider = self
            .query
            .provider_id
            .as_ref()
            .or_else(|| self.providers.first().map(|p| &p.id));
        if let Some(provider) = provider {
            let day = chrono::Local::now().date_naive() + chrono::Duration::days(self.guide_day);
            let start = day.and_hms_opt(0, 0, 0).unwrap();
            let from = chrono::TimeZone::from_local_datetime(&chrono::Local, &start)
                .earliest()
                .map(|date| date.timestamp_millis())
                .unwrap_or_else(|| start.and_utc().timestamp_millis());
            let channels = self
                .page
                .items
                .iter()
                .map(|item| {
                    item.epg_channel_id
                        .clone()
                        .unwrap_or_else(|| item.title.clone())
                })
                .collect();
            self.worker.send(Command::Guide(
                provider.clone(),
                channels,
                from,
                from + 24 * 3_600_000,
            ));
        }
    }
    fn prepare(&mut self, item: CatalogItem) {
        if item.content_type == "series" {
            self.worker.send(Command::PlaySeries(item));
        } else {
            self.worker
                .send(Command::Prepare(PlaybackTarget::catalog(item)));
        }
    }
    fn open_detail(&mut self, item: CatalogItem) {
        self.episodes.clear();
        self.detail_positions.clear();
        self.detail_error = None;
        self.detail_loading = false;
        self.worker.send(Command::DetailPositions(
            item.provider_id.clone(),
            item.content_type.clone(),
            item.id.clone(),
        ));
        if item.content_type == "series"
            && let Some(provider) = self.providers.iter().find(|p| p.id == item.provider_id)
        {
            self.worker
                .send(Command::Series(provider.clone(), item.clone()));
        }
        if item.content_type == "movie"
            && let Some(provider) = self
                .providers
                .iter()
                .find(|p| p.id == item.provider_id && p.kind == "xtream")
            && item.external_id.is_some()
        {
            self.worker
                .send(Command::Movie(provider.clone(), item.clone()));
        }
        self.details = Some(item);
    }
    fn close_detail(&mut self) {
        self.details = None;
        if let Some(item) = self.selected_catalog.clone() {
            self.select_catalog(item);
        }
    }
    fn track_preferences_key(&self) -> Option<String> {
        let target = self.playing.as_ref()?;
        Some(crate::preferences::key(
            &target.item.provider_id,
            &target.item.content_type,
            target.series_id.as_deref(),
            target.season_id.as_deref(),
            &target.item.id,
        ))
    }
    fn select_track(&mut self, kind: &str, track: Option<&vela_player::Track>) {
        if let Some(player) = &self.player {
            let _ = player.select_track(kind, track.map(|track| track.id));
        }
        if let Some(key) = self.track_preferences_key() {
            let raw = crate::preferences::update(
                self.settings.get(&key).map(String::as_str),
                kind,
                track,
            );
            self.settings.insert(key.clone(), raw.clone());
            self.worker.send(Command::Setting(key, raw));
        }
        self.selected_track.insert(kind.into(), "user".into());
    }
    fn restore_tracks(&mut self, tracks: &[vela_player::Track]) {
        let Some(key) = self.track_preferences_key() else {
            return;
        };
        for kind in ["audio", "sub", "video"] {
            if self.selected_track.contains_key(kind) {
                continue;
            }
            let default = self
                .settings
                .get(if kind == "audio" {
                    "default_audio"
                } else {
                    "default_subtitles"
                })
                .map(String::as_str);
            let selection = crate::preferences::resolve(
                kind,
                tracks,
                self.settings.get(&key).map(String::as_str),
                default,
            );
            match selection {
                crate::preferences::Selection::Pending => {}
                crate::preferences::Selection::KeepAuto => {
                    if let Some(player) = &self.player {
                        let _ = player.select_track_auto(kind);
                    }
                    self.selected_track.insert(kind.into(), "auto".into());
                }
                crate::preferences::Selection::Off => {
                    if let Some(player) = &self.player {
                        let _ = player.select_track(kind, None);
                    }
                    self.selected_track.insert(kind.into(), "off".into());
                }
                crate::preferences::Selection::Track(id) => {
                    if let Some(player) = &self.player {
                        let _ = player.select_track(kind, Some(id));
                    }
                    self.selected_track.insert(kind.into(), id.to_string());
                }
            }
        }
    }
    fn set_volume(&mut self, volume: f64) {
        self.volume.volume = volume.clamp(0.0, 100.0);
        if self.volume.volume > 0.0 {
            self.volume.last_audible_volume = self.volume.volume;
        }
        if let Some(player) = &self.player {
            let _ = player.set_volume(self.volume.volume);
            let _ = player.set_muted(false);
        }
        self.worker.send(Command::Volume(self.volume));
    }
    fn toggle_mute(&mut self) {
        self.set_volume(if self.volume.volume == 0.0 {
            self.volume.last_audible_volume
        } else {
            0.0
        });
    }
    fn persist_progress(&self) {
        let (Some(target), Some(player)) = (&self.playing, &self.player) else {
            return;
        };
        let state = player.snapshot();
        let progress = PlaybackProgress {
            provider_id: target.item.provider_id.clone(),
            catalog_key: target.key(),
            item_id: target.item.id.clone(),
            item_type: target.item.content_type.clone(),
            title: target.item.title.clone(),
            subtitle: target.item.subtitle.clone(),
            artwork_url: target.item.artwork_url.clone(),
            series_id: target.series_id.clone(),
            season_id: target.season_id.clone(),
            position_seconds: state.position.max(0.0) as i64,
            duration_seconds: if state.duration > 0.0 {
                Some(state.duration as i64)
            } else {
                target.item.duration_seconds
            },
            completion_percentage: if state.duration > 0.0 {
                (state.position / state.duration).clamp(0.0, 1.0)
            } else {
                0.0
            },
            completed: state.ended
                || (state.duration > 0.0 && state.position / state.duration >= 0.95),
            last_watched_at: chrono::Utc::now().timestamp_millis(),
            watch_count: 1,
        };
        self.worker.send(Command::Progress(progress));
    }
    fn close_player(&mut self, ctx: &egui::Context) {
        self.restore_space_hold();
        self.worker.send(Command::CancelPlayback);
        self.persist_progress();
        if let Some(item) = &self.details {
            self.worker.send(Command::DetailPositions(
                item.provider_id.clone(),
                item.content_type.clone(),
                item.id.clone(),
            ));
        }
        if let Some(player) = &self.player {
            let _ = player.stop();
        }
        self.playing = None;
        self.recent_live_channels.clear();
        self.recent_live_loading = false;
        self.recent_live_expanded = true;
        self.playback_positions.clear();
        self.rail_scrolled_to = None;
        self.controls_hidden = false;
        self.fullscreen = false;
        ctx.send_viewport_cmd(egui::ViewportCommand::Fullscreen(false));
        self.reload();
    }
}

impl eframe::App for VelaApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        if !self.window_sized {
            let bounds = ctx.input(|i| (i.viewport().outer_rect, i.viewport().inner_rect));
            if let (Some(outer), Some(inner)) = bounds {
                let border = outer.size() - inner.size();
                ctx.send_viewport_cmd(egui::ViewportCommand::InnerSize(egui::vec2(
                    1440.0 - border.x.max(0.0),
                    900.0 - border.y.max(0.0),
                )));
                ctx.send_viewport_cmd(egui::ViewportCommand::MinInnerSize(egui::vec2(
                    1120.0 - border.x.max(0.0),
                    720.0 - border.y.max(0.0),
                )));
                self.window_sized = true;
            }
        }
        self.receive(ctx);
        if let Some(error) = self.fatal.clone() {
            egui::CentralPanel::default().show(ctx,|ui|{ui.add_space(60.0);ui.heading("Your library is safe");ui.label(error);ui.label("Vela has not replaced or reset your original database. You can choose the previous Vela catalog to migrate it safely.");
                if ui.button("Choose existing Vela library…").clicked()&& let Some(path)=rfd::FileDialog::new().add_filter("SQLite catalog",&["sqlite","db"]).pick_file(){self.worker.shutdown();self.worker=Worker::with_legacy(ctx.clone(),path);self.fatal=None;self.loading=true;}});
            return;
        }
        self.import_status(ctx);
        if self.playing.is_some() {
            self.player_ui(ctx);
            return;
        }
        self.sidebar(ctx);
        egui::CentralPanel::default()
            .frame(egui::Frame::new().fill(BG).inner_margin(0.0))
            .show(ctx, |ui| {
                if !self.initialized {
                    ui.vertical_centered(|ui| {
                        ui.add_space(60.0);
                        ui.spinner();
                        ui.label("Loading library…");
                    });
                } else if self.section == Section::Settings {
                    self.settings_ui(ui);
                } else if self.section == Section::Guide {
                    self.guide_ui(ui);
                } else if self.section == Section::Recent {
                    self.recent_ui(ui);
                } else {
                    self.catalog(ui);
                }
            });
        self.provider_dialog(ctx);
        self.detail_dialog(ctx);
        if let Some(provider) = self.delete_provider.clone() {
            let mut keep = true;
            egui::Window::new("Remove provider?")
                .collapsible(false)
                .open(&mut keep)
                .show(ctx, |ui| {
                    ui.label(format!(
                        "Remove {} and its catalog, favorites, and watch progress?",
                        provider.name
                    ));
                    if ui.button("Remove provider").clicked() {
                        self.worker
                            .send(Command::DeleteProvider(provider.id.clone()));
                        self.delete_provider = None;
                    }
                });
            if !keep {
                self.delete_provider = None;
            }
        }
        if self.confirm_clear_history {
            let mut keep = true;
            egui::Window::new("Clear watch history?").collapsible(false).open(&mut keep).show(ctx,|ui|{ui.label("This clears watch history and resume positions. Providers and favorites are kept.");if ui.button("Clear history").clicked(){self.worker.send(Command::ClearHistory);self.confirm_clear_history=false;}});
            if !keep {
                self.confirm_clear_history = false;
            }
        }
        if let Some(provider) = self.confirm_clear_provider_history.clone() {
            let mut keep = true;
            let name = self
                .providers
                .iter()
                .find(|entry| entry.id == provider)
                .map(|entry| entry.name.as_str())
                .unwrap_or("this provider");
            egui::Window::new("Clear this provider's recent history?").collapsible(false).open(&mut keep).show(ctx, |ui| {
                ui.label(format!("Clear watch history and resume positions for {name}? Other providers and favorites are kept."));
                if ui.button("Clear recent").clicked() {
                    self.worker.send(Command::ClearProviderHistory(provider));
                    self.confirm_clear_provider_history = None;
                }
            });
            if !keep {
                self.confirm_clear_provider_history = None;
            }
        }
        if self.confirm_clear_cache {
            let mut keep = true;
            egui::Window::new("Clear provider catalog cache?").collapsible(false).open(&mut keep).show(ctx,|ui|{ui.label("This clears downloaded catalogs and guide data. Providers, favorites and watch progress are kept.");if ui.button("Clear catalog cache").clicked(){self.worker.send(Command::ClearCache);self.confirm_clear_cache=false;}});
            if !keep {
                self.confirm_clear_cache = false;
            }
        }
        if self.confirm_reset_data {
            let mut keep = true;
            egui::Window::new("Reset all Vela app data?").collapsible(false).open(&mut keep).show(ctx,|ui|{ui.label("This clears providers, catalogs, favorites, settings and watch progress from this Rust app. Vela will make a recovery backup first. Your original Flutter database stays untouched.");if ui.button("Back up and reset app data").clicked(){self.worker.send(Command::ResetData);self.confirm_reset_data=false;}});
            if !keep {
                self.confirm_reset_data = false;
            }
        }
        // Workers and input request redraws when data changes. Only the live
        // guide needs an idle clock tick; a static library should consume no GPU.
        if self.section == Section::Live && self.live_guide_mode {
            ctx.request_repaint_after(Duration::from_secs(60));
        }
    }
    fn on_exit(&mut self, _gl: Option<&glow::Context>) {
        self.restore_space_hold();
        self.persist_progress();
        self.worker.send(Command::Volume(self.volume));
        if let Some(player) = &mut self.player {
            player.shutdown_gl();
        }
        self.worker.shutdown();
    }
}

fn new_provider() -> Provider {
    Provider {
        id: uuid::Uuid::new_v4().to_string(),
        name: "Primary IPTV".into(),
        kind: "xtream".into(),
        source_kind: Some("url".into()),
        is_enabled: true,
        auto_refresh_enabled: true,
        auto_refresh_interval_minutes: 1440,
        ..Default::default()
    }
}
fn time_label(seconds: f64) -> String {
    let seconds = seconds.max(0.0) as u64;
    format!(
        "{}:{:02}:{:02}",
        seconds / 3600,
        (seconds / 60) % 60,
        seconds % 60
    )
}
