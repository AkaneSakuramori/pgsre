#!/usr/bin/env bash
set -euo pipefail

LIB="${1:?usage: extract_strings.sh <libmain.so> [outdir]}"
OUT="${2:-.}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$OUT"
python3 "$HERE/xor0d_decrypt.py" "$LIB" "$OUT/libmain_xor0d.bin"

echo "[*] raw strings"
strings -n 4 "$OUT/libmain_xor0d.bin" > "$OUT/libmain_xor0d_strings.txt"

echo "[*] classified plaintext"
python3 "$HERE/xor0d_decrypt.py" "$LIB" --classify > "$OUT/libmain_plaintext.txt"

echo "[*] mod identifiers"
grep -aE 'hl_|Pgp|pgp_|Hela|hela|plg\.|pgo\.|lua\.' "$OUT/libmain_plaintext.txt" \
  | sort -u > "$OUT/mod_identifiers.txt" || true

wc -l "$OUT"/*.txt
