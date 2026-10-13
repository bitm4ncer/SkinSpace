# Headspace Distribution — Phase A (Manifest + Engine + VLC-Pack) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein CLI (`Install-Headspace.ps1`), das das Headspace-VLC-Erlebnis installiert — Skin aus `dist/`, projectM-Preset-Pack „Cream of the Crop" (gepinnte Quelle, SHA256), `vlcrc`-Konfiguration — plus Manifest-Validator, Journal, Uninstall/Resume und Tests in Repo-Konvention.

**Architecture:** JSON-Manifeste mit festem Aktions-Vokabular; Engine als PowerShell-5.1-Modul (ASCII-only) mit injizierbaren Pfaden für Tests; CLI-Frontend; Tests als eigenständige PS-Skripte (`OK:`/`FAIL:` + Exit-Code, wie `tools/tests/run_task3.ps1`); Mock-HTTP-Server auf `TcpListener` (kein Admin nötig).

**Tech Stack:** Windows PowerShell 5.1, `ConvertFrom/To-Json`, `System.Net.Sockets.TcpListener`, `Invoke-WebRequest`, `Get-FileHash`, 7-Zip (`C:\Program Files\7-Zip\7z.exe`), `[System.IO.File]`.

**Spec:** `docs/superpowers/specs/2026-10-13-headspace-distribution-design.md` (§5.1 VLC-Pack, §6 Engine, §8 Sicherheit, §9 Fehler/Resume, §10 Tests — Phase A aus §11)

## Global Constraints

- Plattform Windows 10/11, **Windows PowerShell 5.1** (`powershell.exe`), keine externen Module. Pester 5 ist nicht verfügbar (nur Pester 3.4.0) — **nicht benutzen**.
- Alle Skripte: **pure ASCII, ohne BOM** (PS 5.1-Encoding-Falle, siehe `tools/pack.ps1`); in Skripten `$ErrorActionPreference='Stop'`.
- Tests laufen via `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <test>.ps1`, melden `OK: <check>` / `FAIL: <check>` und exit 1 bei Fehlern (Repo-Konvention).
- Keine Admin-Aktionen in Phase A. Keine Fremd-`exe`-Ausführung. Downloads erfordern SHA256.
- Zielpfade: TargetRoot Default `%LOCALAPPDATA%\HeadspacePack`, `vlcrc` Default `%APPDATA%\vlc\vlcrc`. **Tests überschreiben immer** (`-TargetRoot`, `-VlcrcPath`).
- Default-Skin: `Headspace-2x.vlt` (Quelle `dist/`, Maße 1098x788).
- Sprache: Code/Kommentare/Konsolenausgaben Englisch (ASCII); Repo-Doku Deutsch.
- Branch `distribution-phase-a` (von aktuellem Stand). Commits nur mit eigenen Pfaden: `distribution/**`, `docs/**`.
- Manifest-Aktions-Vokabular: `copy | write-config | regsvr32 | run-payload-script | manual-note` (Phase A implementiert `copy`, `write-config`, `manual-note`; die uebrigen existieren nur im Validator).
- Tokens in Werten: `%REPO%` `%TARGET%` `%WORK%` `%ARTIFACT%` `%APPDATA%` `%LOCALAPPDATA%` `%VLC_INSTALL_DIR%` `%WMP_VIS_DIR%`.

## Review Focus

1. **`vlcrc`-Integrität:** Kommentare, Sections, Leerzeilen und Zeilenenden bleiben unangetastet — nur die Ziellinie/der Zielblock darf sich ändern (Task 4: Diff-Test + Idempotenz).
2. **VLC läuft während der Installation:** Änderungen dürfen nicht still verloren gehen — klarer Block/`-Force` (Task 2: Guard-Test; Task 7: CLI-Exit-Code 2).
3. **Download-Fehler** (404, 500, Hash-Mismatch, offline, BYO): kein halb installiertes Item, klare Meldung, Resume repariert (Task 3: Mirror/Retry/Hash/Offline/BYO; Task 6: Dirty-Cleanup).
4. **Pfade mit Leerzeichen/Umlauten** (TargetRoot, `Program Files`): alles über Parser/Pipeline, nie `cmd`-String-Konkatenation (Task 5/6: Test mit Umlaut-Zielordner).
5. **Ungültiges Manifest blockiert alles:** Validator verhindert jeden Schritt, CLI endet mit Exit 2 und schreibt nichts (Task 1 + Task 7).

## Nicht in diesem Plan (bewusst)

