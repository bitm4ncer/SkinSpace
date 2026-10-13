# Projekt: Headspace (WMP) → VLC Skin Port

Stand: 2026-10-13 (Spike abgeschlossen)

## Kontext
- Reddit-Bounty (r/VLC, u/jbyrdab): "$50 bounty - Recreate the 'headspace' windows media player skin in VLC"
- Original: offizieller Microsoft-WMP-Skin von 2000 („Headspace", WMP7-Ära, ©2000)
- Original gesichert: `research/original/Headspace.wmz` (ZIP, 82 Dateien) + entpackt: `research/original/extracted/`
- Zielmaschine: VLC 3.0.23 x64, 7-Zip, ffmpeg vorhanden
- **Nutzer-Entscheidung: maximale Originaltreue (kein Bounty-Fokus)**

## Phasen
- [x] Original-Assets beschafft + entpackt + vollständig RE'd
- [x] Deep Research: `01-vlc-skins2-research.md`, `02-headspace-reverse-engineering.md` (+inventory.csv/controls.json), `03-wmp-format-ecosystem.md`
- [x] Konsolidiertes Mapping: `04-vlc-mapping-summary.md`
- [x] Zustandsrekonstruktionen: `previews/states/state-{A,B,C,D}.png`
- [x] **Spike abgeschlossen:** `05-spike-results.md` — Layout-Switch ✅, Video-Einbettung ✅, EQ+Config-Write ✅, Seek ✅, Tooltips ✅, Pop-Fenster ✅, Viz ❌ (nicht erreichbar)
- [ ] Design-Dokument (Spec) schreiben → User-Review
- [ ] Implementierungsplan (writing-plans) → User-Review + Ausführungswahl
- [ ] Build:
  - [ ] Assets upscalen (2×?, Real-ESRGAN-ncnn / Alternative), Alpha aus Magenta, Retouch Kopf
  - [ ] `theme.xml` bauen (4 Layouts: closed/eq/pl/both; DTD 2.0)
  - [ ] Progressbar-Frames + Slider-Grafiken generieren
  - [ ] Test-Suite: alle Zustände laden, Interaktionen, Vergleich mit `previews/states/`
- [ ] Abschluss: Doku, Installationsanleitung, ggf. Bonus (About-Fenster mit Credits)

## Kern-Design-Entscheidungen (Arbeitsstand)
1. EIN Fenster + 4 Layouts (Plan A); Fallback: getrennte Ohr-Fenster (Plan B, verifiziert)
2. Screen: Video eingebettet + Idle-Grafik; Viz-Auswahl entfällt
3. Balance → funktionaler Ersatz (Mute-Toggle) oder entfernt [im Design final]
4. Reset-Link → EQ-Enable-Link
5. „Return to Full Mode" → `dialogs.changeSkin()` oder entfernt [im Design final]
6. Assets 2×-Upscale [im Design final]

## Bekannte Abweichungen (unvermeidbar)
- Ohr-Slide-Animation (keine Bewegungsanimation in skins2) — Bounty-Ausnahme genannt
- Visualisierungen + Viz-Menü (nicht skin-steuerbar)
- Download-Progress-Doppelanzeige im Seekbar (kein Sekundärfortschritt)
- Playlist ohne Spalten/Dropdown (skins2-Limit)
- Kein weiches Fenster-Alpha gegen Desktop (nur binäre Form; `skins2-transparency`-Option gäbe Ganzfenster-Alpha)
