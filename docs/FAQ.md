# FAQ

**Is this the full source?**
No. It is the analysis, tooling, and documentation. `SOURCE.md` explains how to
reproduce the decoded tree locally.

**Can `libhela.so` be recompiled?**
No. It is stripped, OLLVM-obfuscated ARM64 machine code. It can be repackaged,
not rebuilt from source.

**Why is the rebuild signed with a different key?**
The original private key is not in the APK — only the certificate. Re-signing is
mandatory after any modification.

**Will the rebuilt app work?**
It installs and launches on arm64 devices, but a new certificate breaks Play
Integrity and certificate-pinned checks. Any license/activation flow that pins
the signer will fail. Static verification passed; runtime testing requires an
arm64 device.

**Why does it need to uninstall the old app?**
Android refuses to replace an app whose signature differs.

**Are the Lua scripts in the APK?**
No. The APK references `/tmp/hela/lua/*.lua`; the scripts load at runtime.

**What is `libmain.so` vs `libhela.so`?**
The file is named `libmain.so` so Unity loads it; its ELF `SONAME` is
`libhela.so`, the mod's fingerprint.

**Is the game anti-cheat removed?**
No. Quago and Play Integrity are intact.

**What cipher is used?**
Single-byte XOR `0x0D`. See `DECRYPTION.md`.

**Why 8,157 Java files but 23,365 Smali files?**
JADX merges and skips synthetics; Smali is the faithful DEX view.

**Can I publish the decoded tree?**
It contains proprietary code and assets. Don't.
