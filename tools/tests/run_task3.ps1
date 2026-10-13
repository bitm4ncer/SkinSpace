# run_task3.ps1 — Suite für Task 3: Assets + Builder + Build/Pack + Skin-Ladetest
$root = 'C:\GitHub\VLC_Skins'
$fail = 0
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\tests\test_original_assets.ps1')
if($LASTEXITCODE -ne 0){ $fail = 1 }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\tests\test_build_theme.ps1')
if($LASTEXITCODE -ne 0){ $fail = 1 }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\build_theme.ps1') -Scale 1
if($LASTEXITCODE -ne 0){ $fail = 1 }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\pack.ps1')
if($LASTEXITCODE -ne 0){ $fail = 1 }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\test_skin.ps1')
if($LASTEXITCODE -ne 0){ $fail = 1 }
if($fail -eq 0){ Write-Host 'PASS: Task-3-Suite (Assets + Builder + Ladetest)'; exit 0 }
Write-Host 'FAIL: Task-3-Suite'
exit 1
