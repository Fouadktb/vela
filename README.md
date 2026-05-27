# Vela

Vela is a private desktop IPTV player for macOS and Windows. The app is being migrated to Flutter with an embedded `media_kit` video surface, local catalog storage, provider import, and watch continuity.

This repository is intended for private distribution for now. Release artifacts are built locally on each target operating system and uploaded manually to GitHub Releases.

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

Create a macOS zip for GitHub upload:

```bash
PATH="$HOME/.codex/toolchains/flutter/bin:$PATH" scripts/package-macos.sh
```

Build the Windows app on Windows:

```powershell
flutter build windows
```

Create a Windows zip for GitHub upload on Windows:

```powershell
.\scripts\package-windows.ps1
```

## Manual Release Upload

Flutter desktop apps are built on the target operating system. Build macOS on macOS, build Windows on Windows, then upload the zips to the GitHub Release.

Expected release assets:

- `vela-macos-vX.Y.Z.zip`
- `vela-windows-vX.Y.Z.zip`
- `SHA256SUMS-vX.Y.Z.txt`

Example upload:

```bash
gh release upload vX.Y.Z release/vela-macos-vX.Y.Z.zip release/SHA256SUMS-vX.Y.Z.txt --clobber
```

Installer and DMG polish is intentionally deferred until the playable Flutter app has been validated on both macOS and Windows.
