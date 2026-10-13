# pack.ps1 - packt ein Theme-Verzeichnis als .vlt (ZIP). Standard: src\theme -> dist\Headspace.vlt
# WICHTIG: diese Datei absichtlich pure ASCII halten (PS 5.1 liest ohne BOM als ANSI; UTF-8-Sonderzeichen in Strings zerbrechen das Parsing)
param(
  [string]$Stage = 'C:\GitHub\VLC_Skins\src\theme',
  [string]$OutFile = 'C:\GitHub\VLC_Skins\dist\Headspace.vlt'
)
$ErrorActionPreference = 'Stop'
$outDir = Split-Path -Parent $OutFile
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
Remove-Item $OutFile -ErrorAction SilentlyContinue

if(-not (Test-Path (Join-Path $Stage 'theme.xml'))){ Write-Host "FAIL: theme.xml fehlt in $Stage - erst build_theme.ps1 laufen lassen"; exit 1 }
foreach($req in 'images','fonts'){ if(-not (Test-Path (Join-Path $Stage $req))){ Write-Host "FAIL: $req fehlt im Stage ($Stage)"; exit 1 } }

Push-Location $Stage
try { & 'C:\Program Files\7-Zip\7z.exe' a -tzip $OutFile theme.xml images fonts | Out-Null }
finally { Pop-Location }
if($LASTEXITCODE -ne 0 -or -not (Test-Path $OutFile)){ Write-Host 'FAIL: 7z-Packen fehlgeschlagen'; exit 1 }

$list = & 'C:\Program Files\7-Zip\7z.exe' l $OutFile
$count = ($list | Select-String -Pattern '\.png$|theme\.xml$|font\.otf$').Count
$hasTheme = ($list | Select-String -Pattern 'theme\.xml$').Count -gt 0
if(-not $hasTheme){ Write-Host 'FAIL: theme.xml nicht im Archiv'; exit 1 }
$kb = [int]((Get-Item $OutFile).Length / 1024)
Write-Host ('OK: {0} ({1} Dateien, {2} KB)' -f $OutFile, $count, $kb)
exit 0
