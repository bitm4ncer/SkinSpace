# 02 – Headspace (offizieller Microsoft-WMP-Skin) – Reverse-Engineering-Dokumentation

| Feld | Wert |
|---|---|
| Gegenstand | Skin „headspace" (Theme-ID `headspace`), Original: `Headspace.wmz` (ZIP), entpackt: 82 Dateien |
| Quelle der Dateien | `C:\GitHub\VLC_Skins\research\original\extracted\` (unverändert gelassen) |
| Herkunft | https://archive.org/download/windowsmediaplayerskinscollection/Headspace.wmz |
| Werkzeuge | `headspace.wms` (531 Zeilen, XML) + `headspace.js` (147 Zeilen, JScript) zeilenweise gelesen; 80 BMPs mit PowerShell/System.Drawing vermessen (Maße, Bytegröße, Pixel-/Farbanalysen); Schichtmodell per eigener Composite-Rekonstruktion verifiziert |
| Verifikationsartefakte | `research/previews/states/state-A-closed.png`, `state-B-eq-open.png`, `state-C-pl-open.png`, `state-D-vis-open.png` (rekonstruierte Zustände; Abgleich mit der offiziellen Vorschau `Headspace_preview.png`, 342×394 – deckungsgleich) |
| Maschinenlesbar | `research/original/inventory.csv` (82 Datensätze + Kopfzeile), `research/original/controls.json` (68 Controls) |
| Stand | 2026-10-13 |

**Lesehilfe zu Quellenangaben.** `wms Z.x` = `research/original/extracted/headspace.wms`, Zeile x. `js Z.x` = `research/original/extracted/headspace.js`, Zeile x. „abgeleitet" bedeutet: Der Wert steht nicht im XML, sondern ergibt sich aus dem referenzierten Bild (z. B. Subview-Größe = Bildgröße).

---

## 1. Herkunft & Metadaten

### 1.1 Steckbrief der Originaldatei

| Merkmal | Wert | Beleg |
|---|---|---|
| Titel / Theme-ID | `headspace` | `wms Z.5` |
| Autor | `Microsoft Corporation` | `wms Z.6` |
| Copyright | „©2000 Microsoft Corporation. All rights reserved." | `wms Z.2`, `wms Z.7`, `js Z.2` |
| Container | `.wmz` = ZIP-Archiv (SKIN-Datei-Format von WMP7+) | `Headspace.wmz`, 241.903 Bytes |
| Inhalt | 82 Dateien: 1× `.wms`, 1× `.js`, 80× `.bmp` | Verzeichnisliste |
| Formatversion | `.wms`-XML mit WMP-7-Skin-Syntax (in WMP 7/8/9/10/11/12 Legacy weiter unterstützt) | Attributsatz in `wms` |
| Skript-Abhängigkeit | 2. Skript aus einer DLL-Ressource: `res://wmploc.dll/RT_TEXT/#132;` | `wms Z.13` |
| Zeichen-Besonderheit | Datei beginnt mit UTF-8-BOM; die Copyright-Zeichen sind als 0xA9 (Latin-1 ©) gespeichert und erscheinen je nach Konsolen-Codepage als Ersatzzeichen | `wms Z.1-2`, `js Z.1-2` |

### 1.2 Zeitstempel der Dateien (Entwicklungs-Zeitachse, aus den ZIP-Metadaten)

| Datum/Zeit (lokal) | Anzahl | Dateien (Auszug) | Interpretation |
|---|---|---|---|
| 2000-01-29 09:11:46 | 47 | gesamte Transport-/Ohr-/Button-/Drawer-Grafik, `play_controls_*`, `progressbar.bmp`, `pause_*` | Erste vollständige Asset-Lieferung (WMP-7-Beta-Phase) |
| 2000-01-29 09:11:48 | 23 | `right_*`, `thumb_*`, `viz_drop*` | Zweite Lieferung am selben Tag |
| 2000-02-18 02:24:44/46 | 3 | `themebutton_01/02/03` | „Return to Full Mode"-Button kam später dazu |
| 2000-03-10 09:17:26 | 4 | `horizontal_slider/thumb`, `vertical_slider/thumb` | Slider-Grafiken nachgezogen |
| 2000-03-31 10:11:52 | 3 | `head.bmp`, `vid_bkgd.bmp`, `progressbar_foreground.bmp` | Letzte Bildkorrekturen (Gesicht, Screen, Download-Progress) |
| 2000-04-13 07:11:28 | 1 | `headspace.js` | Skript-Finalisierung |
| 2000-06-23 06:26:12 | 1 | `headspace.wms` | Skin-Definition zuletzt gespeichert – 1 Monat vor WMP 7 RTM (2000-07-25) |

Der Skin stammt damit eindeutig aus der **WMP-7-Generation (Development 2000)**, nicht aus der WMP-9-Suite – siehe 1.3.

### 1.3 Web-Herkunft und Einordnung (Quellen)

* **Wikipedia, „Windows Media Player", Abschnitt *Skinning support*** (en.wikipedia.org/wiki/Windows_Media_Player, abgerufen 2026-10-13): „The initial set of skins introduced in version 7 were **'Classic', 'Headspace', 'Miniplayer', 'Optik', 'Roundlet', 'Rusty', and 'Toothy'**." → Headspace war ein **mit WMP 7 ausgelieferter Microsoft-Skin**. Für Version 9 nennt dieselbe Quelle dagegen nur `9SeriesDefault` (nur Out-of-Band) und `Revert`; ältere Skins „are retained if the player is upgraded from a previous version". Headspace gehörte also **nicht** zum WMP-9-Default-Set, lief dort aber als installierter Skin weiter.
* **Trashworld News, „Windows Media Player Skins"** (www.trashworldnews.com/wmp-skins/): listet „**Headspace — Microsoft Corporation**" – neben weiteren Microsoft-Skins (Canvas, Heart, Toothy, Science, Claw, Classic, Optik) und Abgrenzung zu The-Skins-Factory-Titeln. Die Autorschaft Microsoft ist damit auch in der Community-Galerie belegt.
* **WMP Skins Archive** (wmpskinsarchive.neocities.org): führt „Headspace" in seiner Skin-Liste; der dort verlinkte Sammel-Download stammt von archive.org – dieselbe Quelle wie unsere `.wmz`.
* **WMP Goodies** (sites.google.com/view/wmpgoodies/skins, Seite „Skins/Page 1 (Microsoft)"): „**29. Headspace – Created By: Microsoft – Size: 237KB**" und „**30. Headspace Beta – Created By: Microsoft – Size: 236KB – There's not much difference.**" → Es existieren **zwei Fassungen** (Final + Beta).

**Einordnung der Auftrags-Hypothesen:**

* „Bestandteil der WMP9-Skinsuite" – **nur eingeschränkt richtig**: Headspace debütierte mit WMP 7 (©2000), wurde in WMP 8 (Windows XP) mitgeführt und funktionierte in WMP 9 weiter; das WMP-9-Default-Set enthielt ihn nicht. Die hier vorliegende Datei nutzt die `.wms`-Syntax, wie sie in der WMP-7/8/9-Ära geschrieben wurde (daher im Projekt „WMP9-Format").
* „Media Center?" – Der Skin **nutzt** Media-Center-nahe WMP-Objekte (`mediacenter.effectType`, `mediacenter.effectPreset` in `js Z.25-26/35-36`; „Return to Full Mode" → `view.returnToMediaCenter()` in `wms Z.113`), war aber **kein Bestandteil von Windows XP Media Center Edition**; der MCE-Skin heißt „Media Center XP" und stammt von The Skins Factory (Trashworld-Liste).
* **Beta-Indiz:** Unsere `.wmz` misst 241.903 Bytes = **236,2 KiB** und passt damit besser zu „Headspace Beta (236KB)" als zu „Headspace (237KB)". Endgültige Klärung nur durch Vergleich beider Varianten möglich (siehe §7).

**Rechtlicher Hinweis für den Port:** Das Werk ist urheberrechtlich geschützt (©2000 Microsoft, all rights reserved). Für eine nicht-kommerzielle Neuinterpretation (Reddit-Bounty-Kontext, Projekt `00-plan.md`) sollten Grafiken nicht 1:1 weiterverbreitet, sondern neu gezeichnet/upgeresed und die Herkunft kenntlich gemacht werden.

---

## 2. Asset-Inventar (alle 80 BMPs)

Vollständige maschinenlesbare Liste inkl. Bytegrößen: `research/original/inventory.csv` (82 Datensätze; Spalten `file,bytes,width,height,format,states,role`). Die Spalte „Zustand" folgt der kanonischen Notation aus der Aufgabe (`01_default/02_rollover/03_down/04_disabled`); die Dateinamen von EQ/PL nutzen Kurzformen (`01_DF/02_RV/03_Dwn/04_Dis`) – im CSV auf die kanonischen Namen normalisiert. **Uprez-Flag** in der letzten Spalte: `kritisch` > `hoch` > `mittel` > `niedrig` > `nein` (Kriterium: Detailgrad × geplante Skalierung; alle Flächen sind für 96 dpi/1× gebaut – für einen 2×/3×-Port müssen Fotos neu skaliert werden).

### 2.1 Kopf, Screen, Fenstersteuerung (7)

| Datei | Maße | Bytes | Zustand | Rolle / Besonderheit | Uprez |
|---|---|---|---|---|---|
| `head.bmp` | 234×394 | 277.430 | keyed | **Hauptgrafik Gesicht.** 31.487 px Magenta `#FF00FF` (Screen-Öffnung) + 17.909 px Rot `#FF0000` (Außen-Clip) – beide Farben sind Schlüsselfarben, kein Motiv | kritisch |
| `vid_bkgd.bmp` | 216×159 | 4.514 | – | **1bpp!** Schwarz = Screen-Fläche, Weiß = geclippte Ecken (`clippingColor #FFFFFF`); 1 px höher als das 158-px-Subview | nein |
| `minimize_close_01_default.bmp` | 29×16 | 1.464 | 01_default | Strip Minimieren+Close | hoch |
| `minimize_close_02_rollover.bmp` | 29×16 | 1.464 | 02_rollover | s. o. | hoch |
| `minimize_close_03_down.bmp` | 29×16 | 1.464 | 03_down | s. o. | hoch |
| `minimize_close_04_disabled.bmp` | 29×16 | 1.464 | 04_disabled | s. o. | hoch |
| `minimize_close_map.bmp` | 29×16 | 1.464 | map | **Mapping-Image** (nie gezeichnet): `#FF00CC` = Minimize (x 0–13, 224 px), `#CC0066` = Close (x 15–28, 224 px); Spalte 14 + Hintergrund (`#ADFF2B`-Grün) inert | nein |

### 2.2 Transport-Strip und Pause (8)

| Datei | Maße | Bytes | Zustand | Rolle / Besonderheit | Uprez |
|---|---|---|---|---|---|
| `play_controls_01_default.bmp` | 144×25 | 10.856 | 01_default | **Transport-Strip**: prev/play/stop/next/vis in einem Bild | hoch |
| `play_controls_02_rollover.bmp` | 144×25 | 10.856 | 02_rollover | weicht in 1.413 px ab (alle 5 Buttons leuchten) | hoch |
| `play_controls_03_down.bmp` | 144×25 | 10.856 | 03_down | – | hoch |
| `play_controls_04_disabled.bmp` | 144×25 | 10.856 | 04_disabled | weicht in 3.197 px ab (stärkste Abweichung) | hoch |
| `play_controls_map.bmp` | 144×25 | 10.856 | map | **Mapping-Image** (nie gezeichnet): 5 Kreise à 23 px (y 1–23) | nein |
| `pause_01_default.bmp` | 23×23 | 1.712 | 01_default | **Pause-Overlay** exakt über dem Play-Button; 68 Magenta-Pixel = runde Ecken | hoch |
| `pause_02_rollover.bmp` | 23×23 | 1.712 | 02_rollover | – | hoch |
| `pause_03_down.bmp` | 23×23 | 1.712 | 03_down | **kein 04_disabled vorhanden** | hoch |

Mapping-Farben und Klickregionen von `play_controls_map.bmp` (je genau 461 px, alle punktförmig geprüft):

| Element | Mapping-Farbe | Region (x/y) | Mittelpunkt | Absolut (View, +48/+31) |
|---|---|---|---|---|
| `prevelement` | `#FF0033` | x 1–23, y 1–23 | 12/12 | 310–332 / 32–54 |
| `playelement` | `#FFFF00` | x 26–48, y 1–23 | 37/12 | 335–357 / 32–54 |
| `stopelement` | `#00FF00` | x 52–74, y 1–23 | 63/12 | 361–383 / 32–54 |
| `nextelement` | `#00FFFF` | x 77–99, y 1–23 | 88/12 | 386–408 / 32–54 |
| `buttonelement id="vis"` | `#0000FF` | x 119–141, y 1–23 | 130/12 | 428–450 / 32–54 |

