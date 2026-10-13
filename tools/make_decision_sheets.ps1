# make_decision_sheets.ps1 — Entscheidungsblätter: Pixel-Look vs. xBR vs. hqx vs. KI (Task-1-Gate)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = 'C:\GitHub\VLC_Skins'
$src = Join-Path $root 'skins\headspace\originals\extracted'
$renders = Join-Path $root 'research\upscale-review\renders'
$out = Join-Path $root 'research\upscale-review'

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

$fT = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$fS = New-Object System.Drawing.Font('Segoe UI', 10)
$white = [System.Drawing.Brushes]::White

# ---------- Sheet 1: Thumb (8x Zoom) — 3 scharfe Strategien ----------
$cols = @(
  @{ t='Nearest 2x (Pixel-Look)';   img=(Load-Nearest2x (Join-Path $src 'thumb_01_default.bmp')) },
  @{ t='xBR 2x (scharf+geglaettet)'; img=(New-Object System.Drawing.Bitmap((Join-Path $renders 'thumb_01_default.xbr2.png'))) },
  @{ t='hqx 2x (pixel-scharf)';      img=(New-Object System.Drawing.Bitmap((Join-Path $renders 'thumb_01_default.hqx2.png'))) }
)
$zoom = 8; $pad = 16; $lblH = 26
$cellW = 36*$zoom; $cellH = 18*$zoom
$W = $pad*2 + 3*$cellW + 2*$pad; $H = $pad + $lblH + $cellH + $pad
$cv = New-Object System.Drawing.Bitmap($W,$H,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($cv)
$g.Clear([System.Drawing.Color]::FromArgb(255,36,36,42))
for($i=0;$i -lt 3;$i++){
  $x = $pad + $i*($cellW+$pad)
  $g.DrawString($cols[$i].t, $fS, $white, $x, $pad)
  $chk = New-Checker $cellW $cellH 8
  $g3 = [System.Drawing.Graphics]::FromImage($chk)
  $g3.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g3.DrawImage($cols[$i].img, 0, 0, $cellW, $cellH)
  $g3.Dispose()
  $g.DrawImage($chk, $x, ($pad+$lblH), $cellW, $cellH)
  $chk.Dispose()
}
$g.Dispose()
$cv.Save((Join-Path $out 'sheet_thumb_decision.png'),[System.Drawing.Imaging.ImageFormat]::Png); $cv.Dispose()
foreach($c in $cols){ $c.img.Dispose() }
"sheet_thumb_decision.png OK"

# ---------- Sheet 2: UI-Assets (Buttons/EQ/Drawer) ----------
$uiRows = @(
  @{ name='play_controls_01_default.bmp'; label='Transport-Buttons (Original-Sheet)'; zoom=2 },
  @{ name='EQ_01_DF.bmp';                 label='EQ-Knopf';                          zoom=6 },
  @{ name='L_drwr_open_01_default.bmp';   label='EQ-Ohr-Handle';                     zoom=4 }
)
$cellBox = 300; $rowH = $cellBox + 26
$W2 = $pad*2 + 3*($cellBox+$pad)
$H2 = $pad + $uiRows.Count*$rowH + $pad
$cv2 = New-Object System.Drawing.Bitmap($W2,$H2,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($cv2)
$g.Clear([System.Drawing.Color]::FromArgb(255,36,36,42))
$y = $pad
foreach($r in $uiRows){
  $base = [System.IO.Path]::GetFileNameWithoutExtension($r.name)
  $imgs = @(
    @{ t='Nearest 2x (Pixel-Look)';   img=(Load-Nearest2x (Join-Path $src $r.name)) },
    @{ t='xBR 2x';                    img=(New-Object System.Drawing.Bitmap((Join-Path $renders "$base.xbr2.png"))) },
    @{ t='KI anime + weiche Maske';   img=(New-Object System.Drawing.Bitmap((Join-Path $renders "$base.anime.png"))) }
  )
  $g.DrawString($r.label, $fT, $white, $pad, $y)
  for($i=0;$i -lt 3;$i++){
    $x = $pad + $i*($cellBox+$pad)
    $g.DrawString($imgs[$i].t, $fS, $white, $x, ($y+2))
    $img = $imgs[$i].img
    $fit = [Math]::Min($cellBox / $img.Width, $cellBox / $img.Height)
    $dw = [int]($img.Width * $fit); $dh = [int]($img.Height * $fit)
    $chk = New-Checker $cellBox $cellBox 8
    $g3 = [System.Drawing.Graphics]::FromImage($chk)
    $g3.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g3.DrawImage($img, [int](($cellBox-$dw)/2), [int](($cellBox-$dh)/2), $dw, $dh)
    $g3.Dispose()
    $g.DrawImage($chk, $x, ($y+24), $cellBox, $cellBox)
    $chk.Dispose(); $img.Dispose()
  }
  $y += $rowH
}
$g.Dispose()
$cv2.Save((Join-Path $out 'sheet_ui_decision.png'),[System.Drawing.Imaging.ImageFormat]::Png); $cv2.Dispose()
"sheet_ui_decision.png OK"

# ---------- Sheet 3: Kopf-Kontur (Crops auf der Silhouette!) ----------
$headCols = @(
  @{ t='Nearest 2x (Pixel-Look)';    img=(Load-Nearest2x (Join-Path $src 'head.bmp')) },
  @{ t='KI anime + weiche Maske v3'; img=(New-Object System.Drawing.Bitmap((Join-Path $renders 'head.anime.png'))) },
  @{ t='KI x4plus + weiche Maske v3'; img=(New-Object System.Drawing.Bitmap((Join-Path $renders 'head.x4plus.png'))) }
)
$crops = @(@(30,0,60,60), @(0,270,60,60), @(174,270,60,60))
$zoom3 = 6; $cellW3 = 60*$zoom3; $cellH3 = 60*$zoom3
$W3 = $pad*2 + 3*$cellW3 + 2*$pad
$H3 = $pad + ($crops.Count)*(26+$cellH3+$pad)
$cv3 = New-Object System.Drawing.Bitmap($W3,$H3,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($cv3)
$g.Clear([System.Drawing.Color]::FromArgb(255,36,36,42))
$y = $pad
foreach($cr in $crops){
  for($i=0;$i -lt 3;$i++){
    $x = $pad + $i*($cellW3+$pad)
    $g.DrawString($headCols[$i].t, $fS, $white, $x, $y)
  }
  $y += 26
  for($i=0;$i -lt 3;$i++){
    $x = $pad + $i*($cellW3+$pad)
    $chk = New-Checker $cellW3 $cellH3 8
    $g3 = [System.Drawing.Graphics]::FromImage($chk)
    $g3.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g3.DrawImage($headCols[$i].img, (New-Object System.Drawing.Rectangle(0,0,$cellW3,$cellH3)), (New-Object System.Drawing.Rectangle(($cr[0]*2),($cr[1]*2),($cr[2]*2),($cr[3]*2))), [System.Drawing.GraphicsUnit]::Pixel)
    $g3.Dispose()
    $g.DrawImage($chk, $x, $y, $cellW3, $cellH3)
    $chk.Dispose()
  }
  $y += $cellH3 + $pad
}
$g.Dispose()
$cv3.Save((Join-Path $out 'sheet_head_edge.png'),[System.Drawing.Imaging.ImageFormat]::Png); $cv3.Dispose()
foreach($c in $headCols){ $c.img.Dispose() }
"sheet_head_edge.png OK"

$fT.Dispose(); $fS.Dispose()
"DECISION SHEETS OK"
