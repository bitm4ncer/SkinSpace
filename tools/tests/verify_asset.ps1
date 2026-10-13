# verify_asset.ps1 — prüft ein aufbereitetes 2×-Asset gegen das Original
# Usage: verify_asset.ps1 -Original <bmp/png> -Output <png> [-Keys '#FF00FF',...] [-ExpectAlpha]
# Exit 0 = OK (letzte Ausgabezeile: PASS ...), sonst Exit 1 mit FAIL-Zeilen.
param(
  [Parameter(Mandatory)][string]$Original,
  [Parameter(Mandatory)][string]$Output,
  [string[]]$Keys = @(),
  [switch]$ExpectAlpha
)
Add-Type -AssemblyName System.Drawing
$fail = @()

if (-not (Test-Path $Output)) { Write-Host "FAIL: Output fehlt: $Output"; exit 1 }
if (-not (Test-Path $Original)) { Write-Host "FAIL: Original fehlt: $Original"; exit 1 }

$src = New-Object System.Drawing.Bitmap($Original)
$expW = $src.Width * 2; $expH = $src.Height * 2
$src.Dispose()

$b = New-Object System.Drawing.Bitmap($Output)
if ($b.Width -ne $expW -or $b.Height -ne $expH) {
  $fail += "Dimensionen: $($b.Width)x$($b.Height), erwartet ${expW}x${expH}"
}
$b2 = $b.Clone((New-Object System.Drawing.Rectangle(0,0,$b.Width,$b.Height)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$b.Dispose()
$rect = New-Object System.Drawing.Rectangle(0,0,$b2.Width,$b2.Height)
$data = $b2.LockBits($rect,[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$len = $data.Stride * $b2.Height
$bytes = New-Object byte[] $len
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0,$bytes,0,$len)
$b2.UnlockBits($data)

# Key-Tripel vorab parsen
$keyTriples = @()
foreach($k in $Keys){
  $keyTriples += ,@([Convert]::ToInt32($k.Substring(1,2),16),[Convert]::ToInt32($k.Substring(3,2),16),[Convert]::ToInt32($k.Substring(5,2),16),$k)
}
$keyCounts = @{}; foreach($k in $Keys){ $keyCounts[$k] = 0 }
$transparent = 0
$opaque = 0
for($i=0; $i -lt $len; $i+=4){
  $bb=$bytes[$i]; $gg=$bytes[$i+1]; $rr=$bytes[$i+2]; $aa=$bytes[$i+3]
  if($aa -eq 0){ $transparent++ } else { $opaque++ }
  if($keyTriples.Count -gt 0){
    foreach($t in $keyTriples){
      if($rr -eq $t[0] -and $gg -eq $t[1] -and $bb -eq $t[2] -and $aa -eq 255){ $keyCounts[$t[3]]++ }
    }
  }
}
foreach($k in $Keys){
  if($keyCounts[$k] -gt 0){ $fail += "Farbkey $k noch voll-opak vorhanden: $($keyCounts[$k]) Pixel" }
}
if(($Keys.Count -gt 0 -or $ExpectAlpha) -and $transparent -eq 0){
  $fail += "Keine transparenten Pixel vorhanden (Alpha fehlt)"
}

if($fail.Count -gt 0){
  foreach($f in $fail){ Write-Host "FAIL: $f" }
  Write-Host "FAIL: $Output"
  exit 1
}
Write-Host "OK: $Output ($($expW)x${expH}, transparent=$transparent, opak=$opaque)"
exit 0
