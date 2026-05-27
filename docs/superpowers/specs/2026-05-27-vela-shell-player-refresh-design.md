# Vela Shell, Player, and Refresh Design

## Goal

Move the app from a functional IPTV prototype toward a named, daily-use desktop product. This pass covers branding, shell ergonomics, section filter behavior, automatic provider refresh, and a cinematic playback control overlay.

## Product Name

The app name is **Vela**. It should replace generic "IPTV Player" branding in the sidebar, window title, package product name, and release-facing metadata. The existing package id can stay stable for now to avoid breaking installed app data.

## App Shell

The left sidebar defaults to a compact icon rail so the catalog has more horizontal space. On hover or keyboard focus, it expands to show the Vela wordmark and section labels. Navigation remains accessible via button labels and titles, and the active item remains visually obvious in both collapsed and expanded states.

The toolbar gets more breathing room: title and search should not feel crowded, and the search area should align cleanly with the catalog grid. Section changes reset the global search query, selected category, selected item, and category-panel search so filters do not leak between Live TV, Movies, Series, Favorites, and Recently Watched.

## Provider Auto-Refresh

Providers get automatic refresh preferences stored locally:

- `auto_refresh_enabled`, default enabled.
- `auto_refresh_interval_hours`, default 24.
- `last_refresh_at` remains the source of staleness.

On app startup, any enabled provider whose last refresh is missing or older than the interval is refreshed in the background. Settings show the auto-refresh state, interval selector, and manual refresh/delete actions. Refresh errors should surface as inline app status/errors instead of blocking app startup.

## Playback UI

The playback controls become a cinema overlay. The surface is darker and wider, with a bottom gradient, now-playing title, clear status, large primary play/pause, stop, 10-second skip controls, and audio/subtitle menus. VOD playback shows a progress rail and time metadata when duration is available; live streams show a live badge and no fake timeline. Existing double-click/touch skip gestures remain for seekable content.

## Testing

Tests should cover filter reset on section changes, provider auto-refresh calls, refresh preference updates, sidebar/app branding, bundled player path behavior already in place, and the playback menu/overlay controls. Full verification remains `pnpm build`, `pnpm check:mpv`, and an Electron visual smoke pass.
