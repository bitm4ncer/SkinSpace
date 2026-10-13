$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$out = 'C:\GitHub\VLC_Skins\research\spike\pack'
New-Item -ItemType Directory -Force -Path $out | Out-Null

function New-Bmp([int]$w,[int]$h) {
  $b = New-Object System.Drawing.Bitmap($w,$h)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)
  return @($b,$g)
}
function Save-Bmp($b,[string]$name) { $b.Save((Join-Path $out $name),[System.Drawing.Imaging.ImageFormat]::Png); $b.Dispose() }
function P([int]$x,[int]$y) { return [System.Drawing.Point]::new($x,$y) }

# --- bg1: 400x300, Ecke unten rechts abgeschnitten ---
$p = New-Bmp 400 300; $b=$p[0]; $g=$p[1]
$pts = [System.Drawing.Point[]]@( (P 1 1),(P 398 1),(P 398 268),(P 368 298),(P 1 298) )
$g.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,34,80,12))), $pts)
$g.DrawPolygon((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,130,210,50), 3)), $pts)
$g.DrawString('PROBE L1  400x300', (New-Object System.Drawing.Font('Segoe UI',16,[System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, 22, 120)
$g.DrawString('drag me (bg)  |  switch oben links', (New-Object System.Drawing.Font('Segoe UI',9)), [System.Drawing.Brushes]::LightGreen, 22, 150)
$g.Dispose(); Save-Bmp $b 'bg1.png'

# --- bg2: 700x300, Ecke unten links abgeschnitten ---
$p = New-Bmp 700 300; $b=$p[0]; $g=$p[1]
$pts = [System.Drawing.Point[]]@( (P 1 1),(P 698 1),(P 698 298),(P 31 298),(P 1 268) )
$g.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,20,60,90))), $pts)
$g.DrawPolygon((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,80,180,230), 3)), $pts)
$g.DrawString('PROBE L2  700x300', (New-Object System.Drawing.Font('Segoe UI',16,[System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, 300, 120)
$g.Dispose(); Save-Bmp $b 'bg2.png'

# --- btn: 24x24 Magenta-Kreis ---
$p = New-Bmp 24 24; $b=$p[0]; $g=$p[1]
$g.FillEllipse([System.Drawing.Brushes]::Magenta, 2,2,20,20)
$g.DrawEllipse((New-Object System.Drawing.Pen([System.Drawing.Color]::Black,2)), 2,2,20,20)
$g.Dispose(); Save-Bmp $b 'btn.png'

# --- thumb: 16x16 gelber Kreis ---
$p = New-Bmp 16 16; $b=$p[0]; $g=$p[1]
$g.FillEllipse([System.Drawing.Brushes]::Gold, 1,1,14,14)
$g.DrawEllipse((New-Object System.Drawing.Pen([System.Drawing.Color]::Black,1)), 1,1,14,14)
$g.Dispose(); Save-Bmp $b 'thumb.png'

# --- led off/on: 14x14 ---
$p = New-Bmp 14 14; $b=$p[0]; $g=$p[1]
$g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,60,60,60))), 1,1,12,12)
$g.DrawEllipse((New-Object System.Drawing.Pen([System.Drawing.Color]::Black,1)), 1,1,12,12)
$g.Dispose(); Save-Bmp $b 'ledoff.png'
$p = New-Bmp 14 14; $b=$p[0]; $g=$p[1]
$g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,60,255,60))), 1,1,12,12)
$g.DrawEllipse((New-Object System.Drawing.Pen([System.Drawing.Color]::Black,1)), 1,1,12,12)
$g.Dispose(); Save-Bmp $b 'ledon.png'

# --- vidframe: 200x150 Schachbrett ---
$p = New-Bmp 200 150; $b=$p[0]; $g=$p[1]
$c1=[System.Drawing.Color]::FromArgb(255,18,18,28); $c2=[System.Drawing.Color]::FromArgb(255,50,50,80)
for($y=0; $y -lt 150; $y+=25){ for($x=0; $x -lt 200; $x+=25){
  $c = if((($x/25)+($y/25)) % 2 -eq 0){$c1}else{$c2}
  $g.FillRectangle((New-Object System.Drawing.SolidBrush($c)), $x,$y,25,25) } }
$g.DrawString('SCREEN', (New-Object System.Drawing.Font('Segoe UI',14,[System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, 60, 60)
$g.Dispose(); Save-Bmp $b 'vidframe.png'

# --- popbg: 160x80 ---
$p = New-Bmp 160 80; $b=$p[0]; $g=$p[1]
$pts = [System.Drawing.Point[]]@( (P 1 1),(P 158 1),(P 158 78),(P 20 78),(P 1 60) )
$g.FillPolygon((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,90,30,110))), $pts)
$g.DrawPolygon((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,200,120,255), 2)), $pts)
$g.Dispose(); Save-Bmp $b 'popbg.png'

# --- track_v: 8x200, 5 Frames je 8x40 (dunkel -> hell) ---
$p = New-Bmp 8 200; $b=$p[0]; $g=$p[1]
$cols = @( [System.Drawing.Color]::FromArgb(255,30,50,20), [System.Drawing.Color]::FromArgb(255,55,95,30), [System.Drawing.Color]::FromArgb(255,85,150,40), [System.Drawing.Color]::FromArgb(255,120,200,60), [System.Drawing.Color]::FromArgb(255,160,240,90) )
for($f=0; $f -lt 5; $f++){ $g.FillRectangle((New-Object System.Drawing.SolidBrush($cols[$f])), 0, ($f*40), 8, 40) }
$g.Dispose(); Save-Bmp $b 'track_v.png'

# --- track_h: 160x8, 4 Frames je 40x8 (Füllstand 25/50/75/100%) ---
$p = New-Bmp 160 8; $b=$p[0]; $g=$p[1]
for($f=0; $f -lt 4; $f++){
  $g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,25,40,15))), ($f*40), 0, 40, 8)
  $fillW = [int](40 * ($f+1) / 4)
  $g.FillRectangle([System.Drawing.Brushes]::Lime, ($f*40), 2, $fillW, 4)
}
$g.Dispose(); Save-Bmp $b 'track_h.png'

Get-ChildItem $out | Select-Object Name, Length | Format-Table -AutoSize
