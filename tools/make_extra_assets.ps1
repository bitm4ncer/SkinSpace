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

# --- "reset"-Link (unterstrichen): on/off (Funktion: EQ an/aus; Original-Text "reset" beibehalten) ---
foreach($on in @($false, $true)){
  $b = New-Object System.Drawing.Bitmap(24, 10, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($b)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)
  $col = if($on){ [System.Drawing.Color]::FromArgb(255,119,206,7) } else { [System.Drawing.Color]::FromArgb(255,85,130,34) }
  $f = New-Object System.Drawing.Font('Segoe UI', 7)
  $br = New-Object System.Drawing.SolidBrush($col)
  $g.DrawString('reset', $f, $br, 0, -1)
  $g.DrawLine((New-Object System.Drawing.Pen($col, 1)), 0, 9, 21, 9)
  $f.Dispose(); $br.Dispose(); $g.Dispose()
  $name = if($on){'eq_link_on.png'}else{'eq_link_off.png'}
  Save-Bmp $b $name
}

Get-ChildItem $dir -Filter 'led_*' | Select-Object Name
Get-ChildItem $dir -Filter 'eq_link_*' | Select-Object Name
Get-ChildItem $dir -Filter 'drawer_fill*' | Select-Object Name
'OK: Zusatz-Assets erzeugt'
exit 0
