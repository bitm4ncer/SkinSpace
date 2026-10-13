@echo off
rem Headspace fuer VLC - Starter MIT Visualizer im Kopf-Screen (projectM)
rem Alternative Visualizer: einfach "projectm" durch "goom" ersetzen
start "" "C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins --skins2-last="%~dp0..\..\dist\Headspace-2x.vlt" --audio-visual=projectm --no-media-library --no-video-title-show
