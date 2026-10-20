# PGSharp 0.433.0 — Reverse Engineering Report

> This is the full technical report. It describes artifacts (APK, DEX, `.so`,
> decoded tree) that are **not** included in this repository; see
> [`../SOURCE.md`](../SOURCE.md) for local reproduction.

**Target:** `test.apk` (hash in [`../data/hashes.json`](../data/hashes.json))
**Analysis date:** 2026-10-20
**Analyst:** ironhawk909 (REA v42, JADX 0.7.1 / static + custom decryption)
**Method:** Static reverse engineering, ELF/DEX parsing, OLLVM string deobfuscation, Capstone AArch64 disassembly, resource/manifest decoding. No execution of the sample.

---

## 1. Executive summary

The sample is **not an official Niantic build**. It is **PGSharp**, a third-party modified Pokémon GO client, rebased onto game version **0.433.0** (versionCode `2026100702`).

The mod is **native-only**. The Android DEX is effectively stock; the entire modification lives in a replaced Unity player library:

- File name: `libmain.so`
- SONAME: **`libhela.so`**
- Size: 38,312,416 bytes
- SHA-256: `c3f93191436481b347fab8cb33113ea36cbf60744dccb9e99924788d7f403b4b`

That library contains:

- A **Dobby**-based inline hook engine (`sethook`, `unhook`, `hook_sym_addr`, `hook_sym_name`).
- An embedded **Lua 5.1.5** VM, deliberately mislabeled `"Ruby 5.1.5 … Ruby.org"`.
- A full in-game GUI (layouts, drawables, view IDs, settings objects).
- A spoofing / teleport / auto-walk / cooldown / sniper / feed system.
- A license activation and trial system tied to `https://www.pgsharp.com/activation`.
- OLLVM obfuscation: control-flow flattening, `.datadiv_decode*` datum obfuscation, and **single-byte XOR `0x0D` string encryption** — broken in this analysis.

Four independent signals establish attribution:

1. Self-signed certificate `CN=hela`.
2. Replaced `libmain.so` with SONAME `libhela.so`.
3. Plaintext update URL `https://www.pgsharp.com/download64`.
4. Decrypted UI/Lua/mod strings (`hl_*`, `Pgp*`, `Hela*`, `/tmp/hela/lua/*.lua`, `plg.*`, `Hide PGSharp`, `Please RESPECT cooldown rules to avoid softban.`).

This is a much newer build than the publicly documented PGSharp 1.33.0 / game 0.221.0 sample (Romain Thomas, ekoparty 2021).

---

## 2. Sample identity

| Field | Value |
|---|---|
| File | `test.apk` |
| Size | 210,412,021 bytes |
| SHA-256 | `80aa97f7ebdf04ecd972b82a2a4495f087331024487d77ed1b1c3c457e547315` |
| Container | ZIP / APK (`application/vnd.android.package-archive`) |
| Package | `com.nianticlabs.pokemongo` |
| App label | `@string/app_name` (Pokémon GO) |
| Version name | `0.433.0` |
| Version code | `2026100702` |
| minSdk | 28 |
| targetSdk | 36 |
| DEX classes | 12,025 |
| Resources | 2,198 |
| Permissions | 44 |
| Distribution URL | `https://canon-filetolink-go.vercel.app/dl/17c4981416e84d87a7a0b891` |

### Component inventory (selected)

- Application: `com.nianticproject.holoholo.libholoholo.unity.WorkManagerApplication`
- Launcher: `com.nianticproject.holoholo.libholoholo.unity.UnityMainActivity`
- 34 activities total
- 19 services (WorkManager, Firebase, Niantic background/sensor/location, Pokémon GO Plus, push)
- 8 providers (FileProvider, FirebaseInitProvider, FacebookInitProvider, Niantic KeyValue/Login providers, Usabilla)

### Manifest flags of note

