//! Embedded libmpv player. The command/event thread never blocks the GL render thread.
//! Call `shutdown_gl` from `eframe::App::on_exit`, while its GL context is current.
use anyhow::{Context, Result, anyhow, bail};
use eframe::{egui, egui_glow, glow};
use glow::HasContext;
use libloading::Library;
use serde::{Deserialize, Serialize};
use std::{
    collections::HashSet,
    ffi::{CStr, CString, c_char, c_int, c_void},
    path::{Path, PathBuf},
    ptr,
    sync::{Arc, Mutex, RwLock, mpsc},
    thread::{self, JoinHandle},
};

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Track {
    pub id: i64,
    pub kind: String,
    pub title: String,
    pub language: Option<String>,
    pub selected: bool,
}
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerState {
    pub position: f64,
    pub duration: f64,
    pub paused: bool,
    pub volume: f64,
    pub muted: bool,
    pub speed: f64,
    pub loading: bool,
    pub ended: bool,
    pub error: Option<String>,
    pub tracks: Vec<Track>,
}
impl Default for PlayerState {
    fn default() -> Self {
        Self {
            position: 0.,
            duration: 0.,
            paused: true,
            volume: 100.,
            muted: false,
            speed: 1.,
            loading: false,
            ended: false,
            error: None,
            tracks: vec![],
        }
    }
}

#[repr(C)]
struct Event {
    id: c_int,
    error: c_int,
    userdata: u64,
    data: *mut c_void,
}
#[repr(C)]
struct Property {
    name: *const c_char,
    format: c_int,
    data: *mut c_void,
}
#[repr(C)]
struct EndFile {
    reason: c_int,
    error: c_int,
    playlist_entry_id: i64,
    playlist_insert_id: i64,
    playlist_insert_num_entries: c_int,
}
#[repr(C)]
struct Param {
    kind: c_int,
    data: *mut c_void,
}
impl Param {
    fn end() -> Self {
        Self {
            kind: 0,
            data: ptr::null_mut(),
        }
    }
}
#[repr(C)]
struct GlInit {
    get_proc: unsafe extern "C" fn(*mut c_void, *const c_char) -> *mut c_void,
    ctx: *mut c_void,
}
#[repr(C)]
struct Fbo {
    fbo: c_int,
    width: c_int,
    height: c_int,
    internal_format: c_int,
}
#[repr(C)]
union NodeValue {
    string: *mut c_char,
    list: *mut NodeList,
    integer: i64,
    double: f64,
}
#[repr(C)]
struct Node {
    value: NodeValue,
    format: c_int,
}
#[repr(C)]
struct NodeList {
    count: c_int,
    values: *mut Node,
    keys: *mut *mut c_char,
}