- `vlc.milkdrop3` (Standalone-App) und `vlc.whitecap` (Info-Item) -> Phase B (Quellen-/Binärpinning bzw. reines Info-Item).
- WMP-Pack mit Regsvr32/Admin -> Phase B; Winamp-Pack -> Phase C; Inno-Installer -> Phase D; Release-Zip/Offline-Tool -> Phase E; Bitmancer-Integration -> eigener Agent (Spec §5.4).
- Kein Code-Signing, kein Auto-Updater, kein Mehrsprachen-Framework (Phase A bleibt bewusst klein).

---

### Task 1: Branch, Scaffold, Manifest-Schema, Validator

**Files:**
- Create: `distribution/README.md` (Layout, Schema-Kurzreferenz, Wartung)
- Create: `distribution/manifests/vlc-pack.json` (nur `vlc.skin`-Item; Presets-Item folgt in Task 7)
- Create: `distribution/manifests/sources.json` (`{"schemaVersion":1,"mirrors":{}}`)
- Create: `distribution/engine/HeadspacePack.psm1` (Modulkopf + Validator/Reader)
- Create: `distribution/engine/Test-Manifests.ps1` (CLI: validiert `distribution/manifests`, Exit 0/1)
- Create: `distribution/tests/support/assert.ps1` (`Assert-True`, `Assert-Equal`, `Assert-Throws`, `Complete-Asserts`)
- Create: `distribution/tests/fixtures/manifests/good/pack.json`
- Create: `distribution/tests/fixtures/manifests/bad/dup-id.json`, `bad-sha.json`, `unknown-action.json`, `missing-name.json`
- Create: `distribution/tests/test_manifest_validator.ps1`

**Interfaces:**
- Produces:
  - `Test-ManifestSet -ManifestDir <string>` -> `[pscustomobject]@{ Ok=[bool]; Problems=[string[]] }`
  - `Read-ManifestItems -ManifestDir <string>` -> `[object[]]` (wirft bei ungültig; Items = vereinigte `items[]` aller `*-pack.json`)
  - Item-Felder: `id` (`^[a-z0-9]+\.[a-z0-9.]+$`, global eindeutig), `name`, `category` (`vlc|wmp|winamp|bitmancer`), `default` (bool), `notes`, `license.{status,redistribution}` (`redistribution` in `repo-asset|downloader-only|allowed|byo`), `sources[]` (URLs, nur `https`), `sha256` (64 hex, Pflicht wenn `sources` nicht leer), `archive` (`none|zip|7z`), `install.steps[]` (>=1; `copy` braucht `from`+`to`; `write-config` braucht `file="vlcrc"`+`section`+`key`+`value`; `manual-note` braucht `text`)
  - `distribution/tests/support/assert.ps1`: dot-sourcen setzt `$script:AssertFailures`; `Complete-Asserts` gibt Exit-Code zurueck (0/1) und druckt `PASS:`/`FAIL:`.

- [ ] **Step 1: Branch anlegen und Scaffold-Verzeichnisse erstellen**

```powershell
git checkout -b distribution-phase-a
New-Item -ItemType Directory -Force -Path distribution\manifests,distribution\engine,distribution\tests\support,distribution\tests\fixtures\manifests\good,distribution\tests\fixtures\manifests\bad
```

- [ ] **Step 2: Failing test schreiben — `distribution/tests/test_manifest_validator.ps1`**

Fixiertes Verhalten (Assertions, exakt):
- dot-sourct `support\assert.ps1`, importiert das Modul.
- GOOD-Fixture -> `(Test-ManifestSet -ManifestDir <good>).Ok` == `$true`, `Problems` leer; `(Read-ManifestItems -ManifestDir <good>).Count` == 2.
- Fuer jede BAD-Fixture: `Ok` == `$false` und `Problems` enthaelt den erwarteten Marker-Fragmenttext: `duplicate id` (dup-id), `sha256` (bad-sha), `unknown action` (unknown-action), `missing name` (missing-name).
- `Read-ManifestItems` auf BAD wirft (`Assert-Throws`).
- GOOD-Fixture-Inhalt (2 Items, fest): `test.local` (keine `sources`, `install.steps=[{action="copy",from="a.txt",to="%TARGET%/a.txt"}]`) und `test.remote` (`sources=[{url="https://example.invalid/x.zip"}]`, `sha256` = 64x`0`).

