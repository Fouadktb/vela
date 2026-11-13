use super::*;
use crate::theme;

impl VelaApp {
    fn next_episode(&self) -> Option<Episode> {
        let target = self.playing.as_ref()?;
        let index = self.playback_episodes.iter().position(|episode| {
            episode.id == target.item.id && Some(&episode.season_id) == target.season_id.as_ref()
        })?;
        self.playback_episodes.get(index + 1).cloned()
    }
    fn advance_episode(&mut self) {
        if let Some(next) = self.next_episode() {
            self.worker
                .send(Command::Prepare(PlaybackTarget::episode(&next)));
        }
    }
    fn seek_relative(&mut self, seconds: f64) {
        if let Some(player) = &self.player {
            let state = player.snapshot();
            if state.duration > 0.0 {
                let _ = player.seek((state.position + seconds).clamp(0.0, state.duration));
                self.seek_indicator = Some((
                    format!("{}{:.0}s", if seconds > 0.0 { "+" } else { "" }, seconds),
                    Instant::now(),
                ));
            }
        }
    }
    pub(super) fn shortcuts(&mut self, ctx: &egui::Context) {
        if self.playing.is_none() || ctx.wants_keyboard_input() || egui::Popup::is_any_open(ctx) {
            return;
        }
        if ctx.input(|i| i.key_pressed(egui::Key::Escape)) {
            self.close_player(ctx);
            return;
        }
        if ctx.input(|i| i.key_pressed(egui::Key::F)) {
            self.fullscreen = !self.fullscreen;
            ctx.send_viewport_cmd(egui::ViewportCommand::Fullscreen(self.fullscreen));
        }
        if ctx.input(|i| i.key_pressed(egui::Key::ArrowRight)) {
            self.seek_relative(10.0);
        }
        if ctx.input(|i| i.key_pressed(egui::Key::ArrowLeft)) {
            self.seek_relative(-10.0);
        }
        if ctx.input(|i| i.key_pressed(egui::Key::ArrowUp)) {
            self.set_volume(self.volume.volume + 5.0);
        }
        if ctx.input(|i| i.key_pressed(egui::Key::ArrowDown)) {
            self.set_volume(self.volume.volume - 5.0);
        }
        if ctx.input(|i| i.key_pressed(egui::Key::M)) {
            self.toggle_mute();
        }
        if ctx.input(|i| i.key_pressed(egui::Key::N)) {
            self.advance_episode();
        }
        if ctx.input(|i| i.key_pressed(egui::Key::Space)) && self.space_pressed_at.is_none() {
            self.space_pressed_at = Some(Instant::now());
        }
        if self
            .space_pressed_at
            .is_some_and(|at| at.elapsed() > Duration::from_millis(300))
            && self.speed_before_hold.is_none()
            && let Some(player) = &self.player
            && player.snapshot().duration > 0.0
        {
            self.speed_before_hold = Some(self.speed);
            let _ = player.set_speed(2.0);
        }
        if ctx.input(|i| i.key_released(egui::Key::Space))
            && self.space_pressed_at.take().is_some()
            && let Some(player) = &self.player
        {
            if let Some(speed) = self.speed_before_hold.take() {
                let _ = player.set_speed(speed);
            } else {
                let state = player.snapshot();
                if state.ended {
                    let _ = player.seek(0.0);
                }
                let _ = player.set_paused(if state.ended { false } else { !state.paused });
            }
        }
    }
    pub(super) fn player_ui(&mut self, ctx: &egui::Context) {
        self.shortcuts(ctx);
        let Some(target) = self.playing.clone() else {
            return;
        };
        let Some(player) = &self.player else {
            return;
        };
        let state = player.snapshot();
        self.restore_tracks(&state.tracks);
        if ctx.input(|input| {
            input.pointer.delta() != Vec2::ZERO
                || input.pointer.any_pressed()
                || input
                    .events
                    .iter()
                    .any(|event| matches!(event, egui::Event::Key { .. }))
        }) {
            self.controls_last_activity = Instant::now();
        }
        let visible = state.ended
            || egui::Popup::is_any_open(ctx)
            || state.paused
            || state.loading
            || state.error.is_some()
            || self.controls_last_activity.elapsed() < Duration::from_secs(3)
            || ctx.wants_keyboard_input();
        let screen = ctx.content_rect();
        let mut video_response = None;
        egui::CentralPanel::default()
            .frame(egui::Frame::new().fill(Color32::BLACK))
            .show(ctx, |ui| {
                if let Some(player) = &self.player {
                    video_response = Some(player.show(ui));
                }
                if visible {
                    paint_player_gradients(ui, screen);
                }
            });
        if let Some(response) = video_response
            && response.double_clicked()
        {
            let fraction = response
                .interact_pointer_pos()
                .map(|p| (p.x - response.rect.left()) / response.rect.width())
                .unwrap_or(0.5);
            if fraction < 0.33 {
                self.seek_relative(-10.0);
            } else if fraction > 0.67 {
                self.seek_relative(10.0);
            } else {
                self.fullscreen = !self.fullscreen;
                ctx.send_viewport_cmd(egui::ViewportCommand::Fullscreen(self.fullscreen));
            }
        }
        if visible {
            egui::Area::new(egui::Id::new("player-top-controls"))
                .order(egui::Order::Foreground)
                .fixed_pos(screen.min + egui::vec2(24.0, 18.0))
                .show(ctx, |ui| {
                    ui.set_width(screen.width() - 48.0);
                    ui.horizontal(|ui| {
                        if icon_button(ui, "arrowLeft", "Back", false).clicked() {
                            self.close_player(ctx);
                        }
                        if target.item.content_type == "live" {
                            ui.menu_button(theme::icon("history"), |ui| {
                                for history in self
                                    .history
                                    .clone()
                                    .into_iter()
                                    .filter(|h| h.item_type == "live")
                                    .take(10)
                                {
                                    if ui.button(&history.title).clicked() {
                                        self.resume_history(&history);
                                        ui.close();
                                    }
                                }
                            });
                        }
                        ui.add_space(4.0);
                        ui.vertical(|ui| {
                            ui.label(
                                RichText::new(&target.item.title)
                                    .font(theme::bold(22.0))
                                    .color(Color32::WHITE),
                            );
                            if let Some(subtitle) = &target.item.subtitle {
                                ui.label(RichText::new(subtitle).small().color(theme::MUTED));
                            }
                        });
                        ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                            if icon_button(ui, "refreshCw", "Retry", false).clicked() {
                                self.worker.send(Command::Prepare(target.clone()));
                            }
                        });
                    });
                });
            egui::Area::new(egui::Id::new("player-bottom-controls"))
                .order(egui::Order::Foreground)
                .fixed_pos(egui::pos2(screen.left() + 48.0, screen.bottom() - 104.0))
                .show(ctx, |ui| {
                    ui.set_width((screen.width() - 96.0).max(200.0));
                    ui.spacing_mut().item_spacing = egui::vec2(10.0, 0.0);
                    ui.horizontal(|ui| {
                        ui.allocate_ui_with_layout(
                            egui::vec2(48.0, 24.0),
                            egui::Layout::left_to_right(egui::Align::Center),
                            |ui| {
                                ui.label(
                                    RichText::new(time_label(
                                        self.seek_position.unwrap_or(state.position),
                                    ))
                                    .size(12.0)
                                    .color(Color32::from_rgb(216, 210, 200)),
                                );
                            },
                        );
                        let mut position = self.seek_position.unwrap_or(state.position);
                        let width = (ui.available_width() - 58.0).max(20.0);
                        let response = white_slider(
                            ui,
                            &mut position,
                            state.duration,
                            egui::vec2(width, 24.0),
                            6.0,
                            "Playback position",
                            state.duration > 0.0,
                        );
                        if response.changed() {
                            self.seek_position = Some(position);
                        }
                        if response.drag_stopped()
                            || response.clicked()
                            || (response.changed() && !response.dragged())
                        {
                            if state.duration > 0.0
                                && let Some(player) = &self.player
                            {
                                let _ = player.seek(position);
                            }
                            self.seek_position = None;
                        }
                        ui.allocate_ui_with_layout(
                            egui::vec2(48.0, 24.0),
                            egui::Layout::right_to_left(egui::Align::Center),
                            |ui| {
                                ui.label(
                                    RichText::new(if state.duration > 0.0 {
                                        time_label(state.duration)
                                    } else {
                                        "LIVE".into()
                                    })
                                    .size(12.0)
                                    .color(Color32::from_rgb(216, 210, 200)),
                                );
                            },
                        );
                    });
                    ui.add_space(12.0);
                    let track_labels: Vec<_> = [
                        ("audio", "audioLines", "Auto"),
                        ("sub", "subtitles", "Off"),
                        ("video", "monitorPlay", "Auto"),
                    ]
                    .into_iter()
                    .map(|(kind, icon, default)| {
                        let chosen = state
                            .tracks
                            .iter()
                            .find(|t| t.kind == kind && t.selected)
                            .and_then(|t| t.language.as_deref())
                            .unwrap_or(default);
                        (kind, icon, chosen.to_owned())
                    })
                    .collect();
                    let speed_label = format!("{}x", self.speed);
                    let next = self.next_episode().is_some();
                    let controls_width = 44.0 * 4.0
                        + 172.0
                        + track_labels
                            .iter()
                            .map(|(_, _, label)| pill_width(ui, label))
                            .sum::<f32>()
                        + pill_width(ui, &speed_label)
                        + 80.0
                        + if next {
                            pill_width(ui, "Next Episode") + 10.0
                        } else {
                            0.0
                        };
                    ui.horizontal(|ui| {
                        ui.add_space(((ui.available_width() - controls_width) / 2.0).max(0.0));
                        if icon_button(
                            ui,
                            if state.paused || state.ended {
                                "play"
                            } else {
                                "pause"
                            },
                            if state.paused || state.ended {
                                "Play"
                            } else {
                                "Pause"
                            },
                            true,
                        )
                        .clicked()
                            && let Some(player) = &self.player
                        {
                            if state.ended {
                                let _ = player.seek(0.0);
                                self.ended_handled = false;
                            }
                            let _ =
                                player.set_paused(if state.ended { false } else { !state.paused });
                        }
                        if icon_button(ui, "rotateCcw", "Rewind 10 seconds", false).clicked() {
                            self.seek_relative(-10.0);
                        }
                        if icon_button(ui, "rotateCw", "Forward 10 seconds", false).clicked() {
                            self.seek_relative(10.0);
                        }
                        let (volume_rect, volume_response) =
                            ui.allocate_exact_size(egui::vec2(172.0, 44.0), egui::Sense::hover());
                        let (volume_fill, volume_stroke) = control_appearance(
                            ui,
                            &volume_response,
                            Color32::from_black_alpha(102),
                        );
                        ui.painter().rect_filled(volume_rect, 22.0, volume_fill);
                        ui.painter().rect_stroke(
                            volume_rect,
                            22.0,
                            volume_stroke,
                            egui::StrokeKind::Inside,
                        );
                        let mute_rect = egui::Rect::from_min_size(
                            volume_rect.min + egui::vec2(4.0, 0.0),
                            egui::vec2(44.0, 44.0),
                        );
                        let mute = ui.interact(
                            mute_rect,
                            ui.id().with("player-volume-mute"),
                            egui::Sense::click(),
                        );
                        paint_icon_feedback(ui, &mute, mute_rect);
                        let mute_focused = mute.has_focus();
                        paint_icon(
                            ui,
                            mute_rect.center(),
                            if self.volume.volume == 0.0 || state.muted {
                                "volumeX"
                            } else {
                                "volume2"
                            },
                            Color32::WHITE,
                        );
                        mute.widget_info(|| {
                            egui::WidgetInfo::labeled(
                                egui::WidgetType::Button,
                                true,
                                "Mute / unmute",
                            )
                        });
                        if mute
                            .on_hover_cursor(egui::CursorIcon::PointingHand)
                            .on_hover_text("Mute / unmute")
                            .clicked()
                        {
                            self.toggle_mute();
                        }
                        let mut volume_ui =
                            ui.new_child(egui::UiBuilder::new().id_salt("volume-slider").max_rect(
                                egui::Rect::from_min_size(
                                    volume_rect.min + egui::vec2(52.0, 0.0),
                                    egui::vec2(112.0, 44.0),
                                ),
                            ));
                        let mut volume = self.volume.volume;
                        let volume_slider = white_slider(
                            &mut volume_ui,
                            &mut volume,
                            100.0,
                            egui::vec2(112.0, 44.0),
                            5.0,
                            "Volume",
                            true,
                        );
                        if volume_slider.changed() {
                            self.set_volume(volume);
                        }
                        if mute_focused || volume_slider.has_focus() {
                            ui.painter().rect_stroke(
                                volume_rect,
                                22.0,
                                egui::Stroke::new(2.0_f32, theme::ACCENT),
                                egui::StrokeKind::Inside,
                            );
                        }
                        for (kind, icon, label) in &track_labels {
                            let tracks: Vec<_> =
                                state.tracks.iter().filter(|t| t.kind == *kind).collect();
                            let response =
                                pill_button(ui, icon, label, false).on_hover_text(match *kind {
                                    "audio" => "Audio tracks",
                                    "sub" => "Subtitle tracks",
                                    _ => "Video tracks",
                                });
                            egui::Popup::menu(&response)
                                .frame(
                                    egui::Frame::popup(ui.style())
                                        .fill(Color32::from_rgb(23, 25, 28)),
                                )
                                .align(egui::RectAlign::TOP_START)
                                .show(|ui| {
                                    ui.set_min_width(260.0);
                                    ui.set_max_width(360.0);
                                    if *kind == "sub"
                                        && ui
                                            .selectable_label(
                                                !tracks.iter().any(|t| t.selected),
                                                "Off",
                                            )
                                            .clicked()
                                    {
                                        self.select_track(kind, None);
                                        ui.close();
                                    }
                                    if tracks.is_empty() {
                                        ui.label("No tracks available");
                                    }
                                    for track in &tracks {
                                        let label = format!(
                                            "{}{}",
                                            track.title,
                                            track
                                                .language
                                                .as_ref()
                                                .map(|l| format!(" ({l})"))
                                                .unwrap_or_default()
                                        );
                                        if ui.selectable_label(track.selected, label).clicked() {
                                            self.select_track(kind, Some(track));
                                            ui.close();
                                        }
                                    }
                                });
                        }
                        let response = pill_button(ui, "gauge", &speed_label, false)
                            .on_hover_text("Playback speed");
                        egui::Popup::menu(&response)
                            .frame(
                                egui::Frame::popup(ui.style()).fill(Color32::from_rgb(23, 25, 28)),
                            )
                            .align(egui::RectAlign::TOP_START)
                            .show(|ui| {
                                for speed in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0] {
                                    if ui
                                        .selectable_label(
                                            self.speed == speed,
                                            if speed == 1.0 {
                                                "Normal".into()
                                            } else {
                                                format!("{speed}x")
                                            },
                                        )
                                        .clicked()
                                    {
                                        self.speed = speed;
                                        if let Some(player) = &self.player {
                                            let _ = player.set_speed(speed);
                                        }
                                        ui.close();
                                    }
                                }
                            });
                        if next && pill_button(ui, "chevronsRight", "Next Episode", true).clicked()
                        {
                            self.advance_episode();
                        }
                        if icon_button(
                            ui,
                            if self.fullscreen {
                                "minimize"
                            } else {
                                "maximize"
                            },
                            "Fullscreen",
                            false,
                        )
                        .clicked()
                        {
                            self.fullscreen = !self.fullscreen;
                            ctx.send_viewport_cmd(egui::ViewportCommand::Fullscreen(
                                self.fullscreen,
                            ));
                        }
                    });
                });
        } else {
            ctx.set_cursor_icon(egui::CursorIcon::None);
        }
        if let Some(error) = &state.error {
            egui::Area::new(egui::Id::new("playback-error"))
                .order(egui::Order::Foreground)
                .anchor(egui::Align2::CENTER_CENTER, Vec2::ZERO)
                .show(ctx, |ui| {
                    egui::Frame::new()
                        .fill(theme::PANEL)
                        .stroke(egui::Stroke::new(1.0_f32, theme::OUTLINE))
                        .corner_radius(8)
                        .inner_margin(22.0)
                        .show(ui, |ui| {
                            ui.set_width(320.0);
                            ui.vertical_centered(|ui| {
                                ui.label(RichText::new("Playback failed").font(theme::bold(16.0)));
                                ui.add_space(10.0);
                                ui.label(error);
                                ui.add_space(14.0);
                                if ui
                                    .button(RichText::new("Retry").color(Color32::BLACK))
                                    .clicked()
                                {
                                    self.worker.send(Command::Prepare(target.clone()));
                                }
                            });
                        });
                });
        } else if state.loading {
            egui::Area::new(egui::Id::new("buffering"))
                .order(egui::Order::Foreground)
                .anchor(egui::Align2::CENTER_CENTER, Vec2::ZERO)
                .show(ctx, |ui| {
                    ui.add(egui::Spinner::new().color(theme::ACCENT).size(36.0));
                });
        }
        if let Some((text, at)) = &self.seek_indicator
            && at.elapsed() < Duration::from_millis(700)
        {
            egui::Area::new(egui::Id::new("seek-feedback"))
                .order(egui::Order::Foreground)
                .anchor(egui::Align2::CENTER_CENTER, Vec2::ZERO)
                .show(ctx, |ui| {
                    ui.label(
                        RichText::new(text)
                            .font(theme::bold(32.0))
                            .color(Color32::WHITE),
                    );
                });
        }
        if !state.ended {
            self.ended_handled = false;
        }
        if state.ended && !self.ended_handled {
            self.persist_progress();
            self.ended_handled = true;
            self.advance_episode();
        }
        if self.last_progress.elapsed() > Duration::from_secs(5) {
            self.persist_progress();
            self.last_progress = Instant::now();
        }
        ctx.request_repaint_after(Duration::from_millis(if state.paused { 150 } else { 33 }));
    }
}
fn paint_icon(ui: &egui::Ui, center: egui::Pos2, name: &str, color: Color32) {
    ui.painter().text(
        center,
        egui::Align2::CENTER_CENTER,
        theme::icon(name).text(),
        egui::FontId::new(20.0, egui::FontFamily::Name("Vela Lucide".into())),
        color,
    );
}
fn icon_button(ui: &mut egui::Ui, name: &str, tooltip: &str, primary: bool) -> egui::Response {
    let (rect, response) = ui.allocate_exact_size(egui::vec2(44.0, 44.0), egui::Sense::click());
    let foreground = if primary {
        Color32::BLACK
    } else {
        Color32::WHITE
    };
    let base = if primary {
        Color32::WHITE
    } else {
        Color32::from_black_alpha(102)
    };
    let (fill, stroke) = control_appearance(ui, &response, base);
    ui.painter().circle_filled(rect.center(), 22.0, fill);
    ui.painter()
        .circle_stroke(rect.center(), 22.0 - stroke.width / 2.0, stroke);
    paint_icon(ui, rect.center(), name, foreground);
    if matches!(name, "rotateCcw" | "rotateCw") {
        ui.painter().text(
            rect.center(),
            egui::Align2::CENTER_CENTER,
            "10",
            theme::bold(9.0),
            foreground,
        );
    }
    response.widget_info(|| egui::WidgetInfo::labeled(egui::WidgetType::Button, true, tooltip));
    response
        .on_hover_cursor(egui::CursorIcon::PointingHand)
        .on_hover_text(tooltip)
}
fn pill_width(ui: &egui::Ui, label: &str) -> f32 {
    (ui.painter()
        .layout_no_wrap(label.into(), theme::bold(12.0), Color32::WHITE)
        .size()
        .x
        + 50.0)
        .clamp(44.0, 190.0)
}
fn pill_button(ui: &mut egui::Ui, icon: &str, label: &str, primary: bool) -> egui::Response {
    let width = pill_width(ui, label);
    let (rect, response) = ui.allocate_exact_size(egui::vec2(width, 44.0), egui::Sense::click());
    let color = if primary {
        Color32::BLACK
    } else {
        Color32::WHITE
    };
    let (fill, stroke) = control_appearance(
        ui,
        &response,
        if primary {
            theme::ACCENT
        } else {
            Color32::from_black_alpha(102)
        },
    );
    ui.painter().rect_filled(rect, 22.0, fill);
    ui.painter()
        .rect_stroke(rect, 22.0, stroke, egui::StrokeKind::Inside);
    paint_icon(
        ui,
        egui::pos2(rect.left() + 22.0, rect.center().y),
        icon,
        color,
    );
    ui.painter().text(
        egui::pos2(rect.left() + 38.0, rect.center().y),
        egui::Align2::LEFT_CENTER,
        label,
        theme::bold(12.0),
        color,
    );
    response.widget_info(|| egui::WidgetInfo::labeled(egui::WidgetType::Button, true, label));
    response.on_hover_cursor(egui::CursorIcon::PointingHand)
}
fn white_slider(
    ui: &mut egui::Ui,
    value: &mut f64,
    max: f64,
    size: Vec2,
    thumb: f32,
    label: &str,
    enabled: bool,
) -> egui::Response {
    let (rect, mut response) = ui.allocate_exact_size(size, egui::Sense::click_and_drag());
    let left = rect.left() + thumb;
    let right = (rect.right() - thumb).max(left + 1.0);
    if enabled && max.is_finite() && max > 0.0 {
        if (response.dragged() || response.clicked())
            && let Some(pointer) = response.interact_pointer_pos()
        {
            let next = (f64::from((pointer.x - left) / (right - left)) * max).clamp(0.0, max);
            if *value != next {
                *value = next;
                response.mark_changed();
            }
        }
        if response.has_focus() {
            let direction = ui.input(|i| {
                i.key_pressed(egui::Key::ArrowRight) as i32
                    - i.key_pressed(egui::Key::ArrowLeft) as i32
            });
            if direction != 0 {
                *value = (*value + max / 100.0 * f64::from(direction)).clamp(0.0, max);
                response.mark_changed();
            }
        }
    }
    if enabled && max.is_finite() && max > 0.0 {
        use egui::accesskit::{Action, ActionData};
        let previous = *value;
        ui.input(|input| {
            for request in input.accesskit_action_requests(response.id, Action::SetValue) {
                if let Some(ActionData::NumericValue(next)) = request.data
                    && next.is_finite()
                {
                    *value = next.clamp(0.0, max);
                }
            }
            let delta = input.num_accesskit_action_requests(response.id, Action::Increment) as f64
                - input.num_accesskit_action_requests(response.id, Action::Decrement) as f64;
            *value = (*value + delta * max / 100.0).clamp(0.0, max);
        });
        if *value != previous {
            response.mark_changed();
        }
    }
    let fraction = if enabled && max.is_finite() && max > 0.0 {
        (*value / max).clamp(0.0, 1.0) as f32
    } else {
        0.0
    };
    let center = egui::pos2(egui::lerp(left..=right, fraction), rect.center().y);
    let pressed = response.dragged() || control_pressed(ui, &response);
    if enabled && (response.hovered() || pressed || response.has_focus()) {
        let halo = if response.has_focus() {
            theme::ACCENT.gamma_multiply(0.25)
        } else {
            Color32::from_white_alpha(if pressed { 64 } else { 36 })
        };
        ui.painter().circle_filled(center, thumb + 7.0, halo);
        if response.has_focus() {
            ui.painter().circle_stroke(
                center,
                thumb + 4.0,
                egui::Stroke::new(2.0_f32, theme::ACCENT),
            );
        }
    }
    ui.painter().line_segment(
        [
            egui::pos2(left, rect.center().y),
            egui::pos2(right, rect.center().y),
        ],
        egui::Stroke::new(
            3.0_f32,
            Color32::from_white_alpha(if enabled && (response.hovered() || pressed) {
                130
            } else {
                85
            }),
        ),
    );
    ui.painter().line_segment(
        [egui::pos2(left, rect.center().y), center],
        egui::Stroke::new(3.0_f32, Color32::WHITE),
    );
    if enabled {
        ui.painter().circle_filled(center, thumb, Color32::WHITE);
    }
    response.widget_info(|| egui::WidgetInfo::slider(enabled, *value, label));
    ui.ctx().accesskit_node_builder(response.id, |node| {
        use egui::accesskit::Action;
        node.set_min_numeric_value(0.0);
        node.set_max_numeric_value(max);
        node.set_numeric_value_step(max / 100.0);
        if enabled {
            node.add_action(Action::SetValue);
            if *value < max {
                node.add_action(Action::Increment);
            }
            if *value > 0.0 {
                node.add_action(Action::Decrement);
            }
        }
    });
    if enabled {
        response.on_hover_cursor(egui::CursorIcon::PointingHand)
    } else {
        response
    }
}
fn control_pressed(ui: &egui::Ui, response: &egui::Response) -> bool {
    response.is_pointer_button_down_on()
        || (response.has_focus()
            && ui.input(|i| i.key_down(egui::Key::Space) || i.key_down(egui::Key::Enter)))
}
fn control_appearance(
    ui: &egui::Ui,
    response: &egui::Response,
    base: Color32,
) -> (Color32, egui::Stroke) {
    let pressed = control_pressed(ui, response);
    let hover = response.hovered() || response.contains_pointer();
    let fill = if base == Color32::WHITE {
        if pressed {
            Color32::from_gray(205)
        } else if hover {
            Color32::from_gray(235)
        } else {
            base
        }
    } else if base == theme::ACCENT {
        if pressed {
            Color32::from_rgb(205, 155, 65)
        } else if hover {
            Color32::from_rgb(245, 202, 110)
        } else {
            base
        }
    } else if pressed {
        Color32::from_rgba_unmultiplied(58, 63, 69, 235)
    } else if hover || response.has_focus() {
        Color32::from_rgba_unmultiplied(42, 46, 51, 204)
    } else {
        base
    };
    let stroke = if response.has_focus() {
        egui::Stroke::new(2.0_f32, theme::ACCENT)
    } else {
        egui::Stroke::new(
            1.0_f32,
            Color32::from_white_alpha(if pressed {
                190
            } else if hover {
                130
            } else {
                46
            }),
        )
    };
    (fill, stroke)
}
fn paint_icon_feedback(ui: &egui::Ui, response: &egui::Response, rect: egui::Rect) {
    if response.hovered() || control_pressed(ui, response) || response.has_focus() {
        ui.painter().circle_filled(
            rect.center(),
            18.0,
            Color32::from_white_alpha(if control_pressed(ui, response) {
                56
            } else {
                28
            }),
        );
        if response.has_focus() {
            ui.painter().circle_stroke(
                rect.center(),
                19.0,
                egui::Stroke::new(2.0_f32, theme::ACCENT),
            );
        }
    }
}
/// Decoration stays in the video's own paint list, after the video callback.
/// It creates no Area or input widget; Foreground controls always paint above it.
fn paint_player_gradients(ui: &egui::Ui, screen: egui::Rect) {
    let painter = ui.painter();
    gradient(
        painter,
        egui::Rect::from_min_size(screen.min, egui::vec2(screen.width(), 180.0)),
        Color32::from_black_alpha(176),
        Color32::TRANSPARENT,
    );
    gradient(
        painter,
        egui::Rect::from_min_size(
            egui::pos2(screen.left(), screen.bottom() - 190.0),
            egui::vec2(screen.width(), 190.0),
        ),
        Color32::TRANSPARENT,
        Color32::from_black_alpha(217),
    );
}
fn gradient(painter: &egui::Painter, rect: egui::Rect, top: Color32, bottom: Color32) {
    let mut mesh = egui::Mesh::default();
    mesh.colored_vertex(rect.left_top(), top);
    mesh.colored_vertex(rect.right_top(), top);
    mesh.colored_vertex(rect.right_bottom(), bottom);
    mesh.colored_vertex(rect.left_bottom(), bottom);
    mesh.add_triangle(0, 1, 2);
    mesh.add_triangle(0, 2, 3);
    painter.add(egui::Shape::mesh(mesh));
}

