# Android TV design

## Goal

Add Android TV as the next Vela target while keeping one shared product codebase. The first release should produce a sideloadable APK from GitHub that friends can install on Android TV devices for testing.

## Product scope

- Android TV is part of Vela, not a separate app name or fork.
- The first Android TV build supports Xtream Codes and M3U URL providers.
- Provider setup uses TV remote input only in the first version.
- The provider setup flow must be structured so a future QR/import-code flow can replace or sit beside remote input without changing provider storage.
- Local file import is hidden on Android TV until core provider import, catalog navigation, and playback are reliable.
- Google Play compatibility is considered in manifest and UX decisions, but the first distribution path is GitHub APK sideloading.

## Architecture

Vela keeps a shared core and adds platform-specific app surfaces where Android TV needs different behavior.

- Shared core: provider models, Xtream/M3U importers, catalog database, watch history, favorites, playback item mapping, update checks, backup/export logic where supported.
- Desktop shell: current hover/click desktop layout remains the default for macOS and Windows.
- TV shell: a new remote-first shell is selected on Android. It uses the same catalog data and playback controller concepts, but presents focusable rows, larger controls, and D-pad-safe navigation.
- Platform adapters: startup, fullscreen, local file picking, and external release asset selection move behind platform-safe helpers instead of direct desktop assumptions.

The Android scaffold is added with `flutter create --platforms=android .` and then customized for TV.

## Android TV platform setup

The Android manifest must make Vela visible and usable on Android TV:

- Declare internet access.
- Declare `android.software.leanback`.
- Declare touchscreen as not required.
- Add a `LEANBACK_LAUNCHER` entry point.
- Lock the activity to landscape.
- Add TV launcher banner and icon resources.
- Avoid declaring touch support metadata.

Release output for testing is a release APK asset uploaded to GitHub, named like `vela-android-tv-v0.5.0.apk`. Android APKs must be signed, so Vela should use a free self-signed Android release key for repeatable sideload updates. This is separate from paid desktop code signing. A Play Store/AAB path can be added later once the APK flow is proven.

## Playback

Playback stays in-app with `media_kit`. The existing dependency set already resolves Android media-kit video libraries, so the first implementation should validate the current player on Android TV before considering a native Android player.

Android TV fullscreen cannot use `window_manager`. Desktop fullscreen remains in the desktop adapter. Android TV uses Flutter/system immersive mode and route-level fullscreen behavior.

Remote playback controls:

- Select toggles overlay controls or activates the focused control.
- Back first hides controls or recent/live menus, then exits the player.
- Left/right seek for movies and episodes only.
- Up/down move focus through controls, track menus, recent live channels, and episode rail.
- Long-press/held actions are optional for the first APK unless they work reliably on Android TV remotes.
- Audio, subtitle, and video track pickers stay available when the stream exposes tracks.

## TV catalog UX

The TV UI should not reuse desktop hover behavior. It needs a 10-foot, D-pad-first layout:

- Large readable typography and visible focus rings.
- Rows or rails for categories and content.
- Category names can wrap and must remain readable.
- Every visible action must be reachable using up, down, left, right, select, and back.
- Search is available but optimized for remote text input.
- Settings and provider management remain reachable without requiring a playlist, but catalog sections stay disabled until a provider import succeeds.

The desktop app already has useful catalog concepts, but TV should render them in a layout that prioritizes directional focus instead of mouse efficiency.

## Provider setup

The first setup screen uses remote-friendly fields for:

- Provider name.
- Xtream server URL, username, password.
- M3U URL.
- Auto-refresh interval select.

The form writes through the same provider repository as desktop. Import unlocks the app only after provider save and catalog import succeed. Partial or failed imports show step-level progress and clear errors.

Future QR setup should attach at the form boundary. The expected later shape is: TV displays a short pairing code, a phone/desktop page submits provider credentials, and the TV imports through the same repository/import service.

## Updates and distribution

The app update checker continues to read GitHub Releases. On Android TV it should prefer Android APK assets and show manual download/install guidance. Automatic app updates are out of scope because the app is not signed for store distribution and is installed manually.

Release scripts should eventually produce:

- macOS DMG.
- Windows installer.
- Android TV APK.
- SHA256 checksums.

The first implementation can add a local Android build command and document manual GitHub upload if fully automated release scripting would slow down the TV prototype.

## Error handling

Android TV errors must be readable from a couch distance:

- Provider import failures show the failing step, HTTP status when available, and whether saved provider data was kept.
- Playback failures show a concise message and a Back action.
- Unsupported local file import is hidden instead of shown as a disabled broken path.
- Missing Android build prerequisites fail with clear script output.

## Verification

Baseline verification:

- `flutter pub get`
- `dart run scripts/verify_version_sync.dart`
- `flutter analyze`

Android TV verification:

- `flutter build apk --release`
- Install APK on an Android TV emulator or physical Android TV.
- Confirm the app appears in the TV launcher.
- Confirm D-pad navigation reaches provider setup, catalog sections, settings, and player controls.
- Import an Xtream provider and confirm live, movie, and series catalog access.
- Play one live channel and one movie/episode.
- Confirm Back behavior exits player without quitting the app.
- Confirm desktop macOS and Windows builds still analyze after platform-safe refactors.

## References

- Android TV navigation: https://developer.android.com/training/tv/get-started/navigation
- Android TV setup and Leanback manifest: https://developer.android.com/training/tv/start/start.html
- Android TV quality guidelines: https://developer.android.com/docs/quality-guidelines/tv-app-quality
- media_kit platform support: https://github.com/media-kit/media-kit
