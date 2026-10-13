# VLC skins2 — Umfassender Recherchebericht

**Zweck:** Technische Grundlage für den Port des WMP9-Skins „Headspace“ (Microsoft, 2000) nach VLC 3.0.x (skins2) auf Windows x64.
**Zielsystem:** VLC 3.0.23 x64, `C:\Program Files\VideoLAN\VLC`, Windows.
**Datum:** 2026-10-13.
**Methodik:** Quellcode-Analyse des VLC-Tags `3.0.23` (GitLab `code.videolan.org/videolan/vlc`, Modul `modules/gui/skins2`), offizielle Doku (readthedocs, VideoLAN-Wiki, videolan.org), lokale Read-only-Prüfung der Installation. Jede Kernaussage ist **[VERIFIED]** (direkt im Code/Doku/Datei belegt) oder **[UNCERTAIN]** (begründete Annahme / nicht abschließend prüfbar) markiert. Quellen-URLs stehen jeweils dabei, gesammelt am Ende.

---

## 0. Executive Summary

- skins2 in VLC 3.0.x ist ein **eigenständiges XML-UI-Toolkit** mit fester DTD-Version **2.0**. Es kann irreguläre, transparente Fenster darstellen (per-Pixel-Maske → Windows-Fenster-Region, dadurch echte Click-Through-Bereiche), mehrere Fenster inkl. Playlist- und Equalizer-Fenster verwalten, Video einbetten, komplette 10-Band-Equalizer-UI bauen und animierte Bitmaps (bis hin zu Blink-/Rotationsanimationen) abspielen.
- **Es gibt KEIN Balance-Widget** (weder Variable noch Action noch DTD-Element) und **keine Visualisierungssteuerung** (goom/projectM) aus dem Skin heraus.
- **Theme-XML-Datei = `theme.xml`** (nicht `skin.xml`!). Skin-Archiv `.vlt` = **tar.gz oder zip** (VLC 3.0.23s gebündeltes `default.vlt` ist nachweislich ein gzip/tar), Wurzel-XML wird rekursiv gesucht.
- Equalizer ist voll aus XML steuerbar: `equalizer.band(0..9)`, `equalizer.preamp`, `equalizer.isEnabled`, Actions `equalizer.enable()`/`disable()` — im mitgelieferten `default.vlt` sogar als komplettes EQ-Fenster implementiert.
- Text/Tooltips unterstützen dynamische `$`-Variablen (`$T` Zeit, `$N` Titel, `$V` Volume, `$H` Hover-Hilfetext u. a.) — damit lässt sich der klassische „Statusbar-/Tooltip-Trick“ von WMP9-Skins nachbauen.
- skins2 existiert auch in VLC 4.x (master) weiter, wird dort per Meson-Option gebaut und bekommt 2026 noch Bugfixes — sogar ein neues macOS-Backend entsteht. Deprecation/Entfernung ist derzeit **nicht** erkennbar.

---

## 1. Lokaler Check der Installation (read-only)

Ausgeführt per PowerShell (nur lesende Zugriffe, nichts verändert):

| Prüfung | Ergebnis |
|---|---|
| `C:\Program Files\VideoLAN\VLC\plugins\gui\libskins2_plugin.dll` | **existiert**, 2.349.976 Bytes, LastWrite 2025-12-31 [VERIFIED] |
| `C:\Program Files\VideoLAN\VLC\skins\` | **existiert** [VERIFIED] |
| Inhalt `skins\` | `default.vlt` (163.617 B), `skin.dtd` (10.662 B), `skin.catalog` (167 B), `winamp2.xml` (32.210 B), `fonts\FreeSans.ttf`, `fonts\FreeSansBold.ttf` [VERIFIED] |
| `%APPDATA%\vlc\skins` | **existiert nicht**; `%APPDATA%\vlc` enthält nur `vlcrc`, `vlc-qt-interface.ini`, `art`, `crashdump`, `ml.xspf` [VERIFIED] |
| `vlcrc` enthält aktuell keine `skins2-*`-Einträge (Skins-Interface nie benutzt) [VERIFIED] |
| VLC-Version | 3.0.23 [VERIFIED] |

**Bedeutung:** Das Plugin ist vorhanden; Skins müssen auf diesem System nach `C:\Program Files\VideoLAN\VLC\skins\` kopiert werden (die `%APPDATA%`-Konfigurationsordner werden von skins2 **nicht** gescannt, siehe §3.1). Die mitgelieferte `skin.dtd` ist die vollständige, autoritative Referenz („version 2.0“, erste Zeile) und wurde für diesen Bericht ausgelesen.

---

## 2. PRIORITÄT 1 — Capability-Verdicts (Code-basiert)

### 2.1 (a) Vollständige XML-Tag- und Attributliste des skins2-Parsers

Der Parser ist **handgeschrieben** (kein generisches XML-Dispatch): `handleBeginElement()` in `modules/gui/skins2/parser/skin_parser.cpp` behandelt exakt die unten gelisteten Elemente; die Datenstrukturen sind in `parser/builder_data.def` / `builder_data.hpp` generiert. Zusätzlich liegt die offizielle DTD in `share/skins2/skin.dtd` (identisch zur installierten `VLC\skins\skin.dtd`).
Quellen: https://code.videolan.org/videolan/vlc/-/blob/3.0.23/modules/gui/skins2/parser/skin_parser.cpp · https://code.videolan.org/videolan/vlc/-/blob/3.0.23/modules/gui/skins2/parser/builder_data.def · https://code.videolan.org/videolan/vlc/-/blob/3.0.23/share/skins2/skin.dtd

**Wichtig:** `Theme version` **muss** exakt `"2.0"` sein (`SKINS_DTD_VERSION` in `parser/xmlparser.hpp`), sonst lädt der Skin nicht: „bad theme version … (you need version 2.0)“ [VERIFIED].

| Tag | Attribute (fett = Pflicht) | Anmerkung |
|---|---|---|
| **Theme** | **version**, tooltipfont (`defaultfont`), magnet (15), alpha (255), movealpha (255) | Global; `alpha`/`movealpha` = Fenster-Gesamttransparenz, nur wenn Option `skins2-transparency` an ist [VERIFIED] |
| ThemeInfo | name, author, email, webpage | Wird nur geloggt [VERIFIED] |
| Include | **file** | Inkludiert weitere XML-Dateien (rekursiv), gleiche Skin-Daten [VERIFIED] |
| IniFile | **id**, **file** | Parst INI-Datei (v. a. Winamp2-Kompatibilität) [VERIFIED] |
| Bitmap | **id**, **file**, **alphacolor** (`#RRGGBB`), nbframes (1), fps (Default im Parser: 4, DTD: 0), loop (0=unendlich) | `nbframes`/`fps`/`loop` = **Animationsframes** (vertikal gestapelt) [VERIFIED] |
| SubBitmap | **id**, **x**, **y**, **width**, **height**, nbframes, fps, loop | Ausschnitt eines Bitmaps (Sprite-Sheets!) [VERIFIED] |
| BitmapFont | **id**, **file**, type (digits/text) | Winamp-artige Bitmap-Fonts (z. B. für Ziffernanzeigen) [VERIFIED] |
| Font | **id**, **file**, size (12) | TrueType via FreeType [VERIFIED] |
| PopupMenu | **id** | Skin-definiertes Kontextmenü [VERIFIED in DTD+Code; in der offiziellen „Create“-Doku nicht beschrieben → [UNCERTAIN] bzgl. Praxisreife] |
| MenuItem | **label**, action (none) | Eintrag im PopupMenu [VERIFIED] |
| MenuSeparator | — | Trenner [VERIFIED] |
| Window | id (none), visible (true), x, y, position, xoffset, yoffset, xmargin, ymargin, dragdrop (true), playondrop (true) | Mehrere Fenster erlaubt; Spezial-IDs: `playlist_window`, `fullscreenController` [VERIFIED] |
| Layout | **width**, **height**, id, minwidth/maxwidth/minheight/maxheight (−1) | Ein Fenster kann mehrere Layouts haben (Umschalten per Action) [VERIFIED] |
| Group | x, y | Nur Offset-Gruppe (deprecated zugunsten Panel) [VERIFIED] |
| Panel | **width**, **height**; x, y, lefttop, rightbottom, xkeepratio, ykeepratio, position, xoffset/yoffset/xmargin/ymargin | Container mit eigenem Bezugssystem; verschachtelbar [VERIFIED] |
| Anchor | **priority**; x, y, lefttop, points, range (10) | Magnetpunkte/Kurven zwischen Fenstern (Docking) + Screen-Magnetismus [VERIFIED] |
| Image | **image**; id, visible, x, y, width/height (−1), lefttop, rightbottom, xkeepratio, ykeepratio, action, action2, resize (mosaic), help, art (false) | `action` kann auch `move`, `resizeS`, `resizeE`, `resizeSE` sein; `action2` = Doppelklick; `art="true"` = Album-Cover! [VERIFIED] |
| Button | **up**; id, visible, x, y, lefttop, rightbottom, xkeepratio, ykeepratio, down, over, action, tooltiptext, help | up/down/over-Bitmaps [VERIFIED] |
| Checkbox | **up1**, **up2**, **state**; down1/over1/down2/over2, action1, action2, tooltiptext1/2, help | 2-Zustands-Schalter mit boolescher `state`-Expression [VERIFIED] |
| Slider | **up**, **points**; id, visible, x, y, width/height (−1), lefttop, rightbottom, xkeepratio, ykeepratio, down, over, thickness (10), value, tooltiptext, help | `points` = Bezier-Kurve für den Cursor! `value` = Prozent-Variable [VERIFIED] |
| SliderBackground | **image**; nbhoriz (1), nbvert (1), padhoriz/padvert (0) | Bildraster, Frame = f(Slider-Wert) [VERIFIED] |
| RadialSlider | **sequence**, **nbimages**; minangle (0), maxangle (360), value, tooltiptext, help | Runder Regler (Knob) aus Bildsequenz [VERIFIED] |
| Text | **font**; id, visible, x, y, width (0=auto), text, color, scrolling (auto/manual/none), alignment (left/center/right), focus (true), help | Dynamische `$`-Variablen in `text` (s. u.) [VERIFIED] |
| Playtree | **id**, **font**; flat (false), width/height, bgimage, itemimage, openimage, closedimage, fgcolor, playcolor, bgcolor1/2, selcolor, position, … | Playlist-Baum; **muss ein `<Slider>`-Kind enthalten** (Position) [VERIFIED] |
| Playlist | wie Playtree, aber flat-Default **true** | Älteres Alias für Playtree (laut Doku deprecated) [VERIFIED] |
| Video | id, visible, x, y, width/height, position, …, lefttop, rightbottom, xkeepratio, ykeepratio, **autoresize** (true), help | Eingebetteter Videobereich! [VERIFIED] |
| (kein Element) | — | **Es gibt KEIN `Animation`-Tag** für Control-Bewegungen; **kein `Balance`-Element**, **kein `Visualization`-Element**, **kein List-Tag** (s. u.) [VERIFIED] |

