These are the existing Vela Flutter app's fonts, carried into the Rust desktop
renderer to preserve typography and icon shapes. Latin text retains the original
Roboto faces. Noto Naskh Arabic is a fallback for glyphs absent from Roboto.

- Roboto-Regular/Medium/Bold/Black.ttf: copied from the Flutter SDK's material_fonts
  assets. The original app explicitly uses `Typography.material2021().white`
  without a platform argument; Flutter defaults that typography call to Android
  and therefore Roboto on both desktop platforms. See Roboto_LICENSE.txt.
- Lucide.ttf: copied unchanged from lucide_icons_flutter 3.1.14+2
  `assets/lucide.ttf`, the package resolved by the existing app. Glyph codepoints
  in theme.rs come from that same package's generated lucide_icons.dart.
  LucideFlutter-LICENSE.txt preserves the font package license;
  Lucide-LICENSE.txt preserves the upstream Lucide and Feather notices.

The Vela logo remains code-native and follows the exact proportional geometry
of the [legacy logo source](https://github.com/Fouadktb/vela/blob/2829911a167bdc8e185c3b62938c1f94b53f295e/lib/src/shared/vela_logo_mark.dart).

## Arabic fallback

`NotoNaskhArabic.ttf` is the unchanged Noto Naskh Arabic 2.021 variable font,
from the official Google Fonts repository:
https://github.com/google/fonts/tree/main/ofl/notonaskharabic

Download source:
https://raw.githubusercontent.com/google/fonts/main/ofl/notonaskharabic/NotoNaskhArabic%5Bwght%5D.ttf

SHA256: `67b5a525a661b607971fbd3f96a81b89d3a768e74534fca84f18ac97e6fab72f`

Upstream source revision: notofonts/arabic
`59f5a3fd985bf24858915c3dddfc51a537640965` (from the official font metadata).
The SIL Open Font License 1.1 and copyright notice are preserved in
`NotoNaskhArabic-LICENSE.txt`.

All Roboto weight families retain egui's existing fallback chain after the
Arabic font, including symbol/arrow coverage. Arabic joining and bidi visual
ordering are performed only for display labels; stored names, search inputs,
and identifiers retain their original logical Unicode text.

## Symbol fallback

`NotoSansSymbols2.ttf` is the unchanged Noto Sans Symbols 2 v2.008 font from
Google Fonts, used only for symbols absent from the existing Roboto/default
fallback faces. Basic arrows including U+2192 are covered by the complementary
Noto Sans Symbols family below.

https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssymbols2/NotoSansSymbols2-Regular.ttf

SHA256: `7d5fb73b7ca67a6798101741f5d280a3d016a56a197afcd4199dbb57b4b82a21`

Official source revision: notofonts/symbols
`25b00f0d3f40873a005287514ba2a48558655314` (Google Fonts metadata).
The original SIL Open Font License 1.1 is preserved in
`NotoSansSymbols2-LICENSE.txt`.

`NotoSansSymbols.ttf` is the unchanged Noto Sans Symbols v2.003 variable font.
It covers basic arrows that are intentionally absent from Symbols 2.

https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssymbols/NotoSansSymbols%5Bwght%5D.ttf

SHA256: `f7e7e04b4a24b6c78893d50cbfd2b2f6cae49617ab047bfef668d252adb128f7`

Official source revision: notofonts/symbols
`b61fa7f86fb7d4163ee11d46d0977393f98d4f7a` (Google Fonts metadata).
See `NotoSansSymbols-LICENSE.txt` for the original SIL Open Font License 1.1.