#[cfg(test)]
mod slider_tests {
    use super::*;
    #[test]
    fn accessible_volume_changes_report_changes_and_enforce_bounds() {
        use egui::accesskit::{Action, ActionData, ActionRequest};
        let context = egui::Context::default();
        let mut value = 37.0;
        let mut id = egui::Id::NULL;
        let _ = context.run(egui::RawInput::default(), |ctx| {
            egui::CentralPanel::default().show(ctx, |ui| {
                id = white_slider(
                    ui,
                    &mut value,
                    100.0,
                    egui::vec2(112.0, 44.0),
                    5.0,
                    "Volume",
                    true,
                )
                .id;
            });
        });
        for (requested, expected) in [(41.0, 41.0), (200.0, 100.0), (-5.0, 0.0)] {
            let input = egui::RawInput {
                events: vec![egui::Event::AccessKitActionRequest(ActionRequest {
                    action: Action::SetValue,
                    target: id.value().into(),
                    data: Some(ActionData::NumericValue(requested)),
                })],
                ..Default::default()
            };
            let _ = context.run(input, |ctx| {
                egui::CentralPanel::default().show(ctx, |ui| {
                    assert!(
                        white_slider(
                            ui,
                            &mut value,
                            100.0,
                            egui::vec2(112.0, 44.0),
                            5.0,
                            "Volume",
                            true
                        )
                        .changed()
                    );
                });
            });
            assert_eq!(value, expected);
        }
    }
}

