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
2. **Priorität:** Feasibility-Spike „IWMPEffects-Host in VLC" zuerst — **abgeschlossen mit Verdict GO** (3/3 getestete GDI-Vizzes laden registration-frei und rendern). Der Host wird als optionale, experimentelle Phase F geführt; Paket-Design/-Umsetzung hängt nicht davon ab.
3. **Hosting:** **Runtime-Downloader + BYO-Fallback** — keine proprietären Binaries in Repo oder Release. Repo enthält nur eigenes Material, Manifeste, Hashes, Doku.
4. **Winamp-Pack:** Plugin-Track **und** Standalone-Track.
5. **Technik:** Ansatz A — Manifest + PowerShell-Engine + Inno-Setup-Installer; Engine zusätzlich als portables Skript.
6. **Zusatz-Pack:** „Bitmancer" — eigene Retro- und Modern-Visualizer eines separaten Agenten, 100 % Original-Inhalt (`redistribution: allowed`) — wird als viertes, vorausgewähltes Pack in den Installer eingeplant (§5.4).

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

Pro Item ein JSON-Objekt; das **Aktions-Vokabular ist fest verdrahtet** (`copy | write-config | regsvr32 | run-payload-script | manual-note`; Downloads landen als `%ARTIFACT%`, entpackte Archive als `%WORK%`), Manifeste können keinen freien Code ausführen. Werte dürfen Tokens enthalten: `%REPO%` `%TARGET%` `%WORK%` `%ARTIFACT%` `%APPDATA%` `%LOCALAPPDATA%` `%VLC_INSTALL_DIR%` `%WMP_VIS_DIR%`.

Pflichtfelder: `id`, `name`, `category` (`vlc|wmp|winamp|bitmancer`), `install.steps[]` (≥ 1 Aktion), `license.{status,redistribution}` (`redistribution` ∈ `repo-asset|allowed|downloader-only|byo`), `default`, `notes`.
Pflicht bei Downloads: `sources[]` (geordnete URL-Kette, nur `https`) + `sha256`; **repo-lokale** Dateien (Build-Artefakte) benötigen keinen Hash.
Optional: `size`, `archive` (`none|zip|7z`, Default `none`), `requires[]` (z. B. `vlc-present`, `vlc>=3.0.24`, `winamp-or-wacup`, `wmp-legacy`, `windows`), `byo` (bool).
Schritt-Formate: `{ action:"copy", from, to }` · `{ action:"write-config", file:"vlcrc", section, key, value }` · `{ action:"regsvr32", from }` · `{ action:"manual-note", text }`.

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
  "install": { "steps": [ { "action": "copy", "from": "%ARTIFACT%", "to": "%WMP_VIS_DIR%/alchemy.dll" } ] },
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
- **Experimentell (nur mit vom Nutzer bereitgestellten DLLs):** eigener WMP-Viz-Host in VLC. Spike-Verdikt **GO** für GDI-Vizzes (`vizhost32.exe` als x86-Helper, registration-freies `DllGetClassObject`, Shared-Memory-Frame-Transport, gespeistes `TimedLevel`). D3D-Ära-Vizzes (Battery & Co.) offen → zweiter Spike. DLLs werden **nie** mitgeliefert.
- Quellen laufen über `sources.json`-Mirror-Ketten (WMP Goodies → Original-MS-Links → MediaFire); **BYO-Picker** springt ein, wenn alle Quellen tot sind.

### 5.3 Winamp-Pack (opt-in)

- **Plugin-Track** (nur wenn Winamp 5.x oder WACUP erkannt): MilkDrop 2 (gefixter Community-Build, nicht das buggy 2.25d aus Winamp 5.9x), AVS + Preset-Packs, Geiss → in den `Plugins`-Ordner des erkannten Players. Winamp/WACUP selbst wird **nicht** gebündelt (bei Fehlen: Info + Download-Links).
- **Standalone-Track** (immer möglich): MilkDrop 3 portable + Presets + Verknüpfung; Butterchurn als Browser-Info.

### 5.4 Bitmancer-Pack (eigene Visualizer, vorausgewählt ✅)