Zwischen next und vis liegt eine **bewusst leere Zone x 100–118** (19 px) – der vis-Button ist optisch abgesetzt (Sonne/Rad).

### 2.3 Übrige Bedienelemente auf dem Kopf (16)

| Datei | Maße | Bytes | Zustand | Rolle | Uprez |
|---|---|---|---|---|---|
| `EQ_01_DF.bmp` | 20×19 | 1.196 | 01_default | EQ-Toggle `bEq` (Drawer links) | hoch |
| `EQ_02_RV.bmp` | 20×19 | 1.196 | 02_rollover | – | hoch |
| `EQ_03_Dwn.bmp` | 20×19 | 1.196 | 03_down | – | hoch |
| `EQ_04_Dis.bmp` | 20×19 | 1.196 | 04_disabled | – | hoch |
| `PL_01_DF.bmp` | 19×20 | 1.256 | 01_default | Playlist-Toggle `bPl` (Drawer rechts) | hoch |
| `PL_02_RV.bmp` | 19×20 | 1.256 | 02_rollover | – | hoch |
| `PL_03_Dwn.bmp` | 19×20 | 1.256 | 03_down | – | hoch |
| `PL_04_Dis.bmp` | 19×20 | 1.256 | 04_disabled | – | hoch |
| `themebutton_01_default.bmp` | 35×31 | 3.404 | 01_default | „Return to Full Mode" | hoch |
| `themebutton_02_rollover.bmp` | 35×31 | 3.404 | 02_rollover | – | hoch |
| `themebutton_03_down.bmp` | 35×31 | 3.404 | 03_down | **kein 04_disabled** | hoch |
| `thumb_01_default.bmp` | 18×9 | 558 | 01_default | Seek-Thumb (8 Magenta-Pixel = Ecken) | hoch |
| `thumb_02_rollover.bmp` | 18×9 | 558 | 02_rollover | – | hoch |
| `thumb_03_down.bmp` | 18×9 | 558 | 03_down | **kein 04_disabled** | hoch |
| `progressbar.bmp` | 163×9 | 4.484 | – | Seek-Track: grauer Doppel-Gradient (Maximum `#C5C5C5` um x ≈ 80 = Mitte; Ränder ≈ `#212121`/`#262626`), unten grüne Kante (`#34BF00` in y 7–8), Höhenprofil y 0 dunkel → y 3/4 hell → y 6 Highlight | hoch |
| `progressbar_foreground.bmp` | 163×9 | 4.484 | – | Download-Fortschritt, violetter Doppel-Gradient (Maximum `#DFA6DF` bei x = 80), gleiches Höhenprofil | hoch |

### 2.4 Visualisierungs-Auswahl „vizDrop" (13)

| Datei | Maße | Bytes | Zustand | Rolle | Uprez |
|---|---|---|---|---|---|
| `viz_drop.bmp` | 174×26 | 13.678 | – | Pille (Trägerfläche), 352 Magenta-Pixel (Rundungen) | hoch |
| `viz_drop_L_01_default.bmp` | 22×21 | 1.484 | 01_default | Previous-Button | hoch |
| `viz_drop_L_02_rollover.bmp` | 22×21 | 1.484 | 02_rollover | – | hoch |
| `viz_drop_L_03_down.bmp` | 22×21 | 1.484 | 03_down | – | hoch |
| `viz_drop_L_04_disabled.bmp` | 22×21 | 1.484 | 04_disabled | – | hoch |
| `viz_drop_R_01_default.bmp` | 22×21 | 1.484 | 01_default | Next-Button | hoch |
| `viz_drop_R_02_rollover.bmp` | 22×21 | 1.484 | 02_rollover | – | hoch |
| `viz_drop_R_03_down.bmp` | 22×21 | 1.484 | 03_down | – | hoch |
| `viz_drop_R_04_disabled.bmp` | 22×21 | 1.484 | 04_disabled | – | hoch |
| `viz_drop_X_01_default.bmp` | 13×13 | 576 | 01_default | Close-Button | hoch |
| `viz_drop_X_02_rollover.bmp` | 13×13 | 576 | 02_rollover | – | hoch |
| `viz_drop_X_03_down.bmp` | 13×13 | 576 | 03_down | – | hoch |
| `viz_drop_X_04_disabled.bmp` | 13×13 | 576 | 04_disabled | – | hoch |

### 2.5 Linkes Ohr / EQ-Drawer (14)

| Datei | Maße | Bytes | Zustand | Rolle / Besonderheit | Uprez |
|---|---|---|---|---|---|
| `left_ear.bmp` | 84×170 | 42.894 | – | Lautsprecher-Turm; **2.265 Magenta-Pixel** als Außenkontur, verteilt links: Spalte 0 = 155 px magenta, ab Spalte 51 = 0 px, rechts (Sp. 70–83) 1–10 px | kritisch |
| `L_drwr_open_01_default.bmp` | 18×66 | 3.752 | 01_default | Handle `bEqHandle` **geschlossen** (Open-Symbol); 328 Magenta-Pixel | mittel |
| `L_drwr_open_02_rollover.bmp` | 18×66 | 3.752 | 02_rollover | weicht 480 px ab (Button leuchtet) | mittel |
| `L_drwr_open_03_down.bmp` | 18×66 | 3.752 | 03_down | – | mittel |
| `L_drwr_close_01_default.bmp` | 18×66 | 3.752 | 01_default | Handle **offen** (Close-Symbol); 164 px Unterschied zu `open_01` (Symbol-/Pfeilrichtung) – wird per Skript getauscht (`js Z.75-77`) | mittel |
| `L_drwr_close_02_rollover.bmp` | 18×66 | 3.752 | 02_rollover | – | mittel |
| `L_drwr_close_03_down.bmp` | 18×66 | 3.752 | 03_down | – | mittel |
| `L_drwr_04_disabled.bmp` | 18×66 | 3.752 | 04_disabled | **toter Asset**: im XML nirgends referenziert (kein `disabledImage` am Handle) | niedrig |
| `left_X_01_default.bmp` | 11×11 | 450 | 01_default | Close-X des EQ-Drawers | mittel |
| `left_X_02_rollover.bmp` | 11×11 | 450 | 02_rollover | – | mittel |
| `left_X_04_disabled.bmp` | 11×11 | 450 | 04_disabled | **kein 03_down** | mittel |
| `left_drawer_top.bmp` | 167×10 | 5.094 | – | obere Blende (opak, reiner Verlauf) | niedrig |
| `left_drawer_bottom.bmp` | 168×10 | 5.094 | – | untere Blende (opak) | niedrig |
| `left_drawer_right.bmp` | 16×160 | 7.734 | – | rechte Blende; Magenta nur in Spalten 10–15 (abgerundete Ecke) | mittel |

### 2.6 Rechtes Ohr / Playlist-Drawer (14)

| Datei | Maße | Bytes | Zustand | Rolle / Besonderheit | Uprez |
|---|---|---|---|---|---|
| `right_ear.bmp` | 87×170 | 44.934 | – | wie `left_ear.bmp`, gespiegelt: 2.291 Magenta-Pixel, links 10 px/Spalte, ab Spalte 16 = 0 px, rechts ab ca. Spalte 66 stark ansteigend bis 155 px in der letzten Spalte | kritisch |
| `R_drwr_open_01_default.bmp` | 18×67 | 3.808 | 01_default | Handle `bPlHandle` geschlossen; 340 Magenta-Pixel | mittel |
| `R_drwr_open_02_rollover.bmp` | 18×67 | 3.808 | 02_rollover | – | mittel |
| `R_drwr_open_03_down.bmp` | 18×67 | 3.808 | 03_down | – | mittel |
| `R_drwr_close_01_default.bmp` | 18×67 | 3.808 | 01_default | Handle offen; 158 px Unterschied zu `open_01`; per Skript (`js Z.99-101`) | mittel |
| `R_drwr_close_02_rollover.bmp` | 18×67 | 3.808 | 02_rollover | – | mittel |
| `R_drwr_close_03_down.bmp` | 18×67 | 3.808 | 03_down | – | mittel |
| `R_drwr_04_disabled.bmp` | 18×67 | 3.808 | 04_disabled | **toter Asset** (nirgends referenziert) | niedrig |
| `right_X_01_default.bmp` | 11×11 | 450 | 01_default | Close-X des PL-Drawers | mittel |
| `right_X_02_rollover.bmp` | 11×11 | 450 | 02_rollover | – | mittel |
| `right_X_04_disabled.bmp` | 11×11 | 450 | 04_disabled | **kein 03_down** | mittel |
| `right_drawer_top.bmp` | 172×10 | 5.214 | – | obere Blende (opak) | niedrig |
| `right_drawer_bottom.bmp` | 172×10 | 5.214 | – | untere Blende (opak) | niedrig |
| `right_drawer_left.bmp` | 13×160 | 6.454 | – | linke Blende; Magenta in Spalten 0–6 | mittel |

### 2.7 Drawer-Innenflächen (4) und Slider-Basen (4)

| Datei | Maße | Bytes | Zustand | Rolle | Uprez |
|---|---|---|---|---|---|
| `drawer_bkgrnd_left.bmp` | 10×140 | 4.534 | – | Innenhintergrund links (beide Drawer) | nein |
| `drawer_bkgrnd_top.bmp` | 157×11 | 5.246 | – | Innenhintergrund oben/Titelzeile | nein |
| `drawer_bkgrnd_right.bmp` | 5×140 | 2.294 | – | Innenhintergrund rechts | nein |
| `drawer_bkgrnd_bottom.bmp` | 157×3 | 1.470 | – | Innenhintergrund unten | nein |
| `horizontal_slider.bmp` | 15×11 | 582 | – | Track für Balance + Volume (`tiled`, Zielbreite 71) | mittel |
| `horizontal_thumb.bmp` | 9×11 | 362 | – | Thumb für Balance + Volume (keine Zustandsbilder) | mittel |
| `vertical_slider.bmp` | 11×15 | 594 | – | Track für alle 10 EQ-Bänder (`tiled`, Zielhöhe 76) | mittel |
| `vertical_thumb.bmp` | 11×11 | 450 | – | Thumb für alle 10 EQ-Bänder (kein Magenta) | mittel |

### 2.8 Zustandsfamilien-Konsistenz, Key-Farben, Uprez-Fazit

**Zustandsfamilien:**

* Vollständig (4 Zustände): `minimize_close_*`, `play_controls_*`, `EQ_*`, `PL_*`, `viz_drop_L_*`, `viz_drop_R_*`, `viz_drop_X_*`.
* 3 Zustände (kein `04_disabled`): `pause_*`, `themebutton_*`, `thumb_*`.
* `left_X_*` / `right_X_*`: 3 Zustände, aber ohne `03_down` (nur default/rollover/disabled).
* Drawer-Handles: `open_*` (3) + `close_*` (3) + je ein **unbenutztes** `04_disabled`.
* Einzel-/Dauerbilder ohne Suffix: `head`, `vid_bkgd`, `viz_drop`, `*_drawer_*`, `drawer_bkgrnd_*`, `horizontal_*`, `vertical_*`, `progressbar*`.

**Key-/Transparenzfarben (vollständige Liste der Dateien mit Magenta-Anteil):** `head.bmp` (zusätzlich Rot), `left_ear.bmp`, `right_ear.bmp`, `left_drawer_right.bmp`, `right_drawer_left.bmp`, `L_drwr_*` (alle 7), `R_drwr_*` (alle 7), `pause_*` (68 px), `thumb_*` (8 px), `viz_drop.bmp` (352 px), `viz_drop_L_*` (7 px). Alle anderen BMPs sind vollständig opak; `head.bmp` ist das einzige Bild mit Rot; `vid_bkgd.bmp` nutzt Weiß als Clip-Farbe.

**Uprez-Fazit für den VLC-Port:**

1. **Kritisch (Fotos/Renderings, nicht vektorisierbar):** `head.bmp` (234×394), `left_ear.bmp` (84×170), `right_ear.bmp` (87×170). Empfehlung: Spezial-Upscaler (z. B. Real-ESRGAN/Multiscale) **auf den keyfreien Motivflächen**; die Magenta-/Rot-Bereiche vorher **ausmaskieren** (Maske aus dem Original ableiten) und erst nach dem Upscale neu zusammensetzen – sonst entstehen an den Key-Kanten Farbsäume, die beim anschließenden Keying ausfransen.
2. **Hoch (kleine, detailreiche Icons/Strips):** `play_controls_*` (5 Buttons in 23 px!), `pause_*`, `EQ_*`, `PL_*`, `themebutton_*`, `thumb_*`, `progressbar*.bmp`, `minimize_close_*`, `viz_drop*`. Empfehlung: 3–4× Upscale + manuelles Nachzeichnen (Vektor) der Symbolkonturen.
3. **Mittel (kleine Flächen/Kacheln):** Drawer-Blenden, `*_X_*`, Drawer-Handles, Slider-Basen. Nachzeichenbar.
4. **Unkritisch, am besten prozedural ersetzen:** `drawer_bkgrnd_*` (reine Verläufe), `left/right_drawer_top/bottom` (flächige grüne Blenden), `vid_bkgd.bmp` (1bpp-Black), `_map.bmp` (werden nie gezeichnet – für den Port nicht nötig, dienen nur als Hit-Test-Referenz).

