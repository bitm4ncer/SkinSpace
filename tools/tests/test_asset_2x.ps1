# test_asset_2x.ps1 — prüft die Sample-Renders beider Modelle (Task 1)
# Erwartet Ausgaben in research/upscale-review/renders/<name>.<model>.png
$root = 'C:\GitHub\VLC_Skins'
$renders = Join-Path $root 'research\upscale-review\renders'
$orig = Join-Path $root 'research\original\extracted'
$verify = Join-Path $root 'tools\tests\verify_asset.ps1'

$cases = @(
  @{ f='head.bmp';                     keys=@('#FF00FF','#FF0000') },
  @{ f='left_ear.bmp';                 keys=@('#FF00FF') },
  @{ f='right_ear.bmp';                keys=@('#FF00FF') },
  @{ f='play_controls_01_default.bmp'; keys=@() },
  @{ f='progressbar.bmp';              keys=@() },
  @{ f='progressbar_foreground.bmp';   keys=@() },
  @{ f='thumb_01_default.bmp';         keys=@('#FF00FF') },
  @{ f='L_drwr_open_01_default.bmp';   keys=@('#FF00FF') },
  @{ f='EQ_01_DF.bmp';                 keys=@() }
)
$models = @('x4plus','anime')
$n = 0; $ok = 0
foreach($c in $cases){
  $base = [System.IO.Path]::GetFileNameWithoutExtension($c.f)
  foreach($m in $models){
    $n++
    $outp = Join-Path $renders "$base.$m.png"
    & $verify -Original (Join-Path $orig $c.f) -Output $outp -Keys $c.keys
    if($LASTEXITCODE -eq 0){ $ok++ } else { Write-Host "ASSET FAIL: $base.$m" }
  }
}
if($ok -eq $n){ Write-Host "PASS: $ok/$n asset renders verified" ; exit 0 }
Write-Host "FAIL: $ok/$n asset renders verified"
exit 1
