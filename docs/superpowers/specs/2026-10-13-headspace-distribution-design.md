# Headspace Distribution — Packs & Installer (Design)

**Datum:** 2026-10-13
**Status:** Entwurf zur Review
**Bezug:** ergänzt `docs/superpowers/specs/2026-10-13-headspace-vlc-skin-design.md` (der Skin selbst bleibt unverändert)

## 1. Ziel

Der VLC-Headspace-Skin existiert (`dist/Headspace.vlt` + Varianten). Neu kommt eine benutzerfreundliche **Distribution**:

- Das Repo bietet ein kuratiertes **Manifest** über alle verfügbaren alten WMP-Visualizer, den Original-Headspace-Skin und die Winamp-Klassiker.
- Ein Installer (`Headspace-Setup.exe`) installiert wählbar: **VLC-Erlebnis**, **WMP-Legacy-Original-Restore**, **Winamp-Pack**.
- Das **Winamp-Pack** hat zwei Schienen: Plugin-Pack (für vorhandenes Winamp/WACUP) und Standalone (`MilkDrop 3`, Butterchurn-Hinweis).

**Erfolgskriterium („so benutzerfreundlich wie möglich"):** Ein VLC-Nutzer lädt eine Datei, Doppelklick, zwei Klicks — VLC startet im Headspace-Skin mit laufenden Visuals, **ohne Admin**. Admin fällt nur an, wenn der WMP-Teil gewählt wird.

## 2. Entscheidungen (abgestimmt)

1. **Scope:** Ein Installer, drei wählbare Erlebnisse; Umsetzung gestaffelt.
2. **Priorität:** Feasibility-Spike „IWMPEffects-Host in VLC" zuerst (läuft separat, Ergebnis nur informativ für Phase 2 der Roadmap); Paket-Design/Umsetzung hängt nicht davon ab.
3. **Hosting:** **Runtime-Downloader + BYO-Fallback** — keine proprietären Binaries in Repo oder Release. Repo enthält nur eigenes Material, Manifeste, Hashes, Doku.
4. **Winamp-Pack:** Plugin-Track **und** Standalone-Track.
5. **Technik:** Ansatz A — Manifest + PowerShell-Engine + Inno-Setup-Installer; Engine zusätzlich als portables Skript.

**Faktenlage (recherchiert):** WMP-Visualizer sind 32-bit-COM-DLLs (`IWMPEffects`) und laufen ausschließlich in Windows Media Player (Legacy). VLC nutzt eigene Visualizer (projectM/MilkDrop-Presets, Goom, Spectrum/Scope/VU u. a.). Der Visualizer aus dem Headspace-Screenshot, **WhiteCap (SoundSpectrum)**, ist kommerziell und läuft seit Version 6.9.8 (Sept. 2026) nativ in VLC.

## 3. Repo-Layout

```
distribution/
  manifests/
    vlc-pack.json        # VLC-Erlebnis
    wmp-pack.json        # Original-Restore (Core/Extended/Info)
    winamp-pack.json     # Plugin- + Standalone-Track
    sources.json         # Mirror-/Fallback-Ketten je Item
  payload/               # NUR eigener Inhalt (kein Fremd-Binärmaterial)
    vlc/                 # Headspace*.vlt (Kopien der Build-Artefakte), Config-Templates
    wmp/                 # unsere Hilfsskripte, Fix-Anleitungen, Credits
    winamp/              # unsere Skripte, Preset-Listen, Doku
    docs/                # README-*.md, LICENSES.md, CREDITS.md
  engine/
    HeadspacePack.psm1   # Download-/Install-Engine
    Install-Headspace.ps1# CLI-Frontend (portabel nutzbar)
  installer/
    headspace-setup.iss  # Inno-Setup-Wizard
    assets/              # Icons, Banner, DE/EN-Strings
  tests/                 # Pester-Tests (Manifest-Validator, Engine, E2E)
```

## 4. Manifest-Format

Pro Item ein JSON-Objekt; das **Aktions-Vokabular ist fest verdrahtet** (`copy | extract | regsvr32 | write-config | run-payload-script | manual-note`), Manifeste können keinen freien Code ausführen.

Pflichtfelder: `id`, `name`, `category` (`vlc|wmp|winamp`), `sources[]` (geordnete URL-Kette), `sha256`, `size`, `archive` (`none|zip|7z`), `install.action`, `license.{status,redistribution}`, `default`, `notes`.
Optional: `requires[]` (`vlc>=3.0.24`, `winamp-or-wacup`, `wmp-legacy`, `windows`), `target` (Resolver-Name), `byo` (bool).

Beispiel:

```json
{
  "id": "wmp.alchemy",
  "name": "Alchemy",
  "category": "wmp",
  "requires": ["windows", "wmp-legacy"],
  "sources": [
    { "url": "https://drive.google.com/uc?export=download&id=<ID>" },
    { "url": "https://download.microsoft.com/<…>/wm9viz.exe" }
  ],
  "sha256": "<64 hex>",
  "size": 348160,
  "archive": "none",
  "install": { "action": "regsvr32", "target": "wmp-visualizations" },
  "license": { "status": "proprietary-abandonware", "redistribution": "downloader-only" },
  "default": true,
  "notes": "Microsoft; Core-Set."
}
```

`redistribution` unterscheidet: `allowed` (darf in `payload/` liegen), `downloader-only` (nur zur Laufzeit laden), `byo` (nur Anleitung + Picker).

## 5. Pack-Inhalte

### 5.1 VLC-Pack (vorausgewählt)

| Item | Quelle | Aktion |
|---|---|---|
| Headspace-Skin 1×/2×/3× | `payload/vlc/` (bestehende Pipeline) | kopieren nach `%LOCALAPPDATA%\HeadspacePack\skins\`, `skins2-last` in `vlcrc` setzen (mit Backup) |
| projectM-Preset-Pack (.milk) | kuratiert (projectM-/MilkDrop3-Repos); Lizenz je Pack entscheidet `payload/` vs. `downloader-only` | Presets nach `%LOCALAPPDATA%\HeadspacePack\presets\`, projectM-Preset-Pfad in `vlcrc` (opt-in) |
| VLC-Erkennung | Registry `HKLM\SOFTWARE\VideoLAN\VLC` | Warnung + Link bei fehlend/zu alt (< 3.0.24 wegen CVE-2026-102875 im skins2-Loader) |
| MilkDrop 3 portable (optional) | GitHub-Release | entpacken nach `%LOCALAPPDATA%\HeadspacePack\MilkDrop3` + Startmenü-Verknüpfung |
| WhiteCap (Info) | SoundSpectrum | nur Link/Erklärung (kommerziell; Original-Visual aus dem Screenshot; läuft in VLC) |

### 5.2 WMP-Pack (opt-in, Admin nur hier)

- **Original Headspace-Skin** (.wmz + Beta) aus den WMP-Goodies-Archiven; Zielpfad gemäß WMP-Goodies-Guide (bei Umsetzung verifizieren).
- **Core-Visualizer:** Alchemy, Battery, Bars and Waves, Plenoptic, Musical Colors, 3D Alchemy, WMP8-Legacy-Pack, Trilogy I–III, Blazing Colors, Color Cubes, Pulsing Colors, Picture Viz I/II, StarTime, SnowTime, Yule Log, WMP9-Visualizer → DLLs nach `…\Windows Media Player\Visualizations\`, `regsvr32`, Transition-Bug-Fix.
- **Extended-Visualizer:** Warner Bros (Grind, Terminator III, Looney Tunes), Dungeon Siege, projectMwmp u. a. — einzeln abwählbar, Status (`works|buggy|unknown`) im Manifest.
- **Info:** vizz.fm (Browser-Clone), WhiteCap.
- Quellen laufen über `sources.json`-Mirror-Ketten (WMP Goodies → Original-MS-Links → MediaFire); **BYO-Picker** springt ein, wenn alle Quellen tot sind.

### 5.3 Winamp-Pack (opt-in)

- **Plugin-Track** (nur wenn Winamp 5.x oder WACUP erkannt): MilkDrop 2 (gefixter Community-Build, nicht das buggy 2.25d aus Winamp 5.9x), AVS + Preset-Packs, Geiss → in den `Plugins`-Ordner des erkannten Players. Winamp/WACUP selbst wird **nicht** gebündelt (bei Fehlen: Info + Download-Links).
- **Standalone-Track** (immer möglich): MilkDrop 3 portable + Presets + Verknüpfung; Butterchurn als Browser-Info.

## 6. Engine

- **Erkennung:** VLC (Registry/Pfad), WMP Legacy (Installation + Feature-Status), Winamp/WACUP (Registry/Plugin-Ordner), `vlcrc`.
- **Pipeline pro Item:** `check → download (Mirror, 2 Retries) → SHA256 → extract → action → journal`.
- **BYO:** bei Download-Fehler Datei-/Ordner-Picker; akzeptiert nur Hash-Match; manuelle Anleitung als letzte Stufe.
- **Journal:** `%LOCALAPPDATA%\HeadspacePack\journal.json` — Basis für Uninstall/Repair/`-Resume`; „dirty"-Items werden beim nächsten Lauf repariert.
- **CLI:** `Install-Headspace.ps1 [-Packs vlc,wmp,winamp] [-DryRun] [-OfflinePath <dir>] [-Select id1,id2] [-Resume] [-LogDir <dir>]`.
- **`vlcrc`:** nur bekannte Keys ändern, Backup + Restore; `-DryRun` zeigt den Diff.

## 7. Installer (Inno Setup)

1. Welcome → **Optionen**: drei Sektionen (VLC ✅, WMP ⬜, Winamp ⬜) mit aufklappbaren Unteroptionen; Live-Erkennung + Versionswarnungen.
2. **Fortschritt pro Item** (Download % → Hash ✓ → entpacken → installieren); DE-UI, EN-Strings vorhanden.
3. **Abschluss**: „VLC mit Headspace starten", Log öffnen, Credits/Lizenzen. Offline-Modus `--offline <ordner>`; BYO-Dialog integriert.
4. **Uninstall**: Inno-Uninstaller + Engine-Journal; `vlcrc`-Restore aus Backup.
5. Stiller Modus für Tests: `/VERYSILENT /SUPPRESSMSGBOXES /LOG`.

## 8. Sicherheit

- SHA256-Pflicht; kein Item ohne Hash wird installiert.
- Keine Ausführung von Fremd-`exe`s; Archive werden entpackt, nie gestartet.
- Festes Aktions-Vokabular; `run-payload-script` nur aus `payload/` (repo-vertrauenswürdig).
- `regsvr32` nur für verifizierte, kuratierte DLLs; Registry-Aktionen journalisiert und beim Uninstall rückgängig.
- Defender-False-Positives bei Alt-DLLs: dokumentierter Hinweis, keine automatische Ausnahme.

## 9. Fehlerbehandlung & Resume

- Item-Fehler isoliert; Abschlussbericht „fertig / übersprungen / fehlgeschlagen + Grund".
- Abbruch jederzeit möglich; `-Resume` setzt fort, „dirty"-Items werden bereinigt.
- Fehlende Ziele (kein VLC/Winamp/WMP): klare Meldung + Link, kein Blind-Kopieren.
- Logs pro Lauf unter `%LOCALAPPDATA%\HeadspacePack\logs\`.

## 10. Tests

- **Manifest-Validator:** Schema, eindeutige IDs, Hash-Format, optional Online-Erreichbarkeit (Skip-Flag).
- **Engine-Unit-Tests (Pester):** Mock-HTTP-Download, Hash-Mismatch ⇒ fail, Mirror-Fallback, BYO-Match, Journal/Uninstall, `vlcrc`-Patch + Restore mit Fixture.
- **E2E:** `Install-Headspace.ps1 -Packs vlc -OfflinePath <cache>` auf sauberem System → VLC startet im Skin; Screenshot-Vergleich wie bestehender Skin-Testrunner (`tools/tests/` bleibt unangetastet).
- **Installer-Test:** Silent-Install/Uninstall + Log-Auswertung.
- Alle neuen Tests unter `distribution/tests/`.

## 11. Phasenplan

Geplant und umgesetzt wird phasenweise; **der erste Implementierungsplan umfasst Phase A** (weitere Phasen bekommen eigene Pläne).

| Phase | Inhalt | Fertig wenn |
|---|---|---|
| A | Manifest + Engine + VLC-Pack (nutzt vorhandene `.vlt`-Builds) | CLI installiert VLC-Pack end-to-end, Tests grün |
| B | WMP-Pack (Downloader, Core-Liste, regsvr32 + Fix, Admin-Flow) | Core-Items installieren auf Win10/11-Testmaschine, Uninstall sauber |
| C | Winamp-Pack (Plugin- + Standalone-Track) | beide Tracks getestet |
| D | Inno-Installer um die Engine | Wizard-Flow DE/EN, Silent-Test, Uninstall |
| E | Release (Root-README, Release-ZIP, Offline-Cache-Tool, Credits) | Release-ZIP enthält Setup + Cache-Tool + Doku |

Jede Phase endet mit Tests + Commit. Neue Items sind danach reine JSON-Änderungen.

## 12. Abgrenzung (YAGNI)

Kein Auto-Updater, kein Mehrsprachen-Framework (DE + EN Strings genügen), kein Code-Signing (SmartScreen-Hinweis in der Doku), kein Linux/macOS (Manifest-Feld `requires: windows`).

## 13. Verifikationsliste (vor/während Umsetzung zu klären)

- Exakte `vlcrc`-Keys (`skins2-last`, projectM-Preset-Pfad) und Neustart-Verhalten.
- WMP-Skin-Zielpfad + „Adding Skins to WMP 10"-Guide (WMP Goodies).
- Winamp/WACUP-Plugin-Ordner-Erkennung (Registry).
- Inno Setup auf Build-Rechner (winget/choco), Version pinnen.
- Exakte Quellen pinnen: MilkDrop2-Fixbuild, AVS, Geiss, MilkDrop 3, projectM-Presets (URL + SHA256).
- Lizenzstatus der Preset-Packs ⇒ `payload/` vs. `downloader-only`.
- WMP-Legacy-Verfügbarkeit auf Win11 (Media-Features) + Admin-Flow.

## 14. Referenzen

- WMP Goodies: 266 Skins, 62 Visualizer, Guides (REGSVR32, Transition-Bug-Fix, Skins) — `sites.google.com/view/wmpgoodies`
- `wmpvis.fandom.com` (Visualizer-Wiki + Community)
- `github.com/TRConGithub/projectMwmp` (projectM als WMP-Visualizer)
- SoundSpectrum WhiteCap (VLC-Support seit 6.9.8, 05.09.2026)
- CVE-2026-102875 (skins2 ThemeLoader; gefixt in VLC 3.0.24)
- MilkDrop 3 (`github.com/milkdrop2077/MilkDrop3`), AVS (`github.com/grandchild/vis_avs`), Geiss (`github.com/geissomatik/geiss`)
- Spike „IWMPEffects-Host" (separate Session) — Ergebnis wird nur als optionales experimentelles Item nachgeführt.
