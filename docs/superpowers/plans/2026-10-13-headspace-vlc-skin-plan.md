# Headspace → VLC Skin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Den Original-Skin „Headspace" (WMP7, © 2000, Microsoft) als VLC-3.0.x-skins2-Skin `dist/Headspace.vlt` maximal originalgetreu neu auflegen (2×-Auflösung).

**Architecture:** Ein Fenster `main` mit 4 Layouts (closed/EQ/PL/beides, Maße = Original ×2) und instant `setLayout`-Umschaltung; alle Controls 1:1 aus `headspace.wms`-Koordinaten ×2; EQ voll verdrahtet (`equalizer.band(0..9)`); Screen = eingebettetes `<Video>` (`visible="vlc.hasVout"`). `theme.xml` wird per Build-Skript aus XML-Fragmenten (gemeinsame Teile + je Layout) assembliert und validiert. Assets werden aus den unveränderten Original-BMPs abgeleitet (Farbkey→Alpha, Real-ESRGAN 4×→2×, Handretouch), flache Flächen prozedural.

**Tech Stack:** VLC 3.0.23 (Windows, skins2, DTD 2.0), PowerShell 5.1 (Build/Assets/Tests), Real-ESRGAN-ncnn-vulkan (portable, RTX 4070), 7-Zip, ffmpeg (nur Testmedien), `research/spike/winhelp.ps1` (Screenshot/Klick-Helfer).

**Spec:** `docs/superpowers/specs/2026-10-13-headspace-vlc-skin-design.md`

## Global Constraints

- Zielversion VLC 3.0.x (getestet wird 3.0.23); Wurzel-XML heißt **`theme.xml`**, `<Theme version="2.0">`, DOCTYPE wie in `default.vlt`.
- **Alle Koordinaten/Maße = Original × 2** (Quelle: `research/02-headspace-reverse-engineering.md` Kapitel 3 + `research/original/controls.json`; Original-Werte NICHT runden, exakt verdoppeln).
- **Original-Assets in `research/original/` werden nie verändert**; alle Ableitungen entstehen neu in `src/theme/images/`.
- Keine toten Controls; Ersatzlösungen exakt wie Spec §5.2 (Balance→Mute-LED, Reset→EQ-An/Aus-Link, Return→`dialogs.changeSkin()`, Viz-Menü entfernt, kein Zeit-Text, keine Disabled-Optik).
- Kein neues visuelles Design außer den abgesegneten Ersatz-Elementen (Mute-LED, Track-Frames, Idle-Fläche) in Original-Farbwelt.
- **Harter Freigabe-Gate:** Upscale-Ergebnisse werden dem Nutzer visuell vorgelegt; erst nach explizitem OK wird in Serie verarbeitet (Task 1, STOP-Schritt).
- Tooltips: Original-Wortlaut (Englisch). Skin-Texte/Kommentare englisch; Repo-Doku deutsch.
- Jeder Task endet mit Commit (`git commit`), Testnachweis gehört in die Commit-Message-Notiz.
- VLC-Tests immer mit Config-Backup/Restore (`%APPDATA%\vlc\vlcrc`), Logcheck via `--file-logging -vvv` (keine `bad theme`/`unknown`-Meldungen), Fenster deterministisch via `skins2-config`-Edit platzieren.

## Review Focus

- **Playlist-Scroll & lange Einträge** (Ordner-Baum, sehr lange Titel) → muss bedienbar bleiben und darf nicht überlaufen. Test in Task 5.
- **Dateipfade mit Leerzeichen/Umlauten** für `--skins2-last` und `Open skin…` → Skin muss trotzdem laden. Test in Task 3.
- **Video-Seitenverhältnisse** (4:3/16:9/Hochformat) im festen Screen-Ausschnitt → darf nichts außerhalb durchscheinen lassen. Test in Task 6.
- **Audio ohne Video** → Screen zeigt Idle-Fläche, nicht Schwarz-Reste des letzten Vouts. Test in Task 6.
- **Schnelles Layout-Toggeln während Wiedergabe** → Video/EQ bleiben intakt, kein Absturz. Test in Task 6.
- **Multi-Monitor/Negativ-Koordinaten** → Fenster erscheint sichtbar auf dem aktiven Monitor. Test in Task 3.

---

### Task 1: Upscale-Prototyp + Vergleichsblatt — **GATE: visuelle Freigabe durch den Nutzer**

**Files:**
- Create: `tools/prepare_assets.ps1` (Aufbereitung: BMP→PNG32, Farbkey→Alpha, Upscale, Downsample, Track-Frames)
- Create: `tools/fetch_realesrgan.ps1` (Download+Entpacken des Tools)
- Create: `research/upscale-review/*.png` (Vergleichsbilder), `research/upscale-review/decisions.md`
- Create: `.gitignore` (`tools/realesrgan/`, `research/spike/*.log`, temporär)

