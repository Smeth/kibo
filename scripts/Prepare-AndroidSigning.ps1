param([switch]$Create,[switch]$Resume)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$keyRoot = Join-Path $repoRoot 'android\keystores'
$keyFile = Join-Path $keyRoot 'kibo-upload.jks'
$propertiesFile = Join-Path $repoRoot 'android\key.properties'
$recoveryFile = Join-Path $keyRoot 'password.dpapi'
if (-not $Create -and -not $Resume) {
    Write-Output ('Keystore present: ' + (Test-Path -LiteralPath $keyFile))
    Write-Output ('Signing configuration present: ' + (Test-Path -LiteralPath $propertiesFile))
    exit 0
}
foreach ($target in $(if ($Resume) { @($propertiesFile) } else { @($keyFile,$propertiesFile,$recoveryFile) })) {
    if (Test-Path -LiteralPath $target) { throw 'Signature existante : aucun fichier ne sera remplace.' }
}
$keytool = if ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\keytool.exe'))) {
    Join-Path $env:JAVA_HOME 'bin\keytool.exe'
} else { 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' }
if (-not (Test-Path -LiteralPath $keytool)) { throw 'JDK Android Studio requis.' }
New-Item -ItemType Directory -Path $keyRoot -Force | Out-Null
$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls.exe $keyRoot /inheritance:r /grant:r ($identity + ':(OI)(CI)F') > $null
if ($LASTEXITCODE -ne 0) { throw 'Protection du dossier de signature impossible.' }
$bytes = New-Object byte[] 32
$random = [Security.Cryptography.RandomNumberGenerator]::Create()
try { $random.GetBytes($bytes) } finally { $random.Dispose() }
$password = [Convert]::ToBase64String($bytes)
if ($Resume) {
    if (-not (Test-Path -LiteralPath $recoveryFile)) { throw 'Reprise impossible sans recuperation DPAPI existante.' }
    $recovered = ConvertTo-SecureString ([IO.File]::ReadAllText($recoveryFile))
    $credential = New-Object System.Management.Automation.PSCredential('local',$recovered)
    $password = $credential.GetNetworkCredential().Password
}
function Invoke-Keytool([string[]]$Arguments,[string]$LogPath) {
    $before = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $keytool @Arguments > $LogPath 2>&1
        $result = $LASTEXITCODE
    } finally { $ErrorActionPreference = $before }
    if ($result -ne 0) { throw 'Operation keytool echouee. Journal local ignore disponible.' }
}
$previous = $env:KIBO_SIGNING_PASSWORD
try {
    $env:KIBO_SIGNING_PASSWORD = $password
    $secure = ConvertTo-SecureString $password -AsPlainText -Force
    $protected = ConvertFrom-SecureString $secure
    if (-not $Resume) { [IO.File]::WriteAllText($recoveryFile,$protected) }
    if (-not (Test-Path -LiteralPath $keyFile)) {
        Invoke-Keytool @('-genkeypair','-keystore',$keyFile,'-storetype','JKS','-alias','kibo-upload','-keyalg','RSA','-keysize','3072','-validity','10000','-dname','CN=KIBO','-storepass:env','KIBO_SIGNING_PASSWORD','-keypass:env','KIBO_SIGNING_PASSWORD') (Join-Path $keyRoot 'generation.log')
    }
    Invoke-Keytool @('-list','-keystore',$keyFile,'-alias','kibo-upload','-storepass:env','KIBO_SIGNING_PASSWORD') (Join-Path $keyRoot 'verification.log')
    $content = 'storeFile=keystores/kibo-upload.jks' + "`n" + 'keyAlias=kibo-upload' + "`n" + 'storePassword=' + $password + "`n" + 'keyPassword=' + $password + "`n"
    [IO.File]::WriteAllText($propertiesFile,$content)
    & icacls.exe $propertiesFile /inheritance:r /grant:r ($identity + ':F') > $null
    if ($LASTEXITCODE -ne 0) { throw 'Protection du fichier de configuration impossible.' }
    Write-Output 'Cle de signature locale creee et verifiee. Aucun secret affiche.'
    Write-Output 'Avant diffusion : sauvegarder la cle et le mot de passe dans un coffre externe. Le fichier DPAPI depend du compte Windows actuel.'
    Write-Output 'Ne pas installer cette signature sur le TECNO de recette signe avec la cle debug.'
} finally {
    $env:KIBO_SIGNING_PASSWORD = $previous
    $password = $null; $content = $null; $secure = $null
    $credential = $null; $recovered = $null
    [Array]::Clear($bytes,0,$bytes.Length)
}
