# make_vid_bkgd.ps1 - erzeugt vid_bkgd.png (Idle-Screen) aus head.png.
#
# vid_bkgd liegt im Layout bei view (270,59) und ist 216x159 gross; head.png
# liegt bei view (261,0). Ein vid_bkgd-Pixel (x,y) entspricht also head-lokal
# (9+x, 59+y).
#
# Ergebnis: deckend schwarz GENAU in der Screen-Oeffnung (transparent + nicht
# die rote Aussen-Clip-Farbe), sonst transparent. KEINE Farbe in den Ecken -
# die Ecken des Loch-Rechtecks (ausserhalb des Gesichts) bleiben transparent;
# um sie kuemmert sich tools/vout_mask.ps1 (Region-Trim).
#
# Die N×-Varianten werden von make_scaled_variant.ps1 aus dieser Datei skaliert.
param([string]$Skin = 'headspace', [string]$Root, [string]$OutFile)
$ErrorActionPreference = 'Stop'
if(-not $Root){ $Root = Split-Path $PSScriptRoot -Parent }
$imgDir = Join-Path $Root "skins\$Skin\theme\images"
if(-not $OutFile){ $OutFile = Join-Path $imgDir 'vid_bkgd.png' }
Add-Type -AssemblyName System.Drawing

$head = New-Object System.Drawing.Bitmap((Join-Path $imgDir 'head.png'))
$vbW = 216; $vbH = 159; $ox = 9; $oy = 59
$vb = New-Object System.Drawing.Bitmap($vbW, $vbH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$black = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$open = 0
for($y = 0; $y -lt $vbH; $y++){
  for($x = 0; $x -lt $vbW; $x++){
    $hx = $ox + $x; $hy = $oy + $y
    $set = $clear
    if($hx -ge 0 -and $hx -lt $head.Width -and $hy -ge 0 -and $hy -lt $head.Height){
      $c = $head.GetPixel($hx, $hy)
      $isRed = ($c.A -lt 128 -and $c.R -ge 200 -and $c.G -lt 80 -and $c.B -lt 80)
      if($c.A -lt 128 -and -not $isRed){ $set = $black; $open++ }
    }
    $vb.SetPixel($x, $y, $set)
  }
}
$head.Dispose()
$vb.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output ("OK: {0} ({1}x{2}, {3} Oeffnungs-Pixel schwarz)" -f $OutFile, $vbW, $vbH, $open)
$vb.Dispose()
exit 0