**Interfaces:**
- Produces: `Convert-HeadspaceAsset` (Parameter: `-InFile`, `-OutFile`, `-KeyColor`, `-TargetScale 2`, `-Model`), verifizierte Modellwahl pro Asset-Klasse in `decisions.md` — Task 2 nutzt beides.

- [ ] **Step 1: Git-Baseline**

```powershell
git init; git add -A; git commit -m "chore: research baseline (RE docs, spike results, original assets)"
```
Falls keine globale Git-Identität: repo-lokal `git config user.name "VLC_Skins Build"` / `user.email "build@local"`.

- [ ] **Step 2: Real-ESRGAN beschaffen und Funktionscheck**

Download (offizielles Release): `https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesrgan-ncnn-vulkan-20220424-windows.zip` → `tools/realesrgan/`.
Verifizieren: `& tools\realesrgan\realesrgan-ncnn-vulkan.exe -h` zeigt Usage; Modelle `realesrgan-x4plus` + `realesrgan-x4plus-anime` vorhanden.

- [ ] **Step 3: `prepare_assets.ps1` — Kernfunktionen schreiben**

Funktionen: `ConvertTo-Png32` (BMP→PNG32), `Remove-KeyColor` (Farbkey → Alpha 0, Kanten mit 1px-Weichzeichnung), `Invoke-Upscale4x` (Aufruf realesrgan mit gegebenem Modell), `Downscale-2x` (System.Drawing HighQualityBicubic), `New-SliderFrames` (SliderBackground-Strips generieren, s. Task 2).
Referenz für Farbkeys: `research/02-headspace-reverse-engineering.md` §2 (Magenta `#FF00FF` = Transparenz; Rot `#FF0000` = Clip in `head.bmp`; Weiß in `vid_bkgd`).

- [ ] **Step 4: Sample-Set beiderlei Modelle rendern (4× → Downsample 2×)**

Sample: `head.bmp`, `left_ear.bmp`, `right_ear.bmp`, `play_controls_01_default.bmp`, `progressbar.bmp` + `progressbar_foreground.bmp`, `thumb_01_default.bmp`, `L_drwr_open_01_default.bmp`, `EQ_01_DF.bmp`.
Ausgabe pro Asset: Original (nearest 2×) | x4plus→2× | x4plus-anime→2×.

- [ ] **Step 5: Vergleichsblätter erzeugen und dem Nutzer vorlegen**

Pro Asset ein PNG in `research/upscale-review/` (3 Spalten, 100 % Zoom + 4× Detailausschnitt), plus Übersichtsblatt. Vorlegen via `browser.preview`. 

- [ ] **Step 6: STOP — Freigabe einholen**

Ergebnis in `decisions.md` festhalten (Modell je Asset-Klasse + gewünschte Handretouchen). **Erst nach explizitem OK des Nutzers weiter zu Task 2.**

- [ ] **Step 7: Commit** (`feat: upscale prototype + comparison sheets`)

---

### Task 2: Komplette Asset-Produktion + theme.xml-Generator

**Files:**
- Create: `src/theme/xml/header.xml` (Theme, ThemeInfo, Font, alle Bitmap/SubBitmap-Definitionen)
- Create: `src/theme/xml/layout_closed.xml`, `layout_eq.xml`, `layout_pl.xml`, `layout_both.xml`
- Create: `tools/build_theme.ps1` (assembliert `src/theme/theme.xml` + validiert)
- Create: `tools/pack.ps1` (ZIP → `dist/Headspace.vlt`)
- Modify: `tools/prepare_assets.ps1` (alle 80 Assets nach `src/theme/images/`)
- Create: `src/theme/fonts/font.otf` (Kopie aus `research/refs/default-vlt/default/subX/font.otf`; Font-ID heißt `defaultfont`, damit Theme-`tooltipfont` greift)

**Interfaces:**
- Consumes: `decisions.md` + `Convert-HeadspaceAsset` (Task 1).
- Produces: `build_theme.ps1` schreibt bei Fehlern Exit-Code ≠ 0; `src/theme/images/*.png` (2×) + `src/theme/theme.xml` — Tasks 3–6 editieren nur noch die XML-Fragmente und rufen Builder+Pack+ Test auf.

- [ ] **Step 1: Alle Assets verarbeiten**

`prepare_assets.ps1` über `research/original/extracted/` laufen lassen. Sonderfälle: Buttons aus `*_map.bmp`-Zonen als `SubBitmap`-Regionen (Koord. ×2) im Header deklarieren (Sheet bleibt 1 Bitmap je Zustand); flache Flächen `drawer_bkgrnd_*`, `vid_bkgd` prozedural in Original-Farben neu zeichnen (2×); `progressbar`-Füllframes: 64 Frames, Breite 326, generiert.
Sichtprobe: Montage aller verarbeiteten Assets als Kontaktbogen → `browser.preview`.

