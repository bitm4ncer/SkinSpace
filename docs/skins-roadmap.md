# SkinSpace Roadmap

Porting classic Windows Media Player skins (.wmz, 2000-2008) to VLC (skins2).
Sources: the [Internet Archive collection](https://archive.org/details/windowsmediaplayerskinscollection)
and the curated [WMP Skins Archive](https://wmpskinsarchive.neocities.org/).

## Status

| Skin | Status |
|---|---|
| Headspace (Microsoft) | **done** (v1.0: 1x/2x/3x in `dist/`) |
| 9SeriesDefault ("Corona", WMP9 default) | **in design** |

## Wishlist (curated by the user)

Checked against the full official VLC skin gallery (2026-10): **none of these
exist for VLC yet** -- the only WMP-related VLC skins are WMP11/WMP12
look-alikes ("Media Player 12", "WMP 12", "WMP11", "Win VLC 11") plus
"Alienware Darkstar".

| Skin | Origin | Notes |
|---|---|---|
| Cerulean | Microsoft | designer classic |
| Crimson Skies | Microsoft (game tie-in) | |
| cyberchannel | Microsoft | |
| deepbluesomething | Microsoft | |
| Disney Mix Central | Microsoft (Disney tie-in) | |
| Frostbite | Microsoft | |
| Gold | Microsoft | |
| Half-Life 2 | game tie-in | |
| Goo | Microsoft | |
| Halo 2 Combat Media Player | game tie-in | |
| Ice | Microsoft | |
| Lost Planet | game tie-in | |
| Mandalay | Microsoft | |
| Mecha (Plus!) | Microsoft Plus! DME | |
| Official Xbox Skin for WMP (MPXP, alternate version) | Microsoft | |
| QuickSilver | Microsoft | |
| Rusty | Microsoft | |
| Secura | Microsoft | |
| T3: Skynet Media Player | movie tie-in | |
| TDK Digital MixMaster | TDK | hardware brand |
| The Unit | Microsoft | |

Porting order is decided per skin (recommended next candidates after
9SeriesDefault: the compact "designer classics" -- small asset sets, fast
wins -- before the big movie/game tie-ins).

## Conventions (from the Headspace port)

- Original skin assets as the base (screen opening adjusted where needed),
  plus 1x/2x/3x variants (nearest look)
- One repo skin folder per port: `skins/<name>/{theme,variants,originals}`
- Shared build chain: `tools/*.ps1 -Skin <name>`
- Engine limits are adapted and documented (e.g. Balance -> Preamp,
  "reset" link = EQ on/off, visualizers via `--audio-visual`)
- Fan project: unofficial, non-commercial, credits to the original authors
  (Microsoft Corporation / The Skins Factory / brand owners)
