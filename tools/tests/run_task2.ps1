# run_task2.ps1 — Testrunner für Task 2 (Assets 1:1 + Builder)
$fail = 0
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'test_original_assets.ps1')
if($LASTEXITCODE -ne 0){ $fail = 1 }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'test_build_theme.ps1')
if($LASTEXITCODE -ne 0){ $fail = 1 }
if($fail -eq 0){ Write-Host 'PASS: Task-2-Suite (Assets 78/78 + Builder 2/2)'; exit 0 }
Write-Host 'FAIL: Task-2-Suite'
exit 1
