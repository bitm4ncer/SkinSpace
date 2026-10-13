# Headspace → VLC Skin Port — Design-Spezifikation

Status: **Entwurf zur Review** · Datum: 2026-10-13 · Zielversion: VLC 3.0.x (getestet: 3.0.23, Windows)

## 1. Ziel & Erfolgskriterien

Der offizielle Microsoft-"Headspace"-Skin (WMP7, © 2000) wird als natives VLC-skins2-Skin (`.vlt`) neu aufgelegt — **maximal originalgetreu**:

- **Optik:** Original-Assets, dieselben Positionen (aus `headspace.wms`), dieselben Zustände; Auflösung 2× (keine Umgestaltung, nur Upscale + Farbkey→Alpha).
- **Funktion:** Alle Elemente, die VLC leisten kann, funktionieren 1:1 wie im Original (Transport, Seek, 10-Band-EQ + Enable, Volume, Playlist, Tooltips, Ziehen, Minimieren/Schließen). Die 4 technisch unmöglichen Elemente werden dokumentiert ersetzt oder entfernt — **keine toten Buttons**.
- **Abnahme:** Lädt in VLC 3.0.23 fehlerfrei; Sichtprüfung gegen die Zustandsrekonstruktionen (`research/previews/states/`); EQ/Volume/Seek schreiben in VLCs Config; Video wird eingebettet.

## 2. Nicht-Ziele

- Kein Bounty-Submission-Workflow (kein Demo-Video, keine Wettbewerbs-Optimierung).
- Kein Patch/Build von VLC selbst; keine QML-Alternative.
- Keine Ohr-Slide-Animation (skins2 hat keine Bewegungsanimationen) — instant Umschalten.
- Keine Visualisierungen im Screen (nur Qt-intern erreichbar; im Skin-Modus unmöglich).
- Kein macOS/Linux-Support-Versprechen (DTD-2.0-konform, dort ebenfalls lauffähig, aber ungetestet).

## 3. Ausgangsmaterial (alles vorhanden, bleibt unverändert als Quelle)

| Quelle | Pfad |
|---|---|
| Original-Skin (ZIP) + entpackt (82 Dateien) | `research/original/Headspace.wmz`, `research/original/extracted/` |
| Asset-Inventar / Control-Dump | `research/original/inventory.csv`, `controls.json` |
| RE-Dokumentation (Geometrie, Script, Assets) | `research/02-headspace-reverse-engineering.md` |
| VLC-Capability-Analyse (Code-belegt) | `research/01-vlc-skins2-research.md` |
| Konsolidiertes Feature-Mapping | `research/04-vlc-mapping-summary.md` |
| Spike-Verifikation (Layouts, Video, EQ, Popup, Tooltips) | `research/05-spike-results.md` |
| Zustandsrekonstruktionen (Referenzbilder) | `research/previews/states/state-{A-closed,B-eq-open,C-pl-open,D-vis-open}.png` |

## 4. Zielartefakte

```
dist/Headspace.vlt              ← das fertige Skin (ZIP mit theme.xml + Assets + Font)
src/theme/theme.xml             ← Skin-Definition (handgeschrieben, DTD 2.0)
src/theme/images/*.png          ← aufbereitete Assets (2×, PNG32)
src/theme/fonts/*               ← freie Schrift (metriknah zu Verdana für Kleinsttexte/Tooltips)
tools/                          ← Build-/Upscale-/Pack-Skripte (PowerShell)
README.md                       ← Installation, Bedienung, Credits, Abweichungen
docs/superpowers/specs/         ← dieses Dokument + späterer Implementierungsplan
```

