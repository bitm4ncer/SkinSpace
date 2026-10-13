@echo off
rem Headspace fuer VLC - Starter MIT Visualizer im Kopf-Screen
rem Nutzt goom (per CLI zuverlaessig). Achtung: "projectm"/"glspectrum" werden von
rem VLCs audio-visual-Validierung per CLI stillschweigend verworfen - die nur
rem zur Laufzeit ueber das VLC-Menue waehlen.
start "" "C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins --skins2-last="%~dp0..\..\dist\Headspace-2x.vlt" --audio-visual=goom --no-media-library --no-video-title-show