---

## 3. Layout-Dokumentation (aus `headspace.wms`)

### 3.1 Elementhierarchie mit deklarierten Werten

```
theme id="headspace"                                                   wms Z.5-8
└─ view (760×394, backgroundColor=none, titleBar=false, resizable=false) wms Z.9-16
   ├─ subview [head]   left=261 top=0  bg=head.bmp (234×394 abgeleitet) wms Z.17-22
   │   ├─ buttongroup [minimize_close] 101/4  z=2  map+4 Zustandsbilder wms Z.23-40
   │   ├─ buttongroup [play_controls]   48/31 z=2  map+4 Zustandsbilder wms Z.41-63
   │   ├─ pausebutton                 74/32  z=3  3 Bilder                wms Z.64-71
   │   ├─ button bEq                  15/214 z=2  4 Bilder                wms Z.72-81
   │   ├─ button bPl                 204/214 z=2  4 Bilder                wms Z.82-91
   │   ├─ slider seek                 39/223 z=2  3 Bilder + fg/bg         wms Z.92-107
   │   ├─ button [themebutton]       101/232 z=2  3 Bilder                wms Z.108-115
   │   ├─ subview [screen] 9/59 216×158 z=-2  bg=vid_bkgd.bmp             wms Z.117-121
   │   │   ├─ effects visEffects 0/0 216×158 visible=false               wms Z.122-125
   │   │   └─ video vid  12/11 193×135 visible=false                    wms Z.126-131
   │   └─ subview visDrop 30/33 (174×26) z=-1 visible=false              wms Z.134-176
   │       ├─ button [vizPrev]  9/3  z=1     ├─ button [vizNext] 135/3  z=1
   │       ├─ button [vizClose] 157/8 z=1    └─ text [vizTitle] 30/6 w=105 z=2
   ├─ subview sEqEar 207/86 269×170 z=-1  onEndMove=EqOnEndMove()        wms Z.179-187
   │   ├─ subview [earFace] 0/0 (84×170) bg=left_ear.bmp                 wms Z.188-192
   │   │   ├─ button bEqHandle   8/66  z=1  ├─ button bEqClose  72/7 z=1 visible=false
   │   ├─ subview [eqFrameTop]    84/0  (167×10) bg=left_drawer_top.bmp  wms Z.213-217
   │   ├─ subview [eqFrameBottom] 84/150 (168×10) bg=left_drawer_bottom  wms Z.218-222
   │   ├─ subview [eqFrameRight] 251/0  (16×160) bg=left_drawer_right    wms Z.223-228
   │   └─ subview sEqView 84/10 171×140 z=-1 visible=false bg=#285F03    wms Z.229-233
   │       ├─ [eqBkgndLeft/Top/Bottom/Right] (4 Innenflächen)            wms Z.234-253
   │       ├─ slider balance 8/11 w=71 z=1   ├─ text [balanceLabel] 25/22 z=1
   │       ├─ slider volume  89/11 w=71 z=1  ├─ text [volumeLabel] 108/22 z=1
   │       ├─ equalizerSettings eq enable=true                           wms Z.289-290
   │       ├─ slider eq1…eq10 (x = 11/26/41/56/71/86/101/116/131/146, y=44, h=76)
   │       └─ text [resetLink] 140/127 z=1 (Underline, hand)             wms Z.422-431
   ├─ subview sPlEar 277/86 272×170 z=-1  onEndMove=PlOnEndMove()         wms Z.434-441
   │   ├─ [plFrameLeft] 0/0 (13×160)  ├─ [plFrameTop] 13/0 (172×10)      wms Z.442-450
   │   ├─ [plFrameBottom] 13/150 (172×10)                                wms Z.451-454
   │   ├─ subview [plEar] 185/0 (87×170) bg=right_ear.bmp                wms Z.455-459
   │   │   ├─ button bPlHandle 61/65 z=1  ├─ button bPlClose 4/7 z=1 visible=false
   │   └─ subview [plView] 13/10 172×140 z=-1 bg=#285F03                 wms Z.480-484
   │       ├─ [plBkgndLeft/Top/Bottom/Right]                             wms Z.485-500
   │       └─ playlist pl 0/0 172×140 visible=false                      wms Z.501-511
   └─ text xEqTt / xPlTt / xVisTt  (enabled=false, visible=false)       wms Z.515-529
```

Volle Attributdetails je Element: `research/original/controls.json` (68 Einträge, Schlüssel exakt `id, typ, parent, left, top, width, height, zIndex, assets, aktion, quelle`). Eckige Klammern im Feld `id` = vom Reverse Engineering vergebene synthetische Kennung, weil das Originalelement keine `id` hat. Bei `width`/`height` mit „abgeleitet" ist die Bildgröße des referenzierten Assets eingesetzt.

### 3.2 Koordinaten- und Schichtmodell

**Grundregeln (durch MS-Doku belegt und durch die Rekonstruktion bestätigt):**

