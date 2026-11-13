#![cfg_attr(target_os = "windows", windows_subsystem = "windows")]
mod app;
mod artwork;
mod preferences;
mod theme;
mod worker;
#[cfg(test)]
mod worker_tests;

fn main() -> eframe::Result {
    let options = eframe::NativeOptions {
        renderer: eframe::Renderer::Glow,
        viewport: eframe::egui::ViewportBuilder::default()
            .with_title("Vela")
            .with_inner_size([1440.0, 900.0])
            .with_min_inner_size([1000.0, 660.0])
            .with_app_id("com.fouadktb.vela"),
        ..Default::default()
    };
    eframe::run_native(
        "Vela",
        options,
        Box::new(|cc| Ok(Box::new(app::VelaApp::new(cc)))),
    )
}
