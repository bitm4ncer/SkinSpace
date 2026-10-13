# SkinSpace

Classic Windows Media Player skins and visualizers for VLC (skins2) -- built as
faithfully as possible: original assets converted 1:1, no redrawing. VLC's own
visualizers run right inside the skin screen. Unofficial fan project.

## INCLUDED SKINS

```text
Skin          Status           Files (dist/)
-----------   --------------   ------------------------------------------
Headspace     finished (v1.0)  Headspace.vlt      (1x, 549x394)
<more>        planned          Headspace-2x.vlt   (2x, pixel look)
                               Headspace-3x.vlt   (3x, pixel look)
```

## QUICK START

Requirements: VLC 3.0.x (tested: 3.0.23, Windows).

**Option 1 -- starter bat (recommended, no admin needed):**

```text
skins/headspace/Start-Headspace.bat              (normal, EQ enabled)
skins/headspace/Start-Headspace-Visualizer.bat   (with projectM in the screen)
```

**Option 2 -- command line:**

```text
"C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins ^
    --skins2-last="C:\...\dist\Headspace-2x.vlt"
```

**Option 3 -- install into VLC:** copy the `.vlt` to
`C:\Program Files\VideoLAN\VLC\skins\` and select it in VLC:
*Tools > Preferences > Interface > "Use custom skin"* (restart required).

> **Playlist note:** by default the skin shows VLC's playlist root nodes
> ("Playlist"/"Media Library") as rows. With `--no-media-library` (see the
> starter bats) the list is clean, just like the original.

> **WARNING 1:** "Open skin..." (context menu) can crash VLC (reproduced on
> 3.0.23). Workaround: restart VLC via the starter bat / `--skins2-last`.

> **WARNING 2:** If VLC will not start after a crash, clear the folder
> `%APPDATA%\vlc\crashdump` -- a left-over crash dump blocks every start
> (known VLC 3.0.x behavior).

## CONTROLS

```text
Element                       Function
---------------------------   --------------------------------------------
Forehead left / right         Minimize / Close
Forehead center               Previous | Play | Stop | Next
                              and the "sun" = Open media
(during playback)             Pause button appears over Play
Chin left (bars icon)         Equalizer drawer (left ear) open/close
Chin right (list icon)        Playlist drawer (right ear) open/close
Chin center (bracket icon)    Preferences
Seekbar                       Seek via click / drag
Head                          Drag the window
Drag & drop                   Drop media onto the window -- videos and
                              visualizers show up in the head screen
```

**Equalizer drawer:**

- 10 band sliders + Volume: take effect **immediately** during playback and
  are saved for the next session.
- VLC's equalizer filter is **off** by default; the starter bats enable it on
  launch (like the original, where the EQ was always active). Alternatively
  click the "reset" link once (on; LED lit = active), click again = off.
- The "Volume" label doubles as the mute indicator: it reads "Volume" normally and
  shows a struck-through label while muted. Click it to mute/unmute.
- "reset" link = **equalizer on/off**. A true gain reset is technically not
  possible in the VLC skin system (the engine offers no reset command).
- "Preamp" slider (originally Balance): controls the EQ pre-amp (+/-20 dB,
  live). VLC skins cannot bind Balance -- so it was repurposed and relabeled.

**Playlist drawer:**

- Per-row checkboxes and the scrollbar with arrows are **rebuilt original
  artwork**. VLC has no per-item state (the boxes are always "on") and no
  arrow scrolling (scroll with the mouse wheel or drag the thumb).
- The bottom right shows the **current track time** ("00:04 / 00:30"). A
  duration column per row is not possible: VLC only hands the skin the title
  strings.

## VISUALIZERS (goom / projectM in the head screen)

VLC's own visualizers run inside the skin screen. Enable via start option:

```text
--audio-visual=projectm        (alternative: --audio-visual=goom)
```

Ready-made starter: `skins/headspace/Start-Headspace-Visualizer.bat` (projectM).

- The visualizer cannot be switched from within the skin -- VLC offers no
  visualizer actions to skins. The original Headspace had a "WhiteCap Viz"
  chooser at the top of the screen; reproducible as pure artwork if wanted.
- projectM presets (`.milk`) can be configured in VLC; the upcoming VLC pack
  will ship a small curated selection.
- In development: **"Bitmancer Visualizer Pack"** -- custom retro and modern
  visualizers (100% own code).

## INSTALLER & PACKS (work in progress)

An Inno Setup installer with its own package manager is planned (German UI,
uninstall/repair included). Design and implementation plan live under `docs/`.

```text
Packs (individually selectable):

