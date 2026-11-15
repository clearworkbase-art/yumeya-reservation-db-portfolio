#requires -version 5.1
[CmdletBinding()]
param(
    [string]$PsqlPath,
    [string]$MavenPath,
    [string]$AdminUser = 'postgres'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($PsqlPath)) {
    $psqlCommand = Get-Command psql.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $psqlCommand) { throw 'psql.exeが見つかりません。PATHへ追加するか、-PsqlPathを指定してください。' }
    $PsqlPath = $psqlCommand.Source
}
if (-not (Test-Path -LiteralPath $PsqlPath)) { throw "psql.exeが見つかりません: $PsqlPath" }
if ([string]::IsNullOrWhiteSpace($MavenPath)) {
    $mvnCommand = Get-Command mvn.cmd -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $mvnCommand) { throw 'mvn.cmdが見つかりません。MavenのbinをPATHへ追加するか、-MavenPathを指定してください。' }
    $MavenPath = $mvnCommand.Source
}
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$schemaPath = Join-Path $repoRoot 'apps\yumeya-reservation\db\01_schema.sql'
$migrationPath = Join-Path $repoRoot 'apps\yumeya-reservation\db\05_privilege_migration.sql'
$databaseOwnerPath = Join-Path $repoRoot 'apps\yumeya-reservation\db\05a_database_owner_migration.sql'
if (-not (Test-Path -LiteralPath $schemaPath)) { throw '01_schema.sqlが見つかりません。' }

$adminSecure = Read-Host 'PostgreSQL管理者パスワード（テストDB・ロール作成用。保存されません）' -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminSecure)
$adminPassword = $null
$appPassword = -join (1..32 | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) })
$suffix = [Guid]::NewGuid().ToString('N').Substring(0,12)
$testDatabase = "yumeya_privtest_$suffix"
$testOwner = "yumeya_owner_test_$suffix"
$testApp = "yumeya_app_test_$suffix"

