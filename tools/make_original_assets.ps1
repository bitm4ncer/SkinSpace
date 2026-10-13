# make_original_assets.ps1 — konvertiert ALLE Original-BMPs 1:1 nach skins/<skin>/theme/images/ (PNG32, exakte Key-Entfernung)
# und generiert skins/<skin>/theme/xml/bitmaps.xml (Bitmap-Deklarationen für den Builder).
# Regeln (siehe research/upscale-review/decisions.md): Magenta -> Alpha überall; Rot -> Alpha nur in head.bmp; sonst unverändert.
param([string]$Skin = 'headspace', [string]$Root)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'prepare_assets.ps1')   # liefert ConvertTo-Png32 + Remove-KeyColor

if(-not $Root){ $Root = Split-Path $PSScriptRoot -Parent }
$src    = Join-Path $Root "skins\$Skin\originals\extracted"
$imgDir = Join-Path $Root "skins\$Skin\theme\images"
$xmlDir = Join-Path $Root "skins\$Skin\theme\xml"
$fontDir = Join-Path $Root "skins\$Skin\theme\fonts"
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
  if($f.Name -eq 'vid_bkgd.bmp'){ $keys = @('#FFFFFF') }
  $null = Remove-KeyColor -Path $tmp -Keys $keys -OutPath $final
  Remove-Item $tmp
  if($f.Name -like 'play_controls_*' -or $f.Name -like 'minimize_close_*'){ continue }  # Deklaration in subbitmaps.xml (Klickzonen)
  [void]$bitmapLines.Add(('  <Bitmap id="{0}.png" file="images/{0}.png" alphacolor="#FE01FE"/>' -f $f.BaseName))
}
$outXml = New-Object System.Collections.Generic.List[string]
[void]$outXml.Add('  <!-- GENERIERT von tools/make_original_assets.ps1 — nicht von Hand editieren -->')
foreach($l in $bitmapLines){ [void]$outXml.Add($l) }
[System.IO.File]::WriteAllText((Join-Path $xmlDir 'bitmaps.xml'), ($outXml -join "`r`n") + "`r`n", (New-Object System.Text.UTF8Encoding($false)))

"OK: $($bmps.Count) Assets konvertiert, bitmaps.xml mit $($bitmapLines.Count) Eintraegen"
exit 0