type Handle = *mut c_void;
struct Api {
    _library: Library,
    path: PathBuf,
    create: unsafe extern "C" fn() -> Handle,
    initialize: unsafe extern "C" fn(Handle) -> c_int,
    destroy: unsafe extern "C" fn(Handle),
    option: unsafe extern "C" fn(Handle, *const c_char, *const c_char) -> c_int,
    set: unsafe extern "C" fn(Handle, *const c_char, c_int, *mut c_void) -> c_int,
    set_string: unsafe extern "C" fn(Handle, *const c_char, *const c_char) -> c_int,
    get_string: unsafe extern "C" fn(Handle, *const c_char) -> *mut c_char,
    command: unsafe extern "C" fn(Handle, *const *const c_char) -> c_int,
    observe: unsafe extern "C" fn(Handle, u64, *const c_char, c_int) -> c_int,
    wait: unsafe extern "C" fn(Handle, f64) -> *const Event,
    free: unsafe extern "C" fn(*mut c_void),
    error: unsafe extern "C" fn(c_int) -> *const c_char,
    render_create: unsafe extern "C" fn(*mut Handle, Handle, *mut Param) -> c_int,
    render_free: unsafe extern "C" fn(Handle),
    render: unsafe extern "C" fn(Handle, *mut Param) -> c_int,
    render_callback:
        unsafe extern "C" fn(Handle, Option<unsafe extern "C" fn(*mut c_void)>, *mut c_void),
}
impl Api {
    fn load() -> Result<Arc<Self>> {
        let candidates = library_candidates();
        let mut failures = Vec::new();
        for path in candidates {
            // libmpv is an explicit native dependency, never an untrusted media path.
            match unsafe { Self::load_from(&path) } {
                Ok(api) => return Ok(Arc::new(api)),
                Err(e) => failures.push(format!("{}: {e}", path.display())),
            }
        }
        bail!(
            "libmpv could not be loaded. Install the bundled runtime or set VELA_MPV_LIBRARY. Tried:\n{}",
            failures.join("\n")
        )
    }
    unsafe fn load_from(path: &Path) -> Result<Self> {
        let library = unsafe { Library::new(path) }?;
        macro_rules! sym {
            ($name:literal) => {
                unsafe { *library.get(concat!($name, "\0").as_bytes())? }
            };
        }
        Ok(Self {
            create: sym!("mpv_create"),
            initialize: sym!("mpv_initialize"),
            destroy: sym!("mpv_terminate_destroy"),
            option: sym!("mpv_set_option_string"),
            set: sym!("mpv_set_property"),
            set_string: sym!("mpv_set_property_string"),
            get_string: sym!("mpv_get_property_string"),
            command: sym!("mpv_command"),
            observe: sym!("mpv_observe_property"),
            wait: sym!("mpv_wait_event"),
            free: sym!("mpv_free"),
            error: sym!("mpv_error_string"),
            render_create: sym!("mpv_render_context_create"),
            render_free: sym!("mpv_render_context_free"),
            render: sym!("mpv_render_context_render"),
            render_callback: sym!("mpv_render_context_set_update_callback"),
            _library: library,
            path: path.into(),
        })
    }
    fn check(&self, code: c_int) -> Result<()> {
        if code < 0 {
            let text = unsafe { CStr::from_ptr((self.error)(code)) };
            bail!("{} ({code})", text.to_string_lossy());
        }
        Ok(())
    }
    fn option(&self, h: Handle, key: &str, value: &str) -> Result<()> {
        let k = CString::new(key)?;
        let v = CString::new(value)?;
        self.check(unsafe { (self.option)(h, k.as_ptr(), v.as_ptr()) })
            .with_context(|| format!("mpv option {key}"))
    }
    fn set_string(&self, h: Handle, key: &str, value: &str) -> Result<()> {
        let k = CString::new(key)?;
        let v = CString::new(value)?;
        self.check(unsafe { (self.set_string)(h, k.as_ptr(), v.as_ptr()) })
            .with_context(|| format!("mpv property {key}"))
    }
    fn get(&self, h: Handle, key: &str) -> Option<String> {
        let k = CString::new(key).ok()?;
        let p = unsafe { (self.get_string)(h, k.as_ptr()) };
        if p.is_null() {
            return None;
        }
        let value = unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned();
        unsafe { (self.free)(p.cast()) };
        Some(value)
    }
    fn command(&self, h: Handle, args: &[String]) -> Result<()> {
        let strings: Vec<_> = args
            .iter()
            .map(|v| CString::new(v.as_str()))
            .collect::<std::result::Result<_, _>>()?;
        let mut pointers: Vec<_> = strings.iter().map(|v| v.as_ptr()).collect();
        pointers.push(ptr::null());
        self.check(unsafe { (self.command)(h, pointers.as_ptr()) })
    }
    fn headers(&self, h: Handle, headers: &[(String, String)]) -> Result<()> {
        // A typed node array avoids mpv's comma-separated option parsing entirely.
        let strings: Vec<_> = headers
            .iter()
            .map(|(k, v)| CString::new(format!("{k}: {v}")))
            .collect::<std::result::Result<_, _>>()?;
        let mut nodes: Vec<_> = strings
            .iter()
            .map(|s| Node {
                value: NodeValue {
                    string: s.as_ptr().cast_mut(),
                },
                format: 1,
            })
            .collect();
        let mut list = NodeList {
            count: nodes.len() as c_int,
            values: nodes.as_mut_ptr(),
            keys: ptr::null_mut(),
        };
        let mut node = Node {
            value: NodeValue { list: &mut list },
            format: 7,
        };
        self.check(unsafe {
            (self.set)(
                h,
                c"http-header-fields".as_ptr(),
                6,
                (&mut node as *mut Node).cast(),
            )
        })
    }
}

