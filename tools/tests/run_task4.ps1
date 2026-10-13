# run_task4.ps1 - Suite fuer Task 4: Builder-Regression + Build/Pack + EQ-Drawer-Interaktion
$root = 'C:\GitHub\VLC_Skins'
$fail = 0
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\tests\test_build_theme.ps1') | Out-Null
if($LASTEXITCODE -ne 0){ $fail = 1; Write-Host 'FAIL: Builder-Tests' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\build_theme.ps1') -Scale 1 | Out-Null
if($LASTEXITCODE -ne 0){ $fail = 1; Write-Host 'FAIL: build_theme' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\pack.ps1') | Out-Null
if($LASTEXITCODE -ne 0){ $fail = 1; Write-Host 'FAIL: pack' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\skin_interact_test.ps1') -ClickX 286 -ClickY 223 -Shot (Join-Path $root 'tools\tmp\eq_drawer_check.png')
if($LASTEXITCODE -ne 0){ $fail = 1 }
if($fail -eq 0){ Write-Host 'PASS: Task-4-Suite (EQ-Drawer oeffnet, Log sauber)'; exit 0 }
Write-Host 'FAIL: Task-4-Suite'
exit 1
