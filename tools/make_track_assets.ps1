# make_track_assets.ps1 - baut die Track-Komposite aus den Original-Kacheln (Split: Kappe/Stiel/Kappe)
#   eq_track_v.png (11x76) = Kappe oben (5px) + gruene Linie (Stielzeile) + gespiegelte Kappe unten
#   sl_track_h.png (71x11) = Kappe links + Linie + gespiegelte Kappe rechts
param([string]$Skin = 'headspace', [string]$Root)
$ErrorActionPreference = 'Stop'
if(-not $Root){ $Root = Split-Path $PSScriptRoot -Parent }
Add-Type -AssemblyName System.Drawing
$img = Join-Path $Root "skins\$Skin\theme\images"
$capV = 5    # vertikale Kappengroesse (aus Zeilenanalyse)
$capH = 5    # horizontale Kappengroesse

function Compose-Track($tile, [string]$outPath, [int]$len, [bool]$vertical, [int]$capSize){
  $tw = $tile.Width; $th = $tile.Height
  if($vertical){
    $out = New-Object System.Drawing.Bitmap($tw, $len, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.Clear([System.Drawing.Color]::Transparent)
    # Kappe oben
    $g.DrawImage($tile, (New-Object System.Drawing.Rectangle(0, 0, $tw, $capSize)), (New-Object System.Drawing.Rectangle(0, 0, $tw, $capSize)), [System.Drawing.GraphicsUnit]::Pixel)
    # Linie: Stielzeile unten der Kappe entnehmen (bei y=capSize+1)
    $stemY = [Math]::Min($capSize + 1, $th - 1)
    $g.DrawImage($tile, (New-Object System.Drawing.Rectangle(0, $capSize, $tw, ($len - 2*$capSize))), (New-Object System.Drawing.Rectangle(0, $stemY, $tw, 1)), [System.Drawing.GraphicsUnit]::Pixel)
    # Kappe unten (gespiegelt)
    $flip = New-Object System.Drawing.Bitmap($tw, $capSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gf = [System.Drawing.Graphics]::FromImage($flip)
    $gf.DrawImage($tile, (New-Object System.Drawing.Rectangle(0, 0, $tw, $capSize)), (New-Object System.Drawing.Rectangle(0, 0, $tw, $capSize)), [System.Drawing.GraphicsUnit]::Pixel)
    $gf.Dispose()
    $flip.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipY)
    $g.DrawImage($flip, 0, ($len - $capSize))
    $g.Dispose(); $flip.Dispose()
  } else {
    $out = New-Object System.Drawing.Bitmap($len, $th, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($tile, (New-Object System.Drawing.Rectangle(0, 0, $capSize, $th)), (New-Object System.Drawing.Rectangle(0, 0, $capSize, $th)), [System.Drawing.GraphicsUnit]::Pixel)
    $stemX = [Math]::Min($capSize + 1, $tw - 1)
    $g.DrawImage($tile, (New-Object System.Drawing.Rectangle($capSize, 0, ($len - 2*$capSize), $th)), (New-Object System.Drawing.Rectangle($stemX, 0, 1, $th)), [System.Drawing.GraphicsUnit]::Pixel)
    $flip = New-Object System.Drawing.Bitmap($capSize, $th, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gf = [System.Drawing.Graphics]::FromImage($flip)
    $gf.DrawImage($tile, (New-Object System.Drawing.Rectangle(0, 0, $capSize, $th)), (New-Object System.Drawing.Rectangle(0, 0, $capSize, $th)), [System.Drawing.GraphicsUnit]::Pixel)
    $gf.Dispose()
    $flip.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
    $g.DrawImage($flip, ($len - $capSize), 0)
    $g.Dispose(); $flip.Dispose()
  }
  $out.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $out.Dispose()
}

$vt = New-Object System.Drawing.Bitmap (Join-Path $img 'vertical_slider.png')
Compose-Track $vt (Join-Path $img 'eq_track_v.png') 76 $true $capV
$vt.Dispose()
$ht = New-Object System.Drawing.Bitmap (Join-Path $img 'horizontal_slider.png')
Compose-Track $ht (Join-Path $img 'sl_track_h.png') 71 $false $capH
$ht.Dispose()
'OK: eq_track_v.png + sl_track_h.png erzeugt'
exit 0
