#!/usr/bin/env bash
set -euo pipefail

APK="${1:?usage: verify.sh <apk>}"
BT="${BUILD_TOOLS:-/opt/android-sdk/build-tools/34.0.0}"

echo "== sha256 =="
sha256sum "$APK"

echo "== signature =="
"$BT/apksigner" verify --verbose --print-certs "$APK"

echo "== badging =="
"$BT/aapt2" dump badging "$APK" | sed -n '1,12p'

echo "== native libs =="
unzip -l "$APK" 'lib/*/*.so' | sort -k1 -n

echo "== manifest flags =="
"$BT/aapt2" dump xmltree "$APK" --file AndroidManifest.xml \
  | grep -E 'usesCleartextTraffic|extractNativeLibs|allowBackup|debuggable' || true
