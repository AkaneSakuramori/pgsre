# Asset inventory

This page inventories the mod's resource surface **by name and count**. No
images, binaries, or game assets are stored in this repository.

## Totals

| Category | Count |
|---|---:|
| Resource entries | 2,198 |
| Resource directories | 234 |
| `hl_*` identifiers | 968 |
| PNG images | 874 |
| XML resources | 1,172 |
| JSON assets | 72 |
| Lua scripts shipped | 0 |

## Mod resource prefixes

| Prefix | Meaning |
|---|---|
| `hl_` | Hela — mod UI (settings, feeds, accounts, cooldown, map) |
| `JoystickView_` | virtual joystick styleable |
| `Pgp` / `pgp_` | PGSharp core |
| `Hela` / `hela_` | loader and threads |

## Layouts

```
hl_settings
hl_settings_account
hl_settings_autowalk
hl_settings_cooldown
hl_settings_feeds
hl_settings_map
hl_settings_object_activate
hl_settings_quick_sniper
hl_floatmenu_autowalk
hl_floatmenu_bns
hl_floatmenu_feeds
hl_floatmenu_map
hl_floatmenu_settings
hl_floatmenu_speed
hl_floatmenu_toc
hl_floatmenu_tp
hl_activate_dialog
hl_accounts
hl_account_item
hl_feeds_main
hl_feeds_item
hl_cdhist
hl_cdhist_cat
hl_mapbox_popup
hl_mapbox_popup_teleport
hl_fastsnipe
hl_armapping
hl_arplus
hl_curveball
hl_excellent
hl_enhanced_throw
hl_spoofing
hl_teleport
hl_speed_seek
hl_autogenerate_gpx_pat
```

## Drawable / string families

| Family | Examples |
|---|---|
| Accounts | `hl_accounts_*`, `hl_account_item_name`, `hl_account_item_lv`, `hl_account_item_p_img` |
| Feeds | `hl_feeds_cat_pokemon`, `hl_feeds_cat_quest`, `hl_feeds_cat_raid`, `hl_feeds_cat_misc`, `hl_feed_filter_*` |
| Autowalk | `hl_aw_day`, `hl_aw_week`, `hl_aw_loop`, `hl_aw_oneway`, `hl_aw_outandback`, `hl_aw_poi`, `hl_aw_gym`, `hl_aw_station` |
| Cooldown | `hl_cooldown_timer`, `hl_cdhist_*`, `hl_cdhist_cat_pgslog` |
| Map | `hl_mbmap_*`, `hl_mapbox_popup_*`, `hl_mapbox_popup_teleport` |
| IV / PvP | `hl_eciv`, `hl_ec_pvp_gl`, `hl_ec_pvp_ul`, `hl_ec_pvp_ml`, `hl_ff_attr_iv`, `hl_ffp_checkshiny` |

## Joystick

`JoystickView_JV_*` styleable attributes define the floating joystick
appearance and behavior.

## Runtime scripts (not shipped)

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

## Extract locally

```bash
apktool d -f -o apktool input.apk
# resources: apktool/res/  (PNG, XML)
# assets:    apktool/assets/
# natives:   apktool/lib/arm64-v8a/
```

Do not commit the extracted tree.
