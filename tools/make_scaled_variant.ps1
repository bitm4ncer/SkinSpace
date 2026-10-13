# make_scaled_variant.ps1 — erzeugt eine N×-Bildvariante (Nearest-Neighbor = Pixel-Look) aus skins/<skin>/theme/images
param(
  [Parameter(Mandatory)][int]$Scale,
  [Parameter(Mandatory)][string]$OutDir,
  [string]$Skin = 'headspace',
  [string]$Root,
  [string]$Src
)
$ErrorActionPreference = 'Stop'
if(-not $Root){ $Root = Split-Path $PSScriptRoot -Parent }
if(-not $Src){ $Src = Join-Path $Root "skins\$Skin\theme\images" }
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$count = 0
foreach($f in Get-ChildItem $Src -Filter '*.png'){
  $b = New-Object System.Drawing.Bitmap($f.FullName)
  $b2 = $b.Clone((New-Object System.Drawing.Rectangle(0,0,$b.Width,$b.Height)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $b.Dispose()
  $w = $b2.Width * $Scale; $h = $b2.Height * $Scale
  $dst = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $g.DrawImage($b2, 0, 0, $w, $h)
  $g.Dispose(); $b2.Dispose()
  $dst.Save((Join-Path $OutDir $f.Name), [System.Drawing.Imaging.ImageFormat]::Png)
  $dst.Dispose()
  $count++
}
"OK: $count Bilder x$Scale -> $OutDir"
exit 0
