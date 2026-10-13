# SkinSpace — WMP-Klassiker & Visualizer für VLC

Alte **Windows-Media-Player-Skins** als native **VLC**-Skins (skins2) — maximal originalgetreu,
Original-Assets 1:1, dazu VLCs Visualizer im Skin-Screen. *(Inoffizielles Fan-Projekt.)*

**Enthaltene Skins:**

| Skin | Status | Dateien |
|---|---|---|
| **„Headspace"** (Microsoft, © 2000/2001) | ✅ fertig (v1.0) | `dist/Headspace*.vlt` |

Weitere Skin-Ports sind geplant.

## Dateien

| Datei | Größe | Beschreibung |
|---|---|---|
| `dist/Headspace.vlt` | 549×394 | Originalgröße (1×) |
| `dist/Headspace-2x.vlt` | 1098×788 | 2×, Pixel-Look (Nearest) — Empfehlung für moderne Bildschirme |
| `dist/Headspace-3x.vlt` | 1647×1182 | 3×, Pixel-Look (Nearest) |

## Installation

Voraussetzung: **VLC 3.0.x** (getestet: 3.0.23, Windows). Getestet auf Windows; DTD-2.0-konform, auf
anderen Plattformen ungetestet.

**Empfohlen (ohne Admin):**
```
"C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins --skins2-last="C:\...\dist\Headspace-2x.vlt"
```
**Oder** die `.vlt` nach `C:\Program Files\VideoLAN\VLC\skins\` kopieren und in VLC unter
*Werkzeuge → Einstellungen → Interface → „Benutzerdefiniertes Skin verwenden"* auswählen (Neustart nötig).

**Am einfachsten:** `skins/headspace/Start-Headspace.bat` doppelklicken (startet VLC mit der 2×-Version und
deaktivierter Mediathek → saubere Playlist wie im Original).

> ℹ️ **Zur Playlist:** VLC zeigt im Skin standardmäßig seine Playlist-Wurzelknoten („Playlist"/„Media
> Library") als Zeilen an. Mit `--no-media-library` (siehe .bat) verschwindet die Mediathek-Zeile.

> ⚠️ **Bekanntes Problem:** „Open skin…" (Rechtsklick-Menü im Skin) **kann VLC crashen** — auf
> VLC 3.0.23 reproduziert (fehlerhafter Skin-Wechsel-Mechanismus des Builds). Workaround: VLC neu starten
> bzw. `--skins2-last` verwenden.
>
> ⚠️ **Falls VLC nach einem Crash nicht mehr startet:** den Ordner `%APPDATA%\vlc\crashdump` leeren —
> ein liegengebliebener Crash-Dump blockiert sonst jeden Start (bekanntes VLC-3.0.x-Verhalten).

## Bedienung

| Element | Funktion |
|---|---|
| Stirn links/rechts | Minimieren / Schließen |
| Stirnmitte | ⏮ Zurück · ▶ Play · ⏹ Stop · ⏭ Weiter · ☀️ „Medien öffnen" |
| (beim Abspielen) | Pause-Knopf erscheint über Play |
| Kinn links (Balken-Icon) | **Equalizer-Schublade** (linkes Ohr) öffnen/schließen |
| Kinn rechts (Listen-Icon) | **Playlist-Schublade** (rechtes Ohr) öffnen/schließen |
| Kinnmitte (⌐-Symbol) | Einstellungen (Preferences) |
| Seekbar | Suchen per Klick/Ziehen |
| Kopf | Fenster ziehen |
| Drag & Drop | Musik/Video auf das Fenster ziehen — Videos erscheinen **im Screen im Kopf** |

**Equalizer-Schublade:**
- 10 Band-Regler + Volume: Änderungen wirken **sofort** auf die laufende Wiedergabe und bleiben gespeichert.
- ⚠️ VLCs Equalizer-Filter ist standardmäßig **aus** — die Regler bewegen sich dann, ohne zu klingen.
  `Start-Headspace.bat` startet ihn bereits **aktiv** (wie im Original, wo der EQ immer wirkte).
  Alternativ: den „reset"-Link einmal klicken (EQ an; LED an = aktiv), nochmal klicken = aus.
- „reset"-Link = **Equalizer an/aus**. Ein echtes Nullen aller Regler ist im VLC-Skin-System technisch
  nicht umsetzbar (die Engine bietet keinen Reset-Befehl) — die Regler ggf. manuell auf Mitte ziehen.
- „Preamp"-Regler (ursprünglich Balance): steuert den **EQ-Vorverstärker** (±20 dB, wirkt live).
  VLC-Skins können Balance technisch nicht anbinden — daher umfunktioniert, Label angepasst.
  Mute über VLC-Taste `M`.

## Bekannte Abweichungen vom Original (technisch bedingt, dokumentiert)

- **Visualisierungen**: VLCs eigene Visualizer (goom, projectM, …) laufen **im Kopf-Screen** mit —
  aktiviert über `--audio-visual=goom` bzw. `projectm` (siehe `skins/headspace/Start-Headspace-Visualizer.bat`).
  Im Skin selbst nicht umschaltbar (VLC bietet Skins keine Visualizer-Aktionen); die Optik des
  Original-Wählers (◄ Name ►) ist daher nicht funktional nachbildbar.
- **Balance** → **Preamp** umfunktioniert (VLC-Skins können Balance nicht anbinden): gleiche
  Position/Optik, Label „Preamp", steuert den EQ-Vorverstärker.
- **reset**-Link schaltet den Equalizer an/aus statt Gains zu nullen.
- Keine „disabled"-Optik auf Knöpfen (skins2 kennt nur up/hover/down).
- Ohr-Schubladen öffnen **ohne Slide-Animation** (skins2 hat keine Bewegungsanimation).
- Playlist-Optik: Checkboxen pro Zeile und Scrollbar mit Pfeilen sind **nachgebaute Original-Optik** —
  VLC kennt keinen Eintrag-Status (Checkboxen sind immer „an") und keine Pfeil-Scrollfunktion
  (gescrollt wird per Mausrad oder Ziehen am Thumb). Eine **Dauer pro Zeile** ist nicht möglich (VLC
  liefert dem Skin nur den Titel) — die **Laufzeit des aktuellen Tracks** (z.B. „00:04 / 00:30") steht
  stattdessen unten in der Playlist-Schublade (skin2-Platzhalter `$t`/`$d`, aktualisiert live).
- Cursor wechselt nicht zu einem Hand-Cursor (im Skin-System nicht vorgesehen).
- Ton-Standard-Optik des Original-Screens (Download-Fortschritt im Seekbar) entfällt.

## Credits

- Original-Skin **„Headspace" © 2000/2001 Microsoft Corporation** (offizieller WMP-Skin).
  Assets aus dem Internet-Archive-Backup der Microsoft-Skin-Sammlung
  (`archive.org/details/windowsmediaplayerskinscollection`). Alle Rechte am Original liegen bei Microsoft.
- Dieser Fan-Port ist ein inoffizielles, nicht-kommerzielles Projekt.

## Repo-Struktur (Multi-Skin)

    skins/<name>/theme        Skin-Quellen (XML-Fragmente, Bilder, Fonts) -> theme.xml
    skins/<name>/variants     gestagte 2x/3x-Varianten (generiert)
    skins/<name>/originals    Original-Rohdateien (Referenz für die Konvertierung)
    skins/<name>/Start-*.bat  Starter für dieses Skin
    tools/                    gemeinsame Build-Kette (alle Tools: -Skin <name>, Default headspace)
    dist/                     fertige .vlt-Dateien aller Skins
    research/, docs/          Projektwissen & Doku

**Neues Skin hinzufügen:** Ordner `skins/<name>/` anlegen (mit `theme/` und `originals/`),
Original-Assets nach `originals/extracted/` legen, XML-Fragmente/Bilder anpassen — dann die
Kette mit `-Skin <name>` durchlaufen lassen.

## Build (für Interessierte)

```
tools/make_original_assets.ps1 -Skin headspace   # BMP -> PNG32 + Farbkey-Alpha (+ bitmaps.xml)
tools/make_extra_assets.ps1 -Skin headspace      # LED/Füllung/Link/Playlist-/Scrollbar-Grafiken
tools/make_track_assets.ps1 -Skin headspace      # Slider-Tracks (Kappe-Linie-Kappe) aus Original-Kacheln
tools/build_theme.ps1 -Skin headspace -Scale 1   # theme.xml aus XML-Fragmenten (skins/<skin>/theme/xml/) + Validierung
tools/pack.ps1 -Skin headspace                   # -> dist/Headspace.vlt
tools/build_variants.ps1 -Skin headspace         # 2x/3x-Varianten -> dist/Headspace-2x.vlt / -3x.vlt
tools/tests/run_task3.ps1 …        # Test-Suiten (klickfrei)
```

Detail-Dokumentation: `research/` (Reverse-Engineering, Mapping, Spike-Ergebnisse) und
`docs/superpowers/specs/` (Design-Spezifikation).
