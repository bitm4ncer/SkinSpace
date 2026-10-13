# skin_interact_test.ps1 - startet den Skin, klickt an (fenster-relative Koordinaten), screenshotet, prueft Log, schliesst die eigene Testinstanz.
param(
  [string]$Vlt = 'C:\GitHub\VLC_Skins\dist\Headspace.vlt',
  [int]$ExpectW = 549,
  [int]$ExpectH = 394,
  [int]$ClickX = 0,
  [int]$ClickY = 0,
  [string]$Shot = 'C:\GitHub\VLC_Skins\tools\tmp\interact_shot.png',
  [string]$Log  = 'C:\GitHub\VLC_Skins\tools\tmp\vlc_interact_test.log'
)
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @"
using System; using System.Runtime.InteropServices;
public class FocusHelpI {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern void SwitchToThisWindow(IntPtr h, bool alt);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
}
"@
. 'C:\GitHub\VLC_Skins\research\spike\winhelp.ps1'

if(-not (Test-Path $Vlt)){ Write-Host "FAIL: vlt fehlt: $Vlt"; exit 1 }
$vlcrc = "$env:APPDATA\vlc\vlcrc"
$bk = 'C:\GitHub\VLC_Skins\tools\tmp\vlcrc.interact_backup'
if(Test-Path $vlcrc){ Copy-Item $vlcrc $bk -Force }
$cfg = (Get-Content $vlcrc -ErrorAction SilentlyContinue) | Where-Object { $_ -notmatch '^skins2-(last|config)=' }
$cfg += ('skins2-config=["main" "l_closed" 30 30 {0} {1} 1]' -f $ExpectW, $ExpectH)
Set-Content $vlcrc $cfg

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
  [FocusHelpI]::SwitchToThisWindow($win.Hwnd,$true); Start-Sleep -Milliseconds 500
  [FocusHelpI]::SetForegroundWindow($win.Hwnd) | Out-Null; Start-Sleep -Milliseconds 500
  # Sicher auf die Spitze der Z-Order (klaut KEINEN Fokus, aber Klicks landen sicher bei uns)
  $HWND_TOPMOST = [IntPtr]::new(-1)
  [FocusHelpI]::SetWindowPos($win.Hwnd, $HWND_TOPMOST, 0, 0, 0, 0, 0x0003) | Out-Null
  Start-Sleep -Milliseconds 300
  if($ClickX -gt 0 -or $ClickY -gt 0){
    # Vor-Klick auf neutralen Bereich (Kopf): schluckt den Erst-Aktivierungsklick von Windows
    [WinAPI]::Click(($win.Left+350), ($win.Top+150))
    Start-Sleep -Milliseconds 400
    [WinAPI]::SetCursorPos(($win.Left+$ClickX), ($win.Top+$ClickY)) | Out-Null
    Start-Sleep -Milliseconds 300
    [WinAPI]::Click(($win.Left+$ClickX), ($win.Top+$ClickY))
    Start-Sleep -Milliseconds 1200
  }
  [WinAPI]::SetCursorPos(2,2) | Out-Null
  Start-Sleep -Milliseconds 400
  Capture-Win $win.Hwnd $Shot | Write-Host
  Start-Sleep -Milliseconds 300
  $hits = @(Select-String -Path $Log -Pattern 'bad theme|unknown action|non-unique|policy' -ErrorAction SilentlyContinue)
  if($hits.Count -gt 0){ $hits | Select-Object -First 6 | ForEach-Object { Write-Host "LOGHIT: $($_.Line)" }; Write-Host "FAIL: Theme-Fehler im Log"; $ok = $false }
  else { Write-Host "OK: Log ohne Theme-Fehler" }
}
Get-Process -Id $p.Id -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500
if(Test-Path $bk){ Copy-Item $bk $vlcrc -Force }
if($ok){ Write-Host "PASS: Interaktionstest"; exit 0 }
Write-Host "FAIL: Interaktionstest"
exit 1