Ergänzende Parser-Fakten [VERIFIED]:

- **Maße**: Attribute akzeptieren Pixel (`"100"` bzw. `"100px"`) und **Prozent** (`"10%"`, relativ zum Container/Screen) — `getDimension()`.
- **Positionen**: `-1` (keine), `Center`, `North/South/West/East`, `NorthWest/NorthEast/SouthWest/SouthEast` — `getPosition()`/`convertPosition()`.
- **lefttop/rightbottom**: `lefttop`, `leftbottom`, `righttop`, `rightbottom` + `xkeepratio`/`ykeepratio` für Proportional-Resize.
- **IDs**: müssen eindeutig sein; Duplikate werden automatisch umbenannt („non-unique id“-Warnung). Reserviert: `none`.
- **Fehlende Pflichtattribute** ⇒ Fehler „bad theme (element: X, missing attribute: Y)“ und Abbruch des Skin-Ladens [VERIFIED].
- **Unbekannte Elemente**: werden vom SkinParser nicht behandelt (kein Fehlerpfad im Dispatch) — sie werden also ignoriert; weil aber die **DTD-Validierung aktiv** ist (`XML_PARSER_VALIDATE`/`XML_PARSER_DEFAULTATTRS` in `modules/misc/xml/libxml.c` + Katalog `skin.catalog`), können DTD-Verstöße Warnungen/Fehler im Log erzeugen. → Für uns gilt: **exakt an DTD 2.0 halten**. [VERIFIED für Validierungsflag; [UNCERTAIN], ob unbekannte Elemente das Laden hart abbrechen]
- **`<List>`-Tag**: existiert als Builder-Klasse (`addList`), aber **der Parser erzeugt nie List-Daten** (kein `handleBeginElement`-Zweig, kein DTD-Element) ⇒ faktisch toter Code, nicht benutzbar [VERIFIED].

### 2.2 (b) Slider-Bindings, Balance, Equalizer, Actions

**Prozent-Variablen für Slider/RadialSlider (`value`-Attribut)** — registriert in `src/vlcproc.cpp`:
Quelle: https://code.videolan.org/videolan/vlc/-/blob/3.0.23/modules/gui/skins2/src/vlcproc.cpp

| Variable | Typ | Bedeutung |
|---|---|---|
| `volume` | Volume | Lautstärke [VERIFIED] |
| `time` | StreamTime | Abspielposition (Seek) [VERIFIED] |
| `equalizer.preamp` | EqualizerPreamp | Vorverstärkung (−20…+20 dB als 0…100 %) [VERIFIED] |
| `equalizer.band(0)` … `equalizer.band(9)` | VarPercent | 10 EQ-Bänder: 60Hz, 170Hz, 310Hz, 600Hz, 1k, 3k, 6k, 12k, 14k, 16k [VERIFIED] |
| `playtree.slider` | VarPercent | Wird von einem `<Slider>` **innerhalb** von Playtree/Playlist automatisch gebunden [VERIFIED] |

**Balance: NICHT vorhanden.** [VERIFIED] Weder in der DTD noch in `builder_data.def` noch in den registrierten Variablen (`vars/` enthält nur `equalizer`, `playtree`, `time`, `volume`) noch in der Aktionsliste noch in der offiziellen Variablen-Doku existiert irgendein „balance“-Binding. Der VLC-Core kennt eine Aout-Balance, skins2 verdrahtet sie aber nicht.

**Equalizer: VOLL unterstützt.** [VERIFIED]
- Slider auf `equalizer.band(n)` schreibt `equalizer-bands` in Config + Audio-Output (`vars/equalizer.cpp`).
- `equalizer.preamp` analog (`equalizer-preamp`).
- Boolean `equalizer.isEnabled` für Checkbox-`state`.
- Actions `equalizer.enable()` / `equalizer.disable()` schalten den Audio-Filter `equalizer` via `playlist_EnableAudioFilter()` (`commands/cmd_audio.cpp`).
- Referenz: Das mitgelieferte `default.vlt` enthält ein komplettes EQ-Fenster (`<Window id="eqwin">`) mit Preamp + 10 Bändern [VERIFIED durch In-Memory-Inspektion des Archivs].