- [ ] **Step 3: Test laufen lassen — muss fehlschlagen**

Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File distribution\tests\test_manifest_validator.ps1`
Expected: FAIL (Modul/Datei fehlt).

- [ ] **Step 4: `HeadspacePack.psm1` (Validator + Reader) und `Test-Manifests.ps1` implementieren**

Modulkopf mit `Export-ModuleMember` fuer: `Test-ManifestSet`, `Read-ManifestItems`. Validator faengt Datei-/JSON-/Feldfehler als `Problems` (kein Throw); Reader ruft Validator und wirft aggregiert. `Test-Manifests.ps1` validiert `distribution\manifests` (Pfad relativ zu `$PSScriptRoot`), druckt Probleme, Exit 0/1.

- [ ] **Step 5: `vlc-pack.json` (nur Skin-Item), `sources.json`, `distribution/README.md` schreiben**

`vlc.skin`-Item exakt: `id="vlc.skin"`, `name="Headspace VLC skin (1x/2x/3x)"`, `category="vlc"`, `default=true`, `requires=["vlc-present"]`, `sources=[]`, `archive="none"`, `license={"status":"proprietary-microsoft","redistribution":"repo-asset"}`, `notes="Skin builds from dist/ (existing pipeline)."`, `install.steps=[3x copy von %REPO%/dist/Headspace*.vlt nach %TARGET%/skins/, 1x write-config skins2/skins2-last -> %TARGET%/skins/Headspace-2x.vlt]`. README: Layout, Schema-Kurzreferenz, „Items hinzufuegen = nur JSON" + Wartungshinweis (Hash nur bei Downloads).

- [ ] **Step 6: Test laufen lassen — muss passieren**

Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File distribution\tests\test_manifest_validator.ps1` -> PASS.
Zusatz: `powershell.exe ... -File distribution\engine\Test-Manifests.ps1` -> Exit 0.

- [ ] **Step 7: Commit**

```bash
git add distribution docs
git commit -m "feat(dist): manifest schema + validator + phase-a scaffold"
```

---

### Task 2: Umgebung (VLC-Detection, Running-Guard, Logging)

**Files:**
- Modify: `distribution/engine/HeadspacePack.psm1` (+ `Get-HeadspaceEnvironment`, `Assert-VlcClosed`, `Write-HeadspaceLog`)
- Create: `distribution/tests/test_engine_environment.ps1`

**Interfaces:**
- Produces:
  - `Get-HeadspaceEnvironment [-VlcInstallDirOverride <string>] [-VlcrcPathOverride <string>]` -> `[pscustomobject]@{ VlcInstallDir; VlcVersion; VlcRunning; VlcrcPath; VlcrcExists }` — Quelle: Registry `HKLM:\SOFTWARE\VideoLAN\VLC` (`InstallDir`, `Version`), Fallback `C:\Program Files\VideoLAN\VLC\vlc.exe`; `VlcVersion` = `[version]`-Parse von `Version`-String.
  - `Assert-VlcClosed [-ProcessNames <string[]>] [-Force]` -> void; wirft `"VLC is running - close it or use -Force"` wenn ein Prozess laeuft (Default-Namen `@('vlc')`; Tests injizieren `powershell`).
  - `Write-HeadspaceLog -Context <object> -Level <string> -Message <string>` (`INFO|WARN|ERROR|OK`) — schreibt `"<timestamp> <LEVEL> <message>"` nach `$Context.LogFile` und gibt dieselbe Zeile aus.

- [ ] **Step 1: Failing test schreiben — `test_engine_environment.ps1`**

Assertions (exakt):
- Temp-`vlcrc`-Fixture anlegen; `Get-HeadspaceEnvironment -VlcrcPathOverride <fixture>` -> `VlcrcExists` == `$true`; mit nicht-existentem Pfad -> `$false`.
- `-VlcInstallDirOverride "$env:TEMP\hdspace-vlc"` -> `VlcInstallDir` == Override; `VlcVersion` == `$null` (kein exe).
- `Assert-VlcClosed -ProcessNames @('vlc')` wirft NICHT, wenn kein vlc laeuft (Test laeuft unter `powershell`).
- `Assert-VlcClosed -ProcessNames @('powershell')` wirft (`Assert-Throws`).
- `Assert-VlcClosed -ProcessNames @('powershell') -Force` wirft NICHT.
- `Write-HeadspaceLog` erzeugt Datei mit Zeile, die `" INFO hello"` enthaelt.

- [ ] **Step 2: Test laufen lassen — muss fehlschlagen**

Run: `powershell.exe ... -File distribution\tests\test_engine_environment.ps1` -> FAIL (Funktionen fehlen).

- [ ] **Step 3: Implementieren**