| Attribute | Value | Why it matters |
|---|---|---|
| `android:usesCleartextTraffic` | `true` | allows HTTP |
| `android:extractNativeLibs` | `true` | native libs extracted to disk (mod load path) |
| `android:allowBackup` | `true` | app data backupable |
| `android:requestLegacyExternalStorage` | `true` | legacy storage |
| `android:debuggable` | `false` | release build |
| `android:allowNativeHeapPointerTagging` | `false` | disables heap pointer tagging |

### High-impact permissions

`READ_CONTACTS`, `READ_PRIVILEGED_PHONE_STATE`, `AD_ID`, fine/coarse location, background location, Bluetooth scan/advertise/connect, camera, activity recognition, notifications, foreground service, wake lock, network state.

---

## 3. Signature and provenance

| Field | Value |
|---|---|
| Signature block | `META-INF/HELA.RSA`, `META-INF/HELA.SF` |
| Subject | `CN=hela, OU=uw, O=uw, L=uw, ST=uw, C=uw` |
| Self-signed | Yes |
| Algorithm | `SHA256withRSA` |
| Validity | 2020-01-04 → 2047-05-22 |
| SHA-1 | `69:FF:D0:B7:40:73:0C:71:E1:A5:F0:C0:2B:4C:E0:16:AA:B9:2E:51` |
| SHA-256 | `E6:01:D7:E0:38:3F:0C:C1:E0:F0:A4:24:33:94:E4:2C:AF:BA:6E:7C:ED:F1:AF:37:7F:90:52:C3:A0:0A:46:A4` |

A genuine Play-distributed build is signed by Google Play App Signing, not by a `hela`/`uw` self-signed key. The signature alone proves repackaging. Any Play Integrity / server-side signature check that pins the official certificate will fail.

---

## 4. Package structure

### DEX

| File | Notes |
|---|---|
| `classes.dex` | stock game + SDKs |
| `classes2.dex` | stock |
| `classes3.dex` | stock |

- 24,957 unique class descriptors.
- **No `pgsharp`, `hela`, or mod classes injected into DEX.**
- Top prefixes: `com/google/android` (4,656), `com/usabilla/sdk` (1,444), `com/nianticlabs/platform` (1,119), `com/google/protobuf` (787), `com/appsflyer/internal` (401), `com/facebook/*`, `com/google/firebase`, `androidx/*`.

### Native libraries (arm64-v8a)

| Library | Size | Role |
|---|---|---|
| `libil2cpp.so` | 252,381,992 | IL2CPP runtime + game code |
| `libunity.so` | — | Unity engine; `NEEDED libmain.so` |
| **`libmain.so`** | **38,312,416** | **replaced Unity player = PGSharp mod host (SONAME `libhela.so`)** |
| `libholoholo.so` | — | Niantic game logic |
| `libNianticLabsPlugin.so` | — | Niantic platform plugin |
| `libQuagoTool.so` | — | Quago anti-cheat |
| `libnia-advsync-reporter-android.so` | — | Adventure Sync |
| `libgeouploader.so`, `libadventuresync.so` | — | location sync |
| `libfmod*`, `libFirebaseCpp*`, `libsqlite3.so` | — | audio, Firebase, SQLite |

Hashes:

```
libmain.so   c3f93191436481b347fab8cb33113ea36cbf60744dccb9e99924788d7f403b4b
libil2cpp.so 6b1e11619362ddd53f9dbcd7be1d4296bdec5dda27b9f742c16b8403359c25a0
libunity.so  13595e05cfb73e3d429492029a1922037aa29a3f32baa773019a6b0ac0cc5085
```

### Assets

