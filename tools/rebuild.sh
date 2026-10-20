#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APKTOOL_DIR="${APKTOOL_DIR:-$ROOT/apktool}"
OUT="${OUT:-$ROOT/signed.apk}"
KS="${KS:-$ROOT/pgsharp-rebuild.jks}"
ALIAS="${ALIAS:-pgsharp}"
STOREPASS="${STOREPASS:-pgsharp123}"

BT="${BUILD_TOOLS:-/opt/android-sdk/build-tools/34.0.0}"
ZIPALIGN="$BT/zipalign"
APKSIGNER="$BT/apksigner"

[ -d "$APKTOOL_DIR" ] || { echo "missing $APKTOOL_DIR (run tools/decode.sh)" >&2; exit 1; }
[ -x "$ZIPALIGN" ] || { echo "missing zipalign: $ZIPALIGN" >&2; exit 1; }
[ -x "$APKSIGNER" ] || { echo "missing apksigner: $APKSIGNER" >&2; exit 1; }

if [ ! -f "$KS" ]; then
  echo "[*] generating throwaway keystore"
  keytool -genkeypair -v -keystore "$KS" -alias "$ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$STOREPASS" -keypass "$STOREPASS" \
    -dname "CN=PGSharp Rebuild, OU=uw, O=uw, L=uw, ST=uw, C=uw"
fi

echo "[*] apktool build"
apktool b "$APKTOOL_DIR" -o "$ROOT/unsigned.apk"

echo "[*] zipalign"
"$ZIPALIGN" -p -f 4 "$ROOT/unsigned.apk" "$ROOT/aligned.apk"

echo "[*] sign (v3 only, matching the original scheme)"
"$APKSIGNER" sign \
  --ks "$KS" --ks-key-alias "$ALIAS" \
  --ks-pass "pass:$STOREPASS" --key-pass "pass:$STOREPASS" \
  --v1-signing-enabled false --v2-signing-enabled false --v3-signing-enabled true \
  --out "$OUT" "$ROOT/aligned.apk"

echo "[*] verify"
"$APKSIGNER" verify --verbose --print-certs "$OUT"
echo "[+] $OUT"
