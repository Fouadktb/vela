//! Vela's existing Flutter theme, fonts, Lucide glyphs and proportional logo.
//! Source of truth: lib/src/app/app_theme.dart and shared/vela_logo_mark.dart.
use eframe::egui::{
    self, Color32, CornerRadius, FontData, FontDefinitions, FontFamily, FontId, Painter, Rect,
    RichText, Shape, Stroke, StrokeKind, TextStyle, Vec2, pos2,
};

pub const BG: Color32 = Color32::from_rgb(0x0c, 0x0d, 0x0e);
pub const PANEL: Color32 = Color32::from_rgb(0x15, 0x17, 0x19);
pub const SURFACE_HIGH: Color32 = Color32::from_rgb(0x20, 0x23, 0x26);
pub const TEXT: Color32 = Color32::from_rgb(0xf4, 0xf0, 0xe8);
pub const MUTED: Color32 = Color32::from_rgb(0xa9, 0xa3, 0x9a);
pub const ACCENT: Color32 = Color32::from_rgb(0xe7, 0xb8, 0x5b);
pub const BORDER: Color32 = Color32::from_rgb(0x29, 0x2d, 0x31);
pub const OUTLINE: Color32 = Color32::from_rgb(0x34, 0x38, 0x3c);
pub const SIDEBAR: Color32 = Color32::from_rgb(0x0f, 0x10, 0x12);
pub const SELECTED_BG: Color32 = Color32::from_rgb(0x25, 0x21, 0x1a);
pub const RADIUS: u8 = 8;
const LUCIDE: &str = "Vela Lucide";
const ARABIC: &str = "Vela Noto Naskh Arabic";
const SYMBOLS: &str = "Vela Noto Sans Symbols";
const SYMBOLS_EXTRA: &str = "Vela Noto Sans Symbols 2";
const ROBOTO_MEDIUM: &str = "Vela Roboto Medium";
const ROBOTO_BOLD: &str = "Vela Roboto Bold";
const ROBOTO_BLACK: &str = "Vela Roboto Black";

pub fn bold(size: f32) -> FontId {
    FontId::new(size, FontFamily::Name(ROBOTO_BOLD.into()))
}
/// The existing home hero and rail headings use Flutter FontWeight.w900.
pub fn black(size: f32) -> FontId {
    FontId::new(size, FontFamily::Name(ROBOTO_BLACK.into()))
}
pub fn medium(size: f32) -> FontId {
    FontId::new(size, FontFamily::Name(ROBOTO_MEDIUM.into()))
}

