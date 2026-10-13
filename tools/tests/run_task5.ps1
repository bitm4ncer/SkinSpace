# run_task5.ps1 - Suite fuer Task 5: Builder-Regression + Build/Pack + klickfreier Playlist-Test (Preset l_pl)
$root = 'C:\GitHub\VLC_Skins'
$tmp = "$root\tools\tmp"
$fail = 0
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\tests\test_build_theme.ps1') | Out-Null
if($LASTEXITCODE -ne 0){ $fail = 1; Write-Host 'FAIL: Builder-Tests' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\build_theme.ps1') -Scale 1 | Out-Null
if($LASTEXITCODE -ne 0){ $fail = 1; Write-Host 'FAIL: build_theme' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\pack.ps1') | Out-Null
if($LASTEXITCODE -ne 0){ $fail = 1; Write-Host 'FAIL: pack' }

# Klickfreier Playlist-Test: Preset l_pl + Medien (gequotet!) + Screenshot + Logcheck
. (Join-Path $root 'research\spike\winhelp.ps1')
$vlcrc = "$env:APPDATA\vlc\vlcrc"
$bk = "$tmp\vlcrc.task5_backup"
Copy-Item $vlcrc $bk -Force
$cfg = (Get-Content $vlcrc) | Where-Object { $_ -notmatch '^skins2-(last|config)=' }
$cfg += 'skins2-config=["main" "l_pl" 40 40 760 394 1]'
Set-Content $vlcrc $cfg
$log = "$tmp\vlc_task5.log"
$argsL = @('-I','skins',('--skins2-last="{0}"' -f (Join-Path $root 'dist\Headspace.vlt')),'--no-video-title-show','--file-logging',"--logfile=$log",'-vvv')
$argsL += (Get-ChildItem "$tmp\pltest" -File | ForEach-Object { '"' + $_.FullName + '"' })
$p = Start-Process 'C:\Program Files\VideoLAN\VLC\vlc.exe' -ArgumentList $argsL -PassThru
$win=$null
for($i=0; $i -lt 25; $i++){ Start-Sleep -Milliseconds 900; $win = Get-VlcWin $p.Id | Where-Object { $_.W -eq 760 -and $_.H -eq 394 } | Select-Object -First 1; if($win){ break } }
if(-not $win){ Write-Host 'FAIL: Playlist-Fenster 760x394 nicht gefunden'; $fail = 1 }
else {
  Start-Sleep -Seconds 2
  Capture-Win $win.Hwnd "$tmp\pl_task5.png" | Out-Null
  Start-Sleep -Milliseconds 400
  $hits = @(Select-String -Path $log -Pattern 'bad theme|unknown action|non-unique|policy' -ErrorAction SilentlyContinue)
  if($hits.Count -gt 0){ $hits | Select-Object -First 5 | ForEach-Object { Write-Host "LOGHIT: $($_.Line)" }; Write-Host 'FAIL: Theme-Fehler im Log'; $fail = 1 }
  else { Write-Host 'OK: Log ohne Theme-Fehler' }
}
Get-Process vlc -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
Copy-Item $bk $vlcrc -Force
if($fail -eq 0){ Write-Host 'PASS: Task-5-Suite (Playlist-Drawer 760px, klickfrei)'; exit 0 }
Write-Host 'FAIL: Task-5-Suite'
exit 1
