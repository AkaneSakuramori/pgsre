#!/usr/bin/env python3
"""XOR-0x0D decryptor for the PGSharp mod host.

Because 0x20..0x7E is closed under XOR 0x0D, plaintext also maps to printable
scrambled output. `--classify` applies a bigram score to keep only genuine
decryptions.

Usage:
  xor0d_decrypt.py input.bin output.bin
  xor0d_decrypt.py input.bin --strings --min 4 > strings.txt
  xor0d_decrypt.py input.bin --classify > plaintext.txt
"""
from __future__ import annotations

import argparse
import re
import sys

KEY = 0x0D
BIGRAMS = (
    "th he in er an re on at en nd ti es or te of ed is it al ar st to nt ng "
    "se ha as ou io le ve co me de hi ri ro ic ne ea ra ce li ch ll be ma si "
    "om ur ca el ta la ns di fo ho pe ec pr no ct us ac il tr ly ge da"
).split()
BIGRAM_SET = set(BIGRAMS)


def xor(data: bytes, key: int = KEY) -> bytes:
    return bytes(b ^ key for b in data)


def score(text: str) -> float:
    letters = re.sub(r"[^a-z]", "", text.lower())
    if len(letters) < 4:
        return 0.0
    hits = sum(1 for i in range(len(letters) - 1) if letters[i : i + 2] in BIGRAM_SET)
    return hits / max(1, len(letters) - 1)


def iter_lines(data: bytes):
    for raw in data.split(b"\n"):
        yield raw.rstrip(b"\r")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("input")
    ap.add_argument("output", nargs="?")
    ap.add_argument("--strings", action="store_true", help="emit strings after XOR")
    ap.add_argument("--classify", action="store_true", help="emit only high-confidence plaintext")
    ap.add_argument("--min", type=int, default=4, help="minimum string length")
    ap.add_argument("--threshold", type=float, default=0.045, help="bigram delta")
    args = ap.parse_args()

    data = open(args.input, "rb").read()
    dec = xor(data)

    if args.strings or args.classify:
        pattern = re.compile(rb"[\x20-\x7e]{%d,}" % args.min)
        out = sys.stdout
        for line in iter_lines(dec):
            for m in pattern.finditer(line):
                s = m.group().decode("latin1")
                if args.classify:
                    try:
                        original = xor(m.group()).decode("latin1")
                    except Exception:
                        continue
                    if score(s) > score(original) + args.threshold:
                        out.write(s + "\n")
                else:
                    out.write(s + "\n")
        return 0

    if not args.output:
        ap.error("output path required unless --strings/--classify is used")
    with open(args.output, "wb") as fh:
        fh.write(dec)
    print(f"wrote {args.output} ({len(dec)} bytes)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