Registry-Zugriff defensiv (`Get-ItemProperty -ErrorAction SilentlyContinue`); `VlcRunning` per `Get-Process -Name` mit `-ErrorAction SilentlyContinue`. Prozessliste in `Assert-VlcClosed` ist der Test-Injektionspunkt. Log-Ordner wird bei Bedarf erzeugt (`New-Item -ItemType Directory -Force`).

- [ ] **Step 4: Test laufen lassen — muss passieren**; dann Commit

```bash
git add distribution && git commit -m "feat(dist): environment detection, vlc guard, logging"
```

---

### Task 3: Download-Pipeline (Mirror-Kette, Retries, SHA256, Offline, BYO) + Mock-Server

**Files:**
- Modify: `distribution/engine/HeadspacePack.psm1` (+ `Get-ItemSourceChain`, `Get-VerifiedDownload`, `Expand-DownloadedArchive`)
- Create: `distribution/tests/support/mock_http.ps1`
- Create: `distribution/tests/test_engine_download.ps1`

**Interfaces:**
- Produces:
  - `Get-ItemSourceChain -Item <object> -SourcesMap <object>` -> `[string[]]` = `Item.sources[].url` + angehaengte `SourcesMap.mirrors[Item.id]` (Mirrors zuletzt).
  - `Get-VerifiedDownload -Item <object> -Context <object>` -> `[string]` Pfad zur verifizierten Datei. Reihenfolge: (1) Cache `%TARGET%/cache/<id>.bin` mit Hash-Treffer, (2) `-OfflinePath\<id>.bin`, (3) `-ByoFiles[id]`, (4) URL-Kette mit je 2 Versuchen (`Invoke-WebRequest -UseBasicParsing -TimeoutSec $Context.DownloadTimeoutSec`), Hash-Pruefung `Get-FileHash -Algorithm SHA256`. Kein Kandidat -> `throw "no verified source for <id>"`; Hash-Fehler -> Datei loeschen + `throw "sha256 mismatch for <id>"`. Relative `-OfflinePath`-Angaben werden vorher zu absoluten Pfaden aufgeloest.
  - `Expand-DownloadedArchive -Item <object> -ArchivePath <string> -WorkDir <string>` -> `[string]` Extrakt-Root (`7z x -o<WorkDir>`; Fehler -> throw).
  - `Start-MockHttpServer -Routes <hashtable> [-FailFirstPerRoute <int>]` -> `[pscustomobject]@{ BaseUrl; Stop=[scriptblock] }` — `TcpListener` auf `127.0.0.1:0` in einem `Start-Job`; Route-Wert = Dateipfad; unbekannte Route = 404; `FailFirstPerRoute` = erste N Requests je Route 500 (Retry-Test).

- [ ] **Step 1: `mock_http.ps1` schreiben (Algorithmus, deshalb hier fixiert)**

Job-Skript: `TcpListener(localhost,0)` starten, Port zurueckgeben (erste Job-Ausgabe), dann endlos `AcceptTcpClient()`; Request-Zeile lesen, Pfad parsen; pro Pfad Request-Zaehler fuehren; Status 200 + Bytes bzw. 404/500 senden; Response: `HTTP/1.1 <code>\r\nContent-Length: <n>\r\nConnection: close\r\n\r\n`. `Stop` = `Stop-Job` + `Remove-Job`. Warten bis `BaseUrl` verfuegbar (`Receive-Job` mit Timeout-Schleife).

- [ ] **Step 2: Failing test schreiben — `test_engine_download.ps1`**

Assertions (exakt; Fixture-Datei ~64 KB Zufallsbytes, Hash vorab via `Get-FileHash`):
1. Echter Download vom Mock (Route `/ok.bin`) -> Rueckgabe-Pfad existiert, Hash OK.
2. Route `/miss.bin` = 404, Mirror-Route `/mirror.bin` = 200: Item mit beiden URLs -> Erfolg (Mirror-Fallback).
3. `FailFirstPerRoute 1` auf `/retry.bin` -> Erfolg trotz erstem 500.
4. Falscher `sha256` -> `Assert-Throws`, Cache-Datei wurde geloescht.
5. `-OfflinePath <dir>` mit `<id>.bin` -> Erfolg ohne Server.
6. `-ByoFiles @{ 'test.remote' = '<file>' }` -> Erfolg.
7. `Expand-DownloadedArchive` mit kleinem Test-ZIP (2 Dateien, via 7z erzeugt) -> Root enthaelt `a.txt`,`b.txt`.

- [ ] **Step 3: Test laufen lassen — muss fehlschlagen**; dann implementieren; dann laufen lassen -> PASS.

