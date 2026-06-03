#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_APK="${ROOT_DIR}/build/app/outputs/flutter-apk/app-release.apk"
RELEASE_DIR="${ROOT_DIR}/release"
KEYSTORE_DIR="${VELA_ANDROID_KEYSTORE_DIR:-${HOME}/.config/vela/android}"
KEYSTORE_PATH="${VELA_ANDROID_KEYSTORE:-${KEYSTORE_DIR}/vela-android-tv-release.jks}"
KEYSTORE_PARENT_DIR="$(dirname "${KEYSTORE_PATH}")"
KEY_ALIAS="${VELA_ANDROID_KEY_ALIAS:-vela-android-tv}"
STORE_PASSWORD="${VELA_ANDROID_STORE_PASSWORD:-vela-android-tv-release}"
KEY_PASSWORD="${VELA_ANDROID_KEY_PASSWORD:-${STORE_PASSWORD}}"
KEY_PROPERTIES_PATH="${ROOT_DIR}/android/key.properties"
DEFAULT_ANDROID_SDK="${HOME}/Library/Android/sdk"
ANDROID_STUDIO_JBR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

if [[ -z "${JAVA_HOME:-}" ]] && ! java -version >/dev/null 2>&1; then
  if [[ -x "${ANDROID_STUDIO_JBR}/bin/java" ]]; then
    export JAVA_HOME="${ANDROID_STUDIO_JBR}"
    export PATH="${JAVA_HOME}/bin:${PATH}"
  fi
fi

if [[ -z "${ANDROID_HOME:-}" && -d "${DEFAULT_ANDROID_SDK}" ]]; then
  export ANDROID_HOME="${DEFAULT_ANDROID_SDK}"
fi

if [[ -z "${ANDROID_SDK_ROOT:-}" && -n "${ANDROID_HOME:-}" ]]; then
  export ANDROID_SDK_ROOT="${ANDROID_HOME}"
fi

if [[ -n "${ANDROID_SDK_ROOT:-}" && -d "${ANDROID_SDK_ROOT}/platform-tools" ]]; then
  export PATH="${ANDROID_SDK_ROOT}/platform-tools:${PATH}"
fi

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

if [[ ! -f "${KEYSTORE_PATH}" ]]; then
  if ! command -v keytool >/dev/null 2>&1; then
    echo "keytool is required to create the Android TV release keystore." >&2
    exit 1
  fi
  if ! keytool -help >/dev/null 2>&1; then
    echo "keytool is present but no Java runtime is available. Install Android Studio or a JDK before packaging Android TV." >&2
    exit 1
  fi
  mkdir -p "${KEYSTORE_PARENT_DIR}"
  keytool \
    -genkeypair \
    -v \
    -storetype PKCS12 \
    -keystore "${KEYSTORE_PATH}" \
    -storepass "${STORE_PASSWORD}" \
    -keypass "${KEY_PASSWORD}" \
    -alias "${KEY_ALIAS}" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Vela Android TV, OU=Vela, O=Vela, L=Local, ST=Local, C=US"
fi

cat > "${KEY_PROPERTIES_PATH}" <<EOF
storeFile=${KEYSTORE_PATH}
storePassword=${STORE_PASSWORD}
keyAlias=${KEY_ALIAS}
keyPassword=${KEY_PASSWORD}
EOF

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
