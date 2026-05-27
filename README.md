# Vela

Vela is a desktop IPTV player for macOS and Windows. The app uses Flutter with an embedded `media_kit` video surface, local catalog storage, provider import, and watch continuity.

The repository is public so installed builds can check GitHub Releases for newer versions without authentication. Vela does not auto-update and is not code-signed; when an update is available, the app opens the release page and the user downloads and installs the new build manually.

## Flutter Setup

Install the Flutter desktop toolchain, then enable the platforms you need:

```bash
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter pub get
```

On this development machine, use the bundled Flutter SDK:

```bash
PATH="$HOME/.codex/toolchains/flutter/bin:$PATH" flutter pub get
```

## Local Development

Run the macOS desktop app from the repository root:

```bash
PATH="$HOME/.codex/toolchains/flutter/bin:$PATH" flutter run -d macos
```

Format and analyze the Flutter app:

```bash
PATH="$HOME/.codex/toolchains/flutter/bin:$PATH" dart format --set-exit-if-changed .
PATH="$HOME/.codex/toolchains/flutter/bin:$PATH" flutter analyze
```

## Local Builds

Build the macOS app:

```bash
PATH="$HOME/.codex/toolchains/flutter/bin:$PATH" flutter build macos
```

Create a macOS DMG for GitHub upload:

```bash
PATH="$HOME/.codex/toolchains/flutter/bin:$PATH" scripts/package-macos.sh
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