- [ ] **Step 4: Commit**

```bash
git add distribution && git commit -m "feat(dist): verified download pipeline + mock http server"
```

---

### Task 4: vlcrc-Editor (Section-bewusst, Backup/Restore, Idempotent)

**Files:**
- Modify: `distribution/engine/HeadspacePack.psm1` (+ `Get-VlcrcEntry`, `Set-VlcrcEntry`, `Backup-Vlcrc`, `Restore-VlcrcBackup`)
- Create: `distribution/tests/test_vlcrc_editor.ps1`

**Interfaces:**
- Produces:
  - `Get-VlcrcEntry -Path <string> -Section <string> -Key <string>` -> `[pscustomobject]@{ Present; Active; Value; LineNumber }`
  - `Set-VlcrcEntry -Path <string> -Section <string> -Key <string> -Value <string>` -> `[pscustomobject]@{ Changed; Previous; InsertedSection }` — ersetzt aktive ODER kommentierte Key-Zeile (`#key=...` -> `key=value`); fehlt der Key: einfuegen direkt nach dem Section-Header; fehlt die Section: `[section]`+Key ans Dateiende.
  - `Backup-Vlcrc -Path <string> -BackupDir <string>` -> Backup-Pfad (`vlcrc.<yyyyMMdd-HHmmss>.bak`).
  - `Restore-VlcrcBackup -BackupPath <string> -Path <string>` -> void (kopiert zurueck).
- Verhalten (fixiert): Datei wird als Text gelesen (`[System.IO.File]::ReadAllText`), Zeilen per `[regex]::Split($text,"\r?\n")`, dominantes EOL ermittelt und beim Schreiben beibehalten; ohne Aenderung wird **nicht** geschrieben; Schreiben via `[System.IO.File]::WriteAllText` mit `New-Object System.Text.UTF8Encoding($false)`.

- [ ] **Step 1: Fixture-Inhalt definieren (in den Test einbetten, exakt)**

```
[core]
# core stuff

[projectm]
# projectM preset path (string)
#projectm-preset-path=
#projectm-width=800

[skins2]
# Skin to use (string)
skins2-last=C:\old\Headspace.vlt
#skins2-systray=1

[other]
keepme=1
```

- [ ] **Step 2: Failing test schreiben — `test_vlcrc_editor.ps1`**

Assertions (exakt):
1. `Get-VlcrcEntry` auf `[projectm] projectm-preset-path` -> `Present=$true, Active=$false`.
2. `Set-VlcrcEntry` `[projectm]`-Key -> `Changed=$true`, `InsertedSection=$false`; Datei enthaelt `projectm-preset-path=C:\neu` und `#projectm-width=800` unveraendert; **Zeilen-Diff** (alle Zeilen ausser der geaenderten + ggf. leerer Rest) identisch.
3. Zweiter identischer Aufruf -> `Changed=$false`; Datei-Bytes identisch vor/nach (Idempotenz-Test via `Get-FileHash`).
4. `Set-VlcrcEntry` `[skins2]`-`skins2-last` ersetzt die **aktive** Zeile; `Previous` == alter Wert.
5. Neue Section `[neu]`-Key -> `InsertedSection=$true`; Datei endet mit `[neu]` + Zeile; restliche Zeilen unveraendert.
6. CRLF-Fixture (Inhalt aus Step 1 mit `\r\n`): nach Edit bleiben alle **beibehaltenen** Zeilen CRLF (Byte-Vergleich auf Praefix), geaenderte Zeile mit CRLF.
7. `Backup-Vlcrc` erzeugt Datei in BackupDir; `Restore-VlcrcBackup` stellt Original-Hash wieder her.

- [ ] **Step 3: Test laufen lassen — muss fehlschlagen**

Run: `powershell.exe ... -File distribution\tests\test_vlcrc_editor.ps1` -> FAIL (Funktionen fehlen).

- [ ] **Step 4: Implementieren** (Editor-Funktionen gemaess Interfaces; Backup via `Copy-Item`).

- [ ] **Step 5: Test laufen lassen — muss passieren** -> PASS.

- [ ] **Step 6: Commit** (`feat(dist): section-aware vlcrc editor with backup/restore`)

---

### Task 5: Install-Schritte (copy inkl. Glob, write-config, manual-note, Tokens, DryRun)

**Files:**
- Modify: `distribution/engine/HeadspacePack.psm1` (+ `New-HeadspaceContext`, `Expand-HeadspaceValue`, `Invoke-InstallStep`)
- Create: `distribution/tests/test_engine_steps.ps1`