**Komplette Action-Liste** (aus `parser/interpreter.cpp`, Actions sind case-sensitiv, mehrere mit `;` kombinierbar) [VERIFIED]:
Quelle: https://code.videolan.org/videolan/vlc/-/blob/3.0.23/modules/gui/skins2/parser/interpreter.cpp

- `none`
- **Dialoge**: `dialogs.changeSkin()`, `dialogs.fileSimple()`, `dialogs.file()`, `dialogs.directory()`, `dialogs.disc()`, `dialogs.net()`, `dialogs.playlist()`, `dialogs.messages()`, `dialogs.prefs()`, `dialogs.fileInfo()`, `dialogs.streamingWizard()`, `dialogs.popup()`, `dialogs.audioPopup()`, `dialogs.videoPopup()`, `dialogs.miscPopup()`
- **DVD**: `dvd.nextTitle()`, `dvd.previousTitle()`, `dvd.nextChapter()`, `dvd.previousChapter()`, `dvd.rootMenu()`
- **Playlist**: `playlist.load()`, `playlist.save()`, `playlist.add()`, `playlist.next()`, `playlist.previous()`, `playlist.setRandom(true|false)`, `playlist.setLoop(true|false)`, `playlist.setRepeat(true|false)`, `playlist.del()`, `playtree.del()`, `playlist.sort()`, `playtree.sort()`
- **Player**: `vlc.fullscreen()`, `vlc.play()`, `vlc.pause()`, `vlc.stop()`, `vlc.faster()`, `vlc.slower()`, `vlc.mute()`, `vlc.volumeUp()`, `vlc.volumeDown()`, `vlc.minimize()`, `vlc.onTop()`, `vlc.snapshot()`, `vlc.toggleRecord()`, `vlc.nextFrame()`, `vlc.quit()`
- **Equalizer**: `equalizer.enable()`, `equalizer.disable()`
- **Dynamisch (Fenster/Layouts/Popups)**: `WindowID.show()`, `WindowID.hide()`, `WindowID.maximize()`, `WindowID.unmaximize()`, `WindowID.setLayout(LayoutID)`; `PopupID.show()` (PopupMenu per Action aufklappen; `.show()` prüft erst Fenster, dann Popup) [VERIFIED]
- Hinweis: Ein Play/Pause-**Toggle** ist nicht als Einzel-Action vorhanden; üblich sind zwei Buttons oder ein Checkbox mit `vlc.isPlaying`/`vlc.isPaused`. [VERIFIED]
- **Nicht vorhanden** (im gesamten Interpreter): `balance`, `equalizer`-Presets, `visualization`, `subtitle`-Kontrolle, `aspect`-Kontrolle, `zoom`. [VERIFIED]

**Boolean-Variablen für `visible`/`state`/`flat` (Ausdrücke mit `and`/`or`/`not` + Klammern)** [VERIFIED aus `vlcproc.cpp`, `window_manager.cpp`, `interpreter.cpp`]:
`true`, `false`, `playlist.isRandom`, `playlist.isLoop`, `playlist.isRepeat`, `playtree.isRandom`, `playtree.isLoop`, `playtree.isRepeat`, `vlc.isPlaying`, `vlc.isStopped`, `vlc.isPaused`, `vlc.isSeekable`, `vlc.canRecord`, `vlc.isRecording`, `vlc.isFullscreen`, `vlc.hasVout`, `vlc.hasAudio`, `vlc.isMute`, `vlc.isOnTop`, `dvd.isActive`, `equalizer.isEnabled`, `WindowID.isVisible`, `WindowID.isMaximized`, `LayoutID.isActive`.

**Text-/Tooltip-Substitution (`$`-Variablen)** — Implementierung `utils/var_text.cpp`, aktiv in `Text.text`, `tooltiptext*` und `help`: [VERIFIED]
`$T` aktuelle Zeit (H:MM:SS), `$t` kurz, `$L` Restzeit, `$l` kurz, `$D` Dauer, `$d` kurz, `$V` Volume in %, `$N` Streamname, `$F` Stream-URI, `$B` Bitrate, `$S` Samplerate, `$R` Wiedergabegeschwindigkeit, `$H` Hilfetext des Controls unter der Maus (aus dessen `help`-Attribut) — **der klassische Statusbar-Trick**: ein `<Text text="$H"/>` zeigt kontextabhängige Hilfe.
Quelle: https://code.videolan.org/videolan/vlc/-/blob/3.0.23/modules/gui/skins2/utils/var_text.cpp

### 2.3 (c) Visualisierungen (goom/projectM) und Video-Output

**Visualisierungen: vom Skin aus NICHT steuerbar** [VERIFIED].
- Es gibt im skins2-Interpreter **keine** Action und **keine** Variable für Visualisierungen (auch keine `vlc.visual()`, kein Menüpunkt). Die Visualisierung wird in VLC 3.0 über die Core-Variable `visual` am Audio-Output gesteuert (`src/audio_output/output.c`), die nur die Qt-Oberfläche (Menü „Visualisierungen“) anbietet. Ein Skin hat dafür keinen Zugang; selbst Tastenkürzel dafür existieren im Skins-Betrieb praktisch nicht (nur die Core-Hotkeys, und „Visualisierungen“ ist keiner).
- Technisch würden Visualisierungs-Plugins (`libgoom_plugin`, `libprojectm_plugin` …; Capability `"visualization"`, `modules/visualization/Makefile.am`) ihren eigenen Vout über `aout_filter_RequestVout()` anfordern. Ob dieser dann im `<Video>`-Control eines Skins landet oder als eigenes Fenster erscheint, hängt vom Vout-Window-Provider ab und ist nicht skin-seitig erzwingbar. **[UNCERTAIN]** — für den Port als „nicht verfügbar“ einplanen.

**Video-Output bei aktivem Skin: eingebettet möglich — mit Feinheiten** [VERIFIED]:
- skins2 registriert einen **„vout window“-Provider** (`modules/gui/skins2/src/skin_main.cpp`, `WindowOpen/WindowControl`). Ist `skinned-video` (Option „Display video in a skinned window“, Default **true**) aktiv und das Vout **nicht** „standalone“, liefert skins2 ein HWND-Kindfenster an den Vout (`VOUT_WINDOW_TYPE_HWND`).
- Das `<Video>`-Control (`controls/ctrl_video.cpp`) verwaltet dieses Kindfenster: Es wird als schwarzes Rechteck grundiert, bewegt/größer bei Layout-Resize, und bei `autoresize="true"` **passt es sogar das Layout an die Videogröße an** (zur Laufzeit). `autoresize` ist inkompatibel mit Resize-Policies → Builder erzwingt dann Warnung + `autoresize=false`.
- **Kein `<Video>`-Control im Skin** ⇒ für ältere Skins kann `skinned-video=no` gesetzt werden, dann bleibt der normale (nicht eingebettete) Video-Output erhalten (Optionstext: „give old skins a chance to play back video even though no video tag is implemented“). Bei Default `yes` und fehlendem Video-Control ist die Bildausgabe faktisch nicht darstellbar [VERIFIED Optionstext; Ableitung].
- Fullscreen/Standalone: `cfg->is_standalone` ⇒ skins2 lehnt ab (eigener Vout-Pfad). [VERIFIED `skin_main.cpp`]
- Relevanz für uns: `CtrlVideo` ist **nur sichtbar auf aktivem Layout eines sichtbaren Fensters und nicht im Fullscreen** (`isUseable()`); Video „verschwindet“ also in Layouts ohne Video-Control. [VERIFIED]

