param([int]$Port = 55473, [ValidateSet('Owner','Contacts','Chat','Safety','Mvp','Engagement','History','MessageActions','OptionalPrice','Discovery','Media','Deletion')][string]$Suite = 'Owner')
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$pgBin = 'C:\Program Files\PostgreSQL\13\bin'
$runRoot = Join-Path $repoRoot ('.dart_tool\owner-sql-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $runRoot | Out-Null
$dataRoot = Join-Path $runRoot 'data'
$serverLog = Join-Path $runRoot 'server.log'
$started = $false
function Invoke-FixtureSql([string]$RelativePath) {
    & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $Port -U postgres -d postgres -v ON_ERROR_STOP=1 -f (Join-Path $repoRoot $RelativePath)
    if ($LASTEXITCODE -ne 0) { throw "SQL failed: $RelativePath" }
}
function Invoke-ExpectedGuardRefusal {
    $refusalLog = Join-Path $runRoot 'expected-refusal.log'
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $Port -U postgres -d postgres -v ON_ERROR_STOP=1 -f (Join-Path $repoRoot 'supabase/proposals/owner_management_02_guards.sql') > $refusalLog 2>&1
        $refusalExit = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previousPreference }
    if ($refusalExit -ne 3 -or -not (Select-String -LiteralPath $refusalLog -SimpleMatch 'Function baseline changed' -Quiet)) {
        throw 'Expected baseline refusal was not observed'
    }
    Write-Output 'Expected reapplication refusal verified.'
}
try {
    & "$pgBin\initdb.exe" -D $dataRoot -U postgres --auth=trust --encoding=UTF8 --locale=C > (Join-Path $runRoot 'init.log') 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'initdb failed' }
    # Redirection vers fichier : ne pas conserver les pipes herites du serveur.
    $startArgs = @('-D', ('"' + $dataRoot + '"'), '-l', ('"' + $serverLog + '"'), '-o', ('"-h 127.0.0.1 -p ' + $Port + ' -c ssl=off"'), '-w', 'start')
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "$pgBin\pg_ctl.exe"
    $startInfo.Arguments = $startArgs -join ' '
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.WindowStyle = 'Hidden'
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $pgStart = New-Object System.Diagnostics.Process
    $pgStart.StartInfo = $startInfo
    if (-not $pgStart.Start()) { throw 'pg_ctl process not started' }
    $pgOutput = $pgStart.StandardOutput.ReadToEndAsync()
    $pgError = $pgStart.StandardError.ReadToEndAsync()
    # Attendre uniquement pg_ctl ; Start-Process -Wait attend les descendants.
    if (-not $pgStart.WaitForExit(20000)) { throw 'pg_ctl startup timeout' }
    if ($pgOutput.Wait(1000)) { [IO.File]::WriteAllText((Join-Path $runRoot 'start.log'), $pgOutput.Result) }
    if ($pgError.Wait(1000)) { [IO.File]::WriteAllText((Join-Path $runRoot 'start-error.log'), $pgError.Result) }
    if ($pgStart.ExitCode -ne 0) { throw 'pg_ctl start failed' }
    $started = $true
    Invoke-FixtureSql 'test/sql/direct_publication_fixture.sql'
    if ($Suite -in @('Safety','Mvp','Engagement','History','MessageActions','Deletion')) {
        Invoke-FixtureSql 'supabase/migrations/20261031050000_direct_listing_publication.sql'
        Invoke-FixtureSql 'test/sql/owner_management_real_guards_fixture.sql'
        Invoke-FixtureSql 'supabase/proposals/owner_management_01_enum.sql'
        Invoke-FixtureSql 'supabase/proposals/owner_management_02_guards.sql'
        Invoke-FixtureSql 'test/sql/chat_fixture.sql'
        Invoke-FixtureSql 'test/sql/safety_fixture.sql'
        Invoke-FixtureSql 'supabase/proposals/safety_workflows.sql'
        Invoke-FixtureSql 'test/sql/safety_assertions.sql'
        if($Suite -in @('Mvp','Engagement','History','MessageActions','Deletion')) {
            Invoke-FixtureSql 'test/sql/mvp_extensions_fixture.sql'
            Invoke-FixtureSql 'supabase/proposals/mvp_chat_account.sql'
            Invoke-FixtureSql 'test/sql/mvp_extensions_assertions.sql'
            Invoke-FixtureSql 'supabase/proposals/mvp_chat_hardening.sql'
            Invoke-FixtureSql 'test/sql/mvp_hardening_assertions.sql'
            Invoke-FixtureSql 'supabase/proposals/mvp_block_lookup_index.sql'
            if ($Suite -eq 'MessageActions') {
                Invoke-FixtureSql 'supabase/proposals/chat_message_actions.sql'
                Invoke-FixtureSql 'test/sql/message_actions_assertions.sql'
                Write-Output 'Message actions SQL checks passed.'
            }
            if ($Suite -eq 'History') {
                Invoke-FixtureSql 'supabase/proposals/retained_history.sql'
                Invoke-FixtureSql 'test/sql/retained_history_assertions.sql'
                Write-Output 'Retained history SQL checks passed.'
            }
            if ($Suite -in @('Engagement','Deletion')) {
                Invoke-FixtureSql 'supabase/proposals/engagement_workflows.sql'
                Invoke-FixtureSql 'test/sql/engagement_assertions.sql'
                $refusalLog = Join-Path $runRoot 'engagement-refusal.log'
                $previousPreference = $ErrorActionPreference
                try {
                    $ErrorActionPreference = 'Continue'
                    & "$pgBin\psql.exe" -X -h 127.0.0.1 -p $Port -U postgres -d postgres -v ON_ERROR_STOP=1 -f (Join-Path $repoRoot 'supabase/proposals/engagement_workflows.sql') > $refusalLog 2>&1
                    $refusalExit = $LASTEXITCODE
                } finally { $ErrorActionPreference = $previousPreference }
                if ($refusalExit -ne 3 -or -not (Select-String -LiteralPath $refusalLog -SimpleMatch 'Engagement already installed' -Quiet)) { throw 'Expected engagement reapplication refusal was not observed' }
                Write-Output 'Engagement reapplication refusal verified.'
                if ($Suite -eq 'Deletion') {
                    Invoke-FixtureSql 'test/sql/discovery_fixture.sql'
                    Invoke-FixtureSql 'supabase/proposals/discovery_search_v2.sql'
                    Invoke-FixtureSql 'test/sql/discovery_assertions.sql'
                    Invoke-FixtureSql 'test/sql/media_fixture.sql'
                    Invoke-FixtureSql 'supabase/proposals/listing_media_management.sql'
                    Invoke-FixtureSql 'supabase/proposals/retained_history.sql'
                    Invoke-FixtureSql 'test/sql/deletion_fixture.sql'
                    Invoke-FixtureSql 'supabase/proposals/account_deletion_execution.sql'
                    Invoke-FixtureSql 'test/sql/deletion_assertions.sql'
                    Write-Output 'Deletion freeze, archive, purge, resume, ACL and verification checks passed.'
                }
            }
        }
        Write-Output 'Safety SQL checks passed.'
    } elseif ($Suite -in @('Discovery','Media')) {
        Invoke-FixtureSql 'supabase/migrations/20261031050000_direct_listing_publication.sql'
        Invoke-FixtureSql 'test/sql/owner_management_real_guards_fixture.sql'
        Invoke-FixtureSql 'supabase/proposals/owner_management_01_enum.sql'
        Invoke-FixtureSql 'supabase/proposals/owner_management_02_guards.sql'
        Invoke-FixtureSql 'test/sql/discovery_fixture.sql'
        Invoke-FixtureSql 'supabase/proposals/discovery_search_v2.sql'
        Invoke-FixtureSql 'test/sql/discovery_assertions.sql'
        Write-Output 'Discovery prefix/fuzzy/synonym/ranking/RLS checks passed.'
        if ($Suite -eq 'Media') {
            Invoke-FixtureSql 'test/sql/media_fixture.sql'
            Invoke-FixtureSql 'supabase/proposals/listing_media_management.sql'
            Invoke-FixtureSql 'test/sql/media_assertions.sql'
            Write-Output 'Media atomic editing, replay, conflict and RLS checks passed.'
        }
    } elseif ($Suite -eq 'OptionalPrice') {
        Invoke-FixtureSql 'supabase/migrations/20261031050000_direct_listing_publication.sql'
        Invoke-FixtureSql 'test/sql/owner_management_real_guards_fixture.sql'
        Invoke-FixtureSql 'supabase/proposals/owner_management_01_enum.sql'
        Invoke-FixtureSql 'supabase/proposals/owner_management_02_guards.sql'
        Invoke-FixtureSql 'supabase/proposals/optional_listing_price.sql'
        Invoke-FixtureSql 'supabase/proposals/optional_listing_price.sql'
        Invoke-FixtureSql 'test/sql/optional_listing_price_assertions.sql'
        Write-Output 'Optional price SQL and RLS checks passed.'
    } elseif ($Suite -eq 'Chat') {
        Invoke-FixtureSql 'test/sql/chat_fixture.sql'
        Invoke-FixtureSql 'supabase/proposals/chat_realtime.sql'
        Invoke-FixtureSql 'supabase/proposals/chat_realtime.sql'
        Invoke-FixtureSql 'test/sql/chat_assertions.sql'
        Write-Output 'Chat SQL and publication checks passed.'
    } elseif ($Suite -eq 'Contacts') {
        Invoke-FixtureSql 'supabase/proposals/seller_contacts.sql'
        Invoke-FixtureSql 'test/sql/seller_contacts_assertions.sql'
        Write-Output 'Seller contact SQL checks passed.'
    } else {
    Invoke-FixtureSql 'supabase/migrations/20261031050000_direct_listing_publication.sql'
    Invoke-FixtureSql 'test/sql/owner_management_real_guards_fixture.sql'
    Invoke-FixtureSql 'supabase/proposals/owner_management_01_enum.sql'
    Invoke-FixtureSql 'supabase/proposals/owner_management_01_enum.sql'
    Invoke-FixtureSql 'supabase/proposals/owner_management_02_guards.sql'
    Invoke-ExpectedGuardRefusal
    Invoke-FixtureSql 'test/sql/owner_listing_management_assertions.sql'
    Invoke-FixtureSql 'test/sql/owner_management_extended_assertions.sql'
    Invoke-FixtureSql 'supabase/proposals/owner_management_rollback_guards.sql'
    Invoke-FixtureSql 'supabase/proposals/owner_management_01_enum.sql'
    Write-Output 'Owner guards, ACL, RLS, transitions and rollback assertions passed.'
    Invoke-FixtureSql 'test/sql/client_privileges_fixture.sql'
    Invoke-FixtureSql 'supabase/proposals/client_privileges_01_tables.sql'
    Invoke-FixtureSql 'supabase/proposals/client_privileges_02_defaults_postgres.sql'
    Invoke-FixtureSql 'supabase/proposals/client_privileges_03_defaults_supabase_admin.sql'
    Invoke-FixtureSql 'test/sql/client_privileges_assertions.sql'
    Invoke-FixtureSql 'supabase/proposals/client_privileges_rollback.sql'
    Invoke-FixtureSql 'test/sql/client_privileges_rollback_assertions.sql'
    Write-Output 'Owner management SQL checks passed; rollback applied on fixture only.'
    }
} finally {
    if ($started -or (Test-Path -LiteralPath (Join-Path $dataRoot 'postmaster.pid'))) {
        & "$pgBin\pg_ctl.exe" -D $dataRoot -w stop -m fast > (Join-Path $runRoot 'stop.log') 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Fixture stop failed; inspect $runRoot" }
    }
    Write-Output "Fixture retained: $runRoot"
}
