# Architecture

## Load chain

```
AndroidManifest.xml
└─ com.nianticproject.holoholo.libholoholo.unity.WorkManagerApplication
   └─ UnityMainActivity
      └─ libunity.so
         └─ NEEDED libmain.so
            └─ actually libhela.so  (SONAME)
               ├─ .init_array (180 entries)
               │  └─ .datadiv_decode*  (OLLVM global reconstruction)
               ├─ JNI_OnLoad @ 0x18f090
               │  ├─ Dobby init
               │  ├─ inline hooks (game / IL2CPP)
               │  ├─ Lua 5.1.5 VM
               │  └─ overlay UI
               └─ feature layer
```

Unity loads `libmain.so` by name. The file is present under that name, but its
ELF `SONAME` is `libhela.so` — the mod's fingerprint.

## ELF facts

| Field | Value |
|---|---|
| File | `lib/arm64-v8a/libmain.so` |
| SONAME | `libhela.so` |
| Size | 38,312,416 bytes |
| `JNI_OnLoad` | `0x18f090`, 1,560 bytes |
| `.init_array` | `0xaee8f0`, 1,440 bytes / 180 entries |
| `NEEDED` | `libEGL`, `libGLESv2`, `libjnigraphics`, `libandroid`, `liblog`, `libm`, `libdl`, `libc` |
| Compiler | Android clang 9.0.7 / 9.0.8 (LLVM 9) |
| Zip timestamp | 1980-01-01 |

## Obfuscation

Three layers:

1. **OLLVM control-flow flattening** in `JNI_OnLoad` and mod paths.
2. **Datum obfuscation** — 180 `.datadiv_decode<random>` symbols in
   `.init_array`, reconstructing global data at load.
3. **String encryption** — single-byte XOR `0x0D` (see `DECRYPTION.md`).

`JNI_OnLoad` starts with an obfuscated dispatcher keyed on constants
`0xc4424566`, `0x723c6c9b`, `0x9d70ed66`, consistent with flattened control flow.

## Hook engine

Recovered strings:

```
DobbySymbolResolver
sethook
unhook
hook_sym_addr
hook_sym_name
Duplicate hook
```

The mod uses **Dobby** for inline hooking. Hook metadata is stored as symbol
name + address pairs, and the engine refuses to install a duplicate hook.

## Lua runtime

Banner (engine name swapped):

```
LuaVersion: Ruby 5.1.5  Copyright (C) 1994-2018 Ruby.org, PUC-Rio
```

Actual version: **Lua 5.1.5**. No `luaL_*` symbols are exported or imported;
the VM is statically linked and stripped. No `\x1bLua` bytecode exists in the
APK.

Runtime script paths:

```
/tmp/hela/lua/*.lua
/data/local/tmp/hela/lua/debug.lua
/data/local/tmp/hela/lua/test.lua
```

## Overlay UI

The mod ships its own resources, prefixed `hl_` (968 identifiers). Layouts
cover settings, accounts, feeds, cooldown history, autowalk, teleport,
activation, and floating menus. `JoystickView_JV_*` attributes define the
virtual joystick.

The mod also ships renamed Mapbox render threads:

```
Hela/Mbgl-MapRenderer
Hela/Mbgl-NativeMapView
Hela/Mbgl-TextureViewRenderThread
Hela/Mbgl-AccountsManager
...
```

## Plugin layer

Recovered strings indicate a plugin loader:

```
com.didi.virtualapk.core
com.didi.virtualapk.internal.PluginContentResolver
VirtualAPK.Provider
Hela.LoadedPlugin
Try to copy plugin's cup arch:
init_plugin_natives
u_plugin_path / u_plugin_cls
```

No VirtualAPK component appears in the manifest, so this may be a dormant or
custom-loaded path. Confirm dynamically before relying on it.

## Game stack

- IL2CPP metadata **v39** (`global-metadata.dat`, 35,873,276 bytes).
- `libil2cpp.so` 252,381,992 bytes.
- Anti-cheat: **Quago** (`libQuagoTool.so`, `https://api.quago.io/v1/record`)
  plus **Play Integrity** references.
- Stock game error codes: `ERROR_CHEATING_DETECTED`, `player_cheating_warning`,
  `GAME_CHEATS_OR_SPAM`.

The mod runs alongside the stock anti-cheat; it does not remove it.
