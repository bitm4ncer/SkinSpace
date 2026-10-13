@echo off
rem Headspace fuer VLC - Starter (2x-Version, Equalizer aktiv, saubere Playlist ohne Mediathek-Knoten)
start "" "C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins --skins2-last="%~dp0dist\Headspace-2x.vlt" --audio-filter=equalizer --no-media-library --no-video-title-show
