# In-App Playback Engine Design

## Goal

Vela should feel like one desktop app. Playback should start inside the Vela window whenever the stream can be handled by Chromium plus browser-side transmuxing, and fallback playback should be internal plumbing rather than a user-facing choice.

## Local Playlist Findings

The currently imported provider is Xtream-based. Its live catalog is entirely MPEG-TS (`.ts`), which is suitable for an in-app `mpegts.js` path when the video/audio codecs are browser-decodable. The VOD catalog is mostly MKV, with a large amount of HEVC/EAC3/subtitle-heavy content that Chromium cannot reliably play through a normal `<video>` element.

## Playback Routing

- HLS (`.m3u8`) routes to `hls.js`.
- MPEG-TS (`.ts`, live Xtream `/live/` streams) routes to `mpegts.js`.
- Browser-safe direct files (`.mp4`, `.m4v`, common native paths) route to native `<video>`.
- MKV and AVI route to the fallback decoder path.
- If an in-app engine errors, Vela starts the fallback path automatically.

## User Experience

The UI always starts from the same Play action. In-app playback opens a full-window cinema surface with Vela controls. The user is not asked to choose an engine, and the app does not describe engine details in normal playback.

## Current Limitation

The fallback path still uses the existing mpv controller. This is necessary for this playlist's MKV/HEVC-heavy VOD catalog until we implement a deeper embedded decoder path. The next architecture step is to embed a decoder surface rather than exposing a separate fallback player window.
