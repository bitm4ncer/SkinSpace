================================================================================
                                                                                
  #####  #   #  ###  #   #  ####  ####    ###    ###   ####  #####             
  #      ##  #   #   ##  #  #     #   #  #   #  #   #  #     #                 
  ###    # # #   #   # # #   ###  ####   #####  #      ###  ###               
  #      #  ##   #   #  ##      #  #      #   #  #   #  #     #               
  #####  #   #  ###  #   #  ####  #      #   #   ###   ####  #####             
                                                                                
  WMP-Klassiker & Visualizer fuer VLC -- inoffizielles Fan-Projekt              
================================================================================

  Alte Windows-Media-Player-Skins als native VLC-Skins (skins2), maximal
  originalgetreu: Original-Assets 1:1, keine Neuzeichnung. Dazu laufen VLCs
  eigene Visualizer direkt im Skin-Screen.

  Enthaltene Skins:

    Skin          Status           Dateien (dist/)
    -----------   --------------   ------------------------------------------
    Headspace     fertig (v1.0)    Headspace.vlt      (1x, 549x394)
    <weitere>     geplant          Headspace-2x.vlt   (2x, Pixel-Look)
                                   Headspace-3x.vlt   (3x, Pixel-Look)

--------------------------------------------------------------------------------
  SCHNELLSTART
--------------------------------------------------------------------------------

  Voraussetzung: VLC 3.0.x (getestet: 3.0.23, Windows).

  1) Starter-Bat doppelklicken (empfohlen, ohne Admin):

       skins/headspace/Start-Headspace.bat              (normal, EQ aktiv)
       skins/headspace/Start-Headspace-Visualizer.bat   (mit projectM im Screen)

  2) Oder per Kommandozeile:

       "C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins ^
           --skins2-last="C:\...\dist\Headspace-2x.vlt"

  3) Oder die .vlt nach "C:\Program Files\VideoLAN\VLC\skins\" kopieren und in
     VLC auswaehlen: Werkzeuge > Einstellungen > Interface >
     "Benutzerdefiniertes Skin verwenden" (Neustart noetig).

  HINWEIS Playlist: VLC zeigt im Skin standardmaessig seine Playlist-Wurzel-
  knoten ("Playlist"/"Media Library") als Zeilen an. Mit --no-media-library
  (siehe Starter-Bats) ist die Liste sauber wie im Original.

  WARNUNG 1: "Open skin..." (Rechtsklick-Menue) kann VLC crashen (auf 3.0.23
  reproduziert). Workaround: VLC neu starten bzw. --skins2-last verwenden.

  WARNUNG 2: Falls VLC nach einem Crash nicht mehr startet, den Ordner
  "%APPDATA%\vlc\crashdump" leeren -- ein liegengebliebener Crash-Dump
  blockiert sonst jeden Start (bekanntes VLC-3.0.x-Verhalten).

--------------------------------------------------------------------------------
  BEDIENUNG
--------------------------------------------------------------------------------

    Element                       Funktion
    ---------------------------   --------------------------------------------
    Stirn links / rechts          Minimieren / Schliessen
    Stirnmitte                    Zurueck | Play | Stop | Weiter
                                  und die "Sonne" = Medien oeffnen
    (waehrend Wiedergabe)         Pause-Knopf erscheint ueber Play
    Kinn links (Balken-Icon)      Equalizer-Schublade (linkes Ohr) auf/zu
    Kinn rechts (Listen-Icon)     Playlist-Schublade (rechtes Ohr) auf/zu
    Kinnmitte (Klammer-Symbol)    Einstellungen (Preferences)
    Seekbar                       Suchen per Klick / Ziehen
    Kopf                          Fenster ziehen
    Drag & Drop                   Medien aufs Fenster ziehen -- Videos und
                                  Visualizer erscheinen im Screen im Kopf

  Equalizer-Schublade:
    * 10 Band-Regler + Volume: wirken sofort auf die laufende Wiedergabe und
      bleiben gespeichert.
    * VLCs Equalizer-Filter ist standardmaessig AUS. Die Starter-Bats schalten
      ihn beim Start aktiv (wie im Original, wo der EQ immer wirkte).
      Alternativ: den "reset"-Link einmal klicken (an; LED an = aktiv),
      nochmal klicken = aus.
    * "reset"-Link = Equalizer an/aus. Ein echtes Nullen aller Regler ist im
      VLC-Skin-System technisch nicht umsetzbar (die Engine bietet keinen
      Reset-Befehl).
    * "Preamp"-Regler (urspruenglich Balance): steuert den EQ-Vorverstaerker
      (+/-20 dB, live). VLC-Skins koennen Balance nicht anbinden -- daher
      umfunktioniert, Label angepasst. Mute per VLC-Taste "M".

  Playlist-Schublade:
    * Checkboxen pro Zeile + Scrollbar mit Pfeilen = nachgebaute Original-
      Optik. Der Eintrag-Status existiert in VLC nicht (Boxen sind immer
      "an"); die Pfeile sind Deko (scrollen per Mausrad oder Thumb).
    * Unten rechts laeuft die Zeit des aktuellen Tracks mit ("00:04 / 00:30").
      Eine Dauer-Spalte pro Zeile ist nicht moeglich: VLC liefert dem Skin
      nur die Titel-Zeichenketten.

