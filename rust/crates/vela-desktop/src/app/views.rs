use super::*;
use crate::theme::{self, BORDER, OUTLINE, SIDEBAR, SURFACE_HIGH, TEXT};
use egui::{Align, Align2, FontId, Layout, Rect, Sense, Stroke, Ui, UiBuilder, pos2, vec2};

fn glyph(name: &str) -> String {
    theme::icon(name).text().to_owned()
}
fn title(text: impl Into<String>, size: f32) -> RichText {
    RichText::new(theme::display_text(&text.into()))
        .font(theme::bold(size))
        .color(TEXT)
}
fn icon_button(ui: &mut Ui, icon: &str, tooltip: &str) -> egui::Response {
    let (rect, response) = ui.allocate_exact_size(vec2(38.0, 38.0), Sense::click());
    let pressed = response.is_pointer_button_down_on();
    if response.hovered() || pressed || response.has_focus() {
        ui.painter().rect_filled(
            rect,
            8.0,
            if pressed {
                theme::SELECTED_BG
            } else {
                SURFACE_HIGH
            },
        );
    }
    if response.has_focus() {
        ui.painter().rect_stroke(
            rect,
            8.0,
            Stroke::new(1.0_f32, ACCENT),
            egui::StrokeKind::Inside,
        );
    }
    ui.painter().text(
        rect.center(),
        Align2::CENTER_CENTER,
        glyph(icon),
        FontId::new(18.0, egui::FontFamily::Name("Vela Lucide".into())),
        if !ui.is_enabled() {
            MUTED.gamma_multiply(0.45)
        } else if pressed || response.hovered() {
            ACCENT
        } else {
            TEXT
        },
    );
    response.widget_info(|| {
        egui::WidgetInfo::labeled(egui::WidgetType::Button, ui.is_enabled(), tooltip)
    });
    response
        .on_hover_cursor(egui::CursorIcon::PointingHand)
        .on_hover_text(tooltip)
}
fn icon_label(icon: &str, label: &str, color: Color32) -> egui::text::LayoutJob {
    let mut text = egui::text::LayoutJob::default();
    text.append(
        &glyph(icon),
        0.0,
        egui::TextFormat {
            font_id: FontId::new(18.0, egui::FontFamily::Name("Vela Lucide".into())),
            color,
            ..Default::default()
        },
    );
    text.append(
        &format!("  {label}"),
        0.0,
        egui::TextFormat {
            font_id: theme::bold(14.0),
            color,
            ..Default::default()
        },
    );
    text
}
fn action(ui: &mut Ui, icon: &str, label: &str, primary: bool) -> egui::Response {
    action_enabled(ui, icon, label, primary, true)
}
fn action_enabled(
    ui: &mut Ui,
    icon: &str,
    label: &str,
    primary: bool,
    enabled: bool,
) -> egui::Response {
    let previous_style = ui.style().clone();
    {
        let widgets = &mut ui.style_mut().visuals.widgets;
        for (visual, fill) in [
            (
                &mut widgets.inactive,
                if primary {
                    ACCENT
                } else {
                    Color32::TRANSPARENT
                },
            ),
            (
                &mut widgets.hovered,
                if primary {
                    Color32::from_rgb(244, 202, 115)
                } else {
                    SURFACE_HIGH
                },
            ),
            (
                &mut widgets.active,
                if primary {
                    Color32::from_rgb(206, 158, 70)
                } else {
                    theme::SELECTED_BG
                },
            ),
        ] {
            visual.weak_bg_fill = fill;
            visual.bg_stroke = if primary {
                Stroke::NONE
            } else {
                Stroke::new(1.0_f32, OUTLINE)
            };
        }
    }
    let response = ui
        .add_enabled(
            enabled,
            egui::Button::new(icon_label(icon, label, if primary { BG } else { TEXT }))
                .wrap_mode(egui::TextWrapMode::Extend)
                .min_size(vec2(44.0, 40.0)),
        )
        .on_hover_cursor(egui::CursorIcon::PointingHand);
    ui.set_style(previous_style);
    response
}
fn field(ui: &mut Ui, icon: &str, label: &str, value: &mut String, password: bool) {
    let response = ui.allocate_ui_with_layout(
        vec2(ui.available_width(), 44.0),
        Layout::left_to_right(Align::Center),
        |ui| {
            ui.add_space(10.0);
            ui.label(theme::icon(icon).size(22.0).color(MUTED));
            ui.add_sized(
                [ui.available_width() - 12.0, 32.0],
                egui::TextEdit::singleline(value)
                    .hint_text(label)
                    .password(password)
                    .frame(false),
            );
        },
    );
    ui.painter().hline(
        response.response.rect.x_range(),
        response.response.rect.bottom(),
        Stroke::new(1.0_f32, OUTLINE),
    );
}

fn gradient(painter: &egui::Painter, rect: Rect, start: Color32, end: Color32, horizontal: bool) {
    let mut mesh = egui::Mesh::default();
    let colors = if horizontal {
        [start, end, end, start]
    } else {
        [start, start, end, end]
    };
    for (pos, color) in [
        rect.left_top(),
        rect.right_top(),
        rect.right_bottom(),
        rect.left_bottom(),
    ]
    .into_iter()
    .zip(colors)
    {
        mesh.vertices.push(egui::epaint::Vertex {
            pos,
            uv: egui::epaint::WHITE_UV,
            color,
        });
    }
    mesh.indices.extend_from_slice(&[0, 1, 2, 0, 2, 3]);
    painter.add(egui::Shape::mesh(mesh));
}
fn dark(alpha: u8) -> Color32 {
    Color32::from_rgba_unmultiplied(12, 13, 14, alpha)
}

fn import_progress_text(progress: &imports::ImportProgress) -> String {
    let amount = |count: u64| {
        if progress.unit == "bytes" {
            if count < 1024 {
                format!("{count} B")
            } else if count < 1_048_576 {
                format!("{:.1} KiB", count as f64 / 1024.0)
            } else {
                format!("{:.1} MiB", count as f64 / 1_048_576.0)
            }
        } else {
            format!("{count} {}", progress.unit)
        }
    };
    match progress.total.filter(|total| *total > 0) {
        Some(total) => format!(
            "{} · {} / {} · {:.0}%",
            progress.stage,
            amount(progress.completed.min(total)),
            amount(total),
            (progress.completed as f64 / total as f64 * 100.0).clamp(0.0, 100.0)
        ),
        None if progress.completed > 0 => {
            format!("{} · {}", progress.stage, amount(progress.completed))
        }
        None => progress.stage.clone(),
    }
}