pub fn install(ctx: &egui::Context) {
    let mut fonts = FontDefinitions::default();
    let default_fallbacks = fonts.families[&FontFamily::Proportional].clone();
    for (name, bytes) in [
        (
            "Vela Roboto",
            include_bytes!("../../../assets/fonts/Roboto-Regular.ttf").as_slice(),
        ),
        (
            ROBOTO_MEDIUM,
            include_bytes!("../../../assets/fonts/Roboto-Medium.ttf").as_slice(),
        ),
        (
            ROBOTO_BOLD,
            include_bytes!("../../../assets/fonts/Roboto-Bold.ttf").as_slice(),
        ),
        (
            ROBOTO_BLACK,
            include_bytes!("../../../assets/fonts/Roboto-Black.ttf").as_slice(),
        ),
        (
            LUCIDE,
            include_bytes!("../../../assets/fonts/Lucide.ttf").as_slice(),
        ),
        (
            ARABIC,
            include_bytes!("../../../assets/fonts/NotoNaskhArabic.ttf").as_slice(),
        ),
        (
            SYMBOLS,
            include_bytes!("../../../assets/fonts/NotoSansSymbols.ttf").as_slice(),
        ),
        (
            SYMBOLS_EXTRA,
            include_bytes!("../../../assets/fonts/NotoSansSymbols2.ttf").as_slice(),
        ),
    ] {
        fonts
            .font_data
            .insert(name.into(), FontData::from_static(bytes).into());
        let mut family = vec![name.into()];
        if name != LUCIDE {
            for fallback in [ARABIC, SYMBOLS, SYMBOLS_EXTRA] {
                if name != fallback {
                    family.push(fallback.into());
                }
            }
            family.extend(default_fallbacks.iter().cloned());
        }
        fonts.families.insert(FontFamily::Name(name.into()), family);
    }
    let proportional = fonts.families.entry(FontFamily::Proportional).or_default();
    proportional.insert(0, SYMBOLS_EXTRA.into());
    proportional.insert(0, SYMBOLS.into());
    proportional.insert(0, ARABIC.into());
    proportional.insert(0, "Vela Roboto".into());
    let monospace = fonts.families.entry(FontFamily::Monospace).or_default();
    monospace.push(ARABIC.into());
    monospace.push(SYMBOLS.into());
    monospace.push(SYMBOLS_EXTRA.into());
    ctx.set_fonts(fonts);
    let mut style = (*ctx.style()).clone();
    style.text_styles.insert(TextStyle::Heading, bold(22.0));
    style
        .text_styles
        .insert(TextStyle::Body, FontId::proportional(14.0));
    style.text_styles.insert(TextStyle::Button, bold(14.0));
    style
        .text_styles
        .insert(TextStyle::Small, FontId::proportional(11.0));
    style.spacing.item_spacing = Vec2::new(8.0, 8.0);
    style.spacing.button_padding = Vec2::new(12.0, 10.0);
    style.spacing.interact_size = Vec2::new(44.0, 40.0);
    style.spacing.window_margin = egui::Margin::same(24);
    style.spacing.menu_margin = egui::Margin::same(8);
    style.visuals = egui::Visuals::dark();
    let visuals = &mut style.visuals;
    visuals.override_text_color = Some(TEXT);
    visuals.weak_text_color = Some(MUTED);
    visuals.panel_fill = BG;
    visuals.window_fill = PANEL;
    visuals.window_stroke = Stroke::new(1.0_f32, BORDER);
    visuals.window_corner_radius = CornerRadius::same(RADIUS);
    visuals.menu_corner_radius = CornerRadius::same(RADIUS);
    visuals.window_shadow = egui::epaint::Shadow::NONE;
    visuals.faint_bg_color = PANEL;
    visuals.extreme_bg_color = BG;
    visuals.text_edit_bg_color = Some(PANEL);
    visuals.code_bg_color = SURFACE_HIGH;
    visuals.selection.bg_fill = SELECTED_BG;
    visuals.selection.stroke = Stroke::new(1.0_f32, ACCENT);
    visuals.hyperlink_color = ACCENT;
    visuals.warn_fg_color = ACCENT;
    visuals.error_fg_color = Color32::from_rgb(0xe2, 0x6d, 0x5a);
    for widget in [
        &mut visuals.widgets.noninteractive,
        &mut visuals.widgets.inactive,
        &mut visuals.widgets.hovered,
        &mut visuals.widgets.active,
        &mut visuals.widgets.open,
    ] {
        widget.corner_radius = CornerRadius::same(RADIUS);
        widget.fg_stroke = Stroke::new(1.0_f32, TEXT);
        widget.bg_stroke = Stroke::new(1.0_f32, BORDER);
        widget.expansion = 0.0;
    }
    visuals.widgets.noninteractive.bg_fill = PANEL;
    visuals.widgets.noninteractive.weak_bg_fill = Color32::TRANSPARENT;
    visuals.widgets.inactive.bg_fill = PANEL;
    visuals.widgets.inactive.weak_bg_fill = PANEL;
    visuals.widgets.inactive.bg_stroke = Stroke::new(1.0_f32, OUTLINE);
    visuals.widgets.hovered.bg_fill = SURFACE_HIGH;
    visuals.widgets.hovered.weak_bg_fill = SURFACE_HIGH;
    visuals.widgets.hovered.bg_stroke = Stroke::new(1.0_f32, OUTLINE);
    visuals.widgets.active.bg_fill = SELECTED_BG;
    visuals.widgets.active.weak_bg_fill = SELECTED_BG;
    visuals.widgets.active.bg_stroke = Stroke::new(1.0_f32, ACCENT);
    visuals.widgets.open.bg_fill = SURFACE_HIGH;
    visuals.widgets.open.weak_bg_fill = SURFACE_HIGH;
    ctx.set_style(style);
}

