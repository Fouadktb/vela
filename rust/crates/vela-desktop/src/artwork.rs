//! Bounded artwork loading: network and decoding stay off the UI thread.
use eframe::egui;
use std::{
    collections::{HashMap, HashSet, VecDeque},
    io::{Cursor, Read},
    sync::{Arc, Mutex, mpsc},
    thread,
    time::Duration,
};

pub struct Artwork {
    requests: mpsc::SyncSender<String>,
    results: mpsc::Receiver<(String, Option<egui::ColorImage>)>,
    pending: HashSet<String>,
    failed: HashSet<String>,
    cache: HashMap<String, egui::TextureHandle>,
    order: VecDeque<String>,
}
impl Artwork {
    pub fn new(ctx: egui::Context) -> Self {
        let (requests, rx) = mpsc::sync_channel::<String>(48);
        let (tx, results) = mpsc::sync_channel(8);
        let rx = Arc::new(Mutex::new(rx));
        for _ in 0..2 {
            let rx = rx.clone();
            let tx = tx.clone();
            let ctx = ctx.clone();
            thread::spawn(move || {
                let client = reqwest::blocking::Client::builder()
                    .timeout(Duration::from_secs(12))
                    .connect_timeout(Duration::from_secs(5))
                    .redirect(reqwest::redirect::Policy::limited(3))
                    .build()
                    .ok();
                loop {
                    let request = match rx.lock() {
                        Ok(rx) => rx.recv(),
                        Err(_) => return,
                    };
                    let Ok(url) = request else {
                        return;
                    };
                    let image = (|| -> Option<egui::ColorImage> {
                        let parsed = url::Url::parse(&url).ok()?;
                        if !matches!(parsed.scheme(), "http" | "https") {
                            return None;
                        }
                        let response = client
                            .as_ref()?
                            .get(parsed)
                            .send()
                            .ok()?
                            .error_for_status()
                            .ok()?;
                        if response
                            .content_length()
                            .is_some_and(|size| size > 8 * 1024 * 1024)
                        {
                            return None;
                        }
                        let mut bytes = Vec::new();
                        response
                            .take(8 * 1024 * 1024 + 1)
                            .read_to_end(&mut bytes)
                            .ok()?;
                        if bytes.len() > 8 * 1024 * 1024 {
                            return None;
                        }
                        let mut reader = image::ImageReader::new(Cursor::new(bytes))
                            .with_guessed_format()
                            .ok()?;
                        let mut limits = image::Limits::default();
                        limits.max_image_width = Some(4096);
                        limits.max_image_height = Some(4096);
                        limits.max_alloc = Some(64 * 1024 * 1024);
                        reader.limits(limits);
                        let rgba = reader.decode().ok()?.thumbnail(320, 480).to_rgba8();
                        Some(egui::ColorImage::from_rgba_unmultiplied(
                            [rgba.width() as usize, rgba.height() as usize],
                            rgba.as_raw(),
                        ))
                    })();
                    if tx.send((url, image)).is_err() {
                        return;
                    }
                    ctx.request_repaint();
                }
            });
        }
        Self {
            requests,
            results,
            pending: HashSet::new(),
            failed: HashSet::new(),
            cache: HashMap::new(),
            order: VecDeque::new(),
        }
    }
    pub fn texture(&mut self, ctx: &egui::Context, url: &str) -> Option<egui::TextureHandle> {
        while let Ok((url, image)) = self.results.try_recv() {
            self.pending.remove(&url);
            if let Some(image) = image {
                while self.cache.len() >= 96 {
                    if let Some(old) = self.order.pop_front() {
                        self.cache.remove(&old);
                    } else {
                        break;
                    }
                }
                let texture = ctx.load_texture(
                    format!("poster-{}", self.order.len()),
                    image,
                    egui::TextureOptions::LINEAR,
                );
                self.cache.insert(url.clone(), texture);
                self.order.push_back(url);
            } else {
                if self.failed.len() >= 192 {
                    self.failed.clear();
                }
                self.failed.insert(url);
            }
        }
        if let Some(texture) = self.cache.get(url) {
            self.order.retain(|entry| entry != url);
            self.order.push_back(url.to_owned());
            return Some(texture.clone());
        }
        if !self.pending.contains(url)
            && !self.failed.contains(url)
            && self.requests.try_send(url.to_owned()).is_ok()
        {
            self.pending.insert(url.to_owned());
        }
        None
    }
}