- `assets/bin/Data/Managed/Metadata/global-metadata.dat` — 35,873,276 bytes, magic `0xfab11baf`, **IL2CPP metadata version 39**.
- `assets/featureFlag.json` — `{"ZeroClientId": true}`
- `assets/aa/AddressablesLink/link.xml` — 25 assemblies (`holo-game`, `holo-game-vnext-battle`, `Niantic.*`, `GuiFrameworkCommon`, `TouchScript`, `Zenject`, `Zeppelin`, Unity modules).
- No Lua bytecode found in assets (see §7.6).

---

## 5. The mod library: `libmain.so` → `libhela.so`

### 5.1 ELF facts

| Field | Value |
|---|---|
| SONAME | `libhela.so` |
| `JNI_OnLoad` | `0x18f090`, 1,560 bytes, `GLOBAL DEFAULT` |
| `NEEDED` | `libEGL`, `libGLESv2`, `libjnigraphics`, `libandroid`, `liblog`, `libm`, `libdl`, `libc` |
| `.init_array` | `0xaee8f0`, 1,440 bytes (180 entries) |
| Zip timestamp | 1980-01-01 (epoch) |
| Compiler | Android clang 9.0.7 / 9.0.8 (LLVM 9) strings |

The official Unity player would be `libmain.so` with SONAME `libmain.so`. Renaming the SONAME to `libhela.so` is the mod's fingerprint.

### 5.2 Obfuscation

- **OLLVM control-flow flattening** in `JNI_OnLoad` and the mod paths.
- **Datum obfuscation:** 180 `.datadiv_decode<random>` initializers in `.init_array`, a standard OLLVM pass that reconstructs global data at load.
- **String encryption:** single-byte XOR `0x0D` over printable ASCII. Confirmed against known plaintexts:

| Ciphertext | XOR 0x0D |
|---|---|
| `-~}hndkdhi` | `" specified"` |
| `)Dc{ladi-YA^-nelccha-DI-fht-~}hndkdhi` | `$Invalid TLS channel ID key specified` |
| `-yelc-laabzhi-ot-yeh-]FNH-~}hndkdnlydbc` | ` than allowed by the PKCE specification` |
| `@/tmp/hela/lua/aes.lua` (decrypted form) | Lua chunk path |

Because `0x20..0x7E` is closed under XOR `0x0D`, plaintext also survives the transform; a bigram classifier was used to separate real decryptions from scrambled plaintext.

### 5.3 Hook engine

Decrypted/plaintext strings confirm **Dobby** inline hooking:

```
DobbySymbolResolver
sethook
unhook
hook_sym_addr
hook_sym_name
Duplicate hook
```

`JNI_OnLoad` begins with obfuscated dispatch (constants `0xc4424566`, `0x723c6c9b`, `0x9d70ed66`) consistent with flattened control flow; the hook engine is initialized through the flattened path.

### 5.4 Embedded Lua 5.1.5

Plaintext banner with the engine name swapped:

```
LuaVersion: Ruby 5.1.5  Copyright (C) 1994-2018 Ruby.org, PUC-Rio
```

References resolved after decryption:

```
Lua/LuaAuthors: R. Ierusalimschy, L. H. de Figueiredo, W. Celes
_URL "https://github.com/kikito/md5.lua
dofile #/data/local/tmp/hela/lua/debug.lua
```

No `luaL_*`/`lua_pcall` symbols are exported or imported; the VM is statically linked and stripped. No `\x1bLua` bytecode signature was found in any shipped `.so`, so scripts are not shipped as plain bytecode.

### 5.5 Loading model

1. Unity loads `libunity.so`.
2. `libunity.so` has `NEEDED libmain.so`, so the mod's `libhela.so` is mapped.
3. `JNI_OnLoad` runs, deobfuscates globals via `.datadiv_decode*`, initializes Dobby, and installs hooks into game/IL2CPP functions.
4. The Lua VM is initialized and plugin scripts are loaded from `/tmp/hela/lua/` (and `/data/local/tmp/hela/lua/` for debug).
5. The overlay/menu is built from `hl_*` layouts and resources.
6. Feature flags from the native settings layer drive the hooks.

