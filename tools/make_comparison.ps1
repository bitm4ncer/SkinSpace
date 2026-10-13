# make_comparison.ps1 — Vergleichsblätter für den Upscale-Review (Task 1)
# Layout je Asset: Reihe 1 = Panels [Original nearest 2x | x4plus | anime], Reihe 2+3 = Detailausschnitte (4x Original)
param([string]$ReviewDir = 'C:\GitHub\VLC_Skins\research\upscale-review')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = 'C:\GitHub\VLC_Skins'
$src = Join-Path $root 'research\original\extracted'
$renders = Join-Path $ReviewDir 'renders'

$cases = @(
  @{ f='head.bmp';                     d1=@(100,45,80,80);  d2=@(70,190,80,80) },
  @{ f='left_ear.bmp';                 d1=@(10,40,60,60);   d2=@(0,0,60,60) },
  @{ f='right_ear.bmp';                d1=@(10,40,60,60);   d2=@(0,0,60,60) },
  @{ f='play_controls_01_default.bmp'; d1=@(0,0,72,25);     d2=@(72,0,72,25) },
  @{ f='progressbar.bmp';              d1=@(0,0,80,9);      d2=@(83,0,80,9) },
  @{ f='progressbar_foreground.bmp';   d1=@(0,0,80,9);      d2=@(83,0,80,9) },
  @{ f='thumb_01_default.bmp';         d1=@(0,0,18,9);      d2=@(0,0,9,9) },
  @{ f='L_drwr_open_01_default.bmp';   d1=@(0,0,18,30);     d2=@(0,30,18,36) },
  @{ f='EQ_01_DF.bmp';                 d1=@(0,0,20,19);     d2=@(0,0,10,10) }
)

function New-Checker([int]$w,[int]$h,[int]$cell=8){
  $bmp = New-Object System.Drawing.Bitmap($w,$h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $c1 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,205,205,205))
  $c2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,235,235,235))
  for($y=0;$y -lt $h;$y+=$cell){ for($x=0;$x -lt $w;$x+=$cell){
    $br = if(([int]($x/$cell)+[int]($y/$cell)) % 2 -eq 0){$c1}else{$c2}
    $g.FillRectangle($br,$x,$y,$cell,$cell)
  }}
  $c1.Dispose(); $c2.Dispose(); $g.Dispose()
  return $bmp
}

