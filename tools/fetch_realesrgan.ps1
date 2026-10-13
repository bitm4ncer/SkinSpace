$ErrorActionPreference = 'Stop'
$tools = 'C:\GitHub\VLC_Skins\tools'
$dest  = Join-Path $tools 'realesrgan'
$zip   = Join-Path $tools 'realesrgan.zip'
$exe   = Join-Path $dest 'realesrgan-ncnn-vulkan.exe'

if (Test-Path $exe) { "realesrgan bereits vorhanden: $exe"; exit 0 }

$url = 'https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesrgan-ncnn-vulkan-20220424-windows.zip'
'Downloading: ' + $url
curl.exe -L --fail --silent --show-error -o $zip $url
'Download ok: ' + (Get-Item $zip).Length + ' bytes'

& 'C:\Program Files\7-Zip\7z.exe' x -y -o"$dest" $zip | Select-Object -Last 2
Remove-Item $zip

'--- Inhalt ---'
Get-ChildItem $dest | Select-Object Name, Length | Format-Table -AutoSize
'--- Modelle ---'
Get-ChildItem (Join-Path $dest 'models') -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

'--- Funktionscheck (-h, Exit 1 + stderr = normal) ---'
$prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
$out = & $exe -h 2>&1 | Out-String
$ErrorActionPreference = $prev
($out -split "`n" | Select-Object -First 6) -join "`n"
'exe ok: ' + (Test-Path $exe)