impl VelaApp {
    pub(super) fn import_status(&self, ctx: &egui::Context) {
        if !self.importing {
            return;
        }
        egui::TopBottomPanel::top("global-library-refresh")
            .frame(
                egui::Frame::new()
                    .fill(PANEL)
                    .inner_margin(egui::Margin::symmetric(18, 8)),
            )
            .show(ctx, |ui| {
                ui.horizontal_wrapped(|ui| {
                    ui.add(egui::Spinner::new().size(16.0));
                    ui.label(
                        RichText::new("Updating library…")
                            .color(ACCENT)
                            .font(theme::bold(14.0)),
                    );
                });
                for (_, name, progress) in self.import_jobs.values() {
                    ui.horizontal_wrapped(|ui| {
                        ui.label(RichText::new(name).font(theme::bold(13.0)));
                        ui.label(RichText::new(import_progress_text(progress)).color(MUTED));
                        if let Some(total) = progress.total.filter(|total| *total > 0) {
                            ui.add(
                                egui::ProgressBar::new(
                                    (progress.completed as f64 / total as f64).clamp(0.0, 1.0)
                                        as f32,
                                )
                                .desired_width(160.0)
                                .desired_height(6.0)
                                .fill(ACCENT),
                            );
                        }
                    });
                }
            });
    }
    pub(super) fn sidebar(&mut self, ctx: &egui::Context) {
        let screen = ctx.content_rect();
        let hovered = ctx
            .input(|i| i.pointer.hover_pos())
            .is_some_and(|p| p.x <= self.sidebar_width && screen.contains(p));
        let expanded = self.sidebar_pinned || hovered;
        self.sidebar_width = ctx.animate_value_with_time(
            egui::Id::new("sidebar-width"),
            if expanded { 232.0 } else { 72.0 },
            0.16,
        );
        let width = self.sidebar_width;
        egui::SidePanel::left("navigation")
            .exact_width(width)
            .resizable(false)
            .frame(egui::Frame::new().fill(SIDEBAR).inner_margin(0.0))
            .show(ctx, |ui| {
                ui.spacing_mut().item_spacing.y = 0.0;
                let area = ui.max_rect();
                ui.painter().line_segment(
                    [area.right_top(), area.right_bottom()],
                    Stroke::new(1.0_f32, BORDER),
                );
                egui::Frame::new().inner_margin(0.0).show(ui, |ui| {
                    ui.add_space(18.0);
                    ui.horizontal(|ui| {
                        ui.add_space(12.0);
                        let (rect, _) = ui.allocate_exact_size(vec2(40.0, 40.0), Sense::hover());
                        theme::paint_logo(ui.painter(), rect, ACCENT);
                        if width > 145.0 {
                            ui.add_space(12.0);
                            ui.label(title("Vela", 16.0));
                            ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                                if icon_button(
                                    ui,
                                    if self.sidebar_pinned { "pinOff" } else { "pin" },
                                    if self.sidebar_pinned {
                                        "Unpin sidebar"
                                    } else {
                                        "Pin sidebar"
                                    },
                                )
                                .clicked()
                                {
                                    self.sidebar_pinned = !self.sidebar_pinned;
                                    self.worker.send(Command::Setting(
                                        "sidebar_pinned".into(),
                                        self.sidebar_pinned.to_string(),
                                    ));
                                }
                            });
                        }
                    });
                    ui.add_space(24.0);
                    for (section, icon) in [
                        (Section::Home, "house"),
                        (Section::Live, "tv"),
                        (Section::Movies, "film"),
                        (Section::Series, "library"),
                        (Section::Favorites, "star"),
                        (Section::Recent, "history"),
                        (Section::Settings, "settings"),
                    ] {
                        let selected = self.section == section
                            || (section == Section::Live && self.section == Section::Guide);
                        let row = Rect::from_min_size(
                            pos2(area.left() + 12.0, ui.cursor().min.y),
                            vec2((width - 24.0).max(48.0), 44.0),
                        );
                        let response = ui
                            .allocate_rect(row, Sense::click())
                            .on_hover_text(section.label());
                        response.widget_info(|| {
                            egui::WidgetInfo::labeled(
                                egui::WidgetType::Button,
                                true,
                                section.label(),
                            )
                        });
                        if selected || response.hovered() {
                            ui.painter().rect_filled(
                                row,
                                8.0,
                                if selected {
                                    Color32::from_rgb(37, 33, 26)
                                } else {
                                    SURFACE_HIGH
                                },
                            );
                        }
                        let color = if selected {
                            ACCENT
                        } else {
                            Color32::from_rgb(215, 208, 198)
                        };
                        ui.painter().text(
                            pos2(row.left() + 24.0, row.center().y),
                            Align2::CENTER_CENTER,
                            glyph(icon),
                            FontId::new(20.0, egui::FontFamily::Name("Vela Lucide".into())),
                            color,
                        );
                        if width > 145.0 {
                            ui.painter().text(
                                pos2(row.left() + 58.0, row.center().y),
                                Align2::LEFT_CENTER,
                                section.label(),
                                theme::medium(14.0),
                                if selected { TEXT } else { MUTED },
                            );
                        }
                        if response.clicked()
                            && (!self.providers.is_empty()
                                || matches!(
                                    section,
                                    Section::Home | Section::Live | Section::Settings
                                ))
                        {
                            self.navigate(section);
                        }
                        ui.add_space(4.0);
                        if section == Section::Recent {
                            ui.add_space(8.0);
                            ui.painter().hline(
                                (area.left() + 12.0)..=(area.right() - 12.0),
                                ui.cursor().min.y,
                                Stroke::new(1.0_f32, BORDER),
                            );
                            ui.add_space(9.0);
                        }
                    }
                    if let Some(status) = self
                        .update_status
                        .clone()
                        .filter(|status| status.has_update)
                    {
                        let rect = Rect::from_min_size(
                            pos2(area.left() + 12.0, area.bottom() - 86.0),
                            vec2((width - 24.0).max(48.0), 44.0),
                        );
                        let response = ui
                            .interact(
                                rect,
                                ui.id().with("sidebar-download-update"),
                                Sense::click(),
                            )
                            .on_hover_text(format!("Download Update {}", status.latest_version));
                        ui.painter()
                            .rect_filled(rect, 8.0, Color32::from_rgb(37, 33, 26));
                        ui.painter().rect_stroke(
                            rect,
                            8.0,
                            Stroke::new(
                                1.0_f32,
                                Color32::from_rgba_unmultiplied(231, 184, 91, 115),
                            ),
                            egui::StrokeKind::Inside,
                        );
                        let icon_center = pos2(
                            rect.left() + if width > 145.0 { 26.0 } else { 24.0 },
                            rect.center().y,
                        );
                        ui.painter().text(
                            icon_center,
                            Align2::CENTER_CENTER,
                            glyph("download"),
                            FontId::new(20.0, egui::FontFamily::Name("Vela Lucide".into())),
                            ACCENT,
                        );
                        ui.painter().circle_filled(
                            icon_center + vec2(8.0, -7.0),
                            4.0,
                            Color32::from_rgb(226, 109, 90),
                        );
                        ui.painter().circle_stroke(
                            icon_center + vec2(8.0, -7.0),
                            4.0,
                            Stroke::new(1.5_f32, Color32::from_rgb(37, 33, 26)),
                        );
                        if width > 145.0 {
                            ui.painter().text(
                                pos2(rect.left() + 56.0, rect.center().y),
                                Align2::LEFT_CENTER,
                                format!("Update {}", status.latest_version),
                                theme::bold(14.0),
                                ACCENT,
                            );
                        }
                        if response.clicked() {
                            let _ = open::that(&status.release_url);
                        }
                    }
                    if width > 145.0 {
                        ui.painter().text(
                            pos2(area.left() + 12.0, area.bottom() - 22.0),
                            Align2::LEFT_CENTER,
                            format!("Vela {}", env!("CARGO_PKG_VERSION")),
                            FontId::proportional(11.0),
                            Color32::from_rgb(113, 109, 102),
                        );
                    }
                });
            });
    }

    pub(super) fn header(&mut self, ui: &mut Ui) {
        egui::Frame::new()
            .inner_margin(egui::Margin {
                left: 24,
                right: 24,
                top: 18,
                bottom: 18,
            })
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.allocate_ui_with_layout(
                        vec2(230.0, 58.0),
                        Layout::top_down(Align::LEFT),
                        |ui| {
                            ui.set_min_width(230.0);
                            ui.label(
                                title(
                                    match self.section {
                                        Section::Recent => "History",
                                        _ => "Catalog",
                                    },
                                    11.0,
                                )
                                .color(ACCENT),
                            );
                            ui.add_space(2.0);
                            ui.label(title(self.section.label(), 28.0));
                        },
                    );
                    let extras = if self.section == Section::Live {
                        136.0
                    } else {
                        44.0
                    };
                    egui::Frame::new()
                        .fill(PANEL)
                        .corner_radius(8)
                        .stroke(Stroke::new(1.0_f32, OUTLINE))
                        .inner_margin(10.0)
                        .show(ui, |ui| {
                            ui.horizontal(|ui| {
                                ui.label(
                                    theme::icon(
                                        if crate::worker::global_search_query(&self.query.search)
                                            .is_some()
                                        {
                                            "globe2"
                                        } else {
                                            "search"
                                        },
                                    )
                                    .size(20.0)
                                    .color(MUTED),
                                );
                                let hint = if crate::worker::global_search_query(&self.query.search)
                                    .is_some()
                                {
                                    "Global search".to_owned()
                                } else {
                                    format!(
                                        "Search {} or / global",
                                        self.section.label().to_lowercase()
                                    )
                                };
                                let response = ui.add_sized(
                                    [(ui.available_width() - extras).max(80.0), 28.0],
                                    egui::TextEdit::singleline(&mut self.query.search)
                                        .hint_text(hint)
                                        .frame(false),
                                );
                                if response.changed() {
                                    self.search_changed = Some(Instant::now());
                                    self.loading = true;
                                }
                            });
                        });
                    let global = crate::worker::global_search_query(&self.query.search).is_some();
                    if icon_button(
                        ui,
                        if global { "search" } else { "globe2" },
                        if global {
                            "Search this section"
                        } else {
                            "Search everything"
                        },
                    )
                    .clicked()
                    {
                        crate::worker::toggle_global_search(&mut self.query);
                        self.search_changed = None;
                        self.reload();
                    }
                    if self.section == Section::Live {
                        ui.horizontal(|ui| {
                            if ui
                                .add(egui::Button::selectable(
                                    !self.live_guide_mode,
                                    theme::icon("list").size(18.0),
                                ))
                                .on_hover_text("List view")
                                .clicked()
                            {
                                self.live_guide_mode = false;
                            }
                            if ui
                                .add(egui::Button::selectable(
                                    self.live_guide_mode,
                                    theme::icon("calendarDays").size(18.0),
                                ))
                                .on_hover_text("Guide view")
                                .clicked()
                            {
                                self.live_guide_mode = true;
                                self.request_guide();
                            }
                        });
                    }
                });
                self.notices(ui);
            });
    }
    fn notices(&mut self, ui: &mut Ui) {
        if let Some(error) = self.error.clone() {
            ui.add_space(8.0);
            egui::Frame::new()
                .fill(Color32::from_rgb(44, 27, 24))
                .corner_radius(8)
                .inner_margin(10.0)
                .show(ui, |ui| {
                    ui.horizontal_wrapped(|ui| {
                        ui.label(theme::icon("circleAlert").color(Color32::from_rgb(226, 109, 90)));
                        ui.label(error);
                        if icon_button(ui, "x", "Dismiss").clicked() {
                            self.error = None;
                        }
                    });
                });
        }
    }

    pub(super) fn catalog(&mut self, ui: &mut Ui) {
        if self.section == Section::Home {
            self.home_ui(ui);
            return;
        }
        if self.providers.is_empty()
            || (self.providers.iter().all(|p| p.last_refresh_at.is_none())
                && self.page.total == 0
                && crate::worker::global_search_query(&self.query.search).is_none())
        {
            self.onboarding(ui);
            return;
        }
        self.header(ui);
        if crate::worker::global_search_query(&self.query.search).is_some() {
            self.global_search_ui(ui);
            return;
        }
        let body = ui.available_rect_before_wrap();
        let has_categories = matches!(
            self.section,
            Section::Live | Section::Movies | Section::Series
        );
        let category_width = if has_categories {
            self.category_sidebar_width
                .clamp(220.0, 420.0)
                .min((body.width() - 500.0).max(220.0))
        } else {
            20.0
        };
        let category_rect = Rect::from_min_size(body.min, vec2(category_width, body.height()));
        let drag_rect = Rect::from_min_size(
            pos2(category_rect.right(), body.top()),
            vec2(10.0, body.height()),
        );
        let detail_rect = Rect::from_min_size(
            pos2(body.right() - 320.0, body.top()),
            vec2(320.0, body.height()),
        );
        let center = Rect::from_min_max(
            pos2(drag_rect.right(), body.top()),
            pos2(detail_rect.left(), body.bottom()),
        );
        if has_categories {
            ui.painter()
                .rect_filled(category_rect, 0.0, Color32::from_rgb(17, 19, 21));
        }
        ui.painter()
            .rect_filled(detail_rect, 0.0, Color32::from_rgb(17, 19, 21));
        ui.painter().line_segment(
            [detail_rect.left_top(), detail_rect.left_bottom()],
            Stroke::new(1.0_f32, BORDER),
        );
        if has_categories {
            ui.scope_builder(
                UiBuilder::new().max_rect(category_rect.shrink2(vec2(14.0, 18.0))),
                |ui| self.categories(ui),
            );
        }
        let drag = ui.interact(drag_rect, ui.id().with("category-resize"), Sense::drag());
        if has_categories
            && drag.dragged()
            && let Some(pointer) = drag.interact_pointer_pos()
        {
            self.category_sidebar_width = (pointer.x - body.left()).clamp(220.0, 420.0);
        }
        if drag.drag_stopped() {
            self.worker.send(Command::Setting(
                "category_sidebar_width".into(),
                self.category_sidebar_width.to_string(),
            ));
        }
        if has_categories && (drag.hovered() || drag.dragged()) {
            ui.ctx().set_cursor_icon(egui::CursorIcon::ResizeHorizontal);
            ui.painter().vline(
                drag_rect.center().x,
                drag_rect.y_range(),
                Stroke::new(2.0_f32, ACCENT),
            );
        } else if has_categories {
            ui.painter().vline(
                category_rect.right(),
                category_rect.y_range(),
                Stroke::new(1.0_f32, BORDER),
            );
        }
        ui.scope_builder(UiBuilder::new().max_rect(center.shrink(14.0)), |ui| {
            if self.live_guide_mode && self.section == Section::Live {
                self.guide_ui(ui);
            } else {
                self.catalog_items(ui);
            }
        });
        if !self.loading
            && self.selected_catalog.is_none()
            && let Some(first) = self.page.items.first().cloned()
        {
            self.select_catalog(first);
        }
        ui.scope_builder(
            UiBuilder::new().max_rect(detail_rect.shrink2(vec2(17.0, 18.0))),
            |ui| self.detail_panel(ui),
        );
        ui.advance_cursor_after_rect(body);
    }
    pub(super) fn categories(&mut self, ui: &mut Ui) {
        ui.horizontal(|ui| {
            ui.label(title("Categories", 14.0));
            ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                ui.label(
                    RichText::new(
                        self.categories
                            .iter()
                            .map(|c| c.item_count)
                            .sum::<i64>()
                            .to_string(),
                    )
                    .size(12.0)
                    .color(MUTED),
                );
            });
        });
        ui.add_space(12.0);
        egui::Frame::new()
            .stroke(Stroke::new(1.0_f32, OUTLINE))
            .corner_radius(8)
            .inner_margin(8.0)
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.label(theme::icon("search").size(18.0).color(MUTED));
                    ui.add_sized(
                        [ui.available_width(), 24.0],
                        egui::TextEdit::singleline(&mut self.category_search)
                            .hint_text("Search categories")
                            .frame(false),
                    );
                });
            });
        ui.add_space(8.0);
        let kind = self.query.content_type.as_deref().unwrap_or("live");
        let sort_key = format!("category_sort:{kind}");
        let favorites_key = format!("category_favorites_only:{kind}");
        let mut sort = self
            .settings
            .get(&sort_key)
            .cloned()
            .filter(|value| ["my_order", "a_z", "z_a", "count"].contains(&value.as_str()))
            .unwrap_or_else(|| "my_order".into());
        let mut favorites_only = self
            .settings
            .get(&favorites_key)
            .is_some_and(|value| value == "true");
        let old_sort = sort.clone();
        let old_favorites = favorites_only;
        ui.horizontal(|ui| {
            egui::ComboBox::from_id_salt(("category-sort", kind))
                .width((ui.available_width() - 6.0).max(100.0))
                .selected_text(match sort.as_str() {
                    "a_z" => "A–Z",
                    "z_a" => "Z–A",
                    "count" => "Most items",
                    _ => "My order",
                })
                .show_ui(ui, |ui| {
                    for (value, label) in [
                        ("my_order", "My order"),
                        ("a_z", "A–Z"),
                        ("z_a", "Z–A"),
                        ("count", "Most items"),
                    ] {
                        ui.selectable_value(&mut sort, value.into(), label);
                    }
                });
        });
        ui.horizontal(|ui| {
            ui.label(theme::icon("star").size(16.0).color(if favorites_only {
                ACCENT
            } else {
                MUTED
            }));
            ui.checkbox(&mut favorites_only, "Favorite categories");
        });
        for (key, value, changed) in [
            (sort_key, sort.clone(), sort != old_sort),
            (
                favorites_key,
                favorites_only.to_string(),
                favorites_only != old_favorites,
            ),
        ] {
            if changed {
                self.settings.insert(key.clone(), value.clone());
                self.worker.send(Command::Setting(key, value));
            }
        }
        ui.add_space(8.0);
        let all = self.categories.iter().map(|c| c.item_count).sum();
        if self
            .category_row(ui, "All", all, self.query.category_id.is_none(), false)
            .clicked()
        {
            self.query.category_id = None;
            self.query.offset = 0;
            self.selected_catalog = None;
            self.reload();
        }
        ui.add_space(8.0);
        let search = self.category_search.trim().to_lowercase();
        let ordered = ordered_categories(&self.categories, &sort, favorites_only, &search);
        let reorder_disabled = !search.is_empty() || sort != "my_order";
        egui::ScrollArea::vertical()
            .id_salt(("category-list", self.section.label()))
            .auto_shrink([false, false])
            .show(ui, |ui| {
                if ordered.is_empty() {
                    ui.label(
                        RichText::new(if favorites_only {
                            "No favorite categories."
                        } else {
                            "No matching categories."
                        })
                        .size(12.0)
                        .color(MUTED),
                    );
                }
                for (index, category) in ordered.iter().enumerate() {
                    let same_scope = |other: &Category| {
                        other.provider_id == category.provider_id
                            && other.content_type == category.content_type
                            && other.is_favorite == category.is_favorite
                    };
                    let can_up = !reorder_disabled && index > 0 && same_scope(&ordered[index - 1]);
                    let can_down = !reorder_disabled
                        && index + 1 < ordered.len()
                        && same_scope(&ordered[index + 1]);
                    let actions = self.category_action_row(
                        ui,
                        category,
                        self.query.category_id.as_deref() == Some(&category.id),
                        can_up,
                        can_down,
                        reorder_disabled,
                    );
                    if actions.0 {
                        self.query.category_id = Some(category.id.clone());
                        self.query.offset = 0;
                        self.selected_catalog = None;
                        self.reload();
                    }
                    if actions.1 {
                        self.worker.send(Command::CategoryFavorite(
                            category.provider_id.clone(),
                            category.content_type.clone(),
                            category.id.clone(),
                        ));
                        if let Some(current) = self.categories.iter_mut().find(|c| {
                            c.provider_id == category.provider_id
                                && c.content_type == category.content_type
                                && c.id == category.id
                        }) {
                            current.is_favorite = !current.is_favorite;
                        }
                    }
                    if actions.2 != 0 {
                        let mut ids = ordered_categories(&self.categories, "my_order", false, "")
                            .iter()
                            .filter(|c| {
                                c.provider_id == category.provider_id
                                    && c.content_type == category.content_type
                            })
                            .map(|c| c.id.clone())
                            .collect::<Vec<_>>();
                        if let Some(at) = ids.iter().position(|id| id == &category.id) {
                            let next = at as isize + actions.2;
                            if next >= 0 && (next as usize) < ids.len() {
                                ids.swap(at, next as usize);
                                self.worker.send(Command::ReorderCategories(
                                    category.provider_id.clone(),
                                    category.content_type.clone(),
                                    ids.clone(),
                                ));
                                for (position, id) in ids.iter().enumerate() {
                                    if let Some(current) = self.categories.iter_mut().find(|c| {
                                        c.provider_id == category.provider_id
                                            && c.content_type == category.content_type
                                            && c.id == *id
                                    }) {
                                        current.sort_order = Some(position as i64);
                                    }
                                }
                            }
                        }
                    }
                    ui.add_space(6.0);
                }
            });
    }
    fn category_action_row(
        &self,
        ui: &mut Ui,
        category: &Category,
        selected: bool,
        can_up: bool,
        can_down: bool,
        reorder_disabled: bool,
    ) -> (bool, bool, isize) {
        let foreground = if selected {
            ACCENT
        } else {
            Color32::from_rgb(215, 208, 198)
        };
        let label_width = (ui.available_width() - 134.0).max(36.0);
        let mut job = egui::text::LayoutJob::simple(
            theme::display_text(&category.name),
            theme::bold(14.0),
            foreground,
            label_width,
        );
        job.wrap.max_rows = 3;
        job.wrap.break_anywhere = true;
        let galley = ui.fonts_mut(|fonts| fonts.layout_job(job));
        let height = (galley.size().y + 14.0).max(46.0);
        let (rect, _) = ui.allocate_exact_size(vec2(ui.available_width(), height), Sense::hover());
        let selection = ui
            .interact(
                Rect::from_min_max(rect.min, pos2(rect.right() - 84.0, rect.bottom())),
                ui.id().with((
                    "select-category",
                    &category.provider_id,
                    &category.content_type,
                    &category.id,
                )),
                Sense::click(),
            )
            .on_hover_text(&category.name);
        selection.widget_info(|| {
            egui::WidgetInfo::labeled(
                egui::WidgetType::Button,
                true,
                format!("{}: {} items", category.name, category.item_count),
            )
        });
        if selected || selection.hovered() {
            ui.painter().rect_filled(
                rect,
                8.0,
                if selected {
                    Color32::from_rgb(37, 33, 26)
                } else {
                    SURFACE_HIGH
                },
            );
        }
        ui.painter().galley(
            pos2(rect.left() + 10.0, rect.center().y - galley.size().y / 2.0),
            galley,
            foreground,
        );
        ui.painter().text(
            pos2(rect.right() - 89.0, rect.center().y),
            Align2::RIGHT_CENTER,
            category.item_count.to_string(),
            FontId::proportional(11.0),
            Color32::from_rgb(142, 137, 128),
        );
        let mut favorite = false;
        let mut movement = 0;
        for (index, (icon, tooltip, enabled)) in [
            (
                "star",
                if category.is_favorite {
                    "Unfavorite category"
                } else {
                    "Favorite category"
                },
                true,
            ),
            (
                "chevronUp",
                if reorder_disabled {
                    "Select My order and clear category search to reorder"
                } else {
                    "Move up"
                },
                can_up,
            ),
            (
                "chevronDown",
                if reorder_disabled {
                    "Select My order and clear category search to reorder"
                } else {
                    "Move down"
                },
                can_down,
            ),
        ]
        .into_iter()
        .enumerate()
        {
            let button = Rect::from_center_size(
                pos2(rect.right() - 70.0 + 28.0 * index as f32, rect.center().y),
                vec2(28.0, 36.0),
            );
            let response = category_control_button(
                ui,
                button,
                ui.id().with((
                    "category-action",
                    &category.provider_id,
                    &category.content_type,
                    &category.id,
                    index,
                )),
                icon,
                tooltip,
                enabled,
                index == 0 && category.is_favorite,
            );
            let clicked = enabled && response.clicked();
            if clicked {
                if index == 0 {
                    favorite = true;
                } else {
                    movement = if index == 1 { -1 } else { 1 };
                }
            }
        }
        (selection.clicked(), favorite, movement)
    }
    fn category_row(
        &self,
        ui: &mut Ui,
        label: &str,
        count: i64,
        selected: bool,
        favorite: bool,
    ) -> egui::Response {
        let (rect, response) =
            ui.allocate_exact_size(vec2(ui.available_width(), 42.0), Sense::click());
        if selected || response.hovered() {
            ui.painter().rect_filled(
                rect,
                8.0,
                if selected {
                    Color32::from_rgb(37, 33, 26)
                } else {
                    SURFACE_HIGH
                },
            );
        }
        let text = format!("{}{}", if favorite { "★ " } else { "" }, label);
        let galley = ui.painter().layout(
            theme::display_text(&text),
            FontId::proportional(14.0),
            if selected { TEXT } else { MUTED },
            (rect.width() - 60.0).max(30.0),
        );
        ui.painter().galley(
            pos2(rect.left() + 12.0, rect.center().y - galley.size().y / 2.0),
            galley,
            TEXT,
        );
        ui.painter().text(
            pos2(rect.right() - 10.0, rect.center().y),
            Align2::RIGHT_CENTER,
            count.to_string(),
            FontId::proportional(12.0),
            MUTED,
        );
        response
    }
    pub(super) fn select_catalog(&mut self, item: CatalogItem) {
        self.open_detail(item.clone());
        self.details = None;
        self.selected_catalog = Some(item);
    }
    fn catalog_items(&mut self, ui: &mut Ui) {
        let items = self.page.items.clone();
        if self.loading {
            ui.horizontal(|ui| {
                ui.spinner();
                ui.label(RichText::new("Loading catalog…").color(MUTED));
            });
        }
        if items.is_empty() {
            ui.add_space(60.0);
            ui.vertical_centered(|ui| {
                ui.label(theme::icon("search").size(34.0).color(ACCENT));
                ui.add_space(14.0);
                ui.label(title("No items found", 18.0));
                ui.label(RichText::new("Try another category or search.").color(MUTED));
            });
            return;
        }
        let live = self.section == Section::Live;
        egui::ScrollArea::vertical()
            .id_salt(("catalog-items", self.section.label()))
            .auto_shrink([false, false])
            .show(ui, |ui| {
                if live {
                    for item in &items {
                        let selected = self
                            .selected_catalog
                            .as_ref()
                            .is_some_and(|s| s.provider_id == item.provider_id && s.id == item.id);
                        let width = ui.available_width();
                        let response = egui::Frame::new()
                            .fill(if selected {
                                Color32::from_rgb(31, 33, 30)
                            } else {
                                PANEL
                            })
                            .stroke(Stroke::new(1.0_f32, if selected { ACCENT } else { BORDER }))
                            .corner_radius(8)
                            .inner_margin(8.0)
                            .show(ui, |ui| {
                                ui.set_min_size(vec2(width - 16.0, 56.0));
                                ui.horizontal(|ui| {
                                    let (rect, _) =
                                        ui.allocate_exact_size(vec2(72.0, 48.0), Sense::hover());
                                    self.paint_artwork(ui, item, rect);
                                    ui.vertical(|ui| {
                                        ui.label(title(&item.title, 14.0));
                                        ui.label(
                                            RichText::new(theme::display_text(
                                                item.subtitle.as_deref().unwrap_or("Live TV"),
                                            ))
                                            .size(12.0)
                                            .color(MUTED),
                                        );
                                    });
                                });
                            })
                            .response
                            .interact(Sense::click());
                        if response.clicked() {
                            self.select_catalog(item.clone());
                        }
                        if response.double_clicked() {
                            self.prepare(item.clone());
                        }
                        ui.add_space(8.0);
                    }
                } else {
                    let columns = (ui.available_width() / 174.0).ceil().max(1.0) as usize;
                    let width = (ui.available_width() - 10.0 * (columns.saturating_sub(1) as f32))
                        / columns as f32;
                    for row in items.chunks(columns) {
                        ui.horizontal_top(|ui| {
                            ui.spacing_mut().item_spacing.x = 10.0;
                            for item in row {
                                self.grid_card(ui, item, width);
                            }
                        });
                        ui.add_space(10.0);
                    }
                }
                ui.add_space(12.0);
                ui.horizontal(|ui| {
                    if ui
                        .add_enabled(self.query.offset > 0, egui::Button::new("Previous"))
                        .clicked()
                    {
                        self.query.offset = self.query.offset.saturating_sub(PAGE_SIZE);
                        self.selected_catalog = None;
                        self.reload();
                    }
                    ui.label(
                        RichText::new(format!(
                            "{}–{} of {}",
                            self.query.offset + 1,
                            (self.query.offset + items.len()).min(self.page.total),
                            self.page.total
                        ))
                        .size(11.0)
                        .color(MUTED),
                    );
                    if ui
                        .add_enabled(
                            self.query.offset + items.len() < self.page.total,
                            egui::Button::new("Next"),
                        )
                        .clicked()
                    {
                        self.query.offset += PAGE_SIZE;
                        self.selected_catalog = None;
                        self.reload();
                    }
                });
            });
    }
    fn paint_artwork(&mut self, ui: &Ui, item: &CatalogItem, rect: Rect) {
        ui.painter().rect_filled(rect, 8.0, PANEL);
        ui.painter().rect_stroke(
            rect,
            8.0,
            Stroke::new(1.0_f32, Color32::from_white_alpha(26)),
            egui::StrokeKind::Inside,
        );
        if let Some(texture) = item
            .artwork_url
            .as_deref()
            .and_then(|url| self.artwork.texture(ui.ctx(), url))
        {
            let aspect = texture.size_vec2().x / texture.size_vec2().y;
            let target = rect.width() / rect.height();
            let uv = if aspect > target {
                let w = target / aspect;
                Rect::from_min_max(pos2((1.0 - w) / 2.0, 0.0), pos2((1.0 + w) / 2.0, 1.0))
            } else {
                let h = aspect / target;
                Rect::from_min_max(pos2(0.0, (1.0 - h) / 2.0), pos2(1.0, (1.0 + h) / 2.0))
            };
            ui.painter().image(texture.id(), rect, uv, Color32::WHITE);
        } else {
            ui.painter().text(
                rect.center(),
                Align2::CENTER_CENTER,
                glyph(match item.content_type.as_str() {
                    "live" => "tv",
                    "series" => "library",
                    _ => "film",
                }),
                FontId::new(36.0, egui::FontFamily::Name("Vela Lucide".into())),
                Color32::from_rgb(113, 109, 102),
            );
        }
    }
    fn grid_card(&mut self, ui: &mut Ui, item: &CatalogItem, width: f32) {
        let height = width / 0.8;
        let (rect, response) = ui.allocate_exact_size(vec2(width, height), Sense::click());
        let selected = self
            .selected_catalog
            .as_ref()
            .is_some_and(|s| s.id == item.id && s.provider_id == item.provider_id);
        ui.painter().rect_filled(
            rect,
            8.0,
            if selected {
                Color32::from_rgb(31, 33, 30)
            } else {
                PANEL
            },
        );
        ui.painter().rect_stroke(
            rect,
            8.0,
            Stroke::new(1.0_f32, if selected { ACCENT } else { BORDER }),
            egui::StrokeKind::Inside,
        );
        let artwork = Rect::from_min_max(
            rect.min + vec2(8.0, 8.0),
            pos2(rect.right() - 8.0, rect.bottom() - 60.0),
        );
        self.paint_artwork(ui, item, artwork);
        let badge =
            Rect::from_center_size(artwork.right_bottom() - vec2(20.5, 20.5), vec2(25.0, 25.0));
        ui.painter().circle_filled(badge.center(), 12.5, ACCENT);
        ui.painter().text(
            badge.center(),
            Align2::CENTER_CENTER,
            glyph("play"),
            FontId::new(13.0, egui::FontFamily::Name("Vela Lucide".into())),
            BG,
        );
        if ui
            .interact(
                badge,
                ui.id().with(("home-play", &item.provider_id, &item.id)),
                Sense::click(),
            )
            .clicked()
        {
            self.prepare(item.clone());
        }

        let galley = ui.painter().layout(
            theme::display_text(&item.title),
            theme::bold(14.0),
            TEXT,
            width - 16.0,
        );
        ui.painter()
            .with_clip_rect(Rect::from_min_size(
                pos2(rect.left() + 8.0, artwork.bottom() + 8.0),
                vec2(width - 16.0, 33.0),
            ))
            .galley(
                pos2(rect.left() + 8.0, artwork.bottom() + 8.0),
                galley,
                TEXT,
            );
        ui.painter().text(
            pos2(rect.left() + 8.0, rect.bottom() - 16.0),
            Align2::LEFT_CENTER,
            item.year.map(|y| y.to_string()).unwrap_or_else(|| {
                if item.content_type == "series" {
                    "Series".into()
                } else {
                    "Movie".into()
                }
            }),
            FontId::proportional(12.0),
            MUTED,
        );
        if response.clicked() {
            self.select_catalog(item.clone());
        }
        if response.double_clicked() {
            self.prepare(item.clone());
        }
        response.context_menu(|ui| {
            if ui.button("Details").clicked() {
                self.open_detail(item.clone());
                ui.close();
            }
            if ui
                .button(if item.is_favorite {
                    "Remove favorite"
                } else {
                    "Add favorite"
                })
                .clicked()
            {
                self.worker.send(Command::Favorite(item.clone()));
                ui.close();
            }
        });
    }
    fn detail_panel(&mut self, ui: &mut Ui) {
        let Some(item) = self.selected_catalog.clone() else {
            ui.add_space(ui.available_height() * 0.35);
            ui.vertical_centered(|ui| {
                ui.label(theme::icon("panelRight").size(36.0).color(ACCENT));
                ui.add_space(14.0);
                ui.label(title("Select an item", 16.0));
                ui.label(
                    RichText::new(
                        "Details and playback controls stay here while the catalog scrolls.",
                    )
                    .color(MUTED),
                );
            });
            return;
        };
        let height = ui.available_height();
        egui::ScrollArea::vertical()
            .id_salt("selected-details")
            .max_height((height - 106.0).max(120.0))
            .show(ui, |ui| {
                let (rect, _) = ui.allocate_exact_size(
                    vec2(
                        ui.available_width(),
                        if item.content_type == "live" {
                            96.0
                        } else {
                            190.0
                        },
                    ),
                    Sense::hover(),
                );
                self.paint_artwork(ui, &item, rect);
                ui.add_space(14.0);
                ui.label(title(&item.title, 20.0));
                ui.add_space(8.0);
                ui.horizontal_wrapped(|ui| {
                    ui.label(
                        RichText::new(item.content_type.to_uppercase())
                            .size(11.0)
                            .color(ACCENT),
                    );
                    if let Some(year) = item.year {
                        ui.label(RichText::new(year.to_string()).color(MUTED));
                    }
                    if let Some(rating) = &item.rating {
                        ui.label(RichText::new(format!("★ {rating}")).color(MUTED));
                    }
                });
                ui.add_space(12.0);
                ui.label(
                    RichText::new(theme::display_text(
                        item.description
                            .as_deref()
                            .unwrap_or("No description available."),
                    ))
                    .size(14.0)
                    .color(MUTED),
                );
                if item.content_type == "series" {
                    ui.add_space(18.0);
                    ui.label(title("Episodes", 16.0));
                    ui.add_space(8.0);
                    let episodes: Vec<_> = self
                        .episodes
                        .iter()
                        .filter(|episode| {
                            episode.provider_id == item.provider_id && episode.series_id == item.id
                        })
                        .cloned()
                        .collect();
                    if episodes.is_empty() {
                        ui.label(RichText::new("Episode details will appear here.").color(MUTED));
                    }
                    for episode in episodes {
                        if ui
                            .add_sized(
                                [ui.available_width(), 42.0],
                                egui::Button::new(theme::display_text(&format!(
                                    "S{:02} E{:02}  {}",
                                    episode.season_number, episode.episode_number, episode.title
                                ))),
                            )
                            .clicked()
                        {
                            self.worker
                                .send(Command::Prepare(PlaybackTarget::episode(&episode)));
                        }
                    }
                }
                if item.content_type == "live" {
                    ui.add_space(18.0);
                    ui.horizontal(|ui| {
                        ui.label(title("Programme guide", 16.0));
                        if icon_button(ui, "refreshCw", "Refresh guide").clicked()
                            && let Some(provider) =
                                self.providers.iter().find(|p| p.id == item.provider_id)
                        {
                            self.worker.send(Command::Epg(provider.clone()));
                        }
                    });
                    let channel = item.epg_channel_id.as_deref().unwrap_or(&item.title);
                    for program in self
                        .guide
                        .iter()
                        .filter(|p| p.provider_id == item.provider_id && p.channel_id == channel)
                        .take(8)
                    {
                        ui.label(
                            RichText::new(theme::display_text(&format!(
                                "{}  {}",
                                chrono::DateTime::from_timestamp_millis(program.start_at)
                                    .unwrap_or_default()
                                    .with_timezone(&chrono::Local)
                                    .format("%H:%M"),
                                program.title
                            )))
                            .color(MUTED),
                        );
                    }
                }
            });
        ui.add_space(12.0);
        if item.content_type != "series" && action(ui, "play", "Play", true).clicked() {
            self.prepare(item.clone());
        }
        ui.horizontal(|ui| {
            if action(
                ui,
                if item.is_favorite { "starOff" } else { "star" },
                if item.is_favorite {
                    "Favorited"
                } else {
                    "Favorite"
                },
                false,
            )
            .clicked()
            {
                self.worker.send(Command::Favorite(item.clone()));
            }
            if item.content_type != "live" && action(ui, "info", "Details", false).clicked() {
                self.open_detail(item.clone());
            }
        });
    }

    pub(super) fn home_ui(&mut self, ui: &mut Ui) {
        if self.providers.is_empty()
            || (self.providers.iter().all(|p| p.last_refresh_at.is_none()) && self.page.total == 0)
        {
            self.onboarding(ui);
            return;
        }
        let hero = self
            .home_selected
            .clone()
            .or_else(|| self.home_continue.first().map(|(item, _)| item.clone()))
            .or_else(|| self.latest_movies.first().cloned())
            .or_else(|| self.latest_series.first().cloned())
            .or_else(|| self.page.items.first().cloned());
        let hero_progress = hero.as_ref().and_then(|item| {
            self.home_continue
                .iter()
                .find(|(candidate, _)| {
                    candidate.id == item.id
                        && candidate.provider_id == item.provider_id
                        && candidate.content_type == item.content_type
                })
                .map(|(_, progress)| progress.clone())
        });

        if let Some(item) = &hero
            && let Some(texture) = item
                .artwork_url
                .as_deref()
                .and_then(|url| self.artwork.texture(ui.ctx(), url))
        {
            let rect = ui.max_rect();
            let aspect = texture.size_vec2().x / texture.size_vec2().y;
            let target = rect.width() / rect.height();
            let uv = if aspect > target {
                let width = target / aspect;
                Rect::from_min_max(
                    pos2((1.0 - width) / 2.0, 0.0),
                    pos2((1.0 + width) / 2.0, 1.0),
                )
            } else {
                let height = aspect / target;
                Rect::from_min_max(
                    pos2(0.0, (1.0 - height) / 2.0),
                    pos2(1.0, (1.0 + height) / 2.0),
                )
            };
            ui.painter().image(texture.id(), rect, uv, Color32::WHITE);
            // Exact two overlay layers from Flutter _HomeBackground.
            let upper = Rect::from_min_max(rect.min, pos2(rect.right(), rect.center().y));
            let lower = Rect::from_min_max(pos2(rect.left(), rect.center().y), rect.max);
            gradient(ui.painter(), upper, dark(0xDD), dark(0xCC), false);
            gradient(ui.painter(), lower, dark(0xCC), dark(0xF2), false);
            gradient(ui.painter(), rect, dark(0xEE), dark(0xAA), true);
        }
        egui::ScrollArea::vertical().id_salt("home-scroll").auto_shrink([false,false]).show(ui,|ui| {
            egui::Frame::new().inner_margin(egui::Margin{left:24,right:24,top:20,bottom:6}).show(ui,|ui| {
                let h=if ui.available_width()<760.0{280.0}else{320.0};
                let (rect,_)=ui.allocate_exact_size(vec2(ui.available_width(),h),Sense::hover());
                ui.painter().rect_filled(rect,8.0,Color32::from_rgba_unmultiplied(17,19,21,0x66));
                let left=Rect::from_min_max(rect.min,pos2(rect.center().x,rect.bottom()));
                let right=Rect::from_min_max(pos2(rect.center().x,rect.top()),rect.max);
                gradient(ui.painter(),left,dark(0xEE),dark(0xAA),true);
                gradient(ui.painter(),right,dark(0xAA),dark(0x33),true);
                gradient(ui.painter(),rect,dark(0),dark(0xDD),false);
                let content=Rect::from_min_max(rect.min+vec2(22.0,22.0),pos2((rect.left()+702.0).min(rect.right()-22.0),rect.bottom()-22.0));
                ui.scope_builder(UiBuilder::new().max_rect(content).layout(Layout::bottom_up(Align::LEFT)),|ui| {
                    ui.horizontal(|ui| {
                        if let Some(item)=&hero {
                            if (hero_progress.is_some()||item.content_type!="series")&&action(ui,"play",if hero_progress.is_some(){"Resume"}else{"Play"},true).clicked(){if let Some(progress)=&hero_progress{self.worker.send(Command::ResumeHistory(progress.clone()));}else{self.prepare(item.clone());}}
                            if action(ui,"info","Details",false).clicked(){self.open_detail(item.clone());}
                        }
                    });
                    ui.add_space(18.0);
                    if let Some(item)=&hero {
                        if let Some(description)=&item.description{ui.add(egui::Label::new(RichText::new(theme::display_text(description)).size(16.0).color(Color32::from_rgb(214,208,198))).wrap().truncate());ui.add_space(12.0);}
                        ui.add(egui::Label::new(RichText::new(theme::display_text(&item.title)).font(theme::black(36.0)).color(TEXT)).wrap());ui.add_space(8.0);
                        ui.label(title(match item.content_type.as_str(){"live"=>"Live TV","series"=>"Series",_=>"Movie"},14.0).color(ACCENT));
                    } else {ui.label(title("Your home screen is waiting",24.0));ui.label(RichText::new("Add a provider or refresh your catalog to fill this screen.").color(MUTED));}
                });
            });
            if self.error.is_some() {egui::Frame::new().inner_margin(egui::Margin{left:24,right:24,top:6,bottom:0}).show(ui,|ui|{self.notices(ui);});}
            let continued=self.home_continue.clone();
            if !continued.is_empty(){ui.add_space(22.0);self.rail_heading(ui,"Continue Watching");egui::ScrollArea::horizontal().id_salt("home-continue").show(ui,|ui|{ui.horizontal_top(|ui|{ui.add_space(24.0);ui.spacing_mut().item_spacing.x=12.0;for (item,progress) in &continued{if self.home_card(ui,item,Some(progress.completion_percentage)).double_clicked(){self.worker.send(Command::ResumeHistory(progress.clone()));}}});});}
            for (name,items) in [("Latest Movies",self.latest_movies.clone()),("Latest Series",self.latest_series.clone()),("Favorites",self.home_favorites.clone())] {
                if items.is_empty(){continue;}ui.add_space(22.0);self.rail_heading(ui,name);
                egui::ScrollArea::horizontal().id_salt(("home-rail",name)).show(ui,|ui|{ui.horizontal_top(|ui|{ui.add_space(24.0);ui.spacing_mut().item_spacing.x=12.0;for item in &items{let response=self.home_card(ui,item,None);if response.double_clicked(){self.prepare(item.clone());}}});});
            }
            ui.add_space(28.0);
        });
    }
    fn rail_heading(&self, ui: &mut Ui, name: &str) {
        ui.horizontal(|ui| {
            ui.add_space(24.0);
            ui.label(RichText::new(name).font(theme::black(22.0)).color(TEXT));
        });
        ui.add_space(12.0);
    }
    fn home_card(
        &mut self,
        ui: &mut Ui,
        item: &CatalogItem,
        progress: Option<f64>,
    ) -> egui::Response {
        let (rect, response) = ui.allocate_exact_size(vec2(148.0, 218.0), Sense::click());
        let artwork = Rect::from_min_size(rect.min, vec2(148.0, 154.0));
        self.paint_artwork(ui, item, artwork);
        let badge =
            Rect::from_center_size(artwork.right_bottom() - vec2(20.5, 20.5), vec2(25.0, 25.0));
        ui.painter().circle_filled(badge.center(), 12.5, ACCENT);
        ui.painter().text(
            badge.center(),
            Align2::CENTER_CENTER,
            glyph("play"),
            FontId::new(13.0, egui::FontFamily::Name("Vela Lucide".into())),
            BG,
        );
        if ui
            .interact(
                badge,
                ui.id().with(("home-play", &item.provider_id, &item.id)),
                Sense::click(),
            )
            .clicked()
        {
            self.prepare(item.clone());
        }

        if response.hovered() {
            ui.painter().rect_stroke(
                artwork,
                8.0,
                Stroke::new(1.0_f32, ACCENT),
                egui::StrokeKind::Inside,
            );
        }
        if let Some(progress) = progress {
            let track = Rect::from_min_size(
                pos2(artwork.left() + 8.0, artwork.bottom() - 8.0),
                vec2(132.0, 3.0),
            );
            ui.painter().rect_filled(track, 2.0, SURFACE_HIGH);
            ui.painter().rect_filled(
                Rect::from_min_size(
                    track.min,
                    vec2(132.0 * progress.clamp(0.0, 1.0) as f32, 3.0),
                ),
                2.0,
                ACCENT,
            );
        }
        let galley = ui.painter().layout(
            theme::display_text(&item.title),
            theme::bold(14.0),
            TEXT,
            148.0,
        );
        ui.painter()
            .with_clip_rect(Rect::from_min_size(
                pos2(rect.left(), artwork.bottom() + 10.0),
                vec2(148.0, 34.0),
            ))
            .galley(pos2(rect.left(), artwork.bottom() + 10.0), galley, TEXT);
        ui.painter().text(
            pos2(rect.left(), rect.bottom() - 8.0),
            Align2::LEFT_BOTTOM,
            item.year.map(|y| y.to_string()).unwrap_or_else(|| {
                match item.content_type.as_str() {
                    "live" => "Live TV",
                    "series" | "episode" => "Series",
                    _ => "Movie",
                }
                .into()
            }),
            FontId::proportional(12.0),
            MUTED,
        );
        if response.clicked() {
            self.home_selected = Some(item.clone());
        }
        response.clone().context_menu(|ui| {
            if ui.button("Details").clicked() {
                self.open_detail(item.clone());
                ui.close();
            }
            if ui.button("Play").clicked() {
                self.prepare(item.clone());
                ui.close();
            }
        });
        response
    }

    fn global_search_ui(&mut self, ui: &mut Ui) {
        let query = crate::worker::global_search_query(&self.query.search)
            .unwrap_or("")
            .to_owned();
        let results = self
            .global_search
            .clone()
            .filter(|results| results.query == query);
        if query.is_empty() {
            self.global_notice(ui,"globe2","Global search","Type after / to search live, movies, series, favorites, and recent items together.");
            return;
        }
        if self.error.is_some() && results.is_none() && !self.loading {
            self.global_notice(
                ui,
                "searchAlert",
                "Search unavailable",
                "The library search could not be loaded.",
            );
            return;
        }
        if self.loading || results.is_none() {
            self.global_notice(
                ui,
                "search",
                "Searching library",
                "Checking live, movies, series, favorites, and recent items.",
            );
            return;
        }
        let results = results.unwrap();
        if results.groups.is_empty() {
            self.global_notice(ui,"searchX","No global results",&format!("No live channels, movies, series, favorites, or recent items match \"{query}\"."));
            return;
        }
        egui::ScrollArea::vertical()
            .id_salt(("global-search-results", self.section.label()))
            .auto_shrink([false, false])
            .show(ui, |ui| {
                egui::Frame::new()
                    .inner_margin(egui::Margin {
                        left: 30,
                        right: 30,
                        top: 4,
                        bottom: 32,
                    })
                    .show(ui, |ui| {
                        for group in results.groups {
                            ui.horizontal(|ui| {
                                ui.label(theme::icon(group.icon).size(18.0).color(ACCENT));
                                ui.label(title(group.title, 14.0));
                                ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                                    ui.label(
                                        RichText::new(group.results.len().to_string())
                                            .size(12.0)
                                            .color(MUTED),
                                    );
                                });
                            });
                            ui.add_space(10.0);
                            let columns =
                                ((ui.available_width() + 10.0) / 340.0).floor().max(1.0) as usize;
                            for row in group.results.chunks(columns) {
                                ui.horizontal_top(|ui| {
                                    ui.spacing_mut().item_spacing.x = 10.0;
                                    for result in row {
                                        self.global_tile(ui, result);
                                    }
                                });
                                ui.add_space(10.0);
                            }
                            ui.add_space(8.0);
                        }
                    });
            });
    }
    fn global_notice(&self, ui: &mut Ui, icon: &str, heading: &str, body: &str) {
        let area = ui.available_rect_before_wrap();
        let size = vec2(420.0_f32.min(area.width() - 32.0), 112.0);
        let rect = Rect::from_center_size(area.center(), size);
        ui.painter().add(
            egui::Frame::new()
                .fill(PANEL)
                .stroke(Stroke::new(1.0_f32, BORDER))
                .corner_radius(8)
                .paint(rect),
        );
        ui.scope_builder(UiBuilder::new().max_rect(rect.shrink(18.0)), |ui| {
            ui.horizontal_top(|ui| {
                ui.label(theme::icon(icon).size(24.0).color(ACCENT));
                ui.add_space(4.0);
                ui.vertical(|ui| {
                    ui.label(title(heading, 14.0));
                    ui.add_space(4.0);
                    ui.label(RichText::new(theme::display_text(body)).color(MUTED));
                });
            });
        });
        ui.advance_cursor_after_rect(area);
    }
    fn global_tile(&mut self, ui: &mut Ui, result: &crate::worker::GlobalSearchResult) {
        let item = &result.item;
        let width = 330.0_f32.min(ui.available_width());
        let (rect, response) = ui.allocate_exact_size(vec2(width, 92.0), Sense::click());
        response.widget_info(|| {
            egui::WidgetInfo::labeled(
                egui::WidgetType::Button,
                true,
                format!(
                    "{} · {}",
                    item.title,
                    match item.content_type.as_str() {
                        "live" => "Live channel",
                        "series" => "Series",
                        _ => "Movie",
                    }
                ),
            )
        });

        ui.painter().rect_filled(
            rect,
            8.0,
            if response.hovered() {
                SURFACE_HIGH
            } else {
                PANEL
            },
        );
        ui.painter().rect_stroke(
            rect,
            8.0,
            Stroke::new(1.0_f32, BORDER),
            egui::StrokeKind::Inside,
        );
        let art = Rect::from_min_size(rect.min + vec2(10.0, 10.0), vec2(62.0, 72.0));
        self.paint_artwork(ui, item, art);
        let x = rect.left() + 84.0;
        let available = (rect.width() - 118.0).max(60.0);
        let text_clip = Rect::from_min_size(pos2(x, rect.top() + 10.0), vec2(available, 64.0));
        let painter = ui.painter().with_clip_rect(text_clip);
        let heading =
            painter.layout_no_wrap(theme::display_text(&item.title), theme::bold(14.0), TEXT);
        painter.galley(pos2(x, rect.top() + 14.0), heading, TEXT);
        let subtitle = item
            .subtitle
            .as_deref()
            .unwrap_or(match item.content_type.as_str() {
                "live" => "Live channel",
                "series" => "Series",
                _ => "Movie",
            });
        let subtitle = painter.layout_no_wrap(
            theme::display_text(subtitle),
            FontId::proportional(12.0),
            MUTED,
        );
        painter.galley(pos2(x, rect.top() + 35.0), subtitle, MUTED);
        let mut badge_x = x;
        for badge in [
            Some(match item.content_type.as_str() {
                "live" => "Live channel",
                "series" => "Series",
                _ => "Movie",
            }),
            item.is_favorite.then_some("Favorite"),
            result.progress.is_some().then_some("Recent"),
        ]
        .into_iter()
        .flatten()
        {
            let text = ui.painter().layout_no_wrap(
                badge.into(),
                theme::bold(10.0),
                Color32::from_rgb(215, 208, 198),
            );
            let badge = Rect::from_min_size(
                pos2(badge_x, rect.top() + 59.0),
                text.size() + vec2(14.0, 6.0),
            );
            if badge.right() > rect.right() - 29.0 {
                break;
            }
            ui.painter()
                .rect_filled(badge, 128u8, Color32::from_rgb(26, 29, 32));
            ui.painter().rect_stroke(
                badge,
                128u8,
                Stroke::new(1.0_f32, OUTLINE),
                egui::StrokeKind::Inside,
            );
            ui.painter().galley(badge.min + vec2(7.0, 3.0), text, TEXT);
            badge_x = badge.right() + 6.0;
        }
        ui.painter().text(
            pos2(rect.right() - 17.0, rect.center().y),
            Align2::CENTER_CENTER,
            glyph(if item.content_type == "live" {
                "play"
            } else {
                "panelTopOpen"
            }),
            FontId::new(18.0, egui::FontFamily::Name("Vela Lucide".into())),
            ACCENT,
        );
        if response.clicked() {
            if item.content_type == "live" {
                self.prepare(item.clone());
            } else {
                self.open_detail(item.clone());
            }
        }
        if let Some(progress) = &result.progress {
            response.context_menu(|ui| {
                if ui
                    .button(if progress.completed {
                        "Play again"
                    } else {
                        "Resume"
                    })
                    .clicked()
                {
                    self.worker.send(Command::ResumeHistory(progress.clone()));
                    ui.close();
                }
            });
        }
    }
    pub(super) fn recent_ui(&mut self, ui: &mut Ui) {
        self.header(ui);
        if crate::worker::global_search_query(&self.query.search).is_some() {
            self.global_search_ui(ui);
            return;
        }
        let body = ui.available_rect_before_wrap();
        let detail = Rect::from_min_size(
            pos2(body.right() - 320.0, body.top()),
            vec2(320.0, body.height()),
        );
        let grid = Rect::from_min_max(
            body.min + vec2(30.0, 0.0),
            pos2(detail.left() - 6.0, body.bottom()),
        );
        let selected_id = egui::Id::new("recent-selected-playback-key");
        let mut selected = ui
            .ctx()
            .data_mut(|data| data.get_temp::<String>(selected_id));
        let search = self.query.search.trim().to_lowercase();
        let mut seen = std::collections::HashSet::new();
        let mut cards = Vec::new();
        for progress in self.history.iter().filter(|p| {
            self.query
                .provider_id
                .as_ref()
                .is_none_or(|id| id == &p.provider_id)
        }) {
            let series = if progress.item_type == "episode" {
                progress.series_id.as_deref()
            } else {
                None
            };
            // Flutter Recent groups episodes by their real provider + series.
            let group = (
                progress.provider_id.clone(),
                progress.item_type.clone(),
                series.unwrap_or(&progress.item_id).to_owned(),
            );
            if !seen.insert(group) {
                continue;
            }
            let resolved = self
                .page
                .items
                .iter()
                .chain(&self.latest_movies)
                .chain(&self.latest_series)
                .chain(&self.home_favorites)
                .find(|item| {
                    item.provider_id == progress.provider_id
                        && if let Some(series) = series {
                            item.content_type == "series" && item.id == series
                        } else {
                            item.content_type == progress.item_type && item.id == progress.item_id
                        }
                })
                .cloned();
            let item = resolved.clone().unwrap_or_else(|| CatalogItem {
                id: progress.item_id.clone(),
                provider_id: progress.provider_id.clone(),
                content_type: progress.item_type.clone(),
                title: progress.title.clone(),
                subtitle: progress.subtitle.clone(),
                artwork_url: progress.artwork_url.clone(),
                duration_seconds: progress.duration_seconds,
                ..Default::default()
            });
            if !search.is_empty()
                && !item.title.to_lowercase().contains(&search)
                && !progress.title.to_lowercase().contains(&search)
            {
                continue;
            }
            cards.push((item, progress.clone(), resolved.is_some()));
        }
        if selected
            .as_ref()
            .is_none_or(|key| !cards.iter().any(|(_, p, _)| recent_identity(p) == *key))
        {
            selected = cards.first().map(|(_, p, _)| recent_identity(p));
        }
        ui.scope_builder(UiBuilder::new().max_rect(grid), |ui| {
            if cards.is_empty() {
                ui.add_space(ui.available_height() * 0.35);
                ui.vertical_centered(|ui| {
                    ui.label(theme::icon("history").size(36.0).color(ACCENT));
                    ui.add_space(14.0);
                    ui.label(title("Nothing watched yet", 20.0));
                    ui.label(
                        RichText::new(
                            "No items match the current section, category, or search filter.",
                        )
                        .color(MUTED),
                    );
                });
                return;
            }
            egui::ScrollArea::vertical()
                .id_salt("recent-catalog-grid")
                .auto_shrink([false, false])
                .show(ui, |ui| {
                    let columns = (ui.available_width() / 174.0).ceil().max(1.0) as usize;
                    let width = (ui.available_width() - 10.0 * columns.saturating_sub(1) as f32)
                        / columns as f32;
                    for row in cards.chunks(columns) {
                        ui.horizontal_top(|ui| {
                            ui.spacing_mut().item_spacing.x = 10.0;
                            for (item, progress, _) in row {
                                let key = recent_identity(progress);
                                let response = self.recent_card(
                                    ui,
                                    item,
                                    progress,
                                    width,
                                    selected.as_deref() == Some(&key),
                                );
                                if response.clicked() {
                                    selected = Some(key);
                                    self.selected_catalog = Some(item.clone());
                                }
                                if response.double_clicked() {
                                    self.worker.send(Command::ResumeHistory(progress.clone()));
                                }
                            }
                        });
                        ui.add_space(10.0);
                    }
                });
        });
        if let Some(key) = &selected {
            ui.ctx()
                .data_mut(|data| data.insert_temp(selected_id, key.clone()));
        }
        ui.painter()
            .rect_filled(detail, 0.0, Color32::from_rgb(17, 19, 21));
        ui.painter().line_segment(
            [detail.left_top(), detail.left_bottom()],
            Stroke::new(1.0_f32, BORDER),
        );
        let selection = selected.as_ref().and_then(|key| {
            cards
                .iter()
                .find(|(_, progress, _)| recent_identity(progress) == *key)
        });
        ui.scope_builder(UiBuilder::new().max_rect(detail.shrink2(vec2(17.0,18.0))),|ui| {
            if let Some((item,progress,resolved))=selection {self.recent_details(ui,item,progress,*resolved);}else{ui.add_space(ui.available_height()*0.35);ui.vertical_centered(|ui|{ui.label(theme::icon("panelRight").size(36.0).color(ACCENT));ui.add_space(14.0);ui.label(title("Select an item",16.0));ui.label(RichText::new("Details and playback controls stay here while the catalog scrolls.").color(MUTED));});}
        });
        ui.advance_cursor_after_rect(body);
    }
    fn recent_card(
        &mut self,
        ui: &mut Ui,
        item: &CatalogItem,
        progress: &PlaybackProgress,
        width: f32,
        selected: bool,
    ) -> egui::Response {
        let height = width / 0.8;
        let (rect, response) = ui.allocate_exact_size(vec2(width, height), Sense::click());
        ui.painter().rect_filled(
            rect,
            8.0,
            if selected {
                Color32::from_rgb(31, 33, 30)
            } else {
                PANEL
            },
        );
        ui.painter().rect_stroke(
            rect,
            8.0,
            Stroke::new(1.0_f32, if selected { ACCENT } else { BORDER }),
            egui::StrokeKind::Inside,
        );
        let artwork = Rect::from_min_max(
            rect.min + vec2(8.0, 8.0),
            pos2(rect.right() - 8.0, rect.bottom() - 60.0),
        );
        self.paint_artwork(ui, item, artwork);
        let badge =
            Rect::from_center_size(artwork.right_bottom() - vec2(20.5, 20.5), vec2(25.0, 25.0));
        ui.painter().circle_filled(badge.center(), 12.5, ACCENT);
        ui.painter().text(
            badge.center(),
            Align2::CENTER_CENTER,
            glyph("play"),
            FontId::new(13.0, egui::FontFamily::Name("Vela Lucide".into())),
            BG,
        );
        if ui
            .interact(
                badge,
                ui.id().with(("home-play", &item.provider_id, &item.id)),
                Sense::click(),
            )
            .clicked()
        {
            self.prepare(item.clone());
        }

        if !progress.completed && progress.completion_percentage > 0.0 {
            let bar = Rect::from_min_size(
                pos2(artwork.left(), artwork.bottom() - 3.0),
                vec2(
                    artwork.width() * progress.completion_percentage.clamp(0.0, 1.0) as f32,
                    3.0,
                ),
            );
            ui.painter().rect_filled(bar, 0.0, ACCENT);
        }
        let galley = ui.painter().layout(
            theme::display_text(&item.title),
            theme::bold(14.0),
            TEXT,
            width - 16.0,
        );
        ui.painter()
            .with_clip_rect(Rect::from_min_size(
                pos2(rect.left() + 8.0, artwork.bottom() + 8.0),
                vec2(width - 16.0, 33.0),
            ))
            .galley(
                pos2(rect.left() + 8.0, artwork.bottom() + 8.0),
                galley,
                TEXT,
            );
        ui.painter().text(
            pos2(rect.left() + 8.0, rect.bottom() - 16.0),
            Align2::LEFT_CENTER,
            if progress.completed {
                "Watched".into()
            } else {
                format!("Resume · {}", time_label(progress.position_seconds as f64))
            },
            FontId::proportional(12.0),
            MUTED,
        );
        response
    }
    fn recent_details(
        &mut self,
        ui: &mut Ui,
        item: &CatalogItem,
        progress: &PlaybackProgress,
        resolved: bool,
    ) {
        let height = ui.available_height();
        egui::ScrollArea::vertical()
            .id_salt("recent-selected-details")
            .max_height((height - 112.0).max(120.0))
            .show(ui, |ui| {
                let (rect, _) = ui.allocate_exact_size(
                    vec2(
                        ui.available_width(),
                        if progress.item_type == "live" {
                            96.0
                        } else {
                            190.0
                        },
                    ),
                    Sense::hover(),
                );
                self.paint_artwork(ui, item, rect);
                ui.add_space(14.0);
                ui.label(title(&item.title, 20.0));
                ui.add_space(8.0);
                ui.label(
                    RichText::new(match progress.item_type.as_str() {
                        "live" => "Live TV",
                        "episode" => "Series",
                        _ => "Movie",
                    })
                    .color(ACCENT),
                );
                if let Some(subtitle) = &progress.subtitle {
                    ui.add_space(8.0);
                    ui.label(RichText::new(theme::display_text(subtitle)).color(MUTED));
                }
                ui.add_space(12.0);
                ui.label(
                    RichText::new(theme::display_text(
                        item.description
                            .as_deref()
                            .unwrap_or("No description available."),
                    ))
                    .color(MUTED),
                );
                ui.add_space(12.0);
                ui.label(
                    RichText::new(if progress.completed {
                        "Watched".into()
                    } else {
                        format!(
                            "Continue from {}",
                            time_label(progress.position_seconds as f64)
                        )
                    })
                    .color(MUTED),
                );
            });
        ui.add_space(12.0);
        if action(
            ui,
            "play",
            if progress.completed {
                "Play again"
            } else {
                "Resume"
            },
            true,
        )
        .clicked()
        {
            self.worker.send(Command::ResumeHistory(progress.clone()));
        }
        if resolved && item.content_type != "episode" {
            ui.horizontal(|ui| {
                if action(
                    ui,
                    "star",
                    if item.is_favorite {
                        "Favorited"
                    } else {
                        "Favorite"
                    },
                    false,
                )
                .clicked()
                {
                    self.worker.send(Command::Favorite(item.clone()));
                }
                if item.content_type != "live" && action(ui, "info", "Details", false).clicked() {
                    self.open_detail(item.clone());
                }
            });
        }
    }
    pub(super) fn guide_ui(&mut self, ui: &mut Ui) {
        ui.horizontal(|ui| {
            if icon_button(ui, "chevronLeft", "Previous day").clicked() {
                self.guide_day -= 1;
                self.request_guide();
            }
            ui.label(title(
                (chrono::Local::now() + chrono::Duration::days(self.guide_day))
                    .format("%a, %d %b")
                    .to_string(),
                14.0,
            ));
            if icon_button(ui, "chevronRight", "Next day").clicked() {
                self.guide_day += 1;
                self.request_guide();
            }
            if icon_button(ui, "refreshCw", "Refresh guide").clicked()
                && let Some(provider) = self
                    .providers
                    .iter()
                    .find(|p| Some(&p.id) == self.query.provider_id.as_ref())
                    .or_else(|| self.providers.first())
            {
                self.worker.send(Command::Epg(provider.clone()));
            }
        });
        ui.add_space(12.0);
        let items = self.page.items.clone();
        let programs = self.guide.clone();
        egui::ScrollArea::both()
            .id_salt("live-guide")
            .auto_shrink([false, false])
            .show(ui, |ui| {
                for item in &items {
                    egui::Frame::new()
                        .fill(PANEL)
                        .stroke(Stroke::new(1.0_f32, BORDER))
                        .inner_margin(10.0)
                        .show(ui, |ui| {
                            ui.horizontal(|ui| {
                                if ui
                                    .add_sized(
                                        [150.0, 50.0],
                                        egui::Button::new(theme::display_text(&item.title))
                                            .frame(false),
                                    )
                                    .clicked()
                                {
                                    self.select_catalog(item.clone());
                                }
                                let channel = item.epg_channel_id.as_deref().unwrap_or(&item.title);
                                let matching = programs
                                    .iter()
                                    .filter(|p| {
                                        p.provider_id == item.provider_id && p.channel_id == channel
                                    })
                                    .collect::<Vec<_>>();
                                if matching.is_empty() {
                                    ui.label(
                                        RichText::new("No programme information available")
                                            .color(MUTED),
                                    );
                                }
                                for program in matching {
                                    egui::Frame::new()
                                        .fill(SURFACE_HIGH)
                                        .corner_radius(6)
                                        .inner_margin(8.0)
                                        .show(ui, |ui| {
                                            ui.set_width(165.0);
                                            ui.label(
                                                RichText::new(
                                                    chrono::DateTime::from_timestamp_millis(
                                                        program.start_at,
                                                    )
                                                    .unwrap_or_default()
                                                    .with_timezone(&chrono::Local)
                                                    .format("%H:%M")
                                                    .to_string(),
                                                )
                                                .size(11.0)
                                                .color(ACCENT),
                                            );
                                            ui.label(theme::display_text(&program.title));
                                        });
                                }
                            });
                        });
                    ui.add_space(4.0);
                }
            });
    }
    pub(super) fn settings_ui(&mut self, ui: &mut Ui) {
        egui::Frame::new()
            .inner_margin(egui::Margin {
                left: 30,
                right: 30,
                top: 26,
                bottom: 30,
            })
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.vertical(|ui| {
                        ui.label(title("Preferences", 11.0).color(ACCENT));
                        ui.add_space(6.0);
                        ui.label(title("Settings", 28.0));
                    });
                    ui.with_layout(Layout::right_to_left(Align::BOTTOM), |ui| {
                        ui.label(
                            RichText::new(format!("Vela {}", env!("CARGO_PKG_VERSION")))
                                .size(12.0)
                                .color(MUTED),
                        );
                        for (key, label, values) in [
                            ("default_subtitles", "Subtitles", ["Off", "Auto", "English"]),
                            ("default_audio", "Audio", ["Auto", "Original", "English"]),
                        ] {
                            let mut current = self
                                .settings
                                .get(key)
                                .cloned()
                                .unwrap_or_else(|| values[0].to_owned());
                            let previous = current.clone();
                            egui::ComboBox::from_id_salt(key)
                                .selected_text(format!("{label}: {current}"))
                                .show_ui(ui, |ui| {
                                    for option in values {
                                        ui.selectable_value(
                                            &mut current,
                                            option.to_owned(),
                                            option,
                                        );
                                    }
                                });
                            if current != previous {
                                self.settings.insert(key.into(), current.clone());
                                self.worker.send(Command::Setting(key.into(), current));
                            }
                        }
                    });
                });
                ui.add_space(16.0);
                self.update_card(ui);
                ui.add_space(18.0);
                self.notices(ui);
                let body = ui.available_rect_before_wrap();
                let left_width = 390.0_f32.min((body.width() * 0.44).max(280.0));
                let left = Rect::from_min_size(body.min, vec2(left_width, body.height()));
                let right = Rect::from_min_max(pos2(left.right() + 18.0, body.top()), body.max);
                if self.settings_selected_provider.is_none() && !self.settings_adding_provider {
                    self.settings_selected_provider = self.providers.first().map(|p| p.id.clone());
                }
                ui.scope_builder(UiBuilder::new().max_rect(left), |ui| {
                    egui::Frame::new()
                        .fill(PANEL)
                        .stroke(Stroke::new(1.0_f32, BORDER))
                        .corner_radius(8)
                        .inner_margin(14.0)
                        .show(ui, |ui| {
                            ui.set_width(left.width() - 28.0);
                            ui.horizontal(|ui| {
                                ui.label(theme::icon("server").color(ACCENT));
                                ui.label(title("Providers", 16.0));
                                ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                                    if icon_button(ui, "plus", "Add provider").clicked() {
                                        self.settings_adding_provider = true;
                                        self.settings_selected_provider = None;
                                        self.provider_form = Some(new_provider());
                                    }
                                });
                            });
                            ui.add_space(10.0);
                            if self.providers.is_empty() {
                                ui.label(
                                    RichText::new("Add your first provider to get started.")
                                        .color(MUTED),
                                );
                            }
                            let providers = self.providers.clone();
                            for provider in &providers {
                                let selected = self.settings_selected_provider.as_deref()
                                    == Some(&provider.id)
                                    && !self.settings_adding_provider;
                                let response = egui::Frame::new()
                                    .fill(if selected {
                                        Color32::from_rgb(37, 33, 26)
                                    } else {
                                        PANEL
                                    })
                                    .corner_radius(8)
                                    .stroke(Stroke::new(
                                        1.0_f32,
                                        if selected { ACCENT } else { BORDER },
                                    ))
                                    .inner_margin(12.0)
                                    .show(ui, |ui| {
                                        ui.set_width((left.width() - 54.0).max(160.0));
                                        ui.horizontal(|ui| {
                                            ui.label(
                                                theme::icon(if provider.kind == "xtream" {
                                                    "server"
                                                } else {
                                                    "listVideo"
                                                })
                                                .size(18.0)
                                                .color(ACCENT),
                                            );
                                            ui.vertical(|ui| {
                                                ui.label(title(&provider.name, 14.0));
                                                ui.label(
                                                    RichText::new(format!(
                                                        "{} · {}",
                                                        if provider.kind == "xtream" {
                                                            "Xtream Codes"
                                                        } else {
                                                            "M3U"
                                                        },
                                                        if provider.is_enabled {
                                                            "Enabled"
                                                        } else {
                                                            "Disabled"
                                                        }
                                                    ))
                                                    .size(12.0)
                                                    .color(MUTED),
                                                );
                                            });
                                        });
                                    })
                                    .response
                                    .interact(Sense::click());
                                if response.clicked() {
                                    self.settings_selected_provider = Some(provider.id.clone());
                                    self.settings_adding_provider = false;
                                    self.provider_form = Some(provider.clone());
                                }
                                ui.add_space(8.0);
                            }
                        });
                });
                ui.scope_builder(UiBuilder::new().max_rect(right), |ui| {
                    egui::ScrollArea::vertical()
                        .id_salt("settings-panels")
                        .auto_shrink([false, false])
                        .show(ui, |ui| {
                            let adding = self.settings_adding_provider || self.providers.is_empty();
                            if self.provider_form.is_none()
                                || (!adding
                                    && self.provider_form.as_ref().is_some_and(|form| {
                                        Some(&form.id) != self.settings_selected_provider.as_ref()
                                    }))
                            {
                                self.provider_form = if adding {
                                    Some(new_provider())
                                } else {
                                    self.providers
                                        .iter()
                                        .find(|p| {
                                            Some(&p.id) == self.settings_selected_provider.as_ref()
                                        })
                                        .cloned()
                                };
                            }
                            self.provider_card(ui, adding, true);
                            ui.add_space(14.0);
                            self.data_operations(ui);
                        });
                });
                ui.advance_cursor_after_rect(body);
            });
    }
    fn update_card(&mut self, ui: &mut Ui) {
        let status = self.update_status.clone();
        let error = self.update_error.clone();
        let checking = self.checking_update;
        let has_update = status.as_ref().is_some_and(|status| status.has_update);
        let (icon, heading, message, color) = if checking {
            (
                "loaderCircle",
                "Checking for updates",
                "Looking at the latest Vela release on GitHub.".to_owned(),
                ACCENT,
            )
        } else if let Some(error) = error {
            ("cloudOff", "Update check unavailable", error, ACCENT)
        } else if let Some(status) = &status {
            if status.has_update {
                (
                    "sparkles",
                    "Update available",
                    format!(
                        "Vela {} is available. Download and install it manually from GitHub.",
                        status.latest_version
                    ),
                    ACCENT,
                )
            } else {
                (
                    "checkCircle2",
                    "Up to date",
                    format!(
                        "Installed {} · Latest release {}.",
                        status.current_version, status.latest_version
                    ),
                    Color32::from_rgb(143, 183, 176),
                )
            }
        } else {
            (
                "cloudOff",
                "Update check unavailable",
                "Check for the latest Vela release on GitHub.".to_owned(),
                ACCENT,
            )
        };
        egui::Frame::new()
            .fill(PANEL)
            .stroke(Stroke::new(1.0_f32, BORDER))
            .corner_radius(8)
            .inner_margin(egui::Margin {
                left: 16,
                right: 14,
                top: 14,
                bottom: 14,
            })
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.label(theme::icon(icon).size(24.0).color(color));
                    ui.add_space(4.0);
                    let trailing = if checking {
                        36.0
                    } else if has_update || self.update_error.is_some() {
                        180.0
                    } else {
                        44.0
                    };
                    ui.allocate_ui_with_layout(
                        vec2((ui.available_width() - trailing - 16.0).max(180.0), 42.0),
                        Layout::top_down(Align::LEFT),
                        |ui| {
                            ui.spacing_mut().item_spacing.y = 3.0;
                            ui.label(title(heading, 14.0));
                            ui.label(RichText::new(message).size(12.0).color(MUTED));
                        },
                    );
                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        if checking {
                            ui.spinner();
                        } else {
                            if self.update_error.is_some() {
                                if action(ui, "externalLink", "Releases", false).clicked() {
                                    let _ = open::that("https://github.com/Fouadktb/vela/releases");
                                }
                            } else if let Some(status) = &status
                                && status.has_update
                                && action(ui, "download", "Download", true).clicked()
                            {
                                let _ = open::that(&status.release_url);
                            }
                            if icon_button(ui, "refreshCw", "Check again").clicked() {
                                self.checking_update = true;
                                self.update_error = None;
                                self.worker.send(Command::CheckUpdates);
                            }
                        }
                    });
                });
            });
    }
    fn data_operations(&mut self, ui: &mut Ui) {
        egui::Frame::new()
            .fill(PANEL)
            .stroke(Stroke::new(1.0_f32, BORDER))
            .corner_radius(8)
            .inner_margin(16.0)
            .show(ui, |ui| {
                ui.horizontal(|ui| {
                    ui.label(theme::icon("database").color(ACCENT));
                    ui.label(title("Data & diagnostics", 16.0));
                });
                ui.add_space(12.0);
                ui.horizontal_wrapped(|ui| {
                    if action(ui, "fileText", "Export diagnostics", false).clicked()
                        && let Some(path) = rfd::FileDialog::new()
                            .set_file_name("vela-diagnostics.txt")
                            .save_file()
                    {
                        self.worker.send(Command::Diagnostics(path));
                    }
                    if action(ui, "archive", "Export backup", false).clicked()
                        && let Some(path) = rfd::FileDialog::new()
                            .set_file_name("vela-backup.sqlite")
                            .save_file()
                    {
                        self.worker.send(Command::Backup(path));
                    }
                    if action(ui, "history", "Clear history", false).clicked() {
                        self.confirm_clear_history = true;
                    }
                    if action(ui, "databaseZap", "Clear catalog cache", false).clicked() {
                        self.confirm_clear_cache = true;
                    }
                    if action(ui, "trash2", "Reset app data", true).clicked() {
                        self.confirm_reset_data = true;
                    }
                });
                ui.add_space(12.0);
                ui.label(
                    RichText::new(
                        "Backups include private provider credentials. Keep them private.",
                    )
                    .size(12.0)
                    .color(MUTED),
                );
            });
    }
    fn onboarding(&mut self, ui: &mut Ui) {
        if self.provider_form.is_none() {
            self.provider_form = Some(new_provider());
        }
        egui::ScrollArea::vertical()
            .id_salt("provider-onboarding")
            .auto_shrink([false, false])
            .show(ui, |ui| {
                ui.add_space(((ui.available_height() - 376.0) / 2.0).max(24.0));
                ui.horizontal(|ui| {
                    let width = 640.0_f32.min(ui.available_width() - 48.0);
                    ui.add_space(((ui.available_width() - width) / 2.0).max(16.0));
                    ui.allocate_ui_with_layout(
                        vec2(width, 376.0),
                        Layout::top_down(Align::LEFT),
                        |ui| {
                            self.provider_card(ui, true, false);
                        },
                    );
                });
            });
    }
    fn provider_card(&mut self, ui: &mut Ui, adding: bool, embedded: bool) {
        if adding {
            self.add_provider_card(ui, embedded);
            return;
        }
        let Some(mut form) = self.provider_form.clone() else {
            return;
        };
        let mut save = false;
        let mut refresh = false;
        let mut save_and_refresh = false;
        let width = if embedded {
            ui.available_width()
        } else {
            ui.available_width().min(640.0)
        };
        egui::Frame::new()
            .fill(PANEL)
            .stroke(Stroke::new(1.0_f32, BORDER))
            .corner_radius(8)
            .inner_margin(if embedded { 18.0 } else { 22.0 })
            .show(ui, |ui| {
                ui.set_width((width - if embedded { 36.0 } else { 44.0 }).max(200.0));
                ui.horizontal(|ui| {
                    ui.label(
                        theme::icon(if adding {
                            "server"
                        } else {
                            "slidersHorizontal"
                        })
                        .color(ACCENT),
                    );
                    ui.label(title(
                        if adding {
                            "Add Provider"
                        } else {
                            "Provider settings"
                        },
                        if adding { 24.0 } else { 20.0 },
                    ));
                });
                ui.add_space(20.0);
                ui.horizontal(|ui| {
                    ui.spacing_mut().item_spacing.x = 0.0;
                    for (label, kind, source_kind, icon) in [
                        ("Xtream Codes", "xtream", "url", "server"),
                        ("M3U URL", "m3u", "url", "link"),
                        ("Local File", "m3u", "file", "fileVideo"),
                    ] {
                        let selected = form.kind == kind
                            && (kind == "xtream"
                                || form.source_kind.as_deref() == Some(source_kind));
                        if ui
                            .add_sized(
                                [(width - 48.0) / 3.0, 32.0],
                                egui::Button::selectable(
                                    selected,
                                    icon_label(icon, label, if selected { ACCENT } else { TEXT }),
                                ),
                            )
                            .clicked()
                        {
                            form.kind = kind.into();
                            form.source_kind = Some(source_kind.into());
                        }
                    }
                });
                ui.add_space(16.0);
                field(ui, "tag", "Provider name", &mut form.name, false);
                ui.add_space(12.0);
                if form.kind == "xtream" {
                    field(ui, "server", "Server URL", &mut form.source, false);
                    ui.add_space(12.0);
                    ui.horizontal(|ui| {
                        let half = (ui.available_width() - 12.0) / 2.0;
                        ui.allocate_ui_with_layout(
                            vec2(half, 48.0),
                            Layout::top_down(Align::LEFT),
                            |ui| {
                                field(
                                    ui,
                                    "user",
                                    "Username",
                                    form.username.get_or_insert_with(String::new),
                                    false,
                                )
                            },
                        );
                        ui.allocate_ui_with_layout(
                            vec2(half, 48.0),
                            Layout::top_down(Align::LEFT),
                            |ui| {
                                field(
                                    ui,
                                    "keyRound",
                                    "Password",
                                    form.password.get_or_insert_with(String::new),
                                    !self.provider_password_visible,
                                )
                            },
                        );
                    });
                } else if form.source_kind.as_deref() == Some("file") {
                    ui.horizontal(|ui| {
                        let w = (ui.available_width() - 110.0).max(160.0);
                        ui.allocate_ui_with_layout(
                            vec2(w, 48.0),
                            Layout::top_down(Align::LEFT),
                            |ui| field(ui, "fileVideo", "Local M3U file", &mut form.source, false),
                        );
                        if action(ui, "folderOpen", "Choose", true).clicked()
                            && let Some(path) = rfd::FileDialog::new()
                                .add_filter("M3U playlist", &["m3u", "m3u8"])
                                .pick_file()
                        {
                            form.source = path.display().to_string();
                        }
                    });
                } else {
                    field(ui, "link", "M3U URL", &mut form.source, false);
                }
                if !adding {
                    ui.add_space(16.0);
                    ui.checkbox(&mut form.is_enabled, "Enabled");
                    ui.checkbox(&mut form.auto_refresh_enabled, "Auto refresh");
                    let mut interval = form.auto_refresh_interval_minutes;
                    egui::ComboBox::from_id_salt("refresh-interval")
                        .selected_text(format!(
                            "Refresh every {}",
                            if interval % 1440 == 0 {
                                format!("{} day(s)", interval / 1440)
                            } else {
                                format!("{interval} minutes")
                            }
                        ))
                        .show_ui(ui, |ui| {
                            for (minutes, label) in [
                                (15, "15 minutes"),
                                (30, "30 minutes"),
                                (60, "1 hour"),
                                (180, "3 hours"),
                                (360, "6 hours"),
                                (720, "12 hours"),
                                (1440, "24 hours"),
                                (2880, "2 days"),
                                (4320, "3 days"),
                                (10080, "7 days"),
                            ] {
                                ui.selectable_value(&mut interval, minutes, label);
                            }
                        });
                    form.auto_refresh_interval_minutes = interval;
                }
                ui.add_space(16.0);
                if self.importing {
                    ui.horizontal(|ui| {
                        ui.spinner();
                        ui.label(RichText::new("Importing your provider…").color(ACCENT));
                    });
                }
                self.notices(ui);
                let valid = !form.name.trim().is_empty()
                    && !form.source.trim().is_empty()
                    && (form.kind != "xtream"
                        || (form
                            .username
                            .as_deref()
                            .is_some_and(|s| !s.trim().is_empty())
                            && form
                                .password
                                .as_deref()
                                .is_some_and(|s| !s.trim().is_empty())));
                // Match the existing provider action wrap so the additional
                // actions remain usable in a narrow settings pane.
                ui.horizontal_wrapped(|ui| {
                    if ui
                        .add_enabled(
                            valid && !self.importing,
                            egui::Button::new(
                                RichText::new(if adding {
                                    "Save and Import"
                                } else {
                                    "Save changes"
                                })
                                .font(theme::bold(14.0))
                                .color(BG),
                            )
                            .fill(ACCENT)
                            .min_size(vec2(150.0, 40.0)),
                        )
                        .clicked()
                    {
                        save = true;
                    }
                    if !adding {
                        if action_enabled(
                            ui,
                            "refreshCw",
                            "Save and refresh",
                            false,
                            valid && !self.importing,
                        )
                        .clicked()
                        {
                            save = true;
                            save_and_refresh = true;
                        }
                        if action_enabled(ui, "refreshCw", "Refresh", false, !self.importing)
                            .clicked()
                        {
                            refresh = true;
                        }
                        if action_enabled(ui, "history", "Clear recent", false, !self.importing)
                            .clicked()
                        {
                            self.confirm_clear_provider_history = Some(form.id.clone());
                        }
                        if icon_button(ui, "trash2", "Remove provider").clicked() {
                            self.delete_provider = Some(form.clone());
                        }
                    }
                });
            });
        if save {
            persist_provider_changes(&self.worker, &form, adding || save_and_refresh);
            if adding {
                self.settings_selected_provider = Some(form.id.clone());
                self.settings_adding_provider = false;
            }
            self.provider_password_visible = false;
        }
        if refresh {
            self.worker.send(Command::Refresh(form.clone()));
        }
        self.provider_form = Some(form);
    }
    fn add_provider_card(&mut self, ui: &mut Ui, embedded: bool) {
        let Some(mut form) = self.provider_form.clone() else {
            return;
        };
        let width = if embedded {
            ui.available_width()
        } else {
            ui.available_width().min(640.0)
        };
        let extra = if self.error.is_some() || self.importing {
            58.0
        } else {
            0.0
        };
        let (rect, _) = ui.allocate_exact_size(vec2(width, 376.0 + extra), Sense::hover());
        ui.painter().rect_filled(rect, 8.0, PANEL);
        ui.painter().rect_stroke(
            rect,
            8.0,
            Stroke::new(1.0_f32, BORDER),
            egui::StrokeKind::Inside,
        );
        let inner = rect.shrink(22.0);
        ui.scope_builder(
            UiBuilder::new()
                .max_rect(Rect::from_min_size(inner.min, vec2(inner.width(), 28.0)))
                .layout(Layout::left_to_right(Align::Center)),
            |ui| {
                ui.label(theme::icon("radioTower").size(24.0).color(ACCENT));
                ui.add_space(4.0);
                ui.label(
                    RichText::new("Add Provider")
                        .font(theme::black(24.0))
                        .color(TEXT),
                );
            },
        );
        let segment_rect = Rect::from_min_size(
            pos2(inner.left(), rect.top() + 66.0),
            vec2(inner.width(), 32.0),
        );
        ui.painter().rect_stroke(
            segment_rect,
            16.0,
            Stroke::new(1.0_f32, OUTLINE),
            egui::StrokeKind::Inside,
        );
        let segment_width = segment_rect.width() / 3.0;
        for (index, (label, kind, source_kind, icon)) in [
            ("Xtream Codes", "xtream", "url", "server"),
            ("M3U URL", "m3u", "url", "link"),
            ("Local File", "m3u", "file", "fileVideo"),
        ]
        .into_iter()
        .enumerate()
        {
            let slot = Rect::from_min_size(
                segment_rect.min + vec2(segment_width * index as f32, 0.0),
                vec2(segment_width, 32.0),
            );
            let selected = form.kind == kind
                && (kind == "xtream" || form.source_kind.as_deref() == Some(source_kind));
            let response =
                ui.interact(slot, ui.id().with(("provider-type", index)), Sense::click());
            if selected {
                let rounding = egui::CornerRadius {
                    nw: if index == 0 { 16 } else { 0 },
                    sw: if index == 0 { 16 } else { 0 },
                    ne: if index == 2 { 16 } else { 0 },
                    se: if index == 2 { 16 } else { 0 },
                };
                ui.painter()
                    .rect_filled(slot.shrink(1.0), rounding, Color32::from_rgb(65, 52, 29));
            }
            if index > 0 {
                ui.painter()
                    .vline(slot.left(), slot.y_range(), Stroke::new(1.0_f32, OUTLINE));
            }
            let text = icon_label(
                if selected { "check" } else { icon },
                label,
                if selected { ACCENT } else { TEXT },
            );
            let galley = ui.fonts_mut(|fonts| fonts.layout_job(text));
            ui.painter().galley(
                slot.center() - galley.size() / 2.0,
                galley,
                if selected { ACCENT } else { TEXT },
            );
            if response.clicked() {
                form.kind = kind.into();
                form.source_kind = Some(source_kind.into());
            }
        }
        let row = |y: f32| {
            Rect::from_min_size(
                pos2(inner.left(), rect.top() + y),
                vec2(inner.width(), 44.0),
            )
        };
        provider_field(
            ui,
            row(110.0),
            "tag",
            "Provider name",
            &mut form.name,
            false,
        );
        if form.kind == "xtream" {
            provider_field(
                ui,
                row(170.0),
                "server",
                "Server URL",
                &mut form.source,
                false,
            );
            let half = (inner.width() - 12.0) / 2.0;
            provider_field(
                ui,
                Rect::from_min_size(pos2(inner.left(), rect.top() + 230.0), vec2(half, 44.0)),
                "user",
                "Username",
                form.username.get_or_insert_with(String::new),
                false,
            );
            provider_field(
                ui,
                Rect::from_min_size(
                    pos2(inner.left() + half + 12.0, rect.top() + 230.0),
                    vec2(half, 44.0),
                ),
                "keyRound",
                "Password",
                form.password.get_or_insert_with(String::new),
                true,
            );
        } else if form.source_kind.as_deref() == Some("file") {
            let file_rect = Rect::from_min_size(row(170.0).min, vec2(inner.width() - 112.0, 44.0));
            provider_field(
                ui,
                file_rect,
                "fileVideo",
                "Local M3U file",
                &mut form.source,
                false,
            );
            ui.scope_builder(
                UiBuilder::new().max_rect(Rect::from_min_size(
                    pos2(file_rect.right() + 12.0, file_rect.top()),
                    vec2(100.0, 40.0),
                )),
                |ui| {
                    if action(ui, "folderOpen", "Choose", true).clicked()
                        && let Some(path) = rfd::FileDialog::new()
                            .add_filter("M3U playlist", &["m3u", "m3u8"])
                            .pick_file()
                    {
                        form.source = path.display().to_string();
                    }
                },
            );
        } else {
            provider_field(ui, row(170.0), "link", "M3U URL", &mut form.source, false);
        }
        if extra > 0.0 {
            let status = Rect::from_min_size(
                pos2(inner.left(), rect.top() + 284.0),
                vec2(inner.width(), 52.0),
            );
            ui.scope_builder(UiBuilder::new().max_rect(status), |ui| {
                if self.importing {
                    ui.horizontal(|ui| {
                        ui.spinner();
                        ui.label(RichText::new("Importing your provider…").color(ACCENT));
                    });
                } else if let Some(error) = &self.error {
                    ui.label(
                        RichText::new(error)
                            .size(12.0)
                            .color(Color32::from_rgb(226, 109, 90)),
                    );
                }
            });
        }
        let button_rect = Rect::from_min_size(
            pos2(inner.right() - 180.0, rect.bottom() - 54.0),
            vec2(180.0, 32.0),
        );
        let mut save = false;
        ui.scope_builder(UiBuilder::new().max_rect(button_rect), |ui| {
            ui.spacing_mut().button_padding = vec2(12.0, 5.0);
            ui.spacing_mut().interact_size.y = 32.0;
            save = ui
                .add_enabled(
                    !self.importing,
                    egui::Button::new(icon_label(
                        "download",
                        if self.importing {
                            "Importing"
                        } else {
                            "Save and Import"
                        },
                        BG,
                    ))
                    .fill(ACCENT)
                    .corner_radius(8)
                    .min_size(vec2(180.0, 32.0)),
                )
                .clicked();
        });
        if save {
            let error = if form.name.trim().is_empty() {
                Some("Enter a provider name.")
            } else if form.source.trim().is_empty() {
                Some(if form.kind == "xtream" {
                    "Enter the server URL."
                } else {
                    "Choose a playlist file or enter its URL."
                })
            } else if form.kind == "xtream"
                && form.username.as_deref().is_none_or(|s| s.trim().is_empty())
            {
                Some("Enter your username.")
            } else if form.kind == "xtream"
                && form.password.as_deref().is_none_or(|s| s.trim().is_empty())
            {
                Some("Enter your password.")
            } else {
                None
            };
            if let Some(error) = error {
                self.error = Some(error.into());
            } else {
                self.error = None;
                self.worker.send(Command::SaveProvider(form.clone()));
                self.worker.send(Command::Refresh(form.clone()));
                self.settings_selected_provider = Some(form.id.clone());
                self.settings_adding_provider = false;
                self.provider_password_visible = false;
            }
        }
        self.provider_form = Some(form);
    }
    pub(super) fn provider_dialog(&mut self, _ctx: &egui::Context) {}

    pub(super) fn detail_dialog(&mut self, ctx: &egui::Context) {
        let Some(item) = self.details.clone() else {
            return;
        };
        let season_key = egui::Id::new(("detail-season", &item.provider_id, &item.id));
        if ctx.input(|input| input.key_pressed(egui::Key::Escape))
            && !ctx.wants_keyboard_input()
            && !egui::Popup::is_any_open(ctx)
        {
            self.close_detail();
            ctx.data_mut(|data| data.remove::<i64>(season_key));
            return;
        }
        let screen = ctx.content_rect();
        egui::Area::new(egui::Id::new("content-detail-screen"))
            .order(egui::Order::Foreground)
            .fixed_pos(screen.min)
            .show(ctx, |ui| {
                egui::Frame::new()
                    .fill(BG)
                    .inner_margin(0.0)
                    .show(ui, |ui| {
                        ui.set_min_size(screen.size());
                        ui.set_max_size(screen.size());
                        egui::Frame::new()
                            .inner_margin(egui::Margin {
                                left: 26,
                                right: 26,
                                top: 20,
                                bottom: 10,
                            })
                            .show(ui, |ui| {
                                ui.horizontal(|ui| {
                                    if icon_button(ui, "arrowLeft", "Back").clicked() {
                                        self.close_detail();
                                        ctx.data_mut(|data| data.remove::<i64>(season_key));
                                    }
                                    ui.add_space(2.0);
                                    ui.allocate_ui_with_layout(
                                        vec2((ui.available_width() - 56.0).max(180.0), 48.0),
                                        Layout::top_down(Align::LEFT),
                                        |ui| {
                                            ui.spacing_mut().item_spacing.y = 2.0;
                                            ui.label(
                                                RichText::new(detail_type_label(&item))
                                                    .font(theme::black(11.0))
                                                    .color(ACCENT),
                                            );
                                            ui.add(
                                                egui::Label::new(
                                                    RichText::new(theme::display_text(&item.title))
                                                        .font(theme::black(22.0))
                                                        .color(TEXT),
                                                )
                                                .truncate(),
                                            );
                                        },
                                    );
                                    let favorite_response = icon_button(
                                        ui,
                                        "star",
                                        if item.is_favorite {
                                            "Remove favorite"
                                        } else {
                                            "Add favorite"
                                        },
                                    );
                                    if item.is_favorite {
                                        ui.painter().text(
                                            favorite_response.rect.center(),
                                            Align2::CENTER_CENTER,
                                            glyph("star"),
                                            FontId::new(
                                                18.0,
                                                egui::FontFamily::Name("Vela Lucide".into()),
                                            ),
                                            ACCENT,
                                        );
                                    }
                                    if favorite_response.clicked() {
                                        self.worker.send(Command::Favorite(item.clone()));
                                        if let Some(current) = &mut self.details {
                                            current.is_favorite = !current.is_favorite;
                                        }
                                        if let Some(current) = &mut self.selected_catalog
                                            && current.provider_id == item.provider_id
                                            && current.content_type == item.content_type
                                            && current.id == item.id
                                        {
                                            current.is_favorite = !current.is_favorite;
                                        }
                                    }
                                });
                            });
                        let wide = screen.width() >= 980.0;
                        let padding = if wide {
                            egui::Margin {
                                left: 40,
                                right: 42,
                                top: 18,
                                bottom: 42,
                            }
                        } else {
                            egui::Margin {
                                left: 28,
                                right: 28,
                                top: 10,
                                bottom: 34,
                            }
                        };
                        egui::ScrollArea::vertical()
                            .id_salt(("detail-page", &item.provider_id, &item.id))
                            .auto_shrink([false, false])
                            .show(ui, |ui| {
                                egui::Frame::new().inner_margin(padding).show(ui, |ui| {
                                    if wide {
                                        let width = ui.available_width();
                                        ui.horizontal_top(|ui| {
                                            ui.spacing_mut().item_spacing.x = 34.0;
                                            ui.allocate_ui_with_layout(
                                                vec2(320.0, 1.0),
                                                Layout::top_down(Align::LEFT),
                                                |ui| self.detail_poster(ui, &item, season_key),
                                            );
                                            ui.allocate_ui_with_layout(
                                                vec2((width - 354.0).max(280.0), 1.0),
                                                Layout::top_down(Align::LEFT),
                                                |ui| self.detail_metadata(ui, &item, season_key),
                                            );
                                        });
                                    } else {
                                        self.detail_poster(ui, &item, season_key);
                                        ui.add_space(22.0);
                                        self.detail_metadata(ui, &item, season_key);
                                    }
                                });
                            });
                    });
            });
    }
    fn detail_poster(&mut self, ui: &mut Ui, item: &CatalogItem, _season_key: egui::Id) {
        let scoped_episodes = self
            .episodes
            .iter()
            .filter(|episode| {
                episode.provider_id == item.provider_id && episode.series_id == item.id
            })
            .cloned()
            .collect::<Vec<_>>();
        let series_action = detail_series_action(&scoped_episodes, &self.detail_positions);
        let movie_resume = self
            .detail_positions
            .iter()
            .filter(|p| {
                p.provider_id == item.provider_id
                    && p.item_type == item.content_type
                    && p.item_id == item.id
                    && !p.completed
                    && p.position_seconds > 0
            })
            .max_by_key(|p| p.last_watched_at)
            .cloned();
        let playable = if item.content_type == "series" {
            scoped_episodes.iter().any(detail_episode_playable)
        } else {
            item.stream_url
                .as_deref()
                .is_some_and(|s| !s.trim().is_empty())
                || item
                    .stream_json
                    .as_deref()
                    .is_some_and(|s| !s.trim().is_empty())
        };
        let label = if !playable {
            "Unavailable".to_owned()
        } else if item.content_type == "series" {
            series_action
                .as_ref()
                .map(DetailSeriesAction::primary_label)
                .unwrap_or_else(|| "Play First Episode".into())
        } else if let Some(progress) = &movie_resume {
            if progress.position_seconds < 60 {
                "Resume".into()
            } else {
                format!("Resume {}", detail_duration(progress.position_seconds))
            }
        } else {
            "Play".into()
        };
        let width = ui.available_width();
        let height = if item.content_type == "movie" {
            width / 0.68
        } else {
            width
        };
        let (rect, _) = ui.allocate_exact_size(vec2(width, height), Sense::hover());
        self.detail_poster_image(ui, item, rect);
        ui.add_space(16.0);
        if ui
            .add_enabled(
                playable,
                egui::Button::new(icon_label("play", &label, BG))
                    .fill(ACCENT)
                    .min_size(vec2(width, 40.0)),
            )
            .clicked()
        {
            self.detail_start(item, series_action.as_ref(), false);
        }
        if series_action.is_some() || movie_resume.is_some() {
            ui.add_space(10.0);
            if ui
                .add(
                    egui::Button::new(icon_label("rotateCcw", "Restart", TEXT))
                        .fill(Color32::TRANSPARENT)
                        .stroke(Stroke::new(1.0_f32, OUTLINE))
                        .min_size(vec2(width, 40.0)),
                )
                .clicked()
            {
                self.detail_start(item, series_action.as_ref(), true);
            }
        }
    }
    fn detail_start(
        &self,
        item: &CatalogItem,
        series_action: Option<&DetailSeriesAction>,
        restart: bool,
    ) {
        let target = if item.content_type == "series" {
            series_action
                .map(|action| PlaybackTarget::episode(&action.episode))
                .or_else(|| {
                    self.episodes
                        .iter()
                        .filter(|episode| {
                            episode.provider_id == item.provider_id
                                && episode.series_id == item.id
                                && detail_episode_playable(episode)
                        })
                        .min_by_key(|episode| {
                            (
                                episode.season_number,
                                episode.episode_number,
                                episode.id.clone(),
                            )
                        })
                        .map(PlaybackTarget::episode)
                })
        } else {
            Some(PlaybackTarget::catalog(item.clone()))
        };
        if let Some(target) = target {
            if restart
                || series_action.is_some_and(|action| action.kind == DetailSeriesActionKind::Replay)
            {
                self.worker.send(Command::Restart(target));
            } else {
                self.worker.send(Command::Prepare(target));
            }
        }
    }
    fn detail_poster_image(&mut self, ui: &Ui, item: &CatalogItem, rect: Rect) {
        ui.painter().rect_filled(rect, 8.0, PANEL);
        if let Some(texture) = item
            .artwork_url
            .as_deref()
            .and_then(|url| self.artwork.texture(ui.ctx(), url))
        {
            let image = texture.size_vec2();
            let aspect = image.x / image.y;
            let target = rect.width() / rect.height();
            if item.content_type == "movie" {
                let uv = if aspect > target {
                    let width = target / aspect;
                    Rect::from_min_max(
                        pos2((1.0 - width) / 2.0, 0.0),
                        pos2((1.0 + width) / 2.0, 1.0),
                    )
                } else {
                    let height = aspect / target;
                    Rect::from_min_max(
                        pos2(0.0, (1.0 - height) / 2.0),
                        pos2(1.0, (1.0 + height) / 2.0),
                    )
                };
                ui.painter().image(texture.id(), rect, uv, Color32::WHITE);
            } else {
                let scale = (rect.width() / image.x).min(rect.height() / image.y);
                let image_rect = Rect::from_center_size(rect.center(), image * scale);
                ui.painter().image(
                    texture.id(),
                    image_rect,
                    Rect::from_min_max(pos2(0.0, 0.0), pos2(1.0, 1.0)),
                    Color32::WHITE,
                );
            }
        } else {
            ui.painter().text(
                rect.center(),
                Align2::CENTER_CENTER,
                glyph(if item.content_type == "series" {
                    "library"
                } else {
                    "film"
                }),
                FontId::new(54.0, egui::FontFamily::Name("Vela Lucide".into())),
                Color32::from_rgb(113, 109, 102),
            );
        }
    }
    fn detail_metadata(&mut self, ui: &mut Ui, item: &CatalogItem, season_key: egui::Id) {
        let scoped_episodes = self
            .episodes
            .iter()
            .filter(|episode| {
                episode.provider_id == item.provider_id && episode.series_id == item.id
            })
            .cloned()
            .collect::<Vec<_>>();
        let series_action = detail_series_action(&scoped_episodes, &self.detail_positions);
        let movie_resume = self
            .detail_positions
            .iter()
            .filter(|p| {
                p.item_type == item.content_type
                    && p.provider_id == item.provider_id
                    && p.item_id == item.id
                    && !p.completed
                    && p.position_seconds > 0
            })
            .max_by_key(|p| p.last_watched_at)
            .cloned();
        ui.label(
            RichText::new(theme::display_text(&item.title))
                .font(theme::black(36.0))
                .color(TEXT),
        );
        ui.add_space(14.0);
        ui.horizontal_wrapped(|ui| {
            ui.spacing_mut().item_spacing = vec2(8.0, 8.0);
            if let Some(year) = item.year {
                detail_chip(ui, &year.to_string());
            }
            if let Some(rating) = item
                .rating
                .as_deref()
                .filter(|rating| !rating.trim().is_empty())
            {
                detail_chip(ui, &format!("Rating {rating}"));
            }
            if let Some(duration) = item.duration_seconds {
                detail_chip(ui, &detail_duration(duration));
            }
            if item.is_favorite {
                detail_chip(ui, "Favorite");
            }
            if let Some(action) = &series_action {
                detail_chip(ui, &action.summary_label());
            } else if movie_resume.is_some() {
                detail_chip(ui, "Resume available");
            }
        });
        ui.add_space(24.0);
        ui.label(
            RichText::new("Overview")
                .font(theme::black(11.0))
                .color(ACCENT),
        );
        ui.add_space(10.0);
        ui.label(
            RichText::new(theme::display_text(
                item.description
                    .as_deref()
                    .filter(|text| !text.trim().is_empty())
                    .unwrap_or(if self.detail_loading {
                        "Loading description from the provider."
                    } else {
                        "No description available."
                    }),
            ))
            .size(16.0)
            .color(TEXT),
        );
        if series_action.is_some() || movie_resume.is_some() {
            ui.add_space(22.0);
            ui.label(
                RichText::new("Progress")
                    .font(theme::black(11.0))
                    .color(ACCENT),
            );
            ui.add_space(8.0);
            if let Some(action) = &series_action {
                ui.label(RichText::new(action.summary_label()).color(MUTED));
            } else if let Some(progress) = &movie_resume {
                let fraction = detail_progress_fraction(progress);
                ui.label(
                    RichText::new(if fraction > 0.0 {
                        format!(
                            "{}% watched",
                            (fraction * 100.0).round().clamp(1.0, 100.0) as i64
                        )
                    } else {
                        format!("Resume from {}", detail_duration(progress.position_seconds))
                    })
                    .color(MUTED),
                );
            }
            let position = series_action
                .as_ref()
                .and_then(|action| action.position.as_ref())
                .or(movie_resume.as_ref());
            if let Some(progress) = position
                && detail_progress_fraction(progress) > 0.0
            {
                ui.add_space(10.0);
                detail_progress_bar(ui, detail_progress_fraction(progress), 7.0);
            }
        }
        if item.content_type == "series" {
            ui.add_space(30.0);
            self.detail_episode_section(ui, item, season_key, series_action.as_ref());
        }
        if item.content_type != "series"
            && let Some(error) = &self.detail_error
        {
            ui.add_space(18.0);
            detail_notice(ui, "circleAlert", "Details unavailable", error);
        }
    }
    fn detail_episode_section(
        &mut self,
        ui: &mut Ui,
        item: &CatalogItem,
        season_key: egui::Id,
        series_action: Option<&DetailSeriesAction>,
    ) {
        let mut episodes = self
            .episodes
            .iter()
            .filter(|episode| {
                episode.provider_id == item.provider_id
                    && episode.series_id == item.id
                    && detail_episode_playable(episode)
            })
            .cloned()
            .collect::<Vec<_>>();
        episodes.sort_by_key(|episode| {
            (
                episode.season_number,
                episode.episode_number,
                episode.id.clone(),
            )
        });
        if episodes.is_empty() {
            if self.detail_loading {
                detail_notice(
                    ui,
                    "listVideo",
                    "Loading episodes",
                    "Fetching seasons and episodes for this series.",
                );
            } else if let Some(error) = &self.detail_error {
                detail_notice(ui, "listX", "Episodes unavailable", error);
            } else {
                detail_notice(
                    ui,
                    "listVideo",
                    "Episodes unavailable",
                    "The provider has not returned playable episode details yet.",
                );
            }
            return;
        }
        let mut seasons = episodes
            .iter()
            .map(|episode| episode.season_number)
            .collect::<Vec<_>>();
        seasons.sort();
        seasons.dedup();
        let saved = ui.ctx().data_mut(|data| data.get_temp::<i64>(season_key));
        let mut selected = detail_selected_season(
            &seasons,
            saved,
            series_action.map(|action| action.episode.season_number),
        );
        ui.horizontal(|ui| {
            ui.label(
                RichText::new("Episodes")
                    .font(theme::black(22.0))
                    .color(TEXT),
            );
            ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                egui::ComboBox::from_id_salt(("detail-season-menu", &item.provider_id, &item.id))
                    .selected_text(format!("Season {selected}"))
                    .show_ui(ui, |ui| {
                        for season in &seasons {
                            ui.selectable_value(&mut selected, *season, format!("Season {season}"));
                        }
                    });
            });
        });
        ui.ctx()
            .data_mut(|data| data.insert_temp(season_key, selected));
        ui.add_space(14.0);
        if self.detail_loading {
            ui.horizontal(|ui| {
                ui.spinner();
                ui.label(RichText::new("Refreshing episode details…").color(MUTED));
            });
        }
        if let Some(error) = &self.detail_error {
            detail_notice(ui, "circleAlert", "Episode refresh unavailable", error);
            ui.add_space(10.0);
        }
        let positions = self.detail_positions.clone();
        for episode in episodes
            .iter()
            .filter(|episode| episode.season_number == selected)
        {
            let position = positions
                .iter()
                .filter(|position| detail_position_matches(episode, position))
                .max_by_key(|position| position.last_watched_at);
            let current =
                series_action.filter(|action| detail_same_episode(&action.episode, episode));
            if Self::detail_episode_tile(ui, episode, position, current.map(|action| action.kind))
                .clicked()
            {
                self.worker
                    .send(Command::Prepare(PlaybackTarget::episode(episode)));
            }
            ui.add_space(10.0);
        }
    }
    fn detail_episode_tile(
        ui: &mut Ui,
        episode: &Episode,
        position: Option<&PlaybackProgress>,
        action: Option<DetailSeriesActionKind>,
    ) -> egui::Response {
        let frame = egui::Frame::new()
            .fill(PANEL)
            .stroke(Stroke::new(
                1.0_f32,
                if action.is_some() { ACCENT } else { BORDER },
            ))
            .corner_radius(8)
            .inner_margin(14.0);
        let margin = frame.total_margin().sum();
        let inner_size = vec2((ui.available_width() - margin.x).max(1.0), 156.0 - margin.y);
        let mut response = frame
            .show(ui, |ui| {
                ui.set_min_size(inner_size);
                ui.set_max_size(inner_size);
                ui.horizontal_top(|ui| {
                    ui.allocate_ui_with_layout(
                        vec2(44.0, 24.0),
                        Layout::top_down(Align::LEFT),
                        |ui| {
                            ui.label(
                                RichText::new(format!("{:02}", episode.episode_number))
                                    .font(theme::black(16.0))
                                    .color(ACCENT),
                            );
                        },
                    );
                    ui.allocate_ui_with_layout(
                        vec2((ui.available_width() - 42.0).max(140.0), 1.0),
                        Layout::top_down(Align::LEFT),
                        |ui| {
                            ui.spacing_mut().item_spacing.y = 0.0;
                            ui.add(
                                egui::Label::new(
                                    RichText::new(theme::display_text(&episode.title))
                                        .font(theme::black(16.0))
                                        .color(TEXT),
                                )
                                .truncate(),
                            );
                            ui.add_space(6.0);
                            ui.label(
                                RichText::new(format!(
                                    "S{} E{}{}",
                                    episode.season_number,
                                    episode.episode_number,
                                    episode
                                        .duration_seconds
                                        .map(|duration| format!(" / {}", detail_duration(duration)))
                                        .unwrap_or_default()
                                ))
                                .size(12.0)
                                .color(MUTED),
                            );
                            if let Some(action) = action {
                                ui.add_space(8.0);
                                ui.label(
                                    RichText::new(match action {
                                        DetailSeriesActionKind::Resume => "Current episode",
                                        DetailSeriesActionKind::Continue => "Next up",
                                        DetailSeriesActionKind::Replay => "Replay episode",
                                    })
                                    .font(theme::black(11.0))
                                    .color(ACCENT),
                                );
                            }
                            if let Some(position) = position {
                                ui.add_space(8.0);
                                ui.label(
                                    RichText::new(if position.completed {
                                        "Watched".to_owned()
                                    } else {
                                        format!(
                                            "Resume {}",
                                            detail_duration(position.position_seconds)
                                        )
                                    })
                                    .font(theme::black(11.0))
                                    .color(ACCENT),
                                );
                                let fraction = detail_progress_fraction(position);
                                if fraction > 0.0 {
                                    ui.add_space(6.0);
                                    detail_progress_bar(ui, fraction, 5.0);
                                }
                            }
                            if let Some(description) = episode
                                .description
                                .as_deref()
                                .filter(|text| !text.trim().is_empty())
                            {
                                ui.add_space(8.0);
                                let mut job = egui::text::LayoutJob::simple(
                                    theme::display_text(description),
                                    FontId::proportional(14.0),
                                    MUTED,
                                    ui.available_width(),
                                );
                                job.wrap.max_rows = 1;
                                ui.add(egui::Label::new(job).truncate())
                                    .on_hover_text(theme::display_text(description));
                            }
                        },
                    );
                    ui.label(theme::icon("play").size(20.0).color(TEXT));
                });
            })
            .response
            .interact(Sense::click());
        response.widget_info(|| {
            egui::WidgetInfo::labeled(
                egui::WidgetType::Button,
                true,
                format!(
                    "Play Season {} Episode {}: {}",
                    episode.season_number, episode.episode_number, episode.title
                ),
            )
        });
        if response.hovered() || response.has_focus() {
            ui.painter().rect_stroke(
                response.rect,
                8.0,
                Stroke::new(1.0_f32, ACCENT),
                egui::StrokeKind::Inside,
            );
        }
        response = response.on_hover_cursor(egui::CursorIcon::PointingHand);
        response
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum DetailSeriesActionKind {
    Resume,
    Continue,
    Replay,
}
#[derive(Clone, Debug)]
struct DetailSeriesAction {
    kind: DetailSeriesActionKind,
    episode: Episode,
    position: Option<PlaybackProgress>,
}
impl DetailSeriesAction {
    fn primary_label(&self) -> String {
        format!(
            "{} S{} E{}",
            match self.kind {
                DetailSeriesActionKind::Resume => "Resume",
                DetailSeriesActionKind::Continue => "Continue",
                DetailSeriesActionKind::Replay => "Replay",
            },
            self.episode.season_number,
            self.episode.episode_number
        )
    }
    fn summary_label(&self) -> String {
        let label = format!(
            "S{} E{}",
            self.episode.season_number, self.episode.episode_number
        );
        match self.kind {
            DetailSeriesActionKind::Resume => self
                .position
                .as_ref()
                .map(|position| {
                    format!(
                        "Resume {label} from {}",
                        detail_duration(position.position_seconds)
                    )
                })
                .unwrap_or_else(|| format!("Resume {label}")),
            DetailSeriesActionKind::Continue => format!("Next up {label}"),
            DetailSeriesActionKind::Replay => format!("Last watched {label}"),
        }
    }
}
fn detail_type_label(item: &CatalogItem) -> &'static str {
    match item.content_type.as_str() {
        "live" => "Live channel",
        "series" => "Series",
        _ => "Movie",
    }
}
fn detail_duration(seconds: i64) -> String {
    let seconds = seconds.max(0);
    if seconds < 60 {
        "1m".into()
    } else if seconds < 3600 {
        format!("{}m", seconds / 60)
    } else {
        format!("{}h {}m", seconds / 3600, (seconds / 60) % 60)
    }
}
fn detail_episode_playable(episode: &Episode) -> bool {
    episode
        .stream_url
        .as_deref()
        .is_some_and(|text| !text.trim().is_empty())
        || episode
            .stream_json
            .as_deref()
            .is_some_and(|text| !text.trim().is_empty())
}
fn detail_same_episode(a: &Episode, b: &Episode) -> bool {
    a.provider_id == b.provider_id
        && a.series_id == b.series_id
        && a.season_id == b.season_id
        && a.id == b.id
}
fn detail_position_matches(episode: &Episode, position: &PlaybackProgress) -> bool {
    episode.provider_id == position.provider_id
        && position.item_type == "episode"
        && Some(episode.series_id.as_str()) == position.series_id.as_deref()
        && Some(episode.season_id.as_str()) == position.season_id.as_deref()
        && episode.id == position.item_id
}
fn detail_series_action(
    episodes: &[Episode],
    positions: &[PlaybackProgress],
) -> Option<DetailSeriesAction> {
    let mut playable = episodes
        .iter()
        .filter(|episode| detail_episode_playable(episode))
        .collect::<Vec<_>>();
    playable.sort_by_key(|episode| {
        (
            episode.season_number,
            episode.episode_number,
            episode.id.clone(),
        )
    });
    let index: std::collections::HashMap<_, _> = playable
        .iter()
        .enumerate()
        .map(|(index, episode)| {
            (
                (
                    episode.provider_id.as_str(),
                    episode.series_id.as_str(),
                    episode.season_id.as_str(),
                    episode.id.as_str(),
                ),
                index,
            )
        })
        .collect();
    let position_index = |position: &PlaybackProgress| {
        if position.item_type != "episode" {
            return None;
        }
        index
            .get(&(
                position.provider_id.as_str(),
                position.series_id.as_deref()?,
                position.season_id.as_deref()?,
                position.item_id.as_str(),
            ))
            .copied()
    };
    let latest_resume = positions
        .iter()
        .filter(|position| {
            !position.completed
                && position.position_seconds > 0
                && position_index(position).is_some()
        })
        .max_by_key(|position| position.last_watched_at);
    if let Some(position) = latest_resume {
        return Some(DetailSeriesAction {
            kind: DetailSeriesActionKind::Resume,
            episode: playable[position_index(position)?].clone(),
            position: Some(position.clone()),
        });
    }
    let latest = positions
        .iter()
        .filter(|position| {
            (position.completed || position.position_seconds > 0)
                && position_index(position).is_some()
        })
        .max_by_key(|position| position.last_watched_at)?;
    let current = position_index(latest)?;
    if latest.completed {
        if let Some(next) = playable.get(current + 1) {
            return Some(DetailSeriesAction {
                kind: DetailSeriesActionKind::Continue,
                episode: (**next).clone(),
                position: None,
            });
        }
        return Some(DetailSeriesAction {
            kind: DetailSeriesActionKind::Replay,
            episode: playable[current].clone(),
            position: None,
        });
    }
    Some(DetailSeriesAction {
        kind: DetailSeriesActionKind::Resume,
        episode: playable[current].clone(),
        position: Some(latest.clone()),
    })
}