- **Eigenproduktion** eines separaten Agenten: eigene Retro- und Modern-Visualizer, 100 % eigener Code/Content → `redistribution: allowed`, darf in `payload/` liegen (kein Downloader nötig).
- **Retro-Track:** neue `IWMPEffects`-DLLs im Stil der Klassiker (GDI-basiert; im WMP-Pack via `regsvr32` installierbar und im experimentellen Host aus §5.2 nutzbar) → `payload/bitmancer/retro/`.
- **Modern-Track:** neue `.milk`-Presets (MilkDrop-/projectM-Format) im Bitmancer-Look für VLC → `payload/bitmancer/presets/`.
- **Manifest:** Items mit Prefix `bitmancer.` in den VLC-/WMP-Manifesten (inkl. CLSIDs für Phase F); eigener Abschnitt im Installer, **default an**.
- **Handoff:** `docs/handoffs/2026-10-13-bitmancer-visualizer-pack.md`.

## 6. Engine

- **Erkennung:** VLC (Registry/Pfad), WMP Legacy (Installation + Feature-Status), Winamp/WACUP (Registry/Plugin-Ordner), `vlcrc`.
- **Pipeline pro Item:** `check → download (Mirror, 2 Retries) → SHA256 → extract → action → journal`.
- **BYO:** bei Download-Fehler Datei-/Ordner-Picker; akzeptiert nur Hash-Match; manuelle Anleitung als letzte Stufe.
- **Journal:** `%LOCALAPPDATA%\HeadspacePack\journal.json` — Basis für Uninstall/Repair/`-Resume`; „dirty"-Items werden beim nächsten Lauf repariert.
- **CLI:** `Install-Headspace.ps1 [-Packs vlc,wmp,winamp] [-DryRun] [-OfflinePath <dir>] [-Select id1,id2] [-Resume] [-LogDir <dir>]`.
- **`vlcrc`:** nur bekannte Keys ändern, Backup + Restore; `-DryRun` zeigt den Diff.

## 7. Installer (Inno Setup)

1. Welcome → **Optionen**: drei Sektionen (VLC ✅, WMP ⬜, Winamp ⬜) mit aufklappbaren Unteroptionen; Live-Erkennung + Versionswarnungen.
2. **Fortschritt pro Item** (Download % → Hash ✓ → entpacken → installieren); EN-UI, DE-Strings vorhanden.
3. **Abschluss**: „VLC mit Headspace starten", Log öffnen, Credits/Lizenzen. Offline-Modus `--offline <ordner>`; BYO-Dialog integriert.
4. **Uninstall**: Inno-Uninstaller + Engine-Journal; `vlcrc`-Restore aus Backup.
5. Stiller Modus für Tests: `/VERYSILENT /SUPPRESSMSGBOXES /LOG`.

## 8. Sicherheit

- SHA256-Pflicht für alle **Downloads**; repo-lokale Dateien (Build-Artefakte aus `dist/`) werden ohne Hash kopiert — der Validator unterscheidet beide Fälle.
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
- **Engine-Unit-Tests (Repo-Konvention: eigenständige PS-Skripte mit `OK:`/`FAIL:` + Exit-Code; Pester 5 ist nicht verfügbar, Pester 3.4.0 wird nicht genutzt):** Mock-HTTP-Download, Hash-Mismatch ⇒ fail, Mirror-Fallback, BYO-Match, Journal/Uninstall, `vlcrc`-Patch + Restore mit Fixture.
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
| P (parallel, separater Agent) | Bitmancer-Pack (eigene Retro- + Modern-Visualizer), Handoff `docs/handoffs/2026-10-13-bitmancer-visualizer-pack.md` | Items in Manifest + Installer wählbar; `redistribution: allowed` |
| F (optional, eigener Spec-/Plan-Zyklus) | Experimenteller WMP-Viz-Host in VLC (`vizhost32.exe` + IPC) | opt-in läuft; Zusicherung nur für GDI-Vizzes, D3D-Ära per zweitem Spike geklärt |

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
- Spike „IWMPEffects-Host" (**abgeschlossen: Verdict GO**): 3/3 GDI-Vizzes rendern registration-frei in einen Memory-DC (120/120 Frames, kein eigenes Fenster); verifizierte Referenz (IIDs, Vtable, `TimedLevel` x86 = 4112 Bytes) im Spike-Report; D3D-/DirectDraw-Vizzes = offener zweiter Spike. Aufwand für Phase F: ca. 1–2 Wochen funktional, 3–5 Wochen robust.