--------------------------------------------------------------------------------
  VISUALIZER (goom / projectM im Kopf-Screen)
--------------------------------------------------------------------------------

  VLCs eigene Visualizer laufen im Skin-Screen. Aktivierung per Startoption:

      --audio-visual=projectm        (Alternative: --audio-visual=goom)

  Fertige Starter:

      skins/headspace/Start-Headspace-Visualizer.bat      (projectM)

  Hinweise:
    * Im Skin selbst ist die Visualisierung nicht umschaltbar -- VLC bietet
      Skins keine Visualizer-Aktionen. Der Original-Headspace hatte dafuer
      den Waehler "WhiteCap Viz" oben im Screen; als reine Optik nachbaubar.
    * projectM-Presets (.milk) sind in VLC konfigurierbar; das kommende
      VLC-Pack bringt eine kuratierte Auswahl mit.
    * In Entwicklung: "Bitmancer Visualizer Pack" -- eigene Retro- und
      Modern-Visualizer (100% eigener Code).

--------------------------------------------------------------------------------
  INSTALLER & PAKS (in Entwicklung)
--------------------------------------------------------------------------------

  Geplant ist ein Inno-Setup-Installer mit eigenem Paket-Manager (deutsche UI,
  Uninstall/Repair inklusive). Design und Umsetzungsplan liegen unter docs/.

  Pakete (einzeln abwaehlbar):

    [x] VLC-Pack        Headspace-Skins 1x/2x/3x, kuratierte projectM-Presets,
                        VLC-Erkennung + Versionswarnung, optional MilkDrop 3
                        portabel; setzt skins2-last in der vlcrc (mit Backup)

    [ ] WMP-Pack        Original-.wmz aus den WMP-Goodies-Archiven + Original-
                        WMP-Visualizer (Alchemy, Battery & Co.; nur mit Admin-
                        Rechten). Experimentell: WMP-Visualizer im VLC-Screen
                        (Machbarkeits-Spike: GO fuer GDI-Vizzes)

    [ ] Winamp-Pack     MilkDrop 2 (Community-Fix) + AVS fuer Winamp/WACUP;
                        MilkDrop 3 standalone fuer alle

    [x] Bitmancer-Pack  Eigene Visualizer (eigener Code, darf mitgeliefert
                        werden; Retro-DLLs + Modern-Presets) -- in Entwicklung

  Merkmale der Engine:
    * Manifest mit SHA256-Pflicht fuer alle Downloads, Mirror-Ketten,
      BYO-Picker wenn Quellen tot sind (nur Hash-Match wird akzeptiert)
    * Journal mit Uninstall/Repair/Resume, vlcrc-Editor mit Backup/Restore
    * CLI:  Install-<Projekt>.ps1 [-Packs vlc,wmp,winamp] [-DryRun]
            [-OfflinePath <dir>] [-Resume]
    * Empfehlung VLC >= 3.0.24 (Sicherheitsfix im skins2-Loader);
      getestet ist 3.0.23

--------------------------------------------------------------------------------
  BEKANNTE ABWEICHUNGEN VOM ORIGINAL (technisch bedingt und dokumentiert)
