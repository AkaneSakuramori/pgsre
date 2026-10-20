# Indicators of compromise

## Certificate

```
Subject: CN=hela, OU=uw, O=uw, L=uw, ST=uw, C=uw
SHA-256: E6:01:D7:E0:38:3F:0C:C1:E0:F0:A4:24:33:94:E4:2C:AF:BA:6E:7C:ED:F1:AF:37:7F:90:52:C3:A0:0A:46:A4
SHA-1:   69:FF:D0:B7:40:73:0C:71:E1:A5:F0:C0:2B:4C:E0:16:AA:B9:2E:51
Validity: 2020-01-04 → 2047-05-22
```

## Files

| File | Value |
|---|---|
| `lib/arm64-v8a/libmain.so` | SHA-256 `c3f93191436481b347fab8cb33113ea36cbf60744dccb9e99924788d7f403b4b` |
| | SONAME `libhela.so`, 38,312,416 bytes |
| `lib/arm64-v8a/libil2cpp.so` | 252,381,992 bytes |
| `assets/bin/Data/Managed/Metadata/global-metadata.dat` | 35,873,276 bytes, magic `0xfab11baf`, v39 |
| `META-INF/HELA.RSA` / `HELA.SF` | signer block |

## Strings

```
DobbySymbolResolver
sethook
unhook
hook_sym_addr
hook_sym_name
Duplicate hook
LuaVersion: Ruby 5.1.5  Copyright (C) 1994-2018 Ruby.org, PUC-Rio
Hela.LoadedPlugin
Hela/SoLibraryLoader
Hela/Mbgl-MapRenderer
plg.enablespoof
pgo.il2ready
```

## Paths

```
/tmp/hela/lua/
/data/local/tmp/hela/lua/test.lua
/data/local/tmp/hela/lua/debug.lua
```

## Network

```
https://www.pgsharp.com/activation
https://www.pgsharp.com/download64
https://api.quago.io/v1/record          (anti-cheat, stock)
```

## Resources

```
hl_activate_dialog
hl_settings_object_activate
hl_floatmenu_*
Hide PGSharp
Please RESPECT cooldown rules to avoid softban.
The feed is limited (Trial/Free License).
Please upgrade to standard license to create/enable more filters.
This feature is not available for %s license.
```

## Behavioral

- Injects an overlay and floating joystick into a Unity game.
- Loads Lua from `/tmp/hela/lua/`.
- Hooks game functions via Dobby.
- Presents PGSharp activation/trial UI.
- Leaves Quago and Play Integrity intact.