---

## 6. Decrypted string intelligence

Decryption produced 361,187 printable strings; 33,951 scored as genuine plaintext; 1,058 are mod-specific identifiers/resources.

### 6.1 Lua runtime and scripts

Paths (Lua chunk names use the `@` prefix):

```
/tmp/hela/lua/aes.lua
/tmp/hela/lua/base64.lua
/tmp/hela/lua/class.lua
/tmp/hela/lua/fifo.lua
/tmp/hela/lua/gamedump.lua
/tmp/hela/lua/global.lua
/tmp/hela/lua/init.lua
/tmp/hela/lua/jclass.lua
/tmp/hela/lua/json.lua
/tmp/hela/lua/localtest.lua
/tmp/hela/lua/location.lua
/tmp/hela/lua/md5.lua
/tmp/hela/lua/pgo.lua
/tmp/hela/lua/pgodump.lua
/tmp/hela/lua/plugin.lua
/tmp/hela/lua/reflect.lua
/tmp/hela/lua/uuid.lua
/tmp/hela/lua/test_old.lua
/tmp/hela/lua/templateindexs.lua
/data/local/tmp/hela/lua/test.lua
/data/local/tmp/hela/lua/debug.lua
```

`aes`, `base64`, `md5`, `uuid`, `json` show a scripting stack with crypto/encoding helpers — consistent with plugin/remote-config handling.

### 6.2 Lua plugin API

```
plg.run              plg.pause            plg.setspeed
plg.map              plg.float            plg.http
plg.joystart         plg.joystop          plg.randomwalk
plg.entergame        plg.enablespoof

pgo.lua              pgo.hook             pgo.il2ready
pgo.statector        pgo.statees          pgo.svcctor

lua.spoof            lua.randomwalk
hela.login           hela.so
Hela.LoadedPlugin
```

`plg.http` means Lua plugins have network capability. `pgo.hook` / `pgo.il2ready` expose the IL2CPP hook layer to scripts. `plg.entergame` gates plugin execution on game entry.

### 6.3 Thread and loader names

```
Hela/AppAuth
Hela/SoLibraryLoader
Hela/Mbgl-AccountsManager
Hela/Mbgl-ConnectivityReceiver
Hela/Mbgl-EGLConfigChooser
Hela/Mbgl-FileSource
Hela/Mbgl-FontUtils
Hela/Mbgl-Layer
Hela/Mbgl-LibraryLoader
Hela/Mbgl-Light
Hela/Mbgl-LocalRequestTask
Hela/Mbgl-MapChangeReceiver
Hela/Mbgl-MapRenderer
Hela/Mbgl-Mapbox
Hela/Mbgl-NativeMapView
Hela/Mbgl-Source
Hela/Mbgl-Transform
Hela/Mbgl-TextureViewRenderThread
Hela/Mbgl-Textu...
```

These are the mod's renamed Mapbox render threads; the mod ships its own Mapbox integration inside `libhela.so`.

### 6.4 UI resource namespace (`hl_`)

968 unique `hl_*` identifiers. Layouts include:

```
hl_settings, hl_settings_account_stats
hl_settings_object_activate, _autofeed, _autohatch, _autotest
hl_settings_object_drop, _dropdown_switch, _enhance_throw
hl_settings_object_exportimport, _group, _mode_switch
hl_settings_object_multiple_option, _parent, _pvpinfo
hl_settings_object_singlebutton, _speed, _subsetting
hl_settings_object_switch, _tapto
hl_activate_dialog, hl_autowalk, hl_teleport
hl_enable_spoofing_settings, hl_settings_object_enhance_throw
```

Drawables include joystick, map, speed, walk, snipe, cooldown, and floating menu icons. The floating menu entries are:

```
hl_floatmenu_autowalk   hl_floatmenu_bns      hl_floatmenu_feeds
hl_floatmenu_map        hl_floatmenu_settings hl_floatmenu_speed
hl_floatmenu_toc        hl_floatmenu_tp
```

