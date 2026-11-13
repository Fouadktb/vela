use anyhow::Result;
use eframe::egui;
use std::{
    collections::BTreeMap,
    path::PathBuf,
    sync::{
        Arc, Condvar, Mutex,
        atomic::{AtomicU64, Ordering},
        mpsc,
    },
    thread,
    time::Duration,
};
use vela_core::{imports, store::Store, *};

#[derive(Clone, Debug)]
pub struct PlaybackTarget {
    pub generation: u64,
    pub item: CatalogItem,
    pub series_id: Option<String>,
    pub season_id: Option<String>,
}
impl PlaybackTarget {
    pub fn catalog(item: CatalogItem) -> Self {
        Self {
            generation: 0,
            item,
            series_id: None,
            season_id: None,
        }
    }
    pub fn episode(episode: &Episode) -> Self {
        Self {
            generation: 0,
            item: CatalogItem {
                id: episode.id.clone(),
                provider_id: episode.provider_id.clone(),
                content_type: "episode".into(),
                title: episode.title.clone(),
                description: episode.description.clone(),
                artwork_url: episode.artwork_url.clone(),
                stream_url: episode.stream_url.clone(),
                stream_json: episode.stream_json.clone(),
                duration_seconds: episode.duration_seconds,
                ..Default::default()
            },
            series_id: Some(episode.series_id.clone()),
            season_id: Some(episode.season_id.clone()),
        }
    }
    pub fn key(&self) -> String {
        match (&self.series_id, &self.season_id) {
            (Some(series), Some(season)) => {
                vela_core::store::playback_catalog_key(&self.item.id, Some(series), Some(season))
            }
            _ => self.item.id.clone(),
        }
    }
}

#[derive(Clone)]
pub struct GlobalSearchResult {
    pub item: CatalogItem,
    pub progress: Option<PlaybackProgress>,
}
#[derive(Clone)]
pub struct GlobalSearchGroup {
    pub title: &'static str,
    pub icon: &'static str,
    pub results: Vec<GlobalSearchResult>,
}
#[derive(Clone)]
pub struct GlobalSearchResults {
    pub query: String,
    pub groups: Vec<GlobalSearchGroup>,
}
/// Slash mode is a view over the library; the underlying section filters stay
/// intact so deleting the prefix or clicking the toggle restores them exactly.
pub fn global_search_query(value: &str) -> Option<&str> {
    value.trim_start().strip_prefix('/').map(str::trim)
}
pub fn toggle_global_search(query: &mut CatalogQuery) {
    query.search = match global_search_query(&query.search) {
        Some(_) => query
            .search
            .trim_start()
            .strip_prefix('/')
            .unwrap_or("")
            .trim_start()
            .to_owned(),
        None => {
            let search = query.search.trim();
            if search.is_empty() {
                "/".to_owned()
            } else {
                format!("/ {search}")
            }
        }
    };
    query.offset = 0;
}

pub struct ViewData {
    pub global_search: Option<GlobalSearchResults>,
    pub providers: Vec<Provider>,
    pub categories: Vec<Category>,
    pub page: CatalogPage,
    pub latest_movies: Vec<CatalogItem>,
    pub latest_series: Vec<CatalogItem>,
    pub home_favorites: Vec<CatalogItem>,
    pub home_continue: Vec<(CatalogItem, PlaybackProgress)>,
    pub history: Vec<PlaybackProgress>,
    pub settings: BTreeMap<String, String>,
}

#[derive(Clone)]
pub struct Origin {
    pub provider: Provider,
    pub revision: u64,
}

#[derive(Clone)]
struct NetworkSender {
    tx: mpsc::Sender<(u64, Command)>,
    generation: u64,
}
impl NetworkSender {
    fn send(&self, command: Command) -> Result<(), ()> {
        self.tx.send((self.generation, command)).map_err(|_| ())
    }
}

// Each foreground operation has a reserved worker and at most one queued job.
// Replacing obsolete queued requests keeps rapid navigation bounded and lets
// playback discovery proceed even while full provider imports are running.
type NetworkJob = Box<dyn FnOnce() + Send + 'static>;
#[derive(Default)]
struct LaneState {
    pending: Option<NetworkJob>,
    closed: bool,
}
struct LatestNetworkLane {
    shared: Arc<(Mutex<LaneState>, Condvar)>,
}
impl LatestNetworkLane {
    fn new() -> Self {
        let shared = Arc::new((Mutex::new(LaneState::default()), Condvar::new()));
        let receiver = shared.clone();
        thread::spawn(move || {
            loop {
                let job = {
                    let (mutex, ready) = &*receiver;
                    let mut state = mutex.lock().unwrap_or_else(|error| error.into_inner());
                    while state.pending.is_none() && !state.closed {
                        state = ready.wait(state).unwrap_or_else(|error| error.into_inner());
                    }
                    if state.closed {
                        return;
                    }
                    state.pending.take().expect("pending network job")
                };
                job();
            }
        });
        Self { shared }
    }
    fn submit(&self, job: impl FnOnce() + Send + 'static) {
        let (mutex, ready) = &*self.shared;
        let mut state = mutex.lock().unwrap_or_else(|error| error.into_inner());
        if !state.closed {
            state.pending = Some(Box::new(job));
            ready.notify_one();
        }
    }
}
impl Drop for LatestNetworkLane {
    fn drop(&mut self) {
        let (mutex, ready) = &*self.shared;
        let mut state = mutex.lock().unwrap_or_else(|error| error.into_inner());
        state.closed = true;
        state.pending = None;
        ready.notify_one();
    }
}

pub enum Command {
    Load(u64, CatalogQuery),
    SaveProvider(Provider),
    DeleteProvider(String),
    Refresh(Provider),
    Imported(Origin, Result<ImportSnapshot>),
    PlaySeries(CatalogItem),
    PlaySeriesFetched(Origin, Result<SeriesDetails>),
    Series(Provider, CatalogItem),
    SeriesFetched(Origin, String, Result<SeriesDetails>),
    Movie(Provider, CatalogItem),
    MovieFetched(Origin, String, Result<CatalogItem>),
    DetailPositions(String, String, String),
    WatchRecentLive(Option<(String, String)>),
    Epg(Provider),
    EpgFetched(Origin, Result<Vec<EpgProgram>>),
    Guide(String, Vec<String>, i64, i64),
    CategoryFavorite(String, String, String),
    ReorderCategories(String, String, Vec<String>),
    Favorite(CatalogItem),
    Setting(String, String),
    Volume(VolumePreferences),
    Progress(PlaybackProgress),
    Prepare(PlaybackTarget),
    Restart(PlaybackTarget),
    CancelPlayback,
    ResumeHistory(PlaybackProgress),
    Backup(PathBuf),
    Diagnostics(PathBuf),
    ClearHistory,
    ClearProviderHistory(String),
    ClearCache,
    ResetData,
    CheckUpdates,
    UpdatesFetched(Result<vela_core::updates::ReleaseInfo>),
    Shutdown,
}
pub enum Event {
    Ready(PathBuf),
    View(u64, ViewData),
    Message(String),
    Error(String),
    Fatal(String),
    Series(String, String, Vec<Episode>),
    Metadata(CatalogItem),
    DetailPositions(String, String, String, Result<Vec<PlaybackProgress>>),
    DetailStatus(String, String, String, bool, Option<String>),
    RecentLiveChannels(u64, String, String, Result<Vec<CatalogItem>>),
    Epg(Vec<EpgProgram>),
    Prepared(Box<PlaybackTarget>, Option<PlaybackProgress>),
    Busy(bool),
    ImportStarted(String, String, String),
    ImportProgress(String, String, imports::ImportProgress),
    ImportFinished(String, String),
    ResetComplete(PathBuf),
    PlaybackQueue(u64, Vec<Episode>),
    PlaybackPositions(u64, Vec<PlaybackProgress>),
    Updates(Result<vela_core::updates::ReleaseInfo>),
}

