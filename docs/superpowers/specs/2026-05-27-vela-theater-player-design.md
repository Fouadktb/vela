# Vela Theater Player Design

## Goal

Vela should have one playback experience. Users should not see or choose between browser playback, mpv playback, fallback playback, or external playback for normal use. Clicking Play opens a single Vela Theater surface with Vela controls.

## Decision

Use mpv as the only normal playback backend. The user's playlist contains many MKV/HEVC movies and episodes, so Chromium-only playback would knowingly fail on a large part of the catalog. mpv gives the required container and codec coverage across macOS and Windows.

## Experience

Playback opens a dedicated fullscreen theater surface:

- mpv renders video fullscreen with its own OSC and OSD disabled.
- A transparent Vela overlay window sits above the video.
- React renders the title, progress, play/pause, stop, 10-second seek, audio, and subtitle controls.
- Double-clicking or double-tapping the left or right side of the theater surface seeks backward or forward 10 seconds for seekable content.
- Pressing Escape stops playback.

This is still implemented with mpv as a separate native process under the hood, but the user-facing model is one Vela player.

## Non-Goals

- No browser HLS/MPEG-TS/native playback path.
- No visible mpv OSC.
- No user-facing fallback selector.
- No attempt to embed mpv into the Electron DOM on macOS. A local proof showed `mpv --wid` accepts Electron's native handle, but macOS still behaves like a separate Cocoa video surface rather than a reliable child view.

## Verification

The release gate is `pnpm build`, `pnpm check:mpv`, an Electron launch smoke test, and manual playback testing against live, movie, and episode items from the real provider.
