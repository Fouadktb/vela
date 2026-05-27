# Vela Flutter MediaKit Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current Electron/mpv player architecture with a Flutter desktop Vela app that uses one embedded `media_kit` playback surface for macOS and Windows.

**Architecture:** Flutter owns the app shell, catalog UI, settings, and playback route. `media_kit` owns decoding and media state through an embedded Flutter video widget, while Riverpod coordinates application state and Drift persists the local IPTV catalog. The existing Electron implementation is reference material only until the Flutter app reaches parity.

**Tech Stack:** Flutter desktop, Dart, media_kit, media_kit_video, media_kit_libs_video, flutter_riverpod, Drift/SQLite, http, window_manager, path_provider, file_selector, shared_preferences, lucide_icons_flutter.

---

## Owner Constraints

- Do not add automated tests or test tooling. The owner explicitly asked to remove tests.
- Do not rebuild the Electron overlay/player.
- Do not keep two user-visible playback modes.
- Use Conventional Commits.
- Keep branch naming with a type prefix for new branches.

## Implementation Rules

- Start from a small playback spike before porting catalog scope.
- Commit after each completed task.
- Keep the app name `Vela`.
- Keep the current repo name unless the owner chooses to rename later.
- Prefer deleting obsolete Electron/mpv paths after Flutter parity rather than maintaining both stacks.
- Use `dart format .`, `flutter analyze`, and platform builds as verification.
- Use manual playback checks for user-facing player behavior.

## Source Material To Read First

- Spec: `docs/superpowers/specs/2026-05-27-flutter-media-kit-migration-design.md`
- Existing provider/domain types:
  - `src/shared/catalog/types.ts`
  - `src/shared/providers/types.ts`
  - `src/shared/playback/types.ts`
- Existing import logic:
  - `electron/main/imports/importXtreamProvider.ts`
  - `electron/main/imports/importM3uProvider.ts`
  - `src/providers/m3u/parseM3u.ts`
- Existing catalog UI reference:
  - `src/renderer/app/App.tsx`
  - `src/renderer/styles/global.css`

## Target File Structure

Create the Flutter app at the repository root so normal Flutter commands work from the repo root.

```text
pubspec.yaml
analysis_options.yaml
lib/main.dart
lib/src/app/vela_app.dart
lib/src/app/app_theme.dart
lib/src/app/navigation_controller.dart
lib/src/app/section_state.dart
lib/src/catalog/catalog_database.dart
lib/src/catalog/catalog_database.g.dart
lib/src/catalog/catalog_models.dart
lib/src/catalog/catalog_repository.dart
lib/src/catalog/category_repository.dart
lib/src/catalog/watch_history_repository.dart
lib/src/providers/provider_models.dart
lib/src/providers/provider_repository.dart
lib/src/providers/provider_refresh_service.dart
lib/src/providers/m3u/m3u_parser.dart
lib/src/providers/xtream/xtream_client.dart
lib/src/providers/xtream/xtream_importer.dart
lib/src/playback/playable_item.dart
lib/src/playback/playback_controller.dart
lib/src/playback/player_state.dart
lib/src/playback/track_models.dart
lib/src/playback/vela_player_route.dart
lib/src/playback/vela_player_controls.dart
lib/src/playback/seek_zones.dart
lib/src/shell/vela_shell.dart
lib/src/shell/vela_sidebar.dart
lib/src/shell/section_header.dart
lib/src/features/providers/provider_setup_screen.dart
lib/src/features/settings/settings_screen.dart
lib/src/features/catalog/catalog_screen.dart
lib/src/features/catalog/category_list.dart
lib/src/features/catalog/item_grid.dart
lib/src/features/catalog/detail_panel.dart
lib/src/features/series/episode_rail.dart
lib/src/shared/async_value_view.dart
lib/src/shared/empty_state.dart
lib/src/shared/vela_icons.dart
assets/app_icon/
assets/placeholder/
macos/
windows/
```

After Flutter parity, remove or archive these Electron/mpv paths:

