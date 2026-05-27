#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Vela.app"
BUILD_APP="${ROOT_DIR}/build/macos/Build/Products/Release/${APP_NAME}"
RELEASE_ROOT="${ROOT_DIR}/release"
PACKAGE_DIR="${RELEASE_ROOT}/vela-macos"
ZIP_PATH="${RELEASE_ROOT}/vela-macos.zip"

cd "${ROOT_DIR}"

flutter pub get
flutter build macos

if [[ ! -d "${BUILD_APP}" ]]; then
  echo "Expected macOS app not found: ${BUILD_APP}" >&2
  exit 1
fi

rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}"
rm -f "${ZIP_PATH}"

ditto "${BUILD_APP}" "${PACKAGE_DIR}/${APP_NAME}"

(
  cd "${PACKAGE_DIR}"
  ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}" "${ZIP_PATH}"
)

echo "Created ${ZIP_PATH}"