function Invoke-PsqlText {
    param(
        [string]$Database,
        [string]$User,
        [string]$Password,
        [string]$Query,
        [switch]$ExpectFailure,
        [switch]$VerboseError,
        [switch]$SqlStateError,
        [switch]$Diagnostic
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $PsqlPath
    $psi.Arguments = '-X -h 127.0.0.1 -p 5432 -U "' + $User + '" -d "' + $Database + '" -v ON_ERROR_STOP=1 -P pager=off -P footer=off -A -t -f -'
    if ($VerboseError) { $psi.Arguments += ' -v VERBOSITY=verbose' }
    if ($SqlStateError) { $psi.Arguments += ' -v VERBOSITY=sqlstate' }
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables['PGPASSWORD'] = $Password
    $psi.EnvironmentVariables['PGCLIENTENCODING'] = 'UTF8'
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $writer = New-Object System.IO.StreamWriter($process.StandardInput.BaseStream, $utf8)
    $writer.Write($Query)
    $writer.Flush()
    $writer.Dispose()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    $code = $process.ExitCode
    $output = $stdout + $stderr
    if ($Diagnostic) {
        return [pscustomobject]@{
            StdOut = $stdout
            StdErr = $stderr
            ExitCode = $code
        }
    }
    if ($ExpectFailure) {
        if ($code -eq 0) { throw "拒否されるべきSQLが成功しました。対象DB: $Database" }
        return $output
    }
    if ($code -ne 0) { throw "psql exit=$code; stdout=[$stdout]; stderr=[$stderr]" }
    return $output
}

function Normalize-PsqlOutput {
    param([string]$Output)
    if ($null -eq $Output) { return '' }
    return (($Output -replace "`r", '')).Trim()
}

function Get-PsqlDataLines {
    param([string]$Output)
    $normalized = Normalize-PsqlOutput $Output
    if ($normalized.Length -eq 0) { return @() }
    return @($normalized -split "`n" | ForEach-Object { $_.Trim() } | Where-Object {
        $_ -and ($_ -notmatch '^(INSERT|UPDATE|DELETE|SELECT|CREATE|ALTER|DROP|TRUNCATE|BEGIN|COMMIT|ROLLBACK|GRANT|REVOKE)(\s|$)')
    })
}

function Get-PsqlFirstDataLine {
    param([string]$Output,[string]$Label)
    $lines = @(Get-PsqlDataLines $Output)
    if ($lines.Count -eq 0) { throw "$Label のデータ行がありません。実際の出力=[$(Normalize-PsqlOutput $Output)]" }
    return $lines[0]
}

function Assert-OutputContains {
    param([string]$Output,[string]$Pattern,[string]$Label)
    $normalized = Normalize-PsqlOutput $Output
    if ($normalized -notmatch $Pattern) { throw "$Label の期待値を確認できませんでした。実際の出力=[$normalized]" }
    Write-Output "PASS $Label"
}

function Assert-PsqlSqlStateFailure {
    param([pscustomobject]$Result,[string]$SqlState,[string]$Label)
    $combined = "$(Normalize-PsqlOutput $Result.StdOut)`n$(Normalize-PsqlOutput $Result.StdErr)"
    if ($Result.ExitCode -eq 0) {
        throw "$Label が成功扱いになりました。終了コード=0、出力=[$combined]"
    }
    if ($combined -notmatch "(?m)\b$SqlState\b") {
        throw "$Label のSQLSTATEが期待値と異なります。終了コード=$($Result.ExitCode)、出力=[$combined]"
    }
    Write-Output "PASS $Label (exit=$($Result.ExitCode), sqlstate=$SqlState)"
}

try {
    $adminPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    # DB・ロール作成前の事前検証。失敗時は以降のCREATEへ進まない。
    $preflight = Invoke-PsqlText -Database 'postgres' -User $AdminUser -Password $adminPassword -Query "SHOW client_encoding;" -Diagnostic
    $preflightEncoding = Normalize-PsqlOutput $preflight.StdOut
    Write-Output "PREFLIGHT psql_exit=$($preflight.ExitCode)"
    Write-Output "PREFLIGHT stdout=[$preflightEncoding]"
    Write-Output "PREFLIGHT stderr=[$(Normalize-PsqlOutput $preflight.StdErr)]"
    if ($preflight.ExitCode -ne 0) { throw '管理者接続の事前検証に失敗しました。DB・ロールは作成していません。' }
    if ($preflightEncoding -ne 'UTF8') { throw "client_encodingがUTF8ではありません。実際の値=[$preflightEncoding]。DB・ロールは作成していません。" }
    $preflightConnection = Invoke-PsqlText -Database 'postgres' -User $AdminUser -Password $adminPassword -Query "SELECT current_user;" -Diagnostic
    Write-Output "PREFLIGHT connection_exit=$($preflightConnection.ExitCode)"
    Write-Output "PREFLIGHT connection_stdout=[$(Normalize-PsqlOutput $preflightConnection.StdOut)]"
    Write-Output "PREFLIGHT connection_stderr=[$(Normalize-PsqlOutput $preflightConnection.StdErr)]"
    if ($preflightConnection.ExitCode -ne 0) { throw '管理者接続確認に失敗しました。DB・ロールは作成していません。' }

    $schema = Get-Content -LiteralPath $schemaPath -Raw -Encoding utf8
    $migration = (Get-Content -LiteralPath $migrationPath -Raw -Encoding utf8).Replace('yumeya_owner',$testOwner).Replace('yumeya_app',$testApp).Replace('yumeya_portfolio',$testDatabase)
    $databaseOwner = (Get-Content -LiteralPath $databaseOwnerPath -Raw -Encoding utf8).Replace('yumeya_owner',$testOwner).Replace('yumeya_portfolio',$testDatabase)

    $bootstrapRoles = @"
CREATE ROLE $testOwner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE ROLE $testApp LOGIN PASSWORD '$appPassword';
"@
    Invoke-PsqlText -Database 'postgres' -User $AdminUser -Password $adminPassword -Query $bootstrapRoles | Out-Null
    Invoke-PsqlText -Database 'postgres' -User $AdminUser -Password $adminPassword -Query "CREATE DATABASE $testDatabase OWNER $testOwner;" | Out-Null
    Write-Output "TEST_DATABASE=$testDatabase"
    Write-Output "TEST_OWNER_ROLE=$testOwner"
    Write-Output "TEST_APP_ROLE=$testApp"

    Invoke-PsqlText -Database $testDatabase -User $AdminUser -Password $adminPassword -Query $schema | Out-Null
    Invoke-PsqlText -Database $testDatabase -User $AdminUser -Password $adminPassword -Query $migration | Out-Null
    Invoke-PsqlText -Database 'postgres' -User $AdminUser -Password $adminPassword -Query $databaseOwner | Out-Null
    Write-Output 'PASS isolated owner/privilege migration'

    Assert-OutputContains (Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "SELECT count(*) FROM public.rooms;") '^3$' 'SELECT rooms'
    $idOutput = Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "INSERT INTO public.reservations (room_code,check_in,check_out,guests,status) VALUES ('MATSU',DATE '2099-01-10',DATE '2099-01-12',2,'CONFIRMED') RETURNING reservation_id;"
    $id = Get-PsqlFirstDataLine $idOutput 'INSERT identity sequence'
    if ($id -notmatch '^\d+$') { throw "INSERT identity sequenceの予約IDが不正です。予約ID=[$id]" }
    Write-Output "PASS INSERT identity sequence (reservation_id=$id)"

    Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "INSERT INTO public.reservations (room_code,check_in,check_out,guests,status) VALUES ('MATSU',DATE '2099-01-12',DATE '2099-01-14',2,'CONFIRMED');" | Out-Null
    Write-Output 'PASS checkout/checkin boundary'

    Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "INSERT INTO public.reservations (room_code,check_in,check_out,guests,status) VALUES ('TAKE',DATE '2099-02-10',DATE '2099-02-12',2,'CONFIRMED');" | Out-Null
    $duplicate = Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "INSERT INTO public.reservations (room_code,check_in,check_out,guests,status) VALUES ('TAKE',DATE '2099-02-11',DATE '2099-02-13',2,'CONFIRMED');" -ExpectFailure -SqlStateError -Diagnostic
    Assert-PsqlSqlStateFailure $duplicate '23P01' 'overlap rejection'

    $cancelIdOutput = Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "INSERT INTO public.reservations (room_code,check_in,check_out,guests,status) VALUES ('UME',DATE '2099-03-10',DATE '2099-03-12',2,'CONFIRMED') RETURNING reservation_id;"
    $cancelId = Get-PsqlFirstDataLine $cancelIdOutput 'CANCELLED対象予約'
    if ($cancelId -notmatch '^\d+$') { throw "CANCELLED対象予約のIDが不正です。予約ID=[$cancelId]" }
    Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "UPDATE public.reservations SET status='CANCELLED', cancelled_at=CURRENT_TIMESTAMP WHERE reservation_id=$cancelId AND status='CONFIRMED';" | Out-Null
    Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "INSERT INTO public.reservations (room_code,check_in,check_out,guests,status) VALUES ('UME',DATE '2099-03-10',DATE '2099-03-12',2,'CONFIRMED');" | Out-Null
    Write-Output 'PASS CANCELLED reuse'

    Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "BEGIN; INSERT INTO public.reservations (room_code,check_in,check_out,guests,status) VALUES ('MATSU',DATE '2099-04-10',DATE '2099-04-12',2,'CONFIRMED'); ROLLBACK; SELECT count(*) FROM public.reservations WHERE room_code='MATSU' AND check_in=DATE '2099-04-10';" | Out-Null
    Write-Output 'PASS transaction rollback'

    $createFail = Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "CREATE TABLE public.blocked_create_test(id integer);" -ExpectFailure -SqlStateError -Diagnostic
    Assert-PsqlSqlStateFailure $createFail '42501' 'CREATE denied'
    $alterFail = Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "ALTER TABLE public.rooms ADD COLUMN blocked_alter_test integer;" -ExpectFailure -SqlStateError -Diagnostic
    Assert-PsqlSqlStateFailure $alterFail '42501' 'ALTER denied'
    $dropFail = Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "DROP TABLE public.rooms;" -ExpectFailure -SqlStateError -Diagnostic
    Assert-PsqlSqlStateFailure $dropFail '42501' 'DROP denied'
    $truncateFail = Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "TRUNCATE TABLE public.rooms;" -ExpectFailure -SqlStateError -Diagnostic
    Assert-PsqlSqlStateFailure $truncateFail '42501' 'TRUNCATE denied'

    $sequenceFail = Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "SELECT nextval('public.reservations_reservation_id_seq'::regclass);" -ExpectFailure -SqlStateError -Diagnostic
    Assert-PsqlSqlStateFailure $sequenceFail '42501' 'direct nextval denied'
    $identityAfterSequenceCheck = Invoke-PsqlText -Database $testDatabase -User $testApp -Password $appPassword -Query "INSERT INTO public.reservations (room_code,check_in,check_out,guests,status) VALUES ('TAKE',DATE '2099-05-10',DATE '2099-05-12',2,'CONFIRMED') RETURNING reservation_id;"
    $identityId = Get-PsqlFirstDataLine $identityAfterSequenceCheck 'identity INSERT without sequence grant'
    if ($identityId -notmatch '^\d+$') { throw "identity INSERTの予約IDが不正です。予約ID=[$identityId]" }
    Write-Output "PASS identity INSERT without sequence grant (reservation_id=$identityId)"

    $env:YUMEYA_JDBC_URL = "jdbc:postgresql://127.0.0.1:5432/$testDatabase"
    $env:YUMEYA_DB_USER = $testApp
    $env:YUMEYA_DB_PASSWORD = $appPassword
    $classes = Join-Path $repoRoot 'apps\yumeya-reservation\target\classes'
    $driver = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'apps\yumeya-reservation\target') -Recurse -Filter 'postgresql-*.jar' | Select-Object -First 1
    if (-not $driver) { throw 'JDBCドライバーJARがtarget配下にありません。先にMaven packageを実行してください。' }
    $javaScript = @'
import java.time.*;
import jp.portfolio.yumeya.*;
var repository = new ReservationRepository();
var draft = new ReservationDraft("MATSU", "桂松の間", LocalDate.of(2099, 8, 1), LocalDate.of(2099, 8, 3), 2);
var id = repository.insert(draft);
if (repository.find(id) == null) throw new RuntimeException("find failed");
if (repository.search("MATSU", "CONFIRMED").isEmpty()) throw new RuntimeException("search failed");
if (!repository.cancel(id)) throw new RuntimeException("cancel failed");
System.out.println("PASS Java/JDBC repository");
/exit
'@
    $javaOutput = @($javaScript | & 'jshell.exe' --class-path "$classes;$($driver.FullName)" 2>&1)
    $javaExitCode = $LASTEXITCODE
    $javaOutputText = [string]::Join("`n", $javaOutput)
    if ($javaExitCode -ne 0 -or $javaOutputText -notmatch 'PASS Java/JDBC repository') {
        throw "Java/JDBC検証が完了しませんでした。exit=$javaExitCode; output=[$javaOutputText]"
    }
    Write-Output 'PASS Java/JDBC repository'
    Write-Output '--- TEST ASSETS KEPT ---'
    Write-Output "DB=$testDatabase OWNER=$testOwner APP=$testApp"
    Write-Output 'テスト専用DB・ロールは削除していません。承認後に別途削除してください。'
}
finally {
    if ($null -ne $ptr) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    Remove-Item Env:YUMEYA_JDBC_URL,Env:YUMEYA_DB_USER,Env:YUMEYA_DB_PASSWORD -ErrorAction SilentlyContinue
}