--------------------------------------------------------------------------------

    * Keine "disabled"-Optik auf Knoepfen (skins2 kennt nur up/hover/down).
    * Ohr-Schubladen oeffnen ohne Slide-Animation (keine Bewegungsanimation).
    * Cursor wechselt nicht zu einem Hand-Cursor (im Skin-System nicht
      vorgesehen).
    * "reset"-Link schaltet den EQ an/aus statt Gains zu nullen.
    * Balance ist in VLC-Skins nicht anbindbar -- Regler wurde zum
      funktionierenden Preamp umfunktioniert (Label angepasst).
    * Visualizer-Wahl/-Name im Skin nicht moeglich (siehe oben).
    * Playlist-Checkboxen ohne Funktion, Pfeile ohne Scroll-Funktion;
      keine Dauer pro Zeile (siehe Bedienung).
    * Download-Fortschritt im Seekbar (Original-Optik) entfaellt.

--------------------------------------------------------------------------------
  REPO-STRUKTUR (Multi-Skin)
--------------------------------------------------------------------------------

    SkinSpace/
    |
    +-- skins/
    |   +-- headspace/              Skin Nr. 1 (weitere kommen daneben)
    |       +-- theme/              Build-Quellen: XML-Fragmente, Bilder, Fonts
    |       +-- variants/           gestagte 2x/3x-Varianten (generiert)
    |       +-- originals/          Original-Rohdateien (WMZ, Bitmaps, Previews)
    |       +-- Start-Headspace.bat
    |       +-- Start-Headspace-Visualizer.bat
    |
    +-- tools/                      gemeinsame Build-Kette (-Skin <name>)
    +-- dist/                       fertige .vlt-Dateien aller Skins
    +-- research/, docs/            Projektwissen & Doku
    +-- README.md, RESUME.md

  Neues Skin hinzufuegen:
    1. Ordner skins/<name>/ anlegen (mit theme/ und originals/)
    2. Original-Assets nach originals/extracted/ legen
    3. XML-Fragmente/Bilder in theme/ anpassen
    4. Kette mit -Skin <name> durchlaufen lassen (siehe unten)

--------------------------------------------------------------------------------
  BUILD-KETTE (fuer Interessierte)
--------------------------------------------------------------------------------

    Original (.wmz / Bitmaps)
          |
          v
    tools/make_*.ps1      -->  skins/<name>/theme/  (PNG32 + Fragmente)
          |
          v
    tools/build_theme.ps1 -->  theme.xml (mit eingebauter Validierung)
          |
          v
    tools/pack.ps1        -->  dist/<Skin>.vlt  -->  VLC 3.0.x (skins2)
          |
          +-- tools/build_variants.ps1  -->  dist/<Skin>-2x.vlt / -3x.vlt

    Aufrufe (Default-Skin: headspace):

      tools/make_original_assets.ps1 -Skin headspace   # BMP -> PNG32 (+ bitmaps.xml)
      tools/make_extra_assets.ps1 -Skin headspace      # LED/Fuellung/Link/Playlist-Grafiken
      tools/make_track_assets.ps1 -Skin headspace      # Slider-Tracks aus Original-Kacheln
      tools/build_theme.ps1 -Skin headspace -Scale 1   # theme.xml + Validierung
      tools/pack.ps1 -Skin headspace                   # -> dist/Headspace.vlt
      tools/build_variants.ps1 -Skin headspace         # -> dist/Headspace-2x/-3x.vlt

    Test-Suiten (klickfrei): tools/tests/run_task5.ps1, run_task6.ps1

    Detail-Doku: research/ (Reverse-Engineering, Mapping, Spike-Ergebnisse)
    und docs/superpowers/ (Specs + Plaene, inkl. Distribution/Installer).

--------------------------------------------------------------------------------
  CREDITS & HINWEISE
--------------------------------------------------------------------------------

    * Original-Skin "Headspace" (c) 2000/2001 Microsoft Corporation -- offi-
      zieller WMP-Skin. Assets aus dem Internet-Archive-Backup der Microsoft-
      Skin-Sammlung (archive.org/details/windowsmediaplayerskinscollection).
      Alle Rechte am Original liegen bei Microsoft.
    * "VLC" ist eine Marke der VideoLAN-Organisation. Dieses Projekt ist
      inoffiziell und steht in keiner Verbindung zu VideoLAN oder Microsoft.
    * Nicht-kommerzielles Fan-Projekt, Nutzung auf eigene Verantwortung.

================================================================================
  Viel Spass -- und: die Idee lebt von den Originalen. Danke, Microsoft 2000/01.
================================================================================