pub struct Worker {
    tx: mpsc::Sender<(u64, Command)>,
    playback_generation: Arc<AtomicU64>,
    pub rx: mpsc::Receiver<Event>,
    join: Option<thread::JoinHandle<()>>,
}
impl Worker {
    pub fn new(context: egui::Context) -> Self {
        Self::spawn(context, Store::open_default)
    }
    #[cfg(test)]
    pub fn test_new(context: egui::Context, path: PathBuf) -> Self {
        Self::spawn(context, move || Store::open(path))
    }
    pub fn with_legacy(context: egui::Context, path: PathBuf) -> Self {
        Self::spawn(context, move || Store::open_with_legacy(&path))
    }
    fn spawn(
        context: egui::Context,
        open: impl FnOnce() -> Result<Store> + Send + 'static,
    ) -> Self {
        let (tx, commands) = mpsc::channel();
        let (events, rx) = mpsc::channel();
        let playback_generation = Arc::new(AtomicU64::new(0));
        let current_generation = playback_generation.clone();
        let network_tx = NetworkSender {
            tx: tx.clone(),
            generation: 0,
        };
        let join = thread::spawn(move || {
            let emit = |event| {
                let _ = events.send(event);
                context.request_repaint();
            };
            let store = match open() {
                Ok(store) => store,
                Err(error) => {
                    emit(Event::Fatal(format!(
                        "Your existing library was left untouched. Vela could not open or migrate it: {error}"
                    )));
                    return;
                }
            };
            emit(Event::Ready(store.path().to_owned()));
            let mut active_imports = 0usize;
            let playback_network = LatestNetworkLane::new();
            let detail_network = LatestNetworkLane::new();
            let guide_network = LatestNetworkLane::new();
            let mut revisions = std::collections::HashMap::<String, u64>::new();
            let mut refreshing = std::collections::HashSet::new();
            let mut refresh_runs = std::collections::HashMap::<String, String>::new();
            let mut last_attempt = std::collections::HashMap::<String, std::time::Instant>::new();
            let mut last_schedule = std::time::Instant::now() - Duration::from_secs(60);
            let mut recent_live: Option<(u64, String, String)> = None;
            let mut playback_series: Option<(u64, String, String)> = None;
            loop {
                if last_schedule.elapsed() >= Duration::from_secs(30) {
                    last_schedule = std::time::Instant::now();
                    if let Ok(providers) = store.providers() {
                        for provider in scheduled_refreshes(
                            providers,
                            &refreshing,
                            &last_attempt,
                            2usize.saturating_sub(active_imports),
                            chrono::Utc::now().timestamp_millis(),
                        ) {
                            let _ = network_tx.send(Command::Refresh(provider));
                        }
                    }
                }
                let (generation, command) = match commands.recv_timeout(Duration::from_secs(1)) {
                    Ok(command) => command,
                    Err(mpsc::RecvTimeoutError::Timeout) => continue,
                    Err(_) => break,
                };
                if matches!(&command, Command::Shutdown) {
                    break;
                }
                if matches!(
                    &command,
                    Command::Prepare(_)
                        | Command::Restart(_)
                        | Command::ResumeHistory(_)
                        | Command::PlaySeries(_)
                        | Command::PlaySeriesFetched(..)
                ) && generation != current_generation.load(Ordering::SeqCst)
                {
                    continue;
                }
                let refresh_recent = matches!(
                    &command,
                    Command::WatchRecentLive(_)
                        | Command::Progress(_)
                        | Command::SaveProvider(_)
                        | Command::DeleteProvider(_)
                        | Command::Imported(..)
                        | Command::ClearCache
                        | Command::ResetData
                        | Command::ClearHistory
                        | Command::ClearProviderHistory(_)
                );
                let restart = matches!(&command, Command::Restart(_));
                let result: Result<()> = (|| {
                    match command {
                        Command::DetailPositions(provider, kind, id) => {
                            let positions = store.detail_positions(&provider, &kind, &id);
                            emit(Event::DetailPositions(provider, kind, id, positions));
                        }
                        Command::WatchRecentLive(current) => {
                            if generation == current_generation.load(Ordering::SeqCst) {
                                recent_live =
                                    current.map(|(provider, id)| (generation, provider, id));
                            }
                        }
                        Command::Load(token, query) => {
                            let history = store.recent_history(200)?;
                            let mut home_continue = Vec::new();
                            let mut seen = std::collections::HashSet::new();
                            for progress in history
                                .iter()
                                .filter(|p| p.item_type != "live" && !p.completed)
                                .take(120)
                            {
                                let (kind, id) = if progress.item_type == "episode" {
                                    ("series", progress.series_id.as_deref().unwrap_or(""))
                                } else {
                                    (progress.item_type.as_str(), progress.item_id.as_str())
                                };
                                if !seen.insert((
                                    progress.provider_id.clone(),
                                    kind.to_owned(),
                                    id.to_owned(),
                                )) {
                                    continue;
                                }
                                if let Some(item) = store.item(&progress.provider_id, kind, id)? {
                                    home_continue.push((item, progress.clone()));
                                    if home_continue.len() >= 24 {
                                        break;
                                    }
                                }
                            }
                            let global_search = global_search_query(&query.search)
                                .map(|search| search_library(&store, search))
                                .transpose()?;
                            let page = if global_search.is_some() {
                                CatalogPage::default()
                            } else {
                                store.catalog(&query)?
                            };
                            let data = ViewData {
                                global_search,
                                providers: store.providers()?,
                                categories: store.categories(
                                    query.provider_id.as_deref(),
                                    query.content_type.as_deref().unwrap_or("live"),
                                )?,
                                page,
                                history,
                                home_continue,
                                settings: store.settings()?,
                                latest_movies: store
                                    .catalog(&CatalogQuery {
                                        content_type: Some("movie".into()),
                                        latest_first: true,
                                        limit: 24,
                                        ..Default::default()
                                    })?
                                    .items,
                                latest_series: store
                                    .catalog(&CatalogQuery {
                                        content_type: Some("series".into()),
                                        latest_first: true,
                                        limit: 24,
                                        ..Default::default()
                                    })?
                                    .items,
                                home_favorites: store
                                    .catalog(&CatalogQuery {
                                        favorites_only: true,
                                        limit: 24,
                                        ..Default::default()
                                    })?
                                    .items,
                            };
                            emit(Event::View(token, data));
                        }
                        Command::SaveProvider(provider) => {
                            store.upsert_provider(&provider)?;
                            *revisions.entry(provider.id.clone()).or_default() += 1;
                            emit(Event::Message("Provider saved".into()));
                        }
                        Command::DeleteProvider(id) => {
                            store.delete_provider(&id)?;
                            *revisions.entry(id.clone()).or_default() += 1;
                            emit(Event::Message(
                                "Provider and its library data removed".into(),
                            ));
                        }
                        Command::CategoryFavorite(provider, kind, category) => {
                            store.toggle_category_favorite(&provider, &kind, &category)?;
                            emit(Event::Message("Category favorites updated".into()));
                        }
                        Command::ReorderCategories(provider, kind, ids) => {
                            store.reorder_categories(&provider, &kind, &ids)?;
                            emit(Event::Message("Category order saved".into()));
                        }
                        Command::Favorite(item) => {
                            store.toggle_favorite(&item)?;
                            emit(Event::Message("Favorites updated".into()));
                        }
                        Command::Setting(key, value) => store.set_setting(&key, &value)?,
                        Command::Volume(volume) => store.save_volume(volume)?,
                        Command::Progress(progress) => {
                            store.save_progress(&progress)?;
                            if let Some((watch_generation, provider, series)) = &playback_series
                                && *watch_generation == current_generation.load(Ordering::SeqCst)
                            {
                                emit(Event::PlaybackPositions(
                                    *watch_generation,
                                    store.detail_positions(provider, "series", series)?,
                                ));
                            }
                        }
                        Command::ResumeHistory(progress) => {
                            let mut target = if progress.item_type == "episode" {
                                let series = progress.series_id.as_deref().ok_or_else(|| {
                                    anyhow::anyhow!("Episode history is missing its series")
                                })?;
                                let episode=store.episodes(&progress.provider_id,series)?.into_iter().find(|e|e.id==progress.item_id&&Some(e.season_id.as_str())==progress.season_id.as_deref()).ok_or_else(||anyhow::anyhow!("This episode is not in the current catalog. Refresh its series first."))?;
                                PlaybackTarget::episode(&episode)
                            } else {
                                PlaybackTarget::catalog(store.item(&progress.provider_id,&progress.item_type,&progress.item_id)?.ok_or_else(||anyhow::anyhow!("This item is not in the current catalog. Refresh its provider first."))?)
                            };
                            let resume = if target.item.content_type == "live" {
                                None
                            } else {
                                store.resume(
                                    &target.item.provider_id,
                                    &target.item.content_type,
                                    &target.item.id,
                                    target.series_id.as_deref(),
                                    target.season_id.as_deref(),
                                )?
                            };
                            target.generation = generation;
                            playback_series = target.series_id.as_ref().map(|series| {
                                (generation, target.item.provider_id.clone(), series.clone())
                            });
                            emit(Event::PlaybackQueue(
                                generation,
                                if let Some(series) = &target.series_id {
                                    playback_queue(&store, &target.item.provider_id, series)?
                                } else {
                                    vec![]
                                },
                            ));
                            emit(Event::PlaybackPositions(
                                generation,
                                if let Some(series) = &target.series_id {
                                    store.detail_positions(
                                        &target.item.provider_id,
                                        "series",
                                        series,
                                    )?
                                } else {
                                    vec![]
                                },
                            ));
                            emit(Event::Prepared(Box::new(target), resume));
                        }
                        Command::Prepare(mut target) | Command::Restart(mut target) => {
                            let progress = if restart || target.item.content_type == "live" {
                                None
                            } else {
                                store.resume(
                                    &target.item.provider_id,
                                    &target.item.content_type,
                                    &target.item.id,
                                    target.series_id.as_deref(),
                                    target.season_id.as_deref(),
                                )?
                            };
                            target.generation = generation;
                            playback_series = target.series_id.as_ref().map(|series| {
                                (generation, target.item.provider_id.clone(), series.clone())
                            });
                            emit(Event::PlaybackQueue(
                                generation,
                                if let Some(series) = &target.series_id {
                                    playback_queue(&store, &target.item.provider_id, series)?
                                } else {
                                    vec![]
                                },
                            ));
                            emit(Event::PlaybackPositions(
                                generation,
                                if let Some(series) = &target.series_id {
                                    store.detail_positions(
                                        &target.item.provider_id,
                                        "series",
                                        series,
                                    )?
                                } else {
                                    vec![]
                                },
                            ));
                            emit(Event::Prepared(Box::new(target), progress));
                        }
                        Command::Refresh(provider) => {
                            let Some(provider) = store.provider(&provider.id)? else {
                                return Ok(());
                            };
                            let origin = Origin {
                                provider: provider.clone(),
                                revision: *revisions.get(&provider.id).unwrap_or(&0),
                            };
                            if refreshing.contains(&provider.id) {
                                return Ok(());
                            }
                            refreshing.insert(provider.id.clone());
                            last_attempt.insert(provider.id.clone(), std::time::Instant::now());
                            if active_imports >= 2 {
                                refreshing.remove(&provider.id);
                                anyhow::bail!(
                                    "Two imports are already running. Wait for one to finish."
                                );
                            }
                            let run_id = match store.record_refresh_start(&provider.id) {
                                Ok(run) => run,
                                Err(error) => {
                                    refreshing.remove(&provider.id);
                                    return Err(error);
                                }
                            };
                            refresh_runs.insert(provider.id.clone(), run_id.clone());
                            active_imports += 1;
                            emit(Event::Busy(true));
                            emit(Event::ImportStarted(
                                provider.id.clone(),
                                provider.name.clone(),
                                run_id.clone(),
                            ));
                            let progress_events = events.clone();
                            let progress_context = context.clone();
                            let mut tx = network_tx.clone();
                            tx.generation = generation;
                            thread::spawn(move || {
                                let result = imports::import_provider_with_progress(
                                    &provider,
                                    &mut |progress| {
                                        let _ = progress_events.send(Event::ImportProgress(
                                            provider.id.clone(),
                                            run_id.clone(),
                                            progress,
                                        ));
                                        progress_context.request_repaint();
                                    },
                                );
                                let _ = tx.send(Command::Imported(origin, result));
                            });
                        }
                        Command::Imported(origin, result) => {
                            let provider = &origin.provider;
                            let was_active = refreshing.remove(&provider.id);
                            let progress_run =
                                refresh_runs.get(&provider.id).cloned().unwrap_or_default();
                            let completed = (|| -> Result<()> {
                                let Some(current) = store.provider(&provider.id)? else {
                                    return Ok(());
                                };
                                if !origin.is_current(&store, &revisions)? {
                                    if let Some(run) = refresh_runs.remove(&provider.id) {
                                        store.finish_refresh(
                                            &run,
                                            0,
                                            Some("Provider changed during import"),
                                        )?;
                                    }
                                    let _ = network_tx.send(Command::Refresh(current));
                                    return Ok(());
                                }
                                let result=result.and_then(|snapshot|{anyhow::ensure!(!snapshot.items.is_empty(),"Provider returned no playable items; your previous library was kept");store.replace_catalog_with_progress(&snapshot, &mut |completed,total| { emit(Event::ImportProgress(provider.id.clone(), progress_run.clone(), imports::ImportProgress { stage: "Saving library".into(), completed, total: Some(total), unit: "records".into() })); })?;Ok(snapshot.items.len())});
                                if let Some(run) = refresh_runs.remove(&provider.id) {
                                    match &result {
                                        Ok(count) => {
                                            store.finish_refresh(&run, *count as i64, None)?
                                        }
                                        Err(error) => store.finish_refresh(
                                            &run,
                                            0,
                                            Some(&error.to_string()),
                                        )?,
                                    }
                                }
                                let count = result?;
                                emit(Event::Message(format!(
                                    "Imported {count} items from {}",
                                    provider.name
                                )));
                                Ok(())
                            })();
                            refresh_runs.remove(&provider.id);
                            if was_active {
                                active_imports = active_imports.saturating_sub(1);
                            }
                            emit(Event::ImportFinished(provider.id.clone(), progress_run));
                            emit(Event::Busy(active_imports > 0));
                            completed?;
                        }
                        Command::PlaySeries(item) => {
                            let provider = store
                                .provider(&item.provider_id)?
                                .ok_or_else(|| anyhow::anyhow!("Provider was removed"))?;
                            let origin = Origin {
                                provider: provider.clone(),
                                revision: *revisions.get(&provider.id).unwrap_or(&0),
                            };
                            if !store.episodes(&item.provider_id, &item.id)?.is_empty() {
                                let (mut target, resume, episodes) =
                                    series_playback(&store, &item.provider_id, &item.id)?;
                                target.generation = generation;
                                playback_series = target.series_id.as_ref().map(|series| {
                                    (generation, target.item.provider_id.clone(), series.clone())
                                });
                                emit(Event::PlaybackQueue(generation, episodes));
                                emit(Event::PlaybackPositions(
                                    generation,
                                    if let Some(series) = &target.series_id {
                                        store.detail_positions(
                                            &target.item.provider_id,
                                            "series",
                                            series,
                                        )?
                                    } else {
                                        vec![]
                                    },
                                ));
                                emit(Event::Prepared(Box::new(target), resume));
                            } else {
                                anyhow::ensure!(
                                    provider.kind == "xtream",
                                    "No playable episodes are available. Refresh the provider first."
                                );
                                let mut tx = network_tx.clone();
                                tx.generation = generation;
                                let current_playback = current_generation.clone();
                                playback_network.submit(move || {
                                    if generation != current_playback.load(Ordering::SeqCst) {
                                        return;
                                    }
                                    let result = imports::fetch_series(
                                        &provider,
                                        item.external_id.as_deref().unwrap_or(""),
                                        &item.id,
                                    );
                                    let _ = tx.send(Command::PlaySeriesFetched(origin, result));
                                });
                            }
                        }
                        Command::PlaySeriesFetched(origin, result) => {
                            if !origin.is_current(&store, &revisions)? {
                                return Ok(());
                            }
                            let details = result?;
                            store.replace_series_details(&details)?;
                            let (mut target, resume, episodes) = series_playback(
                                &store,
                                &details.series.provider_id,
                                &details.series.id,
                            )?;
                            target.generation = generation;
                            playback_series = target.series_id.as_ref().map(|series| {
                                (generation, target.item.provider_id.clone(), series.clone())
                            });
                            emit(Event::PlaybackQueue(generation, episodes));
                            emit(Event::PlaybackPositions(
                                generation,
                                if let Some(series) = &target.series_id {
                                    store.detail_positions(
                                        &target.item.provider_id,
                                        "series",
                                        series,
                                    )?
                                } else {
                                    vec![]
                                },
                            ));
                            emit(Event::Prepared(Box::new(target), resume));
                        }
                        Command::Series(provider, item) => {
                            let identity = (
                                item.provider_id.clone(),
                                "series".to_owned(),
                                item.id.clone(),
                            );
                            let start = (|| -> Result<()> {
                                let provider = store
                                    .provider(&provider.id)?
                                    .ok_or_else(|| anyhow::anyhow!("Provider was removed"))?;
                                let current = store.episodes(&item.provider_id, &item.id)?;
                                emit(Event::Series(
                                    item.provider_id.clone(),
                                    item.id.clone(),
                                    current,
                                ));
                                if provider.kind != "xtream" || item.external_id.is_none() {
                                    emit(Event::DetailStatus(
                                        identity.0.clone(),
                                        identity.1.clone(),
                                        identity.2.clone(),
                                        false,
                                        None,
                                    ));
                                    return Ok(());
                                }
                                emit(Event::DetailStatus(
                                    identity.0.clone(),
                                    identity.1.clone(),
                                    identity.2.clone(),
                                    true,
                                    None,
                                ));
                                let origin = Origin {
                                    provider: provider.clone(),
                                    revision: *revisions.get(&provider.id).unwrap_or(&0),
                                };
                                let mut tx = network_tx.clone();
                                tx.generation = generation;
                                detail_network.submit(move || {
                                    let result = imports::fetch_series(
                                        &provider,
                                        item.external_id.as_deref().unwrap_or(""),
                                        &item.id,
                                    );
                                    let _ =
                                        tx.send(Command::SeriesFetched(origin, item.id, result));
                                });
                                Ok(())
                            })();
                            if let Err(error) = start {
                                emit(Event::DetailStatus(
                                    identity.0,
                                    identity.1,
                                    identity.2,
                                    false,
                                    Some(error.to_string()),
                                ));
                            }
                        }
                        Command::SeriesFetched(origin, series, result) => {
                            let provider = origin.provider.id.clone();
                            let fetched = (|| -> Result<Vec<Episode>> {
                                anyhow::ensure!(
                                    origin.is_current(&store, &revisions)?,
                                    "Provider changed while loading this series; reopen it to refresh."
                                );
                                let details = result?;
                                anyhow::ensure!(
                                    details.series.provider_id == provider
                                        && details.series.id == series,
                                    "Series response did not match the requested item"
                                );
                                store.replace_series_details(&details)?;
                                store.episodes(&provider, &series)
                            })();
                            match fetched {
                                Ok(episodes) => {
                                    emit(Event::Series(provider.clone(), series.clone(), episodes));
                                    emit(Event::DetailStatus(
                                        provider,
                                        "series".into(),
                                        series,
                                        false,
                                        None,
                                    ));
                                }
                                Err(error) => emit(Event::DetailStatus(
                                    provider,
                                    "series".into(),
                                    series,
                                    false,
                                    Some(error.to_string()),
                                )),
                            }
                        }
                        Command::Movie(provider, item) => {
                            let identity = (
                                item.provider_id.clone(),
                                "movie".to_owned(),
                                item.id.clone(),
                            );
                            let start = (|| -> Result<()> {
                                let provider = store
                                    .provider(&provider.id)?
                                    .ok_or_else(|| anyhow::anyhow!("Provider was removed"))?;
                                if let Some(current) =
                                    store.item(&item.provider_id, "movie", &item.id)?
                                {
                                    emit(Event::Metadata(current));
                                }
                                if provider.kind != "xtream" || item.external_id.is_none() {
                                    emit(Event::DetailStatus(
                                        identity.0.clone(),
                                        identity.1.clone(),
                                        identity.2.clone(),
                                        false,
                                        None,
                                    ));
                                    return Ok(());
                                }
                                emit(Event::DetailStatus(
                                    identity.0.clone(),
                                    identity.1.clone(),
                                    identity.2.clone(),
                                    true,
                                    None,
                                ));
                                let origin = Origin {
                                    provider: provider.clone(),
                                    revision: *revisions.get(&provider.id).unwrap_or(&0),
                                };
                                let mut tx = network_tx.clone();
                                tx.generation = generation;
                                detail_network.submit(move || {
                                    let result = imports::fetch_movie(
                                        &provider,
                                        item.external_id.as_deref().unwrap_or(""),
                                        &item.id,
                                    );
                                    let _ = tx.send(Command::MovieFetched(origin, item.id, result));
                                });
                                Ok(())
                            })();
                            if let Err(error) = start {
                                emit(Event::DetailStatus(
                                    identity.0,
                                    identity.1,
                                    identity.2,
                                    false,
                                    Some(error.to_string()),
                                ));
                            }
                        }
                        Command::MovieFetched(origin, id, result) => {
                            let provider = origin.provider.id.clone();
                            let fetched = (|| -> Result<Option<CatalogItem>> {
                                anyhow::ensure!(
                                    origin.is_current(&store, &revisions)?,
                                    "Provider changed while loading this movie; reopen it to refresh."
                                );
                                let metadata = result?;
                                anyhow::ensure!(
                                    metadata.provider_id == provider
                                        && metadata.id == id
                                        && metadata.content_type == "movie",
                                    "Movie response did not match the requested item"
                                );
                                store.update_item_metadata(&metadata)?;
                                store.item(&provider, "movie", &id)
                            })();
                            match fetched {
                                Ok(item) => {
                                    if let Some(item) = item {
                                        emit(Event::Metadata(item));
                                    }
                                    emit(Event::DetailStatus(
                                        provider,
                                        "movie".into(),
                                        id,
                                        false,
                                        None,
                                    ));
                                }
                                Err(error) => emit(Event::DetailStatus(
                                    provider,
                                    "movie".into(),
                                    id,
                                    false,
                                    Some(error.to_string()),
                                )),
                            }
                        }

                        Command::Epg(provider) => {
                            let Some(provider) = store.provider(&provider.id)? else {
                                return Ok(());
                            };
                            let origin = Origin {
                                provider: provider.clone(),
                                revision: *revisions.get(&provider.id).unwrap_or(&0),
                            };
                            let mut tx = network_tx.clone();
                            tx.generation = generation;
                            guide_network.submit(move || {
                                let result = imports::fetch_epg(&provider);
                                let _ = tx.send(Command::EpgFetched(origin, result));
                            });
                        }
                        Command::EpgFetched(origin, result) => {
                            if !origin.is_current(&store, &revisions)? {
                                return Ok(());
                            }
                            let provider = origin.provider.id;
                            let programs = result?;
                            store.replace_epg(&provider, &programs)?;
                            emit(Event::Message("Programme guide refreshed".into()));
                        }
                        Command::Guide(provider, channels, from, to) => {
                            emit(Event::Epg(store.epg(&provider, &channels, from, to)?))
                        }
                        Command::Backup(path) => {
                            store.backup_to(&path)?;
                            emit(Event::Message(
                                "Database backup saved. It includes private provider credentials."
                                    .into(),
                            ));
                        }
                        Command::Diagnostics(path) => {
                            let text = format!(
                                "Vela Rust {}\nOS: {}\nProviders: {}\nCatalog items: {}\nNo provider URLs, credentials, or media paths are included.\n",
                                env!("CARGO_PKG_VERSION"),
                                std::env::consts::OS,
                                store.providers()?.len(),
                                store
                                    .catalog(&CatalogQuery {
                                        limit: 1,
                                        ..Default::default()
                                    })?
                                    .total
                            );
                            std::fs::write(path, text)?;
                            emit(Event::Message("Diagnostics saved".into()));
                        }
                        Command::ClearCache => {
                            store.clear_catalog_cache()?;
                            emit(Event::Message("Catalog cache cleared. Providers, favorites and watch progress were kept.".into()));
                        }
                        Command::ResetData => {
                            let backup = store.path().with_file_name(format!(
                                "vela-before-reset-{}.sqlite",
                                uuid::Uuid::new_v4()
                            ));
                            store.backup_to(&backup)?;
                            for provider in store.providers()? {
                                *revisions.entry(provider.id).or_default() += 1;
                            }
                            store.reset_app_data()?;
                            emit(Event::ResetComplete(backup));
                        }
                        Command::ClearHistory => {
                            store.clear_history()?;
                            emit(Event::Message(
                                "Watch history and resume positions cleared".into(),
                            ));
                        }
                        Command::ClearProviderHistory(provider) => {
                            store.clear_provider_history(Some(&provider))?;
                            emit(Event::Message(
                                "Provider watch history and resume positions cleared".into(),
                            ));
                        }
                        Command::CheckUpdates => {
                            let mut tx = network_tx.clone();
                            tx.generation = generation;
                            std::thread::spawn(move || {
                                let _ =
                                    tx.send(Command::UpdatesFetched(vela_core::updates::check()));
                            });
                        }
                        Command::UpdatesFetched(result) => emit(Event::Updates(result)),
                        Command::CancelPlayback | Command::Shutdown => {
                            recent_live = None;
                            return Ok(());
                        }
                    }
                    Ok(())
                })();
                if let Err(error) = result {
                    emit(Event::Error(format!("{error}")));
                }
                if refresh_recent
                    && let Some((watch_generation, provider, id)) = &recent_live
                    && *watch_generation == current_generation.load(Ordering::SeqCst)
                {
                    emit(Event::RecentLiveChannels(
                        *watch_generation,
                        provider.clone(),
                        id.clone(),
                        recent_live_channels(&store, provider, id),
                    ));
                }
            }
        });
        Self {
            tx,
            playback_generation,
            rx,
            join: Some(join),
        }
    }
    pub fn send(&self, command: Command) {
        let generation = if matches!(
            &command,
            Command::Prepare(_)
                | Command::Restart(_)
                | Command::ResumeHistory(_)
                | Command::PlaySeries(_)
                | Command::CancelPlayback
                | Command::Shutdown
        ) {
            self.playback_generation.fetch_add(1, Ordering::SeqCst) + 1
        } else {
            self.generation()
        };
        let _ = self.tx.send((generation, command));
    }
    #[cfg(test)]
    pub fn complete_for_test(&self, generation: u64, command: Command) {
        self.tx.send((generation, command)).unwrap();
    }
    pub fn generation(&self) -> u64 {
        self.playback_generation.load(Ordering::SeqCst)
    }
    pub fn shutdown(&mut self) {
        if self.join.is_none() {
            return;
        }
        // Dropping the main sender is insufficient while network workers exist.
        // Shutdown is an ordered message: all pending preference/progress writes finish.
        self.send(Command::Shutdown);
        if let Some(join) = self.join.take() {
            let _ = join.join();
        }
    }
}

