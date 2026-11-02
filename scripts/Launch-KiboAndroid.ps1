param([string]$DeviceId, [switch]$EnablePhoneAuth, [switch]$ProfileMode, [switch]$EnableDiscoveryV2, [switch]$EnableMediaManagement, [switch]$EnableAccountDeletion)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $repoRoot
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$dart = 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe'
$flutter = 'C:\flutter\bin\cache\flutter_tools.snapshot'
foreach ($required in @($adb,$dart,$flutter,'config/supabase.public.json','config/supabase.local.json')) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw 'SDK ou configuration locale KIBO manquant ; consulter DEVELOPMENT_SETUP.md sans afficher de secret.' }
}
$deviceOutput = & $adb devices
if ($LASTEXITCODE -ne 0) { throw 'Lecture des appareils ADB impossible.' }
$devices = @($deviceOutput | Where-Object { $_ -match '^\S+\s+device$' } | ForEach-Object { ($_ -split '\s+')[0] })
if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    if ($devices.Count -ne 1) { throw 'Un telephone autorise unique doit etre connecte ; sinon preciser -DeviceId.' }
    $DeviceId = $devices[0]
}
if ($DeviceId -notin $devices) { throw 'Telephone cible absent ou debogage non autorise. Aucun build lance.' }
New-Item -ItemType Directory -Path (Join-Path $repoRoot '.dart_tool') -Force | Out-Null
$logPath = Join-Path $repoRoot '.dart_tool\kibo-android-launch.log'
$previousDebug = $env:DEBUG
try {
    # DEBUG can make gradlew echo compile parameters. Never expose its raw log.
    $env:DEBUG = ''
    $phoneAuthFlag = if ($EnablePhoneAuth) { 'true' } else { 'false' }
    $discoveryFlag = if ($EnableDiscoveryV2) { 'true' } else { 'false' }
    $mediaFlag = if ($EnableMediaManagement) { 'true' } else { 'false' }
    $deletionFlag = if ($EnableAccountDeletion) { 'true' } else { 'false' }
    $buildMode = if ($ProfileMode) { '--profile' } else { '--debug' }
    & $dart $flutter run -d $DeviceId $buildMode --no-resident --no-pub --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true "--dart-define=KIBO_PHONE_AUTH_ENABLED=$phoneAuthFlag" "--dart-define=KIBO_DISCOVERY_V2_ENABLED=$discoveryFlag" "--dart-define=KIBO_MEDIA_MANAGEMENT_ENABLED=$mediaFlag" "--dart-define=KIBO_ACCOUNT_DELETION_ENABLED=$deletionFlag" > $logPath 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Lancement KIBO echoue. Journal local ignore disponible ; ne pas le partager sans expurgation.' }
    Select-String -LiteralPath $logPath -Pattern '^Running Gradle|^Installing |^Syncing ' | ForEach-Object { $_.Line }
    $appPid = & $adb -s $DeviceId shell pidof com.kibo.kibo
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($appPid -join ''))) { throw 'Commande Flutter terminee mais processus KIBO non confirme.' }
    $activityOutput = & $adb -s $DeviceId shell dumpsys activity activities
    $foreground = [bool]($activityOutput | Where-Object { $_ -match '(mResumedActivity|topResumedActivity).*com\.kibo\.kibo/' })
    Write-Output ('Processus KIBO confirme : ' + ($appPid -join ' '))
    Write-Output ('KIBO au premier plan : ' + $foreground)
    Write-Output 'Aucune desinstallation, aucun effacement, aucune donnee de recette distante creee par ce script.'
} finally { $env:DEBUG = $previousDebug }
