# test_variants.ps1 — prüft die Größenvarianten (Bilder exakt N×, theme.xml-Maße N×, .vlt vorhanden)
$root = 'C:\GitHub\VLC_Skins'
Add-Type -AssemblyName System.Drawing
$fail = 0
foreach($n in 2,3){
  $stage = Join-Path $root "skins\headspace\variants\${n}x"
  $srcImg = Join-Path $root 'skins\headspace\theme\images'
  $varImg = Join-Path $stage 'images'
  # 1) Bilder: gleiche Namen, exakt N×
  $bad = 0; $count = 0
  foreach($f in Get-ChildItem $srcImg -Filter '*.png'){
    $count++
    $o = Join-Path $varImg $f.Name
    if(-not (Test-Path $o)){ Write-Host "FAIL: ${n}x fehlt: $($f.Name)"; $bad++; continue }
    $b1 = New-Object System.Drawing.Bitmap($f.FullName)
    $b2 = New-Object System.Drawing.Bitmap($o)
    if($b2.Width -ne $b1.Width*$n -or $b2.Height -ne $b1.Height*$n){ Write-Host "FAIL: ${n}x Dim $($f.Name): $($b2.Width)x$($b2.Height) != $($b1.Width*$n)x$($b1.Height*$n)"; $bad++ }
    $b1.Dispose(); $b2.Dispose()
  }
  if($bad -gt 0){ $fail++; Write-Host "FAIL: ${n}x Bilder: $bad Fehler" } else { Write-Host "OK: ${n}x Bilder ($count Stueck) exakt skaliert" }
  # 2) theme.xml: Layout-Maße N×
  $tx = Join-Path $stage 'theme.xml'
  if(-not (Test-Path $tx)){ Write-Host "FAIL: ${n}x theme.xml fehlt"; $fail++ }
  else {
    $t = Get-Content $tx -Raw
    $mw = 549*$n; $mh = 394*$n
    if($t -match ('<Layout id="l_closed" width="' + $mw + '" height="' + $mh + '"')){ Write-Host "OK: ${n}x Layout-Masse ${mw}x${mh}" }
    else { Write-Host "FAIL: ${n}x Layout-Maße nicht ${mw}x${mh}"; $fail++ }
  }
  # 3) dist-vlt
  $vlt = Join-Path $root "dist\Headspace-${n}x.vlt"
  if(Test-Path $vlt){ Write-Host "OK: ${n}x vlt: $([int]((Get-Item $vlt).Length/1024)) KB" } else { Write-Host "FAIL: ${n}x vlt fehlt"; $fail++ }
}
if($fail -eq 0){ Write-Host 'PASS: Varianten-Tests (2x + 3x)'; exit 0 }
Write-Host "FAIL: Varianten-Tests ($fail Fehler)"
exit 1
