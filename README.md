# Vela

Vela is a private desktop IPTV player for macOS and Windows. The app is being migrated to Flutter with an embedded `media_kit` video surface, local catalog storage, provider import, and watch continuity.

This repository is intended for private distribution for now. Release artifacts are built by GitHub Actions from version tags and published on GitHub Releases.

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

## GitHub Artifact Builds

The `Build Vela Artifacts` workflow can be run manually from GitHub Actions. It builds native macOS and Windows zips on their matching runners and uploads them as workflow artifacts.

Pushing a version tag such as `v0.2.0` builds both platforms and publishes a GitHub Release with:

- `vela-macos-vX.Y.Z.zip`
- `vela-windows-vX.Y.Z.zip`
- `SHA256SUMS-vX.Y.Z.txt`

Installer and DMG polish is intentionally deferred until the playable Flutter app has been validated on both macOS and Windows.
