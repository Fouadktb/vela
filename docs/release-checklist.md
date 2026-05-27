# Release Checklist

Use this checklist for every local Vela release candidate before creating a GitHub Release.

## Versioning

- Confirm the target release version and update `pubspec.yaml`.
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
- Confirm `release/vela-macos.zip` is ready for GitHub upload.
- On Windows, run `scripts/package-windows.ps1`.
- Confirm `release/vela-windows/vela.exe` launches locally.
- Confirm `release/vela-windows.zip` is ready for GitHub upload.
- Keep installer and DMG polish separate until the playable Flutter app is validated on both macOS and Windows.

## GitHub Release Upload

- For cross-platform artifact builds, run the `Build Vela Artifacts` workflow manually from GitHub Actions.
- Download `vela-macos.zip` and `vela-windows.zip` from the workflow artifacts when both jobs pass.
- Create or push the release tag after local verification passes.
- Confirm the tag workflow creates the GitHub Release automatically.
- Include verification notes, supported platforms, and known limitations in the release body.
- Download the uploaded artifacts from GitHub and confirm the files match the local release output.
