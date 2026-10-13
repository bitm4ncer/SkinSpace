# test_skin.ps1 — lädt dist/Headspace.vlt in VLC, schießt Screenshot, prüft Log, räumt auf.
param(
  [string]$Vlt = 'C:\GitHub\VLC_Skins\dist\Headspace.vlt',
  [int]$ExpectW = 549,
  [int]$ExpectH = 394,
  [string]$Shot = 'C:\GitHub\VLC_Skins\tools\tmp\skin_shot.png',
  [string]$Log  = 'C:\GitHub\VLC_Skins\tools\tmp\vlc_skin_test.log',
  [switch]$KeepOpen
)
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class FocusHelp {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern void SwitchToThisWindow(IntPtr h, bool alt);
}
"@
. 'C:\GitHub\VLC_Skins\research\spike\winhelp.ps1'

if(-not (Test-Path $Vlt)){ Write-Host "FAIL: vlt fehlt: $Vlt"; exit 1 }
$vlcrc = "$env:APPDATA\vlc\vlcrc"
$bk = 'C:\GitHub\VLC_Skins\tools\tmp\vlcrc.test_skin_backup'
Copy-Item $vlcrc $bk -Force
(Get-Content $vlcrc) | Where-Object { $_ -notmatch '^skins2-(last|config)=' } | Set-Content $vlcrc

$p = Start-Process 'C:\Program Files\VideoLAN\VLC\vlc.exe' -ArgumentList @('-I','skins',('--skins2-last="{0}"' -f $Vlt),'--no-video-title-show','--file-logging',"--logfile=$Log",'-vvv') -PassThru
$win = $null
for($i=0; $i -lt 25; $i++){
  Start-Sleep -Milliseconds 900
  $win = Get-VlcWin $p.Id | Where-Object { $_.W -eq $ExpectW -and $_.H -eq $ExpectH } | Select-Object -First 1
  if($win){ break }
}
$ok = $true
if(-not $win){ Write-Host "FAIL: Fenster ${ExpectW}x${ExpectH} nicht gefunden"; $ok = $false }
else {
  [FocusHelp]::SwitchToThisWindow($win.Hwnd,$true); Start-Sleep -Milliseconds 400
  [FocusHelp]::SetForegroundWindow($win.Hwnd) | Out-Null; Start-Sleep -Milliseconds 400
  [WinAPI]::SetCursorPos(2,2)   # Cursor parken (kein Hover-State im Screenshot)
  Start-Sleep -Milliseconds 400
  Capture-Win $win.Hwnd $Shot | Write-Host
  Start-Sleep -Milliseconds 300
  # Log-Check (kurz warten, damit Log geflusht ist)
  $hits = @()
  for($t=0; $t -lt 6; $t++){
    Start-Sleep -Milliseconds 500
    $hits = @(Select-String -Path $Log -Pattern 'bad theme|unknown action|non-unique|policy' -ErrorAction SilentlyContinue)
    if($hits.Count -gt 0){ break }
  }
  if($hits.Count -gt 0){ $hits | Select-Object -First 8 | ForEach-Object { Write-Host "LOGHIT: $($_.Line)" }; Write-Host "FAIL: Theme-Fehler im Log"; $ok = $false }
  else { Write-Host "OK: Log ohne Theme-Fehler" }
}
if(-not $KeepOpen){ Get-Process vlc -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $p.Id } | Stop-Process -Force }
Start-Sleep -Milliseconds 500
Copy-Item $bk $vlcrc -Force
if($ok){ Write-Host "PASS: Skin-Ladetest ($ExpectW x $ExpectH)"; exit 0 }
Write-Host "FAIL: Skin-Ladetest"
exit 1
