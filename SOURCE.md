# Source reproduction

This repository intentionally does **not** commit the decoded application tree.
That tree contains proprietary game code, native binaries, and assets owned by
their respective rights holders. Publishing it would be redistribution, not
research.

The full tree can be reproduced locally from an APK you are entitled to use.

## What the full tree contains

| Layer | Path after decoding | Approx. size |
|---|---|---:|
| Smali (3 DEX) | `apktool/smali*` | 200.9 MB |
| Resources | `apktool/res` | 5.4 MB |
| Assets | `apktool/assets` | 166.7 MB |
| Native libs | `apktool/lib/arm64-v8a` | 367.4 MB |
| Java view | `jadx/sources` | 35.7 MB |
| Original DEX | `dex/*.dex` | 28.0 MB |

Total: roughly **804 MB**.

## Reproduce

```bash
./tools/decode.sh /path/to/input.apk
```

That runs:

```bash
apktool d -f -o apktool input.apk
jadx -d jadx --no-res -j 4 input.apk
```

## Rebuild

```bash
./tools/rebuild.sh
```

## Why this split

- **Committed here:** analysis, decrypted-string *findings*, feature map, IOCs,
  original diagrams, and tooling. These are the research output.
- **Not committed:** the APK, DEX, smali, Java decompilation, native libraries,
  assets, and signing material. These are third-party content.

If you need a private snapshot for your own device, keep it local and do not
publish it.

## Reference hashes

```
APK          80aa97f7ebdf04ecd972b82a2a4495f087331024487d77ed1b1c3c457e547315
libmain.so   c3f93191436481b347fab8cb33113ea36cbf60744dccb9e99924788d7f403b4b
libil2cpp.so 6b1e11619362ddd53f9dbcd7be1d4296bdec5dda27b9f742c16b8403359c25a0
libunity.so  13595e05cfb73e3d429492029a1922037aa29a3f32baa773019a6b0ac0cc5085
global-metadata.dat f5961a8548256da287b4f79466a169c302b90ec59be7f6461e8e58b482c0fb0d
```