**Interfaces:**
- Produces:
  - `New-HeadspaceContext -RepoRoot <string> -ManifestDir <string> [-TargetRoot <string>] [-VlcrcPath <string>] [-LogDir <string>] [-OfflinePath <string>] [-ByoFiles <hashtable>] [-DryRun] [-Force] [-DownloadTimeoutSec <int>=60] [-Select <string[]>] [-Resume]` -> Context (Felder: `RepoRoot ManifestDir TargetRoot VlcrcPath LogDir LogFile CacheDir OfflinePath ByoFiles DryRun Force DownloadTimeoutSec Select Resume Env JournalPath`)
  - `Expand-HeadspaceValue -Value <string> -Context <object> [-WorkDir <string>] [-Artifact <string>]` -> `[string]` (Token-Ersetzung, danach `[Environment]::ExpandEnvironmentVariables`).
  - `Invoke-InstallStep -Item <object> -Step <object> -Context <object> -State <object> [-WorkDir <string>] [-Artifact <string>]` -> void; ergaenzt `$State.files` (Array absoluter Ziele) bzw. `$State.configEdits` (`@{file;section;key;previous;backup}`); bei `$Context.DryRun` keine Schreiboperation (nur Log).
- `copy`-Semantik (fixiert): `from` mit `**/` (nur Form `%WORK%/**/*.ext` zugelassen) = rekursiv alle Dateien mit Endung `*.ext` aus dem Basisordner, Zielpfad = `to\<relativer Pfad>`; sonst Einzeldatei-Kopie. Zielordner werden erzeugt.

- [ ] **Step 1: Failing test schreiben — `test_engine_steps.ps1`**

Assertions (exakt; TargetRoot = `"$env:TEMP\Headspace Pack Testae\Ziel"` — Leerzeichen + Umlaut):
1. Einzel-`copy` (`%REPO%`-Fixture-Datei -> `%TARGET%/a.txt`) legt Zieldatei an; `State.files` enthaelt sie.
2. Glob-`copy` (`%WORK%/**/*.milk` aus Fixture-Baum `x/one.milk`, `x/sub/two.milk`, `x/skip.txt`) kopiert genau 2 Dateien nach `%TARGET%/presets/cotc/x/...` (Struktur erhalten), `skip.txt` nicht.
3. `write-config` auf Fixture-`vlcrc` setzt Key (wie Task 4) und `State.configEdits` enthaelt `previous` + `backup`; Backup-Datei existiert.
4. `Expand-HeadspaceValue` ersetzt `%TARGET%`, `%APPDATA%`, `%REPO%`; unbekanntes Token -> throw.
5. `-DryRun`: keine Zieldateien, keine vlcrc-Aenderung, `State.files` leer.
6. Unbekannte Action `foo` -> throw `"unknown action 'foo'"`.

- [ ] **Step 2: Test laufen lassen — muss fehlschlagen**

Run: `powershell.exe ... -File distribution\tests\test_engine_steps.ps1` -> FAIL (Funktionen fehlen).

- [ ] **Step 3: Implementieren** (Tokens, Steps, DryRun-Guard gemaess Interfaces).

- [ ] **Step 4: Test laufen lassen — muss passieren** -> PASS.

- [ ] **Step 5: Commit** (`feat(dist): install steps, token expansion, dry-run`)

---

### Task 6: Item-Pipeline + Journal + Uninstall + Resume

**Files:**
- Modify: `distribution/engine/HeadspacePack.psm1` (+ `Read-InstallJournal`, `Write-InstallJournal`, `Install-HeadspaceItem`, `Invoke-HeadspaceInstall`, `Invoke-HeadspaceUninstall`)
- Create: `distribution/tests/test_engine_install.ps1`

**Interfaces:**
- Produces:
  - Journal (`$Context.JournalPath` = `%TARGET%/journal.json`): `{ schemaVersion=1; lastRun=@{id;timestamp;packs}; items=@{ "<id>"=@{ state="installed|dirty"; files=[abs]; configEdits=[@{file;section;key;previous;backup}]; timestamp } } }`
  - `Install-HeadspaceItem -Item <object> -Context <object>` -> Statusobjekt `@{Id;Result="installed|skipped|failed";Message}` — laeuft Item-Pipeline: `requires`-Check (fehlendes VLC -> failed mit `"VLC not found"`; Version < 3.0.24 -> WARN), Download/Extrakt (wenn `sources`/`archive`), Steps, Journal-Eintrag `installed`.
  - `Invoke-HeadspaceInstall -Context <object>` -> `@{Installed=[string[]];Skipped=[string[]];Failed=@(...);Errors=[string[]]}` — Auswahl: Items mit `category in -Packs` (Default `vlc`); `default=false`-Items nur wenn per `-Select` gematcht (Wildcards `*` erlaubt). **Resume-Regel:** existiert Journal mit `state="dirty"` und `-Resume` fehlt -> Abbruch mit `"previous run incomplete - use -Resume"` (Exit 2 im CLI); mit `-Resume`: dirty-Items vor Neulauf bereinigen (Dateien loeschen, Config-Edits zuruecksetzen).
  - `Invoke-HeadspaceUninstall -Context <object> [-Id <string>]` -> entfernt `files` (nur wenn unter TargetRoot), stellt `configEdits.previous` wieder her (oder entfernt Key, wenn `previous=$null`), Journal-Eintrag loeschen.