### 2.4 (d) Fenster: Form, Transparenz, Click-Through, Resize, Multi-Window, OnTop, Drag

**Irreguläre Fenster/Transparenz (Windows, `win32_graphics.cpp`/`win32_window.cpp`)** [VERIFIED]:
- Jedes `Bitmap` kann 32-bit Alpha (PNG) **und** eine `alphacolor` (#RRGGBB) als Transparenzfarbe verwenden — beides wird berücksichtigt.
- Beim Zeichnen baut skins2 aus allen Pixeln mit `alpha == 0` eine **Fenster-Region** (`CreateRectRgn` je Zeile) und ruft `SetWindowRgn(hWnd, mask, TRUE)` auf (`Win32Graphics::applyMaskToWindow`). Damit sind volltransparente Bereiche **außerhalb des Fensters**.
- **Click-Through: JA.** Da die Region-Bereiche nicht zum Fenster gehören, gehen Mausklicks dort an das darunterliegende Fenster/den Desktop (Windows-Semantik von `SetWindowRgn`). Teil-transparente Pixel (`0 < alpha < 255`) liegen **in** der Region und **fangen** weiterhin Mausereignisse. [VERIFIED Code; Windows-Klickverhalten technisch abgeleitet → [VERIFIED]]
- **Halbtransparenz:** Innerhalb des Skin-Fensters wird mit `AlphaBlend` in einen Offscreen-DC komponiert (weiche Kanten/Schatten funktionieren innerhalb des Skins). Gegen den **Desktop** wird nicht geblendet (BitBlt mit SRCCOPY). **Ganzfenster-Alpha** gibt es über `SetLayeredWindowAttributes(LWA_ALPHA)` — gesteuert von Theme-`alpha` / `movealpha` (während des Bewegens) — aber **nur wenn die Option `skins2-transparency` aktiviert ist** (Default in 3.0.23: **false**!); zusätzlich multipliziert die Qt-Option `qt-opacity`. Der in `default.vlt` gesetzte Wert `movealpha="200"` ist also ohne aktivierte Option wirkungslos. [VERIFIED]
- Darkstar-Beispiel: Der bekannte „Alienware Darkstar“-Skin (siehe §3.3) ist genau über diesen Mechanismus (Alpha-Bitmaps + Region) irregulär geformt.

**Runtime-Resize: JA** [VERIFIED]:
- `<Image action="move|resizeS|resizeE|resizeSE">` erzeugt `CtrlMove`/`CtrlResize`-Drag-Handles (Ecke/Seite ziehen) — `parser/builder.cpp` + `controls/ctrl_move.cpp`.
- Layouts haben `minwidth/maxwidth/minheight/maxheight`; `Anchor`-Punkte + `lefttop/rightbottom` + `xkeepratio/ykeepratio` steuern, was beim Resize mitwandert (Kaskade über mehrere Fenster); Fenster halten Abstand/Magnetismus (Theme-`magnet`, Default 15 px).
- Zusätzlich: `WindowID.maximize()`/`unmaximize()` + `WindowID.isMaximized`; **Video-Autoresize** kann die Layoutgröße an die Videoauflösung anpassen.
- Warnung des Builders bei inkonsistenter Resize-Policy: „pls, check resize policy for id: …“ (Nur-Fehlerlog, Control wird trotzdem gebaut). [VERIFIED]

**Mehrere Fenster: JA** [VERIFIED]:
- Beliebig viele `<Window>`-Tags; das mitgelieferte `default.vlt` hat **5 Fenster**: `main`, `eqwin` (Equalizer), `plwin` (Playlist), `aboutwin`, `fullscreenController` [VERIFIED per Archiv-Inspektion].
- Fenster können sich per `Anchor` verbinden/andocken; `WindowID.show()/hide()` blendet sie ein/aus; `skins2-config` speichert Positionen/Sichtbarkeit über Sitzungen (attribut `visible`/x/y nur beim ersten Start wirksam) [VERIFIED + Doku].
- Spezialfall: ein Fenster mit ID `playlist_window` wird bei `skinned-playlist=false` durch den **Qt-Playlist-Dialog** ersetzt (`interpreter.cpp`) [VERIFIED].

**Always-on-Top: JA** über Action `vlc.onTop()` (Toggle aller Skinfenster; `Win32Window::toggleOnTop` nutzt `HWND_TOPMOST/NOTOPMOST`) plus Boolean `vlc.isOnTop`. Zusätzlich kann der Vout-State `VOUT_WINDOW_STATE_ABOVE` gesetzt werden. [VERIFIED]

**Fenster-Drag: JA**, aber anzugeben: Ein `<Image action="move">` (typisch: Titelleiste/Hintergrundgrafik) implementiert das Verschieben per `CtrlMove` (`startMove`/`move`/`stopMove` inkl. Anchored-Windows und moveAlpha). Ohne solches Control lässt sich das (rahmenlose) Fenster nicht bewegen. [VERIFIED]

**Minimize/Close** [VERIFIED]: `vlc.minimize()` (alle Skinfenster via OSFactory), `vlc.quit()` (beendet VLC). Fenster-schließen = `WindowID.hide()`; es gibt keinen WM-Close-Button (Fenster sind `WS_POPUP`). Systray-Icon (`skins2-systray`, Windows-Default true) und Taskbar-Eintrag (`skins2-taskbar`) existieren.

**Fullscreen: JA** [VERIFIED]: `vlc.fullscreen()`; Status `vlc.isFullscreen`; zusätzlich das spezielle Fenster `fullscreenController`, das nur im Vollbild erscheint und per Hotkey **`i`** oder Mittelklick ein-/ausgeblendet wird (FSC-Fenster, `src/fsc_window.cpp`).

**Tooltips** [VERIFIED]: `tooltiptext`/`tooltiptext1/2` auf Button/Checkbox/Slider/RadialSlider; Anzeige nach **500 ms** Timer in einem eigenen Topmost-Fenster (`src/tooltip.cpp`, `win32/win32_tooltip.cpp`), Font = Theme-`tooltipfont` (TTF **oder** BitmapFont!). Tooltip-Texte unterstützen die `$`-Variablen (z. B. `tooltiptext="Volume: $V%"` — so im Default-Skin) ⇒ **dynamische Tooltips**.
**Tooltip-/Statusbar-Trick:** `help`-Attribut + `<Text text="$H">` ergibt eine kontextabhängige Statuszeile (Hover-Text des Controls unter der Maus). [VERIFIED]

### 2.5 (e) Playlist-Widget (Playtree/Playlist)

[VERIFIED außer wo markiert] Quelle: `controls/ctrl_tree.hpp`/`ctrl_tree.cpp`, `vars/playtree.*`, Doku.
- **Baum oder flach**: `flat="false"` = Ordner-/Knotenbaum (mit `openimage`/`closedimage`/`itemimage`), `flat="true"` = flache Liste (WMP9-artig).
- **Kein Spaltenmodell, keine Header, keine Sortier-/Filter-UI im Widget**; es gibt nur: Icon links, Textzeile, Farbe für normal/aktuell/Selektion, Zebra-Hintergrund (`bgcolor1/2`), optional `bgimage`.
- **Scrollen** integriert: Mausrad, Tasten (`UP/DOWN/PAGEUP/PAGEDOWN`), Klick in Liste; **kein sichtbarer Scrollbar-Balken** als Widget — man baut sich einen, indem man `Slider` als Kind des Playtree platziert (automatisch an `playtree.slider` gebunden) und daneben eigene Grafik/Buttons legt. Der Slider ist **zwingend** (“This tag must contain a Slider tag” laut Doku; Parser bindet den nächsten Slider automatisch).
- **Item-Höhe** = max(Font, Icons) + Zeilenabstand; Text wird bei Überbreite mit „...“ gekürzt.
- Playlist-Funktionen (nur per Actions, nicht per Rechtsklick-Kontextmenü im Widget — [UNCERTAIN], ob Kontextmenü existiert): `playlist.add/del/sort/next/previous`, `setRandom/setLoop/setRepeat`, Laden/Speichern.
- Das separate `<List>`-Tag ist **nicht implementiert** (toter Code; kein Parser-Zweig, kein DTD-Element) [VERIFIED].

---

## 3. PRIORITÄT 2 — Format & Tooling

### 3.1 (f) .vlt-Format, Laden, Speicherorte, Fehlerverhalten

**Wurzel-XML: `theme.xml`** [VERIFIED]: `#define DEFAULT_XML_FILE "theme.xml"` in `src/theme_loader.cpp`. Der Loader sucht **rekursiv** im Archiv nach der ersten `theme.xml`. (Falls keine `theme.xml`, aber eine `main.bmp` gefunden wird, wird eine **Winamp2-Skin** angenommen und `winamp2.xml` aus dem VLC-Resourcepfad als Theme verwendet! [VERIFIED])

**Archivformate** [VERIFIED]:
- `.vlt` ist **kein ZIP-Namenszwang**: Die mitgelieferte `C:\Program Files\VideoLAN\VLC\skins\default.vlt` ist eine **gzip/tar-Datei** (Magic `1F 8B`, TAR-Einträge inspiziert: `default/theme.xml`, PNGs, `font.otf`) — extrahiert wird über VLCs `vlc_stream_directory_Attach` (libarchive-basiert).
- Laut offizieller Doku sind seit VLC 0.8.5 **tar.gz und zip** zulässig; die Endung `.vlt` wird empfohlen (Skins-Dialog zeigt `.vlt`/`.xml`; zudem scannt der Skin-Browser nur `*.vlt`/`*.wsz`).
- Ein **entpacktes** Verzeichnis mit `theme.xml` direkt laden: geht nur über den Umweg „Datei = XML“ (der Loader akzeptiert auch eine direkt als XML geparste Datei) — praktisch nutzt man das Archiv. [VERIFIED Loader-Logik]

**Inhalt**: `theme.xml` (+optionale weitere XML via `<Include>`), Bilddateien (PNG empfohlen; „most common formats supported“ seit 0.8.5), `Font`-Dateien (TTF) und/oder `BitmapFont`-PNGs, ggf. INI (Winamp2). Pfade sind **relativ zur XML-Position**.

**Laden/Speicherort (Windows)** [VERIFIED]:
- VLC 3.0.23 erwartet zusätzliche Skins in **`<InstallDir>\skins\`** (`C:\Program Files\VideoLAN\VLC\skins`) — dieses Verzeichnis ist der Ressourcenpfad (`win32_factory.cpp`: `<datadir>\skins`, außerdem `<datadir>\skins2`, `<datadir>\share\skins`, `<datadir>\share\skins2`).
- `%APPDATA%\vlc\skins` wird **nicht** gescannt [VERIFIED: lokal nicht vorhanden; Code listet nur datadir-Pfade].
- Skins werden zur Laufzeit per `ThemeRepository` gescannt (`*.vlt`, `*.wsz`) und unter der Variable `intf-skins` („Select skin“) geführt; `skins2-last` (Konfig-Option, auch als **`--skins2-last=<pfad>`** auf der Kommandozeile) merkt den letzten Skin. Ist der gemerkte Skin nicht mehr zugänglich, springt sie auf den Skin namens **„Default“** (`default.vlt`) zurück. [VERIFIED `theme_repository.cpp`]
- Interface starten: Kommandozeile **`-I skins`** (Modulname `skins2`, Shortcut `skins`; Wiki nennt `-I skins2`) oder Preferences → Interface → „Use custom skin“ + **Neustart** (Moduswechsel Qt↔Skins erfordert Neustart). [VERIFIED skin_main.cpp add_shortcut + Doku „restart required“]
- **Skin-Wechsel ohne Neustart**: Rechtsklick im Skin → Interface → *Select skin*/*Open skin* bzw. Action `dialogs.changeSkin()`; `CmdChangeSkin` lädt das neue Theme live, restauriert bei Fehler das alte. [VERIFIED `cmd_change_skin.cpp`; Wiki bestätigt Rechtsklick-Menü]
- Weitere Optionen [VERIFIED `skin_main.cpp`]: `skins2-config` (Fensterpositionen, privat), `skins2-systray` (Win, Default true), `skins2-taskbar` (Win, true), `skins2-transparency` (Default **false** — s. o.), `skinned-playlist` (true), `skinned-video` (true).

**Fehlerverhalten** [VERIFIED]:
- Beim **Start**: Wenn weder `skins2-last` noch der Default (`default.vlt`) ladbar ist, beendet VLC sich selbst („no skins found : exiting“).
- Beim **Skin-Wechsel zur Laufzeit**: Fehler ⇒ altes Theme wird restauriert; existiert keins, beendet VLC sich.
- Parse-Fehler einzelner Elemente: „bad theme (element: …)“-Fehler ⇒ Ladefehler; fehlende optionale Controls/Fonts führen zu Warnungen und werden übersprungen (z. B. „unknown font id“, „unknown slider value“).
- Es wird **nicht** in Windows-Registry o. ä. geschrieben; Config liegt in `%APPDATA%\vlc\vlcrc` (`skins2-last`, `skins2-config`).

### 3.2 (g) VLC Skin Editor, Doku, Tutorials

- **Offizielle Doku (Bounty-Link)** — https://vlc-user-documentation.readthedocs.io/en/latest/addons/skins.html: Skins-Liste verlinkt auf https://www.videolan.org/vlc/skins.php; Sammel-Download `vlc-skins.zip`; Windows-Ordner `C:\Program Files\VideoLAN\VLC\skins`, Linux `~/.local/share/vlc/skins2`, **macOS nicht unterstützt**; Aktivierung über Preferences → Interface („Use custom skin“) und **Neustart**; Verweis auf Skin Editor und `skins2-create.html`. [VERIFIED]
- **VideoLAN-Wiki** — https://wiki.videolan.org/Skins/: zusätzlich `vlc -I skins2`; Rechtsklick im Skin → *Interface → Select skin / Open skin*; Notfall-Rückkehr via `vlc -I qt` bzw. Windows-Startmenü „Quick Settings → Interface“; Hinweis „Not all skins are fully functional“; Fullscreen-Controller seit VLC 1.1. [VERIFIED]
- **Offizielle Skin-Doku „HowTo create your own skin“** — https://www.videolan.org/vlc/skins2-create.html (Olivier Teulière, 2004–2013): beschreibt Tags, Actions, `$`-Variablen, Boolean-Ausdrücke, Prozent-Variablen, Layout-Modell (Anchors/keepratio), Bezier-Kurven, Kompression; verweist auf die DTD („A skin that does not follow the DTD … won't be loaded“). Große Teile dieses Berichts decken sich mit dieser Doku; die Doku entspricht dem Code-Stand 3.0.x (Balancing fehlt auch hier — konsistent). [VERIFIED]
- **VLC Skin Editor** — https://www.videolan.org/vlc/skineditor.html: WYSIWYG-Editor (Java), **letzter Build 0.8.5** unter http://get.videolan.org/skin-editor/0.8.5/ (JRE ≥ 6!), Features: kein XML-Wissen nötig, VLT Import/Export, SubBitmap-Hilfe, Vorschau. **Status: seit Jahren unmaintained** (Build 0.8.5; Quellcode-Repo https://code.videolan.org/videolan/skin-designer). [VERIFIED Doku; [UNCERTAIN] ob Binaries auf modernem JRE laufen]
- **Bezugsquellen/Tutorials**: skins-Forum (https://forum.videolan.org/viewforum.php?f=15), Skins-Galerie mit Sortierung/Rating (https://www.videolan.org/vlc/skins.php), Addons-Seite (https://addons.videolan.org/). Für tiefe Arbeit ist die DTD selbst die beste Referenz (lokal: `C:\Program Files\VideoLAN\VLC\skins\skin.dtd`).

### 3.3 (h) Beispiel-Skins (komplex/irregulär) mit Download-URLs

Alle Einzel-Downloads folgen dem Muster `https://www.videolan.org/vlc/download-skins2-go.php?url=<Dateiname>` (aus `skins.php` + `js/skins.js` verifiziert; Beispiel-URL liefert HTTP 200). Metadaten aus den `showSkinBox(...)`-Aufrufen der Galerie [VERIFIED]:

| Skin | Autor/Jahr | URL | Technisch |
|---|---|---|---|
| **Alienware Darkstar** | Universematrix, 2010 | https://www.videolan.org/vlc/download-skins2-go.php?url=Alienware%20Darkstar.vlt (534 KiB, benötigt VLC ≥ 0.9.0) | **Irreguläre Alien-Form** — Paradebeispiel für per-Pixel-Transparenz + Fensterregion (§2.4); komplexes Button-/Animation-Set. [VERIFIED Existenz; Form-Eigenschaft aus Screenshot/Titel → [UNCERTAIN] im Detail] |
| **WMP11_B — resizable and with total time** | ANGEL_B, 2010 | https://www.videolan.org/vlc/download-skins2-go.php?url=WMP_B_2.vlt (187 KiB) | Explizit **resizable**: nutzt `resizeS/E/SE`, Anchors, `minwidth/maxwidth`; „total time“ = `$D`/`$T`-Textvariablen. Direkt relevant als WMP-Port-Referenz. [VERIFIED Metadaten] |
| **WinampModern** | Sliper, 2009 | https://www.videolan.org/vlc/download-skins2-go.php?url=Modern.vlt (123 KiB) | Winamp-Modern-Look: BitmapFont(s), RadialSlider/Animationen, Multi-Window. [VERIFIED Metadaten] |
| **Media Player 12 (WMP12-Look)** | sebweber, 2010 | https://www.videolan.org/vlc/download-skins2-go.php?url=windows_media_player_12.vlt (447 KiB) | Umfangreichster WMP-Look; zeigt, wie weit WMP-Optik in skins2 getrieben wurde (große Button-/Slider-Sets, Library-Fenster). [VERIFIED Metadaten] |
| **LCARSx32_Standard** | Sara Miller, 2009 | https://www.videolan.org/vlc/download-skins2-go.php?url=LCARSx32.vlt (68 KiB) | Star-Trek-LCARS, stark irreguläre Panels/Farben. [VERIFIED Metadaten] |
| Referenz | VideoLAN | **`default.vlt` bereits im Installationsordner** (163 KiB, tar.gz) | 5 Fenster (main/eqwin/plwin/aboutwin/fullscreenController), kompletter EQ, Volume/Seek-Slider, `$T/$D/$N`-Textvariablen, Tooltips `Volume: $V%`, Fullscreen-Controller — **die wichtigste praktische Referenz für den Port**. [VERIFIED durch Inspektion] |
| Alle | — | https://www.videolan.org/vlc/download-skins2-go.php?url=vlc-skins.zip (37 MiB, ~1050 Zeilen Galerie) | Sammelpack. [VERIFIED] |

Bonus: skins2 lädt auch **klassische Winamp-2-Skins** (`*.wsz` oder `main.bmp` + `winamp2.xml`) [VERIFIED `theme_loader.cpp`, `theme_repository.cpp`] — für einen WMP9-Port irrelevant, aber nützliches Kompatibilitäts-Feature.

---

## 4. PRIORITÄT 3 — Status von skins2 in VLC 4.x (Stand 2026-10)

- **Vorhanden und gepflegt:** Der Branch `master` (VLC 4.0-Entwicklung) enthält `modules/gui/skins2` weiterhin — inzwischen mit zusätzlichem **`macosx/`-Backend** (Objective-C++: `macosx_window.mm`, `macosx_graphics.mm`, …) neben win32/x11/os2. [VERIFIED: https://code.videolan.org/videolan/vlc/-/tree/master/modules/gui/skins2]
- **Baubar per Meson-Option `skins2`** (`modules/gui/skins2/meson.build`, Option `skins2`, Default auto: auf Windows/macOS/X11 möglich; benötigt FreeType, optional Fribidi/HarfBuzz für Textshaping). [VERIFIED: https://code.videolan.org/videolan/vlc/-/blob/master/modules/gui/skins2/meson.build]
- **Aktive Wartung 2026:** offene Skins2-Issues aus 2026 (z. B. #30199 „Skins2 maximized window ignores desktop work area…“, #29931–#29933 Crash-/Fuzz-Reports, #26906 „4.0 regression: skins2 triggers a bogus Qt interface on wayland“) belegen Bugfix-Betrieb, **keine** Deprecation. [VERIFIED: https://code.videolan.org/videolan/vlc/-/issues/30199]
- **Keine öffentlichen Entfernungs-/Deprecation-Pläne gefunden.** Die Qt-Oberfläche wird in 4.x auf QML umgestellt; ein **generelles QML-Theming als offizieller Skins-Ersatz ist nicht vorgesehen** — Qt-QML ist Customizing auf Theme-Farben beschränkt, nicht auf frei geformte Fenster/Skins. [UNCERTAIN: keine Roadmap-Notiz explizit; abgeleitet aus Fehlen von Ankündigungen + fortgesetzter Pflege]
- **Stabil bleibt 3.0.x**: Die offizielle Downloadseite verteilt weiterhin **3.0.24** (Stand 2026-10), VLC 4.0 ist noch nicht veröffentlicht. [VERIFIED: https://www.videolan.org/vlc/]
- **Konsequenz für den Port:** Auf **3.0.x/skins2** entwickeln (identisch zu 3.0.23). 4.x wird skins2 voraussichtlich weiter unterstützen; DTD 2.0 bleibt die gemeinsame Basis. Risiko: 4.0-Builds erfordern `skin2`-Option explizit und es gibt offene 4.0-Regressions-Issues. [VERIFIED Issues]

---

## 5. Capability-Verdict-Tabelle (Master)

**Legende:** ✅ möglich · ⚠️ teilweise/eingeschränkt · ❌ nicht möglich · **Belege** = Code/Doku-Kurzreferenz (Details §2/§3).

| Feature | Verdict | Beleg (Quelle/Code) | Anmerkung |
|---|---|---|---|
| Play / Pause | ✅ | `interpreter.cpp` Actions `vlc.play()`, `vlc.pause()`; States `vlc.isPlaying/isPaused` | Kein Einzel-Toggle; mit 2 Buttons/Checkbox nachbauen |
| Stop | ✅ | `vlc.stop()`, `vlc.isStopped` | s. o. |
| Next / Prev | ✅ | `playlist.next()`, `playlist.previous()` | Playlist-Actions (Interpreter) |
| Seek | ✅ | Slider `value="time"`; `StreamTime` in `vars/time.{hpp,cpp}`; `vlc.isSeekable` | Bezier-`points` erlaubt auch kreisrunde Seeker |
| Volume | ✅ | Slider `value="volume"`; `vars/volume.hpp`; `$V` | Steps/Mute über `vlc.mute()`, `vlc.volumeUp/Down()` |
| **Balance** | ❌ | Fehlt in DTD, `builder_data.def`, Variablen-Registrierung, Doku | Kein Var, kein Slider-Typ, keine Action |
| **Equalizer** | ✅ | `equalizer.band(0..9)`, `equalizer.preamp`, `equalizer.isEnabled`, `equalizer.enable()/disable()`; `vars/equalizer.cpp`; `cmd_audio.cpp` | Komplette 10-Band-UI möglich (Default-Skin zeigt es); wirkt, wenn Filter aktiv |
| Playlist | ⚠️ | `Playtree` (+`Slider`-Kind, `flat`); `ctrl_tree.cpp` | Baum/flach, keine Spalten; „Scrollbar“ nur selbstgebaut; `<List>` tot |
| Video-Einbettung | ✅ | `<Video>`, vout-Provider in `skin_main.cpp`, `ctrl_video.cpp`, `vout_manager.cpp` | `skinned-video` (Default an); `autoresize` passt Layout an; standalone/Fullscreen nicht eingebettet |
| Visualisierungen (goom/projectM) | ❌ | Keine Action/Var in `interpreter.cpp`/`vlcproc.cpp`; Core-`visual` nur Qt | Vom Skin nicht umschaltbar; Einbettung [UNCERTAIN] |
| Animation / Slides | ⚠️ | `Bitmap`/`SubBitmap` `nbframes`/`fps`/`loop`; `anim_bitmap.cpp` | Bilder-Animationen (Frames vertikal) ja — **keine** Control-Bewegungs-/Pfadanimation; `loop=0` endlos, sonst Stopp auf letztem Frame |
| Tooltips | ✅ | `tooltiptext*`-Attribute; `tooltip.cpp` (500 ms); `tooltipfont` | Eigene Tooltip-Fenster; dynamische `$`-Variablen erlaubt („Volume: $V%“) |
| Tooltip-/Statusbar-Trick | ✅ | `$H` + `help`-Attribut; `var_text.cpp` | `<Text text="$H">` = kontextabhängige Statuszeile; gute WMP9-Parität |
| Fensterform / Transparenz | ⚠️ | Alpha-Bitmaps + `alphacolor`; `SetWindowRgn`-Maske; `alpha`/`movealpha` + Option `skins2-transparency` | Pixelgenaue **binäre** Form ja; gegen Desktop **kein** Alpha-Blend; Ganzfenster-Alpha nur mit Option (Default aus!), Multiplikator `qt-opacity` |
| Click-Through | ✅ | Region = nur Alpha>0-Pixel (`win32_graphics.cpp`) → Bereiche außerhalb fangen keine Maus | Windows-Standardverhalten; halbtransparente Pixel fangen Maus weiter |
| Runtime-Resize | ✅ | `Image action="resizeS/E/SE"`; `ctrl_resize.cpp`; `Layout min/max`; `Anchor`; `xkeepratio`; `maximize()` | Auch Video-`autoresize`; Fenster-Kaskade via Anchors |
| Multi-Window | ✅ | Mehrere `<Window>`; `default.vlt` = 5 Fenster; `WindowID.show()/hide()` | EQ-/Playlist-Fenster portierbar; `playlist_window`-Spezialfall (Qt-Dialog) |
| Always-on-Top | ✅ | `vlc.onTop()` (→ `toggleOnTop`), `vlc.isOnTop` | Global für alle Skinfenster |
| Minimize / Close | ✅ | `vlc.minimize()` (`cmd_minimize.cpp`), `vlc.quit()`, `hide()` | Kein echtes Fenster-„Schließen“ (rahmenlos); Systray/Taskbar-Optionen |
| Fullscreen | ✅ | `vlc.fullscreen()`, `vlc.isFullscreen`, `fullscreenController`-Fenster („i“/Mittelklick) | FSC-Fenster nur im Vollbild |
| Font / Schrift | ✅ | `Font` (TTF via FreeType, `ft2_font.cpp`); `BitmapFont` (digits/text) | Schriften im Archiv; Shaping in 4.x optional Fribidi/HarfBuzz |
| *(Zusatz)* Drag & Drop Dateien | ✅ | `Window dragdrop/playondrop` | `win32_dragdrop.cpp` |
| *(Zusatz)* Album-Cover | ✅ | `<Image art="true">` + `art_manager.cpp` | Lädt Stream-Art als Bitmap |
| *(Zusatz)* Kontextmenüs | ⚠️ | Rechtsklick auf `Image` → `dialogs.popup()` (`ctrl_image.cpp`); `PopupMenu`/`MenuItem` + `PopupID.show()` | Skin-eigene Popups sind in DTD/Code, aber kaum dokumentiert |
| *(Zusatz)* Snapshots/Record/Frame-Step | ✅ | `vlc.snapshot()`, `vlc.toggleRecord()`, `vlc.nextFrame()` | Core-Funktionen |
| *(Zusatz)* DVD-Navigation | ✅ | `dvd.*`-Actions + `dvd.isActive` | Menüs für DVD-Skins |
| *(Zusatz)* Untertitel-/Spurauswahl | ❌ | Keine Actions in `interpreter.cpp` (nur Core-Hotkeys) | Nur über Tastatur/Prefs, nicht skinbar |

---

## 6. Konkrete Empfehlungen für den Headspace-Port

1. **Ziel festlegen:** Gegen **VLC 3.0.x/skins2** entwickeln (3.0.23/3.0.24 identisch relevant). 4.x abwarten, aber Code so halten, dass er DTD-2.0-konform bleibt (läuft dann auch in 4.x).
2. **Struktur:** Wurzel-XML heißt **`theme.xml`** mit `<Theme version="2.0" …>`. Wenn das entpackte Headspace-Paket `skin.xml` o. ä. heißt: umbenennen. Alle Pfade relativ; Assets ins Archiv (`.vlt` = tar.gz oder zip); optional große Teile per `<Include file="…">` splitten.
3. **Bilder:** PNG 32-bit mit sauberem Alpha; **zusätzlich `alphacolor` setzen** (WMP9-Skins nutzen meist Magenta `#FF00FF`) — das Attribut ist in 3.0 Pflicht. Große WMP9-Sprite-Sheets 1:1 als `Bitmap` + viele `SubBitmap` abbilden.
4. **Interaktion:** Buttons mit `up/down/over` (WMP9-Hover-Optik); Toggles (z. B. Shuffle/Loop/Mute/EQ an/aus) als `Checkbox` mit `state="…"` + `action1/action2`.
5. **Slider:** Seek=`value="time"`, Volume=`value="volume"`, EQ=`equalizer.band(n)`/`preamp`; für WMP9-Optik `SliderBackground` (Frame je Wert) nutzen; Radiale Regler (falls im Skin) als `RadialSlider`.
6. **Balance weglassen oder als Deko konvertieren** — technisch nicht anbindbar. Optionen: Mute-/Volume-Regler dort platzieren oder das Element statisch machen (dann aber keine falsche Funktion suggerieren).
7. **Equalizer-Fenster voll portieren**: 10 Bänder + Preamp als Slider, Enable-Checkbox mit `equalizer.isEnabled` + `enable()/disable()`.
8. **Playlist als `Playtree flat="true"`** mit `Slider`-Kind + eigenen Scroll-Buttons/Grafik; Titel-/Zeitspalten gibt es nicht — im Zweifel per Tooltip/Statusbar (`$N/$T`) abfedern.
9. **Fenster-Set:** Main-/Playlist-/EQ-Fenster als separate `<Window>`; Andocken/Magnetismus via `Anchor` (priorities!) und `magnet` im Theme; Positionen merkt sich VLC selbst.
10. **Titelleiste:** `<Image action="move">` fürs Ziehen, `<Image action="resizeSE">`-Ecken fürs Skalieren; `minwidth/maxwidth` setzen.
11. **Statusbar/Ticker:** `<Text text="$N" scrolling="auto">`, Zeitanzeige `text="$T / $D"`, Hover-Hilfe `text="$H"` + `help`-Attribute — deckt den WMP9-Statusbereich ab.
12. **Tooltips:** `tooltiptext` mit `$`-Variablen dynamisch halten; Theme-`tooltipfont` nicht vergessen (Default `defaultfont`).
13. **Video:** `<Video>`-Control für den WMP9-Videobereich einplanen; `autoresize` bewusst setzen (Achtung: schließt Resize-Policy aus).
14. **Testen/Diagnose:** Skins in `C:\Program Files\VideoLAN\VLC\skins` kopieren (Admin) oder „Open skin…“; VLC mit `-vvv` starten und Log auf „bad theme“, „unknown action“, „pls, check resize policy“, „non-unique id“ prüfen. Option `skins2-transparency` für `alpha/movealpha` aktivieren. Bei Problemen `vlc -I qt` bzw. Startmenü-Quick-Settings.
15. **Aufwand-Risiken:** (a) fehlende Balance, (b) Visualisierungen, (c) keine Control-Bewegungsanimationen — WMP9-„Slides“ ggf. als Frame-Animation eines Bitmaps nachempfinden; (d) komplexe WMP9-Masken müssen als binäre Alpha-Form gebaut werden (keine weichen Desktop-Schatten außerhalb des Skins).

---

## 7. Quellenverzeichnis (Auswahl, alle abgerufen 2026-10-13)

**Code (VLC 3.0.23):**
- Modul-Übersicht: https://code.videolan.org/videolan/vlc/-/tree/3.0.23/modules/gui/skins2
- DTD (Source): https://code.videolan.org/videolan/vlc/-/blob/3.0.23/share/skins2/skin.dtd
- `parser/skin_parser.cpp` · `parser/builder_data.def` · `parser/xmlparser.{hpp,cpp}` · `parser/builder.cpp` · `parser/interpreter.cpp`
- `src/theme_loader.cpp` · `src/theme_repository.cpp` · `src/vlcproc.cpp` · `src/window_manager.cpp` · `src/tooltip.cpp` · `src/var_manager.cpp` · `src/skin_main.cpp` · `src/vout_manager.cpp` · `src/anim_bitmap.cpp`
- `vars/equalizer.{hpp,cpp}` · `vars/volume.hpp` · `vars/time.{hpp,cpp}` · `utils/var_text.{hpp,cpp}`
- `controls/ctrl_video.cpp` · `controls/ctrl_tree.{hpp,cpp}` · `controls/ctrl_move.cpp` · `controls/ctrl_image.cpp` · `controls/ctrl_text.cpp`
- `win32/win32_window.cpp` · `win32/win32_graphics.cpp` · `win32/win32_loop.cpp` · `win32/win32_factory.cpp`
- Core: `include/vlc_actions.h` · `modules/misc/xml/libxml.c` · `src/audio_output/output.c` · `modules/visualization/Makefile.am`
- 4.x: https://code.videolan.org/videolan/vlc/-/tree/master/modules/gui/skins2 · `meson.build` · Issues: https://code.videolan.org/videolan/vlc/-/issues/30199

**Doku/Websites:**
- https://vlc-user-documentation.readthedocs.io/en/latest/addons/skins.html
- https://wiki.videolan.org/Skins/
- https://www.videolan.org/vlc/skins2-create.html
- https://www.videolan.org/vlc/skineditor.html · http://get.videolan.org/skin-editor/0.8.5/ · https://code.videolan.org/videolan/skin-designer
- https://www.videolan.org/vlc/skins.php · https://www.videolan.org/vlc/download-skins2-go.php?url=vlc-skins.zip
- https://www.videolan.org/vlc/ (Versionsstand 3.0.24)

**Lokale Artefakte (read-only geprüft):** `C:\Program Files\VideoLAN\VLC\skins\skin.dtd`, `…\skins\default.vlt` (In-Memory-Inspektion), `…\skins\skin.catalog`, `…\plugins\gui\libskins2_plugin.dll`.

---

## 8. ZUSAMMENFASSUNG

Der Rechercheauftrag ist abgeschlossen. skins2 in VLC 3.0.23 ist ein mächtiges, vollständig XML-definiertes UI-System (DTD-Version 2.0, Pflicht), dessen Fähigkeiten weit über einfaches Theming hinausgehen. Für den Headspace-Port zentral: Der Skin kann Play/Pause/Stop/Next/Prev, Seek, Volume, DVD-Navigation, Snapshots, Recording, Frame-Step, Multi-Window-Management, Fullscreen inkl. Fullscreen-Controller, Tooltips mit dynamischen Variablen, Drag&Drop, Album-Art und komplett den 10-Band-Equalizer steuern. Fenster können beliebige, per Alpha-Maske ausgeschnittene Formen annehmen; transparente Pixel sind auf Windows echte Click-Through-Zonen (Fensterregion). Fenster lassen sich zur Laufzeit per Drag-Handles (resizeS/E/SE) skalieren, per Anchors andocken und immer-im-Vordergrund schalten. Die Playlist ist als Baum oder flache Liste (Playtree, flat) mit selbstgebautem Slider darstellbar.

Die drei wichtigsten Einschränkungen: **kein Balance-Widget** (nirgends im Code/DTD), **keine Steuerung von Visualisierungen** (goom/projectM nur über Qt/Core), und **keine Control-Bewegungsanimation** — Animationen gibt es nur als vertikale Bitmap-Frames (nbframes/fps/loop). Außerdem färbt WMP9-üblich „Balance“-Regler: diese müssen entfallen oder umgewidmet werden.

Formatseitig ist entscheidend: Wurzel-XML **theme.xml** (rekursiv gesucht; NICHT skin.xml), Archiv `.vlt` als tar.gz oder zip (Default-Skin ist tar.gz), Ablage unter `C:\Program Files\VideoLAN\VLC\skins`, Start mit `-I skins`, Laden/Wechseln ohne Neustart per „Open skin…“, Fehlerfall mit Fallback auf default.vlt bzw. Theme-Rollback.

Doku und Tooling sind brauchbar, aber alt: die offizielle Skins2-Doku (videolan.org/vlc/skins2-create.html), Wiki und readthedocs decken die Kernfeatures; der Java-Skin-Editor (0.8.5) ist unmaintained — für den Port ist die DTD selbst (lokal vorhanden) plus der mitgelieferte `default.vlt` als Muster die beste Grundlage. VLC 4.x behält skins2 (master: eigenes Meson-Option, aktive Fixes, neues macOS-Backend), es gibt keine Deprecation-Anzeichen; stabil ist weiterhin 3.0.24, sodass die Portierung gefahrlos auf 3.0.x erfolgen kann.