impl Drop for Worker {
    fn drop(&mut self) {
        self.shutdown();
    }
}

fn recent_live_channels(
    store: &Store,
    current_provider: &str,
    current_id: &str,
) -> Result<Vec<CatalogItem>> {
    let mut seen = std::collections::HashSet::new();
    let mut channels = Vec::new();
    for entry in store.recent_history(80)? {
        if entry.item_type != "live"
            || (entry.provider_id == current_provider && entry.item_id == current_id)
            || !seen.insert((entry.provider_id.clone(), entry.item_id.clone()))
        {
            continue;
        }
        let Some(mut item) = store.item(&entry.provider_id, "live", &entry.item_id)? else {
            continue;
        };
        let direct = item
            .stream_url
            .as_deref()
            .map(str::trim)
            .filter(|url| !url.is_empty() && !url.contains('\0'))
            .map(str::to_owned);
        let resolved = direct.or_else(|| {
            let provider = store.provider(&item.provider_id).ok()??;
            let json = item.stream_json.as_deref()?;
            imports::resolve_stream_url(&provider, json, "live").ok()
        });
        let Some(url) = resolved.filter(|url| !url.trim().is_empty() && !url.contains('\0')) else {
            continue;
        };
        item.stream_url = Some(url);
        channels.push(item);
        if channels.len() == 10 {
            break;
        }
    }
    Ok(channels)
}

