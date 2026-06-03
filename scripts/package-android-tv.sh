#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_APK="${ROOT_DIR}/build/app/outputs/flutter-apk/app-release.apk"
RELEASE_DIR="${ROOT_DIR}/release"

cd "${ROOT_DIR}"

VERSION="$(awk '
  /^version:[[:space:]]*/ {
    version = $2
    sub(/\+.*/, "", version)
    print version
    exit
  }
' pubspec.yaml)"

if [[ -z "${VERSION}" ]]; then
  echo "Could not read app version from pubspec.yaml." >&2
  exit 1
fi

APK_PATH="${RELEASE_DIR}/vela-android-tv-v${VERSION}.apk"
CHECKSUM_PATH="${RELEASE_DIR}/SHA256SUMS-android-tv-v${VERSION}.txt"

flutter pub get
dart run scripts/verify_version_sync.dart
flutter analyze
flutter build apk --release

if [[ ! -f "${BUILD_APK}" ]]; then
  echo "Expected Android TV APK not found: ${BUILD_APK}" >&2
  exit 1
fi

mkdir -p "${RELEASE_DIR}"
cp "${BUILD_APK}" "${APK_PATH}"
(
  cd "${RELEASE_DIR}"
  shasum -a 256 "$(basename "${APK_PATH}")" > "$(basename "${CHECKSUM_PATH}")"
)

echo "Android TV APK: ${APK_PATH}"
echo "Checksum: ${CHECKSUM_PATH}"
