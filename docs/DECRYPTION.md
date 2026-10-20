# String decryption

## Cipher

Single-byte XOR with key **`0x0D`**.

```
plaintext[i] = ciphertext[i] ^ 0x0D
```

Because the printable range `0x20..0x7E` is closed under XOR `0x0D`, a plaintext
string also produces a printable, but scrambled, result when the same transform
is applied. A naive "decrypt everything" therefore yields both real plaintext
and garbage.

## Verification against known plaintext

| Ciphertext | XOR `0x0D` |
|---|---|
| `-~}hndkdhi` | `" specified"` |
| `)Dc{ladi-YA^-nelccha-DI-fht-~}hndkdhi` | `$Invalid TLS channel ID key specified` |
| `-yelc-laabzhi-ot-yeh-]FNH-~}hndkdnlydbc` | ` than allowed by the PKCE specification` |

These are BoringSSL/Android error strings, which confirms the key beyond doubt.

## Separating real plaintext

A bigram score (English/identifier bigrams such as `th`, `he`, `in`, `er`, `on`,
`re`, `at`, `en`, `nd`) is computed for both the original line and its XOR
result. A line is treated as encrypted when:

```
score(xor(line)) > score(line) + 0.045
```

That produced:

| Metric | Count |
|---|---:|
| Printable lines after XOR | 361,187 |
| Bigram-classified genuine plaintext | 33,951 |
| Curated mod identifiers | 1,058 |

## Tool

```python
KEY = 0x0D
plain = bytes(b ^ KEY for b in cipher)
```

```bash
python3 tools/xor0d_decrypt.py libmain.so libmain_xor0d.bin
strings -n 4 libmain_xor0d.bin > libmain_xor0d_strings.txt
```

## Why it matters

Static extraction before decryption yields only a few mod strings
(`autocatch`, `autospin`, `enhancedThrow*`). Decryption exposes:

- Lua runtime paths and API (`plg.*`, `pgo.*`, `lua.*`)
- 968 `hl_*` UI resources
- Activation, trial, and tier strings
- Cooldown/softban warnings
- Plugin-loader strings (VirtualAPK)
- Thread names and loader names (`Hela/*`)