/// Ordered discovery: explicit configuration, packaged runtime, then system loader.
pub fn library_candidates() -> Vec<PathBuf> {
    let mut paths = Vec::new();
    if let Some(path) = std::env::var_os("VELA_MPV_LIBRARY") {
        paths.push(path.into());
    }
    #[cfg(target_os = "macos")]
    let names = &[
        "libmpv.2.dylib",
        "libmpv.dylib",
        "libmpv.framework/libmpv",
        "Mpv.framework/Mpv",
    ];
    #[cfg(target_os = "windows")]
    let names = &["libmpv-2.dll", "mpv-2.dll", "libmpv.dll"];
    #[cfg(not(any(target_os = "macos", target_os = "windows")))]
    let names = &["libmpv.so.2", "libmpv.so"];
    if let Ok(exe) = std::env::current_exe()
        && let Some(dir) = exe.parent()
    {
        for base in [
            dir.to_path_buf(),
            dir.join("resources"),
            dir.join("../Frameworks"),
            dir.join("../Resources"),
        ] {
            for name in names {
                paths.push(base.join(name));
            }
        }
    }
    for name in names {
        paths.push(PathBuf::from(name));
    }
    paths
}

enum Command {
    Open {
        url: String,
        headers: Vec<(String, String)>,
        resume: Option<f64>,
    },
    Set(String, String),
    Seek(f64),
    Stop,
    Shutdown,
}
struct Worker {
    tx: mpsc::Sender<Command>,
    join: Option<JoinHandle<()>>,
}
impl Worker {
    fn stop(&mut self) {
        let _ = self.tx.send(Command::Shutdown);
        if let Some(join) = self.join.take() {
            let _ = join.join();
        }
    }
}

