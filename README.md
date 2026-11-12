# Vela

Vela supports macOS and Windows desktop apps only. The app uses Flutter with an embedded `media_kit` video surface, local catalog storage, provider import, and watch continuity.

The repository is public so installed builds can check GitHub Releases for newer versions without authentication. Vela does not auto-update and is not code-signed; when an update is available, the app opens the release page and the user downloads and installs the new build manually.

There are no browser, phone, or TV app targets in this repository. The supported apps share one Flutter implementation and retain native `media_kit` playback.

## Flutter Setup

Install Flutter 3.44.0 (the version used by CI), then enable the platforms you need:

```bash
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter pub get
```

## Local Development

Run the macOS desktop app from the repository root:

```bash
flutter run -d macos
```

Format and analyze the Flutter app:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Local Builds

Build the macOS app:

```bash
flutter build macos
```

Create a macOS DMG for GitHub upload:

```bash
scripts/package-macos.sh
```

Build the Windows app on Windows:

```powershell
flutter build windows
```

Create a Windows installer for GitHub upload on Windows. This requires Inno Setup 6:

```powershell
winget install JRSoftware.InnoSetup
.\scripts\package-windows.ps1
```

Or run the manual `Build Windows Installer` GitHub workflow. It builds on a Windows runner and uploads `vela-windows-vX.Y.Z-setup.exe` as a workflow artifact.

## Manual Updates And Release Upload

Flutter desktop apps are built on the target operating system. Build macOS on macOS, build Windows on Windows or the manual GitHub workflow, then upload the artifacts to the GitHub Release.

The app checks `https://api.github.com/repos/Fouadktb/vela/releases/latest`. Keep release tags aligned with `pubspec.yaml` using `vX.Y.Z`; otherwise installed apps cannot compare versions correctly.

Expected release assets:

- `vela-macos-vX.Y.Z.dmg`
- `vela-windows-vX.Y.Z-setup.exe`
- `SHA256SUMS-vX.Y.Z.txt`

Example upload:

```bash
gh release upload vX.Y.Z release/vela-macos-vX.Y.Z.dmg release/SHA256SUMS-vX.Y.Z.txt --clobber
```

Code signing, notarization, and automatic updates are intentionally out of scope. Users will see OS warnings for unsigned builds and install updates manually from GitHub Releases.

## Playback preferences and import performance

Volume and mute are saved globally in the app settings database, including the
last audible level used when unmuting. Playback restores the saved level before
opening a stream, and closing playback flushes pending changes.

M3U imports use a set to track series catalog entries, avoiding repeated scans of
the growing catalog. XMLTV imports filter by the requested time window before
decoding programme descriptions. Run the repeatable parser benchmark with:

```bash
dart run scripts/benchmark_m3u.dart
```

The app remains Flutter/Dart. A Rust migration requires a separately validated
native playback, storage migration, and macOS/Windows packaging path; these
performance fixes do not introduce a second implementation.

Desktop checks build both supported targets in GitHub Actions on every push to
`main` and on pull requests.
