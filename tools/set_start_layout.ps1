# set_start_layout.ps1 - setzt das Startlayout des Skins in der vlcrc.
#
# skins2 merkt sich Fensterposition + aktives Layout in der Option
# "skins2-config" im vlcrc, Format:
#     ["<windowId>" "<layoutId>" x y width height visible]
# (7 Felder - das letzte "visible" ist Pflicht, sonst verwirft skins2 die
#  Config und nimmt das Default-Layout.)
#
# Dieser Helfer setzt das Layout (z.B. l_closed = geschlossene Ohren) und die
# zum Layout passende Groesse; die Fensterposition (x,y) bleibt erhalten.
param(
  [string]$Layout = 'l_closed',
  [int]$Width = 1098,
  [int]$Height = 788,
  [string]$Window = 'main'
)
$ErrorActionPreference = 'Stop'
$vlcrc = Join-Path $env:APPDATA 'vlc\vlcrc'
if(-not (Test-Path $vlcrc)){ Write-Host "FAIL: vlcrc fehlt: $vlcrc"; exit 1 }

$lines = [System.IO.File]::ReadAllLines($vlcrc)
$rx = '^\s*skins2-config\s*=\s*\[\s*"([^"]*)"\s+"([^"]*)"\s+(-?\d+)\s+(-?\d+)\s+(\d+)\s+(\d+)(\s+\d+)?\s*\]'
$found = $false
for($i = 0; $i -lt $lines.Count; $i++){
  if($lines[$i] -match $rx){
    $win = $matches[1]
    $x = [int]$matches[3]; $y = [int]$matches[4]
    $lines[$i] = ('skins2-config=["{0}" "{1}" {2} {3} {4} {5} 1]' -f $win, $Layout, $x, $y, $Width, $Height)
    $found = $true
    break
  }
}
if(-not $found){
  $new = New-Object System.Collections.Generic.List[string]
  $new.AddRange([string[]]$lines)
  $new.Add(('skins2-config=["{0}" "{1}" 100 100 {2} {3} 1]' -f $Window, $Layout, $Width, $Height))
  $lines = $new.ToArray()
}
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines($vlcrc, $lines, $enc)
Write-Host ("OK: Startlayout = {0} ({1}x{2})" -f $Layout, $Width, $Height)
exit 0