pub struct Player {
    api: Arc<Api>,
    worker: Worker,
    state: Arc<RwLock<PlayerState>>,
    renderer: Option<Arc<Mutex<Renderer>>>,
}
impl Player {
    pub fn new(cc: &eframe::CreationContext<'_>) -> Result<Self> {
        let gl = cc
            .gl
            .clone()
            .context("Vela requires the eframe glow renderer")?;
        if gl.version().is_embedded || gl.version().major < 3 {
            bail!(
                "Embedded playback requires desktop OpenGL 3.0 or newer. Update the graphics driver; ANGLE/OpenGL ES contexts are not used by this native renderer."
            );
        }
        let (mut player, handle) = Self::start(false, Some(cc.egui_ctx.clone()))?;
        match Renderer::new(player.api.clone(), handle, gl, cc.egui_ctx.clone()) {
            Ok(renderer) => player.renderer = Some(Arc::new(Mutex::new(renderer))),
            Err(error) => {
                player.worker.stop();
                return Err(error);
            }
        }
        Ok(player)
    }
    /// A real libmpv core with null audio/video outputs, for deterministic runtime smoke tests.
    pub fn headless() -> Result<Self> {
        Ok(Self::start(true, None)?.0)
    }
    fn start(headless: bool, repaint: Option<egui::Context>) -> Result<(Self, Handle)> {
        let api = Api::load()?;
        let state = Arc::new(RwLock::new(PlayerState::default()));
        let (tx, rx) = mpsc::channel();
        let (ready_tx, ready_rx) = mpsc::sync_channel(1);
        let worker_api = api.clone();
        let worker_state = state.clone();
        let join = thread::Builder::new()
            .name("vela-playback".into())
            .spawn(move || {
                worker_main(worker_api, worker_state, rx, ready_tx, headless, repaint)
            })?;
        let handle = match ready_rx.recv().context("Playback worker failed to start")? {
            Ok(h) => h as Handle,
            Err(error) => {
                let _ = join.join();
                bail!(error);
            }
        };
        Ok((
            Self {
                api,
                worker: Worker {
                    tx,
                    join: Some(join),
                },
                state,
                renderer: None,
            },
            handle,
        ))
    }
    pub fn library_path(&self) -> &Path {
        &self.api.path
    }
    pub fn snapshot(&self) -> PlayerState {
        self.state.read().unwrap_or_else(|e| e.into_inner()).clone()
    }
    fn send(&self, command: Command) -> Result<()> {
        self.worker
            .tx
            .send(command)
            .map_err(|_| anyhow!("Playback worker is closed"))
    }
    pub fn open(&self, url: &str, headers: &[(String, String)], resume: Option<f64>) -> Result<()> {
        if url.is_empty() || url.as_bytes().contains(&0) {
            bail!("Stream URL is empty or contains a null byte");
        }
        if headers.iter().any(|(k, v)| {
            k.is_empty() || k.contains(['\r', '\n', ':', '\0']) || v.contains(['\r', '\n', '\0'])
        }) {
            bail!("Invalid HTTP header");
        }
        if resume.is_some_and(|v| !v.is_finite() || v < 0.) {
            bail!("Invalid resume position");
        }
        self.send(Command::Open {
            url: url.into(),
            headers: headers.to_vec(),
            resume,
        })
    }
    fn set(&self, key: &str, value: impl ToString) -> Result<()> {
        self.send(Command::Set(key.into(), value.to_string()))
    }
    pub fn set_paused(&self, value: bool) -> Result<()> {
        self.set("pause", if value { "yes" } else { "no" })
    }
    pub fn set_volume(&self, value: f64) -> Result<()> {
        if !value.is_finite() {
            bail!("Volume must be finite");
        }
        self.set("volume", value.clamp(0., 100.))
    }
    pub fn set_muted(&self, value: bool) -> Result<()> {
        self.set("mute", if value { "yes" } else { "no" })
    }
    pub fn set_speed(&self, value: f64) -> Result<()> {
        if !value.is_finite() || !(0.25..=4.).contains(&value) {
            bail!("Playback speed must be between 0.25 and 4");
        }
        self.set("speed", value)
    }
    pub fn seek(&self, seconds: f64) -> Result<()> {
        if !seconds.is_finite() || seconds < 0. {
            bail!("Seek position must be finite and nonnegative");
        }
        self.send(Command::Seek(seconds))
    }
    pub fn select_track(&self, kind: &str, id: Option<i64>) -> Result<()> {
        let property = match kind {
            "audio" => "aid",
            "sub" | "subtitle" => "sid",
            "video" => "vid",
            _ => bail!("Unknown track kind"),
        };
        self.set(property, id.map_or_else(|| "no".into(), |v| v.to_string()))
    }
    pub fn select_track_auto(&self, kind: &str) -> Result<()> {
        let property = match kind {
            "audio" => "aid",
            "sub" | "subtitle" => "sid",
            "video" => "vid",
            _ => bail!("Unknown track kind"),
        };
        self.set(property, "auto")
    }
    pub fn stop(&self) -> Result<()> {
        self.send(Command::Stop)
    }
    pub fn show(&self, ui: &mut egui::Ui) -> egui::Response {
        let (rect, response) = ui.allocate_exact_size(
            ui.available_size().max(egui::vec2(1., 1.)),
            egui::Sense::click(),
        );
        ui.painter().rect_filled(rect, 0., egui::Color32::BLACK);
        if let Some(renderer) = &self.renderer {
            let renderer = renderer.clone();
            let state = self.state.clone();
            ui.painter().add(egui::PaintCallback {
                rect,
                callback: Arc::new(egui_glow::CallbackFn::new(move |info, painter| {
                    let mut renderer = renderer.lock().unwrap_or_else(|e| e.into_inner());
                    if let Err(error) = renderer.paint(info, painter) {
                        state.write().unwrap_or_else(|e| e.into_inner()).error =
                            Some(format!("Video rendering: {error}"));
                    }
                })),
            });
        }
        response
    }
    /// Must run from eframe's on_exit hook before its GL context is destroyed.
    pub fn shutdown_gl(&mut self) {
        if let Some(renderer) = self.renderer.take()
            && !renderer.lock().unwrap_or_else(|e| e.into_inner()).destroy()
        {
            self.renderer = Some(renderer);
            return;
        }
        self.worker.stop();
    }
}
impl Drop for Player {
    fn drop(&mut self) {
        if self.renderer.is_some() {
            // No GL calls are legal here: Drop may run after the native context died.
            // Keep the core/library/resources alive rather than invoke undefined behavior.
            // The application normally calls shutdown_gl in its on_exit hook.
            eprintln!(
                "Vela: player dropped without shutdown_gl; preserving GL resources until process exit"
            );
            if let Some(renderer) = self.renderer.take() {
                std::mem::forget(renderer);
            }
            if let Some(join) = self.worker.join.take() {
                std::mem::forget(join);
            }
        } else {
            self.worker.stop();
        }
    }
}

