# IPTV Player Design Spec

Date: 2026-05-26
Status: approved for implementation planning
Branch: feature/initial-design-spec

## Goal

Build a polished desktop IPTV player for macOS and Windows. The app should be usable by the owner and a small circle first, hosted on GitHub, and structured well enough to become public later. It is not a landing page project. The first product surface is the actual player.

The app should feel substantially better than typical IPTV players: fast browsing, strong search, sensible navigation, reliable playback, and a clean desktop experience.

## Product Scope

Version 1 supports:

- macOS and Windows desktop installs.
- GitHub-hosted source and manual GitHub Releases.
- Xtream Codes input: server URL, username, and password.
- M3U input: URL and/or local playlist file.
- Live TV, VOD movies, and series.
- Local catalog cache.
- Search, category filtering, favorites, recently watched, and watch progress.
- Managed mpv playback controlled by the app.
- External VLC/mpv fallback for streams that fail in the managed path.
- Simple local storage for v1, behind a boundary that can later move credentials to OS credential storage.

Version 1 does not include:

- Landing page.
- Cloud sync.
- User accounts.
- Public IPTV provider directory.
- Mobile, tablet, or TV apps.
- App store distribution.
- Auto-update.
- Code signing, notarization, or Windows certificate signing unless added later.
- Full TV remote-control interface.
- Advanced parental controls.
- A guarantee of perfectly embedded mpv video inside the React layout on both macOS and Windows.

The app should not ship or promote IPTV content. Users provide their own provider details or playlists.

## Recommended Stack

Use Electron, React, and TypeScript with managed mpv playback.

Primary packages and tools:

- Electron for the desktop shell, app lifecycle, windows, OS integration, and process control.
- React and TypeScript for the renderer UI.
- Vite for renderer development and build speed.
- electron-builder for local macOS and Windows packaging.
- SQLite for catalog cache and local app state.
- mpv as the managed playback engine, controlled through JSON IPC.
- lucide-react for production icons.

Rationale:

Electron and React provide the fastest path to a refined desktop UI and mature packaging. mpv is better suited than browser video for inconsistent IPTV streams. The design avoids old or fragile Electron video plugin foundations and treats mpv as a controlled playback process.

## Architecture

The app has three main runtime layers.

### React Renderer

The renderer owns the user experience:

- Onboarding and provider setup.
- Sidebar navigation.
- Live TV, Movies, Series, Favorites, and Recently Watched views.
- Search and filters.
- Detail panes.
- Player controls.
- Settings.
- Import and refresh progress.
- Error presentation.

The renderer does not directly access filesystem, credentials, SQLite, or child processes. It talks to the Electron main process through a narrow typed preload API.

### Electron Main Process

The main process owns privileged desktop work:

- App lifecycle and windows.
- Secure IPC handlers.
- Provider import and refresh jobs.
- SQLite access.
- Local config access.
- mpv process management.
- External player launching.
- Build/release integration points.

Long-running imports and refreshes run outside the renderer and emit progress events back to React.

### Managed mpv Playback Service

The playback service owns mpv process control:

- Start, stop, and reuse mpv where appropriate.
- Resolve catalog items into playable stream URLs.
- Launch mpv with controlled options.
- Control playback through JSON IPC.
- Observe playback state and track metadata.
- Surface stream and player errors to the main process.
- Support opening streams in external VLC/mpv.

Windows can later explore deeper integration using native window handles and mpv window attachment. macOS v1 should use a controlled player window rather than depending on embedded foreign-process video inside the React DOM.

## Data Model

Xtream Codes and M3U are provider adapters. After import, both must produce the same normalized catalog model so the UI is provider-agnostic.

Core entities:

- `Provider`: id, type, name, base URL or playlist source, credentials/config, cache timestamps, status.
- `LiveChannel`: id, provider id, name, logo, category/group, stream resolver data, EPG channel id, last seen timestamp.
- `Movie`: id, provider id, title, poster, category, metadata, stream resolver data, last seen timestamp.
- `Series`: id, provider id, title, poster, category, metadata, seasons, last seen timestamp.
- `Episode`: id, provider id, series id, season number, episode number, title, metadata, stream resolver data, duration, progress.
- `EpgProgram`: id, provider id, channel id, title, start time, end time, description.
- `Favorite`: item type, item id, provider id, created timestamp.
- `WatchProgress`: item type, item id, provider id, position, duration, completed flag, updated timestamp.
- `RecentlyWatched`: item type, item id, provider id, last watched timestamp.

Stream resolver data should preserve enough provider-specific information to build the final URL at playback time without leaking provider-specific logic into the renderer.

## Import And Refresh

The app supports two provider adapters in v1:

- Xtream Codes adapter.
- M3U adapter.

Each adapter is responsible for fetching/parsing source data, validating obvious failures, mapping source fields into normalized entities, and returning diagnostics.

Refresh rules:

- Refresh runs in the Electron main process.
- Refresh emits progress events to the renderer.
- Browsing should remain usable while refresh runs where possible.
- Existing favorites, recently watched items, and progress are preserved.
- Items missing from a refresh are marked stale before deletion.
- Provider errors do not erase local cache by default.
- Search indexes or derived lookup tables are rebuilt after successful catalog updates.

For M3U, the parser should tolerate imperfect playlists and capture diagnostics for malformed rows. For Xtream Codes, invalid credentials, unreachable server, and unexpected response shapes should produce clear errors.

## Storage

Use SQLite for the catalog, cache, favorites, progress, and recently watched state. Use a small local config store for v1 provider credentials and app settings.

Storage must sit behind service/repository interfaces so v1 simple credential storage can later be replaced with macOS Keychain and Windows Credential Manager without changing UI code or provider import logic.

