# RESUME — SkinSpace (Stand: 2026-10-13, Abend)

**Projekt:** Multi-Skin-Repo „SkinSpace" — WMP-Klassiker als VLC-Skins (skins2).
Erstes Skin: **Headspace** (Microsoft © 2000/2001) — fertig (v1.0 + Nachbesserungen).

## Aktueller Stand
- Alle 7 Plan-Tasks abgeschlossen; dazu die Nachbesserungen der letzten Runden:
  EQ-Debug (Starter-Bat mit EQ aktiv) · Preamp statt Balance · Playlist-Optik (Checkboxen,
  Scrollbar mit Pfeilen/Thumb, Live-Laufzeit `$t / $d`) · Idle-Screen pures Schwarz ·
  Video/Visualizer füllen das Screen-Loch · Visualizer via `--audio-visual=goom|projectm`.
- **Multi-Skin-Struktur:** `skins/<name>/{theme,variants,originals,Start-*.bat}`;
  `tools/` = gemeinsame Kette (alle Tools mit `-Skin <name>`, Default `headspace`).
- Ledger (alle Rulings): `.superpowers/sdd/2026-10-13-headspace-vlc-skin-plan/progress.md`
- Plan/Specs: `docs/superpowers/…` · Nutzer-Doku: `README.md`

## Betriebsregeln (wichtig)
1. **Crashdump-Falle:** Wenn VLC plötzlich nicht mehr startet → Ordner
   `%APPDATA%\vlc\crashdump` leeren (liegengebliebener Dump blockiert jeden Start).
2. **„Open skin…" meiden** (`dialogs.changeSkin()` crasht auf VLC 3.0.23 reproduzierbar) →
   Neustart über die Starter-Bats bzw. `--skins2-last`.
3. **Start-Process-Argumente mit Leerzeichen immer quoten** (Fehlersuche sonst evtl. Scheinbefunde).
4. Tests klickfrei per `skins2-config`-Layout-Preset; Klick-Tests nur nach Absprache.
5. Native Pipelines mit frühem Abbruch (`Select-Object -First`) killen Prozesse →
   Ausgabe erst in eine Variable sammeln, dann filtern.

## Offene Punkte
- **Upscale** (Real-ESRGAN): swap-ready, nicht aktiv — Gate liegt in Plan-Task 1.
- **Layout-Toggle-Klicktest** am Live-Fenster (bewusst beim Nutzer).
- **Distribution Phase A** (Manifest+Engine+VLC-Pack) und **Bitmancer Visualizer Pack**:
  eigene Docs unter `docs/` (eigener Strang).