fn worker_main(
    api: Arc<Api>,
    state: Arc<RwLock<PlayerState>>,
    rx: mpsc::Receiver<Command>,
    ready: mpsc::SyncSender<std::result::Result<usize, String>>,
    headless: bool,
    repaint: Option<egui::Context>,
) {
    let h = unsafe { (api.create)() };
    if h.is_null() {
        let _ = ready.send(Err("mpv_create failed".into()));
        return;
    }
    let initialized = (|| -> Result<()> {
        for (key, value) in [
            ("config", "no"),
            ("terminal", "no"),
            ("idle", "yes"),
            ("keep-open", "yes"),
            ("input-default-bindings", "no"),
            ("input-vo-keyboard", "no"),
            ("osd-level", "0"),
            ("vo", if headless { "null" } else { "libmpv" }),
        ] {
            api.option(h, key, value)?;
        }
        if headless {
            api.option(h, "ao", "null")?;
        }
        // WGL native OpenGL cannot promise D3D11/ANGLE zero-copy interop. Copy-back
        // safely uses hardware decode when supported and otherwise software decode.
        api.option(
            h,
            "hwdec",
            if cfg!(target_os = "windows") {
                "auto-copy"
            } else {
                "auto-safe"
            },
        )?;
        api.check(unsafe { (api.initialize)(h) })?;
        for (id, key) in [
            "time-pos",
            "duration",
            "pause",
            "volume",
            "mute",
            "speed",
            "paused-for-cache",
            "eof-reached",
            "track-list",
        ]
        .iter()
        .enumerate()
        {
            let key = CString::new(*key)?;
            api.check(unsafe { (api.observe)(h, id as u64, key.as_ptr(), 0) })?;
        }
        Ok(())
    })();
    if let Err(error) = initialized {
        let _ = ready.send(Err(format!("{error:#}")));
        unsafe { (api.destroy)(h) };
        return;
    }
    if ready.send(Ok(h as usize)).is_err() {
        unsafe { (api.destroy)(h) };
        return;
    }
    let mut running = true;
    while running {
        for command in rx.try_iter() {
            let result = match command {
                Command::Shutdown => {
                    running = false;
                    break;
                }
                Command::Open {
                    url,
                    headers,
                    resume,
                } => {
                    {
                        let mut s = state.write().unwrap_or_else(|e| e.into_inner());
                        s.position = 0.;
                        s.duration = 0.;
                        s.loading = true;
                        s.ended = false;
                        s.error = None;
                        s.tracks.clear();
                    }
                    (|| -> Result<()> {
                        api.headers(h, &headers)?;
                        // Manual/off selections are scoped to the previous item.
                        // The application reapplies saved per-item choices after load.
                        for property in ["aid", "sid", "vid"] {
                            api.set_string(h, property, "auto")?;
                        }
                        let start = resume.unwrap_or(0.);
                        api.set_string(h, "start", &start.to_string())?;
                        api.command(h, &["loadfile".into(), url, "replace".into()])?;
                        api.set_string(h, "pause", "no")
                    })()
                }
                Command::Set(key, value) => api.set_string(h, &key, &value),
                Command::Seek(seconds) => api.command(
                    h,
                    &["seek".into(), seconds.to_string(), "absolute+exact".into()],
                ),
                Command::Stop => api.command(h, &["stop".into()]),
            };
            if let Err(error) = result {
                let mut s = state.write().unwrap_or_else(|e| e.into_inner());
                s.error = Some(format!("{error:#}"));
                s.loading = false;
            }
            if let Some(ctx) = &repaint {
                ctx.request_repaint();
            }
        }
        if !running {
            break;
        }
        let mut changed = HashSet::new();
        for index in 0..128 {
            let e = unsafe { (api.wait)(h, if index == 0 { 0.02 } else { 0. }) };
            if e.is_null() {
                break;
            }
            let event = unsafe { &*e };
            if event.id == 0 {
                break;
            }
            if let Some(ctx) = &repaint {
                ctx.request_repaint();
            }
            match event.id {
                1 => {
                    running = false;
                    break;
                }
                6 => {
                    let mut s = state.write().unwrap_or_else(|e| e.into_inner());
                    s.loading = true;
                    s.ended = false;
                }
                7 => {
                    if !event.data.is_null() {
                        let end = unsafe { &*event.data.cast::<EndFile>() };
                        let mut s = state.write().unwrap_or_else(|e| e.into_inner());
                        s.loading = false;
                        s.ended = end.reason == 0;
                        if end.reason == 4 {
                            s.error = Some(api.check(end.error).err().map_or_else(
                                || "Playback ended with an unknown error".into(),
                                |e| e.to_string(),
                            ));
                        }
                    }
                }
                8 | 21 => {
                    state.write().unwrap_or_else(|e| e.into_inner()).loading = false;
                    changed.insert("track-list".to_owned());
                }
                22 if !event.data.is_null() => {
                    let p = unsafe { &*event.data.cast::<Property>() };
                    if !p.name.is_null() {
                        changed.insert(
                            unsafe { CStr::from_ptr(p.name) }
                                .to_string_lossy()
                                .into_owned(),
                        );
                    }
                }
                _ => {}
            }
        }
        if !changed.is_empty() {
            // Never hold a UI-visible lock across a libmpv API call. The render
            // thread must have no wait dependency on the command thread.
            let tracks = changed.contains("track-list").then(|| read_tracks(&api, h));
            let values: Vec<_> = changed
                .into_iter()
                .filter(|n| n != "track-list")
                .filter_map(|name| api.get(h, &name).map(|value| (name, value)))
                .collect();
            {
                let mut s = state.write().unwrap_or_else(|e| e.into_inner());
                if let Some(tracks) = tracks {
                    s.tracks = tracks;
                }
                for (name, value) in values {
                    match name.as_str() {
                        "time-pos" => s.position = value.parse().unwrap_or(0.),
                        "duration" => s.duration = value.parse().unwrap_or(0.),
                        "pause" => s.paused = value == "yes",
                        "volume" => s.volume = value.parse().unwrap_or(100.),
                        "mute" => s.muted = value == "yes",
                        "speed" => s.speed = value.parse().unwrap_or(1.),
                        "paused-for-cache" => s.loading = value == "yes",
                        "eof-reached" => s.ended = value == "yes",
                        _ => {}
                    }
                }
            }
            if let Some(ctx) = &repaint {
                ctx.request_repaint();
            }
        }
    }
    unsafe { (api.destroy)(h) };
}
fn read_tracks(api: &Api, h: Handle) -> Vec<Track> {
    let count = api
        .get(h, "track-list/count")
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(0)
        .min(1000);
    (0..count)
        .map(|index| {
            let prefix = format!("track-list/{index}/");
            Track {
                id: api
                    .get(h, &format!("{prefix}id"))
                    .and_then(|v| v.parse().ok())
                    .unwrap_or(0),
                kind: api.get(h, &format!("{prefix}type")).unwrap_or_default(),
                title: api
                    .get(h, &format!("{prefix}title"))
                    .unwrap_or_else(|| format!("Track {}", index + 1)),
                language: api.get(h, &format!("{prefix}lang")),
                selected: api
                    .get(h, &format!("{prefix}selected"))
                    .is_some_and(|v| v == "yes"),
            }
        })
        .collect()
}

