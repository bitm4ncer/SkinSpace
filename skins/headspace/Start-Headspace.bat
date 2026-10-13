@echo off
rem Headspace fuer VLC - Standard-Starter: 2x-Skin, Equalizer aktiv, goom-Visualizer, saubere Playlist
rem Hinweis: "projectm"/"glspectrum" verwirft VLCs CLI-Validierung stillschweigend - die nur
rem zur Laufzeit ueber das VLC-Menue waehlen.
start "" "C:\Program Files\VideoLAN\VLC\vlc.exe" -I skins --skins2-last="%~dp0..\..\dist\Headspace-2x.vlt" --audio-filter=equalizer --audio-visual=goom --no-media-library --no-video-title-show
