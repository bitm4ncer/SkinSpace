@echo off
rem Headspace fuer VLC - Standard-Starter:
rem   2x-Skin, Equalizer aktiv, goom-Visualizer, saubere Playlist
rem   + Screen-Maske: tools\vout_mask.ps1 schneidet das Video-Fenster auf die
rem     runde Screen-Form zu und zieht die schwarzen Eck-Zipfel des skins2-
rem     Backdrops aus der Fenster-Region (der Skin kann das nicht selbst).
start "" powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0..\..\tools\vout_mask.ps1"
start "" "C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins --skins2-last="%~dp0..\..\dist\Headspace-2x.vlt" --audio-filter=equalizer --audio-visual=goom --no-media-library --no-video-title-show
