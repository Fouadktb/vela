# Player feedback pass design

## Goal

Address tester feedback around live playback switching, playback speed gestures, category readability, category sidebar sizing, and Windows fullscreen window chrome.

## Scope

- Live TV player shows a recent-channel rail by default. The user can collapse it and reopen it while staying inside the player.
- Recent live channels come from watch history, are resolved back through the catalog before display, and exclude the current channel.
- Holding Space temporarily plays seekable content at 2x speed. Releasing Space restores the previous speed. Short Space press keeps play/pause behavior. Live streams keep play/pause only.
- Category sidebars in catalog sections are resizable with a drag handle and category names can wrap to multiple lines.
- Windows fullscreen entry must hide the native title bar even when the window was maximized before entering fullscreen.

## Design

The player route remains the owner of playback transitions. A small provider resolves recent live watch-history entries into `PlayableItem` objects, so switching a recent channel can reuse the existing `_openItem` path and keep track preference/progress logic centralized.

The category width is stored in `NavigationController` so it persists while moving between catalog sections. The catalog layout wraps the category list in a resizable pane with min/max constraints. Category rows remove the fixed one-line height and allow up to three lines before truncation.

Fullscreen handling stays inside `PlaybackController`. On Windows, entering fullscreen first unmaximizes a maximized window, then enters fullscreen. When leaving fullscreen, Vela restores the maximized state manually.

## Verification

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter build macos`
- Manual smoke: open a live channel, confirm recent rail is visible/collapsible, switch to a recent channel, hold/release Space on a movie/episode, resize the category sidebar, and confirm category names wrap.