fn playback_queue(store: &Store, provider: &str, series: &str) -> Result<Vec<Episode>> {
    let credentials = store.provider(provider)?;
    Ok(store
        .episodes(provider, series)?
        .into_iter()
        .filter_map(|mut episode| {
            let direct = episode
                .stream_url
                .as_deref()
                .map(str::trim)
                .filter(|value| !value.is_empty() && !value.contains('\0'))
                .map(str::to_owned);
            episode.stream_url = direct.or_else(|| {
                imports::resolve_stream_url(
                    credentials.as_ref()?,
                    episode.stream_json.as_deref()?,
                    "episode",
                )
                .ok()
            });
            episode.stream_url.as_ref()?;
            Some(episode)
        })
        .collect())
}
fn series_playback(
    store: &Store,
    provider: &str,
    series: &str,
) -> Result<(PlaybackTarget, Option<PlaybackProgress>, Vec<Episode>)> {
    let episodes = playback_queue(store, provider, series)?;
    anyhow::ensure!(!episodes.is_empty(), "This series has no playable episodes");
    let positions = store.detail_positions(provider, "series", series)?;
    let scoped_index = |position: &PlaybackProgress| {
        if position.provider_id != provider
            || position.item_type != "episode"
            || position.series_id.as_deref() != Some(series)
        {
            return None;
        }
        episodes.iter().position(|episode| {
            episode.id == position.item_id
                && Some(episode.season_id.as_str()) == position.season_id.as_deref()
        })
    };
    if let Some(position) = positions
        .iter()
        .filter(|position| {
            !position.completed && position.position_seconds > 0 && scoped_index(position).is_some()
        })
        .max_by_key(|position| position.last_watched_at)
    {
        let index = scoped_index(position).expect("filtered valid position");
        return Ok((
            PlaybackTarget::episode(&episodes[index]),
            Some(position.clone()),
            episodes,
        ));
    }
    let index = positions
        .iter()
        .filter(|position| {
            (position.completed || position.position_seconds > 0)
                && scoped_index(position).is_some()
        })
        .max_by_key(|position| position.last_watched_at)
        .and_then(|position| {
            scoped_index(position).map(|index| {
                if position.completed {
                    (index + 1).min(episodes.len() - 1)
                } else {
                    index
                }
            })
        })
        .unwrap_or(0);
    Ok((PlaybackTarget::episode(&episodes[index]), None, episodes))
}

