# Release Checklist

Use this checklist for every local Vela release candidate before creating a GitHub Release.

## Versioning

- Confirm the target release version and update `pubspec.yaml`.
- Update `lib/src/app/app_version.dart` to the same version and build number.
- Keep version tags aligned with the app version, using `vX.Y.Z`.
- Confirm release commits use Conventional Commits.
- Review user-facing changes and note anything that should be included in release notes.
- Confirm the working tree contains only intended release changes before tagging.

## Flutter Verification

- Run `flutter pub get`.
- Run `dart format --set-exit-if-changed .`.
- Run `flutter analyze`.
- On macOS, run `flutter build macos`.
- On Windows, run `flutter build windows`.

## Manual Provider Import Checks

- Import a known legal sample M3U provider.
- Confirm the imported provider appears in the catalog.
- Import a known legal Xtream provider, when credentials are available.
- Confirm live channels, movies, and series appear in their expected sections.
- Restart Vela and confirm imported provider data is still available.

## Manual Playback Checks

- Launch the built app from the platform build output.
- Start playback for a known legal sample stream.
- Confirm video renders inside the Vela player.
- Confirm play, pause, seek, and volume controls respond.
- Close the player and confirm the app remains open.
- Relaunch Vela and confirm watch continuity resumes from the expected item.

## Local Packages

- On macOS, run `scripts/package-macos.sh`.
- Confirm `release/vela-macos/Vela.app` launches locally.
- Mount `release/vela-macos.dmg` and confirm it contains `Vela.app` plus an `Applications` shortcut.
- Confirm `release/vela-macos.dmg` is ready for GitHub upload.
- On Windows, run `scripts/package-windows.ps1`.
- Confirm `release/vela-windows/vela.exe` launches locally.
- Run the generated `release/vela-windows-vX.Y.Z-setup.exe` installer.
- Confirm Vela launches from the installed Start menu shortcut.
- Confirm `release/vela-windows-vX.Y.Z-setup.exe` is ready for GitHub upload.
- If no Windows machine is available, run the manual `Build Windows Installer` GitHub workflow for the release tag and download its installer artifact.
- Confirm the Windows installer targets `Program Files` and prompts for admin access.

## GitHub Release Upload

- Confirm the repository is public so Vela can check GitHub Releases without authentication.
- Rename local packages to include the release tag, for example `vela-macos-vX.Y.Z.dmg` and `vela-windows-vX.Y.Z-setup.exe`.
- Generate `SHA256SUMS-vX.Y.Z.txt` from the release artifacts.
- Create or push the release tag after local verification passes.
- Create the GitHub Release manually.
- Upload the platform artifacts and checksum file manually with `gh release upload` or the GitHub UI.
- Include verification notes, supported platforms, and known limitations in the release body.
- Download the uploaded artifacts from GitHub and confirm the files match the local release output.
- Code signing, notarization, and automatic updates are intentionally out of scope. Users update manually from GitHub Releases.