### 6.5 Feature inventory (confirmed by strings)

| Area | Strings | Meaning |
|---|---|---|
| Catching | `autocatch`, `Quick Catch`, `hl_catch_caught`, `_caught_ditto`, `_escaped`, `_fled`, `_missed` | auto-catch + result tracking |
| Spinning | `autospin`, `hl_aw_station` | auto-spin PokéStops |
| Throwing | `enhancedThrowARPlus`, `enhancedThrowCurve`, `enhancedThrowExcellent`, `enhancedThrowHit`, `hl_enhanced_throw`, `hl_curveball`, `hl_excellent` | throw assist |
| Auto-walk | `AutoWalk`, `autowalk_on_96`, `autowalk_off_96`, `autowalk_pause_96`, `hl_aw_day/week/loop/oneway/outandback/poi/gym/station`, `plg.randomwalk`, `lua.randomwalk` | route walking |
| Speed | `hl_speed`, `hl_speed_seek`, `hl_speed_text`, `plg.setspeed`, `u_walkspeed`, `u_loc_setspeed_mid` | speed control |
| Teleport | `Teleport`, `Tap to Walk/Teleport`, `hl_teleport`, `hl_f_tp`, `hl_mapbox_popup_teleport`, `hl_coordinates`, `spoofto` | coordinate teleport |
| Spoofing | `Spoofing Location`, `hl_spoofing`, `hl_enable_spoofing_settings`, `lua.spoof`, `plg.enablespoof`, `u_enable_spoof`, `u_spoofing`, `u_spoof_runnable` | mock location |
| Cooldown | `Cooldown`, `Cooldown Time`, `Cooldown Timer`, `Cooldown History`, `Cooldown: %s`, `MapPokestop_SetCooldownTime`, `hl_cdhist*`, `hl_cd_raid_extra`, `hl_cd_rocket_extra`, `_hl_pgp_softban` | cooldown matrix + history |
| Sniper | `Quick Sniper`, `hl_fastsnipe`, `hl_feeds_item_fastsnipeFlag`, `hl_cdhist_item_snipe` | fast snipe |
| Feeds | `Feeds`, `hl_feeds_cat_pokemon/quest/raid/misc`, `hl_feed_filter_*`, `hl_feed_result_*` | live spawn/quest/raid feeds |
| Favorites/routes | `hl_favorites`, `hl_favor_cat_hotplaces/points/routes`, `hl_favorite_route` | saved locations/routes |
| GPX | `Auto-Generated GPX`, `hl_auto_gpx_title`, `hl_autogenerate_gpx_pat`, `Import GPX Failed` | route import/export |
| Accounts | `hl_accounts_*`, `hl_account_item_*`, `hl_account_item_name/lv/p_img` | multi-account manager |
| Gift | `Gift Assistant`, `GiftingRpcService_OpenGift`, `GiftingRpcService_SendGift` | gift automation |
| Raids/rocket | `Instant Beat Team Rocket`, `instantRocket`, `instantLeader`, `hl_feed_raid_*` | instant rocket/leader |
| AR | `Instant ArMapping`, `hl_armapping`, `hl_arplus`, `hl_ar` | AR mapping |
| Inventory | `autoDiscard`, `autoTransfer`, `autoFeed`, `autoHatch`, `autoInventorySnapshot`, `hl_autodiscard_*` | inventory automation |
| PvP/IV | `hl_ec_pvp_gl/ul/ml`, `hl_eciv`, `hl_abbreviation_iv/level`, `hl_ff_attr_iv`, `hl_ffp_checkshiny` | IV/PvP analysis |
| Map | `hl_mapbox_popup_*`, `hl_mbmap_*`, `hl_mapbox_*`, `showMapAvatars` | in-game map overlay |
| Misc | `Skip Cutscenes`, `Quick Load Map`, `Hide PGSharp`, `hideRaidStatus`, `hideTrainerName`, `disableLastPokemonCaught`, `fakeround`, `spawnBooster`, `DoUpdate` | misc toggles |

