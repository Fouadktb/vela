# Rust desktop packaging

Run the platform packager from a machine with the matching native toolchain:

```sh
scripts/package-rust-macos.sh
```

```powershell
.\scripts\package-rust-windows.ps1
```

Both scripts read the version from the Rust workspace, use the locked dependency
set, verify the pinned native-runtime archive SHA256, collect Cargo/font notices,
and run the real libmpv headless integration test against the staged runtime.
The macOS script builds both Apple Silicon and Intel, creates a universal binary,
adds the bundle-relative framework search path, signs each framework and app ad
hoc, and verifies the DMG and the app mounted from it. Windows packaging requires
7-Zip and Inno Setup 6. The installer retains Vela's existing application ID.

Artifacts and platform-specific checksum files are written under `release/`.
The workflow uploads build artifacts; it does not publish a GitHub Release.

## Playback validation

The headless test loads generated WAV audio into the actual packaged libmpv and
checks volume, mute, pause, speed, seeking, resume, track selection, resetting
selection to automatic, and missing-file error reporting:

```sh
cargo test --manifest-path rust/Cargo.toml -p vela-player --test runtime -- --ignored
```

Supply `VELA_MPV_LIBRARY` when running outside the installed app. A test executable
outside a macOS app bundle also needs `DYLD_FRAMEWORK_PATH` pointing to the bundled
framework directory; the installed app uses its own executable-relative rpath.

The framebuffer example checks red upper-half and blue lower-half video pixels,
vertical orientation, and an untouched toolbar in the actual egui framebuffer:

```sh
ffmpeg -f lavfi -i 'color=c=red:s=320x180:r=25,drawbox=x=0:y=90:w=320:h=90:color=blue:t=fill' \
  -t 6 -c:v libx264 -pix_fmt yuv420p /tmp/vela-orientation.mp4
cargo run --manifest-path rust/Cargo.toml -p vela-player --example render_smoke -- /tmp/vela-orientation.mp4
```

This is a native GUI test requiring a working desktop OpenGL 3+ graphics session.
It has been exercised on macOS; the Windows hosted workflow runs the actual
headless libmpv tests and does not claim embedded WGL framebuffer validation.
Adding a Mesa software-GL driver would introduce another binary/runtime toolchain;
that distribution is not part of Vela's packages or CI. Validate the framebuffer
example on Windows with its actual desktop graphics driver before claiming that
platform's embedded rendering has been exercised.

## Notices

`notices.py` reads `cargo metadata --locked --filter-platform` for the package's
architecture targets. It preserves available original crate notices, metadata
expressions and source URLs, the lockfile, and every font license/notice `.txt`.
Missing notice text in an upstream crate is recorded explicitly. Generated
notices are package resources rather than repository-generated build output.
