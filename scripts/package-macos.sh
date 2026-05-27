#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Vela.app"
BUILD_APP="${ROOT_DIR}/build/macos/Build/Products/Release/${APP_NAME}"
RELEASE_ROOT="${ROOT_DIR}/release"
PACKAGE_DIR="${RELEASE_ROOT}/vela-macos"
DMG_STAGING_DIR="${RELEASE_ROOT}/vela-macos-dmg"
DMG_PATH="${RELEASE_ROOT}/vela-macos.dmg"

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

echo "Created ${DMG_PATH}"
