# Findings

## Identification

The APK is a **PGSharp** mod of Pokémon GO **0.433.0**. Identification rests on
four independent signals:

1. Self-signed certificate `CN=hela, OU=uw, O=uw, L=uw, ST=uw, C=uw`.
2. `libmain.so` with `SONAME libhela.so`.
3. Decrypted URLs `https://www.pgsharp.com/activation` and `/download64`.
4. Hundreds of `hl_*` / `Pgp*` / `Hela*` strings and resources.

## Package facts

| Field | Value |
|---|---|
| Package | `com.nianticlabs.pokemongo` |
| Version name | `0.433.0` |
| Version code | `2026100702` |
| minSdk / targetSdk | 28 / 36 |
| ABI | `arm64-v8a` |
| Classes | 12,025 |
| Resources | 2,198 |
| Permissions | 44 |
| Activities / services / providers | 34 / 19 / 8 |
| Manifest flags | `usesCleartextTraffic`, `extractNativeLibs`, `allowBackup`, `requestLegacyExternalStorage`, `allowNativeHeapPointerTagging=false`, `debuggable=false` |

## Modification model

The game DEX and resources are essentially stock. The mod is carried by the
replaced Unity player library (`libmain.so` = `libhela.so`), which:

- reconstructs obfuscated globals at load (180 `.init_array` entries),
- installs Dobby inline hooks,
- embeds Lua 5.1.5 for plugins,
- injects its own overlay UI (`hl_*`),
- gates features on a PGSharp license.

## Feature map

### Catching and throwing

`autocatch`, `autospin`, `enhancedThrowARPlus`, `enhancedThrowCurve`,
`enhancedThrowExcellent`, `enhancedThrowHit`, `autoDiscard`, `autoTransfer`,
`autoFeed`, `autoHatch`, `autoInventorySnapshot`, `autoWildSnapshot`.

### Movement

`Spoofing Location`, `Teleport`, `AutoWalk`, `hl_speed_seek`,
`plg.setspeed`, `plg.randomwalk`, `lua.randomwalk`, `JoystickView_*`,
`Auto-Generated GPX`, `Import GPX Failed`, `hl_aw_*` route types
(`day`, `week`, `loop`, `oneway`, `outandback`, `poi`, `gym`, `station`).

### Feeds, sniper, cooldown

`Feeds`, `Quick Sniper`, `hl_fastsnipe`, `hl_feed_filter_*`,
`Cooldown: %s`, `Cooldown History`, `hl_cdhist*`,
`Please RESPECT cooldown rules to avoid softban.`, `_hl_pgp_softban`.

### Raids, rockets, gifts, accounts

`Instant Beat Team Rocket`, `instantRocket`, `instantLeader`,
`Instant ArMapping`, `hl_armapping`, `Gift Assistant`,
`GiftingRpcService_OpenGift`, `GiftingRpcService_SendGift`,
`hl_accounts_*`, `hl_account_item_name/lv/p_img`.

### Analysis and overlay

`hl_ec_pvp_gl/ul/ml`, `hl_eciv`, `hl_ff_attr_iv`, `hl_ffp_checkshiny`,
`hl_mapbox_popup_*`, `hl_mbmap_*`, `showMapAvatars`, `Hide PGSharp`,
`hideRaidStatus`, `hideTrainerName`.

### Licensing

`https://www.pgsharp.com/activation`, `hl_activate_dialog`,
`hl_settings_object_activate`, `The feed is limited (Trial/Free License).`,
`Please upgrade to standard license to create/enable more filters.`,
`This feature is not available for %s license.`,
`Please activate before sign in.`

## Anti-cheat

Untouched. Quago root detection and Play Integrity remain in the package.
The mod does not remove or disable them. This means a rebuilt client is still
subject to the game's integrity checks and to server-side ban risk.

## Not recovered

- Lua script bodies (loaded at runtime; absent from the APK).
- Original signing private key.
- Recompilable source for `libhela.so` / `libil2cpp.so`.
- Activation protocol (no network capture available).

## Confidence

| Claim | Confidence |
|---|---|
| Package/version/ABI | High — manifest |
| XOR `0x0D` string cipher | High — known plaintext |
| `libhela.so` host | High — ELF SONAME |
| Dobby hooking | High — symbol strings |
| Lua 5.1.5 | High — version banner + API names |
| Feature list | Medium–High — strings/resources; runtime confirmation pending |
| VirtualAPK plugin path | Low–Medium — strings present, manifest absent |