fn detail_selected_season(seasons: &[i64], selected: Option<i64>, active: Option<i64>) -> i64 {
    selected
        .filter(|season| seasons.contains(season))
        .or_else(|| active.filter(|season| seasons.contains(season)))
        .or_else(|| seasons.first().copied())
        .unwrap_or(1)
}
fn detail_progress_fraction(position: &PlaybackProgress) -> f32 {
    let value = if position.completed {
        1.0
    } else if position
        .duration_seconds
        .is_some_and(|duration| duration > 0)
    {
        position.position_seconds as f64 / position.duration_seconds.unwrap() as f64
    } else {
        position.completion_percentage
    };
    if value.is_finite() {
        value.clamp(0.0, 1.0) as f32
    } else {
        0.0
    }
}
fn detail_progress_bar(ui: &mut Ui, fraction: f32, height: f32) {
    let (rect, _) = ui.allocate_exact_size(vec2(ui.available_width(), height), Sense::hover());
    ui.painter().rect_filled(rect, 128u8, BORDER);
    ui.painter().rect_filled(
        Rect::from_min_size(
            rect.min,
            vec2(rect.width() * fraction.clamp(0.0, 1.0), height),
        ),
        128u8,
        ACCENT,
    );
}
fn detail_chip(ui: &mut Ui, label: &str) {
    egui::Frame::new()
        .fill(Color32::from_rgb(26, 29, 32))
        .stroke(Stroke::new(1.0_f32, OUTLINE))
        .corner_radius(128)
        .inner_margin(egui::Margin {
            left: 10,
            right: 10,
            top: 6,
            bottom: 6,
        })
        .show(ui, |ui| {
            ui.label(
                RichText::new(theme::display_text(label))
                    .font(theme::bold(11.0))
                    .color(Color32::from_rgb(215, 208, 198)),
            );
        });
}
fn detail_notice(ui: &mut Ui, icon: &str, heading: &str, message: &str) {
    egui::Frame::new()
        .fill(PANEL)
        .stroke(Stroke::new(1.0_f32, BORDER))
        .corner_radius(8)
        .inner_margin(16.0)
        .show(ui, |ui| {
            ui.horizontal_top(|ui| {
                ui.label(theme::icon(icon).size(24.0).color(ACCENT));
                ui.vertical(|ui| {
                    ui.label(title(heading, 14.0));
                    ui.add_space(4.0);
                    ui.label(RichText::new(theme::display_text(message)).color(MUTED));
                });
            });
        });
}

