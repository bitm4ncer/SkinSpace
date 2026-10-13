# Spike-Ergebnisse — Machbarkeits-Verifikation für den Headspace-Port

Datum: 2026-10-13 · Artefakt: `probe.vlt` (Wegwerf-Testskin, `research/spike/pack/`) · Getestet mit VLC 3.0.23 (Windows)

## Probe-Aufbau
Ein Fenster mit 2 Layouts (l1 400×300 / l2 700×300, alle Controls dupliziert), separatem Pop-Fenster (`pop.show/hide` via Checkbox), EQ-Slider (`equalizer.band(0)`) + Enable-Checkbox, Seek-Slider (`value="time"`), `<Video>` (`visible="vlc.hasVout"`), Z-Order-Overlap Image/Video (in l1/l2 jeweils anders geordnet), Tooltips, dynamische Texte (`$T/$D/$V`), `action="move"`-Hintergrund. Geladen als ZIP-`.vlt` über `-I skins --skins2-last=…` — **ohne Admin**.

## Ergebnisse

### 1. Laden & Format — ✅
- Handgeschriebene `theme.xml` mit `<!DOCTYPE Theme PUBLIC "-//VideoLAN//DTD VLC Skins V2.0//EN" "skin.dtd">` + `version="2.0"` lädt fehlerfrei (Log: nur ein irrelevanter Hinweis auf fehlende optionale `FreeSans.ttf` in `%APPDATA%\vlc\skins\fonts`).
- `.vlt` als ZIP ok; Assets werden nach `%TEMP%\vlt2\` extrahiert. Kein `bad theme`, keine „unknown action“, keine DTD-Fehler.
- `alphacolor` (Pflichtattribut je `<Bitmap>`) mit ungenutzter Farbe + echtes PNG-Alpha → funktioniert (irreguläre Form sichtbar, Ecke transparent).

### 2. Layout-Switch & Fenster — ✅ (offene Kleinigkeit)
- `main.setLayout(l2/l1)` per Button: **instant**, Fenstergröße wechselt exakt (400↔700, Position bleibt).
- **Persistenz entdeckt:** `skins2-config` in `vlcrc` speichert je Fenster: aktives Layout, Position, Größe, Sichtbarkeit — `["main" "l1" 500 300 400 300 1]`, wird beim Start exakt wiederhergestellt (auch als Test-Trick nutzbar, um das Fenster deterministisch zu platzieren).
- Video überlebt den Layout-Switch während der Wiedergabe (Log: `Active Layout changed (0)/(1)`, Bild läuft weiter).
- **[OFFEN]** Default-Layout beim *allerersten* Start (ohne gespeicherte Config): beobachtet wurde das **zuletzt deklarierte** Layout (l2). Regel im Build absichern (Reihenfolge der Layouts festlegen + Erststart-Test).
- Nebenbei: `Theme magnet=15`-Fenster-Dragging lief mit synthetischer Maus in einen Overshoot (Automatisierungs-Artefakt durch Event-Koaleszenz, siehe unten); Mechanik vorhanden, reale Maus unkritisch (Nutzer hat das Fenster während des Spikes real verschoben).

### 3. Video-Einbettung — ✅✅
- Testvideo (ffmpeg `testsrc2`, 640×360) wird **in das `<Video>`-Control eingebettet**: Log `setSize (640x360) received from vout thread`, `VideoCtrl … control visibility changed (1)`, kein separates Fenster.
- `visible="vlc.hasVout"` schaltet das Control automatisch (versteckt bei Stop/kein Vout).
- Screenshots `t8a_video_l1.png` (400er Fenster, Video im Screen) und `t8b_video_l2.png` (nach Layout-Switch, Video läuft weiter).

### 4. Visualisierungen — ❌ (definitiv nicht erreichbar)
- Keine CLI-Option (`--longhelp` ohne Treffer), `visual=goom` in `vlcrc` wird ignoriert, kein „visual“-Audiofilter-Plugin vorhanden; nur das Qt-Menü kann sie aktivieren (im Skin-Modus ist kein Qt-Menü erreichbar).
- → **Screen-Konzept:** eingebettetes Video + Idle-Grafik; die Viz-Auswahl (prev/next/close) entfällt (von der Bounty als „screen adjustment“/„removing buttons that no longer have a use“ gedeckt). Optional im Build: Album-Cover (`art="true"`) für Audio testen.
- Screenshot `t9b_viz_attempt.png` (Audio läuft, Screen bleibt ohne Viz).

### 5. Z-Order Image vs. Video — ✅
- Das `<Video>`-Control ist ein echtes Child-HWND und liegt **immer über** GDI-Inhalten derselben Fläche (in beiden XML-Reihenfolgen getestet).
- Heißt: Idle-Grafik (oder Album-Cover) einfach unter das Video legen — bei `visible="vlc.hasVout"`-Video unsichtbar, sonst sichtbar. Sauberes Umschalten Bild⇄Video wie im Original.

### 6. Equalizer & Interaktion — ✅✅✅
- **EQ-Slider-Drag schreibt die Config:** nach Drag stand in `vlcrc` `equalizer-bands=20.0 0.0 …` (Band 0 = Maximum). Beim Neustart laden die Slider die gespeicherten Werte (Persistenz wie im Original).
- Enable-Checkbox (`state="equalizer.isEnabled"` + `enable()/disable()`) funktioniert (LED wechselt).
- `SliderBackground`-Frames reagieren auf den Wert (Track-Anzeige wechselt) → Seekbar-Füllung darstellbar.
- **Tooltips** erscheinen (eigenes Fenster, 59×21, am Cursor) — inkl. dynamischer `$`-Variablen.
- **Dynamische Texte** live: `0:00:01 / 0:00:15  Vol: 90%`.
- **Seek via Klick/Drag** funktioniert (Sprung 0:02 → 0:13 bei 15-s-Video; Thumb + Zeit aktualisieren; Screenshot `t9a_seek_after.png`).
- **Checkbox → Fenster:** `state="pop.isVisible"` + `pop.show()/hide()` — Pop-Fenster erschien exakt bei konfigurierter Position (600,140, 160×80) und ließ sich per eigenem Close-Button wieder verstecken. (Damit ist auch der Fallback Plan B „getrennte Ohr-Fenster“ voll verifiziert.)

## Automatisierungs-Artefakte (Testharness, keine Skin-Probleme)
- Synthetische Drags über schnelle Cursor-Teleports können in skins2 Overshoot produzieren (mehrfach angewandte Deltas durch koaleszierte WM_MOUSEMOVE). **Mit realer Maus irrelevant** (übliche Nutzung).
- Klicks auf Buttons/Checkboxen/Slider sind zuverlässig, **wenn** das Fenster vorher per `SwitchToThisWindow` in den Vordergrund geholt wird (sonst gehen Klicks an das darunterliegende Fenster).

## Konsequenzen fürs Design
1. **Plan A bestätigt:** EIN Fenster `main` mit 4 Layouts — `l.closed` (549×394), `l.eq` (549), `l.pl` (760), `l.both` (760); Umschalten per Buttons (`setLayout`) = instant (Slide-Animation bleibt unmöglich; Bounty-Ausnahme greift wortwörtlich).
2. **Fallback Plan B verfügbar:** getrennte `eqwin`/`plwin`-Fenster (Muster aus `default.vlt` + Pop-Test) — falls Layout-Switching im Vollausbau Probleme macht.
3. **Screen:** `<Video>` (eingebettet) + Idle-Bitmap darunter; Viz-Auswahl streichen; Album-Cover optional testen.
4. **Kein VLC Skin Editor nötig** — handgeschriebene `theme.xml` (DTD 2.0) funktioniert einwandfrei; Build per ZIP→`.vlt`.
5. **Testing ohne Admin:** `-I skins --skins2-last=<pfad>`; Fensterposition/-layout per `skins2-config` steuerbar; Fehlersuche mit `-vvv`.
6. **Config-Hygiene:** Skin-Tests verändern `vlcrc` (EQ-Werte, skins2-last/-config) — Backup/Restore-Praxis wie in diesem Spike beibehalten.

## Restrisiken (im Build adressieren)
- Erststart-Default-Layout (Reihenfolge-Regel verifizieren).
- Album-Cover (`art="true"`) in skins2 3.0 — ungetestet.
- Slide-Animation der Ohren: prinzipbedingt nicht möglich (keine Bewegungsanimation in skins2).
- Synthetischer Overshoot vs. reale Maus: einmal manuell bestätigen.

## Artefakt-Dateien (alle unter `research/spike/`)
- `pack/` (Assets + `theme.xml`), `probe.vlt` (25 KiB)
- Screenshots: `t1b_loaded_again.png`, `t2c_after_click.png`, `t4b_after_popclick.png`, `t8a_video_l1.png`, `t8b_video_l2.png`, `t9a_seek_before/after.png`, `t9b_viz_attempt.png`
- Logs: `vlc_t1.log`, `vlc_t2.log`, `vlc_t3.log`, `vlc_t4.log`
- `winhelp.ps1` (Screenshot/Klick-Helfer für weitere Tests), `make_assets.ps1`
- `vlcrc.backup` (User-Config; wiederhergestellt & verifiziert)