1. `left`/`top` sind relativ zum Eltern-Subview; `width`/`height` werden – wenn nicht deklariert – aus dem Hintergrundbild übernommen (`head`-Subview = 234×394, weil `head.bmp` so groß ist; `earFace` = 84×170 usw.).
2. **`zIndex`:** „The background bitmap of a VIEW or SUBVIEW has a fixed z index of zero. If you want a control to be behind the background, the zIndex must be set to a negative number." (MS Learn, `AmbientAttributes.zIndex`). Daraus folgt das Kernprinzip dieses Skins: **Screen (-2) und visDrop (-1) liegen hinter `head.bmp` und werden nur durch dessen Magenta-Öffnung sichtbar.** Die beiden Ohren (`sEqEar`/`sPlEar`, z=-1) liegen hinter dem Kopf-Subview (z=0).
3. `zIndex` eines VIEW/SUBVIEW ist **absolut**, der eines Controls **relativ** zu seinem Container. `BUTTONELEMENT` erbt den zIndex seiner `BUTTONGROUP`.
4. **`clippingColor="#FF0000"`** auf dem Kopf-Subview (wms Z.20): „The clipping color indicates the regions of the clippingImage (or backgroundImage for VIEW or SUBVIEW) that correspond to transparent, non-clickable portions of the control." (MS Learn, `AmbientAttributes.clippingColor`) – die roten 17.909 px um die Kopfsilhouette werden also weggeschnitten und sind **nicht klickbar**.
5. **`transparencyColor="#FF00FF"`** (Magenta) macht die jeweiligen Bildflächen transparent (MS Learn `VIEW.transparencyColor`: „transparency color of the background image"). Das Präzise Hit-Test-Verhalten von Transparency-Flächen ist in der verfügbaren Doku nicht ausformuliert (→ §7).
6. `clippingColor="#FFFFFF"` am Screen-Subview (wms Z.120) schneidet die weißen Ecken von `vid_bkgd.bmp` (1bpp) weg; `clippingColor="#FF00FF"` an visDrop (wms Z.137) schneidet dessen Magenta-Rundungen weg.

**Absolute Schlüsselkoordinaten der Hauptelemente (View-Koordinaten):**

| Element | x-Bereich | y-Bereich | Anmerkung |
|---|---|---|---|
| Kopf `head.bmp` | 261–494 | 0–393 | volle View-Höhe |
| Screen-Subview (216×158) | 270–485 | 59–216 | z=-2 hinter dem Kopf |
| **Gesichts-Öffnung** (Magenta in `head.bmp`) | 271–484 (max. Breite 214 in y≈150) | 59–215 (Höhe 157) | ellipsen-/blobförmig: y=59 nur x 347–405, y=70 x 282–474, y=150 x 271–484, y=215 x 359–396 (jeweils +261 gerechnet) |
| Video `vid` (193×135) | 282–474 | 70–204 | Oberkante = exakte Breite der Öffnung in y=70 → bewusst so gesetzt |
| visDrop (174×26) | 291–464 | 33 (zu) / 59–84 (offen) | bei y=33 komplett hinter der Stirn |
| Linkes Ohr `sEqEar` (269×170) | 207–475 (zu) / **0–268 (offen)** | 86–255 | zu: 54 px ragen links am Kopf vorbei (207–260) |
| EQ-Drawer-Inhalt `sEqView` (171×140) | 291–461 (zu) / 84–254 (offen) | 96–235 | zu: hinter dem Kopf, offen: links neben dem Kopf |
| Rechtes Ohr `sPlEar` (272×170) | 277–548 (zu) / **488–759 (offen)** | 86–255 | zu: 54 px ragen rechts vorbei (495–548) |
| PL-Drawer-Inhalt `plView` (172×140) | 290–461 (zu) / 501–672 (offen) | 96–235 | |
| Rechter Lautsprecher `right_ear` (87×170) | 462–548 (zu) / 673–759 (offen) | 86–255 | |
| Transport-Strip (144×25) | 309–452 | 31–55 | |
| Minimieren/Close (29×16) | 362–390 | 4–19 | |
| Pause (23×23) | 335–357 | 32–54 | exakt über dem Play-Kreis |
| `bEq` (20×19) | 276–295 | 214–232 | |
| `bPl` (19×20) | 465–483 | 214–233 | |
| Seek-Slider (163×9) | 300–462 | 223–231 | Thumb-Fahrweg durch `borderSize=9` innen |
| Theme-Button (35×31) | 362–396 | 232–262 | |

**Symmetrie-Beleg:** Im geschlossenen Zustand ragt jedes Ohr **54 px** über den Kopf hinaus (links 261−207 = 54, rechts 549−495 = 54). Ein linker Ohrklotz-Streifen (207–260) und ein rechter (495–548) ergeben zusammen mit dem Kopf exakt die 342-px-Breite der offiziellen Vorschau (siehe 3.4).

### 3.3 Geometrie-Rechnung: Slide-Werte, Fensterbreite, Animation

| Größe | Wert | Beleg |
|---|---|---|
| View deklariert | 760×394 | wms Z.11 |
| `widthClosed` | 549 | js Z.16 |
| `widthOpened` | 760 | js Z.17 |
| `eqClosedPos` / `eqOpenedPos` | 207 / 0 | js Z.5-6 |
| `plClosedPos` / `plOpenedPos` | 277 / 488 | js Z.8-9 |
| `visClosedPos` / `visOpenedPos` | 33 / 59 | js Z.11-12 |
| `speed` | 120 | js Z.19 |

**Nachgerechnete Zusammenhänge:**

* **549 = rechte Kante des geschlossenen PL-Ohrs**: 277 + 272 = 549. **760 = rechte Kante des offenen PL-Ohrs**: 488 + 272 = 760. Die Fensterbreiten sind also exakt die Ohr-Kanten → im offenen Zustand ist kein Pixel des Drawers abgeschnitten, im geschlossenen kein Leerraum rechts.
* **211 = Wanderweg des PL-Ohrs** (488 − 277) = **Breitendifferenz** (760 − 549). Öffnen und Verbreitern laufen gleichzeitig ab (`js Z.96` setzt die Breite sofort, `moveto` animiert das Ohr über 120 ms).
* **207 = Wanderweg des EQ-Ohrs** (207 − 0). Der Kopf bleibt stehen; das Ohr fährt nach links aus dem Bildbereich heraus und bleibt **komplett sichtbar** (0–268). Da der linke Rand der View 0 ist, wird nichts geclippt – der Drawer fährt „ins Freie" links neben den Kopf.
* **26 = visDrop-Weg** (59 − 33): Da die Gesichtsöffnung erst bei y=59 beginnt, ist die Pille bei y=33 vollständig von der Stirn verdeckt und erscheint beim Herunterfahren aus dem Nichts im oberen Screen-Bereich.
* **Sichtbarer Inhalt im geschlossenen Zustand:** 207–548 (342 px) × 0–393 (394 px) → **exakt die Maße der offiziellen Vorschau `Headspace_preview.png` (342×394)**. Das ist ein unabhängiger Beleg für das Schichtmodell: In WMP sind die Flächen x<207 und x>548 transparent (backgroundColor=none), die Vorschau wurde darauf zugeschnitten.
* **Startbesonderheit:** `Init()` setzt `view.width` **nicht**; die View startet mit den im XML deklarierten 760 px und wird erst beim ersten PL-Schließen (`PlOnEndMove`, js Z.130) auf 549 gesetzt. Die überstehenden 211 px sind unsichtbar (nichts wird dort gezeichnet), vergrößern aber die Fensterfläche (→ §7).

### 3.4 Zustände A–D: Was sieht man wann – und was liegt dahinter?

Grundlage: Schichtreihenfolge von hinten nach vorn = `sEqEar` (z=-1) → `sPlEar` (z=-1) → innerhalb des Kopf-Subviews: Screen-Inhalt (z=-2: `vid_bkgd` → `visEffects` → `vid`) → `visDrop` (z=-1) → **`head.bmp`** → Kopf-Controls (positive z). Daraus folgt: **Alles, was in den Ohren liegt und vom Kopf überdeckt wird, ist unsichtbar; die Gesichtsöffnung gibt ausschließlich den Screen frei (nicht die Ohren), weil der Screen im Kopf-Subview höher liegt als die Ohren.** Die Rekonstruktion (unten) bestätigt das Bild für Bild.

**Zustand A – Start/geschlossen (Beleg: `previews/states/state-A-closed.png` ≈ offizielle Vorschau):**

* Sichtbar: der grüne Kopf mit beiden Lautsprecher-Ohren (je 54 px vorstehend), die Gesichtsöffnung mit schwarzem Screen-Hintergrund (`vid_bkgd`), Visualisierung (wenn kein Video), Transport-Strip, Min/Close, Pause (nur bei Wiedergabe), `bEq`/`bPl`, Seek-Bar, Theme-Button.
* Verdeckt: `visDrop` liegt bei y=33 hinter der Stirn (Stirn ist opak bis y=58). Beide Drawer-Inhalte (`sEqView` inkl. Balance/Volume/EQ, `pl`) sind mit `visible=false` zusätzlich ausgeblendet; die **Blendenrahmen** der Ohren (`left_drawer_top/bottom/right`, `right_drawer_top/bottom`, `right_drawer_left`) sind vorhanden, liegen aber (a) hinter dem Screen-Subview bzw. (b) hinter `head.bmp` und damit komplett verdeckt. Das Beispiel `left_drawer_top.bmp` (im geschlossenen Zustand bei 291–457/y 86–95) wäre in der Gesichtsöffnung sichtbar, **wenn** der Screen nicht darüber läge – genau dafür ist die Reihenfolge Ohr(z=-1) < Screen(z=-2 im Kopf) konstruiert.
* Fenster: nominal 549 breit (nach dem ersten PL-Zyklus), sichtbarer Inhalt 342 px.

**Zustand B – EQ-Drawer offen (`state-B-eq-open.png`):**

* `ToggleEqView()` (js Z.71-79, offener Zweig): `sEqView.visible = bEqClose.visible = true` **sofort**, dann `sEqEar.moveto(0, 86, 120)` – der komplette Drawer (Lautsprecher + Blenden + Panel) fährt in 120 ms nach links. Während der Fahrt ist der Inhalt schon sichtbar (kein Nachpellen).
* Sichtbar danach: Lautsprecher-Turm links außen (0–83), Blendenrahmen (obere Blende 84–250, untere Blende 84–251, rechte Blende 251–266), Innenfläche `sEqView` (84–254) mit Balance (x 92–162, y 107–117), Volume (x 173–243), 10 EQ-Bändern (x 95–241, y 140–215) und „reset" (224/223).
* `bEqClose` (X) erscheint bei 72/7 im Ohr; das Handle wechselt auf die Close-Grafik (js Z.75-77); Tooltip von `bEq` und `bEqHandle` wird „Close graphic equalizer controls".
* Der rechte Kopfbereich bleibt unverändert; das Ohr verschiebt sich nicht mehr hinter den Kopf, sondern liegt vollständig frei. Beim Schließen wird **erst nach** dem Zurückfahren (`EqOnEndMove`, js Z.134-138) der Inhalt ausgeblendet → kein Flackern, aber während der Rückfahrt ist der Drawer-Inhalt noch sichtbar, bis er hinter dem Kopf verschwindet.
* Fensterbreite: unverändert (549 bzw. 760) – der Drawer passt immer in x≥0.

**Zustand C – Playlist offen (`state-C-pl-open.png`):**

* `TogglePlView()` (js Z.94-104, offener Zweig): `view.width = 760` **sofort** (Platz schaffen), `bPlClose.visible = true` sofort, dann `sPlEar.moveto(488, 86, 120)`. Die Playlist selbst (`pl`) wird erst am Ende der Bewegung durch `PlOnEndMove()` (js Z.126-127) eingeblendet.
* Sichtbar: Kopf unverändert in der Mitte; rechts der komplette PL-Drawer 488–759 (Blenden: linke Blende 488–500, obere/untere Blende 501–672, Lautsprecher-Turm 673–759, Playlist-Fläche 501–672 mit dunkelgrünem Hintergrund `#285F03`), links das geschlossene EQ-Ohr.
* Das PL-Ohr wandert **nach rechts aus dem Kopf heraus** und vergrößert zugleich das Fenster – dadurch „wächst" der Skin an der rechten Seite.
* Beim Schließen: `pl.visible=false` und `moveto(277)` sofort, `bPlClose` aus; erst am Ende der Bewegung schrumpft das Fenster auf 549 (js Z.130). Während der Rückfahrt bleiben die 760 px Breite erhalten – sonst würde der noch ausgefahrene Drawer abgeschnitten.

**Zustand D – Visualisierungs-Auswahl offen (`state-D-vis-open.png`):**

* `ToggleVisView()` (js Z.115-121, nur wenn `!vidIsPlaying`): `visDrop.visible=true`, dann `moveto(30, 59, 120)`. Die Pille fährt aus der Stirn in den oberen Teil der Gesichtsöffnung und liegt exakt in der Öffnung (y 59–84, x 291–464).
* Sichtbar: Pille mit Previous (300/62), Titeltext (`visEffects.currentPresetTitle`, zentriert, x 321–425), Next (426/62), Close (448/67) – alle auf grünem Träger.
* Beim Schließen fährt sie auf y=33 zurück; `visible=false` wird erst am Ende durch `VisDropOnEndMove()` gesetzt (js Z.142). Läuft währenddessen ein Video an, ruft `VisDropOnEndMove()` erneut `StartVideo()` (js Z.143-146).
* Video-Sperre: Bei laufendem Video öffnet sich die Pille nicht (`else if(!vidIsPlaying)`, js Z.115).

**Sichtbarkeits-Matrix:**

| Element | A: zu (kein Video) | A': z u (Video) | B: EQ offen | C: PL offen | D: visDrop offen |
|---|---|---|---|---|---|
| `head.bmp` | sichtbar | sichtbar | sichtbar | sichtbar | sichtbar |
| Screen/`vid_bkgd` | durch Öffnung sichtbar | dito | dito | dito | dito |
| `visEffects` | **sichtbar** (`EndVideo`) | verdeckt von `vid` | unverändert | unverändert | bleibt sichtbar |
| `vid` | unsichtbar | **sichtbar** | unverändert | unverändert | – (nicht öffenbar) |
| `visDrop` | unsichtbar (y=33, hinter Stirn) | unsichtbar/unzugänglich | unverändert | unverändert | **sichtbar (y=59)** |
| `sEqEar` | sichtbar (54 px) | dito | **komplett ausgefahren** | unverändert zu | unverändert zu |
| `sEqView`+Inhalt | unsichtbar | unsichtbar | **sichtbar** | unsichtbar | unsichtbar |
| `bEqClose` | unsichtbar | unsichtbar | **sichtbar** | unsichtbar | unsichtbar |
| `sPlEar` | sichtbar (54 px) | dito | unverändert zu | **komplett ausgefahren** | unverändert zu |
| `pl` / `bPlClose` | unsichtbar | unsichtbar | unsichtbar | **sichtbar** | unsichtbar |
| Fensterbreite | 549* | 549* | 549* | **760** | 549* |
| Pause-Button | weg | sichtbar | (statusabhängig) | (statusabhängig) | (statusabhängig) |

\* Sonderfall Start: bis zum ersten Schließen des PL-Drawers bleibt die im XML deklarierte Breite 760 aktiv (js Z.21-31 setzt sie nicht).

### 3.5 Verifikation des Layouts

1. **Composite-Rekonstruktion:** Ein eigenes PowerShell/System.Drawing-Skript hat die Zustände A–D aus den Original-Assets mit exakt der oben hergeleiteten Schicht-/Key-Logik gerendert (`previews/states/*.png`). Die Ergebnisse zeigen eine funktionierende, konsistente Player-Skin ohne Artefakte.
2. **Abgleich mit der offiziellen Vorschau:** `state-A-closed.png` (549×394, Inhalt 207–548) stimmt in Aufbau, Überlappungen und Proportionen mit `Headspace_preview.png` (342×394) überein; die Vorschau ist genau der Inhaltausschnitt x 207–548 bei y 0–393.
3. **Geometrie-Plausibilität:** Video-Oberkante (y=70) deckt sich mit der Öffnungsbreite (x 282–474) in y=70; der Pause-Button (335–357) liegt exakt über dem Play-Kreis (335–357); Fensterbreiten entsprechen den Ohr-Kanten (549/760) – drei unabhängige Konsistenzbeweise.

---

## 4. Kontrollen-Funktionsdoku (Tabelle je Control)

Positionen: `left/top` sind die deklarierten Werte relativ zum Parent; `Absolut` = View-Koordinaten (nur bei Bedarf). „Status-Ausdrücke" listet alle `wmpprop:`/`wmpenabled:`-Bindungen. Maschinenlesbare Fassung aller Angaben inkl. Assets/Quellen: `controls.json`.

### 4.1 view (`theme id="headspace"`)

| Feld | Wert |
|---|---|
| Typ | VIEW (Fenster/Theme) |
| id | keine (im Skript global als `view` adressierbar) |
| Position | 0/0, 760×394 |
| Assets | – (backgroundColor=none → komplett transparente Fläche) |
| Status-Ausdrücke | – |
| Events | `onLoad="Init();"` (wms Z.14 → js Z.21-31), `onClose="OnClose();"` (wms Z.15 → js Z.33-37); `titleBar=false`, `resizable=false` |
| Tooltip | – |
| Quelle | wms Z.5-16 |

### 4.2 Minimize (buttonelement in `[minimize_close|group]`)

| Feld | Wert |
|---|---|
| Typ | buttonelement (in buttongroup mit `mappingImage`) |
| id | keine |
| Position | Gruppe 101/4 (29×16, Absolut 362/4); Klickregion 0/0, 14×16 (Map x0–13) |
| Assets | `minimize_close_map.bmp` (Region `#FF00CC`), Gruppe zeichnet `minimize_close_01_default/02_rollover/03_down/04_disabled.bmp` |
| Status-Ausdrücke | – (immer aktiv; `04_disabled` bleibt ungenutzt) |
| Events | `onClick="view.minimize();"` |
| Tooltip | **Minimize** |
| Quelle | wms Z.23-34 |

### 4.3 Close (buttonelement in `[minimize_close|group]`)

| Feld | Wert |
|---|---|
| Typ | buttonelement |
| id | keine |
| Position | Region 15/0, 14×16 (Map `#CC0066`, x15–28) |
| Assets | s. o. |
| Status-Ausdrücke | – |
| Events | `onClick="view.close();"` → löst `view.onClose` → `OnClose()` aus (Visualisierungs-Preset wird zurückgeschrieben) |
| Tooltip | **Close** |
| Quelle | wms Z.35-39 |

### 4.4 prev / 4.5 play / 4.6 stop / 4.7 next (Elemente der `[play_controls|group]`)

| Feld | prev | play | stop | next |
|---|---|---|---|---|
| Typ | `prevelement` | `playelement` | `stopelement` | `nextelement` |
| id | keine | keine | keine | keine |
| Position (Region) | 1/1, 23×23 | 26/1, 23×23 | 52/1, 23×23 | 77/1, 23×23 |
| Mapping-Farbe | `#FF0033` | `#FFFF00` | `#00FF00` | `#00FFFF` |
| Assets der Gruppe | `play_controls_map.bmp` + `play_controls_01_default/02_rollover/03_down/04_disabled.bmp` (144×25, ganzer Strip wechselt) | | | |
| Status-Ausdrücke | – | `tabStop="wmpenabled:player.controls.play"` (nur Tab-Reihenfolge, keine Sichtbarkeit) | – | – |
| Events | Standardverhalten von WMP (kein onClick im Skin); Klick/Disabled-Logik steuert der Player | | | |
| Tooltip | kein `upToolTip` definiert (WMP-Standard-Tooltips bleiben) | | | |
| Quelle | wms Z.48-49 | Z.50-53 | Z.54-55 | Z.56-57 |

### 4.8 vis (buttonelement, Sonne/Rad)

| Feld | Wert |
|---|---|
| Typ | buttonelement |
| id | `vis` |
| Position | 119/1, 23×23 (Absolut 428–450/32–54) |
| Assets | Gruppe s. 4.4; Mapping-Farbe `#0000FF` |
| Status-Ausdrücke | – |
| Events | `onClick="ToggleVisView();"` (js Z.107-122) |
| Tooltip | `upToolTip="Open visualization chooser"` initial; zur Laufzeit aus `xVisTt` überschrieben – **Bug:** es wird immer `xVisTt.value` = „Close visualization chooser" gesetzt (js Z.112 und Z.119), auch im geschlossenen Zustand |
| Quelle | wms Z.58-62 |

### 4.9 pausebutton

| Feld | Wert |
|---|---|
| Typ | `pausebutton` (eigenständiges WMP-Element) |
| id | keine |
| Position | 74/32, 23×23, **z=3** (über dem Play-Button mit z=2) |
| Assets | `pause_01_default.bmp`, `pause_02_rollover.bmp`, `pause_03_down.bmp` (kein Disabled-Bild) |
| Status-Ausdrücke | `visible="wmpenabled:player.controls.pause"` → erscheint nur, wenn Pausieren möglich ist (d. h. während der Wiedergabe) |
| Events | Standardverhalten Pause/Resume |
| Tooltip | WMP-Standard |
| Quelle | wms Z.64-71 |

### 4.10 seek (Slider)

| Feld | Wert |
|---|---|
| Typ | SLIDER |
| id | `seek` |
| Position | 39/223 (Absolut 300/223), Breite 163 (aus `progressbar.bmp`), Höhe 9 |
| Assets | `progressbar.bmp` (Track), `progressbar_foreground.bmp` (Download-Progress), `thumb_01_default.bmp`, `thumb_02_rollover.bmp`, `thumb_03_down.bmp` |
| Status-Ausdrücke | `max="wmpprop:player.currentmedia.duration"`, `value="wmpprop:player.controls.currentposition"`, `foregroundProgress="wmpprop:player.network.downloadProgress"` |
| Events | `onDragEnd="player.controls.currentposition=value;"` – Position wird **erst beim Loslassen** gesetzt (kein Live-Scrubbing); kein onDragBegin/onPositionChange |
| Tooltip | **Seek** (Attribut `toolTip`) |
| Weitere Attribute | `slide="false"` → Foreground wird an Ort und Stelle aufgedeckt (kein „Schieben"), `useForegroundProgress="true"`, `borderSize="9"` (Thumb-Fahrweg beidseitig um 9 px beschnitten), `transparencyColor="#FF00FF"` (Thumb-Ecken) |
| Quelle | wms Z.92-107 |

### 4.11 bEq (EQ-Toggle auf dem Kinn)

| Feld | Wert |
|---|---|
| Typ | BUTTON |
| id | `bEq` |
| Position | 15/214, 20×19, z=2 (Absolut 276/214) |
| Assets | `EQ_01_DF.bmp`, `EQ_02_RV.bmp`, `EQ_03_Dwn.bmp`, `EQ_04_Dis.bmp` |
| Status-Ausdrücke | – |
| Events | `onClick="ToggleEqView();"`; zur Laufzeit ändert das Skript `upToolTip` |
| Tooltip | **Open graphic equalizer controls** (offen: „Close graphic equalizer controls") |
| Quelle | wms Z.72-81 |

### 4.12 bPl (Playlist-Toggle auf dem Kinn)

| Feld | Wert |
|---|---|
| Typ | BUTTON |
| id | `bPl` |
| Position | 204/214, 19×20, z=2 (Absolut 465/214) |
| Assets | `PL_01_DF.bmp`, `PL_02_RV.bmp`, `PL_03_Dwn.bmp`, `PL_04_Dis.bmp` |
| Status-Ausdrücke | – |
| Events | `onClick="TogglePlView();"`; Tooltip-Wechsel per Skript |
| Tooltip | **Open playlist** (offen: „Close playlist") |
| Quelle | wms Z.82-91 |

### 4.13 themebutton („Return to Full Mode")

| Feld | Wert |
|---|---|
| Typ | BUTTON |
| id | keine |
| Position | 101/232, 35×31, z=2 (Absolut 362/232) |
| Assets | `themebutton_01_default.bmp`, `themebutton_02_rollover.bmp`, `themebutton_03_down.bmp` |
| Status-Ausdrücke | – |
| Events | `onClick="view.returnToMediaCenter();"` – dokumentierte VIEW-Methode: „Returns the user to the full mode of Windows Media Player" (MS Learn, `view.returnToMediaCenter`) |
| Tooltip | **Return to Full Mode** |
| Quelle | wms Z.108-115 |

### 4.14 Screen-Subview `[screen]`

| Feld | Wert |
|---|---|
| Typ | SUBVIEW |
| id | keine |
| Position | 9/59, 216×158, **z=-2** (Absolut 270/59) |
| Assets | `vid_bkgd.bmp` (1bpp: schwarz = Fläche, weiß = Clipping) |
| Status-Ausdrücke | – |
| Events | – |
| Tooltip | – |
| Besonderheit | `clippingColor="#FFFFFF"`; liegt hinter `head.bmp` (z=0) und wird nur durch dessen Magenta-Öffnung sichtbar (vgl. §3.2/3.4) |
| Quelle | wms Z.117-121 |

### 4.15 visEffects (Visualisierung)

| Feld | Wert |
|---|---|
| Typ | EFFECTS |
| id | `visEffects` |
| Position | 0/0 im Screen, 216×158 |
| Assets | – (WMP rendert die Visualisierung) |
| Status-Ausdrücke | `visEffects.currentPresetTitle` wird im visDrop-Text angezeigt (wms Z.173) |
| Events | – (kein eigenes Event; gesteuert über `previous()`/`next()`-Aufrufe der visDrop-Buttons und `mediacenter`-Sync) |
| Tooltip | – |
| Zuordnung | `visible="false"` im XML (wms Z.122), wird von `EndVideo()` auf true gesetzt (js Z.56); Presets aus `mediacenter.effectType`/`effectPreset` (js Z.25-26), Rückschreiben in `OnClose()` (js Z.35-36) |
| Quelle | wms Z.122-125 |

### 4.16 vid (Video)

| Feld | Wert |
|---|---|
| Typ | VIDEO |
| id | `vid` |
| Position | 12/11 im Screen, 193×135 (Absolut 282/70) |
| Assets | – |
| Status-Ausdrücke | – (Erkennung im Skript über `player.OpenState`/`player.currentMedia.ImageSourceWidth`) |
| Events | `OnVideoStart="StartVideo();"`, `OnVideoEnd="EndVideo();"` |
| Tooltip | – |
| Zuordnung | `visible="false"` im XML (wms Z.126) |
| Quelle | wms Z.126-131 |

### 4.17 visDrop (Auswahl-Pille)

| Feld | Wert |
|---|---|
| Typ | SUBVIEW |
| id | `visDrop` |
| Position | 30/33, 174×26, **z=-1**, `visible="false"` (Absolut zu 291/33, offen 291/59) |
| Assets | `viz_drop.bmp` (Pille, Magenta-Rundungen via `clippingColor="#FF00FF"`) |
| Status-Ausdrücke | – |
| Events | `onEndMove="VisDropOnEndMove();"` (js Z.140-147) – **Animations-Callback**, kein Nutzer-Drag |
| Tooltip | –; `titleBar=false`, `resizable=false` |
| Quelle | wms Z.134-142 |

### 4.18 vizPrev / 4.19 vizNext / 4.20 vizClose / 4.21 vizTitle

| Feld | vizPrev | vizNext | vizClose | vizTitle |
|---|---|---|---|---|
| Typ | BUTTON | BUTTON | BUTTON | TEXT |
| id | keine | keine | keine | keine |
| Position | 9/3, 22×21, z=1 | 135/3, 22×21, z=1 | 157/8, 13×13, z=1 | 30/6, Breite 105, z=2 |
| Assets | `viz_drop_L_01_default/02_rollover/03_down/04_disabled.bmp`; `transparencyColor="#FF00FF"` | `viz_drop_R_01_default/…/04_disabled.bmp` | `viz_drop_X_01_default/…/04_disabled.bmp` | – |
| Status-Ausdrücke | – | – | – | `value="wmpprop:visEffects.currentPresetTitle"`, `justification="Center"` |
| Events | `onClick="visEffects.previous();"` | `onClick="visEffects.next();"` | `onClick="ToggleVisView();"` | – |
| Tooltip | **Previous visualization** | **Next visualization** | **Close visualization chooser** | – |
| Quelle | wms Z.143-152 | Z.153-161 | Z.162-170 | Z.171-175 |

### 4.22 sEqEar (linkes Ohr, bewegliches Panel)

| Feld | Wert |
|---|---|
| Typ | SUBVIEW |
| id | `sEqEar` |
| Position | 207/86, 269×170, z=-1 (`visible` nie gesetzt = immer vorhanden) |
| Assets | Enthält `left_ear.bmp`, Blenden, `sEqView` |
| Status-Ausdrücke | – |
| Events | `onEndMove="EqOnEndMove();"` (js Z.134-138) |
| Tooltip | –; `transparencyColor="#FF00FF"`, `backgroundColor=none`, `titleBar=false`, `resizable=false` |
| Bewegung | `moveto(207 ↔ 0, 86, 120)` aus `ToggleEqView()` |
| Quelle | wms Z.179-187 |

### 4.23 bEqHandle (Zieh-/Klickgriff am Ohr)

| Feld | Wert |
|---|---|
| Typ | BUTTON |
| id | `bEqHandle` |
| Position | 8/66 im `[earFace]`, 18×66, z=1 (Absolut geschlossen 215/152; im offenen Drawer 8/152) |
| Assets | `L_drwr_open_01_default/02_rollover/03_down.bmp` (deklariert), zusätzlich per Skript `L_drwr_close_01_default/02_rollover/03_down.bmp`; `transparencyColor="#FF00FF"`; `L_drwr_04_disabled.bmp` bleibt unbenutzt |
| Status-Ausdrücke | – |
| Events | `onClick="ToggleEqView();"` |
| Tooltip | **Open graphic equalizer controls** (offen: „Close…", js Z.69/78) |
| Quelle | wms Z.193-202 |

### 4.24 bEqClose (X im offenen EQ-Drawer)

| Feld | Wert |
|---|---|
| Typ | BUTTON |
| id | `bEqClose` |
| Position | 72/7 im `[earFace]`, 11×11, z=1, `visible="false"` (Absolut im **offenen** Drawer 72/93 – nur dort sichtbar; geschlossen wäre es 279/93) |
| Assets | `left_X_01_default.bmp`, `left_X_02_rollover.bmp`, `left_X_04_disabled.bmp` (kein Down-Bild) |
| Status-Ausdrücke | – |
| Events | `onClick="ToggleEqView();"`; Sichtbarkeit über `EqOnEndMove()` (js Z.136-137) |
| Tooltip | **Close graphic equalizer controls** |
| Quelle | wms Z.203-211 |

### 4.25 sEqView (Inhalt des EQ-Drawers)

| Feld | Wert |
|---|---|
| Typ | SUBVIEW |
| id | `sEqView` |
| Position | 84/10, 171×140, z=-1, `visible="false"` |
| Assets | `drawer_bkgrnd_left/top/bottom/right.bmp`, `horizontal_slider/thumb`, `vertical_slider/thumb` (Kinder) |
| Status-Ausdrücke | – |
| Events | Sichtbarkeit über `EqOnEndMove()` |
| Tooltip | –; `backgroundColor="#285F03"`, `titleBar=false`, `resizable=false` |
| Quelle | wms Z.229-233 |

### 4.26 balance (Slider)

| Feld | Wert |
|---|---|
| Typ | SLIDER (horizontal) |
| id | `balance` |
| Position | 8/11, Breite 71 (aus `horizontal_slider.bmp` tiled), Höhe 11 |
| Assets | `horizontal_slider.bmp`, `horizontal_thumb.bmp` |
| Status-Ausdrücke | `value="wmpprop:player.settings.balance"` |
| Events | `value_onchange="player.settings.balance=value;"` (live beim Ziehen) |
| Tooltip | **Balance**; `min="-100"`, `max="100"`, `borderSize="7"`, `tiled="true"`, `direction="horizontal"` |
| Quelle | wms Z.254-264 |

### 4.27 volume (Slider)

| Feld | Wert |
|---|---|
| Typ | SLIDER (horizontal) |
| id | `volume` |
| Position | `jscript:balance.left+balance.width+10` = 89 / `jscript:balance.top` = 11, Breite 71 |
| Assets | `horizontal_slider.bmp`, `horizontal_thumb.bmp` |
| Status-Ausdrücke | `value="wmpprop:player.settings.volume"` |
| Events | `value_onchange="player.settings.volume=value; player.settings.mute='false';"` → Lautstärkeänderung hebt **immer** die Stummschaltung auf |
| Tooltip | **Volume**; `min="0"`, `max="100"`, `borderSize="7"`, `tiled="true"` |
| Quelle | wms Z.271-281 |

### 4.28 eq (equalizerSettings) + eq1…eq10

| Feld | Wert |
|---|---|
| Typ | `equalizerSettings` (Steuerobjekt) + 10× SLIDER (vertikal) |
| id | `eq`, `eq1` … `eq10` |
| Position | `eq` ohne Koordinaten (`enable="true"`); `eq1` 11/44, dann je +15 px: 11/26/41/56/71/86/101/116/131/146, jeweils 11×76, `left = balance.left+3 + 15*(n−1)`, `top = balance.top+33` |
| Assets | `vertical_slider.bmp` (tiled auf Höhe 76), `vertical_thumb.bmp` |
| Status-Ausdrücke | `value="wmpprop:eq.gainLevel1"` … `gainLevel10` |
| Events | `value_onchange="eq.gainLevelN=value;"` pro Band |
| Tooltip | **Graphic equalizer control** (alle 10 identisch); `min="-14"`, `max="14"`, `borderSize="7"`, `tiled="true"`, `direction="vertical"` |
| Quelle | wms Z.289-421 (eq 289-290; eq1 292-304; … eq10 409-421) |

### 4.29 resetLink (Textlink „reset")

| Feld | Wert |
|---|---|
| Typ | TEXT |
| id | keine |
| Position | `jscript:eq10.left-6` = 140 / `jscript:eq1.top+83` = 127, z=1 |
| Assets | – |
| Status-Ausdrücke | – |
| Events | `onClick="eq.reset();"` → alle 10 Bänder auf 0 |
| Tooltip | **Reset graphic equalizer controls**; `cursor="hand"`, `fontStyle="Underline"`, Farbe `#DDDDDD`, Größe 7 |
| Quelle | wms Z.422-431 |

### 4.30 sPlEar (rechtes Ohr, bewegliches Panel)

| Feld | Wert |
|---|---|
| Typ | SUBVIEW |
| id | `sPlEar` |
| Position | 277/86, 272×170, z=-1 |
| Assets | `right_drawer_left/top/bottom.bmp`, `right_ear.bmp`, `plView` |
| Status-Ausdrücke | – |
| Events | `onEndMove="PlOnEndMove();"` (js Z.124-132) |
| Tooltip | –; `transparencyColor` nur auf den Bildern, `titleBar=false`, `resizable=false` |
| Bewegung | `moveto(277 ↔ 488, 86, 120)` aus `TogglePlView()`; zusätzlich `view.width` 760/549 |
| Quelle | wms Z.434-441 |

### 4.31 bPlHandle / 4.32 bPlClose

| Feld | bPlHandle | bPlClose |
|---|---|---|
| Typ | BUTTON | BUTTON |
| id | `bPlHandle` | `bPlClose` |
| Position | 61/65 im `[plEar]` (Absolut im **offenen** Drawer 734/151; geschlossen 523/151), 18×67, z=1 | 4/7 im `[plEar]` (Absolut im **offenen** Drawer 677/93; geschlossen 466/93), 11×11, z=1, `visible="false"` |
| Assets | `R_drwr_open_01_default/02_rollover/03_down.bmp` + per Skript `R_drwr_close_01_default/02_rollover/03_down.bmp`; `R_drwr_04_disabled.bmp` unbenutzt | `right_X_01_default.bmp`, `right_X_02_rollover.bmp`, `right_X_04_disabled.bmp` |
| Status-Ausdrücke | – | – |
| Events | `onClick="TogglePlView();"` | `onClick="TogglePlView();"`; Sichtbarkeit: sofort true beim Öffnen (js Z.97) und über `PlOnEndMove()` (js Z.126-127) |
| Tooltip | **Open playlist** (offen: „Close playlist") | **Close playlist** |
| Quelle | wms Z.460-469 | wms Z.470-478 |

### 4.33 pl (Playlist)

| Feld | Wert |
|---|---|
| Typ | PLAYLIST |
| id | `pl` |
| Position | 0/0 im `[plView]`, 172×140, z=0, `visible="false"` |
| Assets | – (WMP rendert) |
| Status-Ausdrücke | – |
| Events | Sichtbarkeit über `PlOnEndMove()`; Spaltenmodi aus `Init()` (`js Z.23-24`) |
| Tooltip | –; `backgroundcolor="#285F03"`, `foregroundcolor="white"`, `columnsVisible="false"`, `columns="name=Name;Duration=Time"`, `dropDownVisible="true"`, `playlistItemsVisible="true"` |
| Quelle | wms Z.501-511 |

### 4.34 xEqTt / xPlTt / xVisTt (Tooltip-Speicher)

| Feld | xEqTt | xPlTt | xVisTt |
|---|---|---|---|
| Typ | TEXT | TEXT | TEXT |
| id | `xEqTt` | `xPlTt` | `xVisTt` |
| Position | keine (unsichtbar) | keine | keine |
| Assets | – | – | – |
| Status-Ausdrücke | – (`enabled="false"`, `visible="false"`) | dito | dito |
| Events | – | – | – |
| Tooltip-/Wertpaar | `toolTip="Open graphic equalizer controls"` / `value="Close graphic equalizer controls"` | `toolTip="Open playlist"` / `value="Close playlist"` | `toolTip="Open visualization chooser"` / `value="Close visualization chooser"` |
| Nutzung | `js Z.69` (zu → `.toolTip`), `Z.78` (offen → `.value`) | `js Z.92`, `Z.102` | `js Z.112`, `Z.119` – **beide Zweige `.value`** (Bug) |
| Quelle | wms Z.515-519 | Z.520-524 | Z.525-529 |

---

## 5. Script-Dokumentation (`headspace.js`, 147 Zeilen)

### 5.1 Globale Zustandsvariablen (js Z.5-19)

| Zeile | Variable | Wert | Bedeutung |
|---|---|---|---|
| 5 | `eqClosedPos` | 207 | x-Position des linken Ohrs im geschlossenen Zustand |
| 6 | `eqOpenedPos` | 0 | x-Position offen |
| 7 | `eqIsOpen` | `false` | Zustandsflag des EQ-Drawers (einzige Wahrheit für Toggle & onEndMove) |
| 8 | `plClosedPos` | 277 | x-Position des rechten Ohrs geschlossen |
| 9 | `plOpenedPos` | 488 | x-Position offen |
| 10 | `plIsOpen` | `false` | Zustandsflag Playlist |
| 11 | `visClosedPos` | 33 | y-Position der Viz-Pille versteckt (hinter der Stirn) |
| 12 | `visOpenedPos` | 59 | y-Position sichtbar (Öffnung beginnt bei y=59) |
| 13 | `visIsOpen` | `false` | Zustandsflag Viz-Auswahl |
| 14 | `vidIsPlaying` | `false` | „es läuft Video" – steuert Viz-Sichtbarkeit und die Öffnungssperre |
| 16 | `widthClosed` | 549 | Fensterbreite geschlossen |
| 17 | `widthOpened` | 760 | Fensterbreite offen |
| 19 | `speed` | 120 | Animationsdauer aller `moveto`-Aufrufe (ms) |

### 5.2 `Init()` – js Z.21-31 (aufgerufen durch `view onLoad`)

```
Z.23   pl.setColumnResizeMode( 0, "Stretches" );        // Spalte Name: dehnt sich
Z.24   pl.setColumnResizeMode( 1, "AutoSizeData" );     // Spalte Time: an Datenbreite
Z.25   visEffects.currentEffectType = mediacenter.effectType;
Z.26   visEffects.currentPreset   = mediacenter.effectPreset;
Z.28-29 vidIsPlaying = (player.OpenState == osMediaOpen) &&
                       (player.currentMedia.ImageSourceWidth > 0);
Z.30   vidIsPlaying ? StartVideo() : EndVideo();
```

* Z.23-24: Playlist-Spaltenmodi (Breitenverhalten) – einzige Playlist-Konfiguration im Skript.
* Z.25-26: Übernahme des zuletzt global aktiven Visualisierungs-Presets aus dem WMP-Objekt `mediacenter` (Skins erben so die Vollmodus-Visualisierung).
* **Z.28-29 Videoerkennung:** Ein geöffnetes Medium gilt nur dann als Video, wenn `player.OpenState == osMediaOpen` (nicht „loading/stopped") **und** `player.currentMedia.ImageSourceWidth > 0` (das Medium hat eine Bildquelle). Ein reines Audio-Medium hat Breite 0 und fällt in den Else-Zweig.
* Z.30: Startentscheidung – Video? dann `StartVideo()` (versteckt die Visualisierung), sonst `EndVideo()` (zeigt sie). Da `visEffects.visible` im XML `false` ist, ist dies der **einzige** Weg, die Visualisierung beim Start sichtbar zu machen.
* Auffällig: `view.width` wird hier **nicht** gesetzt (Startbreite 760, s. §3.3).

### 5.3 `OnClose()` – js Z.33-37

```
Z.35   mediacenter.effectType   = visEffects.currentEffectType;
Z.36   mediacenter.effectPreset = visEffects.currentPreset;
```

Rückschreiben des im Skin (ggf. per Pille) gewählten Presets in den WMP-Zustand, damit der Vollmodus nach dem Schließen dieselbe Visualisierung zeigt. Symmetrisch zu `Init()` Z.25-26.

### 5.4 `StartVideo()` – js Z.39-52

```
Z.41   vidIsPlaying = true;
Z.43-51  if(visIsOpen) { ToggleVisView(); }              // Pille erst einfahren
         else { visEffects.visible = false;              // Viz aus
                vid.visible = true; }                    // Video an
```

* Läuft die Viz-Auswahl noch (selten: Preset geöffnet, dann startet Video), wird sie **zuerst geschlossen**; das eigentliche Umschalten passiert dann am Ende von deren Bewegung (`VisDropOnEndMove` → StartVideo, vgl. 5.11) – das ist die gegenseitige Rekursion des Skripts.
* Im Normalfall: Viz aus, Video an. `vidIsPlaying` sperrt zugleich das Öffnen der Pille.

### 5.5 `EndVideo()` – js Z.54-59

```
Z.56   visEffects.visible = true;
Z.57-58 vidIsPlaying =
       vid.visible = false;                              // Verkettete Zuweisung
```

Video aus, Visualisierung an, Flag zurückgesetzt. Beachte die verkettete Zuweisung: `vidIsPlaying` **und** `vid.visible` erhalten denselben Wert `false`.

### 5.6 `ToggleEqView()` – js Z.61-81 (linkes Ohr / Equalizer)

```
Z.63-70  if(eqIsOpen) {                                  // SCHLIESSEN
           sEqEar.moveto(eqClosedPos, sEqEar.top, speed);   // 207
           bEqHandle.image      = "L_drwr_open_01_default.bmp";
           bEqHandle.hoverImage = "L_drwr_open_02_rollover.bmp";
           bEqHandle.downImage  = "L_drwr_open_03_down.bmp";
           bEq.upToolTip = bEqHandle.upToolTip = xEqTt.toolTip;   // „Open …"
         }
Z.71-79  else {                                          // ÖFFNEN
           sEqView.visible = bEqClose.visible = true;        // sofort sichtbar
           sEqEar.moveto(eqOpenedPos, sEqEar.top, speed);    // 0
           bEqHandle.image      = "L_drwr_close_01_default.bmp";
           bEqHandle.hoverImage = "L_drwr_close_02_rollover.bmp";
           bEqHandle.downImage  = "L_drwr_close_03_down.bmp";
           bEq.upToolTip = bEqHandle.upToolTip = xEqTt.value;     // „Close …"
         }
Z.80     eqIsOpen = !eqIsOpen;
```

Erkenntnisse: (a) Beim **Öffnen** wird der Drawer-Inhalt sofort eingeblendet, beim **Schließen** bleibt er bis zum Ende der Bewegung sichtbar – das Ausblenden übernimmt `EqOnEndMove()` (5.9). (b) Das Handle-Bild wird zur Laufzeit zwischen zwei Bildsätzen umgeschaltet (deshalb existieren je 3 `open`- und 3 `close`-Dateien). (c) Der Tooltip wird über das versteckte Textfeld `xEqTt` gesetzt (5.12).

### 5.7 `TogglePlView()` – js Z.83-105 (rechtes Ohr / Playlist)

```
Z.85-93  if(plIsOpen) {                                  // SCHLIESSEN
           pl.visible = false;                              // sofort
           sPlEar.moveto(plClosedPos, sPlEar.top, speed);    // 277
           bPlHandle.image/hoverImage/downImage = R_drwr_open_0x…
           bPl.upToolTip = bPlHandle.upToolTip = xPlTt.tooltip;
         }
Z.94-103 else {                                          // ÖFFNEN
           view.width = widthOpened;                         // 760 – sofort!
           bPlClose.visible = true;                          // sofort
           sPlEar.moveto(plOpenedPos, sPlEar.top, speed);    // 488
           bPlHandle.image/hoverImage/downImage = R_drwr_close_0x…
           bPl.upToolTip = bPlHandle.upToolTip = xPlTt.value;
         }
Z.104    plIsOpen = !plIsOpen;
```

Erkenntnisse: (a) `pl.visible` wird beim Öffnen **nicht** gesetzt – die Playlist erscheint erst mit `PlOnEndMove()` (5.10), also wenn das Ohr angekommen ist. (b) Die Fensterverbreiterung geschieht **vor** der Animation, die Verschmälerung erst **nach** der Rückfahrt (in `PlOnEndMove`) – das verhindert abgeschnittene Grafiken während der Bewegung. (c) `bPlClose.visible` wird doppelt gesetzt (hier sofort und in `PlOnEndMove`). (d) Schreibweise `xPlTt.tooltip` (kleines t) statt `…toolTip` wie in Z.69 – siehe §7.

### 5.8 `ToggleVisView()` – js Z.107-122 (Viz-Auswahl-Pille)

```
Z.109-114 if(visIsOpen) {                                // SCHLIESSEN
            visDrop.moveto(visDrop.left, visClosedPos, speed);   // y 33
            vis.upToolTip = xVisTt.value;                        // BUG: sollte toolTip sein
            visIsOpen = false;
          }
Z.115-121 else if(!vidIsPlaying) {                       // ÖFFNEN (nur ohne Video!)
            visDrop.visible = true;
            visDrop.moveto(visDrop.left, visOpenedPos, speed);   // y 59
            vis.upToolTip = xVisTt.value;
            visIsOpen = true;
          }
```

Erkenntnisse: (a) Öffnen ist **gesperrt**, solange Video läuft (`!vidIsPlaying`). (b) Beim Schließen bleibt `visible` bis zum Ende der Bewegung true (Ausblenden über `VisDropOnEndMove`). (c) **Original-Bug:** In beiden Zweigen wird `xVisTt.value` („Close visualization chooser") zugewiesen – der Tooltip „Open visualization chooser" erscheint nur beim allerersten Zustand (vor dem ersten Öffnen).

### 5.9 `EqOnEndMove()` – js Z.134-138 (**Animations-Callback**)

```
Z.136-137  sEqView.visible =
           bEqClose.visible = eqIsOpen;
```

Wird von `sEqEar onEndMove` aufgerufen, wenn die `moveto`-Animation endet (nicht durch Nutzer-Drag – der Skin definiert keinen Drag-Mechanismus). Setzt Inhalt und X-Button konsistent auf den **aktuellen** Zustand: nach dem Öffnen beide `true`, nach dem Schließen beide `false`. Dieses Muster ist der Kern der Drawer-Choreografie.

### 5.10 `PlOnEndMove()` – js Z.124-132

```
Z.126-127  pl.visible =
           bPlClose.visible = plIsOpen;
Z.128-131  if(!plIsOpen) { view.width = widthClosed; }   // Fenster erst jetzt schrumpfen
```

Erkenntnisse: (a) Nach dem Öffnen werden Playlist und X sichtbar; nach dem Schließen verschwinden sie. (b) Das Fenster wird **erst** am Ende der Rückfahrt auf 549 verkleinert. (c) Der Aufrufzeitpunkt macht `onEndMove` zum Ersatz für ein „transitionend"-Event.

### 5.11 `VisDropOnEndMove()` – js Z.140-147

```
Z.142    visDrop.visible = visIsOpen;
Z.143-146 if(vidIsPlaying) { StartVideo(); }
```

Erkenntnisse: (a) Sichtbarkeit folgt dem Flag (ein-/ausblenden erst nach der Bewegung). (b) **Rekursionsauflösung:** Wird während der Rückfahrt ein Video erkannt, ruft `StartVideo()` erneut – beim zweiten Durchlauf ist `visIsOpen` false und der Video-Zweig (`visEffects.visible=false; vid.visible=true;`) läuft direkt. Die Rekursion terminiert also nach genau einem Zusatzdurchlauf. Das ist der komplette Video-Umschaltmechanismus des Skins.

### 5.12 Der hidden-text-Tooltip-Trick (`xEqTt`/`xPlTt`/`xVisTt`)

Die drei TEXT-Elemente (wms Z.515-529) sind `enabled="false"` und `visible="false"` – reine Datenhalter außerhalb jeder Darstellung. Ihr **`toolTip`-Attribut** trägt den Text für den geschlossenen, ihr **`value`** den für den offenen Zustand:

| Halter | `toolTip` (zu) | `value` (offen) | Lesestelle(n) im Skript |
|---|---|---|---|
| `xEqTt` | Open graphic equalizer controls | Close graphic equalizer controls | Z.69 (`toolTip`), Z.78 (`value`) |
| `xPlTt` | Open playlist | Close playlist | Z.92 (`tooltip` – Kleinschreibung!), Z.102 (`value`) |
| `xVisTt` | Open visualization chooser | Close visualization chooser | Z.112 (`value`), Z.119 (`value`) – **Bug** |

Zweck: WMP-Skins kennen keine Variablen-Strings für Tooltips; der Trick „missbraucht" die beiden Text-Attribute als Konstanten-Speicher, weil das Skript Attributwerte zur Laufzeit nur umschreiben, aber nicht neu erzeugen kann. Für den Port relevant: In VLC müssen Tooltip-Texte ersetzt werden, ohne dieses Muster übernehmen zu können (→ §6/Hinweise).

### 5.13 Weitere Script-Beobachtungen

* **Kein `onReSize`, kein `onTimer`, kein `onError`** – der Skin ist rein eventgetrieben; alle Übergänge bestehen aus `moveto` + `onEndMove` + Flag.
* **Keine Persistenz**: Öffnungszustände werden nicht gespeichert (Neustart immer geschlossen).
* **Keine Fehlerbehandlung** und keine Prüfung, ob `mediacenter` existiert.
* `speed = 120` ms für alle drei Panels – einheitliches, eher flottes Gefühl.

---

## 6. Funktionensoll (Gesamtliste für das spätere VLC-Mapping)

Jede Zeile: **Was** – **Auslöser** – **sichtbares Feedback**. Nummerierung fortlaufend.

### A. Transport

1. **Play/Pause starten** – `playelement` (Klickregion `#FFFF00`, Position 335/32 im Kreis-Strip) – Wiedergabe startet/pausiert; Strip zeigt Default→Rollover→Down; bei laufender Wiedergabe liegt der Pause-Button (z=3) exakt darüber und zeigt statt Play das Pause-Symbol.
2. **Pause/Losspielen** – `pausebutton` (335/32, sichtbar nur `wmpenabled:player.controls.pause`) – Pause-Symbol ↔ Wiedergabe; Button verschwindet bei gestoppter/leerer Wiedergabe.
3. **Stop** – `stopelement` (361/32) – Wiedergabe stoppt, Track-Position bleibt (WMP-Standard), Strip-Feedback.
4. **Vorheriger Titel** – `prevelement` (310/32) – Trackwechsel, Strip-Feedback.
5. **Nächster Titel** – `nextelement` (386/32) – Trackwechsel, Strip-Feedback.
6. **Funktionslücke:** Es gibt **kein** Spulen (FF/RW), kein Shuffle/Repeat, kein „Stumm"-Symbol.

### B. Fenster (Min/Close/Ziehen)

7. **Minimieren** – Minimize-Region (362/4) – Fenster wird minimiert (`view.minimize()`), Skin-Zustand bleibt erhalten.
8. **Schließen** – Close-Region (377/4) – Fenster schließt (`view.close()`); `onClose` schreibt das Visualisierungs-Preset nach `mediacenter` zurück.
9. **Fenster verschieben** – Ziehen an einer klickfreien Stelle der View (kein `titleBar`) – Skin folgt der Maus (WMP-Standardfenstermechanik, kein Skin-Code).
10. **Fensterbreite** – automatisch beim Playlist-Öffnen/-Schließen – 549 px ↔ 760 px; **kein** manuelles Resizing möglich (`resizable="false"`).

### C. Seek & Status

11. **Springen im Titel** – `seek`-Slider ziehen (300/223, 163×9) – Thumb folgt der Maus (Hover-/Down-Grafik), Position wird erst bei `onDragEnd` gesetzt; Track-Position ändert sich hörbar erst beim Loslassen.
12. **Position anzeigen** – laufender Track – `value` folgt `player.controls.currentposition`; der violette Foreground wird mit der Position „aufgedeckt" (`slide=false`) – die Farbe markiert also **nicht** die Position (positioniert wird über den Thumb), sondern die Hintergrundfüllung.
13. **Download-/Pufferfortschritt anzeigen** – `foregroundProgress=player.network.downloadProgress` – bei Streams/Downloads läuft die Aufdeckung des violetten Bildes dem Abspielpunkt voraus.
14. **Funktionslücke:** Keine numerische Zeit-/Dauer-Anzeige, kein Fortschrittstext, keine Bitraten-/Statuszeile.

### D. Screen (Visualisierung, Video, Viz-Auswahl)

15. **Visualisierung zeigen** – automatisch, wenn kein Video erkannt wird (`EndVideo()`, `visEffects.visible=true`) – Farb-/Formanimation im Screen.
16. **Video zeigen** – automatisch, wenn `OnVideoStart` feuert – Video (193×135) anstelle der Visualisierung, zugleich Viz-Pille gesperrt (`!vidIsPlaying`).
17. **Video→Visualisierung zurückschalten** – `OnVideoEnd` – Visualisierung erscheint ohne Nutzeraktion.
18. **Viz-Auswahl öffnen** – `vis`-Button (Sonne, 428/32) oder erneut Close-Kreis – Pille fährt in 120 ms aus der Stirn in die Bildschirmöffnung (y 33→59).
19. **Viz-Preset wechseln** – Pfeil links (300/62) → `visEffects.previous()`; Pfeil rechts (426/62) → `visEffects.next()` – Visualisierung wechselt, mittig zeigt der Text den Preset-Namen (`visEffects.currentPresetTitle`).
20. **Viz-Auswahl schließen** – X (448/67) oder `vis`-Button – Pille fährt hoch und verschwindet hinter der Stirn; `visible` erst nach der Bewegung false.
21. **Preset merken** – beim Schließen des Skins (`OnClose`) – beim nächsten Öffnen/Init wird dasselbe Preset geladen (über `mediacenter`).

### E. Linkes Ohr (Drawer links)

22. **EQ-Drawer öffnen/schließen** – `bEq` (276/214, Kinn) **oder** der Griff `bEqHandle` (215/152, geschlossen; im offenen Drawer 8/152) **oder** das X `bEqClose` (72/93, nur offen sichtbar) – Ohr fährt 207→0 px (120 ms); Griff-Symbol wechselt (Open→Close-Pfeil), Tooltip wechselt, Panel-Inhalt erscheint (öffnend sofort, schließend erst nach der Fahrt).
23. **Balance einstellen** – Slider (im offenen Drawer absolut x 92–162, y 107–117) – Thumb bewegt sich, Wert sofort an WMP (`player.settings.balance`), keine Zahlanzeige.
24. **Lautstärke einstellen** – Slider (absolut x 173–243, y 107–117) – Thumb, Wert sofort gesetzt; **jede** Änderung hebt Stummschaltung auf.
25. **10-Band-Equalizer einstellen** – 10 vertikale Slider (absolut x 95–241, y 140–215) – Thumb; jedes Band schreibt `eq.gainLevelN` (−14…+14).
26. **Equalizer zurücksetzen** – Textlink „reset" (absolut 224/223) – alle 10 Bänder springen auf 0 (Thumbs wandern), Tooltip „Reset graphic equalizer controls".
27. **Drawer-Tooltips aktualisieren** – im Toggle – Griff/BEq zeigen „Open…"/„Close…" passend zum Zustand (per hidden-text-Trick).

### F. Rechtes Ohr (Drawer rechts)

28. **Playlist-Drawer öffnen** – `bPl` (465/214, Kinn) **oder** Griff `bPlHandle` (im offenen Drawer absolut 734/151; geschlossen 523/151) – Fenster verbreitert sich sofort auf 760 px, Ohr fährt 277→488 (120 ms), danach erscheint die Playlist.
29. **Playlist schließen** – X `bPlClose` (im offenen Drawer 677/93) oder erneut `bPl`/Griff – Playlist verschwindet sofort, Ohr fährt zurück, **danach** schrumpft das Fenster auf 549 px.
30. **Titel in der Playlist anwählen** – Playlist-Zeilen (501–672/96–236) – WMP-Standardplaylist: Zeile anklicken, Dropdown ist eingeblendet (`dropDownVisible`), Spaltenkopf ausgeblendet; Spalte Name dehnt, Time passt sich an.

### G. Sonstiges

31. **Zurück in den Vollmodus** – Theme-Button (362/232) – `view.returnToMediaCenter()`; WMP verlässt den Skin-Modus.
32. **Tooltips** – Hover über Transport, EQ/PL-Buttons, Handles, Slider, Theme-Button, Reset – Textblasen (`upToolTip`/`toolTip`), teils zustandsabhängig umgeschrieben.
33. **Zustandsbilder (visuelles Feedback)** – Hover/Drücken/Deaktiviert – Rollover- und Down-Bilder an allen Buttons, Disabled-Varianten (nur teilweise angebunden), Thumb-Varianten am Seekbar.

---

## 7. Offene Unklarheiten

1. **Zweites Skript `res://wmploc.dll/RT_TEXT/#132`** (wms Z.13): Inhalt nicht einsehbar (Ressource in einer WMP-System-DLL). Welche Helfer es bereitstellt (vermutlich jScript-Utilities/Hilfsfunktionen älterer Microsoft-Skins), ist unklar – der sichtbare Code nutzt es nicht direkt auf.
2. **`mediacenter`-Objekt**: `mediacenter.effectType`/`effectPreset` sind in der verfügbaren MS-Doku nicht beschrieben (Legacy-/Media-Center-Bindung). Wertebereiche und Semantik (Preset-Indizes? Namen?) bleiben offen; ebenso, ob ein leerer/ungültiger Wert das Rendern der Visualisierung stört.
3. **„Headspace" vs. „Headspace Beta"** (WMP Goodies: 237 KB vs. 236 KB): Unsere `.wmz` = 241.903 Bytes = 236,2 KiB → Indiz für die **Beta**-Fassung. Beweis nur durch Beschaffung und Vergleich der zweiten Variante.
4. **Startbreite 760 statt 549**: `Init()` setzt die Breite nicht; ob WMP9 die Skinbreite beim Laden auf den Inhalt zuschneidet (Transparenz) oder tatsächlich 211 px unsichtbare Fensterfläche rechts bestehen (Klick-/Fokusverhalten?), ist nicht aus den Dateien ableitbar (kein laufendes WMP9 verfügbar; Live-Test im Projekt noch offen).
5. **Hit-Test von `transparencyColor`-Flächen**: Die MS-Doku beschreibt `clippingColor` explizit als „transparent, **non-clickable**"; für `transparencyColor` ist das Klickverhalten nicht ausformuliert. Für den Port relevant (Klick auf die Ohren/Magenta-Bereiche).
6. **Zwei unbenutzte Disabled-Assets** (`L_drwr_04_disabled.bmp`, `R_drwr_04_disabled.bmp`): Absicht (Reserve) oder vergessene Anbindung (`disabledImage` fehlt an beiden Handles)?
7. **Fehlende Zustände**: `left_X`/`right_X` ohne `03_down`, `pause`/`themebutton`/`thumb` ohne `04_disabled` – bewusste Reduktion oder Nachlässigkeit?
8. **Tooltip-Bug bei `vis`** (js Z.112/119, beide `xVisTt.value`): als Bug dokumentiert – ob WMP dennoch „Open…" anzeigt (z. B. weil der Initialwert erhalten bleibt, bis er überschrieben wird, was hier eben passiert), ändert die Bewertung nicht, ist aber ungetestet.
9. **Schreibweise `xPlTt.tooltip`** (js Z.92, kleines „t") vs. `xEqTt.toolTip` (Z.69): Falls der WMP-Skripthost case-sensitive arbeitet, wäre `bPl`-Tooltip nach dem ersten Schließen leer/undefined – nicht verifizierbar ohne WMP.
10. **`vid_bkgd.bmp` 216×159 vs. Subview 216×158** (1 px Überhang): Absicht oder Kopierfehler? Sichtbare Auswirkung minimal (unterste Zeile liegt hinter dem Kinn).
11. **Weiße Ecken in `vid_bkgd.bmp`** liegen (nachgerechnet) **außerhalb** der Gesichtsöffnung und sind damit faktisch unsichtbar – vermutlich ein Überrest aus einer früheren Fensterform/Anordnung.
12. **Rundungsdetails der Gesichtsöffnung**: Die Magenta-Fläche ist blobförmig (y=59 nur 59 px breit, Maximum 214 px in y≈150). Ob WMP die Öffnung pixelgenau 1:1 nutzt (davon gehen wir aus; Composite deckt sich mit der offiziellen Vorschau) oder ob Skalierung/Clipping-Rundungen hinzukommen, ist ohne Live-Rendering nicht endgültig belegbar.
13. **`borderSize`-Feinsemantik bei `tiled`**: Die Doku (MS Learn `SLIDER.borderSize`) beschreibt Rand-Offset und Tiling-Verhalten; die exakte Thumb-Wege-Berechnung (z. B. Seek: 163 − 2×9 = 145 px?) ist daraus nicht eindeutig – für den Port nachzubauen und zu testen.
14. **Foreground-Progress bei lokalen Dateien**: `downloadProgress` ist lokal immer 100 % – ob die violette Fläche dann den ganzen Track füllt (und der graue Track nie sichtbar ist), ist plausibel, aber ungetestet.
15. **WMP-7- vs. WMP-9-Rendering** des Skins (Beta-Zeitraum): Da die Dateien aus der WMP-7-Entwicklung stammen, könnte es in WMP 9 Abweichungen geben (z. B. Tooltip- oder Playlist-Verhalten). Live-Referenz im Projekt noch offen.

---

## Anhang A – Dateipfade

| Inhalt | Pfad |
|---|---|
| Diese Dokumentation | `C:\GitHub\VLC_Skins\research\02-headspace-reverse-engineering.md` |
| Asset-Inventar (CSV) | `C:\GitHub\VLC_Skins\research\original\inventory.csv` |
| Controls (JSON) | `C:\GitHub\VLC_Skins\research\original\controls.json` |
| Original-Skin (unverändert) | `C:\GitHub\VLC_Skins\research\original\extracted\` (82 Dateien) |
| Original-Archiv | `C:\GitHub\VLC_Skins\research\original\Headspace.wmz` |
| Offizielle Vorschau | `C:\GitHub\VLC_Skins\research\original\Headspace_preview.png` (342×394) |
| Einzel-Asset-Previews | `C:\GitHub\VLC_Skins\research\previews\` |
| Rekonstruierte Zustände (neu) | `C:\GitHub\VLC_Skins\research\previews\states\state-A-closed.png`, `state-B-eq-open.png`, `state-C-pl-open.png`, `state-D-vis-open.png` |
| Projektplan | `C:\GitHub\VLC_Skins\research\00-plan.md` |

## Anhang B – Zeilennummern-Index

**`headspace.wms` (531 Zeilen)**

| Zeilen | Inhalt |
|---|---|
| 1-8 | Kommentar + Theme-Kopf (id/author/copyright) |
| 9-16 | VIEW (760×394, scriptFile, onLoad, onClose) |
| 17-177 | Kopf-Subview |
| 23-40 / 41-63 | buttongroup Min/Close · buttongroup Play-Controls |
| 64-71 | pausebutton |
| 72-81 / 82-91 | bEq · bPl |
| 92-107 | seek-Slider |
| 108-115 | themebutton |
| 117-132 | Screen-Subview mit effects (122-125) und video (126-131) |
| 134-176 | visDrop mit 3 Buttons (143-170) und Text (171-175) |
| 179-433 | sEqEar (Ohr) mit earFace (188-212), Blenden (213-228), sEqView (229-432) |
| 234-253 / 289-290 / 292-421 / 422-431 | EQ-Innenflächen · equalizerSettings · eq1…eq10 · Reset-Link |
| 434-513 | sPlEar mit Blenden (442-454), plEar+Handles (455-479), plView+Playlist (480-511) |
| 515-529 | xEqTt / xPlTt / xVisTt |

**`headspace.js` (147 Zeilen)**

| Zeilen | Inhalt |
|---|---|
| 1-3 | Copyright-Kommentar |
| 5-19 | Zustandsvariablen + `speed` |
| 21-31 | `Init()` |
| 33-37 | `OnClose()` |
| 39-52 | `StartVideo()` |
| 54-59 | `EndVideo()` |
| 61-81 | `ToggleEqView()` |
| 83-105 | `TogglePlView()` |
| 107-122 | `ToggleVisView()` |
| 124-132 | `PlOnEndMove()` |
| 134-138 | `EqOnEndMove()` |
| 140-147 | `VisDropOnEndMove()` |

## Anhang C – Verifikationsmethodik

1. **Maße/Farben:** `Add-Type -AssemblyName System.Drawing`, `[System.Drawing.Image]::FromFile(...).Width/.Height`; Pixelanalysen mit `Bitmap.GetPixel` (Zählung aller Key-Farben, Bounding-Boxen, Spalten-/Zeilenprofile) – Ergebnisse in §2/§3.
2. **Referenz-Abgleich:** Regex-Extraktion aller `*.bmp`-Referenzen aus `.wms`+`.js` gegen die Dateiliste: 78 referenziert / 80 vorhanden → genau 2 unbenutzte Dateien (`L_drwr_04_disabled.bmp`, `R_drwr_04_disabled.bmp`), keine fehlenden Referenzen.
3. **Schichtmodell:** Nachbau des Draw-Orders (VIEW-Kinder nach zIndex; Hintergrundbild = z0; negative zIndex-Kinder dahinter; Key-Farben pro Element) in PowerShell, Ausgabe der 4 Zustands-PNGs, Sichtvergleich mit `Headspace_preview.png`.
4. **Gegenproben:** Video-Oberkante ↔ Öffnungsbreite; Pause ↔ Play-Kreis; Fensterbreite ↔ Ohr-Kanten; Vorschau-Breite 342 = 549 − 207.

---

## Zusammenfassung

Der Skin **„Headspace"** (Theme-ID `headspace`, © 2000 Microsoft) ist ein mit **Windows Media Player 7** ausgelieferter offizieller Microsoft-Skin (Wikipedia: initiales WMP-7-Skinset „Classic, Headspace, Miniplayer, Optik, Roundlet, Rusty, Toothy"; Trashworld News und WMP Goodies führen ihn als „Microsoft Corporation"). Die Datei entstammt dem archive.org-Sammelarchiv und umfasst 82 entpackte Dateien: `headspace.wms` (531 Zeilen XML), `headspace.js` (147 Zeilen JScript) und 80 BMPs. Die Zeitstempel (2000-01-29 bis 2000-06-23) datieren die Entwicklung in die WMP-7-Beta-Phase; die Größe (236 KiB) deutet auf die von WMP Goodies gelistete „Headspace Beta"-Fassung hin.

Die Gestaltung: ein grüner Kopf (234×394) mit ovaler Gesichtsöffnung, die als Magenta-Transparenz (`#FF00FF`) in `head.bmp` liegt, während der Rest der Fensterfläche als Rot-Clip (`#FF0000`) weggeschnitten wird. Das Kernprinzip des Layouts ist das Schichtmodell: Screen (-2) und Visualisierungs-Auswahl (-1) liegen **hinter** dem Kopfbild und werden nur durch die Öffnung sichtbar; beide „Ohren" sind verschiebbare Subviews hinter dem Kopf. Links fährt im geöffneten Zustand der 10-Band-Equalizer-Drawer (207→0 px), rechts die Playlist (277→488 px, dabei wächst das Fenster von 549 auf 760 px). Eine dritte Bewegung ist die Visualisierungs-Auswahl „vizDrop", die von y=33 (hinter der Stirn) auf y=59 in den Screen-Bereich fährt. Alle Animationen laufen mit `speed=120` ms und nutzen `onEndMove` als Animations-Callback – daraus ergibt sich die saubere Choreografie (Inhalt ein-/ausblenden erst nach der Fahrt).

Die Funktionsliste ist vollständig: Transport (Play/Pause/Stop/Prev/Next – kein FF/RW), Fenster (Minimize/Close/Drag, dynamische Breite), Seek-Slider mit Download-Fortschritt (`foregroundProgress`), Screen mit automatischem Umschalten Video↔Visualisierung (`OnVideoStart`/`OnVideoEnd`, Videoerkennung über `player.currentMedia.ImageSourceWidth>0`), EQ-Drawer mit Balance, Volume und 10 Bändern (−14…+14, Reset), Playlist-Drawer sowie „Return to Full Mode". 68 Controls sind in `controls.json` mit exakten Koordinaten, zIndex-Werten, Assets, Events und Quellzeilen dokumentiert; `inventory.csv` erfasst alle 80 Assets mit Maßen, Bytegrößen, Zustands-Suffixen und Uprez-Einstufung. Die Rekonstruktion der vier Hauptzustände deckt sich mit der offiziellen Vorschau (342×394 = sichtbarer Inhalt 207–548 px). Offen bleiben vor allem das zweite DLL-Skript, das undokumentierte `mediacenter`-Objekt und der Live-Abgleich in WMP 9.
