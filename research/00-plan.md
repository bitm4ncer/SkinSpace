# Projekt: Headspace (WMP) → VLC Skin Port — FINAL

Stand: 2026-10-13 · Branch `headspace-port` · Status: **Release v1.0**

## Was gebaut wurde
Der offizielle Microsoft-Skin „Headspace" (WMP, © 2000/2001) als natives VLC-3.0.x-Skin,
maximal originalgetreu (Original-Assets 1:1, keine Neuzeichnung):

- **4 Layouts** in einem Fenster: geschlossen (549×394) · EQ-Schublade · Playlist-Schublade · beide (760×394)
- **EQ-Drawer**: 10-Band-Equalizer (schreibt in VLCs EQ), Volume, Balance (optisch), „reset"=EQ an/aus,
  Rails+Kappen+Thumbs & Frequenz-Labels exakt nach Original-Referenzen
- **Playlist**: Playtree (einzeilig, „…"-Abschneidung, Scroll)
- **Screen**: eingebettetes Video (alle Layouts), Audio-Idle schwarz, `vid_bkgd`-Originalgrafik
- **Größenvarianten**: 1× / 2× / 3× (Nearest-Pixel-Look)

## Artefakte
- `dist/Headspace.vlt` · `dist/Headspace-2x.vlt` · `dist/Headspace-3x.vlt`
- `README.md` (Installation, Bedienung, Credits, Abweichungen)
- `research/final-verification/acceptance.md` (Endabnahme)
- Doku: `docs/superpowers/specs/…` (Spec), `docs/superpowers/plans/…` (Plan),
  `research/01–05` (Research/RE/Spike), `.superpowers/sdd/…/progress.md` (Ledger, alle Rulings)

## Wichtige Betriebsregeln (aus dem Tag gelernt)
1. **Crash-Dump-Falle**: Wenn VLC plötzlich nicht mehr startet → `%APPDATA%\vlc\crashdump` leeren.
2. **„Open skin…" meiden** (changeSkin crasht auf 3.0.23) → Neustart mit `--skins2-last`.
3. **Start-Process-Argumente mit Leerzeichen immer quoten** (Skripte).
4. Tests klickfrei per `skins2-config`-Layout-Preset; Klick-Tests nur nach Absprache mit dem Nutzer.
