#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Vela.app"
BUILD_APP="${ROOT_DIR}/build/macos/Build/Products/Release/${APP_NAME}"
RELEASE_ROOT="${ROOT_DIR}/release"
PACKAGE_DIR="${RELEASE_ROOT}/vela-macos"
DMG_STAGING_DIR="${RELEASE_ROOT}/vela-macos-dmg"
DMG_PATH="${RELEASE_ROOT}/vela-macos.dmg"
DMG_VERIFY_MOUNT="${RELEASE_ROOT}/vela-macos-verify-mount"

cd "${ROOT_DIR}"

flutter pub get
flutter build macos

if [[ ! -d "${BUILD_APP}" ]]; then
  echo "Expected macOS app not found: ${BUILD_APP}" >&2
  exit 1
fi

rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"
rm -rf "${DMG_STAGING_DIR}"
mkdir -p "${DMG_STAGING_DIR}"
rm -rf "${DMG_VERIFY_MOUNT}"
rm -f "${DMG_PATH}"

ditto "${BUILD_APP}" "${PACKAGE_DIR}/${APP_NAME}"
ditto "${BUILD_APP}" "${DMG_STAGING_DIR}/${APP_NAME}"
ln -s /Applications "${DMG_STAGING_DIR}/Applications"

hdiutil create \
  -volname "Vela" \
  -srcfolder "${DMG_STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

hdiutil verify "${DMG_PATH}"
mkdir -p "${DMG_VERIFY_MOUNT}"
hdiutil attach \
  -readonly \
  -nobrowse \
  -mountpoint "${DMG_VERIFY_MOUNT}" \
  "${DMG_PATH}" >/dev/null
trap 'hdiutil detach "${DMG_VERIFY_MOUNT}" >/dev/null 2>&1 || true; rm -rf "${DMG_VERIFY_MOUNT}"' EXIT
codesign --verify --deep --strict --verbose=4 "${DMG_VERIFY_MOUNT}/${APP_NAME}"
hdiutil detach "${DMG_VERIFY_MOUNT}" >/dev/null
rm -rf "${DMG_VERIFY_MOUNT}"
trap - EXIT

echo "Created ${DMG_PATH}"
