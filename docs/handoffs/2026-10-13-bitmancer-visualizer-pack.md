# Handoff — „Bitmancer Visualizer Pack" (eigene Retro- & Modern-Visualizer)

| | |
|---|---|
| **An** | neuen Agenten (eigene Session, eigenes Branch) |
| **Von** | Headspace-Distribution-Agent |
| **Datum** | 2026-10-13 |
| **Auftrag** | Baue ein vollständig **eigenes** Visualizer-Pack („Bitmancer"): **Retro-Visualizer** (WMP/`IWMPEffects`-Klasse) **und Modern-Visualizer** (MilkDrop-`.milk`-Presets für VLC/projectM), markenkonform designt, getestet und so abgelegt, dass es als viertes Pack in den Headspace-Installer integriert ist. |

## Kontext

- **Repo:** `C:\GitHub\VLC_Skins`. Branch-Vorschlag: `bitmancer-pack`. Nicht `src/theme/**` anfassen (dort arbeitet der Skin-Agent).
- **Distribution-Spec (dein Platz):** `docs/superpowers/specs/2026-10-13-headspace-distribution-design.md` — §5.4 = Bitmancer-Pack, §4 = Manifest-Format, §8 = Sicherheit, §11 = Phasen.
- **Spike-Referenz (Retro-Vizzes hosten, verifiziert):** `research/spike-wmpviz/README.md` — enthält IIDs, Vtable, `TimedLevel`-Layout und das Rezept, eine x86-`IWMPEffects`-DLL **registration-frei** zu laden und zu rendern. Testhost-Quellcode: `research/spike-wmpviz/WmpHost.cs` (Throwaway, als Basis).
- **Wichtig, rechtlich:** Alles, was du baust, ist **100 % original** — keine kopierten Assets, Presets, Grafiken oder Code aus fremden Visualizern. „Inspiration" ja, „Kopie" nein. Dein Inhalt wird unter einer freien Lizenz mit **erlaubter Weitergabe** veröffentlicht (Vorschlag MIT — mit dem Nutzer bestätigen), damit das Pack direkt im Installer-Payload liegen darf.

## Deliverables

1. **Retro-Track — ≥ 3 (Ziel 5) eigene `IWMPEffects`-DLLs (32-bit/x86)**
   - Stil-Ideen (Klassiker-Hommage mit eigener Optik): Spektrum-/VU-Bars, Oszilloskop-Scope, Partikel-/Orbit-Feld, Kaleidoskop-Linien, Wireframe-Gitter (nur wenn ohne D3D-Zwang sauber machbar).
   - Pflicht: COM in-proc (`DllGetClassObject`/`DllRegisterServer`), `IWMPEffects` vollständig, `IWMPEffects2` optional; **GDI-Rendering in einen fremden HDC**, kein eigenes Fenster im Standardpfad; `GetTitle`, ≥ 1 Preset, korrekt gefülltes `TimedLevel` (Layout siehe Spike-README).
   - Deterministischer Build (CMake oder VS-Projekt + `build.ps1`); Artefakte → `distribution/payload/bitmancer/retro/`.
   - Test: Skript unter `bitmancer/tests/`, das jede DLL registration-frei lädt, 120 Frames rendert und non-black + Frame-Motion prüft (Spike-Host als Basis). **Die DLLs selbst gehören ins Payload, nicht in die Testdaten.**
2. **Modern-Track — ≥ 5 `.milk`-Presets (MilkDrop-Format) → `distribution/payload/bitmancer/presets/`**
   - Pflicht: laufen in projectM (VLC 3.0.x) **und** MilkDrop 3; keine externen Assets; slideshow-tauglich; Header mit Autor/Version (`// …`).
   - Test: VLC-Ladelauf pro Preset mit sauberem Log + Sichtprobe; optional MilkDrop3-Gegenprobe.
3. **Manifest-Fragment** `distribution/payload/bitmancer/manifest-fragment.json`
   - Items `bitmancer.*`, Kategorien `vlc` (Presets) und `wmp` (DLLs), `redistribution: allowed`, `default: true`, `install.action` gemäß Schema, **inklusive CLSIDs** der Retro-DLLs (für den experimentellen Host aus Phase F).
4. **Doku & Lizenz:** `distribution/payload/bitmancer/README.md`, `CREDITS.md`, `LICENSE`.
5. **Visuelle Identität:** wiedererkennbares „Bitmancer"-Design (Retro-Pixel/Neon-Synthwave), alle Items eine erkennbare Family; Farbwelt so, dass sie neben dem grünen Headspace-Skin funktioniert.

## Integration (bereits eingeplant, nichts doppelt bauen)

- Der Installer bekommt laut Spec §5.4 einen eigenen Abschnitt **„Bitmancer-Pack" (default an)**. Eigene Binaries/Presets liegen direkt in `payload/` — kein Downloader nötig.
- Abnahme: `Install-Headspace.ps1 -Select bitmancer*` funktioniert nach Integration; Manifest-Validator + Uninstall-Test sind Teil deiner Abnahme.

## Arbeitsweise

- Eigener Branch, pro Deliverable Tests + Commit. Wenn du die superpowers-Skills nutzt: dieses Dokument ist das Briefing — für die Umsetzung wie gewohnt (brainstorming → writing-plans) vorgehen.
- Recherche-/Stilquellen (nur anschauen, nicht kopieren): WMP Goodies (Visualizer-Sammlung), `wmpvis.fandom.com`, `github.com/TRConGithub/projectMwmp`, MilkDrop-3-Repo (Preset-Beispiele), geisswerks.com (Preset-Authoring-Referenzen).

## Abnahmekriterien

- [ ] Alle Retro-DLLs: registration-freier Lade-+Render-Test grün (120 Frames, Motion nachgewiesen); in WMP Legacy nach `regsvr32` sichtbar (Sichtprobe).
- [ ] Alle Presets: VLC/projectM-Ladelauf ohne Fehler im Log; Sichtproben vorhanden.
- [ ] Manifest-Fragment validiert (Schema/Hashes/IDs) und vom Installer-Konzept konsumierbar.
- [ ] 100 % Original-Inhalt, Lizenzen sauber (Weitergabe erlaubt), Credits gepflegt.
- [ ] `distribution/payload/bitmancer/` enthält keine Fremd-Binaries.

## Offene Punkte (mit Nutzer klären)

- Lizenzwahl (Vorschlag: MIT) und ob der Name „Bitmancer" endgültig ist.
- Zielanzahl/Schwierigkeitsgrad der Visualizer; ob eine D3D-basierte Optik schon in v1 nötig ist (Empfehlung: nein, GDI zuerst).
- Sprache der UI-/Preset-Titel (deutsch oder englisch).
