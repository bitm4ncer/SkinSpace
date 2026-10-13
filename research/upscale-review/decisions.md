# Upscale-Entscheidungen (Task-1-Review) — Stand 2026-10-13

## Verfahren (implementiert in `tools/prepare_assets.ps1` v2)

1. **Farbkey → Alpha: deterministische Maske aus dem Original** (2×, Erosion 1 px, weiche 2-Ring-Kante 150/225).
   Grund: Der erste Durchlauf zeigte, dass die KI-Modelle in flachen Key-Flächen **halluzinieren**
   (schwarze Flecken im Screen-Loch, rotes Gekrissel am Rand) und Key-Farben verfärben →
   Farb-Erkennung im KI-Ergebnis ist unzuverlässig. Die Maske erzwingt die Original-Silhouette.
2. **KI-Assets** (Kopf, Ohren, Buttons, EQ-Icon, Drawer-Handle): Real-ESRGAN 4× → Downscale 2× → Maske.
3. **Flache Geometrie** (`progressbar`, `progressbar_foreground`, `thumb_01_default`): **kein KI-Einsatz** —
   HighQualityBicubic 2× → Maske. (KI erzeugte bei diesen dünnen/flachen Grafiken reines Rauschen.)
4. Buttons ohne Key (`play_controls`, `EQ_01_DF`): Hintergrund ist im Original absichtlich die Kopffarbe
   (opak) — bleibt 1:1 erhalten, keine Maske nötig.

## Modellwahl — Empfehlung

| Asset-Klasse | Empfehlung | Begründung (aus Vergleichsblättern) |
|---|---|---|
| Kopf, Ohren | **realesrgan-x4plus-anime** | sauberere Kanten, weniger „erfundene" Mikro-Textur als x4plus — wirkt originaltreuer |
| Buttons, EQ-Icon, Drawer-Handles | **anime** | schärfere Kanten bei flachem/vektor-artigem Material |
| progressbar / thumb | Lanczos (kein Modell) | KI unbrauchbar (Rauschen) |

Alternative: `x4plus` nur für den Kopf, falls dir dessen etwas kräftigere Gesichts-Textur besser gefällt
(Spalte 2 der Vergleichsblätter).

## Offene Nutzer-Freigabe

- [ ] Vergleichsblätter gesichtet (`overview.png`, `compare_*.png` in `research/upscale-review/`)
- [ ] Modellwahl bestätigt oder geändert

## Beobachtete Grenzen

- Silhouette wird durch die Maske um ~1 Original-Pixel erodiert (Schutz vor Farbfringes) — optisch unauffällig.
- `thumb_01_default` (Original nur 18×9 px) bleibt auch bei 2× klein/weich — als Slider-Cursor unkritisch.
- Nach Freigabe läuft Task 2: alle ~80 Assets nach diesen Regeln, plus prozedurale Flächen (Drawer-Hintergründe, SliderBackground-Frames).
