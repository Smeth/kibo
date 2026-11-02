param([Parameter(Mandatory=$true)][string]$Lot,[string[]]$Tests=@('test'),[switch]$Photos,[switch]$Launch)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $repoRoot
$dart='C:\flutter\bin\cache\dart-sdk\bin\dart.exe'
$flutter='C:\flutter\bin\cache\flutter_tools.snapshot'
if ($Lot -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Invalid lot name' }
$logBase=Join-Path $repoRoot ('.dart_tool\mvp-'+$Lot)
$Tests=@($Tests | ForEach-Object { $_ -split ',' })
& $dart format --output=none --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { throw 'Format failed' }
& $dart $flutter analyze --no-pub --fatal-infos > ($logBase+'-analyze.log') 2>&1
if ($LASTEXITCODE -ne 0) { throw "Analyze failed: $logBase-analyze.log" }
$testArgs=@($flutter,'test','--no-pub','--reporter','expanded')+$Tests
if ($Photos) { $testArgs+='--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true' }
& $dart @testArgs > ($logBase+'-tests.log') 2>&1
if ($LASTEXITCODE -ne 0) { throw "Tests failed: $logBase-tests.log" }
Get-Content -LiteralPath ($logBase+'-tests.log') -Tail 2
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Diff check failed' }
if ($Launch) {
 $adb=Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
 $devices=& $adb devices
 $device=@($devices | Where-Object { $_ -match '^\S+\s+device$' } | ForEach-Object { ($_ -split '\s+')[0] })
 if ($device.Count -ne 1) { Write-Output 'Device launch skipped: exactly one authorized device required.';exit 0 }
 $env:DEBUG=''
 & $dart $flutter run -d $device[0] --no-resident --no-pub --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true > ($logBase+'-device.log') 2>&1
 if ($LASTEXITCODE -ne 0) { throw "Device launch failed: $logBase-device.log" }
 Select-String -LiteralPath ($logBase+'-device.log') -Pattern '^Running Gradle|^√ Built|^Installing |^Syncing ' | ForEach-Object { $_.Line }
}
