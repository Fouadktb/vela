use anyhow::Result;
use eframe::egui;
use std::{
    collections::BTreeMap,
    path::PathBuf,
    sync::{
        Arc,
        atomic::{AtomicU64, AtomicUsize, Ordering},
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
    MovieFetched(Origin, Result<CatalogItem>),
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
    CancelPlayback,
    ResumeHistory(PlaybackProgress),
    Backup(PathBuf),
    Diagnostics(PathBuf),
    ClearHistory,
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
    Epg(Vec<EpgProgram>),
    Prepared(Box<PlaybackTarget>, Option<PlaybackProgress>),
    Busy(bool),
    ResetComplete(PathBuf),
    PlaybackQueue(u64, Vec<Episode>),
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
            let active = Arc::new(AtomicUsize::new(0));
            let mut revisions = std::collections::HashMap::<String, u64>::new();
            let mut refreshing = std::collections::HashSet::new();
            let mut refresh_runs = std::collections::HashMap::<String, String>::new();
            let mut last_attempt = std::collections::HashMap::<String, std::time::Instant>::new();
            let mut last_schedule = std::time::Instant::now() - Duration::from_secs(60);
            loop {
                if last_schedule.elapsed() >= Duration::from_secs(30) {
                    last_schedule = std::time::Instant::now();
                    if let Ok(providers) = store.providers() {
                        for provider in scheduled_refreshes(
                            providers,
                            &refreshing,
                            &last_attempt,
                            2usize.saturating_sub(active.load(Ordering::Relaxed)),
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
                        | Command::ResumeHistory(_)
                        | Command::PlaySeries(_)
                        | Command::PlaySeriesFetched(..)
                ) && generation != current_generation.load(Ordering::SeqCst)
                {
                    continue;
                }
                let result: Result<()> = (|| {
                    match command {
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
                        Command::Progress(progress) => store.save_progress(&progress)?,
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
                            let resume = store.resume(
                                &target.item.provider_id,
                                &target.item.content_type,
                                &target.item.id,
                                target.series_id.as_deref(),
                                target.season_id.as_deref(),
                            )?;
                            target.generation = generation;
                            emit(Event::PlaybackQueue(
                                generation,
                                if let Some(series) = &target.series_id {
                                    store.episodes(&target.item.provider_id, series)?
                                } else {
                                    vec![]
                                },
                            ));
                            emit(Event::Prepared(Box::new(target), resume));
                        }
                        Command::Prepare(mut target) => {
                            let progress = store.resume(
                                &target.item.provider_id,
                                &target.item.content_type,
                                &target.item.id,
                                target.series_id.as_deref(),
                                target.season_id.as_deref(),
                            )?;
                            target.generation = generation;
                            emit(Event::PlaybackQueue(
                                generation,
                                if let Some(series) = &target.series_id {
                                    store.episodes(&target.item.provider_id, series)?
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
                            if active.load(Ordering::Relaxed) >= 2 {
                                refreshing.remove(&provider.id);
                                anyhow::bail!(
                                    "Two imports are already running. Wait for one to finish."
                                );
                            }
                            let run_id = store.record_refresh_start(&provider.id)?;
                            refresh_runs.insert(provider.id.clone(), run_id);
                            active.fetch_add(1, Ordering::Relaxed);
                            emit(Event::Busy(true));
                            let mut tx = network_tx.clone();
                            tx.generation = generation;
                            let counter = active.clone();
                            thread::spawn(move || {
                                let result = imports::import_provider(&provider);
                                counter.fetch_sub(1, Ordering::Relaxed);
                                let _ = tx.send(Command::Imported(origin, result));
                            });
                        }
                        Command::Imported(origin, result) => {
                            let provider = &origin.provider;
                            refreshing.remove(&provider.id);
                            emit(Event::Busy(active.load(Ordering::Relaxed) > 0));
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
                            let result=result.and_then(|snapshot|{anyhow::ensure!(!snapshot.items.is_empty(),"Provider returned no playable items; your previous library was kept");store.replace_catalog(&snapshot)?;Ok(snapshot.items.len())});
                            if let Some(run) = refresh_runs.remove(&provider.id) {
                                match &result {
                                    Ok(count) => store.finish_refresh(&run, *count as i64, None)?,
                                    Err(error) => {
                                        store.finish_refresh(&run, 0, Some(&error.to_string()))?
                                    }
                                }
                            }
                            let count = result?;
                            emit(Event::Message(format!(
                                "Imported {count} items from {}",
                                provider.name
                            )));
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
                                emit(Event::PlaybackQueue(generation, episodes));
                                emit(Event::Prepared(Box::new(target), resume));
                            } else {
                                anyhow::ensure!(
                                    provider.kind == "xtream",
                                    "No playable episodes are available. Refresh the provider first."
                                );
                                anyhow::ensure!(
                                    active.load(Ordering::Relaxed) < 2,
                                    "An import is running; try playing the series again shortly."
                                );
                                active.fetch_add(1, Ordering::Relaxed);
                                let mut tx = network_tx.clone();
                                tx.generation = generation;
                                let counter = active.clone();
                                thread::spawn(move || {
                                    let result = imports::fetch_series(
                                        &provider,
                                        item.external_id.as_deref().unwrap_or(""),
                                        &item.id,
                                    );
                                    counter.fetch_sub(1, Ordering::Relaxed);
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
                            emit(Event::PlaybackQueue(generation, episodes));
                            emit(Event::Prepared(Box::new(target), resume));
                        }
                        Command::Series(provider, item) => {
                            let Some(provider) = store.provider(&provider.id)? else {
                                return Ok(());
                            };
                            let origin = Origin {
                                provider: provider.clone(),
                                revision: *revisions.get(&provider.id).unwrap_or(&0),
                            };
                            let current = store.episodes(&item.provider_id, &item.id)?;
                            if provider.kind != "xtream" || item.external_id.is_none() {
                                emit(Event::Series(
                                    item.provider_id.clone(),
                                    item.id.clone(),
                                    current,
                                ));
                            } else {
                                emit(Event::Series(
                                    item.provider_id.clone(),
                                    item.id.clone(),
                                    current,
                                ));
                                if active.load(Ordering::Relaxed) >= 2 {
                                    anyhow::bail!(
                                        "An import is still running; try opening this series again shortly."
                                    );
                                }
                                active.fetch_add(1, Ordering::Relaxed);
                                let mut tx = network_tx.clone();
                                tx.generation = generation;
                                let counter = active.clone();
                                thread::spawn(move || {
                                    let result = imports::fetch_series(
                                        &provider,
                                        item.external_id.as_deref().unwrap_or(""),
                                        &item.id,
                                    );
                                    counter.fetch_sub(1, Ordering::Relaxed);
                                    let _ =
                                        tx.send(Command::SeriesFetched(origin, item.id, result));
                                });
                            }
                        }
                        Command::SeriesFetched(origin, series, result) => {
                            if !origin.is_current(&store, &revisions)? {
                                return Ok(());
                            }
                            let provider = origin.provider.id;
                            let details = result?;
                            store.replace_series_details(&details)?;
                            emit(Event::Series(
                                provider.clone(),
                                series.clone(),
                                store.episodes(&provider, &series)?,
                            ));
                        }
                        Command::Movie(provider, item) => {
                            let Some(provider) = store.provider(&provider.id)? else {
                                return Ok(());
                            };
                            let origin = Origin {
                                provider: provider.clone(),
                                revision: *revisions.get(&provider.id).unwrap_or(&0),
                            };
                            if active.load(Ordering::Relaxed) >= 2 {
                                anyhow::bail!(
                                    "An import is still running; try opening the movie again shortly."
                                );
                            }
                            active.fetch_add(1, Ordering::Relaxed);
                            let mut tx = network_tx.clone();
                            tx.generation = generation;
                            let counter = active.clone();
                            thread::spawn(move || {
                                let result = imports::fetch_movie(
                                    &provider,
                                    item.external_id.as_deref().unwrap_or(""),
                                    &item.id,
                                );
                                counter.fetch_sub(1, Ordering::Relaxed);
                                let _ = tx.send(Command::MovieFetched(origin, result));
                            });
                        }
                        Command::MovieFetched(origin, result) => {
                            if !origin.is_current(&store, &revisions)? {
                                return Ok(());
                            }
                            let metadata = result?;
                            store.update_item_metadata(&metadata)?;
                            if let Some(item) = store.item(
                                &metadata.provider_id,
                                &metadata.content_type,
                                &metadata.id,
                            )? {
                                emit(Event::Metadata(item));
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
                            if active.load(Ordering::Relaxed) >= 2 {
                                anyhow::bail!(
                                    "An import is still running; try the guide refresh again shortly."
                                );
                            }
                            active.fetch_add(1, Ordering::Relaxed);
                            let mut tx = network_tx.clone();
                            tx.generation = generation;
                            let counter = active.clone();
                            thread::spawn(move || {
                                let result = imports::fetch_epg(&provider);
                                counter.fetch_sub(1, Ordering::Relaxed);
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
                        Command::CheckUpdates => {
                            let mut tx = network_tx.clone();
                            tx.generation = generation;
                            std::thread::spawn(move || {
                                let _ =
                                    tx.send(Command::UpdatesFetched(vela_core::updates::check()));
                            });
                        }
                        Command::UpdatesFetched(result) => emit(Event::Updates(result)),
                        Command::CancelPlayback | Command::Shutdown => return Ok(()),
                    }
                    Ok(())
                })();
                if let Err(error) = result {
                    emit(Event::Error(format!("{error}")));
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

fn series_playback(
    store: &Store,
    provider: &str,
    series: &str,
) -> Result<(PlaybackTarget, Option<PlaybackProgress>, Vec<Episode>)> {
    let episodes = store.episodes(provider, series)?;
    anyhow::ensure!(!episodes.is_empty(), "This series has no playable episodes");
    let history = store.recent_history(1000)?;
    let current = history.iter().find(|p| {
        p.provider_id == provider
            && p.series_id.as_deref() == Some(series)
            && p.item_type == "episode"
    });
    let index = current
        .and_then(|p| {
            episodes
                .iter()
                .position(|e| e.id == p.item_id && Some(&e.season_id) == p.season_id.as_ref())
                .map(|index| {
                    if p.completed {
                        (index + 1) % episodes.len()
                    } else {
                        index
                    }
                })
        })
        .unwrap_or(0);
    let target = PlaybackTarget::episode(&episodes[index]);
    let resume = store.resume(
        provider,
        "episode",
        &target.item.id,
        target.series_id.as_deref(),
        target.season_id.as_deref(),
    )?;
    Ok((target, resume, episodes))
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