Data that should be local-only in v1:

- Provider configuration.
- Credentials.
- Catalog cache.
- EPG cache.
- Favorites.
- Watch progress.
- Recently watched list.
- Settings.

## UX And Navigation

The app is desktop-first with a cinematic playback mode.

Main navigation:

- Live TV.
- Movies.
- Series.
- Favorites.
- Recently Watched.
- Settings.

The main window uses:

- Persistent left sidebar.
- Global search.
- Category/group filters.
- Dense catalog views for fast scanning.
- Detail pane for the selected item.
- Provider/cache status.
- Keyboard-friendly navigation.

Expected keyboard behavior:

- Typing focuses or updates search when appropriate.
- Arrow keys move selection.
- Enter plays the selected item.
- Space toggles pause/play in playback mode.
- Escape leaves playback mode or closes transient UI.

Icons are part of the production design. Use lucide-react icons for sidebar destinations, player controls, search, filters, favorites, refresh, settings, error/retry, and external-player actions. Main navigation should use icon plus text. Compact buttons can use icon-only presentation with tooltips.

## Playback UX

Playback should feel integrated even when the underlying mpv window is separate from the React renderer.

Playback controls:

- Play/pause.
- Stop/back to library.
- Seek for VOD and episodes.
- Volume and mute.
- Fullscreen.
- Audio track selection where available.
- Subtitle track selection where available.
- Reconnect/retry.
- Open external player.

Playback state should update the app:

- Current item.
- Play/pause state.
- Position and duration where known.
- Track list where available.
- Stream errors.
- Last played channel.
- Watch progress for VOD and episodes.
- Recently watched list.

Live streams should prioritize stability and reconnect behavior. VOD and episodes should prioritize seeking, progress, and resume.

## Error Handling

Errors should be specific, plain, and actionable.

Provider errors:

- Invalid credentials.
- Provider unreachable.
- M3U URL unavailable.
- Local M3U file unreadable.
- Playlist parse failure.
- Empty provider catalog.
- Unexpected provider response.

Playback errors:

- No playable stream.
- Stream timed out.
- Stream ended unexpectedly.
- mpv missing or unavailable.
- mpv process crashed.
- External player missing.
- Unsupported action for stream type.

Each error should offer the next useful action when possible:

- Retry.
- Refresh provider.
- Edit credentials.
- Reconnect.
- Open external player.
- Choose player executable.
- Copy diagnostics.

Diagnostics should be useful for debugging but should not expose passwords in logs or UI.

## Project Structure

Use one repository with clear module boundaries:

```text
electron/
  main/
    app/
    ipc/
    windows/
    playback/
    imports/
    storage/
  preload/
src/
  renderer/
    app/
    components/
    features/
    routes/
    styles/
  shared/
    catalog/
    errors/
    ipc/
    providers/
    playback/
  providers/
    xtream/
    m3u/
  storage/
docs/
  superpowers/
    specs/
```

The exact folders can be adjusted during implementation if the scaffold suggests a cleaner convention, but the boundaries should remain.

## Release Process

Use manual local builds uploaded to GitHub Releases in v1.

Expected artifacts:

- macOS: `.dmg` or `.zip`.
- Windows: installer `.exe`.

Release rules:

- Branch names use a type prefix, such as `feature/player-shell`, `bug/fix-m3u-parser`, or `ci/release-build`.
- Commits use Conventional Commits, such as `feat: scaffold desktop player` or `docs: add IPTV player design spec`.
- Version tags use semantic versioning, such as `v0.1.0`.
- Release notes should summarize user-visible changes, known limitations, and test coverage.

Signing, notarization, automated GitHub Actions releases, and auto-update are future enhancements.

## Testing Strategy

Test the highest-risk logic first.

Unit tests:

- M3U parsing.
- Xtream response mapping.
- Catalog normalization.
- Stream URL resolution.
- EPG mapping where available.
- Error mapping.

Storage tests:

- Insert/update catalog entities.
- Preserve favorites across refresh.
- Preserve watch progress across refresh.
- Mark missing items stale.
- Query search/filter results.

Playback service tests:

- mpv command construction.
- IPC message formatting.
- Playback state event mapping.
- External player launch command construction.
- Sanitized diagnostics.

Renderer tests:

- Main navigation.
- Search and filters.
- Provider setup form validation.
- Empty/error/loading states.
- Player controls state.

Manual verification:

- Import a legal/sample M3U playlist.
- Import a test Xtream-like fixture or mocked provider.
- Play a legal HLS stream.
- Play a local media file through mpv for baseline playback.
- Verify external player fallback.
- Build macOS artifact locally.
- Build Windows artifact locally when on Windows.

## Implementation Order

Recommended implementation sequence:

1. Scaffold Electron, React, TypeScript, Vite, linting, tests, and packaging scripts.
2. Add typed IPC and app shell navigation.
3. Add SQLite storage schema and repositories.
4. Add M3U adapter and sample import flow.
5. Add Xtream adapter and account setup flow.
6. Add normalized catalog views: Live TV, Movies, Series.
7. Add search, categories, favorites, recently watched, and progress.
8. Add managed mpv playback service.
9. Add playback UI and external fallback.
10. Add error handling, diagnostics, and release build checklist.

## References Checked

- mpv manual: https://mpv.io/manual/stable/
- Electron BrowserWindow docs: https://www.electronjs.org/docs/latest/api/browser-window/
- electron-builder docs: https://www.electron.build/docs/
- Flutter desktop docs considered during stack comparison: https://docs.flutter.dev/platform-integration/desktop
- media_kit docs considered during stack comparison: https://pub.dev/documentation/media_kit/latest/
