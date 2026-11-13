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
    ui.add_sized(
        [38.0, 38.0],
        egui::Button::new(theme::icon(icon).size(18.0)).frame(false),
    )
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
    ui.add(
        egui::Button::new(icon_label(icon, label, if primary { BG } else { TEXT }))
            .min_size(vec2(44.0, 40.0))
            .fill(if primary {
                ACCENT
            } else {
                Color32::TRANSPARENT
            })
            .stroke(if primary {
                Stroke::NONE
            } else {
                Stroke::new(1.0_f32, OUTLINE)
            }),
    )
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

impl VelaApp {
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
                            self.selected_catalog = None;
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
                                ui.label(theme::icon("search").size(20.0).color(MUTED));
                                let response = ui.add_sized(
                                    [(ui.available_width() - extras).max(80.0), 28.0],
                                    egui::TextEdit::singleline(&mut self.query.search)
                                        .hint_text(format!(
                                            "Search {} or / global",
                                            self.section.label().to_lowercase()
                                        ))
                                        .frame(false),
                                );
                                if response.changed() {
                                    self.search_changed = Some(Instant::now());
                                }
                            });
                        });
                    if icon_button(ui, "globe2", "Search everything").clicked() {
                        self.query.content_type = None;
                        self.query.offset = 0;
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
        if let Some(message) = self.message.clone() {
            ui.add_space(6.0);
            ui.horizontal_wrapped(|ui| {
                ui.label(RichText::new(message).color(ACCENT));
                if ui.small_button("Dismiss").clicked() {
                    self.message = None;
                }
            });
        }
    }

    pub(super) fn catalog(&mut self, ui: &mut Ui) {
        if self.section == Section::Home {
            self.home_ui(ui);
            return;
        }
        if self.providers.is_empty()
            || (self.providers.iter().all(|p| p.last_refresh_at.is_none()) && self.page.total == 0)
        {
            self.onboarding(ui);
            return;
        }
        self.header(ui);
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
        if drag.dragged() {
            self.category_sidebar_width =
                (category_width + drag.drag_delta().x).clamp(220.0, 420.0);
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
        if self.selected_catalog.is_none()
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
        ui.add_space(12.0);
        let all = self.categories.iter().map(|c| c.item_count).sum::<i64>();
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
        let search = self.category_search.to_lowercase();
        let categories = self.categories.clone();
        egui::ScrollArea::vertical()
            .id_salt("category-list")
            .auto_shrink([false, false])
            .show(ui, |ui| {
                for category in categories
                    .iter()
                    .filter(|c| c.name.to_lowercase().contains(&search))
                {
                    let response = self.category_row(
                        ui,
                        &category.name,
                        category.item_count,
                        self.query.category_id.as_deref() == Some(&category.id),
                        category.is_favorite,
                    );
                    if response.clicked() {
                        self.query.category_id = Some(category.id.clone());
                        self.query.offset = 0;
                        self.selected_catalog = None;
                        self.reload();
                    }
                    response.context_menu(|ui| {
                        if ui
                            .button(if category.is_favorite {
                                "Unfavorite category"
                            } else {
                                "Favorite category"
                            })
                            .clicked()
                        {
                            self.worker.send(Command::CategoryFavorite(
                                category.provider_id.clone(),
                                category.content_type.clone(),
                                category.id.clone(),
                            ));
                            ui.close();
                        }
                        for (label, delta) in [("Move up", -1isize), ("Move down", 1)] {
                            if ui
                                .add_enabled(search.is_empty(), egui::Button::new(label))
                                .clicked()
                            {
                                let mut ids: Vec<_> = categories
                                    .iter()
                                    .filter(|c| {
                                        c.provider_id == category.provider_id
                                            && c.content_type == category.content_type
                                    })
                                    .map(|c| c.id.clone())
                                    .collect();
                                if let Some(index) = ids.iter().position(|id| id == &category.id) {
                                    let next = index as isize + delta;
                                    if next >= 0 && (next as usize) < ids.len() {
                                        ids.swap(index, next as usize);
                                        self.worker.send(Command::ReorderCategories(
                                            category.provider_id.clone(),
                                            category.content_type.clone(),
                                            ids,
                                        ));
                                    }
                                }
                                ui.close();
                            }
                        }
                    });
                    ui.add_space(4.0);
                }
            });
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
    fn select_catalog(&mut self, item: CatalogItem) {
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
                    let episodes = self.episodes.clone();
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
                            if ui.add(egui::Button::new(icon_label("arrowRight","Open in catalog",ACCENT)).frame(false)).clicked(){self.navigate(match item.content_type.as_str(){"live"=>Section::Live,"series"=>Section::Series,_=>Section::Movies});self.select_catalog(item.clone());}
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
            egui::Frame::new().inner_margin(egui::Margin{left:24,right:24,top:6,bottom:0}).show(ui,|ui|{ui.label(RichText::new("Pick up where you left off or browse what is new.").size(14.0).color(MUTED));self.notices(ui);});
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

    pub(super) fn recent_ui(&mut self, ui: &mut Ui) {
        self.header(ui);
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
                            if self.provider_form.is_none() {
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
        let width = ui
            .available_width()
            .min(if embedded { 520.0 } else { 640.0 });
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
                                (360, "6 hours"),
                                (720, "12 hours"),
                                (1440, "24 hours"),
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
                ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
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
                        if action(ui, "refreshCw", "Refresh", false).clicked() {
                            refresh = true;
                        }
                        if icon_button(ui, "trash2", "Remove provider").clicked() {
                            self.delete_provider = Some(form.clone());
                        }
                    }
                });
            });
        if save {
            self.worker.send(Command::SaveProvider(form.clone()));
            if adding {
                self.worker.send(Command::Refresh(form.clone()));
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
        let width = ui
            .available_width()
            .min(if embedded { 520.0 } else { 640.0 });
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
        let screen = ctx.content_rect();
        egui::Area::new(egui::Id::new("content-detail-screen"))
            .order(egui::Order::Foreground)
            .fixed_pos(screen.min)
            .show(ctx, |ui| {
                egui::Frame::new()
                    .fill(BG)
                    .inner_margin(24.0)
                    .show(ui, |ui| {
                        ui.set_min_size(screen.size() - vec2(48.0, 48.0));
                        if action(ui, "arrowLeft", "Back", false).clicked() {
                            self.details = None;
                        }
                        ui.add_space(24.0);
                        ui.horizontal_top(|ui| {
                            let (rect, _) =
                                ui.allocate_exact_size(vec2(260.0, 360.0), Sense::hover());
                            self.paint_artwork(ui, &item, rect);
                            ui.add_space(24.0);
                            ui.vertical(|ui| {
                                ui.set_width((screen.width() - 380.0).max(300.0));
                                ui.label(title(&item.title, 32.0));
                                ui.add_space(12.0);
                                ui.label(
                                    RichText::new(item.content_type.to_uppercase()).color(ACCENT),
                                );
                                ui.add_space(20.0);
                                ui.label(
                                    RichText::new(theme::display_text(
                                        item.description
                                            .as_deref()
                                            .unwrap_or("No description available."),
                                    ))
                                    .size(16.0)
                                    .color(MUTED),
                                );
                                ui.add_space(24.0);
                                ui.horizontal(|ui| {
                                    if item.content_type != "series"
                                        && action(ui, "play", "Play", true).clicked()
                                    {
                                        self.prepare(item.clone());
                                        self.details = None;
                                    }
                                    if action(
                                        ui,
                                        "star",
                                        if item.is_favorite {
                                            "Remove favorite"
                                        } else {
                                            "Add favorite"
                                        },
                                        false,
                                    )
                                    .clicked()
                                    {
                                        self.worker.send(Command::Favorite(item.clone()));
                                    }
                                });
                                if item.content_type == "series" {
                                    ui.add_space(24.0);
                                    ui.label(title("Episodes", 22.0));
                                    ui.add_space(12.0);
                                    let episodes = self.episodes.clone();
                                    egui::ScrollArea::vertical()
                                        .id_salt("detail-episodes")
                                        .max_height((screen.height() - 300.0).max(150.0))
                                        .show(ui, |ui| {
                                            for episode in &episodes {
                                                if ui
                                                    .add_sized(
                                                        [ui.available_width(), 44.0],
                                                        egui::Button::new(theme::display_text(
                                                            &format!(
                                                                "S{:02} E{:02}  {}",
                                                                episode.season_number,
                                                                episode.episode_number,
                                                                episode.title
                                                            ),
                                                        )),
                                                    )
                                                    .clicked()
                                                {
                                                    self.worker.send(Command::Prepare(
                                                        PlaybackTarget::episode(episode),
                                                    ));
                                                    self.details = None;
                                                }
                                            }
                                        });
                                }
                            });
                        });
                    });
            });
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