Nutzung: Rechtsklick im Skin → *Open skin…* oder `-I skins --skins2-last=<pfad>` (kein Admin); alternativ Kopie nach `C:\Program Files\VideoLAN\VLC\skins\`.

## 5. Architektur

### 5.1 Fenster & Layouts (Plan A — ein Fenster, wie das Original)

Ein Fenster `main` (`position="Center"`), 4 Layouts (Maße = Original ×2). Umschalten per Buttons (`main.setLayout(...)`), instant:

| Layout-ID | Maße | Inhalt | Auslöser |
|---|---|---|---|
| `l_closed` | 1098×788 | Kopf (261,0 ×2), beide Ohren geschlossen (EQ-Ohr ragt mit Lautsprecher links heraus, PL-Ohr rechts) | Start / Close-Buttons der Schubladen |
| `l_eq` | 1098×788 | EQ-Schublade offen (x 0…538), PL-Ohr geschlossen | EQ-Handle (bEq) |
| `l_pl` | 1520×788 | PL-Schublade offen (x 554…1520), EQ-Ohr geschlossen | PL-Handle (bPl) |
| `l_both` | 1520×788 | Beide Schubladen offen | Öffnen des zweiten Ohrs aus einem Offen-Layout |

Jedes Layout enthält alle sichtbaren Controls vollständig (Duplikation; per Copy-Blöcke generiert). **Fallback Plan B** (getrennte Ohr-Fenster mit `show()/hide()`, im Spike verifiziert) bleibt Reserve, falls Layout-Switching im Vollausbau Probleme macht.

Offener Punkt (im Build klären): Welches Layout ist beim **allerersten** Start aktiv (Regel „zuletzt deklariertes Layout"?). Absicherung: Layout-Reihenfolge entsprechend setzen + Erststart-Test ohne `skins2-config`.

### 5.2 Control-Mapping (Detail: `research/04-vlc-mapping-summary.md`)

| Original | Umsetzung | Status |
|---|---|---|
| Minimize / Close | `vlc.minimize()` / `vlc.quit()` | 1:1 |
| Prev / Play / Stop / Next | `playlist.previous()`, `vlc.play()`, `vlc.stop()`, `playlist.next()` — Mapping-Bitmaps in Einzel-Buttons geschnitten (`SubBitmap`, up/over/down) | 1:1 |
| Pause (liegt exakt über Play) | eigener Button, `visible="vlc.isPlaying"`, `vlc.pause()` | 1:1 |
| Seekbar (progressbar.bmp + foreground) | `<Slider value="time">` + `SliderBackground` (Frames = Füllstand, generiert) + Original-Thumb; **Download-Progress-Ebene entfällt** | 1:1 minus Zweitebene |
| Kopf ziehen | `<Image action="move">` auf Kopf + Hintergrund | 1:1 |
| EQ: Balance-Slider | **Mute-Toggle** im selben Slot (Checkbox `state="vlc.isMute"` + `vlc.mute()`, kleiner LED-Stil) | Ersatz (abgesegnet) |
| EQ: Volume-Slider | `<Slider value="volume">` + Label „Volume" | 1:1 |
| EQ: 10 Bänder (eq1…eq10) | `<Slider value="equalizer.band(0…)…(9)">`, gleiche Optik/Raster wie Original | 1:1 |
| EQ: „reset"-Link | **EQ-An/Aus-Link** (Action + `equalizer.isEnabled`) am selben Platz | Ersatz (abgesegnet) |
| EQ/PL-Handles + Close-X | Buttons → `setLayout` | 1:1 |
| Playlist (Name/Time, flach) | `<Playtree flat="true">` + Pflicht-`<Slider>`-Kind; **Durationsspalte entfällt** (skins2-Limit) | 1:1 minus Spalte |
| Tooltips (alle) | `tooltiptext` mit Original-Wortlaut („Open playlist", „Seek", …) | 1:1 |
| „Return to Full Mode" | `dialogs.changeSkin()` (Skin-Auswahl = VLC-Äquivalent) | Ersatz (abgesegnet) |
| Viz-Auswahl (prev/next/close + Presettitel) | **entfällt ersatzlos** (Funktion existiert in VLC-Skins nicht) | entfernt (abgesegnet) |
| Screen | `<Video>` eingebettet, `visible="vlc.hasVout"`; darunter dunkle Idle-Grafik (Original: schwarz ohne Viz). Album-Cover optional als Experiment, Standard aus | funktional gleichwertig |
| Hidden-Tooltip-Hack (xEqTt…) | nicht nötig (dynamische `tooltiptext`-Funktion vorhanden) | — |
| Kein sichtbarer Zeit-Text | wird **nicht** ergänzt (Original hatte keinen) | 1:1 |

Keine „disabled"-Zustände (skins2 kennt nur up/over/down) — betroffene Buttons bleiben aktiv wie in VLC üblich. Tooltips übernehmen die Orientierung.

### 5.3 Zustandslogik

- Play/Pause exakt wie Original (Pause-Overlay über Play, `vlc.isPlaying`).
- Mute-Toggle: `vlc.isMute`; EQ-Link: `equalizer.isEnabled`; Seek: `vlc.isSeekable`-frei (wie Original immer bedienbar).
- Layout-Wechsel komplett über die 4 Buttons; kein versteckter Zustand.
- `skins2-config` (VLC) merkt Layout/Position/Sichtbarkeit über Sitzungen — erwünscht.

### 5.4 Screen-Konzept

- `<Video id="vid" …>` deckt den Magenta-Ausschnitt des Kopfes (Original-Koordinaten 9,59 + 216×158 → ×2: 18,118 + 432×316).
- Kein Vout → dunkle Idle-Fläche (Original-Look „aus").
- Video ⇄ Idle-Umschaltung automatisch via `visible="vlc.hasVout"` (im Spike verifiziert; Video liegt als Child-Fenster immer oben).

## 6. Asset-Pipeline

### 6.1 Aufbereitung
1. BMP → PNG32 (PowerShell/System.Drawing oder ImageMagick-frei).
2. Farbkeys → Alpha: Magenta `#FF00FF` (Transparenz) / Rot `#FF0000` (Clip-Bereich) / Weiß je Asset — **exakt nach `02-headspace-reverse-engineering.md` §2** (Farbkey-Analyse), Kanten entrauschen.
3. Buttons/Sheets: Klickzonen aus `*_map.bmp` bleiben als getrennte `SubBitmap`-Regionen erhalten (Koordinaten ×2).

