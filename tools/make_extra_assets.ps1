# make_extra_assets.ps1 - erzeugt die Zusatz-Assets (unser Ersatz-Design, Stil an Original angelehnt)
# Ausgaben nach src/theme/images/ (werden von make_scaled_variant fuer 2x/3x mit-skaliert)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = 'C:\GitHub\VLC_Skins\src\theme\images'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

function Save-Bmp($b, [string]$name){
  $b.Save((Join-Path $dir $name), [System.Drawing.Imaging.ImageFormat]::Png)
  $b.Dispose()
}

# --- Mute-LED (14x14): on/off ---
foreach($on in @($false, $true)){
  $b = New-Object System.Drawing.Bitmap(14, 14, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)
  $fill = if($on){ [System.Drawing.Color]::FromArgb(255,120,220,30) } else { [System.Drawing.Color]::FromArgb(255,40,95,5) }
  $rim  = if($on){ [System.Drawing.Color]::FromArgb(255,60,120,10) } else { [System.Drawing.Color]::FromArgb(255,25,60,3) }
  $g.FillEllipse((New-Object System.Drawing.SolidBrush($fill)), 2, 2, 10, 10)
  $g.DrawEllipse((New-Object System.Drawing.Pen($rim, 2)), 2, 2, 10, 10)
  if($on){
    $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200,220,255,180))), 5, 4, 4, 3)
  }
  $g.Dispose()
  $name = if($on){'led_on.png'}else{'led_off.png'}
  Save-Bmp $b $name
}

# --- Drawer-Fuellung (8x8 flat #285F03) ---
$b = New-Object System.Drawing.Bitmap(8, 8, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.Clear([System.Drawing.Color]::FromArgb(255, 40, 95, 3))
$g.Dispose()
Save-Bmp $b 'drawer_fill.png'

# --- "reset"-Link (unterstrichen, KRISP gerendert + hell fuer Lesbarkeit): on/off ---
foreach($on in @($false, $true)){
  $b = New-Object System.Drawing.Bitmap(24, 10, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::SingleBitPerPixelGridFit
  $g.Clear([System.Drawing.Color]::Transparent)
  $col = if($on){ [System.Drawing.Color]::FromArgb(255,232,255,192) } else { [System.Drawing.Color]::FromArgb(255,168,208,96) }
  $f = New-Object System.Drawing.Font('Segoe UI', 7.5)
  $br = New-Object System.Drawing.SolidBrush($col)
  $g.DrawString('reset', $f, $br, 0, -1)
  $g.DrawLine((New-Object System.Drawing.Pen($col, 1)), 0, 9, 21, 9)
  $f.Dispose(); $br.Dispose(); $g.Dispose()
  $name = if($on){'eq_link_on.png'}else{'eq_link_off.png'}
  Save-Bmp $b $name
}

# --- Playlist-Optik: Checkbox + Scrollbar (WMP rendert das intern; stilgerecht nachgebaut) ---
# Checkbox 10x10 (dunkle Box, heller Haken) - wird via itemimage in jeder Playlist-Zeile gezeichnet
$b = New-Object System.Drawing.Bitmap(10, 10, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::Transparent)
$g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,15,42,0))), 0, 0, 10, 10)
$g.DrawRectangle((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,26,61,2), 1)), 0, 0, 9, 9)
$penC = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,119,206,7), 2)
[System.Drawing.Point[]]$ptsC = @((New-Object System.Drawing.Point(2,5)), (New-Object System.Drawing.Point(4,7)), (New-Object System.Drawing.Point(8,3)))
$g.DrawLines($penC, $ptsC)
$g.Dispose()
Save-Bmp $b 'pl_check.png'

# Pfeile 12x12 (oben/unten, default/rollover)
foreach($ud in @('up','down')){
  foreach($hv in @($false, $true)){
    $b = New-Object System.Drawing.Bitmap(12, 12, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $bgc = if($hv){ [System.Drawing.Color]::FromArgb(255,53,111,8) } else { [System.Drawing.Color]::FromArgb(255,36,84,3) }
    $trc = if($hv){ [System.Drawing.Color]::FromArgb(255,168,232,90) } else { [System.Drawing.Color]::FromArgb(255,119,206,7) }
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($bgc)), 0, 0, 12, 12)
    $g.DrawRectangle((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,26,61,2), 1)), 0, 0, 11, 11)
    if($ud -eq 'up'){ [System.Drawing.Point[]]$pts = @((New-Object System.Drawing.Point(2,8)), (New-Object System.Drawing.Point(6,4)), (New-Object System.Drawing.Point(10,8))) }
    else { [System.Drawing.Point[]]$pts = @((New-Object System.Drawing.Point(2,4)), (New-Object System.Drawing.Point(6,8)), (New-Object System.Drawing.Point(10,4))) }
    $g.FillPolygon((New-Object System.Drawing.SolidBrush($trc)), $pts)
    $g.Dispose()
    $sfx = if($hv){'02_rollover'}else{'01_default'}
    Save-Bmp $b ("pl_arrow_{0}_{1}.png" -f $ud, $sfx)
  }
}

# Scroll-Track 12x116 (helle Rinne) + Thumb 12x18 (3 Zustaende)
$b = New-Object System.Drawing.Bitmap(12, 116, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($b)
$g.Clear([System.Drawing.Color]::Transparent)
$g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,26,61,2))), 0, 0, 12, 116)
$g.FillRectangle((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,53,111,8))), 1, 1, 10, 114)
$g.Dispose()
Save-Bmp $b 'pl_scroll_track.png'

foreach($st in @('01_default','02_rollover','03_down')){
  $b = New-Object System.Drawing.Bitmap(12, 18, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.Clear([System.Drawing.Color]::Transparent)
  $bgc = switch($st){ '01_default' { [System.Drawing.Color]::FromArgb(255,26,61,2) } '02_rollover' { [System.Drawing.Color]::FromArgb(255,36,84,3) } '03_down' { [System.Drawing.Color]::FromArgb(255,53,111,8) } }
  $grc = switch($st){ '01_default' { [System.Drawing.Color]::FromArgb(255,119,206,7) } '02_rollover' { [System.Drawing.Color]::FromArgb(255,168,232,90) } '03_down' { [System.Drawing.Color]::FromArgb(255,200,240,122) } }
  $g.FillRectangle((New-Object System.Drawing.SolidBrush($bgc)), 0, 0, 12, 18)
  $g.DrawRectangle((New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,15,42,0), 1)), 0, 0, 11, 17)
  $g.FillRectangle((New-Object System.Drawing.SolidBrush($grc)), 3, 7, 6, 1)
  $g.FillRectangle((New-Object System.Drawing.SolidBrush($grc)), 3, 10, 6, 1)
  $g.Dispose()
  Save-Bmp $b ("pl_scroll_thumb_{0}.png" -f $st)
}

Get-ChildItem $dir -Filter 'led_*' | Select-Object Name
Get-ChildItem $dir -Filter 'eq_link_*' | Select-Object Name
Get-ChildItem $dir -Filter 'drawer_fill*' | Select-Object Name
Get-ChildItem $dir -Filter 'pl_*' | Select-Object Name
'OK: Zusatz-Assets erzeugt'
exit 0