/// Render-only compatibility for egui's unshaped text renderer. Storage,
/// search inputs, identifiers and editable strings must remain in logical order.
/// Apply once to a complete display label, not separately to its substrings.
pub fn display_text(raw: &str) -> String {
    let has_arabic = raw.chars().any(|c| {
        matches!(c as u32,
        0x0600..=0x06ff | 0x0750..=0x077f | 0x0870..=0x08ff | 0xfb50..=0xfdff | 0xfe70..=0xfeff)
    });
    if !has_arabic {
        return raw.to_owned();
    }
    static RESHAPER: std::sync::LazyLock<arabic_reshaper::ArabicReshaper<'static>> =
        std::sync::LazyLock::new(|| {
            let mut reshaper = arabic_reshaper::ArabicReshaper::new();
            reshaper.configuration.insert("delete_harakat", false);
            // The bidi pass reverses RTL runs, so position combining marks for that
            // reversal rather than dropping vowel marks from provider titles.
            reshaper
                .configuration
                .insert("shift_harakat_position", true);
            reshaper
        });
    // Keep hard line separators out of RTL reordering, otherwise a trailing
    // newline can move to the beginning of its paragraph's visual run.
    raw.split_inclusive(['\r', '\n'])
        .map(|line| {
            let (logical, ending) = if line.ends_with(['\r', '\n']) {
                line.split_at(line.len() - 1)
            } else {
                (line, "")
            };
            let shaped = RESHAPER.reshape(logical);
            let bidi = unicode_bidi::BidiInfo::new(&shaped, None);
            let mut visual: String = bidi
                .paragraphs
                .iter()
                .map(|para| bidi.reorder_line(para, para.range.clone()).into_owned())
                .collect();
            visual.push_str(ending);
            visual
        })
        .collect()
}

/// Names accept existing Flutter Lucide identifiers and section-name aliases.
pub fn icon(name: &str) -> RichText {
    let glyph = icon_char(name).map(String::from).unwrap_or_default();
    RichText::new(glyph).font(FontId::new(21.0, FontFamily::Name(LUCIDE.into())))
}

