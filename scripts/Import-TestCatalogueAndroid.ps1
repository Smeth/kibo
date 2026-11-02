param([string]$DeviceId)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path $PSScriptRoot -Parent)
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$dart = 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe'
$flutter = 'C:\flutter\bin\cache\flutter_tools.snapshot'
foreach ($path in @('config/supabase.public.json','config/supabase.local.json','config/seed.local.json','assets/test_catalogue/catalogue.json')) {
    if (-not (Test-Path -LiteralPath $path)) { throw 'Configuration locale de recette manquante.' }
}
$devices = @(& $adb devices | Where-Object { $_ -match '^\S+\s+device$' } | ForEach-Object { ($_ -split '\s+')[0] })
if (-not $DeviceId) {
    if ($devices.Count -ne 1) { throw 'Un seul appareil autorise doit etre connecte.' }
    $DeviceId = $devices[0]
}
if ($DeviceId -notin $devices) { throw 'Appareil cible absent.' }
$previousDebug = $env:DEBUG
try {
    $env:DEBUG = ''
    & $dart $flutter run -d $DeviceId --no-resident --no-pub -t tool/import_test_catalogue.dart --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json --dart-define-from-file=config/seed.local.json > .dart_tool/test-catalogue-launch.log 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Lancement du lanceur echoue ; journal local a expurger avant partage.' }
    Select-String -LiteralPath .dart_tool/test-catalogue-launch.log -Pattern '^Running Gradle|^Installing |^Syncing ' | ForEach-Object { $_.Line }
    Write-Output 'Lanceur installe. Cela ne confirme pas encore la fin de l import distant.'
} finally { $env:DEBUG = $previousDebug }