#[cfg(target_os = "windows")]
type GlExtension = unsafe extern "system" fn(*const u8) -> *const c_void;
#[cfg(not(target_os = "windows"))]
type GlExtension = unsafe extern "C" fn(*const u8) -> *const c_void;
struct GlResolver {
    library: Library,
    extension: Option<GlExtension>,
}
impl GlResolver {
    fn new() -> Result<Self> {
        #[cfg(target_os = "macos")]
        let path = "/System/Library/Frameworks/OpenGL.framework/OpenGL";
        #[cfg(target_os = "windows")]
        let path = "opengl32.dll";
        #[cfg(not(any(target_os = "macos", target_os = "windows")))]
        let path = "libGL.so.1";
        let library = unsafe { Library::new(path) }?;
        #[cfg(target_os = "windows")]
        let extension = unsafe {
            library
                .get::<unsafe extern "system" fn(*const u8) -> *const c_void>(
                    b"wglGetProcAddress\0",
                )
                .ok()
                .map(|p| *p)
        };
        #[cfg(not(target_os = "windows"))]
        let extension = unsafe {
            library
                .get::<unsafe extern "C" fn(*const u8) -> *const c_void>(b"glXGetProcAddressARB\0")
                .ok()
                .map(|p| *p)
        };
        Ok(Self { library, extension })
    }
}
unsafe extern "C" fn resolve_gl(ctx: *mut c_void, name: *const c_char) -> *mut c_void {
    let resolver = unsafe { &*ctx.cast::<GlResolver>() };
    let name = unsafe { CStr::from_ptr(name) };
    if let Ok(symbol) = unsafe {
        resolver
            .library
            .get::<*mut c_void>(name.to_bytes_with_nul())
    } {
        return *symbol;
    }
    if let Some(load) = resolver.extension {
        let p = unsafe { load(name.as_ptr().cast()) };
        if p as usize > 3 && p as usize != usize::MAX {
            return p.cast_mut();
        }
    }
    ptr::null_mut()
}
unsafe extern "C" fn render_wakeup(ctx: *mut c_void) {
    unsafe { &*ctx.cast::<egui::Context>() }.request_repaint();
}
struct Renderer {
    api: Arc<Api>,
    context: Handle,
    gl: Arc<glow::Context>,
    _resolver: Box<GlResolver>,
    repaint: Option<Box<egui::Context>>,
    thread: thread::ThreadId,
    fbo: Option<glow::Framebuffer>,
    color: Option<glow::Renderbuffer>,
    size: [i32; 2],
}
// egui paint callbacks require Send + Sync, but actual GL operations are restricted
// to the creating thread and serialized by the outer Mutex. No pointer escapes.
unsafe impl Send for Renderer {}
impl Renderer {
    fn new(api: Arc<Api>, h: Handle, gl: Arc<glow::Context>, ctx: egui::Context) -> Result<Self> {
        let mut resolver = Box::new(GlResolver::new()?);
        let mut init = GlInit {
            get_proc: resolve_gl,
            ctx: (&mut *resolver as *mut GlResolver).cast(),
        };
        let mut params = [
            Param {
                kind: 1,
                data: c"opengl".as_ptr().cast_mut().cast(),
            },
            Param {
                kind: 2,
                data: (&mut init as *mut GlInit).cast(),
            },
            Param::end(),
        ];
        let mut context = ptr::null_mut();
        api.check(unsafe { (api.render_create)(&mut context, h, params.as_mut_ptr()) })
            .context("Create embedded OpenGL video renderer")?;
        let mut repaint = Box::new(ctx);
        unsafe {
            (api.render_callback)(
                context,
                Some(render_wakeup),
                (&mut *repaint as *mut egui::Context).cast(),
            )
        };
        Ok(Self {
            api,
            context,
            gl,
            _resolver: resolver,
            repaint: Some(repaint),
            thread: thread::current().id(),
            fbo: None,
            color: None,
            size: [0, 0],
        })
    }
    fn paint(&mut self, info: egui::PaintCallbackInfo, painter: &egui_glow::Painter) -> Result<()> {
        if self.context.is_null() {
            return Ok(());
        }
        if thread::current().id() != self.thread {
            bail!("GL render called from a different thread");
        }
        let view = info.viewport_in_pixels();
        let width = view.width_px.max(1);
        let height = view.height_px.max(1);
        unsafe {
            if self.fbo.is_none() {
                self.fbo = Some(self.gl.create_framebuffer().map_err(|e| anyhow!(e))?);
                self.color = Some(self.gl.create_renderbuffer().map_err(|e| anyhow!(e))?);
            }
            self.gl.bind_framebuffer(glow::FRAMEBUFFER, self.fbo);
            if self.size != [width, height] {
                self.gl.bind_renderbuffer(glow::RENDERBUFFER, self.color);
                self.gl
                    .renderbuffer_storage(glow::RENDERBUFFER, glow::RGBA8, width, height);
                self.gl.framebuffer_renderbuffer(
                    glow::FRAMEBUFFER,
                    glow::COLOR_ATTACHMENT0,
                    glow::RENDERBUFFER,
                    self.color,
                );
                self.size = [width, height];
            }
            if self.gl.check_framebuffer_status(glow::FRAMEBUFFER) != glow::FRAMEBUFFER_COMPLETE {
                self.gl
                    .bind_framebuffer(glow::FRAMEBUFFER, painter.intermediate_fbo());
                bail!("Incomplete video framebuffer");
            }
            self.gl.disable(glow::SCISSOR_TEST);
            let mut fbo = Fbo {
                fbo: self.fbo.unwrap().0.get() as c_int,
                width,
                height,
                internal_format: glow::RGBA8 as c_int,
            };
            let mut flip = 1;
            let mut block = 0;
            let mut params = [
                Param {
                    kind: 3,
                    data: (&mut fbo as *mut Fbo).cast(),
                },
                Param {
                    kind: 4,
                    data: (&mut flip as *mut i32).cast(),
                },
                Param {
                    kind: 12,
                    data: (&mut block as *mut i32).cast(),
                },
                Param::end(),
            ];
            let result = self
                .api
                .check((self.api.render)(self.context, params.as_mut_ptr()));
            self.gl.bind_framebuffer(glow::READ_FRAMEBUFFER, self.fbo);
            self.gl
                .bind_framebuffer(glow::DRAW_FRAMEBUFFER, painter.intermediate_fbo());
            let clip = info.clip_rect_in_pixels();
            self.gl.enable(glow::SCISSOR_TEST);
            self.gl.scissor(
                clip.left_px,
                clip.from_bottom_px,
                clip.width_px,
                clip.height_px,
            );
            self.gl.blit_framebuffer(
                0,
                0,
                width,
                height,
                view.left_px,
                view.from_bottom_px,
                view.left_px + width,
                view.from_bottom_px + height,
                glow::COLOR_BUFFER_BIT,
                glow::LINEAR,
            );
            self.gl
                .bind_framebuffer(glow::FRAMEBUFFER, painter.intermediate_fbo());
            result
        }
    }
    fn destroy(&mut self) -> bool {
        if self.context.is_null() {
            return true;
        }
        if thread::current().id() != self.thread {
            eprintln!("Vela: shutdown_gl must run on the GL thread");
            return false;
        }
        unsafe {
            (self.api.render_callback)(self.context, None, ptr::null_mut());
            (self.api.render_free)(self.context);
            self.context = ptr::null_mut();
            if let Some(fbo) = self.fbo.take() {
                self.gl.delete_framebuffer(fbo);
            }
            if let Some(color) = self.color.take() {
                self.gl.delete_renderbuffer(color);
            }
        }
        // Break the egui Context -> retained paint callback -> Renderer cycle.
        self.repaint.take();
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn candidate_paths_are_packaging_relative_or_system_names() {
        let paths = library_candidates();
        assert!(!paths.is_empty());
        assert!(paths.iter().any(|v| v.components().count() == 1));
        assert!(
            paths
                .iter()
                .all(|v| !v.to_string_lossy().contains(".pub-cache"))
        );
    }
    #[test]
    fn initial_state_is_idle() {
        let s = PlayerState::default();
        assert!(s.paused);
        assert!(!s.loading);
        assert!(!s.ended);
        assert_eq!(s.volume, 100.);
    }
}
