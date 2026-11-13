# Release Checklist

Use this checklist for every Vela release candidate before tagging or publishing.
The native desktop app is the only application implementation in this tree
and targets macOS and Windows desktop only. The legacy visual and migration
reference is [commit 2829911](https://github.com/Fouadktb/vela/tree/2829911a167bdc8e185c3b62938c1f94b53f295e). Source cutover does not waive these release gates.

## Version and source

- Confirm the native version in `rust/Cargo.toml` and use the matching `vX.Y.Z` tag.
- Confirm native app About/version text and package metadata derive from the same version.
- Confirm the working tree contains only intended changes, review the final diff, and use Conventional Commits.
- Do not publish a release while required checks or native platform verification remain incomplete.

## Rust verification

Run from the repository root:

```bash
cargo fmt --manifest-path rust/Cargo.toml --all -- --check
cargo clippy --manifest-path rust/Cargo.toml --locked --workspace --all-targets -- -D warnings
cargo test --manifest-path rust/Cargo.toml --locked --workspace
cargo run --manifest-path rust/Cargo.toml --locked --release -p vela-core --example benchmark_import
```

- Confirm both macOS and Windows jobs in the Rust Desktop workflow pass on the release commit.
- Record benchmark machine, build profile, input size, and reported parser/import/search timings; compare identical inputs and conditions when assessing regressions.
- Confirm benchmark row-count, page-bound, integrity, and foreign-key checks pass and temporary data is removed.
- With the packaged runtime selected, run `cargo test --manifest-path rust/Cargo.toml --locked -p vela-player --test runtime -- --ignored` on each OS.
- Treat the headless runtime test as one check; also verify real embedded GPU video in the installed app.

## Preserve the existing visual design

- Compare the archived Flutter reference from commit `2829911` and native app at the same window dimensions, display scale, and representative library state.
- Confirm the same charcoal/gold palette, Roboto typography, Lucide icons, Vela logo, card borders, and 8px radii.
- Confirm collapsed/expanded sidebar behavior and original navigation order: Home, Live, Movies, Series, Favorites, Recent, Settings.
- Confirm the original home composition, catalog category column, selection/detail areas, guide, provider setup, settings, and player controls remain recognizable and usable.
- Check narrow and wide desktop windows, scrolling, keyboard focus, hover/selected/disabled states, and text clipping on both OSes.
- Confirm there are no new browser, phone, TV, or Apple TV app targets.

## Migration and user data

- Start with an isolated `VELA_DATA_DIR` and a copy of a representative Flutter catalog; never use the only installed database for destructive testing.
- Verify automatic discovery of Documents and the macOS sandbox container; verify explicit selection when multiple catalogs exist.
- Confirm original database bytes remain unchanged and the native copy includes committed WAL contents.
- Verify supported older schema upgrades happen in the copy; corrupt, ambiguous, incompatible, and newer schemas must stop with a useful recovery choice.
- Check providers and credentials, stable item/category/episode IDs, favorites, category ordering, history, positions, volume/mute, and track preferences after migration and restart.
- Run the actual Flutter SQLite fixture and Dart parser identity tests; keep fixture provenance when updating them.
- Confirm native data and the original Flutter catalog remain independent after first adoption.
- Export a complete SQLite backup and verify its integrity and contents. Confirm users are told it includes credentials and URLs, and an existing backup is not overwritten.

## Provider import and catalog

- Import a known legal sample M3U file and remote playlist; verify live/movie/series classification, categories, artwork, episode grouping, and persistent results.
- Import a known legal Xtream account when credentials are available; verify account rejection, all catalog sections, episode details, movie metadata, and generated-M3U fallback on HTTP rejection.
- Verify provider add/edit/remove, enable/disable, refresh status, and configured refresh intervals.
- Check search across content types, category filtering, favorite items/categories, category ordering, and pagination with a large catalog.
- Verify XMLTV current/upcoming programmes, aliases, timestamps, escaped text, and compressed feeds; confirm refresh failures retain a usable prior guide.
- Exercise unreachable servers, timeouts, oversized data, malformed input, and retry. Errors and exported diagnostics must not expose account details or private stream URLs.
- Confirm the UI continues responding while imports, artwork fetches, database work, and failed network requests run.

## Playback and continuity

- Launch the installed app and play legal HLS/TS live samples and representative MP4/MKV movies/episodes with available audio/subtitle formats.
- Confirm video is embedded in Vela; test play/pause, seeking, live switching, retry, speed, fullscreen, resizing, and keyboard shortcuts.
- Verify audio/subtitle/video choices, global defaults, per-item overrides, and persistence across restart. Opening a different item must reset track selection before applying its preferences.
- Change volume and mute, close/reopen playback, switch items, then restart; verify the saved level and last audible unmute level.
- Verify movie and scoped episode resume positions, continue-watching state, completion, history, and next-episode behavior.
- Close the player and keep browsing; close the app during playback and verify pending progress/preferences are persisted without a hang.
- Test sleep/wake, network loss/recovery, missing streams, and unsupported media errors.
- Measure representative HD/4K playback CPU, memory, dropped frames, and responsiveness on both OSes. Windows currently uses native WGL with copy-back hardware decoding; do not claim zero-copy acceleration.

## Packages and runtime

- On macOS, run `scripts/package-rust-macos.sh`; confirm the universal app contains both arm64/x86_64 code and its complete framework dependency closure.
- Mount `release/vela-macos-vX.Y.Z.dmg`; verify `Vela.app`, the Applications shortcut, signatures, launch, and embedded playback from the mounted/installed package.
- On Windows, run `scripts/package-rust-windows.ps1` with Inno Setup 6 and 7-Zip installed.
- Install `release/vela-windows-vX.Y.Z-setup.exe`; verify Program Files installation, Start menu/optional desktop shortcuts, first launch, and playback on a clean machine.
- Verify upgrading the previous Flutter install uses the same app/installer identity, removes obsolete runtime files, and preserves the separate user catalogs.
- Verify packages work without Flutter, Rust, developer-installed libmpv, or build-directory paths on the destination machine.
- Confirm pinned archive hashes, runtime manifests, source provenance, and font/native library license notices are included. Review the documented Windows runtime provenance gap before release; bundled license text alone does not complete that review.
- Document actual signing status. Current macOS ad hoc signatures do not provide Developer ID trust or notarization; Windows publisher signing is not configured.

## Publish manually

- Confirm the repository and latest-release endpoint are accessible for update checks.
- Verify the final artifacts and `SHA256SUMS-macos-vX.Y.Z.txt` / `SHA256SUMS-windows-vX.Y.Z.txt` match the release commit and version.
- Create/push the release tag only after the gates above pass.
- Create the GitHub Release and upload both native installers and checksum files manually.
- Include validation notes, supported desktop platforms, migration behavior, and remaining known limitations.
- Download the published artifacts and verify their checksums and installation again.
- Verify older and native Vela builds detect the release and open its download page. Automatic installation remains out of scope.
