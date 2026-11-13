//! Real embedded GL playback smoke. Pass a video with a red upper half and blue lower half.
//! Reads back video colors, vertical orientation, and untouched toolbar pixels.
use eframe::{egui, glow};
use std::{
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};
use vela_player::Player;
struct Smoke {
    player: Player,
    start: Instant,
    requested: bool,
    result: Arc<Mutex<Option<Result<(), String>>>>,
}
impl eframe::App for Smoke {
    fn update(&mut self, ctx: &egui::Context, _: &mut eframe::Frame) {
        egui::TopBottomPanel::top("smoke-toolbar")
            .exact_height(32.)
            .frame(egui::Frame::new().fill(egui::Color32::BLUE))
            .show(ctx, |ui| {
                ui.label("Embedded video bounds check");
            });
        egui::CentralPanel::default().show(ctx, |ui| {
            self.player.show(ui);
        });
        let state = self.player.snapshot();
        if let Some(error) = state.error {
            *self.result.lock().unwrap() = Some(Err(error));
            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
            return;
        }
        for event in ctx.input(|i| i.events.clone()) {
            if let egui::Event::Screenshot { image, .. } = event {
                let pixel = image.pixels[(image.size[1] / 4) * image.size[0] + image.size[0] / 2];
                let lower =
                    image.pixels[(image.size[1] * 3 / 4) * image.size[0] + image.size[0] / 2];
                let toolbar = image.pixels[10 * image.size[0] + image.size[0] - 10];
                let passed = pixel.r() > 100
                    && pixel.g() < 80
                    && pixel.b() < 80
                    && lower.b() > 100
                    && lower.r() < 80
                    && lower.g() < 80
                    && toolbar.b() > 200
                    && toolbar.r() < 50;
                *self.result.lock().unwrap() = Some(if passed {
                    Ok(())
                } else {
                    Err(format!(
                        "Embedded framebuffer color/bounds mismatch: upper={pixel:?}, lower={lower:?}, toolbar={toolbar:?}"
                    ))
                });
                ctx.send_viewport_cmd(egui::ViewportCommand::Close);
            }
        }
        if !self.requested
            && self.start.elapsed() > Duration::from_secs(2)
            && !state.loading
            && state.duration > 0.
        {
            self.requested = true;
            ctx.send_viewport_cmd(egui::ViewportCommand::Screenshot(egui::UserData::default()));
        }
        if self.start.elapsed() > Duration::from_secs(12) {
            *self.result.lock().unwrap() = Some(Err("Embedded video smoke timed out".into()));
            ctx.send_viewport_cmd(egui::ViewportCommand::Close);
        }
        ctx.request_repaint_after(Duration::from_millis(20));
    }
    fn on_exit(&mut self, _: Option<&glow::Context>) {
        self.player.shutdown_gl();
    }
}
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let media = std::env::args()
        .nth(1)
        .ok_or("Pass the red-upper/blue-lower video fixture path")?;
    let result = Arc::new(Mutex::new(None));
    let shared = result.clone();
    eframe::run_native(
        "Vela embedded video smoke",
        eframe::NativeOptions {
            renderer: eframe::Renderer::Glow,
            viewport: egui::ViewportBuilder::default().with_inner_size([640., 360.]),
            ..Default::default()
        },
        Box::new(move |cc| {
            let player = Player::new(cc)?;
            player.open(&media, &[], None)?;
            player.set_muted(true)?;
            Ok(Box::new(Smoke {
                player,
                start: Instant::now(),
                requested: false,
                result: shared,
            }))
        }),
    )?;
    let result = result
        .lock()
        .unwrap()
        .take()
        .ok_or("Smoke window closed without a result")?;
    result.map_err(|e| -> Box<dyn std::error::Error> { e.into() })?;
    println!("embedded-video-ok: libmpv embedded video orientation and toolbar bounds verified");
    Ok(())
}