#[cfg(test)]
mod detail_parity_tests {
    use super::*;

    fn episode(provider: &str, series: &str, season: i64, number: i64) -> Episode {
        Episode {
            provider_id: provider.into(),
            series_id: series.into(),
            season_id: season.to_string(),
            season_number: season,
            episode_number: number,
            id: format!("episode-{number}"),
            title: format!("Episode {number}"),
            stream_url: Some("https://fixture.invalid/episode.ts".into()),
            ..Default::default()
        }
    }
    fn position(
        episode: &Episode,
        seconds: i64,
        completed: bool,
        updated: i64,
    ) -> PlaybackProgress {
        PlaybackProgress {
            provider_id: episode.provider_id.clone(),
            item_type: "episode".into(),
            item_id: episode.id.clone(),
            series_id: Some(episode.series_id.clone()),
            season_id: Some(episode.season_id.clone()),
            position_seconds: seconds,
            duration_seconds: Some(100),
            completed,
            last_watched_at: updated,
            ..Default::default()
        }
    }

    #[test]
    fn detail_resume_matches_full_scope_and_defaults_to_its_season() {
        let first = episode("a", "show", 1, 1);
        let second = episode("a", "show", 2, 1);
        let unrelated = episode("b", "show", 2, 1);
        let action = detail_series_action(
            &[first.clone(), second.clone()],
            &[
                position(&first, 12, false, 10),
                position(&second, 71, false, 20),
                position(&unrelated, 99, false, 100),
            ],
        )
        .unwrap();
        assert!(detail_same_episode(&action.episode, &second));
        assert_eq!(action.kind, DetailSeriesActionKind::Resume);
        assert_eq!(action.primary_label(), "Resume S2 E1");
        assert_eq!(action.summary_label(), "Resume S2 E1 from 1m");
        assert_eq!(action.position.unwrap().position_seconds, 71);
        assert_eq!(detail_selected_season(&[1, 2], None, Some(2)), 2);
        assert_eq!(detail_selected_season(&[1, 2], Some(1), Some(2)), 1);
        assert_eq!(detail_selected_season(&[1, 2], Some(99), Some(2)), 2);
    }

