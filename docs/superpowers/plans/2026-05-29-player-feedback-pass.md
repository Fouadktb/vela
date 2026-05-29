# Player Feedback Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement tester feedback for live player recent channels, Space hold 2x playback, resizable readable category sidebars, and Windows fullscreen chrome.

**Architecture:** Add a focused recent-live-channel resolver in playback, keep player switching inside `VelaPlayerRoute`, persist category sidebar width in `NavigationController`, and fix Windows fullscreen entry in `PlaybackController`.

**Tech Stack:** Flutter desktop, Riverpod, Drift catalog/watch-history repositories, `media_kit`, `window_manager`.

---

### Task 1: Recent Live Channel Rail

**Files:**
- Create: `lib/src/playback/recent_live_channels.dart`
- Modify: `lib/src/playback/vela_player_route.dart`
- Modify: `lib/src/playback/vela_player_controls.dart`

- [ ] Create a `recentLiveChannelsProvider` that watches live watch-history rows, resolves each row through `CatalogRepository.getItem`, resolves stream URLs, converts valid rows to `PlayableItem`, excludes the current live key, and limits results.
- [ ] Add route state for current live key and rail expansion.
- [ ] Pass recent live channels into controls and switch selected channels via the existing `_openItem` path.
- [ ] Render a persistent, collapsible rail for live playback.

### Task 2: Space Hold 2x

**Files:**
- Modify: `lib/src/playback/vela_player_route.dart`

- [ ] Split key handling into Space down/up behavior.
- [ ] Start a short hold timer on Space down.
- [ ] On hold, set seekable non-live playback to 2x and remember the previous speed.
- [ ] On Space up, restore speed if hold activated, otherwise toggle play/pause.

### Task 3: Resizable Category Sidebar

**Files:**
- Modify: `lib/src/app/navigation_controller.dart`
- Modify: `lib/src/features/catalog/catalog_screen.dart`
- Modify: `lib/src/features/catalog/category_list.dart`

- [ ] Add category sidebar width state and setter with min/max clamping.
- [ ] Wrap `CategoryList` in a resizable pane with a draggable divider.
- [ ] Allow category labels to wrap to three lines with variable row height.

### Task 4: Windows Fullscreen Chrome

**Files:**
- Modify: `lib/src/playback/playback_controller.dart`

- [ ] Track whether the window was maximized before fullscreen.
- [ ] On Windows, unmaximize before entering fullscreen.
- [ ] Restore maximized state after exiting fullscreen.

### Task 5: Verification

- [ ] Run `dart format --set-exit-if-changed .`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter build macos`.
- [ ] Start the app for manual testing.