- [ ] **Step 2: `build_theme.ps1` schreiben**

Assembliert: Theme-Header + `<Window id="main" position="Center">` + 4 `<Layout>`-Blöcke (Reihenfolge: `l_eq, l_pl, l_both, l_closed` — gemäß offener Frage „zuletzt deklariertes Layout ist Erststart-Default", wird in Task 3 verifiziert). Validierung: XML wohlgeformt (`[xml]`-Cast), **alle IDs eindeutig**, alle `image`/`up`/`down`/`over`/`up1`/`up2`/`background`-Referenzen existieren in `header.xml`, Koordinaten liegen innerhalb der Layout-Maße. Ausgabe: `src/theme/theme.xml`.

- [ ] **Step 3: `pack.ps1` schreiben** — packt `src/theme/` (theme.xml, images/, fonts/) deterministisch als ZIP nach `dist/Headspace.vlt`; Kontrolle: `7z l`.

- [ ] **Step 4: Testlauf mit leerem Basis-Layout**

Minimal-`l_closed` (nur Hintergrund + Close-Button) bauen, packen, laden: `-I skins --skins2-last=dist\Headspace.vlt -vvv --file-logging` → Log sauber, Fenster erscheint. Damit ist die Toolchain bewiesen (Builder→Pack→Load).

- [ ] **Step 5: Commit** (`feat: asset pipeline + theme generator`)

---

### Task 3: `l_closed` komplett (M2)

**Files:**
- Modify: `src/theme/xml/header.xml` (SubBitmap-Regionen für Transport/Systembuttons), `src/theme/xml/layout_closed.xml`
- Create: `tools/test_skin.ps1` (positioniert Fenster via `skins2-config`, lädt Skin, macht Screenshots, greppt Log)

**Interfaces:**
- Consumes: Builder/Pack aus Task 2. Produces: `test_skin.ps1 -ExpectedWidth <px> -ShotName <name>` (Exit ≠ 0 bei Log-Fund/fehlendem Fenster) — Tasks 4–6 nutzen es.

- [ ] **Step 1: `layout_closed.xml` schreiben** — Controls (absolute Koordinaten = Original ×2, Quelle `02-…md` §3): Kopf-Image (inkl. Alpha-Öffnung), geschlossene Ohr-Grafiken, Minimize/Close, Prev/Play/Stop/Next (SubBitmaps), Pause-Overlay (`visible="vlc.isPlaying"`), Seek-Slider (`value="time"` + 64-Frame-`SliderBackground`) + Thumbs, EQ-/PL-Handle-Buttons (`main.setLayout(l_eq/l_pl)`), „Return"-Button (`dialogs.changeSkin()`), Drag-Handle (`action="move"`), Tooltips im Original-Wortlaut. `position="Center"`.

- [ ] **Step 2: Test 2 des Spec-Testprotokolls ausführen**

Screenshot `l_closed` (1100×788) vs. `state-A-closed.png` (2× skalierte Referenz) → Sichtvergleich. Interaktionen per `winhelp.ps1`: Tooltip (Hover), Minimize, Close (Programm endet), Drag **einmal manuell durch den Nutzer bestätigen lassen**, Erststart-Test mit gelöschtem `skins2-config`-Eintrag → beobachtetes Default-Layout dokumentieren und Layout-Reihenfolge final anpassen.
**Review-Focus-Tests:** Pfad mit Leerzeichen/Umlaut (`C:\...\Head space Prüf.vlt`) lädt; Fenster landet sichtbar auf dem Monitor (auch nach `skins2-config`-Position mit Negativkoordinaten).

- [ ] **Step 3: Commit** (`feat: closed layout complete`)

---

### Task 4: `l_eq` + Equalizer (M3)

**Files:** Modify: `src/theme/xml/layout_eq.xml` (+ ggf. `header.xml` für Mute-LED-Assets)

- [ ] **Step 1: Layout schreiben** — geöffnete EQ-Schublade an Original-Positionen (Drawer-Grafiken, Volume-Slider `value="volume"`, 10 EQ-Slider `value="equalizer.band(0..9)`" mit `background`-Track + Thumb, Mute-LED (`state="vlc.isMute"`, `action="vlc.mute()"`), EQ-An/Aus-Link (`state="equalizer.isEnabled"`, `actions equalizer.enable()/disable()`), Labels „Volume"/„Mute" in 2×-Schrift, Close-X → `setLayout(l_closed)`, Tooltips.

- [ ] **Step 2: Test 3 (Spec)** — Öffnen/Schließen; Screenshot vs. `state-B-eq-open.png`; EQ-Slider-Drag → `vlcrc` hat geänderten `equalizer-bands`-Eintrag; Enable-Link toggelt `equalizer.isEnabled`; Mute-LED toggelt `vlc.isMute`; Volume-Slider wirkt. 

- [ ] **Step 3: Commit** (`feat: equalizer drawer`)

---

### Task 5: `l_pl` + Playlist (M4)

**Files:** Modify: `src/theme/xml/layout_pl.xml` (+ ggf. Scroll-Slider-Styling in Assets)

- [ ] **Step 1: Layout schreiben** — geöffnete PL-Schublade (Drawer-Grafiken, `<Playtree flat="true">` mit Pflicht-`<Slider>`-Kind, Original-Optik: bgcolor `#285F03`, fgcolor weiß, Close-X → `setLayout(l_closed)`, Handle-Button zurück).

- [ ] **Step 2: Test 4 (Spec)** — Öffnen/Schließen; Playlist mit Testmedien befüllen (Drag&Drop von Dateien, `playlist.add()` via Button-Doppelklick?); **Review-Focus: sehr lange Titel + 200-Einträge-Liste → Scroll per Mausrad + Slider; kein Überlauf**; Screenshot vs. `state-C-pl-open.png`.

- [ ] **Step 3: Commit** (`feat: playlist drawer`)

---

### Task 6: `l_both`, Screen/Video, Robustheit (M5a)

**Files:** Modify: `src/theme/xml/layout_both.xml`, `layout_closed.xml`/`layout_eq.xml`/`layout_pl.xml` (Screen-Control + Idle-Fläche konsistent), ggf. Assets.

- [ ] **Step 1: `l_both` + Screen** — beide Schubladen; `<Video>` an Original-Koordinaten (`visible="vlc.hasVout"`), darunter dunkle Idle-Fläche (Original-Look).

- [ ] **Step 2: Test 6 (Spec) + Review-Focus** — Video 4:3/16:9/hochkant: nichts scheint außerhalb des Ausschnitts durch; Audio ohne Video → Idle statt Schwarz-Rest (nach Video-Stop prüfen); **schnelles Layout-Toggeln (10×) während Video läuft** → stabil; Video überlebt alle vier Layouts.

- [ ] **Step 3: Fehlerfall-Test** — absichtlich kaputtes `theme.xml` (ungültige Referenz) → VLC fällt auf `default.vlt` zurück, kein Crash; fehlerfreie Variante erneut laden.

- [ ] **Step 4: Commit** (`feat: both drawers + embedded video`)

---

### Task 7: Feinschliff, Doku, Endabnahme (M5b)

**Files:** Create: `README.md`; Finale: `dist/Headspace.vlt`, `docs/…`-Abnahme-Nachweise; `research/00-plan.md` (Status)

- [ ] **Step 1: Endabnahme-Checkliste (Spec §7.3) komplett durchfahren** und Ergebnis mit Screenshots in `research/final-verification/` dokumentieren.

- [ ] **Step 2: README schreiben** — Installation (3 Wege: Open skin…, `--skins2-last`, Kopie in `Program Files\VideoLAN\VLC\skins`), Bedienung, Credits („Original skin ‚Headspace' © 2000 Microsoft Corporation"), Abweichungsliste (Spec §5.2), Build-Anleitung (`prepare_assets` → `build_theme` → `pack`, in dieser Reihenfolge).

- [ ] **Step 3: Vergleichsblatt final** — 4 Zustände unseres Skins (2×) neben den Original-Rekonstruktionen (2×-skaliert) → `browser.preview` + Nutzerfeedback.

- [ ] **Step 4: Commit + Tag** (`release: Headspace.vlt 1.0`)

---

## Self-Review-Ergebnis (durchgeführt)

- **Spec-Abdeckung:** §5.1→T2/T3/T4/T5/T6, §5.2→T3–T6 (jede Zeile adressiert), §6→T1/T2, §7→T3–T7, §8-Risiken→ T1 (Kopf-Qualität), T3 (Erststart/Monitor), T6 (Album-Cover bleibt optional, im Test nur dokumentiert), §9-Meilensteine↔Tasks deckungsgleich.
- **Keine TBDs**; offener Punkt „Erststart-Layout" hat definierte Vorgehensweise (T3 Step 2).
- **Typkonsistenz:** Funktions-/Dateinamen über Tasks konsistent (`build_theme.ps1`→`theme.xml`→`pack.ps1`→`dist/Headspace.vlt`; `test_skin.ps1` in T3 definiert, T4–T6 genutzt).
- **Review-Focus** vollständig in Task-Tests verankert (Pfad-Sonderfälle→T3, Lange Playlist→T5, Video-Aspekte/Audio-Idle/Toggle-Stresstest→T6, Multi-Monitor→T3).