    #[test]
    fn detail_continue_skips_unplayable_and_replays_last_instead_of_wrapping() {
        let first = episode("a", "show", 1, 1);
        let mut unavailable = episode("a", "show", 1, 2);
        unavailable.stream_url = None;
        let last = episode("a", "show", 2, 1);
        let episodes = [last.clone(), unavailable, first.clone()];
        let next = detail_series_action(&episodes, &[position(&first, 100, true, 10)]).unwrap();
        assert_eq!(next.kind, DetailSeriesActionKind::Continue);
        assert!(detail_same_episode(&next.episode, &last));
        assert_eq!(next.primary_label(), "Continue S2 E1");
        let replay = detail_series_action(
            &episodes,
            &[
                position(&first, 100, true, 10),
                position(&last, 100, true, 20),
            ],
        )
        .unwrap();
        assert_eq!(replay.kind, DetailSeriesActionKind::Replay);
        assert!(detail_same_episode(&replay.episode, &last));
        assert_eq!(replay.primary_label(), "Replay S2 E1");
        assert!(replay.position.is_none());
        // Legacy detail prioritizes the latest still-resumable episode even
        // when another episode was marked complete more recently.
        let resume = detail_series_action(
            &episodes,
            &[
                position(&first, 33, false, 10),
                position(&last, 100, true, 20),
            ],
        )
        .unwrap();
        assert_eq!(resume.kind, DetailSeriesActionKind::Resume);
        assert!(detail_same_episode(&resume.episode, &first));
    }
}

