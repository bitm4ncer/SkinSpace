# build_variants.ps1 — baut die N×-Größenvarianten (2x, 3x) komplett: Bilder -> theme.xml -> .vlt
$ErrorActionPreference = 'Stop'
$root = 'C:\GitHub\VLC_Skins'
foreach($n in 2,3){
  $stage = Join-Path $root "src\variants\${n}x"
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  "=== Variante ${n}x ==="
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\make_scaled_variant.ps1') -Scale $n -OutDir (Join-Path $stage 'images') | Select-Object -Last 1
  New-Item -ItemType Directory -Force -Path (Join-Path $stage 'fonts') | Out-Null
  Copy-Item (Join-Path $root 'src\theme\fonts\*') (Join-Path $stage 'fonts') -Force
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\build_theme.ps1') -Scale $n -OutFile (Join-Path $stage 'theme.xml') | Select-Object -Last 1
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\pack.ps1') -Stage $stage -OutFile (Join-Path $root "dist\Headspace-${n}x.vlt") | Select-Object -Last 1
}
"VARIANTEN FERTIG"
exit 0
