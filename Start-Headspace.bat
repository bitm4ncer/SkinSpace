@echo off
rem Headspace fuer VLC - Starter (2x-Version, saubere Playlist ohne Mediathek-Knoten)
start "" "C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins --skins2-last="%~dp0dist\Headspace-2x.vlt" --no-media-library --no-video-title-show