```text
electron/
src/
scripts/check-mpv.js
scripts/prepare-mpv.cjs
scripts/after-pack-mac.cjs
dist/
dist-electron/
vendor/mpv/
electron-builder.yml
vite.config.ts
tsconfig.json
tsconfig.node.json
package.json
pnpm-lock.yaml
```

Do not remove them until Flutter can import providers, browse the catalog, and play streams.

## Task 1: Create The Flutter Desktop Foundation

**Files:**

- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `lib/main.dart`
- Create: `lib/src/app/vela_app.dart`
- Create: `lib/src/app/app_theme.dart`
- Create: `lib/src/shell/vela_shell.dart`
- Create: `lib/src/shell/vela_sidebar.dart`

- [ ] **Step 1: Confirm Flutter toolchain**

Run:

```bash
flutter --version
flutter doctor -v
```

Expected:

- Flutter is installed.
- macOS desktop tooling is available on macOS.
- Windows desktop tooling is checked later on Windows before publishing a Windows release.

- [ ] **Step 2: Scaffold desktop platforms**

Run:

```bash
flutter create --platforms=macos,windows --project-name vela .
```

Expected:

- `macos/`, `windows/`, `lib/main.dart`, and `pubspec.yaml` exist.
- The command does not delete existing Electron files.

- [ ] **Step 3: Replace the generated package metadata**

Set `pubspec.yaml` to use the product name and dependencies:

```yaml
name: vela
description: Vela desktop IPTV player for macOS and Windows.
publish_to: "none"
version: 0.2.0+1

environment:
  sdk: ">=3.9.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  drift: ^2.33.0
  drift_flutter: ^0.3.0
  file_selector: ^1.0.3
  flutter_riverpod: ^3.3.1
  http: ^1.5.0
  intl: ^0.20.2
  lucide_icons_flutter: ^3.1.14+1
  media_kit: ^1.2.6
  media_kit_libs_video: ^1.0.7
  media_kit_video: ^2.0.1
  path: ^1.9.1
  path_provider: ^2.1.5
  shared_preferences: ^2.5.4
  sqlite3_flutter_libs: ^0.6.0
  window_manager: ^0.5.1

dev_dependencies:
  build_runner: ^2.10.4
  drift_dev: ^2.33.0
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/placeholder/
```

- [ ] **Step 4: Remove generated automated test files**

Flutter scaffolding can generate a default widget test. Remove it immediately so the migration stays aligned with the owner constraint:

```bash
rm -rf test
mkdir -p assets/placeholder
touch assets/placeholder/.gitkeep
```

Expected:

- No `test/` directory remains.
- `pubspec.yaml` does not contain `flutter_test`.
- `assets/placeholder/.gitkeep` exists so the asset folder is tracked.

- [ ] **Step 5: Install dependencies**

Run:

```bash
flutter pub get
```

Expected:

- `pubspec.lock` is created.
- Dependency resolution completes.

- [ ] **Step 6: Add lint configuration**

Create `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_single_quotes: true
    sort_child_properties_last: true
    use_key_in_widget_constructors: false
```

- [ ] **Step 7: Create Vela app entry**

Create `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app/vela_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      title: 'Vela',
      minimumSize: Size(1120, 720),
      size: Size(1440, 900),
      center: true,
      backgroundColor: Colors.black,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(const ProviderScope(child: VelaApp()));
}
```

- [ ] **Step 8: Create the app shell**

Create `lib/src/app/vela_app.dart`:

```dart
import 'package:flutter/material.dart';

import '../shell/vela_shell.dart';
import 'app_theme.dart';

class VelaApp extends StatelessWidget {
  const VelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vela',
      debugShowCheckedModeBanner: false,
      theme: buildVelaTheme(),
      home: const VelaShell(),
    );
  }
}
```

Create `lib/src/app/app_theme.dart` with a restrained off-white/dark theme matching the current Vela direction.

Create `lib/src/shell/vela_shell.dart` with a sidebar and placeholder content area for Live, Movies, Series, Favorites, Recently Watched, and Settings.

Create `lib/src/shell/vela_sidebar.dart` with stable icon-only collapsed width and expanded labels.

