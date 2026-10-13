# Headspace → VLC skins2 — Konsolidiertes Mapping (Synthese)

Stand: 2026-10-13. Quellen: `01-vlc-skins2-research.md` (Code-belegt), `02-headspace-reverse-engineering.md`,
`03-wmp-format-ecosystem.md`. Legende: ✅ 1:1 möglich · 🟡 Workaround/Abweichung (durch Bounty-Regeln gedeckt) · ❌ nicht möglich.

## A. Transport-Controls (Stirn)
| Original | VLC skins2 | Status |
|---|---|---|
| Minimize | `vlc.minimize()` | ✅ |
| Close | `vlc.quit()` | ✅ |
| Prev / Next | `playlist.previous()` / `playlist.next()` | ✅ |
| Play | `vlc.play()` (Button) | ✅ |
| Pause | `vlc.pause()`, `visible="vlc.isPlaying"` — exakt über Play-Kreis platziert wie im Original | ✅ |
| Stop | `vlc.stop()` | ✅ |
| Viz-Button | Visualisierung nicht skin-steuerbar → umwidmen (z. B. Screen-Toggle) oder entfernen (Bounty: „removing buttons that no longer have a use in VLC") | ❌/🟡 |
| Mapping-Bitmaps (play_controls_map) | skins2 kennt keine Farb-Mapping-Gruppen → beim Build in Einzel-Buttons mit je up/over/down zerschneiden | 🟡 |
| Tooltips | `tooltiptext` (+ `$`-Variablen dynamisch) | ✅ |

## B. Fenster & Form
| Original | VLC skins2 | Status |
|---|---|---|
| Kopf-Form ohne Rahmen, Magenta-Transparenz | Alpha-PNGs + `alphacolor` + `SetWindowRgn`; Click-Through echt | ✅ |
| Ziehen überall am Kopf | `<Image action="move">` (Drag-Handle) erforderlich | ✅ |
| `resizable="false"` | Layouts ohne resize-Handles; optional `min/max` | ✅ |
| (WMP: kein onTop) | optional `vlc.onTop()` | ✅ |

## C. Seek-Bereich (Kinn)
| Original | VLC skins2 | Status |
|---|---|---|
| Seek-Slider (progressbar + thumb, borderSize=9) | `<Slider value="time">` + SliderBackground/Thumb-Grafiken | ✅ |
| Download-Progress als 2. Ebene | nicht in skins2 (kein Sekundär-Fortschritt) → Positionsanzeige einzeln | 🟡 |
| 00:00-Zeit | `<Text text="$T">` (`$D` Dauer, `$L` Restzeit) | ✅ |

## D. Screen (Gesicht)
| Original | VLC skins2 | Status |
|---|---|---|
| Visualisierungen (effects) | vom Skin nicht steuerbar/garantiert; Einbettung von in Prefs aktivierten Viz in `<Video>` = [UNCERTAIN] → Experiment nötig | ❌/🟡 |
| Video (automatisch statt Viz) | `<Video>`-Control, eingebettet (`skinned-video` Default an) | ✅ |
| Viz-Auswahl (prev/next/close + Presettitel) | ersatzlos streichen (Bounty: „asset name overhang" darf verschoben/entfernt werden) | 🟡 |
| Idle-Optik | statische/animierte Bitmap (`nframes/fps/loop` = Frame-Animation) | 🟡 |
| Bonus | Album-Cover via `<Image art="true">` | ✅ |

## E. Linkes Ohr (EQ-Drawer)
| Original | VLC skins2 | Status |
|---|---|---|
| Balance-Slider (-100..100) | **Balance gibt es in skins2 NICHT** → ersetzen (z. B. Mute-Toggle `vlc.mute()` + `vlc.isMute`) oder entfernen; Layout minimal anpassen | ❌/🟡 |
| Volume-Slider | `<Slider value="volume">` (+ `$V`-Tooltip) | ✅ |
| 10-Band-EQ (eq1..eq10, ±14) | `<Slider value="equalizer.band(0)">…(9)` — **voll unterstützt**; Referenz: EQ-Fenster in `default.vlt`; optional `equalizer.preamp` | ✅✅ |
| EQ an/aus | Checkbox `state="equalizer.isEnabled"` + `equalizer.enable()/disable()` | ✅ |
| Reset-Link (eq.reset()) | keine Reset-Action → durch EQ-enable-Link ersetzen (funktional!) | 🟡 |
| Drawer-Slide 207→0 (animiert) | keine Bewegungsanimation → Layout-Switch (instant) oder separates Fenster; Bounty-Ausnahme: „ear slide out if it is not possible" | 🟡 |

## F. Rechtes Ohr (Playlist-Drawer)
| Original | VLC skins2 | Status |
|---|---|---|
| Playlist (Name/Time, keine Spalten sichtbar, Scroll) | `<Playtree flat="true">` + Pflicht-`<Slider>`-Kind; Text einzeilig, Scroll per Mausrad/Tasten + selbstgebaute Scroll-Buttons; keine Duration-Spalte (→ Tooltip `$N/$T`) | 🟡 |
| Drawer-Slide 277→488 + Fenster-Resize 549→760 | wie E: Layout-Switch/Fenster-Resize (instant) oder separates Fenster | 🟡 |
| Dropdown-Menü der Playlist | WMP-UI → streichen | 🟡 |

## G. Sonstiges
| Original | VLC skins2 | Status |
|---|---|---|
| „Return to Full Mode" | kein Media Center → `dialogs.changeSkin()` (Skin-Auswahl) oder `dialogs.prefs()`; sonst streichen | 🟡 |
| hidden-text-Tooltip-Trick | nicht nötig (dynamische `tooltiptext`) | ✅ |
| mediacenter.effect-Persistenz | hinfällig | — |

## Fensterstrategie für die Ohren — Optionen
1. **Separate Fenster** je Ohr (`<Window id="eqwin">`, `<Window id="plwin">`) mit `Anchor`-Docking/Magnet; Öffnen/Schließen via Checkbox (`WindowID.show()/hide()`, `state="...isVisible"`) — **Standard-skins2-Pattern (default.vlt), von der Bounty explizit erlaubt** („detached ear menus").
2. Ein Fenster mit mehreren `<Layout>`s (geschlossen / EQ offen / PL offen / beides), Umschalten per `WindowID.setLayout(LayoutID)` — window-resize inklusive, aber ohne Slide-Animation und mit viel XML-Duplikation.
3. Hybrid (Fenster + Layouts).
**Empfehlung: Option 1** (robust, wartbar, bounty-konform; Slide-Animation ist ohnehin unmöglich und explizit ausgenommen).

## Asset-Pipeline (Uprez)
- Kritisch: `head.bmp` (234×394), `left_ear.bmp` (84×170), `right_ear.bmp` (87×170) → 3–4× Upscale (z. B. Real-ESRGAN/xBRZ) + manuelles Retouch; Alpha aus Magenta (#FF00FF) ableiten.
- Buttons (play_controls 144×25, EQ/PL-States), Drawer-Segmente, `viz_drop` (174×26), `progressbar` (163×9), Thumbs → upscalen.
- Flächen (`drawer_bkgrnd_*`, `vid_bkgd` 216×159/159, teils 1bpp) → prozedural neu zeichnen.
- PNG 32-bit + `alphacolor` setzen (3.0-Konvention); Sprite-Sheets als `Bitmap`+`SubBitmap`.

## skin-Technik-Checkliste (aus 01)
- Wurzel: `theme.xml`, `<Theme version="2.0">` (Pflicht!) · `.vlt` = zip **oder** tar.gz
- Ablage: `C:\Program Files\VideoLAN\VLC\skins` (Admin) — oder ohne Admin: Rechtsklick im Skin → *Open skin…* / Start `vlc -I skins --skins2-last=<pfad>`
- Fehlersuche: `vlc -vvv` → „bad theme", „unknown action", „non-unique id", „check resize policy"
- `skins2-transparency` Option aktivieren nur falls Fenster-Alpha gewünscht

## Vor dem Vollausbau zu testende Experimente
1. Eigenständiges Minimal-`.vlt` mit `<Video>`-Control + Videodatei → Einbettung ok?
2. `<Layout>`-Umschaltung: Window-Resize-Verhalten, optische Akzeptanz (statt Slide).
3. Visualisierung in Prefs aktivieren + Skin-Video-Control → erscheint die Viz? (entscheidet Screen-Konzept)
4. Uprez-Qualität an `head.bmp` prototypisch (1 Asset) vor Massenlauf.
5. DTD-Konformität + Loader-Logcheck, Fehlerfallverhalten (Fallback default.vlt).