- [ ] **Step 1: Failing test schreiben — `test_engine_install.ps1`**

Assertions (exakt; Temp-TargetRoot mit Umlaut, Fixture-Manifest aus Task 1 gute Fixture):
1. `Invoke-HeadspaceInstall` mit lokalem Fixture-Item -> `Installed` enthaelt id; Datei + vlcrc-Key existieren; Journal `state="installed"`.
2. Zweiter Lauf -> `Skipped` enthaelt id; Ziel-Bytes unveraendert.
3. `-DryRun` -> Journal wird nicht geschrieben.
4. Journal manuell auf `state="dirty"` setzen -> Install ohne `-Resume` wirft `"previous run incomplete"`; mit `-Resume` -> Datei wird neu erstellt, Zustand `installed`.
5. `Invoke-HeadspaceUninstall` -> Datei geloescht, vlcrc wieder auf `previous` (Fixture-Ausgangswert), Journal-Eintrag weg.
6. Item mit `requires=["vlc-present"]` und leerer Umgebung (Override auf nicht-existenten InstallDir) -> `failed` mit `"VLC not found"`, sonst nichts geschrieben; ein zweites lokales Item im selben Lauf wird trotzdem `installed` (Item-Fehler isoliert).

- [ ] **Step 2: Test laufen lassen — muss fehlschlagen**

Run: `powershell.exe ... -File distribution\tests\test_engine_install.ps1` -> FAIL (Funktionen fehlen).

- [ ] **Step 3: Implementieren** (Journal, Item-Pipeline, Resume-Regel, Uninstall gemaess Interfaces).

- [ ] **Step 4: Test laufen lassen — muss passieren** -> PASS.

- [ ] **Step 5: Commit** (`feat(dist): item pipeline, journal, resume, uninstall`)

---

### Task 7: Manifest-Vervollstaendigung (Presets) + CLI + CLI-Tests

**Files:**
- Modify: `distribution/manifests/vlc-pack.json` (+ `vlc.presets.cotc`)
- Create: `distribution/engine/Install-Headspace.ps1`
- Create: `distribution/tests/test_cli.ps1`
- Modify: `distribution/README.md` (CLI-Nutzung)

**Interfaces:**
- `vlc.presets.cotc`-Item exakt: `name="projectM Presets: Cream of the Crop"`, `category="vlc"`, `default=true`, `requires=["vlc-present"]`, `sources=[{"url":"https://github.com/projectM-visualizer/presets-cream-of-the-crop/archive/0180df21f5e0bd39b9060cc5de420ed2f1f9e509.zip"}]`, `sha256=<siehe Step 2>`, `archive="zip"`, `license={"status":"NOASSERTION (see upstream LICENSE.md)","redistribution":"downloader-only"}`, `notes="Default projectM preset pack since 2022; pinned commit 0180df2."`, `install.steps=[{action="copy",from="%WORK%/**/*.milk",to="%TARGET%/presets/cotc"},{action="write-config",file="vlcrc",section="projectm",key="projectm-preset-path",value="%TARGET%/presets/cotc"}]`.
- CLI `Install-Headspace.ps1` Parameter: `-Packs <string[]>` (Default `@('vlc')`), `-Select <string[]>`, `-ManifestDir <string>` (Default `distribution\manifests`), `-DryRun`, `-OfflinePath`, `-ByoFile <hashtable>`, `-Resume`, `-Force`, `-Uninstall`, `-LogDir`, `-TargetRoot`, `-VlcrcPath`, `-ProcessNames <string[]>` (Default `@('vlc')`, Test-Hook fuer den Running-Guard). Exit: `0` OK · `1` Items fehlgeschlagen · `2` blockiert (ungueltiges Manifest, VLC laeuft ohne `-Force`, dirty ohne `-Resume`).