### 6.6 Licenses, activation, trial

```
https://www.pgsharp.com/activation
https://www.pgsharp.com/download64
))a;href=https://www.pgsharp.com/activation
hl_activate_dialog
hl_activate_obtain_key_pat / _text
hl_settings_object_activate
hl_sto_activate_btn
hl_sto_license_info
hl_settings_object_pvpinfo
hl_activate / hl_deactivate
Activate / Deactivate
Have a license? click here.
Please activate before sign in.
The feed is limited (Trial/Free License).
This feature is not available for %s license.
Please upgrade to standard license to create more filters.
Please upgrade to standard license to enable more filters.
Your settings/feeds/favorites/license will be exported to a file. Please do not send this file to others
```

There is a **license/trial tier system** with feature gating (feed limits, filter limits, per-license availability) and an export of settings/feeds/favorites/license. `hela.login` is a preference key; `hlfblogin_*`, `hlgglogin_*`, `hlptclogin_*` store Facebook/Google/PTC login metadata (account manager).

### 6.7 Safety / softban messaging

```
Please RESPECT cooldown rules to avoid softban.
Go Plus is connected, teleport may trigger a softban.
AutoWalk paused
Stop AutoWalk?
Stop/Pause AutoWalk?
_hide PGSharp
```

The mod implements the community "cooldown matrix" and warns the user it does not prevent bans.

### 6.8 Interesting unresolved blobs

Two 32-byte base64 blobs appear near mod code and may be keys or hashes:

```
gPgpSOzaLjbIpDLlh302x2irQTzWfsQqIWhUsreMMzI=
gakY+fylqW6kp6piqnaQNLZFzT8HlhzP5lsGJk5WguE=
```

Not yet classified as AES keys; no assertion is made beyond "unresolved 32-byte blobs."

### 6.9 Plugin loader (VirtualAPK)

Decrypted strings include:

```
com.didi.virtualapk.core
com.didi.virtualapk.internal.PluginContentResolver
Lm/u/r/loader/a/PluginAppCompatActivity;
VirtualAPK.Provider
VirtualAPK_Settings
Try to copy plugin's cup arch:
Found plugin's cup arch dir:
init_plugin_natives
u_plugin_path / u_plugin_cls
Hela.LoadedPlugin
!plugin has already been loaded :
```

VirtualAPK is a dynamic APK plugin framework. No VirtualAPK provider/component was found in the manifest, so this may be an unregistered/dead code path or used through a custom loader. It is a plausible second-stage plugin mechanism and worth dynamic confirmation.

---

## 7. Game-side stack (unmodified by the mod)

### 7.1 DEX SDK roster

Firebase, Facebook SDK, AppsFlyer, Usabilla, Helpshift, Sentry, Samsung IAP, Google Play Billing, ARCore, Mapbox, Campfire/Lightship Maps, GetFeedback, UniWebView, Quago.

### 7.2 Anti-cheat

- **Quago**: `Java_com_quago_mobile_sdk_root_QuagoRootDetectionNative_checkForRoot`, endpoint `https://api.quago.io/v1/record`, `libQuagoTool.so`.
- **Play Integrity**: `IntegrityErrorCode`, `developer.android.com/google/play/integrity/...`.
- Game error codes: `ERROR_CHEATING_DETECTED`, `player_cheating_warning`, `GAME_CHEATS_OR_SPAM`, `CHANGE_BANNED_NAME`.

The mod does not remove these; it runs alongside the stock anti-cheat. That is a key risk signal for users and a detection opportunity for defenders.

### 7.3 IL2CPP

