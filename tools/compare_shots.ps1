# compare_shots.ps1 — Pixel-Diff zwischen Screenshot und Referenz (gleiche Groesse), mit 10x10-Zonenbericht
param(
  [Parameter(Mandatory)][string]$A,     # Referenz (z.B. state-A)
  [Parameter(Mandatory)][string]$B,     # Screenshot
  [Parameter(Mandatory)][string]$Out,   # Ausgabe-Overlay
  [int]$Thr = 24
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Load-Bytes([string]$p){
  $b = New-Object System.Drawing.Bitmap($p)
  $w=$b.Width; $h=$b.Height
  $b2 = $b.Clone((New-Object System.Drawing.Rectangle(0,0,$w,$h)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $b.Dispose()
  $d = $b2.LockBits((New-Object System.Drawing.Rectangle(0,0,$w,$h)), [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $s = $d.Stride; $by = New-Object byte[] ($s*$h)
  [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $by, 0, $by.Length)
  $b2.UnlockBits($d); $b2.Dispose()
  return @{ W=$w; H=$h; S=$s; B=$by }
}
$ra = Load-Bytes $A
$rb = Load-Bytes $B
if($ra.W -ne $rb.W -or $ra.H -ne $rb.H){ Write-Host "FAIL: Groessen unterschiedlich ($($ra.W)x$($ra.H) vs $($rb.W)x$($rb.H))"; exit 1 }
$w=$ra.W; $h=$ra.H

$diff = New-Object System.Drawing.Bitmap($w,$h,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$dgr = [System.Drawing.Graphics]::FromImage($diff)
$imgA = New-Object System.Drawing.Bitmap($A)
$dgr.DrawImage($imgA,0,0); $dgr.Dispose(); $imgA.Dispose()

$grid = @{}
$total = 0
for($y=0;$y -lt $h;$y++){
  for($x=0;$x -lt $w;$x++){
    $ia = $y*$ra.S + $x*4; $ib = $y*$rb.S + $x*4
    $dd = 0
    foreach($o in 0,1,2,3){
      $v = [Math]::Abs([int]$ra.B[$ia+$o] - [int]$rb.B[$ib+$o])
      if($v -gt $dd){ $dd = $v }
    }
    if($dd -gt $Thr){
      $total++
      $diff.SetPixel($x,$y,[System.Drawing.Color]::FromArgb(255,255,0,255))
      $gx = [int]($x/55); $gy = [int]($y/40)   # 10x10-ish Zellen
      $k = "$gx,$gy"
      if(-not $grid.ContainsKey($k)){ $grid[$k] = 0 }
      $grid[$k]++
    }
  }
}
$diff.Save($Out,[System.Drawing.Imaging.ImageFormat]::Png); $diff.Dispose()
"Diff-Pixel (Thr=$Thr): $total von $($w*$h) ($([Math]::Round(100.0*$total/($w*$h),2))%)"
"--- Top-Zonen (Zelle 55x40px, x,y ab 0) ---"
$grid.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 12 | ForEach-Object {
  $p = $_.Key -split ','
  $x0=[int]$p[0]*55; $y0=[int]$p[1]*40
  "Zone ($x0,$y0)-($($x0+54),$($y0+39)): $($_.Value) Diff-Pixel"
}
exit 0