### 6.2 Upscale (lokal, RTX 4070 vorhanden)
- Tool: **Real-ESRGAN-ncnn-vulkan** (portable, GitHub-Release; kein Install).
- Ablauf je Asset: 4× mit `realesrgan-x4plus` **und** `realesrgan-x4plus-anime` → auf Zielmaß 2× herunterskalieren (Lanczos) → Sichtvergleich, bessere Variante behalten.
- Kopf (`head.bmp`) + Ohren: Nachbearbeitung von Hand (Kanten/Artefakte), da organische Schattierung.
- Flache Flächen (`drawer_bkgrnd_*`, `vid_bkgd`, Track-Strips): **prozedural neu gezeichnet** in Original-Farben (kein Upscale nötig/gewünscht).
- fal.ai bleibt Option (API-Key nötig), falls lokal etwas unbefriedigend bleibt — Entscheidung nach Sichtprüfung.

### 6.3 Koordinaten
`theme.xml` verwendet durchgängig **Original-Koordinaten ×2** (Quelle: Tabellen in `02-…md`, `controls.json`). Kontrolle: Zustandsrekonstruktionen in Original-Größe liegen bereits vor → per Skript halbieren und gegen Screenshots legen.

## 7. Build & Test

### 7.1 Build
- `tools/pack.ps1`: sammelt `src/theme/` → ZIP → `dist/Headspace.vlt` (Determinismus: feste Dateireihenfolge).
- `tools/prepare_assets.ps1`: BMP→PNG, Farbkeys, Upscale, Track-Frames/SliderBackground-Strips.
- Laden ohne Admin: `-I skins --skins2-last=dist\Headspace.vlt` + `--file-logging -vvv`.

### 7.2 Testprotokoll (je Zustand Screenshot + Logcheck)
1. Erststart ohne `skins2-config` (Default-Layout?) → Log sauber (`kein "bad theme"`, keine „unknown action").
2. `l_closed`: Optik gegen `state-A` (halbierte Größe); Transport-Buttons; Tooltips; Ziehen (mit realer Maus bestätigen); Minimize/Close.
3. `l_eq`: Öffnen/Schließen; Mute-Toggle; Volume; alle 10 EQ-Slider → Werte in `vlcrc`; EQ-Link enable/disable.
4. `l_pl`: Öffnen/Schließen; Playlist befüllen (Datei-Drop funktioniert via `dragdrop`), Scroll-Slider, Auswahl/Doppelklick.
5. `l_both`: Kombination; Video läuft während Layout-Wechseln weiter.
6. Screen: Video-Datei → eingebettet; Stop → Idle; (optional Album-Cover-Test).
7. Rückbau/Fehlerfall: defektes Asset simulieren → VLC-Fallback `default.vlt` (kein Crash).

### 7.3 Abnahmekriterien (Checkliste)
- [ ] Lädt fehlerfrei mit `-vvv` (keine `bad theme`/`unknown`-Meldungen)
- [ ] Keine toten Controls; jede sichtbare Schaltfläche hat eine echte Funktion
- [ ] Optik deckt sich mit den Original-Rekonstruktionen (Position/Farbwelt/Zustände)
- [ ] EQ-Persistenz über Neustart; Seek springt; Playlist bedienbar; Video im Screen
- [ ] README mit Installation, Bedienung, Credits („Original skin © 2000 Microsoft"), Abweichungsliste

## 8. Risiken & offene Punkte

| Risiko | Umgang |
|---|---|
| Erststart-Default-Layout unklar | Reihenfolge + Test (§5.1) |
| Upscale-Qualität Kopf (organische Flächen) | 2 Modelle + Handretouch; fal.ai als Fallback |
| Playlist ohne Dauer-Spalte | bewusst akzeptiert (skins2-Limit), Tooltips/keine |
| „disabled"-Optik fehlt (skins2) | akzeptiert; Buttons bleiben aktiv |
| XML-Umfang (4 Layouts × ~40 Controls) | Copy-Blöcke + Konsistenz-Check per Skript (IDs eindeutig) |
| Album-Cover (`art="true"`) ungetestet | optionales Experiment, Block 6 des Testprotokolls |

## 9. Meilensteine

- **M1 — Asset-Pipeline:** Prototyp an `head.bmp` + einem Button + progressbar → Sichtreview (nimmt Upscale-Qualität ab).
- **M2 — Basis-Skin:** `l_closed` komplett (Kopf, Ohren geschlossen, Transport, Seek, Tooltips, Mute) → Testprotokoll 2.
- **M3 — EQ-Schublade:** `l_eq` + komplette EQ-Verdrahtung → Test 3.
- **M4 — Playlist-Schublade:** `l_pl` + Playlist-Scrolling → Test 4.
- **M5 — Kombination, Feinschliff, Verpackung:** `l_both`, Video, README, `dist/Headspace.vlt`, Endabnahme.

## Anhang

- Mapping-Details: `research/04-vlc-mapping-summary.md`
- Capability-Belege: `research/01-vlc-skins2-research.md` (Capability-Verdict-Tabelle §5)
- Spike-Nachweise: `research/05-spike-results.md` + Screenshots in `research/spike/`