- [ ] **Step 9: Verify foundation**

Run:

```bash
dart format .
flutter analyze
flutter run -d macos
```

Expected:

- Formatting completes.
- Analyzer reports no issues.
- Vela opens as a Flutter desktop app on macOS.

- [ ] **Step 10: Commit**

Run:

```bash
git add pubspec.yaml pubspec.lock analysis_options.yaml lib macos windows assets
git commit -m "feat: scaffold flutter desktop app"
```

## Task 2: Prove Embedded Playback Before Porting Catalog

**Files:**

- Create: `lib/src/playback/playable_item.dart`
- Create: `lib/src/playback/player_state.dart`
- Create: `lib/src/playback/track_models.dart`
- Create: `lib/src/playback/playback_controller.dart`
- Create: `lib/src/playback/vela_player_route.dart`
- Create: `lib/src/playback/vela_player_controls.dart`
- Create: `lib/src/playback/seek_zones.dart`
- Modify: `lib/src/shell/vela_shell.dart`

- [ ] **Step 1: Define playback models**

Create `PlayableItem` with:

- `id`
- `title`
- `subtitle`
- `streamUrl`
- `kind` as live, movie, or episode
- `posterUrl`
- `channelLogoUrl`
- `seriesId`
- `seasonNumber`
- `episodeNumber`

Create track models for audio, subtitles, and video:

- `id`
- `title`
- `language`
- `isSelected`
- `isExternal`

- [ ] **Step 2: Implement `PlaybackController`**

Use `media_kit.Player` and `VideoController`.

Controller responsibilities:

- create and dispose `Player`
- open a `PlayableItem`
- expose position, duration, buffering, playing, and error state
- expose audio/subtitle/video track lists
- select audio/subtitle/video tracks
- seek relative by 10 seconds
- toggle fullscreen through `window_manager`
- stop playback and return to shell without exiting the app

- [ ] **Step 3: Build the player route**

`VelaPlayerRoute` must:

- render `Video(controller: videoController)` full-bleed
- layer custom Vela controls above it
- auto-hide controls after inactivity
- show buffering and error states without leaving fullscreen
- close with Escape or close button by returning to the previous shell section

- [ ] **Step 4: Build Netflix-style controls**

`VelaPlayerControls` must include:

- title/subtitle metadata
- back button
- play/pause
- 10 second rewind
- 10 second forward
- timeline
- current time / duration
- volume
- audio track menu
- subtitle track menu with Off option
- video track menu
- speed menu
- fullscreen toggle
- next episode button when available

Menus must be lists or popovers with explicit choices, not switches.

- [ ] **Step 5: Build seek zones**

`seek_zones.dart` must detect double-click/double-tap on:

- left half: seek -10 seconds
- right half: seek +10 seconds

The route must display visual seek feedback, such as `-10` or `+10`, for a short duration.

- [ ] **Step 6: Add temporary playback launcher**

Add a developer-only input in the shell where a legal stream/sample URL can be pasted and opened in the player. This launcher is removed or hidden after catalog playback is wired.

- [ ] **Step 7: Manual playback verification**

Run:

```bash
dart format .
flutter analyze
flutter run -d macos
```

Manual checks:

- Open a legal sample stream URL.
- Confirm playback happens inside the Vela window.
- Enter fullscreen and exit fullscreen.
- Close player and confirm Vela remains open.
- Confirm Cmd-Tab shows Vela only.
- Confirm no overlay appears on another monitor.
- Confirm left/right double-click seeks by 10 seconds.
- Confirm audio/subtitle/video menus render when tracks exist.

- [ ] **Step 8: Commit**

Run:

```bash
git add lib pubspec.yaml pubspec.lock
git commit -m "feat: add embedded media kit player"
```

Do not proceed to catalog porting until this task feels good in real use.

## Task 3: Create Drift Catalog Storage

**Files:**

- Create: `lib/src/catalog/catalog_database.dart`
- Create: `lib/src/catalog/catalog_models.dart`
- Create: `lib/src/catalog/catalog_repository.dart`
- Create: `lib/src/catalog/category_repository.dart`
- Create: `lib/src/catalog/watch_history_repository.dart`
- Create generated: `lib/src/catalog/catalog_database.g.dart`

