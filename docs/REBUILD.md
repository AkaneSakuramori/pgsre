# Rebuild

## Requirements

| Tool | Version |
|---|---|
| `apktool` | 3.0.3 |
| Android build-tools | 34.0.0 (`aapt2`, `zipalign`, `apksigner`) |
| JDK | 21 |
| `jadx` | optional, for Java view |

## Decode

```bash
./tools/decode.sh /path/to/input.apk
```

Produces:

```
apktool/   decoded manifest, res, smali, assets, lib
jadx/      Java decompilation (optional)
dex/       original classes*.dex (optional)
```

## Edit

- Smali: `apktool/smali*`
- Resources / layouts: `apktool/res`
- Manifest: `apktool/AndroidManifest.xml`
- Native libs: `apktool/lib/arm64-v8a` (binary only — not recompilable)

## Build

```bash
./tools/rebuild.sh
```

Steps:

```bash
apktool b apktool -o unsigned.apk
zipalign -p -f 4 unsigned.apk aligned.apk
apksigner sign --ks pgsharp-rebuild.jks --ks-key-alias pgsharp \
  --ks-pass pass:pgsharp123 --key-pass pass:pgsharp123 \
  --v3-signing-enabled true --v1-signing-enabled false \
  --v2-signing-enabled false --out signed.apk aligned.apk
apksigner verify --verbose --print-certs signed.apk
```

The included keystore is a **throwaway test key**. Generate your own for
anything beyond local testing:

```bash
keytool -genkeypair -v -keystore my.jks -alias mykey \
  -keyalg RSA -keysize 2048 -validity 10000
```

## Install

```bash
adb uninstall com.nianticlabs.pokemongo
adb install -r signed.apk
```

Uninstalling first is required because the rebuild has a different certificate.

## Expected runtime differences

| Change | Effect |
|---|---|
| New signing certificate | Play Integrity fails; certificate-pinned checks fail |
| Same `libmain.so` bytes | Mod loads as before |
| Same resources/DEX | UI and game logic unchanged |
| `extractNativeLibs=true` | Native libs unpack on install |

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | signature mismatch | uninstall first |
| `INSTALL_FAILED_NO_MATCHING_ABIS` | device not arm64 | use arm64 device |
| Crash at launch | Play Integrity / anti-tamper | expected with a new cert |
| `apktool b` resource error | framework mismatch | install framework: `apktool if framework-res.apk` |
| Signature verify fails | v1/v2/v3 mismatch | use v3 only, as in `rebuild.sh` |

## Notes

- The rebuild is structurally identical: `libmain.so` hash is unchanged,
  resource count is unchanged, package/version are unchanged.
- No device or emulator was available at analysis time for a runtime pass;
  see `REBUILD.md` and the report for what was verified statically.
