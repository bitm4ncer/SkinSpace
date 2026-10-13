# run_task6.ps1 - Task-6-Suite v2: Screen/Video klickfrei + Fehlerfaelle (Log-/Shot-Pfade sauber, Logfile gequotet)
$root = 'C:\GitHub\VLC_Skins'
$tmp = "$root\tools\tmp"
$fail = 0

& 'C:\Program Files\ffmpeg\bin\ffmpeg.exe' -y -hide_banner -loglevel error -f lavfi -i "testsrc2=size=320x240:rate=30" -t 8 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$tmp\clip43.mp4"
& 'C:\Program Files\ffmpeg\bin\ffmpeg.exe' -y -hide_banner -loglevel error -f lavfi -i "testsrc2=size=240x320:rate=30" -t 8 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$tmp\clipport.mp4"

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$root\tools\build_theme.ps1" -Scale 1 | Out-Null
if($LASTEXITCODE -ne 0){ $fail = 1; Write-Host 'FAIL: build_theme' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$root\tools\pack.ps1" | Out-Null
if($LASTEXITCODE -ne 0){ $fail = 1; Write-Host 'FAIL: pack' }

. "$root\research\spike\winhelp.ps1"
$vlcrc = "$env:APPDATA\vlc\vlcrc"
Copy-Item $vlcrc "$tmp\vlcrc.task6_backup" -Force

function Test-Skin([string]$layout, [int]$w, [string]$media, [string]$shot, [string]$label){
  $slug = $label -replace '[ :]','_'
  $cfg = (Get-Content "$tmp\vlcrc.task6_backup") | Where-Object { $_ -notmatch '^skins2-(last|config)=' }
  $cfg += ('skins2-config=["main" "{0}" 40 40 {1} 394 1]' -f $layout, $w)
  Set-Content $vlcrc $cfg
  Remove-Item "$env:APPDATA\vlc\crashdump" -Recurse -Force -ErrorAction SilentlyContinue
  $log = "$tmp\vlc_task6_$slug.log"
  $argsL = @('-I','skins',('--skins2-last="{0}"' -f "$root\dist\Headspace.vlt"),'--no-video-title-show','--file-logging',('--logfile="{0}"' -f $log),'-vvv')
  if($media -ne ''){ $argsL += ('"' + $media + '"') }
  $p = Start-Process 'C:\Program Files\VideoLAN\VLC\vlc.exe' -ArgumentList $argsL -PassThru
  $win=$null
  for($i=0; $i -lt 25; $i++){ Start-Sleep -Milliseconds 900; $win = Get-VlcWin $p.Id | Where-Object { $_.W -eq $w } | Select-Object -First 1; if($win){ break } }
  $r = 'FAIL(kein Fenster)'
  if($win){
    Start-Sleep -Seconds 3
    Capture-Win $win.Hwnd $shot | Out-Null
    $hits = @(Select-String -Path $log -Pattern 'bad theme|unknown action|non-unique' -ErrorAction SilentlyContinue)
    if($hits.Count -eq 0){ $r = 'OK' } else { $r = 'FAIL(Log)'; $hits | Select-Object -First 3 | ForEach-Object { Write-Host "  LOGHIT: $($_.Line)" } }
  }
  Get-Process -Id $p.Id -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep -Milliseconds 700
  Write-Host "$label : $r"
  if($r -ne 'OK'){ $script:fail = 1 }
}

Test-Skin 'l_closed' 549 "$root\research\spike\media\testvideo.mp4" "$tmp\t6_video_closed_169.png" 'Video 16:9 l_closed'
Test-Skin 'l_closed' 549 "$tmp\clip43.mp4" "$tmp\t6_video_closed_43.png" 'Video 4:3 l_closed'
Test-Skin 'l_closed' 549 "$tmp\clipport.mp4" "$tmp\t6_video_closed_port.png" 'Video hochkant l_closed'
Test-Skin 'l_closed' 549 "$root\research\spike\media\testaudio.mp3" "$tmp\t6_audio_idle.png" 'Audio-Idle l_closed'
Test-Skin 'l_both' 760 "$root\research\spike\media\testvideo.mp4" "$tmp\t6_video_both.png" 'Video l_both'

# broken.vlt selbst bauen (kaputte theme.xml) - damit die Suite nicht von tmp-Resten abhaengt
$brokenDir = "$tmp\broken_pack"
New-Item -ItemType Directory -Force -Path $brokenDir | Out-Null
[System.IO.File]::WriteAllText("$brokenDir\theme.xml", 'BROKEN<<<NOT XML', (New-Object System.Text.UTF8Encoding($false)))
Remove-Item "$tmp\broken.vlt" -ErrorAction SilentlyContinue
Push-Location $brokenDir
& 'C:\Program Files\7-Zip\7z.exe' a -tzip "$tmp\broken.vlt" theme.xml | Out-Null
Pop-Location

# --- Fehlerfall A: kaputtes theme.xml -> erwartet: SAUBERER EXIT ("no skins found"), kein Crash ---
(Get-Content "$tmp\vlcrc.task6_backup") | Where-Object { $_ -notmatch '^skins2-(last|config)=' } | Set-Content $vlcrc
Remove-Item "$env:APPDATA\vlc\crashdump" -Recurse -Force -ErrorAction SilentlyContinue
$logFb = "$tmp\vlc_task6_fallback.log"
$p = Start-Process 'C:\Program Files\VideoLAN\VLC\vlc.exe' -ArgumentList @('-I','skins',('--skins2-last="{0}"' -f "$tmp\broken.vlt"),'--no-video-title-show','--file-logging',('--logfile="{0}"' -f $logFb),'-vvv') -PassThru
$exited = $p.WaitForExit(25000)
$crashwin = Get-Process vlc -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -match 'crash' }
if($exited -and -not $crashwin -and (Select-String -Path $logFb -Pattern 'no skins found' -Quiet)){ Write-Host 'Fehlerfall defekt : OK (sauberer Exit, kein Crash)' }
else { Write-Host 'Fehlerfall defekt : FAIL'; $script:fail = 1 }
Get-Process vlc -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 600
Remove-Item "$env:APPDATA\vlc\crashdump" -Recurse -Force -ErrorAction SilentlyContinue

# --- Fehlerfall B: fehlende Datei -> erwartet: Fallback default.vlt (Fenster 500) ---
$p = Start-Process 'C:\Program Files\VideoLAN\VLC\vlc.exe' -ArgumentList @('-I','skins',('--skins2-last="{0}"' -f "$tmp\gibtsnicht.vlt"),'--no-video-title-show') -PassThru
$win=$null
for($i=0; $i -lt 22; $i++){ Start-Sleep -Milliseconds 900; $win = Get-VlcWin $p.Id | Where-Object { $_.W -eq 500 } | Select-Object -First 1; if($win){ break } }
if($win){ Write-Host 'Fehlerfall fehlend : OK (default.vlt-Fallback 500px)'; Capture-Win $win.Hwnd "$tmp\t6_fallback.png" | Out-Null }
else { Write-Host 'Fehlerfall fehlend : FAIL'; $script:fail = 1 }
Get-Process -Id $p.Id -ErrorAction SilentlyContinue | Stop-Process -Force

Copy-Item "$tmp\vlcrc.task6_backup" $vlcrc -Force
Remove-Item "$env:APPDATA\vlc\crashdump" -Recurse -Force -ErrorAction SilentlyContinue
if($fail -eq 0){ Write-Host 'PASS: Task-6-Suite (Screen/Video + Fehlerfaelle klickfrei)'; exit 0 }
Write-Host 'FAIL: Task-6-Suite'
exit 1
