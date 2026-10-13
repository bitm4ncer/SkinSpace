# make_vid_bkgd.ps1 - erzeugt vid_bkgd.png (Idle-Screen) aus head.png.
#
# vid_bkgd liegt im Layout bei view (270,59) und ist 216x159 gross; head.png
# liegt bei view (261,0). Ein vid_bkgd-Pixel (x,y) entspricht also head-lokal
# (9+x, 59+y).
#
# Ergebnis: deckend schwarz GENAU in der Screen-Oeffnung (die transparente
# Flaeche, die NICHT mit dem Bildrand zusammenhaengt), sonst transparent.
# KEINE Farbe in den Ecken.
#
# Die N×-Varianten werden von make_scaled_variant.ps1 aus dieser Datei skaliert.
param([string]$Skin = 'headspace', [string]$Root, [string]$OutFile)
$ErrorActionPreference = 'Stop'
if(-not $Root){ $Root = Split-Path $PSScriptRoot -Parent }
$imgDir = Join-Path $Root "skins\$Skin\theme\images"
if(-not $OutFile){ $OutFile = Join-Path $imgDir 'vid_bkgd.png' }
Add-Type -AssemblyName System.Drawing

$head = New-Object System.Drawing.Bitmap((Join-Path $imgDir 'head.png'))
$W = $head.Width; $Ht = $head.Height

# Hintergrund = transparente Pixel, die mit dem Bildrand zusammenhaengen (Flood-Fill vom Rand)
$isBg = New-Object 'bool[,]' $W, $Ht
$q = New-Object System.Collections.Queue
for($x=0;$x -lt $W;$x++){
  foreach($y in @(0,($Ht-1))){ if($head.GetPixel($x,$y).A -lt 128 -and -not $isBg[$x,$y]){ $isBg[$x,$y]=$true; $q.Enqueue($x*$Ht+$y) } }
}
for($y=0;$y -lt $Ht;$y++){
  foreach($x in @(0,($W-1))){ if($head.GetPixel($x,$y).A -lt 128 -and -not $isBg[$x,$y]){ $isBg[$x,$y]=$true; $q.Enqueue($x*$Ht+$y) } }
}
while($q.Count -gt 0){
  $idx=[int]$q.Dequeue(); $x=[int][Math]::Floor($idx / $Ht); $y=$idx % $Ht
  foreach($d in @(@(1,0),@(-1,0),@(0,1),@(0,-1))){
    $nx=$x+$d[0]; $ny=$y+$d[1]
    if($nx -ge 0 -and $nx -lt $W -and $ny -ge 0 -and $ny -lt $Ht -and -not $isBg[$nx,$ny] -and $head.GetPixel($nx,$ny).A -lt 128){ $isBg[$nx,$ny]=$true; $q.Enqueue($nx*$Ht+$ny) }
  }
}

$vbW = 216; $vbH = 159; $ox = 9; $oy = 59
$vb = New-Object System.Drawing.Bitmap($vbW, $vbH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$black = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
$clear = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$open = 0
for($y = 0; $y -lt $vbH; $y++){
  for($x = 0; $x -lt $vbW; $x++){
    $hx = $ox + $x; $hy = $oy + $y
    $set = $clear
    if($hx -ge 0 -and $hx -lt $W -and $hy -ge 0 -and $hy -lt $Ht){
      if($head.GetPixel($hx, $hy).A -lt 128 -and -not $isBg[$hx, $hy]){ $set = $black; $open++ }
    }
    $vb.SetPixel($x, $y, $set)
  }
}
$head.Dispose()
$vb.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output ("OK: {0} ({1}x{2}, {3} Oeffnungs-Pixel schwarz)" -f $OutFile, $vbW, $vbH, $open)
$vb.Dispose()
exit 0
