# test_build_theme.ps1 — Builder-Tests: Normalbau + Mutant (kaputte Referenz muss fehlschlagen)
$root = 'C:\GitHub\VLC_Skins'
$builder = Join-Path $root 'tools\build_theme.ps1'
$tmp = Join-Path $root 'tools\tmp'
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

$fail = 0

# --- Fall A: Normalbau ---
if(-not (Test-Path $builder)){ Write-Host "FAIL: Builder fehlt: $builder"; exit 1 }
$outA = Join-Path $tmp 'theme_testA.xml'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $builder -Scale 1 -OutFile $outA 2>&1 | Select-Object -Last 4
if($LASTEXITCODE -ne 0){ Write-Host "FAIL: Normalbau exit=$LASTEXITCODE"; $fail++ }
elseif(-not (Test-Path $outA)){ Write-Host "FAIL: theme.xml nicht geschrieben"; $fail++ }
else {
  try { $x = New-Object System.Xml.XmlDocument; $x.XmlResolver = $null; $x.Load($outA); Write-Host "OK: Normalbau valide XML" }
  catch { Write-Host "FAIL: XML nicht parsebar: $_"; $fail++ }
}

# --- Fall B: Mutant (image-Referenz auf nicht existierendes Bitmap) ---
$fragDir = Join-Path $tmp 'frag_broken'
New-Item -ItemType Directory -Force -Path $fragDir | Out-Null
Copy-Item (Join-Path $root 'src\theme\xml\*') $fragDir -Force
$closed = Join-Path $fragDir 'layout_closed.xml'
$txt = Get-Content $closed -Raw
$txt = $txt -replace 'image="head\.png"', 'image="doesnotexist.png"'
Set-Content $closed $txt -NoNewline
$outB = Join-Path $tmp 'theme_testB.xml'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $builder -Scale 1 -FragmentDir $fragDir -OutFile $outB 2>&1 | Select-Object -Last 4
if($LASTEXITCODE -eq 0){ Write-Host "FAIL: Mutant wurde akzeptiert (exit 0!)"; $fail++ }
else { Write-Host "OK: Mutant korrekt abgelehnt (exit=$LASTEXITCODE)" }

if($fail -eq 0){ Write-Host "PASS: Builder-Tests 2/2"; exit 0 }
Write-Host "FAIL: Builder-Tests ($fail Fehler)"
exit 1
