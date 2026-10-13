# build_variants.ps1 — baut die N×-Größenvarianten (2x, 3x) komplett: Bilder -> theme.xml -> .vlt
param([string]$Skin = 'headspace', [string]$Root)
$ErrorActionPreference = 'Stop'
if(-not $Root){ $Root = Split-Path $PSScriptRoot -Parent }
$disp = $Skin.Substring(0,1).ToUpper() + $Skin.Substring(1)
foreach($n in 2,3){
  $stage = Join-Path $Root "skins\$Skin\variants\${n}x"
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  "=== Variante ${n}x ==="
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'tools\make_scaled_variant.ps1') -Skin $Skin -Scale $n -OutDir (Join-Path $stage 'images') | Select-Object -Last 1
  New-Item -ItemType Directory -Force -Path (Join-Path $stage 'fonts') | Out-Null
  Copy-Item (Join-Path $Root "skins\$Skin\theme\fonts\*") (Join-Path $stage 'fonts') -Force
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'tools\build_theme.ps1') -Skin $Skin -Scale $n -OutFile (Join-Path $stage 'theme.xml') | Select-Object -Last 1
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'tools\pack.ps1') -Stage $stage -OutFile (Join-Path $Root ("dist\{0}-{1}x.vlt" -f $disp, $n)) | Select-Object -Last 1
}
"VARIANTEN FERTIG"
exit 0