- [ ] **Step 1: Define schema**

Create Drift tables for:

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

Indexes required:

- provider + content type
- provider + category
- normalized title
- favorite lookup
- watch history by last watched date
- series season/episode lookup

- [ ] **Step 2: Create repositories**

Repositories must provide:

- provider CRUD
- replace provider catalog transactionally
- watch live/movie/series category lists
- watch item lists by section and category
- search within active section/category
- toggle item favorite
- toggle category favorite
- reorder categories
- add/update watch history
- resume position lookup

- [ ] **Step 3: Generate Drift code**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
dart format .
flutter analyze
```

Expected:

- `catalog_database.g.dart` is generated.
- Analyzer reports no issues.

- [ ] **Step 4: Commit**

Run:

```bash
git add lib/src/catalog pubspec.yaml pubspec.lock
git commit -m "feat: add flutter catalog database"
```

## Task 4: Port M3U And Xtream Providers

**Files:**

- Create: `lib/src/providers/provider_models.dart`
- Create: `lib/src/providers/provider_repository.dart`
- Create: `lib/src/providers/provider_refresh_service.dart`
- Create: `lib/src/providers/m3u/m3u_parser.dart`
- Create: `lib/src/providers/xtream/xtream_client.dart`
- Create: `lib/src/providers/xtream/xtream_importer.dart`
- Modify: `lib/src/catalog/catalog_repository.dart`

- [ ] **Step 1: Define provider models**

Provider model fields:

- `id`
- `name`
- `type` as xtream, m3uUrl, or m3uFile
- `serverUrl`
- `username`
- `password`
- `m3uUrl`
- `localFilePath`
- `refreshEnabled`
- `refreshIntervalMinutes`
- `lastRefreshAt`
- `nextRefreshAt`
- `lastRefreshStatus`
- `lastRefreshMessage`

- [ ] **Step 2: Port M3U parsing**

Port the existing parser behavior from `src/providers/m3u/parseM3u.ts` to Dart.

Required behavior:

- parse `#EXTINF`
- read tvg id/name/logo/group/title
- keep stream URL
- infer live/movie/series when possible
- preserve unknown groups as categories
- skip malformed entries with an import warning rather than failing the whole provider

- [ ] **Step 3: Implement Xtream client**

Implement endpoints for:

- player API auth/info
- live categories
- live streams
- VOD categories
- VOD streams
- series categories
- series list
- series info for seasons/episodes

Normalize server URL so users can enter with or without trailing slash.

- [ ] **Step 4: Implement refresh service**

Refresh service must:

- refresh one provider manually
- refresh stale providers on app launch
- refresh enabled providers by interval while app is open
- write refresh run status
- replace provider catalog transactionally
- keep old catalog if refresh fails

- [ ] **Step 5: Verify provider import**

Run:

```bash
dart format .
flutter analyze
flutter run -d macos
```

Manual checks:

- Add a legal M3U URL.
- Add a local legal M3U file.
- Add an Xtream provider.
- Confirm live, movie, and series categories are stored separately when provider exposes them.
- Confirm failed refresh leaves the previous catalog available.

- [ ] **Step 6: Commit**

Run:

```bash
git add lib/src/providers lib/src/catalog
git commit -m "feat: add flutter provider import"
```

## Task 5: Port The Vela Catalog UX

**Files:**

- Create: `lib/src/app/navigation_controller.dart`
- Create: `lib/src/app/section_state.dart`
- Create: `lib/src/features/catalog/catalog_screen.dart`
- Create: `lib/src/features/catalog/category_list.dart`
- Create: `lib/src/features/catalog/item_grid.dart`
- Create: `lib/src/features/catalog/detail_panel.dart`
- Create: `lib/src/features/providers/provider_setup_screen.dart`
- Create: `lib/src/features/settings/settings_screen.dart`
- Create: `lib/src/shared/async_value_view.dart`
- Create: `lib/src/shared/empty_state.dart`
- Create: `lib/src/shared/vela_icons.dart`
- Modify: `lib/src/shell/vela_shell.dart`
- Modify: `lib/src/shell/vela_sidebar.dart`