- [ ] **Step 1: Failing CLI-Test schreiben — `test_cli.ps1`**

Assertions (exakt; alle mit eigenen `-TargetRoot`/`-VlcrcPath` im Temp):
1. `-DryRun -Select vlc.skin` -> Exit 0, keine Datei im TargetRoot.
2. `-Select test.local -ManifestDir <good-Fixture>` -> Exit 0, Zieldatei (`a.txt`) + vlcrc-Key vorhanden.
3. Ungueltiges Manifest (eine BAD-Fixture in ManifestDir) -> Exit 2, kein Schreibzugriff.
4. Running-Guard: `-ProcessNames @('powershell')` ohne `-Force` -> Exit 2, kein Schreibzugriff; mit `-Force` -> Exit 0/1 (faehrt fort); `-DryRun` liefert **nie** Exit 2 (ueberspringt den Guard).
5. `-Uninstall` nach Test 2 -> Exit 0, Dateien weg, vlcrc restauriert.

- [ ] **Step 2: Pinned Preset-ZIP herunterladen und Hash eintragen**

```powershell
curl.exe -sL "https://github.com/projectM-visualizer/presets-cream-of-the-crop/archive/0180df21f5e0bd39b9060cc5de420ed2f1f9e509.zip" -o "$env:TEMP\cotc.zip"
(Get-FileHash "$env:TEMP\cotc.zip" -Algorithm SHA256).Hash
```
Hash (lowercase) in `vlc-pack.json` eintragen; `Test-Manifests.ps1` -> Exit 0; ZIP fuer den E2E nach `$env:TEMP\headspace-offline\vlc.presets.cotc.bin` kopieren (ausserhalb des Repos — nichts Grosses committen).

- [ ] **Step 3: CLI implementieren** (duennes Frontend: Context bauen, `Assert-VlcClosed` ausser bei DryRun — `-ProcessNames` durchreichen, `Invoke-HeadspaceInstall`/`Invoke-HeadspaceUninstall`, Summary drucken, Exit-Code).

- [ ] **Step 4: Tests laufen lassen** -> PASS; Commit (`feat(dist): preset item pinned + CLI install/uninstall`).

---

### Task 8: E2E am echten VLC, Aggregator, Abschluss

**Files:**
- Create: `distribution/tests/run_phase_a.ps1` (Aggregator: fuehrt alle `test_*.ps1` via `powershell.exe` aus, sammelt PASS/FAIL)
- Modify: `distribution/README.md` (E2E-Anleitung, Uninstall-Hinweis)
- Create: `distribution/tests/out/e2e_skin.png` (Screenshot-Beweis, wird erzeugt)

- [ ] **Step 1: E2E auf der Maschine (VLC geschlossen!)**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File distribution\engine\Install-Headspace.ps1 -Packs vlc -OfflinePath "$env:TEMP\headspace-offline"
```
Erwartet: Exit 0; `%LOCALAPPDATA%\HeadspacePack\skins\Headspace-2x.vlt` existiert; `vlcrc` hat `skins2-last` + `projectm-preset-path`; Presets unter `%LOCALAPPDATA%\HeadspacePack\presets\cotc` (Stichprobe: `Select-String` findet 5 `.milk`-Dateien).

- [ ] **Step 2: Skin-Ladetest gegen die installierte Datei**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\test_skin.ps1 -Vlt "$env:LOCALAPPDATA\HeadspacePack\skins\Headspace-2x.vlt" -ExpectW 1098 -ExpectH 788 -Shot distribution\tests\out\e2e_skin.png
```
Erwartet: `PASS: Skin-Ladetest (1098 x 788)`, Screenshot existiert.

- [ ] **Step 3: Aggregator schreiben und komplett laufen lassen**

`run_phase_a.ps1` listet exakt: `test_manifest_validator`, `test_engine_environment`, `test_engine_download`, `test_vlcrc_editor`, `test_engine_steps`, `test_engine_install`, `test_cli`. Run -> `PASS: Phase-A-Suite`.

- [ ] **Step 4: Optionaler Uninstall-E2E (dokumentiert) + Abschluss-Commit**

```powershell
powershell.exe ... -File distribution\engine\Install-Headspace.ps1 -Uninstall
```
Erwartet: Exit 0; Zielordner-Dateien entfernt; `vlcrc` zurueckgesetzt (Hinweis in README: danach ggf. Skin manuell neu waehlen).

```bash
git add distribution && git commit -m "feat(dist): phase-a e2e, test aggregator, docs"
```
