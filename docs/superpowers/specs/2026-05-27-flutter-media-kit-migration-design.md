# Vela Flutter MediaKit Migration Design

## Status

Ready for owner review.

## Supersedes

This spec supersedes the current Electron/mpv playback direction described in:

- `docs/superpowers/specs/2026-05-27-in-app-playback-engine-design.md`
- `docs/superpowers/specs/2026-05-27-vela-theater-player-design.md`
- `docs/superpowers/specs/2026-05-27-vela-shell-player-refresh-design.md`

The existing Electron implementation remains useful as product reference for provider import, catalog browsing, favorites, recent items, settings, and visual direction. It is not the target playback architecture anymore.

## Decision

Rebuild Vela as a Flutter desktop app for macOS and Windows, using `media_kit` as the single embedded playback engine.

The user-visible product must have one app window, one player experience, and no fallback player selection. Closing playback returns to the catalog. Fullscreen remains part of Vela. Track menus, subtitles, audio selection, video selection, seeking, and episode navigation are implemented in Vela UI over the embedded video surface.

Important nuance: `media_kit` uses libmpv internally on native platforms. That is different from the current architecture. We are removing the standalone mpv executable/window, transparent Electron overlay, external process lifecycle, and fallback-player UX. We are not promising that no mpv-derived decoder code exists inside the app bundle.

## Why

The current Electron + external mpv + transparent overlay approach creates the exact problems the app is supposed to avoid:

- Playback is effectively a separate app/window.
- Cmd-Tab/Alt-Tab behavior is confusing.
- Closing the player can close or hide the wrong thing.
- Multi-monitor overlays can appear without the video.
- Track selection is hard to make reliable because Vela and mpv are separate UI surfaces.
- The user can feel the fallback architecture even when we try to hide it.

Vela needs the player to be a first-class in-app surface, not something coordinated beside the app.

## Goals

- Ship one seamless desktop app for macOS and Windows.
- Use one embedded playback engine for live TV, movies, and series.
- Support IPTV streams that commonly use MPEG-TS, HLS, MP4, MKV, HEVC, AC3/EAC3, multiple audio tracks, and subtitles as far as the chosen engine supports them.
- Keep the Netflix-style player UX: dark fullscreen surface, centered transport, large timeline, track menus, double-click or double-tap 10 second seek zones, next episode affordance, and minimal chrome.
- Preserve the improved Vela catalog UX: collapsible fixed sidebar, category list with favorites/reorder, sticky preview/detail area, favorites, recently watched, settings, multi-playlist, and auto-refresh.
- Keep local build and GitHub release flow practical for private distribution.

## Non-Goals

- No standalone mpv app window.
- No transparent Electron overlay over a separate player.
- No dual user-facing playback modes.
- No Chromium `<video>` plus fallback routing.
- No automated test suite. Verification for this migration uses formatting, static analysis, release builds, and explicit manual playback checks.
- No landing page.
- No DRM playback scope.
- No App Store submission in the first migration pass.

## Research Basis

- Flutter officially supports compiling native Windows and macOS desktop apps, including desktop plugins and release builds via `flutter build windows` and `flutter build macos`: https://docs.flutter.dev/platform-integration/desktop
- Flutter's macOS release documentation covers bundle identity, signing, versioning, icons, and TestFlight/App Store release concerns for later distribution hardening: https://docs.flutter.dev/deployment/macos
- `media_kit` is a Flutter/Dart video and audio playback stack with `media_kit`, `media_kit_video`, and `media_kit_libs_video` packages for the embedded video surface and native libraries: https://github.com/media-kit/media-kit
- pub.dev lists `media_kit` and `media_kit_video` as supporting macOS and Windows: https://pub.dev/publishers/media-kit.dev/packages
- Drift is a reactive SQLite persistence library for Flutter/Dart with macOS and Windows support, which matches the catalog's need for fast local browsing and auto-updating views: https://pub.dev/packages/drift
- Riverpod provides reactive data-binding and asynchronous state handling for Flutter, useful for provider refreshes and catalog screens: https://pub.dev/packages/flutter_riverpod
- `window_manager` provides desktop window/fullscreen controls for macOS and Windows: https://pub.dev/packages/window_manager
- `uosc` is a strong reference for compact player controls, searchable menus, and track menus, but it is an mpv UI layer and would keep Vela tied to an external mpv-style player experience if used directly: https://github.com/tomasklaen/uosc

## Architecture

### Application Shell

Flutter owns the full UI. The primary window contains:

- Fixed/collapsible sidebar with icon-only collapsed mode.
- Route-specific search and filter state, reset when changing top-level section.
- Catalog views for live TV, movies, series, favorites, recently watched, and settings.
- Category browser as a real sidebar/list, not a select or chip strip.
- Detail/preview panel that stays visible while scrolling catalog results.
- Player route that can enter fullscreen without opening a separate player process.

### Playback

Playback is a module, not an external command.

`media_kit.Player` owns media state. `media_kit_video.VideoController` renders into a Flutter `Video` widget. Vela controls are Flutter widgets layered in the same route.

The playback controller exposes:

