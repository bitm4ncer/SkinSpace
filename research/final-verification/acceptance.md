# Endabnahme — Headspace für VLC (Spec §7.3)

Stand: 2026-10-13 · Branch `headspace-port` · Testmethode: klickfreie Preset-Suiten + Pixel-Abgleich + Nutzer-Feedback

## Checkliste

| Kriterium | Status | Beleg |
|---|---|---|
| Lädt fehlerfrei mit `-vvv` (keine bad theme/unknown/non-unique) | ✅ | run_task3/4/5/6-Suiten, Logchecks PASS |
| Keine toten Controls | ✅ | Jede sichtbare Schaltfläche verdrahtet (Transport, Min/Close, EQ, Playlist, Seek, Theme→Preferences, Sun→Open Media, EQ-Slider→VLC-EQ, Playlist-Slider). Dokumentierte Sonderfälle: Balance rein optisch; „reset" = EQ an/aus; Cursor unveränderlich |
| Optik deckt sich mit dem Original | ✅ | Pixel-Sonden gegen Rekonstruktionen; EQ-Drawer gegen **echte WMP-Referenz-Screenshots** iteriert (Rails+Kappen+Thumbs, Frequenz-Labels, reset-Optik). Anm.: frühere Rekonstruktionen (state-B/C) enthielten einen Track-Fehler und wurden durch die Nutzer-Referenzen korrigiert |
| EQ-Persistenz über Neustart | ✅ | Drag schreibt `equalizer-bands` in vlcrc (Spike + Task-4-Test: Band0 → 12.8 dB) |
| Seekbar | ✅ | Slider-Mechanik in Spike + Nutzungskette verifiziert (gleiche Control-Klasse) |
| Playlist bedienbar; lange Titel/Scroll | ✅ | Stresstest: 16 Einträge inkl. >60-Zeichen-Titel → einzeilig mit „…"-Abschneidung, kein Überlauf |
| Video im Screen (alle 4 Layouts) | ✅ | t6_video_closed_169/43/port, t6_video_both — eingebettet, nichts scheint außerhalb durch |
| Audio ohne Video → Idle statt Rest | ✅ | t6_audio_idle (schwarzer Screen) |
| Fehlerfälle: kein Crash | ✅ | Defekt: sauberer Exit („no skins found"). Fehlend: Fallback default.vlt (500px) |
| README (Install, Credits, Abweichungen) | ✅ | `README.md` |
| Manuell (Nutzer): Ziehen am Kopf | ✅ | Nutzer bestätigt („ziehen klappt") |
| Manuell (Nutzer): Layout-Toggling-Stresstest am Live-Fenster | ⏳ | bewusst dem Nutzer überlassen (Klick-Protokoll) |

## Release

- Artefakte: `dist/Headspace.vlt`, `dist/Headspace-2x.vlt`, `dist/Headspace-3x.vlt`
- Commit/Tag: `release: Headspace.vlt 1.0` / Tag `v1.0`

## Offene Punkte / Grenzen

- Tooltips: Umgebungsabhängig (auf dieser Maschine phasenweise instabil; Skin-seitig korrekt konfiguriert, im Referenz-Screenshot des Nutzers nachweislich sichtbar).
- „Open skin…" (changeSkin) crasht auf VLC 3.0.23 (reproduziert, Build-Bug) — umgangen (Theme-Button→Preferences; README-Warnung).
