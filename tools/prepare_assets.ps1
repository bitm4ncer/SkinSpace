# prepare_assets.ps1 — Asset-Pipeline Headspace-Port (v2: Mask-Injection + Modus)
# Modi: 'ai'      = Real-ESRGAN 4x -> 2x, Alpha-Maske deterministisch aus Original (verwirft KI-Halluzinationen in Key-Flächen)
#       'lanczos' = Hochwertiger Bicubic-Scale auf 2x (für flache/geometrische Assets, die KI zerstört), dann gleiche Maske
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = 'C:\GitHub\VLC_Skins'
$RG   = Join-Path $root 'tools\realesrgan\realesrgan-ncnn-vulkan.exe'
$TMP  = Join-Path $root 'tools\tmp'

function Initialize-Tmp { if (-not (Test-Path $TMP)) { New-Item -ItemType Directory -Path $TMP -Force | Out-Null } }

function ConvertTo-Png32 {
  param([string]$In, [string]$Out)
  $b = New-Object System.Drawing.Bitmap($In)
  $b2 = $b.Clone((New-Object System.Drawing.Rectangle(0,0,$b.Width,$b.Height)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $b.Dispose()
  $b2.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
  $b2.Dispose()
}

function Invoke-Upscale4x {
  param([string]$In, [string]$Out, [string]$Model)
  # Start-Process statt Pipeline (Broken-Pipe-Crash); WorkingDirectory = Exe-Ordner (models\ wird relativ zum CWD gesucht).
  $exeDir = Split-Path -Parent $RG
  $errLog = Join-Path $TMP 'realesrgan.err.log'
  $attempt = 0
  while ($attempt -lt 2) {
    $attempt++
    $p = Start-Process -FilePath $RG -WorkingDirectory $exeDir `
      -ArgumentList @('-i', $In, '-o', $Out, '-s', '4', '-n', $Model) `
      -NoNewWindow -Wait -PassThru -RedirectStandardError $errLog
    if ($p.ExitCode -eq 0 -and (Test-Path $Out)) { return }
    Start-Sleep -Milliseconds 500
  }
  $tail = ''
  if (Test-Path $errLog) { $tail = ((Get-Content $errLog -Tail 3) -join ' | ') }
  throw "realesrgan fehlgeschlagen (2 Versuche) fuer $In ($Model): $tail"
}

function ScaleTo2x {
  param([string]$In, [string]$Out)
  $s = New-Object System.Drawing.Bitmap($In)
  $dst = New-Object System.Drawing.Bitmap(($s.Width*2), ($s.Height*2), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.DrawImage($s, 0, 0, $dst.Width, $dst.Height)
  $g.Dispose(); $s.Dispose()
  $dst.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
  $dst.Dispose()
}

function DownscaleTo2x {
  param([string]$In, [string]$Out)
  $big = New-Object System.Drawing.Bitmap($In)
  $tw = [int]($big.Width / 2); $th = [int]($big.Height / 2)
  $dst = New-Object System.Drawing.Bitmap($tw, $th, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($dst)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.DrawImage($big, (New-Object System.Drawing.Rectangle(0,0,$tw,$th)))
  $g.Dispose(); $big.Dispose()
  $dst.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
  $dst.Dispose()
}

function Apply-KeyMask {
  # v3: weiche Maske — binaere Content-Map (Original, 1px erodiert) wird BILINEAR auf 2x abgetastet
  # -> glatte, antialiasing-artige Aussenkontur; keine harten Pixelstufen. Innenfarben (KI/Lanczos) bleiben.
  param([string]$Content2x, [string]$OrigBmp, [string[]]$Keys, [string]$OutPath, [double]$EdgeLow = 0.25, [double]$EdgeHigh = 0.85)
  $keys2 = @()
  foreach ($k in $Keys) { $keys2 += ,@([Convert]::ToInt32($k.Substring(1,2),16), [Convert]::ToInt32($k.Substring(3,2),16), [Convert]::ToInt32($k.Substring(5,2),16)) }
  # 1) Original laden -> binaere Content-Map (0=key, 1=content), 1px Erosion
  $ob = New-Object System.Drawing.Bitmap($OrigBmp)
  $ow = $ob.Width; $oh = $ob.Height
  $ob2 = $ob.Clone((New-Object System.Drawing.Rectangle(0,0,$ow,$oh)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $ob.Dispose()
  $od = $ob2.LockBits((New-Object System.Drawing.Rectangle(0,0,$ow,$oh)), [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $os = $od.Stride; $ol = $os * $oh
  $obytes = New-Object byte[] $ol
  [System.Runtime.InteropServices.Marshal]::Copy($od.Scan0, $obytes, 0, $ol)
  $ob2.UnlockBits($od); $ob2.Dispose()
  $raw = New-Object byte[] ($ow * $oh)
  for ($y = 0; $y -lt $oh; $y++) {
    for ($x = 0; $x -lt $ow; $x++) {
      $oi = $y * $os + $x * 4
      $orr = $obytes[$oi+2]; $ogg = $obytes[$oi+1]; $obb = $obytes[$oi]
      $isKey = $false
      foreach ($t in $keys2) {
        if ($orr -eq $t[0] -and $ogg -eq $t[1] -and $obb -eq $t[2]) { $isKey = $true; break }
      }
      $raw[$y * $ow + $x] = if ($isKey) { 0 } else { 1 }
    }
  }
  $map = New-Object byte[] ($ow * $oh)
  for ($y = 0; $y -lt $oh; $y++) {
    for ($x = 0; $x -lt $ow; $x++) {
      $v = 1
      for ($dy = -1; $dy -le 1 -and $v -eq 1; $dy++) {
        for ($dx = -1; $dx -le 1 -and $v -eq 1; $dx++) {
          $sx = $x + $dx; $sy = $y + $dy
          if ($sx -lt 0 -or $sy -lt 0 -or $sx -ge $ow -or $sy -ge $oh) { continue }
          if ($raw[$sy * $ow + $sx] -eq 0) { $v = 0 }
        }
      }
      $map[$y * $ow + $x] = $v
    }
  }
  # 2) Content laden
  $cb = New-Object System.Drawing.Bitmap($Content2x)
  $cw = $cb.Width; $ch = $cb.Height
  $cb2 = $cb.Clone((New-Object System.Drawing.Rectangle(0,0,$cw,$ch)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $cb.Dispose()
  $cd = $cb2.LockBits((New-Object System.Drawing.Rectangle(0,0,$cw,$ch)), [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $cs = $cd.Stride; $cl = $cs * $ch
  $cbytes = New-Object byte[] $cl
  [System.Runtime.InteropServices.Marshal]::Copy($cd.Scan0, $cbytes, 0, $cl)
  # 3) Bilineare Abtastung der Maske (2x-Zielpixel -> Originalkoordinaten)
  $range = $EdgeHigh - $EdgeLow
  for ($y = 0; $y -lt $ch; $y++) {
    $j = [int]($y / 2); $fy = if ($y % 2 -eq 1) { 0.5 } else { 0.0 }
    if ($j -ge $oh) { $j = $oh - 1; $fy = 0.0 }
    $j1 = [Math]::Min($j + 1, $oh - 1)
    for ($x = 0; $x -lt $cw; $x++) {
      $i = [int]($x / 2); $fx = if ($x % 2 -eq 1) { 0.5 } else { 0.0 }
      if ($i -ge $ow) { $i = $ow - 1; $fx = 0.0 }
      $i1 = [Math]::Min($i + 1, $ow - 1)
      $p00 = $map[$j * $ow + $i]; $p10 = $map[$j * $ow + $i1]
      $p01 = $map[$j1 * $ow + $i]; $p11 = $map[$j1 * $ow + $i1]
      $a = (1-$fx)*(1-$fy)*$p00 + $fx*(1-$fy)*$p10 + (1-$fx)*$fy*$p01 + $fx*$fy*$p11
      $a2 = ($a - $EdgeLow) / $range
      if ($a2 -lt 0) { $a2 = 0 } elseif ($a2 -gt 1) { $a2 = 1 }
      $ci = $y * $cs + $x * 4
      $cbytes[$ci+3] = [byte][Math]::Round($a2 * 255)
    }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($cbytes, 0, $cd.Scan0, $cl)
  $cb2.UnlockBits($cd)
  $cb2.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $cb2.Dispose()
}

function Remove-KeyColor {
  # Fallback/Passthrough ohne Maske (nur exakte Keys + Near-Feather). Speichert nach $OutPath (nie auf geladenen Pfad).
  param([string]$Path, [string[]]$Keys, [string]$OutPath)
  if (-not $OutPath) { $OutPath = "$Path.keyed.png" }
  if (-not $Keys -or $Keys.Count -eq 0) { Copy-Item $Path $OutPath -Force; return 0 }
  $tripels = @()
  foreach ($k in $Keys) { $tripels += ,@([Convert]::ToInt32($k.Substring(1,2),16), [Convert]::ToInt32($k.Substring(3,2),16), [Convert]::ToInt32($k.Substring(5,2),16)) }
  $b = New-Object System.Drawing.Bitmap($Path)
  $b2 = $b.Clone((New-Object System.Drawing.Rectangle(0,0,$b.Width,$b.Height)), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $b.Dispose()
  $w = $b2.Width; $h = $b2.Height
  $d = $b2.LockBits((New-Object System.Drawing.Rectangle(0,0,$w,$h)), [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $stride = $d.Stride; $len = $stride * $h
  $bytes = New-Object byte[] $len
  [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0, $bytes, 0, $len)
  $removed = 0
  for ($i = 0; $i -lt $len; $i += 4) {
    $bb = $bytes[$i]; $gg = $bytes[$i+1]; $rr = $bytes[$i+2]
    foreach ($t in $tripels) {
      if ($rr -eq $t[0] -and $gg -eq $t[1] -and $bb -eq $t[2]) { $bytes[$i+3] = 0; $removed++; break }
    }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $d.Scan0, $len)
  $b2.UnlockBits($d)
  $b2.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $b2.Dispose()
  return $removed
}

function Convert-HeadspaceAsset {
  # Voll-Pipeline: BMP -> PNG32 -> 4x AI (oder Lanczos 2x) -> 2x -> Key-Maske aus Original -> PNG
  param(
    [Parameter(Mandatory)][string]$InFile,
    [Parameter(Mandatory)][string]$OutFile,
    [string]$KeyColor,
    [string[]]$Keys = @(),
    [ValidateSet('ai','lanczos')][string]$Mode = 'ai',
    [string]$Model = 'realesrgan-x4plus',
    [int]$TargetScale = 2
  )
  if ($KeyColor) { $Keys = @($Keys) + $KeyColor }
  if ($TargetScale -ne 2) { throw "Nur TargetScale=2 unterstuetzt (bekommen: $TargetScale)" }
  Initialize-Tmp
  $base = [System.IO.Path]::GetFileNameWithoutExtension($InFile)
  $png = Join-Path $TMP "$base.src.png"
  ConvertTo-Png32 -In $InFile -Out $png
  $hasKeys = ($Keys -and $Keys.Count -gt 0)
  if ($Mode -eq 'ai') {
    $big = Join-Path $TMP "$base.$Model.4x.png"
    $mid = Join-Path $TMP "$base.$Model.2x.png"
    Invoke-Upscale4x -In $png -Out $big -Model $Model
    DownscaleTo2x -In $big -Out $mid
  } else {
    $mid = Join-Path $TMP "$base.lanczos.2x.png"
    ScaleTo2x -In $png -Out $mid
  }
  $outDir = Split-Path -Parent $OutFile
  if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
  if ($hasKeys) {
    Apply-KeyMask -Content2x $mid -OrigBmp $InFile -Keys $Keys -OutPath $OutFile
    $removed = -1   # Maske: exakte Zahl nicht sinnvoll, transparent-Flaechen zaehlt verify_asset
  } else {
    Copy-Item $mid $OutFile -Force
    $removed = 0
  }
  return [pscustomobject]@{ Out = $OutFile; Mode = $Mode; KeysRemoved = $removed }
}
