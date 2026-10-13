# Asset-/Upscale-Entscheidungen (Task 1) — FINAL

## Nutzer-Entscheidung (2026-10-13)

**Phase 1 wird mit den Original-Texturen 1:1 gebaut — kein Upscale.**
- Alle Assets gehen **unverändert** in den Skin (nur BMP→PNG32 + Farbkey→Alpha, exakte Pixel).
- Skin-Größe = Original (Fenster 549×394; alle Koordinaten aus `headspace.wms`, ×1).
- Begründung: maximal originalgetreu; der Pixel-Look des Originals ist gewünscht.
- **Tausch später möglich:** Die komplette Upscale-Maschinerie ist implementiert und dokumentiert;
  der `theme.xml`-Builder erhält einen `-Scale`-Parameter, Upstream-Rendersätze liegen in
  `research/upscale-review/renders/`. Eine 2×-Version ist damit ein Regenerationslauf, kein Umbau.

## Dokumentierte Optionen für eine spätere Upscale-Version (nicht aktiv)

| Klasse | Empfehlung | Belege |
|---|---|---|
| Kopf & Ohren | KI `realesrgan-x4plus-anime` + weiche Konturmaske v3 (glatt, AA) | `sheet_head_edge.png` |
| Thumb, Buttons, EQ-Icon, Drawer | `xBR 2×` (scharf + geglättete Diagonalen) | `sheet_thumb_decision.png`, `sheet_ui_decision.png` |
| Seekbar-Gradient | Lanczos | `compare_progressbar.png` |

## Technik-Referenz (Phase 1)

- **1:1-Konvertierung:** BMP→PNG32, dann exakte Key-Entfernung:
  - **Magenta `#FF00FF` → Alpha 0** in allen Assets, die Magenta enthalten (Automatik: Pixel-Messung).
  - **Rot `#FF0000` → Alpha 0 nur in `head.bmp`** (dort = außenliegende Clip-Fläche des Kopfes).
  - Keine Kantenglättung, keine Skalierung — exakt der Original-Pixelstand.
  - Assets ohne Keys (`play_controls`-Sheets, `EQ_*`, `PL_*`, `progressbar*`, `vid_bkgd`, `drawer_bkgrnd_*` …)
    bleiben opak wie im Original (`transparencyColor`-Angaben aus `headspace.wms` bestätigen das).
- Skript: `tools/make_original_assets.ps1` (folgt in Task 2) — nutzt `ConvertTo-Png32` + Key-Entfernung.
- Upstream (für später, bereits vorhanden): `tools/prepare_assets.ps1` (Modi `ai` / `lanczos`, Mask-Injection v3).

## Review-Historie (kurz)

1. v1 (KI-Upcaale + Farb-Erkennung): Kopf/Ohr — KI-Halluzinationen in Key-Flächen; Seekbar/Thumb — Rauschen.
2. v2: Deterministische binäre Maske aus Original — sauber, aber harte Treppenstufen (Nutzerfeedback).
3. v3: Bilineare weiche Maske — AA-Kontur (Nutzer: „pixelig“ behoben; Sheets aktuell).
4. **Final: Original 1:1** — Nutzerentscheidung für Phase 1.
