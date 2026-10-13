# build_theme.ps1 — assembliert src/theme/theme.xml aus XML-Fragmenten und validiert.
# Parameter: -Scale (Koordinaten-Multiplikator; 1 = Originalgröße), -FragmentDir (für Tests), -OutFile
param(
  [int]$Scale = 1,
  [string]$Root = 'C:\GitHub\VLC_Skins',
  [string]$FragmentDir,
  [string]$OutFile
)
$ErrorActionPreference = 'Stop'
if(-not $FragmentDir){ $FragmentDir = Join-Path $Root 'src\theme\xml' }
if(-not $OutFile){ $OutFile = Join-Path $Root 'src\theme\theme.xml' }

function Read-Frag([string]$name){
  $p = Join-Path $FragmentDir $name
  if(-not (Test-Path $p)){ throw "Fragment fehlt: $p" }
  return (Get-Content $p -Raw)
}
function Scale-Xml([string]$xml, [int]$s){
  if($s -eq 1){ return $xml }
  $xml = [regex]::Replace($xml, '(\b(?:x|y|width|height|thickness|size)\s*=\s*")(-?\d+)(")', {
    param($m) $m.Groups[1].Value + ([int]$m.Groups[2].Value * $s) + $m.Groups[3].Value
  })
  $xml = [regex]::Replace($xml, 'points\s*=\s*"([^"]+)"', {
    param($m)
    $inner = [regex]::Replace($m.Groups[1].Value, '-?\d+', { param($n) ([int]$n.Value * $s).ToString() })
    'points="' + $inner + '"'
  })
  return $xml
}

$header  = Read-Frag 'header.xml'
$bitmaps = Read-Frag 'bitmaps.xml'
$layouts = @(
  @{ id='l_eq';     file='layout_eq.xml';     w=549 },
  @{ id='l_pl';     file='layout_pl.xml';     w=760 },
  @{ id='l_both';   file='layout_both.xml';   w=760 },
  @{ id='l_closed'; file='layout_closed.xml'; w=549 }
)
$w = 549 * $Scale
$h = 394 * $Scale

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
[void]$sb.AppendLine('<!DOCTYPE Theme PUBLIC "-//VideoLAN//DTD VLC Skins V2.0//EN" "skin.dtd">')
[void]$sb.AppendLine('<Theme version="2.0">')
[void]$sb.AppendLine((Scale-Xml $header $Scale))
[void]$sb.AppendLine((Scale-Xml $bitmaps $Scale))
[void]$sb.AppendLine((Scale-Xml (Read-Frag 'subbitmaps.xml') $Scale))
[void]$sb.AppendLine((Scale-Xml (Read-Frag 'extras.xml') $Scale))
[void]$sb.AppendLine('  <Window id="main" position="Center">')
foreach($l in $layouts){
  [void]$sb.AppendLine(('    <Layout id="{0}" width="{1}" height="{2}">' -f $l.id, ($l.w * $Scale), ($h)))
  [void]$sb.AppendLine((Scale-Xml (Read-Frag $l.file) $Scale))
  [void]$sb.AppendLine('    </Layout>')
}
[void]$sb.AppendLine('  </Window>')
[void]$sb.AppendLine('</Theme>')
$text = $sb.ToString()

# ---------- Validierung ----------
$errors = New-Object System.Collections.Generic.List[string]

# 1) XML wohlgeformt
$doc = $null
try { $doc = New-Object System.Xml.XmlDocument; $doc.XmlResolver = $null; $doc.LoadXml($text) }
catch { $errors.Add("XML nicht parsebar: $($_.Exception.Message)") }

if($doc -ne $null){
  # 2) IDs eindeutig (global)
  $ids = @{}
  foreach($m in [regex]::Matches($text, '\bid="([^"]+)"')){
    $idv = $m.Groups[1].Value
    if($ids.ContainsKey($idv)){ $errors.Add("Doppelte id: '$idv'") } else { $ids[$idv] = $true }
  }
  # 3) Referenzen existieren
  $refAttr = '(?:image|up|down|over|up1|up2|down1|down2|over1|over2|background|bgimage|itemimage|openimage|closedimage|mappingImage)'
  foreach($m in [regex]::Matches($text, ($refAttr + '="([^"]+)"'))){
    $v = $m.Groups[1].Value
    if($v -eq '' -or $v -eq 'none'){ continue }
    if(-not $ids.ContainsKey($v)){ $errors.Add("Referenz ohne Deklaration: '$v'") }
  }
  # 4) Datei-Existenz: alle file="..."-Pfade muessen relativ zum Ausgabeordner existieren (nur wenn dort ein images/-Ordner liegt)
  $stageDir = Split-Path -Parent $OutFile
  if(Test-Path (Join-Path $stageDir 'images')){
    foreach($m in [regex]::Matches($text, '\bfile="([^"]+)"')){
      $rel = $m.Groups[1].Value
      $full = Join-Path $stageDir $rel
      if(-not (Test-Path $full)){ $errors.Add("Datei fehlt fuer file=`"$rel`": $full") }
    }
  }
  # 5) Koordinaten innerhalb der Layoutmaße
  foreach($layout in $doc.SelectNodes('//Layout')){
    $lw = [int]$layout.GetAttribute('width'); $lh = [int]$layout.GetAttribute('height')
    $lid = $layout.GetAttribute('id')
    foreach($c in $layout.SelectNodes('./child::*')){
      $xs = $c.GetAttribute('x'); $ys = $c.GetAttribute('y')
      $xi = 0; $yi = 0
      if($xs -ne '' -and [int]::TryParse($xs, [ref]$xi)){ if($xi -lt 0 -or $xi -gt $lw){ $errors.Add("[$lid] ${xi}: x ausserhalb (0..$lw) bei <$($c.Name)>") } }
      if($ys -ne '' -and [int]::TryParse($ys, [ref]$yi)){ if($yi -lt 0 -or $yi -gt $lh){ $errors.Add("[$lid] ${yi}: y ausserhalb (0..$lh) bei <$($c.Name)>") } }
    }
  }
}

if($errors.Count -gt 0){
  foreach($e in $errors){ Write-Host "FAIL: $e" }
  Write-Host "FAIL: theme.xml nicht geschrieben ($($errors.Count) Fehler)"
  exit 1
}

$outDir = Split-Path -Parent $OutFile
if(-not (Test-Path $outDir)){ New-Item -ItemType Directory -Force -Path $outDir | Out-Null }
[System.IO.File]::WriteAllText($OutFile, $text, (New-Object System.Text.UTF8Encoding($false)))
$nLayouts = $doc.SelectNodes('//Layout').Count
$nCtrls = $doc.SelectNodes('//Layout/child::*').Count
Write-Host "OK: theme.xml -> $OutFile ($nLayouts Layouts, $($ids.Count) IDs, $nCtrls Controls, Scale=$Scale)"
exit 0