- [ ] **Step 1: Implement top-level navigation state**

Sections:

- live
- movies
- series
- favorites
- recent
- settings

Search/filter/category state must be scoped per section and reset when moving to another top-level section.

- [ ] **Step 2: Build fixed collapsible sidebar**

Requirements:

- fixed while content scrolls
- icon positions remain stable while expanding/collapsing
- hover can expand
- pointer leaving collapses unless the user pinned it
- clicking a section does not leave the sidebar stuck open
- collapsed width gives content predictable left edge

- [ ] **Step 3: Build category list**

Requirements:

- real vertical list, not chips and not a select
- search categories
- favorite categories
- drag or explicit move up/down reorder
- show item count
- include synthetic "All" without hiding real categories

- [ ] **Step 4: Build item grid/list and sticky detail panel**

Requirements:

- item list gets the available horizontal space
- detail panel stays visible while the item list scrolls
- live items show channel logo and EPG summary when available
- movies and series show poster/metadata
- selected item opens playback from the same embedded player route

- [ ] **Step 5: Build provider setup**

Provider setup supports:

- Xtream Codes
- M3U URL
- local M3U file picker
- provider name
- refresh interval
- import progress and error state

- [ ] **Step 6: Build settings**

Settings supports:

- list providers/playlists
- edit provider name and refresh interval
- manual refresh
- delete provider
- clear provider catalog
- clear recently watched
- default audio/subtitle preferences
- app version/build info

- [ ] **Step 7: Verify catalog UX**

Run:

```bash
dart format .
flutter analyze
flutter run -d macos
```

Manual checks:

- Navigate between every section.
- Confirm search and selected category do not leak between sections.
- Collapse/expand sidebar repeatedly and check for icon jumps.
- Scroll catalog and confirm sidebar/detail panel remain fixed.
- Favorite and reorder categories.
- Open settings and manage multiple providers.

- [ ] **Step 8: Commit**

Run:

```bash
git add lib
git commit -m "feat: port vela catalog experience"
```

## Task 6: Add Series Continuity And Watch History

**Files:**

- Create: `lib/src/features/series/episode_rail.dart`
- Modify: `lib/src/playback/vela_player_route.dart`
- Modify: `lib/src/playback/vela_player_controls.dart`
- Modify: `lib/src/catalog/watch_history_repository.dart`
- Modify: `lib/src/catalog/catalog_repository.dart`

- [ ] **Step 1: Persist watch events**

Persist:

- item id
- provider id
- item kind
- title
- poster/logo
- last watched time
- last position
- duration
- completion percentage

- [ ] **Step 2: Resume playback**

For movies and episodes:

- show resume progress in catalog cards
- resume from last position when selected
- allow restart from beginning in the detail panel

- [ ] **Step 3: Add next episode**

For episodes:

- resolve next episode in same season
- if season ends, resolve first episode in next season
- show next episode button in player controls
- show episode rail below player when not fullscreen

- [ ] **Step 4: Verify continuity**

Run:

```bash
dart format .
flutter analyze
flutter run -d macos
```

Manual checks:

- Start an episode, stop, and confirm it appears in Recently Watched.
- Resume an episode.
- Use next episode from player controls.
- Confirm movie resume and restart actions work.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib
git commit -m "feat: add watch history and episode continuity"
```

## Task 7: Replace Release Flow With Flutter Builds

**Files:**

- Modify: `docs/release-checklist.md`
- Create: `scripts/package-macos.sh`
- Create: `scripts/package-windows.ps1`
- Modify: `.gitignore`
- Modify: `README.md` if it exists; otherwise create it.

- [ ] **Step 1: Update release checklist**

Replace Electron/mpv instructions with:

- `flutter pub get`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter build macos`
- `flutter build windows` on Windows
- manual playback checklist
- manual provider import checklist
- GitHub release upload checklist

Remove references to:

- `pnpm test`
- `pnpm check:mpv`
- `prepare:mpv`
- standalone fallback player
- Electron builder artifacts

