# Release Checklist

Use this checklist for every local release candidate before creating a GitHub Release.

## Versioning

- Confirm the target release version and update `package.json`.
- Keep version tags aligned with the app version, using `vX.Y.Z`.
- Review user-facing changes and note anything that should be included in release notes.
- Confirm the working tree contains only intended release changes before tagging.

## Verification

- Run `pnpm typecheck`.
- Run `pnpm test`.
- Run `pnpm check:mpv`.
- Run `pnpm build`.
- Import a known legal sample M3U playlist.
- Confirm the imported playlist appears in the live catalog.
- Start playback for a legal sample stream.
- Confirm the embedded player controls respond.
- Confirm the external player fallback opens the current stream when embedded playback is unavailable.

## Local Builds

- On macOS, run `pnpm build:mac`.
- Install the macOS artifact locally and confirm the app launches.
- On Windows, run `pnpm build:win`.
- Install the Windows artifact locally and confirm the app launches.
- Check that generated artifacts are written under `release/`.

## GitHub Release

- Create or push the release tag after local verification passes.
- Create a GitHub Release for the tag.
- Upload release artifacts manually from `release/`.
- Include verification notes, supported platforms, and known limitations in the release body.
- Download the uploaded artifacts from GitHub and confirm the files match the local release output.