`global-metadata.dat` v39 is intact; `libil2cpp.so` is stock-sized and untouched. The mod hooks native/IL2CPP functions rather than rewriting managed assemblies.

---

## 8. Behavioral model

```
APK install
  └─ UnityMainActivity (stock)
       └─ libunity.so
            └─ NEEDED libmain.so  →  actually libhela.so (PGSharp)
                 ├─ .datadiv_decode* (OLLVM global reconstruction)
                 ├─ JNI_OnLoad (flattened)
                 │    ├─ Dobby init (sethook/unhook)
                 │    ├─ hook game/IL2CPP functions
                 │    ├─ Lua 5.1.5 VM
                 │    │    ├─ /tmp/hela/lua/*.lua
                 │    │    ├─ plugin.lua + Hela.LoadedPlugin
                 │    │    └─ plg.* / pgo.* / lua.* API
                 │    └─ overlay UI (hl_* layouts)
                 └─ feature layer
                      ├─ spoof/teleport/auto-walk/speed
                      ├─ auto-catch/spin/throw
                      ├─ feeds/sniper/cooldown history
                      ├─ accounts + license/trial
                      └─ map overlay (renamed Mapbox threads)
```

The mod's own Mapbox threads (`Hela/Mbgl-*`) suggest it renders its own map UI rather than only drawing over the game.

---

## 9. Indicators of compromise / detection

### Files and paths

```
/tmp/hela/lua/
/data/local/tmp/hela/lua/
/data/local/tmp/hela/lua/debug.lua
/data/local/tmp/hela/lua/test.lua
```

### Network

```
https://www.pgsharp.com/activation
https://www.pgsharp.com/download64
```

### Signature

```
CN=hela, OU=uw, O=uw, L=uw, ST=uw, C=uw
SHA-256 E6:01:D7:E0:38:3F:0C:C1:E0:F0:A4:24:33:94:E4:2C:AF:BA:6E:7C:ED:F1:AF:37:7F:90:52:C3:A0:0A:46:A4
```

### Library

```
libmain.so  SONAME libhela.so
SHA-256 c3f93191436481b347fab8cb33113ea36cbf60744dccb9e99924788d7f403b4b
```

### Symbols / strings

```
sethook, unhook, hook_sym_addr, hook_sym_name, Duplicate hook
DobbySymbolResolver
LuaVersion: Ruby 5.1.5
Hela.LoadedPlugin
Hela/SoLibraryLoader
plg.run, plg.http, pgo.hook, lua.spoof
hl_settings_object_activate
Hide PGSharp
Please RESPECT cooldown rules to avoid softban.
```

### Package-level checks

- Certificate does not match the official Niantic/Google signer.
- `libmain.so` SONAME is `libhela.so`.
- `libmain.so` ~38 MB and contains `DobbySymbolResolver` and `hl_*` resources.
- DEX is clean — checking DEX only will miss this mod entirely.

---

## 10. Risk assessment

| Risk | Assessment |
|---|---|
| Account ban | High. Stock Quago + Play Integrity + send-time signature checks can detect certificate mismatch and tampering. The mod itself warns about softbans. |
| Malware | Unverified. Self-signed, closed-source, broad permissions, cleartext allowed, native obfuscation, Lua HTTP capability, and dynamic plugin strings. No overt malicious behavior was found statically, but the trust model is poor. |
| Data exposure | `READ_CONTACTS`, `READ_PRIVILEGED_PHONE_STATE`, location/background location, `allowBackup=true`, `usesCleartextTraffic=true`. |
| Supply chain | APK comes from a `vercel.app` file-download redirector, not the vendor domain. The update URL points to `pgsharp.com`. The activation/license path is remote. |
| Integrity | Signature is self-signed and long-lived; no transparency. |
| Legal/ToS | Modified client violates Niantic ToS; distribution may violate local law. |

---

## 11. Methodology and reproducibility

### Tools

