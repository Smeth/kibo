param(
    [string]$DeviceId = 'H6929CK6NU012345',
    [string]$InputFile,
    [string]$OutputFile
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$logDir = Join-Path $repoRoot '.dart_tool/kibo-verifications'
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
if (-not $OutputFile) {
    $OutputFile = Join-Path $logDir ('photo-upload-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N') + '.ndjson')
}
# CreateNew : aucun journal existant n'est remplacé.
$stream = [IO.File]::Open($OutputFile, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
$writer = New-Object IO.StreamWriter($stream, (New-Object Text.UTF8Encoding($false)))
$writer.AutoFlush = $true
$stages = @('validation', 'session', 'reservation_insert', 'reservation_lookup', 'edge_invoke', 'response_confirmation', 'complete')
$codes = @('authentication', 'configuration', 'body', 'fields', 'digest', 'dimensions', 'size', 'listing', 'owner', 'reservation', 'storage', 'invalid_or_unavailable', 'NOT_FOUND', 'WORKER_ERROR', 'BOOT_ERROR')
$uuidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

function Save-PhotoDiagnosticLine([string]$Line) {
    $marker = '[KIBO_PHOTO] '
    $offset = $Line.IndexOf($marker, [StringComparison]::Ordinal)
    if ($offset -lt 0) { return }
    try { $record = $Line.Substring($offset + $marker.Length) | ConvertFrom-Json } catch { return }
    if ($record.v -ne 1 -or $record.attempt -isnot [string] -or $record.attempt -cnotmatch '^[a-f0-9]{32}$') { return }
    if ($record.stage -cnotin $stages -or $record.event -cnotin @('start', 'http', 'failure', 'success')) { return }
    if ($null -ne $record.http_status -and ($record.http_status -isnot [int] -or $record.http_status -lt 100 -or $record.http_status -gt 599)) { return }
    if ($null -ne $record.code -and ($record.code -isnot [string] -or ($record.code -cnotin $codes -and $record.code -cnotmatch '^(?:PGRST[0-9]{3}|[0-9]{2}[0-9A-Z]{3})$'))) { return }
    if ($null -ne $record.server_request_id -and ($record.server_request_id -isnot [string] -or $record.server_request_id -cnotmatch $uuidPattern)) { return }
    # Reconstruire uniquement les champs autorisés. Aucun log brut sauvegardé.
    $safe = [ordered]@{
        v = 1; attempt = $record.attempt; stage = $record.stage; event = $record.event
        http_status = $record.http_status; code = $record.code; server_request_id = $record.server_request_id
    } | ConvertTo-Json -Compress
    $writer.WriteLine($safe)
    Write-Output $safe
}

try {
    if ($InputFile) {
        # Mode de vérification locale du filtre ; aucun ADB ni réseau.
        Get-Content -LiteralPath $InputFile | ForEach-Object { Save-PhotoDiagnosticLine $_ }
    } else {
        $adb = Join-Path $env:LOCALAPPDATA 'Android/sdk/platform-tools/adb.exe'
        $appPid = (& $adb -s $DeviceId shell pidof com.kibo.kibo).Trim()
        if ($LASTEXITCODE -ne 0 -or $appPid -notmatch '^\d+$') { throw 'Processus KIBO absent ou ambigu. Aucune application lancée.' }
        Write-Host "Collecte expurgée vers $OutputFile ; Ctrl+C pour arrêter. Aucun logcat effacé."
        & $adb -s $DeviceId logcat --pid=$appPid -v raw -T 1 'flutter:I' '*:S' |
            ForEach-Object { Save-PhotoDiagnosticLine $_ }
        if ($LASTEXITCODE -ne 0) { throw 'ADB a interrompu la collecte. Ne pas réessayer automatiquement.' }
    }
} finally {
    $writer.Dispose()
}
