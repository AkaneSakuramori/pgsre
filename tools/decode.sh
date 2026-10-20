#!/usr/bin/env bash
set -euo pipefail

APK="${1:?usage: decode.sh <input.apk> [outdir]}"
OUT="${2:-.}"
APK="$(readlink -f "$APK")"

command -v apktool >/dev/null || { echo "apktool not found" >&2; exit 1; }

echo "[*] apktool decode"
apktool d -f -o "$OUT/apktool" "$APK"

if command -v jadx >/dev/null; then
  echo "[*] jadx decompile"
  jadx -d "$OUT/jadx" --no-res -j "$(nproc)" "$APK"
else
  echo "[!] jadx not found; skipping Java view" >&2
fi

echo "[*] extract DEX"
mkdir -p "$OUT/dex"
unzip -o -q "$APK" 'classes*.dex' -d "$OUT/dex" || true

echo "[*] native libs"
find "$OUT/apktool/lib" -name '*.so' -printf '%p %s\n' | sort -k2 -n

echo "[+] done: $OUT"