fn icon_char(name: &str) -> Option<char> {
    let name = match name {
        "home" | "Home" => "house",
        "live" | "Live" => "tv",
        "movies" | "Movies" => "film",
        "series" | "Series" => "library",
        "favorites" | "Favorites" => "star",
        "recent" | "Recent" => "history",
        "Settings" => "settings",
        _ => name,
    };
    let codepoint = match name {
        "alarmClockOff" => 0xe23b,
        "archive" => 0xe041,
        "arrowLeft" => 0xe048,
        "arrowRight" => 0xe049,
        "audioLines" => 0xe55a,
        "calendarClock" => 0xe304,
        "calendarDays" => 0xe2b9,
        "calendarX" => 0xe2be,
        "checkCircle2" => 0xe226,
        "chevronDown" => 0xe06d,
        "chevronUp" => 0xe070,
        "chevronsRight" => 0xe073,
        "circle" => 0xe076,
        "circleAlert" => 0xe077,
        "circleCheck" => 0xe226,
        "circleOff" => 0xe401,
        "clapperboard" => 0xe29b,
        "clock" => 0xe087,
        "clock3" => 0xe250,
        "cloudOff" => 0xe08d,
        "database" => 0xe0ad,
        "databaseZap" => 0xe50b,
        "download" => 0xe0b2,
        "externalLink" => 0xe0b9,
        "fileText" => 0xe0cc,
        "fileVideo" => 0xe321,
        "film" => 0xe0d0,
        "folderOpen" => 0xe247,
        "gauge" => 0xe1bf,
        "globe2" => 0xe1f3,
        "history" => 0xe1f5,
        "house" => 0xe0f5,
        "info" => 0xe0f9,
        "keyRound" => 0xe4a3,
        "library" => 0xe100,
        "link" => 0xe102,
        "list" => 0xe106,
        "listVideo" => 0xe2e2,
        "listX" => 0xe240,
        "loaderCircle" => 0xe10a,
        "maximize" => 0xe112,
        "minimize" => 0xe11a,
        "monitorPlay" => 0xe485,
        "panelRight" => 0xe431,
        "panelTopOpen" => 0xe438,
        "pause" => 0xe12e,
        "pin" => 0xe259,
        "pinOff" => 0xe2b6,
        "play" => 0xe13c,
        "playCircle" => 0xe080,
        "plus" => 0xe13d,
        "power" => 0xe140,
        "radio" => 0xe142,
        "radioTower" => 0xe404,
        "refreshCw" => 0xe145,
        "rotateCcw" => 0xe148,
        "rotateCw" => 0xe149,
        "save" => 0xe14d,
        "search" => 0xe151,
        "searchAlert" => 0xe6e7,
        "searchX" => 0xe4ad,
        "server" => 0xe153,
        "serverOff" => 0xe1ea,
        "settings" => 0xe154,
        "sparkles" => 0xe412,
        "star" => 0xe176,
        "subtitles" => 0xe3a4,
        "tag" => 0xe17f,
        "trash2" => 0xe18e,
        "triangleAlert" => 0xe193,
        "tv" => 0xe195,
        "user" => 0xe19f,
        "volume2" => 0xe1ab,
        "volumeX" => 0xe1ac,
        "x" => 0xe1b2,
        _ => return None,
    };
    char::from_u32(codepoint)
}