fn recent_identity(progress: &PlaybackProgress) -> String {
    let key = vela_core::store::catalog_key(
        &progress.item_type,
        &progress.item_id,
        progress.series_id.as_deref(),
        progress.season_id.as_deref(),
    )
    .unwrap_or_else(|_| progress.item_id.clone());
    format!(
        "{}:{}:{key}",
        vela_core::store::encode_component(&progress.provider_id),
        progress.item_type
    )
}

fn persist_provider_changes(worker: &crate::worker::Worker, provider: &Provider, refresh: bool) {
    // The worker resolves Refresh through the stored provider, so the edited
    // credentials must reach its ordered queue before the refresh request.
    worker.send(Command::SaveProvider(provider.clone()));
    if refresh {
        worker.send(Command::Refresh(provider.clone()));
    }
}

fn provider_field(
    ui: &mut Ui,
    rect: Rect,
    icon: &str,
    label: &str,
    value: &mut String,
    password: bool,
) {
    ui.painter().text(
        pos2(rect.left() + 20.0, rect.center().y),
        Align2::CENTER_CENTER,
        glyph(icon),
        FontId::new(22.0, egui::FontFamily::Name("Vela Lucide".into())),
        MUTED,
    );
    let filled = !value.is_empty();
    if filled {
        ui.painter().text(
            pos2(rect.left() + 44.0, rect.top()),
            Align2::LEFT_TOP,
            label,
            FontId::proportional(11.0),
            MUTED,
        );
    }
    let text_rect = Rect::from_min_max(
        pos2(
            rect.left() + 44.0,
            rect.top() + if filled { 12.0 } else { 6.0 },
        ),
        pos2(rect.right() - 8.0, rect.bottom() - 4.0),
    );
    ui.scope_builder(UiBuilder::new().max_rect(text_rect), |ui| {
        ui.add_sized(
            text_rect.size(),
            egui::TextEdit::singleline(value)
                .hint_text(label)
                .password(password)
                .frame(false),
        );
    });
    ui.painter()
        .hline(rect.x_range(), rect.bottom(), Stroke::new(1.0_f32, OUTLINE));
}

