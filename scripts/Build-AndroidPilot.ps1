param([string]$ReuseStage)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
foreach ($required in @('android/key.properties','config/supabase.local.json','config/supabase.public.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $required))) { throw 'Signature ou configuration locale manquante.' }
}
$stage = Join-Path $repoRoot ('.dart_tool\pilot-' + [guid]::NewGuid().ToString('N'))
if ($ReuseStage) {
    $resolved = [IO.Path]::GetFullPath((Join-Path $repoRoot $ReuseStage))
    $expected = [IO.Path]::GetFullPath((Join-Path $repoRoot '.dart_tool\pilot-'))
    if (-not $resolved.StartsWith($expected,[StringComparison]::OrdinalIgnoreCase) -or
        (Split-Path $resolved -Leaf) -notmatch '^pilot-[0-9a-f]{32}$' -or
        -not (Test-Path -LiteralPath (Join-Path $resolved 'pubspec.yaml'))) { throw 'Dossier de reprise pilote invalide.' }
    $stage = $resolved
}
New-Item -ItemType Directory -Path $stage -Force | Out-Null
foreach ($name in @('lib','android','assets','config')) {
    New-Item -ItemType Directory -Path (Join-Path $stage $name) -Force | Out-Null
}
Copy-Item -LiteralPath (Join-Path $repoRoot 'lib') -Destination $stage -Recurse -Force
Get-ChildItem -LiteralPath (Join-Path $repoRoot 'android') -Force | Where-Object { $_.Name -notin @('.gradle','keystores','key.properties') } | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $stage 'android') -Recurse -Force
}
Get-ChildItem -LiteralPath (Join-Path $repoRoot 'assets') -Force | Where-Object { $_.Name -ne 'test_catalogue' } | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $stage 'assets') -Recurse -Force
}
foreach ($name in @('pubspec.yaml','pubspec.lock','analysis_options.yaml')) { Copy-Item -LiteralPath (Join-Path $repoRoot $name) -Destination $stage }
foreach ($name in @('supabase.public.json','supabase.local.json')) { Copy-Item -LiteralPath (Join-Path $repoRoot ('config\'+$name)) -Destination (Join-Path $stage 'config') }
$pubspecPath = Join-Path $stage 'pubspec.yaml'
$pubspec = [IO.File]::ReadAllText($pubspecPath)
$pubspec = [regex]::Replace($pubspec,'(?m)^\s+- assets/test_catalogue/[^\r\n]*\r?\n','')
[IO.File]::WriteAllText($pubspecPath,$pubspec)
$properties = [IO.File]::ReadAllText((Join-Path $repoRoot 'android\key.properties'))
$store = [regex]::Match($properties,'(?m)^storeFile=(.+)$').Groups[1].Value.Trim()
if (-not [IO.Path]::IsPathRooted($store)) { $store = Join-Path (Join-Path $repoRoot 'android') $store }
if (-not (Test-Path -LiteralPath $store)) { throw 'Keystore introuvable.' }
$properties = [regex]::Replace($properties,'(?m)^storeFile=.+$', ('storeFile='+$store.Replace('\','/')))
[IO.File]::WriteAllText((Join-Path $stage 'android\key.properties'),$properties)
$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls.exe $stage /inheritance:r /grant:r ($identity + ':(OI)(CI)F') > $null
if ($LASTEXITCODE -ne 0) { throw 'Protection du dossier de build impossible.' }
$dart = 'C:\flutter\bin\cache\dart-sdk\bin\dart.exe'
$flutter = 'C:\flutter\bin\cache\flutter_tools.snapshot'
function Invoke-FlutterBuild([string[]]$Arguments,[string]$LogPath) {
    $before = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $dart $flutter @Arguments > $LogPath 2>&1
        $result = $LASTEXITCODE
    } finally { $ErrorActionPreference = $before }
    if ($result -ne 0) { throw ('Commande Flutter echouee ; journal local ignore : '+$LogPath) }
}
$beforeDebug = $env:DEBUG
$beforeLocation = Get-Location
try {
    $env:DEBUG = ''
    Set-Location -LiteralPath $stage
    Invoke-FlutterBuild @('pub','get') (Join-Path $stage 'dependencies.log')
    Invoke-FlutterBuild @('build','appbundle','--release','--no-pub','--dart-define-from-file=config/supabase.public.json','--dart-define-from-file=config/supabase.local.json','--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true','--dart-define=KIBO_DISCOVERY_V2_ENABLED=true','--dart-define=KIBO_MEDIA_MANAGEMENT_ENABLED=true','--dart-define=KIBO_ACCOUNT_DELETION_ENABLED=true') (Join-Path $stage 'build.log')
    $artifact = Join-Path $stage 'build\app\outputs\bundle\release\app-release.aab'
    if (-not (Test-Path -LiteralPath $artifact)) { throw 'Artefact absent.' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($artifact)
    try {
        if (@($archive.Entries | Where-Object { $_.FullName -match 'assets/test_catalogue/' }).Count -ne 0) { throw 'Fixtures presentes dans le bundle.' }
        if (@($archive.Entries | Where-Object { $_.FullName -match '^META-INF/.+\.(RSA|EC|DSA)$' }).Count -eq 0) { throw 'Signature du bundle absente.' }
    } finally { $archive.Dispose() }
    $jarsigner = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\jarsigner.exe' } else { 'C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe' }
    if (-not (Test-Path -LiteralPath $jarsigner)) { throw 'JDK jarsigner requis.' }
    $before = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $jarsigner -verify $artifact > (Join-Path $stage 'signature-verification.log') 2>&1
        $signatureExit = $LASTEXITCODE
    } finally { $ErrorActionPreference = $before }
    if ($signatureExit -ne 0) { throw 'Verification cryptographique du bundle echouee.' }
    $hash = (Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLower()
    $destination = Join-Path $repoRoot ('build\pilot\kibo-1.0.0+2-'+$hash.Substring(0,12)+'.aab')
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $artifact -Destination $destination
    Write-Output ('Pilote signe prepare : '+$destination)
    Write-Output ('SHA256 : '+$hash)
    Write-Output 'Fixtures absentes du bundle. Aucun upload Play Store ni installation effectue.'
} finally {
    Set-Location -LiteralPath $beforeLocation
    $env:DEBUG = $beforeDebug
    $properties = $null
    # Remove only this generated copy of the signing password; keep the original.
    $temporarySigning = Join-Path $stage 'android\key.properties'
    if (Test-Path -LiteralPath $temporarySigning -PathType Leaf) {
        Remove-Item -LiteralPath $temporarySigning -Force
    }
}