- [ ] **Step 2: Add local package scripts**

Add macOS packaging script that:

- runs `flutter build macos`
- copies the `.app` into `release/vela-macos/`
- zips the app for GitHub upload

Add Windows packaging script that:

- runs `flutter build windows`
- copies the Release folder into `release/vela-windows/`
- zips it for GitHub upload

Keep installer/DMG polish separate until the playable Flutter app is validated on both operating systems.

- [ ] **Step 3: Verify macOS build**

Run on macOS:

```bash
dart format .
flutter analyze
flutter build macos
```

Manual checks:

- Launch the built app from `build/macos/Build/Products/Release/`.
- Add a provider.
- Play a stream.
- Close the player and confirm the app remains open.

- [ ] **Step 4: Verify Windows build**

Run on Windows:

```powershell
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter build windows
```

Manual checks:

- Launch the built app from `build\windows\x64\runner\Release`.
- Add a provider.
- Play a stream.
- Close the player and confirm the app remains open.

- [ ] **Step 5: Commit**

Run:

```bash
git add docs/release-checklist.md scripts .gitignore README.md
git commit -m "build: switch release flow to flutter"
```

## Task 8: Remove Legacy Electron/mpv Stack After Flutter Parity

**Files:**

- Delete: `electron/`
- Delete: `src/`
- Delete: `electron-builder.yml`
- Delete: `package.json`
- Delete: `pnpm-lock.yaml`
- Delete: `tsconfig.json`
- Delete: `tsconfig.node.json`
- Delete: `vite.config.ts`
- Delete: `vendor/mpv/`
- Delete: `scripts/check-mpv.js`
- Delete: `scripts/prepare-mpv.cjs`
- Delete: `scripts/after-pack-mac.cjs`
- Keep or update: `.gitignore`
- Keep: `docs/`

- [ ] **Step 1: Confirm parity before deletion**

Do not delete legacy files until these are true:

- Flutter imports Xtream providers.
- Flutter imports M3U URL providers.
- Flutter imports local M3U files.
- Live, movies, series, favorites, recent, and settings exist.
- Embedded playback works on macOS.
- Embedded playback works on Windows.
- Track menus exist.
- Closing the player keeps the app open.

- [ ] **Step 2: Delete legacy files**

Use normal git deletion:

```bash
git rm -r electron src vendor/mpv
git rm electron-builder.yml package.json pnpm-lock.yaml tsconfig.json tsconfig.node.json vite.config.ts
git rm scripts/check-mpv.js scripts/prepare-mpv.cjs scripts/after-pack-mac.cjs
```

- [ ] **Step 3: Verify Flutter still builds**

Run:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter build macos
```

- [ ] **Step 4: Commit**

Run:

```bash
git add -A
git commit -m "chore: remove legacy electron player"
```

## Final Review Checklist

Before publishing a GitHub release:

- `flutter analyze` passes on macOS.
- `flutter build macos` passes.
- `flutter build windows` passes on Windows.
- A legal Xtream provider imports successfully.
- A legal M3U URL imports successfully.
- A legal local M3U file imports successfully.
- Live categories show real categories, not only All/Uncategorized.
- Movies and series are available when provider exposes them.
- Favorites work for items and categories.
- Recently watched updates after playback.
- Provider auto-refresh runs when stale.
- Player opens inside Vela.
- Closing player returns to the catalog.
- Cmd-Tab/Alt-Tab shows one Vela app.
- Fullscreen does not leak overlay UI to another monitor.
- Audio, subtitle, and video track menus are real selectors.
- Left/right double-click seek shows visual feedback and seeks by 10 seconds.
- macOS artifact downloads from GitHub and launches locally.
- Windows artifact downloads from GitHub and launches locally.

## Planned Commit Sequence

```text
feat: scaffold flutter desktop app
feat: add embedded media kit player
feat: add flutter catalog database
feat: add flutter provider import
feat: port vela catalog experience
feat: add watch history and episode continuity
build: switch release flow to flutter
chore: remove legacy electron player
```