fn category_control_button(
    ui: &mut Ui,
    rect: Rect,
    id: egui::Id,
    icon: &str,
    tooltip: &str,
    enabled: bool,
    selected: bool,
) -> egui::Response {
    let enabled = enabled && ui.is_enabled();
    let response = ui.interact(
        rect,
        id,
        if enabled {
            Sense::click()
        } else {
            Sense::hover()
        },
    );
    let pressed = enabled && response.is_pointer_button_down_on();
    if enabled && (response.hovered() || pressed || response.has_focus()) {
        ui.painter().rect_filled(
            rect,
            8.0,
            if pressed {
                theme::SELECTED_BG
            } else {
                SURFACE_HIGH
            },
        );
    }
    if enabled && response.has_focus() {
        ui.painter().rect_stroke(
            rect,
            8.0,
            Stroke::new(1.0_f32, ACCENT),
            egui::StrokeKind::Inside,
        );
    }
    let color = if !enabled {
        Color32::from_rgb(76, 74, 69)
    } else if selected || pressed || response.hovered() {
        ACCENT
    } else {
        Color32::from_rgb(113, 109, 102)
    };
    ui.painter().text(
        rect.center(),
        Align2::CENTER_CENTER,
        glyph(icon),
        FontId::new(15.0, egui::FontFamily::Name("Vela Lucide".into())),
        color,
    );
    response.widget_info(|| egui::WidgetInfo::labeled(egui::WidgetType::Button, enabled, tooltip));
    response
        .on_hover_cursor(if enabled {
            egui::CursorIcon::PointingHand
        } else {
            egui::CursorIcon::Default
        })
        .on_hover_text(tooltip)
}

