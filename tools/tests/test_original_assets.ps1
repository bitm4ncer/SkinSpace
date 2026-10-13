# test_original_assets.ps1 — verifiziert die 1:1-Konvertierung aller Original-Assets (Task 2)
$root = 'C:\GitHub\VLC_Skins'
$src  = Join-Path $root 'skins\headspace\originals\extracted'
$img  = Join-Path $root 'skins\headspace\theme\images'
Add-Type -AssemblyName System.Drawing

function Get-PixelStats([string]$path, [string[]]$keys) {
  $b = New-Object System.Drawing.Bitmap($path)
  $w = $b.Width; $h = $b.Height
  $b2 = $b.Clone((New-Object System.Drawing.Rectangle(0,0,$w,$h)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $b.Dispose()
  $d = $b2.LockBits((New-Object System.Drawing.Rectangle(0,0,$w,$h)), [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $s = $d.Stride; $len = $s*$h
  $bytes = New-Object byte[] $len
  [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $bytes, 0, $len)
  $b2.UnlockBits($d); $b2.Dispose()
  $counts = @{}
  foreach($k in $keys){ $counts[$k] = 0 }
  $tri = @()
  foreach($k in $keys){ $tri += ,@([Convert]::ToInt32($k.Substring(1,2),16),[Convert]::ToInt32($k.Substring(3,2),16),[Convert]::ToInt32($k.Substring(5,2),16),$k) }
  for($i=0; $i -lt $len; $i+=4){
    $bb=$bytes[$i]; $gg=$bytes[$i+1]; $rr=$bytes[$i+2]; $aa=$bytes[$i+3]
    if($aa -eq 255){
      foreach($t in $tri){ if($rr -eq $t[0] -and $gg -eq $t[1] -and $bb -eq $t[2]){ $counts[$t[3]]++ ; break } }
    }
  }
  return @{ W=$w; H=$h; Counts=$counts }
}

$bmps = Get-ChildItem $src -Filter '*.bmp' | Where-Object { $_.Name -notlike '*_map.bmp' } | Sort-Object Name
$n = 0; $ok = 0
foreach($f in $bmps){
  $n++
  $out = Join-Path $img ($f.BaseName + '.png')
  if(-not (Test-Path $out)){ Write-Host "FAIL: fehlt: $($f.BaseName).png"; continue }
  # Originaldimensionen
  $ob = New-Object System.Drawing.Bitmap($f.FullName); $ow=$ob.Width; $oh=$ob.Height; $ob.Dispose()
  $keys = @('#FF00FF')
  if($f.Name -eq 'head.bmp'){ $keys += '#FF0000' }
  if($f.Name -eq 'vid_bkgd.bmp'){ $keys = @('#FFFFFF') }
  $st = Get-PixelStats $out $keys
  $bad = @()
  if($st.W -ne $ow -or $st.H -ne $oh){ $bad += "Dim $($st.W)x$($st.H) != $ow x $oh" }
  foreach($k in $keys){ if($st.Counts[$k] -gt 0){ $bad += "Key $k noch opak: $($st.Counts[$k])" } }
  if($bad.Count -gt 0){ Write-Host "FAIL: $($f.BaseName): $($bad -join '; ')" ; continue }
  $ok++
}
if($ok -eq $n -and $n -gt 0){ Write-Host "PASS: $ok/$n Original-Assets 1:1 verifiziert"; exit 0 }
Write-Host "FAIL: $ok/$n Original-Assets verifiziert"
exit 1
