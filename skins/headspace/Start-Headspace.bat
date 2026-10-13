@echo off
rem Headspace fuer VLC - Standard-Starter:
rem   2x-Skin, Equalizer aktiv, goom-Visualizer, saubere Playlist
rem   + Screen-Maske: tools\vout_mask.ps1 schneidet das Video-Fenster auf die
rem     runde Screen-Form zu und zieht die schwarzen Eck-Zipfel des skins2-
rem     Backdrops aus der Fenster-Region (der Skin kann das nicht selbst).
start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0..\..\tools\vout_mask.ps1"
rem Startlayout auf geschlossene Ohren (l_closed) setzen - skins2 merkt sich das Layout im vlcrc
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0..\..\tools\set_start_layout.ps1" -Layout l_closed -Width 1098 -Height 788
start "" "C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins --skins2-last="%~dp0..\..\dist\Headspace-2x.vlt" --audio-filter=equalizer --audio-visual=goom --no-media-library --no-video-title-show --crop=214:140