fn ordered_categories(
    categories: &[Category],
    sort: &str,
    favorites_only: bool,
    search: &str,
) -> Vec<Category> {
    let normalized = search.trim().to_lowercase();
    let mut result = categories
        .iter()
        .filter(|c| {
            (!favorites_only || c.is_favorite) && c.name.to_lowercase().contains(&normalized)
        })
        .cloned()
        .collect::<Vec<_>>();
    result.sort_by(|a, b| {
        let pinned = b.is_favorite.cmp(&a.is_favorite);
        if pinned != std::cmp::Ordering::Equal {
            return pinned;
        }
        let name = || {
            a.name
                .trim()
                .to_lowercase()
                .cmp(&b.name.trim().to_lowercase())
        };
        let ordering = match sort {
            "a_z" => name(),
            "z_a" => name().reverse(),
            "count" => b.item_count.cmp(&a.item_count).then_with(name),
            _ => a
                .sort_order
                .is_none()
                .cmp(&b.sort_order.is_none())
                .then(a.sort_order.cmp(&b.sort_order))
                .then_with(name),
        };
        ordering
            .then(a.provider_id.cmp(&b.provider_id))
            .then(a.id.cmp(&b.id))
    });
    result
}

#[cfg(test)]
mod category_control_tests {
    use super::ordered_categories;
    use anyhow::Result;
    use vela_core::{CatalogItem, CatalogSnapshot, Provider, Store, migration, store::category_id};

    #[test]
    fn category_controls_read_real_migrated_favorite_and_order_rows() -> Result<()> {
        let temporary = tempfile::tempdir()?;
        let source = temporary.path().join("flutter.sqlite");
        let target = temporary.path().join("rust.sqlite");
        std::fs::write(
            &source,
            include_bytes!("../../../vela-core/tests/fixtures/flutter_schema4.sqlite"),
        )?;
        migration::migrate_if_needed(&target, std::slice::from_ref(&source))?;
        let store = Store::open(&target)?;
        let categories = store.categories(Some("fixture"), "movie")?;
        let visible = ordered_categories(&categories, "my_order", true, "");
        assert_eq!(visible.len(), 1);
        assert_eq!(visible[0].name, "Films & More");
        assert!(visible[0].is_favorite);
        assert_eq!(visible[0].sort_order, Some(0));
        assert_eq!(visible[0].id, "fixture:movie:films%20%26%20more");
        assert_eq!(
            std::fs::read(&source)?,
            include_bytes!("../../../vela-core/tests/fixtures/flutter_schema4.sqlite")
        );
        Ok(())
    }

    #[test]
    fn visible_category_favorites_order_and_filter_preferences_survive_restart_and_refresh()
    -> Result<()> {
        let temporary = tempfile::tempdir()?;
        let path = temporary.path().join("categories.sqlite");
        let snapshot = CatalogSnapshot {
            provider_id: "p".into(),
            items: ["Alpha", "Beta", "Charlie", "Zulu"]
                .into_iter()
                .map(|name| CatalogItem {
                    id: name.to_lowercase(),
                    provider_id: "p".into(),
                    content_type: "live".into(),
                    title: format!("{name} channel"),
                    category_name: Some(name.into()),
                    ..Default::default()
                })
                .collect(),
            ..Default::default()
        };
        {
            let store = Store::open(&path)?;
            store.upsert_provider(&Provider {
                id: "p".into(),
                name: "Test".into(),
                kind: "m3u".into(),
                source: "https://fixture.invalid/playlist".into(),
                auto_refresh_interval_minutes: 1440,
                ..Default::default()
            })?;
            store.replace_catalog(&snapshot)?;
            for name in ["Alpha", "Beta"] {
                assert!(store.toggle_category_favorite(
                    "p",
                    "live",
                    &category_id("p", "live", name)
                )?);
            }
            store.reorder_categories(
                "p",
                "live",
                &["Zulu", "Beta", "Alpha", "Charlie"].map(|name| category_id("p", "live", name)),
            )?;
            store.set_setting("category_sort:live", "my_order")?;
            store.set_setting("category_favorites_only:live", "true")?;
        }
        let store = Store::open(&path)?;
        // A refreshed catalog retains user favorites and positions.
        store.replace_catalog(&snapshot)?;
        let rows = store.categories(Some("p"), "live")?;
        let sort = store.setting("category_sort:live")?.unwrap();
        let favorite_only =
            store.setting("category_favorites_only:live")?.as_deref() == Some("true");
        let names = |categories: Vec<vela_core::Category>| {
            categories
                .into_iter()
                .map(|category| category.name)
                .collect::<Vec<_>>()
        };
        assert_eq!(
            names(ordered_categories(&rows, &sort, favorite_only, "")),
            ["Beta", "Alpha"]
        );
        assert_eq!(
            names(ordered_categories(&rows, &sort, false, "")),
            ["Beta", "Alpha", "Zulu", "Charlie"]
        );
        assert_eq!(
            names(ordered_categories(&rows, "a_z", false, "")),
            ["Alpha", "Beta", "Charlie", "Zulu"]
        );
        assert_eq!(
            names(ordered_categories(&rows, "z_a", false, "")),
            ["Beta", "Alpha", "Zulu", "Charlie"]
        );
        assert_eq!(
            names(ordered_categories(&rows, "my_order", true, "ALP")),
            ["Alpha"]
        );
        assert!(!store.toggle_category_favorite("p", "live", &category_id("p", "live", "Beta"))?);
        assert_eq!(
            names(ordered_categories(
                &store.categories(Some("p"), "live")?,
                "my_order",
                true,
                ""
            )),
            ["Alpha"]
        );
        Ok(())
    }
}

#[cfg(test)]
mod provider_settings_tests {
    use super::*;
    use crate::worker::{Event, Worker};
    use std::{
        collections::HashMap,
        io::{BufRead, BufReader, Write},
        net::TcpListener,
        time::Duration,
    };
    use vela_core::Store;

    #[test]
    fn save_and_refresh_uses_edited_credentials_in_the_real_worker() -> anyhow::Result<()> {
        let listener = TcpListener::bind("127.0.0.1:0")?;
        listener.set_nonblocking(true)?;
        let address = listener.local_addr()?;
        let server = std::thread::spawn(move || {
            let deadline = Instant::now() + Duration::from_secs(10);
            let mut credentials = Vec::new();
            // Account validation plus three category/stream pairs.
            for _ in 0..7 {
                let mut stream = loop {
                    match listener.accept() {
                        Ok((stream, _)) => break stream,
                        Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => {
                            assert!(
                                Instant::now() < deadline,
                                "Expected provider request did not arrive"
                            );
                            std::thread::sleep(Duration::from_millis(2));
                        }
                        Err(error) => panic!("Synthetic provider failed: {error}"),
                    }
                };
                stream.set_nonblocking(false).unwrap();
                stream
                    .set_read_timeout(Some(Duration::from_secs(5)))
                    .unwrap();
                let mut reader = BufReader::new(stream.try_clone().unwrap());
                let mut line = String::new();
                reader.read_line(&mut line).unwrap();
                let target = line.split_whitespace().nth(1).unwrap();
                let url = url::Url::parse(&format!("http://localhost{target}")).unwrap();
                let query: HashMap<_, _> = url.query_pairs().into_owned().collect();
                credentials.push((query["username"].clone(), query["password"].clone()));
                loop {
                    line.clear();
                    reader.read_line(&mut line).unwrap();
                    if line == "\r\n" || line.is_empty() {
                        break;
                    }
                }
                let body = match query.get("action").map(String::as_str) {
                    None => r#"{"user_info":{"auth":1,"status":"Active"}}"#,
                    Some("get_live_streams") => r#"[{"stream_id":42,"name":"New channel"}]"#,
                    _ => "[]",
                };
                write!(
                    stream,
                    "HTTP/1.1 200 OK\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                    body.len()
                )
                .unwrap();
            }
            credentials
        });
        let temporary = tempfile::tempdir()?;
        let path = temporary.path().join("catalog.sqlite");
        let mut provider = Provider {
            id: "edited-provider".into(),
            name: "Existing provider".into(),
            kind: "xtream".into(),
            source: format!("http://{address}"),
            username: Some("old-user".into()),
            password: Some("old-password".into()),
            auto_refresh_enabled: false,
            auto_refresh_interval_minutes: 1440,
            is_enabled: true,
            ..Default::default()
        };
        Store::open(&path)?.upsert_provider(&provider)?;
        let mut worker = Worker::test_new(egui::Context::default(), path.clone());
        assert!(matches!(
            worker.rx.recv_timeout(Duration::from_secs(10))?,
            Event::Ready(_)
        ));
        provider.name = "Edited provider".into();
        provider.username = Some("edited-user".into());
        provider.password = Some("edited&password".into());
        persist_provider_changes(&worker, &provider, true);
        let deadline = Instant::now() + Duration::from_secs(10);
        loop {
            match worker
                .rx
                .recv_timeout(deadline.saturating_duration_since(Instant::now()))?
            {
                Event::Message(message) if message.starts_with("Imported ") => break,
                Event::Error(error) | Event::Fatal(error) => {
                    panic!("Save and refresh failed: {error}")
                }
                _ => {}
            }
        }
        worker.shutdown();
        let requests = server.join().expect("Synthetic provider must finish");
        assert_eq!(requests.len(), 7);
        assert!(
            requests
                .iter()
                .all(|(username, password)| username == "edited-user"
                    && password == "edited&password")
        );
        let store = Store::open(&path)?;
        let saved = store.provider(&provider.id)?.unwrap();
        assert_eq!(saved.username, provider.username);
        assert_eq!(saved.password, provider.password);
        assert_eq!(saved.name, "Edited provider");
        let page = store.catalog(&CatalogQuery {
            provider_id: Some(provider.id),
            ..Default::default()
        })?;
        assert_eq!(page.total, 1);
        assert_eq!(page.items[0].title, "New channel");
        Ok(())
    }
}

#[cfg(test)]
mod episode_size_tests {
    use super::*;
    #[test]
    fn episode_rows_keep_full_width_and_equal_height_for_all_watch_states() {
        let context = egui::Context::default();
        theme::install(&context);
        let episode = Episode {
            title: "Short title".into(),
            episode_number: 1,
            season_number: 3,
            ..Default::default()
        };
        let watched = PlaybackProgress {
            completed: true,
            position_seconds: 3600,
            duration_seconds: Some(3600),
            ..Default::default()
        };
        let resume = PlaybackProgress {
            position_seconds: 1800,
            duration_seconds: Some(3600),
            ..Default::default()
        };
        let long_episode = Episode {
            title: "A long episode title which must not determine the width of the card".repeat(3),
            description: Some(
                "An episode description with enough text to wrap over multiple lines. ".repeat(5),
            ),
            ..episode.clone()
        };
        let input = egui::RawInput {
            screen_rect: Some(Rect::from_min_size(pos2(0.0, 0.0), vec2(1000.0, 900.0))),
            ..Default::default()
        };
        let _ = context.run(input, |ctx| {
            egui::CentralPanel::default().show(ctx, |ui| {
                let width = ui.available_width();
                let rows = [
                    VelaApp::detail_episode_tile(ui, &episode, None, None).rect,
                    VelaApp::detail_episode_tile(
                        ui,
                        &long_episode,
                        Some(&resume),
                        Some(DetailSeriesActionKind::Resume),
                    )
                    .rect,
                    VelaApp::detail_episode_tile(ui, &episode, Some(&watched), None).rect,
                ];
                for row in rows {
                    assert!(
                        (row.width() - width).abs() < 0.5,
                        "card width must fill the same column: {row:?}"
                    );
                    assert!(
                        (row.height() - 156.0).abs() < 0.5,
                        "card height must not depend on watch state: {row:?}"
                    );
                }
            });
        });
    }
}

#[cfg(test)]
mod provider_action_layout_tests {
    use super::*;
    #[test]
    fn provider_actions_wrap_as_whole_buttons_without_squeezing_labels() {
        for width in [440.0, 600.0, 920.0] {
            let ctx = egui::Context::default();
            theme::install(&ctx);
            let _ = ctx.run(
                egui::RawInput {
                    screen_rect: Some(Rect::from_min_size(pos2(0.0, 0.0), vec2(width, 600.0))),
                    ..Default::default()
                },
                |ctx| {
                    egui::CentralPanel::default().show(ctx, |ui| {
                        let available = ui.available_rect_before_wrap();
                        ui.horizontal_wrapped(|ui| {
                            for label in [
                                "Save changes",
                                "Save and refresh",
                                "Refresh",
                                "Clear recent",
                            ] {
                                let response = action_enabled(ui, "refreshCw", label, false, true);
                                assert!(
                                    response.rect.height() <= 42.0,
                                    "label must remain on one line: {label} {:?}",
                                    response.rect
                                );
                                assert!(
                                    response.rect.right() <= available.right() + 1.0,
                                    "button must wrap to next row: {label}"
                                );
                            }
                        });
                    });
                },
            );
        }
    }
}

#[cfg(test)]
mod import_progress_tests {
    use super::*;
    #[test]
    fn unknown_totals_never_claim_a_percentage_and_known_totals_are_stage_scoped() {
        let mut p = imports::ImportProgress {
            stage: "Downloading movies".into(),
            completed: 2_097_152,
            total: None,
            unit: "bytes".into(),
        };
        assert_eq!(import_progress_text(&p), "Downloading movies · 2.0 MiB");
        p.completed = 512;
        assert_eq!(import_progress_text(&p), "Downloading movies · 512 B");
        p.completed = 2048;
        assert_eq!(import_progress_text(&p), "Downloading movies · 2.0 KiB");
        p.completed = 2_097_152;
        p.total = Some(4_194_304);
        assert_eq!(
            import_progress_text(&p),
            "Downloading movies · 2.0 MiB / 4.0 MiB · 50%"
        );
        p.stage = "Saving library".into();
        p.completed = 25;
        p.total = Some(100);
        p.unit = "items".into();
        assert_eq!(
            import_progress_text(&p),
            "Saving library · 25 items / 100 items · 25%"
        );
        p.total = Some(0);
        assert!(!import_progress_text(&p).contains('%'));
    }
}