/// Paint the original gold logo tile with its charcoal V, dot and signal arcs.
/// `color` is the tile color (normally ACCENT), as in Flutter's primary color.
pub fn paint_logo(painter: &Painter, rect: Rect, color: Color32) {
    if !rect.is_positive() {
        return;
    }
    let size = rect.width().min(rect.height());
    let point = |x: f32, y: f32| pos2(rect.left() + size * x, rect.top() + size * y);
    painter.rect_filled(
        rect,
        CornerRadius::same((size * 0.2).round().clamp(0.0, 255.0) as u8),
        color,
    );
    painter.rect_stroke(
        rect.shrink(size * 0.055),
        CornerRadius::same((size * 0.2 * 0.74).round().clamp(0.0, 255.0) as u8),
        Stroke::new(
            size * 0.035,
            Color32::from_rgba_unmultiplied(BG.r(), BG.g(), BG.b(), 41),
        ),
        StrokeKind::Middle,
    );
    let width = size * 0.12;
    let v = [point(0.33, 0.36), point(0.5, 0.72), point(0.67, 0.36)];
    painter.add(Shape::line(v.to_vec(), Stroke::new(width, BG)));
    // Round caps and joins match Canvas strokeCap/strokeJoin.round.
    for p in v {
        painter.circle_filled(p, width * 0.5, BG);
    }
    painter.circle_filled(point(0.5, 0.34), size * 0.028, BG);
    for radius in [size * 0.13, size * 0.22] {
        let center = point(0.5, 0.34);
        let arc: Vec<_> = (0..=32)
            .map(|i| {
                let angle = std::f32::consts::PI * (1.14 + 0.72 * i as f32 / 32.0);
                center + Vec2::new(angle.cos(), angle.sin()) * radius
            })
            .collect();
        painter.circle_filled(arc[0], size * 0.02, BG);
        painter.circle_filled(*arc.last().unwrap(), size * 0.02, BG);
        painter.add(Shape::line(arc, Stroke::new(size * 0.04, BG)));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn installs_original_theme_and_fonts_without_missing_navigation_glyphs() {
        let ctx = egui::Context::default();
        install(&ctx);
        let style = ctx.style();
        assert_eq!(style.visuals.panel_fill, BG);
        assert_eq!(style.visuals.window_fill, PANEL);
        assert_eq!(style.visuals.selection.stroke.color, ACCENT);
        assert_eq!(style.visuals.weak_text_color, Some(MUTED));
        assert_eq!(
            style.visuals.widgets.inactive.corner_radius,
            CornerRadius::same(8)
        );
        assert_eq!(style.text_styles[&TextStyle::Heading], bold(22.0));
        let _ = ctx.run(Default::default(), |ctx| {
            ctx.fonts_mut(|fonts| {
                for name in [
                    "home",
                    "live",
                    "movies",
                    "series",
                    "favorites",
                    "recent",
                    "settings",
                ] {
                    let glyph = icon_char(name).unwrap();
                    assert!(
                        fonts.has_glyph(&FontId::new(21.0, FontFamily::Name(LUCIDE.into())), glyph),
                        "Missing original Lucide glyph for {name}"
                    );
                }
            });
            egui::CentralPanel::default().show(ctx, |ui| {
                paint_logo(
                    ui.painter(),
                    Rect::from_min_size(pos2(8.0, 8.0), Vec2::splat(40.0)),
                    ACCENT,
                )
            });
        });
    }
    #[test]
    fn arabic_display_connects_glyphs_preserves_mixed_latin_and_logical_source() {
        let raw = "سوريا".to_owned();
        let visual = display_text(&raw);
        assert_eq!(raw, "سوريا");
        assert_ne!(visual, raw);
        assert!(
            visual
                .chars()
                .any(|c| matches!(c as u32,0xfb50..=0xfdff|0xfe70..=0xfeff))
        );
        let mixed = display_text("Channel HD 12 - سوريا");
        assert!(mixed.starts_with("Channel HD 12 - "));
        assert!(!mixed.contains('?'));
        assert_eq!(display_text("Open in catalog →"), "Open in catalog →");
        assert_eq!(display_text("One\nTwo"), "One\nTwo");
        assert_eq!(
            display_text("سوريا\nChannel HD"),
            format!("{visual}\nChannel HD")
        );
        assert_eq!(
            display_text("سوريا\r\nChannel HD"),
            format!("{visual}\r\nChannel HD")
        );
        let marked = display_text("سُورِيَا");
        assert!(marked.contains('ُ') && marked.contains('ِ') && marked.contains('َ'));
    }
    #[test]
    fn all_text_weights_have_arabic_presentation_and_symbol_fallbacks() {
        let ctx = egui::Context::default();
        install(&ctx);
        let text = format!("Vela → سوريا {}", display_text("سوريا"));
        let _ = ctx.run(Default::default(), |ctx| {
            ctx.fonts_mut(|fonts| {
                for font in [
                    FontId::proportional(14.0),
                    medium(16.0),
                    bold(22.0),
                    black(36.0),
                ] {
                    for glyph in text.chars() {
                        assert!(
                            fonts.has_glyph(&font, glyph),
                            "Missing glyph U+{:04X} in {font:?}",
                            glyph as u32
                        );
                    }
                }
            })
        });
    }
    #[test]
    fn navigation_icons_match_flutter_lucide_codepoints() {
        assert_eq!(icon_char("home"), char::from_u32(0xe0f5));
        assert_eq!(icon_char("live"), char::from_u32(0xe195));
        assert_eq!(icon_char("favorites"), char::from_u32(0xe176));
        assert_eq!(icon_char("unknown"), None);
    }
}
