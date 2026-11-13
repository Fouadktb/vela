# Native playback runtime provenance and notices

Vela dynamically loads libmpv. The downloaded native runtime is separate from
Vela's Rust sources. `runtime-lock.json` pins every downloaded binary archive by
SHA256; packaging rejects an archive that does not match. The final package
contains the runtime manifest and this notices directory.

## macOS

The universal `video-default` frameworks come from media-kit/libmpv-darwin-build
[v0.6.0](https://github.com/media-kit/libmpv-darwin-build/releases/tag/v0.6.0).
The upstream distribution's original license is included as
`licenses/media-kit-darwin-LICENSE.txt`. This is the default playback flavor,
not the GPL encoders flavor.

Exact component source URLs and SHA256 values are preserved in
`licenses/darwin-downloads.lock`. The complete corresponding build recipes,
patches, and source configuration are available in the
[v0.6.0 build repository](https://github.com/media-kit/libmpv-darwin-build/tree/v0.6.0).
The runtime includes mpv 0.36.0, FFmpeg 6.0, libass, dav1d, FreeType, FriBidi,
HarfBuzz, Mbed TLS, uchardet, libxml2, and libpng. The packager computes the
transitive framework dependency closure from Mpv and excludes unrelated build
products, headers, and developer libraries.

## Windows

The x86_64 DLL comes from media-kit/libmpv-win32-video-build's
[2023-09-24 release](https://github.com/media-kit/libmpv-win32-video-build/releases/tag/2023-09-24),
the same runtime used by the previous Windows application. Upstream identifies
[mpv revision 652a1dd90711839acdccc08004056d25514ef2d8](https://github.com/mpv-player/mpv/tree/652a1dd90711839acdccc08004056d25514ef2d8).
The archive contains the DLL and development headers, with no license-notices
file or complete component source/build manifest. This repository preserves
that provenance gap explicitly; these notices do not claim a completed audit
of every statically linked Windows component.

Only `libmpv-2.dll` is installed. The Rust renderer uses native WGL/OpenGL and
`hwdec=auto-copy`; ANGLE and SwiftShader DLLs are unnecessary. Hardware decode
can copy decoded frames back to system memory; software decode remains the
fallback. Direct D3D11-to-OpenGL/ANGLE zero-copy decode is not promised.

## Source and license availability

mpv's LGPL 2.1 and GPL 2 license texts, FFmpeg's license notice, LGPL 3 text,
and component notices are included in `licenses/`. These texts retain their
upstream terms; bundling a text does not assert that every optional GPL
component is enabled. Follow the linked component source revisions and build
configuration when modifying or redistributing the runtime.

The Windows archive predates the Rust rebuild and should be refreshed only
with a replacement that passes the real libmpv and embedded-render tests.
No runtime binary is committed to this repository.

## Rust dependencies and bundled fonts

Packaging runs `notices.py` against the locked Cargo metadata for the package's
actual platform targets. `licenses/CARGO_NOTICES.txt` and
`licenses/cargo-notices.json` record each resolved third-party package name,
version, source, declared license expression, and the original license/notice
files available in its cached source. Original notice files are copied under
`licenses/cargo/`; `licenses/Cargo.lock` preserves the dependency provenance.
Missing upstream crate notice files are recorded explicitly.

All license text files beside the embedded fonts are copied to `licenses/fonts/`,
including Roboto, Lucide, LucideFlutter, and Noto Naskh Arabic notices. The font
source/readme is copied alongside them.