impl Origin {
    fn is_current(
        &self,
        store: &Store,
        revisions: &std::collections::HashMap<String, u64>,
    ) -> Result<bool> {
        Ok(
            *revisions.get(&self.provider.id).unwrap_or(&0) == self.revision
                && store.provider(&self.provider.id)?.is_some_and(|current| {
                    current.source == self.provider.source
                        && current.kind == self.provider.kind
                        && current.username == self.provider.username
                        && current.password == self.provider.password
                        && current.source_kind == self.provider.source_kind
                }),
        )
    }
}

fn scheduled_refreshes(
    providers: Vec<Provider>,
    refreshing: &std::collections::HashSet<String>,
    attempts: &std::collections::HashMap<String, std::time::Instant>,
    slots: usize,
    now: i64,
) -> Vec<Provider> {
    providers
        .into_iter()
        .filter(|p| {
            p.is_enabled
                && p.auto_refresh_enabled
                && p.last_refresh_at
                    .is_none_or(|last| now - last >= p.auto_refresh_interval_minutes * 60_000)
                && !refreshing.contains(&p.id)
                && attempts
                    .get(&p.id)
                    .is_none_or(|at| at.elapsed() >= Duration::from_secs(300))
        })
        .take(slots)
        .collect()
}

fn search_library(store: &Store, search: &str) -> Result<GlobalSearchResults> {
    let query = search.trim().to_owned();
    let mut groups = Vec::new();
    if query.is_empty() {
        return Ok(GlobalSearchResults { query, groups });
    }
    const LIMIT: usize = 8;
    for (title, icon, kind) in [
        ("Live", "tv", "live"),
        ("Movies", "film", "movie"),
        ("Series", "library", "series"),
    ] {
        let items = store
            .catalog(&CatalogQuery {
                content_type: Some(kind.into()),
                search: query.clone(),
                limit: LIMIT,
                ..Default::default()
            })?
            .items;
        if !items.is_empty() {
            groups.push(GlobalSearchGroup {
                title,
                icon,
                results: items
                    .into_iter()
                    .map(|item| GlobalSearchResult {
                        item,
                        progress: None,
                    })
                    .collect(),
            });
        }
    }
    let mut favorites = Vec::new();
    for kind in ["live", "movie", "series"] {
        favorites.extend(
            store
                .catalog(&CatalogQuery {
                    content_type: Some(kind.into()),
                    favorites_only: true,
                    search: query.clone(),
                    limit: LIMIT,
                    ..Default::default()
                })?
                .items
                .into_iter()
                .take(LIMIT - favorites.len())
                .map(|item| GlobalSearchResult {
                    item,
                    progress: None,
                }),
        );
        if favorites.len() >= LIMIT {
            break;
        }
    }
    if !favorites.is_empty() {
        groups.push(GlobalSearchGroup {
            title: "Favorites",
            icon: "star",
            results: favorites,
        });
    }
    let normalized = query.to_lowercase();
    let mut recent = Vec::new();
    let mut seen = std::collections::HashSet::new();
    for progress in store.recent_history(1000)? {
        if !progress.title.to_lowercase().contains(&normalized)
            && !progress
                .subtitle
                .as_deref()
                .is_some_and(|text| text.to_lowercase().contains(&normalized))
        {
            continue;
        }
        let (kind, id) = if progress.item_type == "episode" {
            ("series", progress.series_id.as_deref().unwrap_or(""))
        } else {
            (progress.item_type.as_str(), progress.item_id.as_str())
        };
        if !seen.insert((progress.provider_id.clone(), kind.to_owned(), id.to_owned())) {
            continue;
        }
        let Some(item) = store.item(&progress.provider_id, kind, id)? else {
            continue;
        };
        let playable = if kind == "series" {
            !store.episodes(&progress.provider_id, id)?.is_empty()
        } else {
            item.stream_url
                .as_deref()
                .is_some_and(|url| !url.trim().is_empty())
                || item
                    .stream_json
                    .as_deref()
                    .is_some_and(|json| !json.trim().is_empty())
        };
        if !playable {
            continue;
        }
        recent.push(GlobalSearchResult {
            item,
            progress: Some(progress),
        });
        if recent.len() >= LIMIT {
            break;
        }
    }
    if !recent.is_empty() {
        groups.push(GlobalSearchGroup {
            title: "Recent",
            icon: "history",
            results: recent,
        });
    }
    Ok(GlobalSearchResults { query, groups })
}