[x] VLC pack        Headspace skins 1x/2x/3x, curated projectM presets,
                    VLC detection + version warning, optional portable
                    MilkDrop 3; sets skins2-last in the vlcrc (with backup)

[ ] WMP pack        Original .wmz from the WMP Goodies archives + original
                    WMP visualizers (Alchemy, Battery & co.; admin rights
                    required). Experimental: WMP visualizers in the VLC
                    screen (feasibility spike: GO for GDI viz)

[ ] Winamp pack     MilkDrop 2 (community fix) + AVS for Winamp/WACUP;
                    MilkDrop 3 standalone for everyone

[x] Bitmancer pack  Custom visualizers (own code, safe to redistribute;
                    retro DLLs + modern presets) -- in development
```

Engine features: manifest with **mandatory SHA256** for all downloads, mirror
chains, BYO picker when sources are dead (hash match only), journal with
uninstall/repair/resume, vlcrc editor with backup/restore. CLI:

```text
Install-<Project>.ps1 [-Packs vlc,wmp,winamp] [-DryRun] [-OfflinePath <dir>] [-Resume]
```

Recommended: VLC >= 3.0.24 (security fix in the skins2 loader); tested on 3.0.23.

## KNOWN DEVIATIONS FROM THE ORIGINAL (technical limits, documented)

- No "disabled" button artwork (skins2 only knows up/hover/down states).
- Ear drawers open **without slide animation** (no motion animation support).
- The cursor does not switch to a hand cursor (not provided by the skin system).
- The "reset" link toggles the EQ instead of zeroing gains.
- Balance cannot be bound in VLC skins -- the slider was repurposed into a
  working pre-amp (label adjusted).
- Visualizer selection/name is not possible inside the skin (see above).
- Playlist checkboxes are decorative, the arrows do not scroll; no per-row
  duration (see Controls).
- Download progress in the seekbar (original artwork) is omitted.

## REPO LAYOUT (multi-skin)

```text
SkinSpace/
|
+-- skins/
|   +-- headspace/              skin #1 (more will live next to it)
|       +-- theme/              build sources: XML fragments, images, fonts
|       +-- variants/           staged 2x/3x variants (generated)
|       +-- originals/          original raw files (WMZ, bitmaps, previews)
|       +-- Start-Headspace.bat
|       +-- Start-Headspace-Visualizer.bat
|
+-- tools/                      shared build chain (-Skin <name>)
+-- dist/                       finished .vlt files for all skins
+-- research/, docs/            project knowledge & docs
+-- README.md, RESUME.md
```

Adding a new skin:

1. Create `skins/<name>/` (with `theme/` and `originals/`)
2. Put the original assets into `originals/extracted/`
3. Adjust the XML fragments/images in `theme/`
4. Run the chain with `-Skin <name>` (see below)

## BUILD CHAIN (for the curious)

```text
Original (.wmz / bitmaps)
      |
      v
tools/make_*.ps1      -->  skins/<name>/theme/  (PNG32 + fragments)
      |
      v
tools/build_theme.ps1 -->  theme.xml (with built-in validation)
      |
      v
tools/pack.ps1        -->  dist/<Skin>.vlt  -->  VLC 3.0.x (skins2)
      |
      +-- tools/build_variants.ps1  -->  dist/<Skin>-2x.vlt / -3x.vlt
```

Calls (default skin: `headspace`):

```text
tools/make_original_assets.ps1 -Skin headspace   # BMP -> PNG32 (+ bitmaps.xml)
tools/make_extra_assets.ps1 -Skin headspace      # LED/fill/link/playlist artwork
tools/make_track_assets.ps1 -Skin headspace      # slider tracks from original tiles
tools/build_theme.ps1 -Skin headspace -Scale 1   # theme.xml + validation
tools/pack.ps1 -Skin headspace                   # -> dist/Headspace.vlt
tools/build_variants.ps1 -Skin headspace         # -> dist/Headspace-2x/-3x.vlt
```

Test suites (click-free): `tools/tests/run_task5.ps1`, `run_task6.ps1`

Detailed docs: `research/` (reverse engineering, mapping, spike results) and
`docs/` (specs + plans, incl. distribution/installer).

## CREDITS & NOTES

- Original skin **"Headspace" (c) 2000/2001 Microsoft Corporation** -- official
  WMP skin. Assets from the Internet Archive backup of the Microsoft skin
  collection (archive.org/details/windowsmediaplayerskinscollection).
  All rights to the original belong to Microsoft.
- "VLC" is a trademark of the VideoLAN organization. This project is
  unofficial and not affiliated with VideoLAN or Microsoft.
- Non-commercial fan project, use at your own risk.

---

Have fun -- and remember: this project lives from the originals.
Thanks, Microsoft, 2000/01.
