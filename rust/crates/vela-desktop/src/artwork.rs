//! Bounded artwork loading: network and decoding stay off the UI thread.
use eframe::egui;
use std::{
    collections::{HashMap, HashSet, VecDeque},
    hash::{Hash, Hasher},
    io::{Cursor, Read},
    path::{Path, PathBuf},
    sync::{Arc, Mutex, mpsc},
    thread,
    time::{Duration, Instant, SystemTime},
};

pub struct Artwork {
    requests: mpsc::SyncSender<String>,
    results: mpsc::Receiver<(String, Option<egui::ColorImage>)>,
    pending: HashSet<String>,
    failed: HashMap<String, Instant>,
    cache: HashMap<String, egui::TextureHandle>,
    order: VecDeque<String>,
}
impl Artwork {
    pub fn new(ctx: egui::Context) -> Self {
        let (requests, rx) = mpsc::sync_channel::<String>(8);
        let (tx, results) = mpsc::sync_channel(8);
        let rx = Arc::new(Mutex::new(rx));
        let disk_cache = vela_core::migration::default_database_path()
            .ok()
            .and_then(|path| path.parent().map(|p| p.join("artwork-cache")));
        for _ in 0..4 {
            let disk_cache = disk_cache.clone();
            let rx = rx.clone();
            let tx = tx.clone();
            let ctx = ctx.clone();
            thread::spawn(move || {
                if let Some(path) = &disk_cache {
                    prune_cache(path);
                }
                let client = reqwest::blocking::Client::builder()
                    .timeout(Duration::from_secs(8))
                    .connect_timeout(Duration::from_secs(3))
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
                        let cached = disk_cache.as_ref().map(|dir| cache_path(dir, &url));
                        if let Some(image) = cached.as_deref().and_then(read_cached) {
                            return Some(image);
                        }
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
                        if let Some(path) = cached {
                            write_cached(&path, &rgba);
                        }
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
            failed: HashMap::new(),
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
                self.failed.insert(url, Instant::now());
            }
        }
        if let Some(texture) = self.cache.get(url) {
            self.order.retain(|entry| entry != url);
            self.order.push_back(url.to_owned());
            return Some(texture.clone());
        }
        if !self.pending.contains(url)
            && !self
                .failed
                .get(url)
                .is_some_and(|at| at.elapsed() < Duration::from_secs(30))
            && self.requests.try_send(url.to_owned()).is_ok()
        {
            self.failed.remove(url);
            self.pending.insert(url.to_owned());
        }
        if !self.pending.contains(url) && !self.failed.contains_key(url) {
            ctx.request_repaint_after(Duration::from_millis(100));
        }
        if let Some(at) = self.failed.get(url) {
            ctx.request_repaint_after(
                Duration::from_secs(30)
                    .saturating_sub(at.elapsed())
                    .max(Duration::from_millis(100)),
            );
        }
        None
    }
}

// Cache filenames contain no provider URLs or credentials. Entries expire after a
// week and are capped at 256 thumbnails. All filesystem work stays on workers.
const CACHE_AGE: Duration = Duration::from_secs(7 * 24 * 60 * 60);
fn cache_path(dir: &Path, url: &str) -> PathBuf {
    let mut hash = std::collections::hash_map::DefaultHasher::new();
    url.hash(&mut hash);
    dir.join(format!("{:016x}.png", hash.finish()))
}
fn read_cached(path: &Path) -> Option<egui::ColorImage> {
    let metadata = path.metadata().ok()?;
    if metadata.len() > 1024 * 1024 || metadata.modified().ok()?.elapsed().ok()? > CACHE_AGE {
        return None;
    }
    let bytes = std::fs::read(path).ok()?;
    let mut reader = image::ImageReader::new(Cursor::new(bytes))
        .with_guessed_format()
        .ok()?;
    let mut limits = image::Limits::default();
    limits.max_image_width = Some(320);
    limits.max_image_height = Some(480);
    limits.max_alloc = Some(4 * 1024 * 1024);
    reader.limits(limits);
    let rgba = reader.decode().ok()?.to_rgba8();
    Some(egui::ColorImage::from_rgba_unmultiplied(
        [rgba.width() as usize, rgba.height() as usize],
        rgba.as_raw(),
    ))
}
fn write_cached(path: &Path, rgba: &image::RgbaImage) {
    let Some(dir) = path.parent() else {
        return;
    };
    if std::fs::create_dir_all(dir).is_err() {
        return;
    }
    let temporary = dir.join(format!("{}.tmp", uuid::Uuid::new_v4()));
    if rgba
        .save_with_format(&temporary, image::ImageFormat::Png)
        .is_ok()
    {
        let _ = std::fs::rename(&temporary, path);
    }
    let _ = std::fs::remove_file(temporary);
    prune_cache(dir);
}
fn prune_cache(dir: &Path) {
    let Ok(entries) = std::fs::read_dir(dir) else {
        return;
    };
    let mut entries: Vec<_> = entries
        .flatten()
        .filter_map(|entry| {
            let path = entry.path();
            if path.extension().is_none_or(|extension| extension != "png") {
                return None;
            }
            let metadata = entry.metadata().ok()?;
            let modified = metadata.modified().unwrap_or(SystemTime::UNIX_EPOCH);
            if modified.elapsed().unwrap_or_default() > CACHE_AGE || metadata.len() > 1024 * 1024 {
                let _ = std::fs::remove_file(path);
                None
            } else {
                Some((modified, path))
            }
        })
        .collect();
    entries.sort_by_key(|(modified, _)| *modified);
    let excess = entries.len().saturating_sub(256);
    for (_, path) in entries.into_iter().take(excess) {
        let _ = std::fs::remove_file(path);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn disk_cache_round_trip_and_corrupt_entry() {
        let temp = tempfile::tempdir().unwrap();
        let path = cache_path(temp.path(), "https://example.test/poster?password=private");
        assert!(!path.to_string_lossy().contains("private"));
        let rgba = image::RgbaImage::from_pixel(2, 3, image::Rgba([12, 34, 56, 255]));
        write_cached(&path, &rgba);
        let image = read_cached(&path).unwrap();
        assert_eq!(image.size, [2, 3]);
        assert_eq!(image.pixels[0], egui::Color32::from_rgb(12, 34, 56));
        std::fs::write(&path, b"invalid image").unwrap();
        assert!(read_cached(&path).is_none());
    }
    #[test]
    fn disk_cache_is_bounded() {
        let temp = tempfile::tempdir().unwrap();
        for index in 0..260 {
            std::fs::write(temp.path().join(format!("{index}.png")), b"test").unwrap();
        }
        prune_cache(temp.path());
        assert_eq!(std::fs::read_dir(temp.path()).unwrap().count(), 256);
    }
}