- `openPlayable(PlayableItem item)`
- `play()`
- `pause()`
- `seekRelative(Duration offset)`
- `seekTo(Duration position)`
- `setVolume(double value)`
- `setAudioTrack(String id)`
- `setSubtitleTrack(String id)`
- `setVideoTrack(String id)`
- `setPlaybackSpeed(double value)`
- `closePlayer()`

The player UI reads state from the controller:

- playing/paused/buffering/error
- duration and position
- volume and mute
- available audio tracks
- available subtitle tracks
- available video tracks
- current tracks
- current item
- next episode when the current item belongs to a series

Player close always disposes or stops playback and navigates back to the previous catalog context. It does not close Vela.

### Provider Import

Vela supports:

- Xtream Codes server URL, username, and password.
- M3U URL.
- Local M3U file.
- Multiple saved providers/playlists.

Provider import normalizes live channels, movies, series, seasons, episodes, categories, logos/posters, stream URLs, and metadata into one catalog model.

Xtream import should use typed endpoints for categories and content rather than deriving everything from one flat playlist whenever possible. M3U import remains parser-based.

### Catalog Persistence

Use Drift over SQLite for local catalog storage. Vela needs indexed queries, reactive lists, and stable migrations as the app grows.

Primary tables:

- providers
- provider_refresh_runs
- categories
- catalog_items
- series
- seasons
- episodes
- favorite_items
- favorite_categories
- category_order
- watch_history
- playback_positions
- app_settings

The UI reads catalog data through repository/providers, not direct table access.

### Auto-Refresh

Each provider has refresh settings:

- enabled or disabled
- interval
- last refresh status
- next refresh time
- refresh on app launch when stale

Refresh runs in the app process with clear progress/error state. It updates the catalog transactionally so the UI never sees a half-imported provider.

### Release

The first Flutter release uses local builds and manual GitHub release upload, matching the current private distribution pattern.

- macOS: build on macOS with `flutter build macos`; package as app archive or DMG after the first playable build is stable.
- Windows: build on Windows with `flutter build windows`; package as zip or installer after the first playable build is stable.
- App signing/notarization is a separate release-hardening phase.

## UX Requirements

### Player

- Fullscreen playback is one Vela route/window state.
- Controls auto-hide after inactivity and reappear on mouse movement, keyboard input, or pointer/touch interaction.
- Double-click or double-tap left seeks back 10 seconds.
- Double-click or double-tap right seeks forward 10 seconds.
- A visible seek feedback indicator appears for backward/forward seek.
- Track menus are real menus/lists, not toggles.
- Audio, subtitle, and video track menus show current selection and allow explicit selection.
- Subtitles can be disabled when a subtitle track exists.
- Live TV displays channel metadata and EPG when available.
- Movies display resume position when available.
- Series displays next episode and season/episode context under or beside the player when not in fullscreen.

### Catalog

- Categories are a list with search, favorite, and reorder actions.
- Category selection shows items inside that category.
- "All" is a synthetic category but does not replace real provider categories.
- Preview/detail panel stays sticky while catalog items scroll.
- Search/filter state is per section and resets on top-level navigation.
- The collapsed sidebar has stable icon positions and no layout jump.
- Sidebar remains fixed while catalog content scrolls.

### Settings

Settings includes:

- provider management
- add Xtream provider
- add M3U URL
- add local M3U file
- refresh interval
- manual refresh
- default subtitle/audio behavior
- clear recent history
- clear cache/catalog for a provider
- app version/build information

## Migration Strategy

The migration should not try to salvage the Electron player. The first implementation step is a Flutter playback spike that proves the new foundation:

1. Launch Vela as Flutter on macOS.
2. Open a known playlist stream in the embedded player.
3. Enter and exit fullscreen.
4. Close playback without closing the app.
5. Show audio/subtitle/video track menus from the embedded player state.
6. Verify seek gestures and keyboard shortcuts.

Only after that spike works should provider import, catalog screens, and release packaging be ported.

The Electron app can remain in the repository as legacy reference during migration. Once Flutter reaches feature parity, the Electron source, mpv scripts, and Electron release packaging should be removed.

## Acceptance Criteria

- `flutter run -d macos` launches Vela on macOS.
- The embedded player can play at least one legal live stream and one legal VOD/sample file without opening a second app window.
- Closing the player returns to the catalog and leaves Vela running.
- Cmd-Tab/Alt-Tab shows Vela as the app, not a separate player.
- Fullscreen does not create an overlay on another monitor.
- Audio, subtitle, and video track menus are visible when the media exposes tracks.
- Double-click or double-tap seek works on left/right player zones.
- Xtream and M3U providers can be saved, refreshed, and browsed.
- Live, movies, series, favorites, recently watched, and settings are available.
- Categories are browsable, favoritable, and reorderable.
- Provider auto-refresh works on app launch and by interval.
- `flutter analyze` passes.
- `flutter build macos` passes on macOS.
- `flutter build windows` passes on Windows before a Windows release is published.

## Open Product Decisions For Review

- Whether the first Flutter release should keep the repository name `iptv-player` while the app/product name remains `Vela`.
- Whether the first release artifact should be a simple zip/app archive before adding DMG and Windows installer polish.
- Whether app signing/notarization should wait until after local macOS/Windows playback validation.