#[cfg(test)]
mod player_feedback_tests {
    use super::*;

    struct Frame {
        output: egui::FullOutput,
        button: egui::Response,
        video_clicked: bool,
    }
    fn render(ctx: &egui::Context, events: Vec<egui::Event>) -> Frame {
        let mut button = None;
        let mut video_clicked = false;
        let output = ctx.run(
            egui::RawInput {
                screen_rect: Some(egui::Rect::from_min_size(
                    egui::Pos2::ZERO,
                    egui::vec2(600.0, 400.0),
                )),
                events,
                ..Default::default()
            },
            |ctx| {
                let screen = ctx.content_rect();
                egui::CentralPanel::default()
                    .frame(egui::Frame::NONE)
                    .show(ctx, |ui| {
                        let video = ui.allocate_rect(screen, egui::Sense::click());
                        video_clicked = video.clicked();
                        ui.painter().rect_filled(screen, 0.0, Color32::RED);
                        paint_player_gradients(ui, screen);
                    });
                egui::Area::new(egui::Id::new("feedback-test-controls"))
                    .order(egui::Order::Foreground)
                    .fixed_pos(egui::pos2(100.0, 300.0))
                    .show(ctx, |ui| {
                        button = Some(icon_button(ui, "play", "Play", true));
                    });
            },
        );
        Frame {
            output,
            button: button.unwrap(),
            video_clicked,
        }
    }
    fn pointer_button(pos: egui::Pos2, pressed: bool) -> egui::Event {
        egui::Event::PointerButton {
            pos,
            button: egui::PointerButton::Primary,
            pressed,
            modifiers: egui::Modifiers::NONE,
        }
    }
    fn button_fill(frame: &Frame) -> Color32 {
        frame
            .output
            .shapes
            .iter()
            .find_map(|shape| match &shape.shape {
                egui::Shape::Circle(circle)
                    if circle.center == frame.button.rect.center()
                        && circle.fill != Color32::TRANSPARENT =>
                {
                    Some(circle.fill)
                }
                _ => None,
            })
            .expect("the actual button must paint its face")
    }
    fn assert_controls_above_gradients(frame: &Frame) {
        let last_gradient = frame
            .output
            .shapes
            .iter()
            .rposition(|shape| match &shape.shape {
                egui::Shape::Mesh(mesh) => {
                    mesh.vertices.len() == 4
                        && mesh.vertices.iter().any(|vertex| vertex.color.a() == 217)
                }
                _ => false,
            })
            .expect("the bottom video gradient must be present");
        let button = frame
            .output
            .shapes
            .iter()
            .position(|shape| {
                matches!(&shape.shape, egui::Shape::Circle(circle) if circle.center == frame.button.rect.center() && circle.fill != Color32::TRANSPARENT)
            })
            .unwrap();
        assert!(
            last_gradient < button,
            "video dimming must paint before interactive controls, including after Area reordering"
        );
    }
    #[test]
    fn gradients_remain_behind_controls_and_do_not_capture_video_clicks() {
        let ctx = egui::Context::default();
        theme::install(&ctx);
        let _ = render(&ctx, vec![]);
        let frame = render(&ctx, vec![]);
        assert_controls_above_gradients(&frame);
        let point = frame.button.rect.center();
        let pressed = render(
            &ctx,
            vec![
                egui::Event::PointerMoved(point),
                pointer_button(point, true),
            ],
        );
        assert_controls_above_gradients(&pressed);
        let clicked = render(&ctx, vec![pointer_button(point, false)]);
        assert!(clicked.button.clicked());
        assert!(!clicked.video_clicked);
        assert_controls_above_gradients(&clicked);
        // This point remains under the bottom gradient, outside the controls.
        let video_point = egui::pos2(30.0, 370.0);
        let _ = render(
            &ctx,
            vec![
                egui::Event::PointerMoved(video_point),
                pointer_button(video_point, true),
            ],
        );
        assert!(render(&ctx, vec![pointer_button(video_point, false)]).video_clicked);
    }
    #[test]
    fn primary_button_paints_distinct_hover_pressed_and_keyboard_focus_states() {
        let ctx = egui::Context::default();
        theme::install(&ctx);
        let _ = render(&ctx, vec![]);
        let normal = render(&ctx, vec![]);
        let point = normal.button.rect.center();
        let hovered = render(&ctx, vec![egui::Event::PointerMoved(point)]);
        assert_ne!(button_fill(&normal), button_fill(&hovered));
        let pressed = render(&ctx, vec![pointer_button(point, true)]);
        assert_ne!(button_fill(&hovered), button_fill(&pressed));
        let _ = render(&ctx, vec![pointer_button(point, false)]);
        ctx.memory_mut(|memory| memory.request_focus(normal.button.id));
        let _ = render(&ctx, vec![egui::Event::PointerGone]);
        let focused = render(&ctx, vec![]);
        assert!(focused.button.has_focus());
        assert!(focused.output.shapes.iter().any(|shape| {
            matches!(&shape.shape, egui::Shape::Circle(circle) if circle.center == focused.button.rect.center() && circle.stroke.width >= 2.0 && circle.stroke.color == theme::ACCENT)
        }));
    }
}