- REA v42 (`reverse-engineer-anything`) with JADX headless MCP 0.7.1
- `zipinfo`/`unzip`, `readelf`, `objdump`, `strings`
- Python 3 + `pyelftools` + `capstone` 5.0.7
- Custom XOR-0x0D decryptor + bigram classifier

### Steps

1. Download, hash, and identify the APK.
2. `inspect-android-package` / `decode-android-resources` (JADX).
3. Extract native libs and metadata.
4. Parse ELF: sections, symbols, `NEEDED`, `SONAME`, `.init_array`, relocations.
5. Disassemble `JNI_OnLoad` with Capstone (AArch64).
6. Extract strings; test single-byte XOR keys against known plaintext (`" specified"`).
7. Decrypt with XOR `0x0D`; classify genuine plaintext by English bigram score.
8. Mine `hl_*`, `Pgp*`, `Hela*`, `plg.*`, `pgo.*`, `lua.*`, paths, and URLs.
9. Correlate with manifest/DEX/anti-cheat/SDK findings.
10. Write report and retain artifacts.

### Key commands

```bash
sha256sum test.apk
unzip -l test.apk
readelf -d libs/extract/lib/arm64-v8a/libmain.so
readelf -sW libs/extract/lib/arm64-v8a/libmain.so
strings -n 6 libmain.so > libmain_strings.txt
python3 -c "print(bytes(c^0x0D for c in open('libmain.so','rb').read()))" > libmain_xor0d.bin
```

---

## 12. Limitations

- **No dynamic execution.** Hooks, Lua scripts, license traffic, and plugin loading were not observed at runtime.
- **Lua scripts not recovered.** No `\x1bLua` bytecode or plaintext scripts in the APK; likely fetched/extracted at runtime or embedded under another layer.
- **Remote endpoints beyond `pgsharp.com` unknown.** The mod's HTTP calls may use obfuscated or runtime-derived hosts.
- **VirtualAPK usage unconfirmed.** Strings present, manifest components absent.
- **32-byte blobs unclassified.**
- **IL2CPP metadata not fully dumped.** The mod hooks native functions; managed method recovery was out of scope for this pass.

---

## 13. Artifacts (all under `/tmp/rea-target/`)

| File | Contents |
|---|---|
| `test.apk` | original sample |
| `apk-inspect.json`, `apk-resources.json` | REA/JADX evidence |
| `decoded_manifest.xml` | decoded AndroidManifest |
| `dex/classes*.dex`, `dex_strings.txt` | DEX + strings |
| `libs/extract/lib/arm64-v8a/*` | all native libs |
| `libmain_strings.txt` | raw strings from mod lib |
| `libmain_xor0d.bin` | whole lib after XOR 0x0D |
| `libmain_xor0d_strings.txt` | 361,187 decrypted strings |
| `libmain_decrypted_clean.txt` | 33,951 bigram-filtered decryptions |
| `mod_findings_strings.txt` | 1,058 curated mod strings |
| `meta2/assets/bin/Data/Managed/Metadata/global-metadata.dat` | IL2CPP metadata |
| `assetsx/assets/aa/AddressablesLink/link.xml` | assembly inventory |

---

## 14. Bottom line

This is a **PGSharp 0.433.0 repack** of Pokémon GO. The DEX is stock; the cheat is a replaced Unity player (`libhela.so`) with Dobby hooks, an embedded Lua 5.1.5 runtime, an in-game menu, spoofing/teleport/auto-walk/cooldown/sniper/feed features, and a license/trial gate. The string encryption is XOR `0x0D` and is fully broken here; the remaining secret material is the runtime-loaded Lua script set and the remote license/activation traffic.

**Recommended next step (if permitted):** dynamic analysis with Frida on a disposable device/emulator — dump `/tmp/hela/lua/*.lua` at load, trace `sethook` targets, and capture `plg.http` / activation requests.

---

*Credit to t.me/@NotYoursNaruto*
