# make_original_assets.ps1 — konvertiert ALLE Original-BMPs 1:1 nach src/theme/images/ (PNG32, exakte Key-Entfernung)
# und generiert src/theme/xml/bitmaps.xml (Bitmap-Deklarationen für den Builder).
# Regeln (siehe research/upscale-review/decisions.md): Magenta -> Alpha überall; Rot -> Alpha nur in head.bmp; sonst unverändert.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'prepare_assets.ps1')   # liefert ConvertTo-Png32 + Remove-KeyColor

$root = 'C:\GitHub\VLC_Skins'
$src  = Join-Path $root 'research\original\extracted'
$imgDir = Join-Path $root 'src\theme\images'
$xmlDir = Join-Path $root 'src\theme\xml'
$fontDir = Join-Path $root 'src\theme\fonts'
New-Item -ItemType Directory -Force -Path $imgDir, $xmlDir, $fontDir | Out-Null

# Font mitkopieren (Font-ID 'defaultfont' muss auf diese Datei zeigen)
Copy-Item (Join-Path $root 'research\refs\default-vlt\default\subX\font.otf') (Join-Path $fontDir 'font.otf') -Force

$bmps = Get-ChildItem $src -Filter '*.bmp' | Where-Object { $_.Name -notlike '*_map.bmp' } | Sort-Object Name
$bitmapLines = New-Object System.Collections.Generic.List[string]
foreach($f in $bmps){
  $tmp   = Join-Path $imgDir ($f.BaseName + '.src.png')
  $final = Join-Path $imgDir ($f.BaseName + '.png')
  ConvertTo-Png32 -In $f.FullName -Out $tmp
  $keys = @('#FF00FF')
  if($f.Name -eq 'head.bmp'){ $keys += '#FF0000' }
  $null = Remove-KeyColor -Path $tmp -Keys $keys -OutPath $final
  Remove-Item $tmp
  [void]$bitmapLines.Add(('  <Bitmap id="{0}.png" file="images/{0}.png" alphacolor="#FE01FE"/>' -f $f.BaseName))
}
$outXml = New-Object System.Collections.Generic.List[string]
[void]$outXml.Add('  <!-- GENERIERT von tools/make_original_assets.ps1 — nicht von Hand editieren -->')
foreach($l in $bitmapLines){ [void]$outXml.Add($l) }
[System.IO.File]::WriteAllText((Join-Path $xmlDir 'bitmaps.xml'), ($outXml -join "`r`n") + "`r`n", (New-Object System.Text.UTF8Encoding($false)))

"OK: $($bmps.Count) Assets konvertiert, bitmaps.xml mit $($bitmapLines.Count) Eintraegen"
exit 0
