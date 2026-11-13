#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${HOME}/.cargo/bin:${PATH}"
export MACOSX_DEPLOYMENT_TARGET=11.0
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
cd "${ROOT_DIR}"
VERSION="$(cargo metadata --locked --no-deps --format-version 1 --manifest-path rust/Cargo.toml | python3 -c 'import json,sys; print(next(p["version"] for p in json.load(sys.stdin)["packages"] if p["name"] == "vela-desktop"))')"
RELEASE_ROOT="${ROOT_DIR}/release"
PACKAGE_DIR="${RELEASE_ROOT}/rust-macos"
APP="${PACKAGE_DIR}/Vela.app"
DMG="${RELEASE_ROOT}/vela-macos-v${VERSION}.dmg"
STAGING="${RELEASE_ROOT}/rust-macos-dmg"
VERIFY_MOUNT="${RELEASE_ROOT}/rust-macos-verify"

rustup target add aarch64-apple-darwin x86_64-apple-darwin
for target in aarch64-apple-darwin x86_64-apple-darwin; do
  cargo build --manifest-path rust/Cargo.toml --locked --release --target "${target}" -p vela-desktop
done
rm -rf "${PACKAGE_DIR}" "${STAGING}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Frameworks" "${APP}/Contents/Resources" "${STAGING}"
lipo -create rust/target/aarch64-apple-darwin/release/vela rust/target/x86_64-apple-darwin/release/vela -output "${APP}/Contents/MacOS/vela"
for arch in arm64 x86_64; do
  lipo "${APP}/Contents/MacOS/vela" -verify_arch "${arch}"
done
install_name_tool -add_rpath '@executable_path/../Frameworks' "${APP}/Contents/MacOS/vela"
python3 rust/packaging/runtime.py macos --destination "${APP}/Contents/Frameworks"
mv "${APP}/Contents/Frameworks/runtime-manifest.json" "${APP}/Contents/Resources/runtime-manifest.json"
cp rust/packaging/vela.icns "${APP}/Contents/Resources/vela.icns"
cp -R rust/packaging/licenses "${APP}/Contents/Resources/licenses"
python3 rust/packaging/notices.py --destination "${APP}/Contents/Resources/licenses" \
  --target aarch64-apple-darwin --target x86_64-apple-darwin
cp rust/packaging/THIRD_PARTY.md "${APP}/Contents/Resources/THIRD_PARTY.md"
cp rust/packaging/runtime-lock.json "${APP}/Contents/Resources/runtime-lock.json"
python3 - "${APP}" "${VERSION}" <<'PY'
from pathlib import Path
import plistlib, sys
app, version = Path(sys.argv[1]), sys.argv[2]
info = {
    'CFBundleExecutable': 'vela', 'CFBundleIdentifier': 'com.fouadktb.vela',
    'CFBundleName': 'Vela', 'CFBundleDisplayName': 'Vela', 'CFBundlePackageType': 'APPL',
    'CFBundleInfoDictionaryVersion': '6.0', 'CFBundleShortVersionString': version,
    'CFBundleVersion': version, 'CFBundleIconFile': 'vela.icns',
    'LSMinimumSystemVersion': '11.0', 'NSHighResolutionCapable': True,
}
with (app / 'Contents/Info.plist').open('wb') as stream:
    plistlib.dump(info, stream)
PY
for framework in "${APP}"/Contents/Frameworks/*.framework; do
  name="$(basename "${framework}" .framework)"
  for arch in arm64 x86_64; do lipo "${framework}/${name}" -verify_arch "${arch}"; done
  codesign --force --sign - "${framework}"
done
codesign --force --sign - "${APP}"
codesign --verify --deep --strict --verbose=2 "${APP}"

# Cargo test runs outside the bundle; the actual app uses its executable rpath.
DYLD_FRAMEWORK_PATH="${APP}/Contents/Frameworks" \
VELA_MPV_LIBRARY="${APP}/Contents/Frameworks/Mpv.framework/Mpv" \
  cargo test --locked --manifest-path rust/Cargo.toml -p vela-player --test runtime -- --ignored

ditto "${APP}" "${STAGING}/Vela.app"
ln -s /Applications "${STAGING}/Applications"
hdiutil create -volname Vela -srcfolder "${STAGING}" -ov -format UDZO "${DMG}"
hdiutil verify "${DMG}"
mkdir -p "${VERIFY_MOUNT}"
hdiutil attach -readonly -nobrowse -mountpoint "${VERIFY_MOUNT}" "${DMG}" >/dev/null
trap 'hdiutil detach "${VERIFY_MOUNT}" >/dev/null 2>&1 || true; rmdir "${VERIFY_MOUNT}" 2>/dev/null || true' EXIT
codesign --verify --deep --strict --verbose=2 "${VERIFY_MOUNT}/Vela.app"
hdiutil detach "${VERIFY_MOUNT}" >/dev/null
rmdir "${VERIFY_MOUNT}"
trap - EXIT
(cd "${RELEASE_ROOT}" && shasum -a 256 "$(basename "${DMG}")" > "SHA256SUMS-macos-v${VERSION}.txt")
printf 'Created %s\n' "${DMG}"
