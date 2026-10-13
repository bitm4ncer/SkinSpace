# pack.ps1 — packt src/theme/ deterministisch als dist/Headspace.vlt (ZIP)
param([string]$Root = 'C:\GitHub\VLC_Skins')
$ErrorActionPreference = 'Stop'
$stage = Join-Path $Root 'src\theme'
$dist  = Join-Path $Root 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$vlt = Join-Path $dist 'Headspace.vlt'
Remove-Item $vlt -ErrorAction SilentlyContinue

if(-not (Test-Path (Join-Path $stage 'theme.xml'))){ Write-Host 'FAIL: theme.xml fehlt — erst build_theme.ps1 laufen lassen'; exit 1 }
foreach($req in 'images','fonts'){ if(-not (Test-Path (Join-Path $stage $req))){ Write-Host "FAIL: $req fehlt im Stage"; exit 1 } }

Push-Location $stage
try { & 'C:\Program Files\7-Zip\7z.exe' a -tzip $vlt theme.xml images fonts | Out-Null }
finally { Pop-Location }
if($LASTEXITCODE -ne 0 -or -not (Test-Path $vlt)){ Write-Host 'FAIL: 7z-Packen fehlgeschlagen'; exit 1 }

$list = & 'C:\Program Files\7-Zip\7z.exe' l $vlt
$count = ($list | Select-String -Pattern '\.png$|theme\.xml$|font\.otf$').Count
$hasTheme = ($list | Select-String -Pattern 'theme\.xml$').Count -gt 0
if(-not $hasTheme){ Write-Host 'FAIL: theme.xml nicht im Archiv'; exit 1 }
Write-Host "OK: $vlt ($count Dateien, $(Get-Item $vlt | Select-Object -ExpandProperty Length) bytes)"
exit 0