#[cfg(test)]
mod scheduling_tests {
    use super::*;
    #[test]
    fn cooling_down_and_running_providers_do_not_starve_later_due_provider() {
        let providers = ["a", "b", "c"]
            .map(|id| Provider {
                id: id.into(),
                is_enabled: true,
                auto_refresh_enabled: true,
                auto_refresh_interval_minutes: 60,
                ..Default::default()
            })
            .to_vec();
        let running = std::collections::HashSet::from(["a".into()]);
        let attempts = std::collections::HashMap::from([("b".into(), std::time::Instant::now())]);
        let selected = scheduled_refreshes(providers.clone(), &running, &attempts, 1, 1000);
        assert_eq!(
            selected.iter().map(|p| p.id.as_str()).collect::<Vec<_>>(),
            ["c"]
        );
        assert!(scheduled_refreshes(providers, &running, &attempts, 0, 1000).is_empty());
    }
}

#[cfg(test)]
mod live_player_tests {
    use super::*;
    fn provider(id: &str) -> Provider {
        Provider {
            id: id.into(),
            kind: "m3u".into(),
            name: id.into(),
            source: "https://fixture.invalid/list".into(),
            is_enabled: true,
            auto_refresh_interval_minutes: 1440,
            ..Default::default()
        }
    }
    fn item(id: &str) -> CatalogItem {
        CatalogItem {
            id: id.into(),
            provider_id: "p".into(),
            content_type: "live".into(),
            title: format!("Current {id}"),
            stream_url: Some(format!("https://fixture.invalid/{id}.ts")),
            ..Default::default()
        }
    }
    fn progress(id: &str, updated: i64) -> PlaybackProgress {
        PlaybackProgress {
            provider_id: "p".into(),
            item_id: id.into(),
            item_type: "live".into(),
            title: "Old history title".into(),
            last_watched_at: updated,
            ..Default::default()
        }
    }
    fn next(worker: &Worker, accept: impl Fn(&Event) -> bool) -> Event {
        let deadline = std::time::Instant::now() + Duration::from_secs(10);
        loop {
            let event = worker
                .rx
                .recv_timeout(deadline.saturating_duration_since(std::time::Instant::now()))
                .expect("worker response");
            if accept(&event) {
                return event;
            }
            if let Event::Error(error) | Event::Fatal(error) = event {
                panic!("{error}");
            }
        }
    }
    #[test]
    fn recent_live_resolves_current_catalog_deduplicates_filters_and_refreshes_on_progress_and_switch()
    -> Result<()> {
        let temp = tempfile::tempdir()?;
        let path = temp.path().join("recent.sqlite");
        let store = Store::open(&path)?;
        store.upsert_provider(&provider("p"))?;
        let mut items = (0..18).map(|i| item(&i.to_string())).collect::<Vec<_>>();
        items[15].stream_url = None;
        store.replace_catalog(&ImportSnapshot {
            provider_id: "p".into(),
            items: items.clone(),
            ..Default::default()
        })?;
        for i in 0..18 {
            store.save_progress(&progress(&i.to_string(), 1_700_000_000_000 + i))?;
        }
        items.retain(|item| item.id != "16");
        store.replace_catalog(&ImportSnapshot {
            provider_id: "p".into(),
            items,
            ..Default::default()
        })?;
        let mut xtream = provider("other");
        xtream.kind = "xtream".into();
        xtream.source = "https://fixture.invalid".into();
        xtream.username = Some("u".into());
        xtream.password = Some("p".into());
        store.upsert_provider(&xtream)?;
        let cross = CatalogItem {
            provider_id: "other".into(),
            stream_url: None,
            stream_json: Some(
                r#"{"providerType":"xtream","streamId":"42","containerExtension":"ts"}"#.into(),
            ),
            ..item("17")
        };
        store.replace_catalog(&ImportSnapshot {
            provider_id: "other".into(),
            items: vec![cross],
            ..Default::default()
        })?;
        store.save_progress(&PlaybackProgress {
            provider_id: "other".into(),
            ..progress("17", 1_700_000_005_000)
        })?;
        let connection = rusqlite::Connection::open(&path)?;
        connection.execute("INSERT INTO watch_history(catalog_key,item_id,item_type,provider_id,title,subtitle,artwork_url,series_id,season_id,position_seconds,duration_seconds,completion_percentage,completed,last_watched_at,watch_count) SELECT 'legacy-duplicate',item_id,item_type,provider_id,title,subtitle,artwork_url,series_id,season_id,position_seconds,duration_seconds,completion_percentage,completed,last_watched_at+2000,watch_count FROM watch_history WHERE provider_id='p' AND item_id='12'",[])?;
        drop(connection);
        let channels = recent_live_channels(&store, "p", "17")?;
        assert_eq!(channels.len(), 10);
        assert!(channels.iter().all(
            |item| !(item.provider_id == "p" && ["17", "16", "15"].contains(&item.id.as_str()))
        ));
        assert_eq!(
            channels
                .iter()
                .map(|item| (&item.provider_id, &item.id))
                .collect::<std::collections::HashSet<_>>()
                .len(),
            10
        );
        assert!(channels.iter().any(|item| item.provider_id == "other"
            && item.id == "17"
            && item.stream_url.as_deref() == Some("https://fixture.invalid/live/u/p/42.ts")));
        assert!(
            channels
                .iter()
                .all(|item| item.title.starts_with("Current"))
        );
        drop(store);
        let mut worker = Worker::test_new(egui::Context::default(), path);
        next(&worker, |event| matches!(event, Event::Ready(_)));
        worker.send(Command::WatchRecentLive(Some(("p".into(), "17".into()))));
        next(&worker, |event| {
            matches!(event, Event::RecentLiveChannels(..))
        });
        worker.send(Command::Progress(progress("0", 1_700_000_010_000)));
        match next(&worker, |event| {
            matches!(event, Event::RecentLiveChannels(..))
        }) {
            Event::RecentLiveChannels(_, _, _, Ok(channels)) => assert_eq!(channels[0].id, "0"),
            _ => panic!("recent list refresh"),
        }
        worker.send(Command::Prepare(PlaybackTarget::catalog(item("0"))));
        next(&worker, |event| matches!(event, Event::Prepared(..)));
        worker.send(Command::WatchRecentLive(Some(("p".into(), "0".into()))));
        match next(&worker, |event| {
            matches!(event, Event::RecentLiveChannels(..))
        }) {
            Event::RecentLiveChannels(generation, _, current, Ok(channels)) => {
                assert_eq!(generation, worker.generation());
                assert_eq!(current, "0");
                assert!(
                    !channels
                        .iter()
                        .any(|item| item.provider_id == "p" && item.id == "0")
                );
                assert!(
                    channels
                        .iter()
                        .any(|item| item.provider_id == "p" && item.id == "17")
                );
            }
            _ => panic!("switched recent list"),
        }
        worker.shutdown();
        Ok(())
    }
    #[test]
    fn restart_preserves_authoritative_progress_and_detail_failures_stay_scoped() -> Result<()> {
        let temp = tempfile::tempdir()?;
        let path = temp.path().join("restart.sqlite");
        let store = Store::open(&path)?;
        store.upsert_provider(&provider("p"))?;
        let movie = CatalogItem {
            content_type: "movie".into(),
            ..item("film")
        };
        store.replace_catalog(&ImportSnapshot {
            provider_id: "p".into(),
            items: vec![movie.clone()],
            ..Default::default()
        })?;
        store.save_progress(&PlaybackProgress {
            item_type: "movie".into(),
            position_seconds: 42,
            ..progress("film", 1_700_000_000_000)
        })?;
        drop(store);
        let mut worker = Worker::test_new(egui::Context::default(), path.clone());
        next(&worker, |event| matches!(event, Event::Ready(_)));
        worker.send(Command::Prepare(PlaybackTarget::catalog(movie.clone())));
        assert!(
            matches!(next(&worker,|event|matches!(event,Event::Prepared(..))),Event::Prepared(_,Some(progress)) if progress.position_seconds==42)
        );
        worker.send(Command::Restart(PlaybackTarget::catalog(movie)));
        assert!(
            matches!(next(&worker,|event|matches!(event,Event::Prepared(..))),Event::Prepared(target,None) if target.generation==worker.generation())
        );
        worker.send(Command::MovieFetched(
            Origin {
                provider: provider("p"),
                revision: 0,
            },
            "film".into(),
            Err(anyhow::anyhow!("metadata unavailable")),
        ));
        assert!(
            matches!(next(&worker,|event|matches!(event,Event::DetailStatus(..))),Event::DetailStatus(provider,kind,id,false,Some(_)) if provider=="p"&&kind=="movie"&&id=="film")
        );
        worker.shutdown();
        assert_eq!(
            Store::open(&path)?
                .resume("p", "movie", "film", None, None)?
                .unwrap()
                .position_seconds,
            42
        );
        Ok(())
    }
    #[test]
    fn series_resume_uses_all_scoped_positions_even_beyond_global_history_limit() -> Result<()> {
        let temp = tempfile::tempdir()?;
        let path = temp.path().join("old-series.sqlite");
        let store = Store::open(&path)?;
        store.upsert_provider(&provider("p"))?;
        store.replace_catalog(&ImportSnapshot {
            provider_id: "p".into(),
            items: vec![CatalogItem {
                id: "series".into(),
                provider_id: "p".into(),
                content_type: "series".into(),
                title: "Series".into(),
                ..Default::default()
            }],
            ..Default::default()
        })?;
        let episode = Episode {
            id: "episode".into(),
            provider_id: "p".into(),
            series_id: "series".into(),
            season_id: "1".into(),
            season_number: 1,
            episode_number: 1,
            title: "Episode".into(),
            stream_url: Some("https://fixture.invalid/e.ts".into()),
            ..Default::default()
        };
        store.replace_series_details(&SeriesDetails {
            series: Series {
                id: "series".into(),
                provider_id: "p".into(),
                title: "Series".into(),
                ..Default::default()
            },
            seasons: vec![Season {
                provider_id: "p".into(),
                series_id: "series".into(),
                season_number: 1,
                ..Default::default()
            }],
            episodes: vec![episode],
        })?;
        store.save_progress(&PlaybackProgress {
            item_type: "episode".into(),
            series_id: Some("series".into()),
            season_id: Some("1".into()),
            position_seconds: 37,
            ..progress("episode", 1_700_000_000_000)
        })?;
        for i in 0..1005 {
            store.save_progress(&PlaybackProgress {
                item_type: "movie".into(),
                position_seconds: 1,
                ..progress(&format!("other-{i}"), 1_700_000_000_100 + i)
            })?;
        }
        assert!(
            !store
                .recent_history(1000)?
                .iter()
                .any(|p| p.item_type == "episode")
        );
        let (target, resume, _) = series_playback(&store, "p", "series")?;
        assert_eq!(target.item.id, "episode");
        assert_eq!(resume.unwrap().position_seconds, 37);
        Ok(())
    }
}

#[cfg(test)]
mod foreground_lane_tests {
    use super::*;
    #[test]
    fn rapid_navigation_keeps_only_the_newest_pending_network_request() {
        let lane = LatestNetworkLane::new();
        let (started_tx, started_rx) = mpsc::channel();
        let (release_tx, release_rx) = mpsc::channel();
        lane.submit(move || {
            started_tx.send(()).unwrap();
            release_rx.recv_timeout(Duration::from_secs(5)).unwrap();
        });
        started_rx.recv_timeout(Duration::from_secs(5)).unwrap();
        let (finished_tx, finished_rx) = mpsc::channel();
        for selected_item in 0..500 {
            let finished = finished_tx.clone();
            lane.submit(move || {
                let _ = finished.send(selected_item);
            });
        }
        release_tx.send(()).unwrap();
        assert_eq!(
            finished_rx.recv_timeout(Duration::from_secs(5)).unwrap(),
            499
        );
        assert!(finished_rx.try_recv().is_err());
    }
}
