# Language and artifact breakdown

Sizes are from the decoded project. Native libraries are **compiled binaries**,
not recoverable C/C++ source. Smali and Java are two representations of the same
DEX bytecode.

| Class | Language / format | Files | Bytes | Size |
|---|---|---:|---:|---:|
| Native | C / C++ (compiled ARM64) | 28 `.so` | 367,380,168 | 367.4 MB |
| Bytecode | Smali | 23,365 | 200,929,962 | 200.9 MB |
| Assets | Unity binary / data | — | 166,734,773 | 166.7 MB |
| Java | Java (JADX) | 8,157 | 35,660,063 | 35.7 MB |
| Bytecode | DEX | 3 | 28,035,860 | 28.0 MB |
| Resources | XML / PNG | 2,046 | 5,350,382 | 5.4 MB |

## Smali by DEX

| Directory | Bytes |
|---|---:|
| `smali` | 70,331,607 |
| `smali_classes2` | 69,597,366 |
| `smali_classes3` | 61,000,989 |

## Native libraries

28 `.so` files, dominated by:

| Library | Bytes | Role |
|---|---:|---|
| `libil2cpp.so` | 252,381,992 | IL2CPP runtime + game code |
| `libunity.so` | 60,299,232 | Unity player |
| `libmain.so` | 38,312,416 | mod host (`libhela.so`) |
| `libholoholo.so` | 6,805,528 | Niantic platform |
| `libQuagoTool.so` | 734,592 | anti-cheat |
| `libhermes.so` | — | React Native JS engine |

Others include `libc++_shared.so`, `libmonobdwgc-2.0.so`, `lib_burst_generated.so`,
`libFirebaseCpp*.so`, `libil2cpptiny.so`, and graphics/audio codecs.

## Assets

| Type | Count | Notes |
|---|---:|---|
| `.dat` | 12 | Unity data, 36 MB |
| `.json` | 72 | feature flags, config |
| `.png` | 874 | images (not redistributed) |
| `.xml` | 1,172 | layouts, manifest, resources |
| `.lua` | 0 | referenced paths only |

## Why the count looks odd

- `8,157` Java files vs `23,365` Smali files: JADX merges/simplifies and skips
  synthetic classes; Smali is the faithful DEX view.
- `367 MB` of "C/C++" is compiled machine code and debug sections, not source.

## Tooling

- `apktool` 3.0.3
- JADX 0.7.1
- Android build-tools 34.0.0
- JDK 21
- `capstone` 5.0.7, `pyelftools`