function Load-Nearest2x([string]$path){
  $s = New-Object System.Drawing.Bitmap($path)
  $dst = New-Object System.Drawing.Bitmap(($s.Width*2),($s.Height*2),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
  $g.DrawImage($s, 0, 0, $dst.Width, $dst.Height)
  $g.Dispose(); $s.Dispose()
  return $dst
}

function Draw-Panel([System.Drawing.Graphics]$g, $img, [int]$x, [int]$y, [int]$pad){
  $g.DrawImage($img, $x, $y, $img.Width, $img.Height)
}

$labelFont = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$noteFont  = New-Object System.Drawing.Font('Segoe UI', 9)
$black = [System.Drawing.Brushes]::Black

foreach($c in $cases){
  $base = [System.IO.Path]::GetFileNameWithoutExtension($c.f)
  $pA = Load-Nearest2x (Join-Path $src $c.f)
  $pB = New-Object System.Drawing.Bitmap((Join-Path $renders "$base.x4plus.png"))
  $pC = New-Object System.Drawing.Bitmap((Join-Path $renders "$base.anime.png"))
  $panels = @($pA, $pB, $pC)
  $names  = @('Original (nearest 2x)', 'x4plus -> 2x', 'x4plus-anime -> 2x')

  $pw = $pA.Width; $ph = $pA.Height
  $d1 = $c.d1; $d2 = $c.d2
  $detailZoom = 4   # 2x-Quelle eines Original-Pixels x4-Faktor => 4x Original
  $d1w = $d1[2]*$detailZoom; $d1h = $d1[3]*$detailZoom
  $d2w = $d2[2]*$detailZoom; $d2h = $d2[3]*$detailZoom
  $cw = [Math]::Max($pw, [Math]::Max($d1w, $d2w))

  $pad = 14; $gap = 14; $labelH = 26
  $totalW = $pad*2 + 3*$cw + 2*$gap
  $totalH = $pad + $labelH + $ph + $gap + $labelH + $d1h + $gap + $labelH + $d2h + $pad

  $canvas = New-Object System.Drawing.Bitmap($totalW, $totalH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($canvas)
  $g.Clear([System.Drawing.Color]::FromArgb(255,36,36,42))
  $white = [System.Drawing.Brushes]::White

  # Reihe 1: Panels
  $y = $pad
  for($i=0;$i -lt 3;$i++){
    $x = $pad + $i*($cw+$gap)
    $g.DrawString($names[$i], $labelFont, $white, $x, $y)
  }
  $y += $labelH
  for($i=0;$i -lt 3;$i++){
    $x = $pad + $i*($cw+$gap)
    Draw-Panel $g $panels[$i] $x $y $pad
  }

  # Detail-Reihen mit Schachbrett-Hintergrund
  $detailRows = @(
    @{ d=$d1; t='Detail 1 (4x Original)'; w=$d1w; h=$d1h },
    @{ d=$d2; t='Detail 2 (4x Original)'; w=$d2w; h=$d2h }
  )
  $y += $ph + $gap
  foreach($row in $detailRows){
    for($i=0;$i -lt 3;$i++){
      $x = $pad + $i*($cw+$gap)
      $g.DrawString(("{0} - {1}" -f $row.t, $names[$i]), $noteFont, $white, $x, $y)
    }
    $y += $labelH
    $dx = $row.d[0]*2; $dy = $row.d[1]*2; $dw = $row.d[2]*2; $dh = $row.d[3]*2
    for($i=0;$i -lt 3;$i++){
      $x = $pad + $i*($cw+$gap)
      $checker = New-Checker $row.w $row.h 8
      $g3 = [System.Drawing.Graphics]::FromImage($checker)
      $g3.DrawImage($panels[$i], (New-Object System.Drawing.Rectangle(0,0,$row.w,$row.h)), (New-Object System.Drawing.Rectangle($dx,$dy,$dw,$dh)), [System.Drawing.GraphicsUnit]::Pixel)
      $g3.Dispose()
      $g.DrawImage($checker, $x, $y, $row.w, $row.h)
      $checker.Dispose()
    }
    $y += $row.h + $gap
  }

  $g.Dispose()
  $out = Join-Path $ReviewDir ("compare_{0}.png" -f $base)
  $canvas.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $canvas.Dispose()
  foreach($p in $panels){ $p.Dispose() }
  "geschrieben: $out"
}
$labelFont.Dispose(); $noteFont.Dispose()

# --- Uebersichtsblatt ---
$ovRowH = 150; $ovCellW = 210; $ovLblW = 240
$ovW = 20 + $ovLblW + 3*($ovCellW + 12) + 20
$ovH = 30 + $cases.Count * ($ovRowH + 34) + 10
$ov = New-Object System.Drawing.Bitmap($ovW, $ovH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($ov)
$g.Clear([System.Drawing.Color]::FromArgb(255,245,245,248))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$fHdr = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$fRow = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$black = [System.Drawing.Brushes]::Black
$gray  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,90,90,95))

for($i=0;$i -lt 3;$i++){
  $x = 20 + $ovLblW + $i*($ovCellW + 12)
  $g.DrawString($names[$i], $fHdr, $black, $x, 8)
}
$y = 30
foreach($c in $cases){
  $base = [System.IO.Path]::GetFileNameWithoutExtension($c.f)
  $g.DrawString($c.f, $fRow, $black, 20, ($y + $ovRowH/2 - 20))
  $g.DrawString(('{0}x{1} -> {2}x{3}' -f 0,0,0,0), $fRow, $gray, -1000, -1000)  # noop fuer Font-Load
  $imgs = @(
    (Load-Nearest2x (Join-Path $src $c.f)),
    (New-Object System.Drawing.Bitmap((Join-Path $renders "$base.x4plus.png"))),
    (New-Object System.Drawing.Bitmap((Join-Path $renders "$base.anime.png")))
  )
  for($i=0;$i -lt 3;$i++){
    $x = 20 + $ovLblW + $i*($ovCellW + 12)
    $img = $imgs[$i]
    $scale = [Math]::Min($ovCellW / $img.Width, $ovRowH / $img.Height)
    $dw = [int]($img.Width * $scale); $dh = [int]($img.Height * $scale)
    $dx = $x + [int](($ovCellW - $dw)/2); $dy = $y + [int](($ovRowH - $dh)/2)
    $g.DrawRectangle((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,200,200,205))), $x, $y, $ovCellW, $ovRowH)
    $g.DrawImage($img, $dx, $dy, $dw, $dh)
    $img.Dispose()
  }
  $y += $ovRowH + 34
}
$g.Dispose()
$ovOut = Join-Path $ReviewDir 'overview.png'
$ov.Save($ovOut, [System.Drawing.Imaging.ImageFormat]::Png)
$ov.Dispose()
$fHdr.Dispose(); $fRow.Dispose(); $gray.Dispose()
"geschrieben: $ovOut"
"SHEETS OK"
