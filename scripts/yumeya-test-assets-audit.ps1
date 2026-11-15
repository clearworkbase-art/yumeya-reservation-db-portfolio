#requires -version 5.1
[CmdletBinding()]
param(
    [string]$PsqlPath,
    [string]$AdminUser = 'postgres'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($PsqlPath)) {
    $psqlCommand = Get-Command psql.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $psqlCommand) { throw 'psql.exeが見つかりません。PATHへ追加するか、-PsqlPathを指定してください。' }
    $PsqlPath = $psqlCommand.Source
}
if (-not (Test-Path -LiteralPath $PsqlPath)) { throw "psql.exeが見つかりません: $PsqlPath" }
$secure = Read-Host 'PostgreSQL管理者パスワード（読み取り専用監査。保存されません）' -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)

function Invoke-ReadOnlyPsql {
    param([string]$Database,[string]$Query)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $PsqlPath
    $psi.Arguments = '-X -h 127.0.0.1 -p 5432 -U "' + $AdminUser + '" -d "' + $Database + '" -A -t -F "|" -P pager=off -c "' + $Query.Replace('"','\"') + '"'
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables['PGPASSWORD'] = $script:plainPassword
    $psi.EnvironmentVariables['PGCLIENTENCODING'] = 'UTF8'
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    $out = $p.StandardOutput.ReadToEnd()
    $err = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    if ($p.ExitCode -ne 0) { throw "読み取り専用SQL失敗。exit=$($p.ExitCode); stderr=[$err]" }
    return $out
}

try {
    $script:plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    Write-Output '--- TEST DATABASES ---'
    $dbRows = Invoke-ReadOnlyPsql 'postgres' "SELECT datname, pg_get_userbyid(datdba), datallowconn, datistemplate FROM pg_database WHERE datname LIKE 'yumeya_privtest_%' ORDER BY datname"
    if ([string]::IsNullOrWhiteSpace($dbRows)) { Write-Output '(none)' }
    else { $dbRows.Trim().Split("`n") | ForEach-Object { Write-Output $_ } }

    Write-Output '--- TEST ROLES ---'
    $roleRows = Invoke-ReadOnlyPsql 'postgres' "SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole, rolbypassrls FROM pg_roles WHERE rolname LIKE 'yumeya_owner_test_%' OR rolname LIKE 'yumeya_app_test_%' ORDER BY rolname"
    if ([string]::IsNullOrWhiteSpace($roleRows)) { Write-Output '(none)' }
    else { $roleRows.Trim().Split("`n") | ForEach-Object { Write-Output $_ } }

    Write-Output '--- ROLE MEMBERSHIPS ---'
    $members = Invoke-ReadOnlyPsql 'postgres' "SELECT member.rolname, parent.rolname FROM pg_auth_members m JOIN pg_roles member ON member.oid=m.member JOIN pg_roles parent ON parent.oid=m.roleid WHERE member.rolname LIKE 'yumeya_%_test_%' OR parent.rolname LIKE 'yumeya_%_test_%' ORDER BY member.rolname, parent.rolname"
    if ([string]::IsNullOrWhiteSpace($members)) { Write-Output '(none)' }
    else { $members.Trim().Split("`n") | ForEach-Object { Write-Output $_ } }

    foreach ($row in ($dbRows.Trim().Split("`n") | Where-Object { $_ })) {
        $parts = $row.Split('|')
        $db = $parts[0]
        Write-Output "--- OBJECT OWNERS: $db ---"
        $objects = Invoke-ReadOnlyPsql $db "SELECT n.nspname, c.relname, CASE c.relkind WHEN 'r' THEN 'table' WHEN 'S' THEN 'sequence' ELSE c.relkind::text END, pg_get_userbyid(c.relowner) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname <> 'information_schema' AND c.relkind IN ('r','S') ORDER BY n.nspname,c.relname"
        if ([string]::IsNullOrWhiteSpace($objects)) { Write-Output '(none)' }
        else { $objects.Trim().Split("`n") | ForEach-Object { Write-Output $_ } }
        Write-Output "--- SHARED DEPENDENCY COUNTS: $db ---"
        $deps = Invoke-ReadOnlyPsql $db "SELECT r.rolname, count(*) FROM pg_shdepend sd JOIN pg_roles r ON r.oid=sd.refobjid WHERE sd.refclassid='pg_authid'::regclass GROUP BY r.rolname ORDER BY r.rolname"
        if ([string]::IsNullOrWhiteSpace($deps)) { Write-Output '(none)' }
        else { $deps.Trim().Split("`n") | ForEach-Object { Write-Output $_ } }
    }
    Write-Output '--- DELETION POLICY ---'
    Write-Output 'No DROP DATABASE, DROP ROLE, DROP OWNED, REASSIGN OWNED, or other write operation was executed.'
    Write-Output 'DB deletion requires approval, no active connections, and owner/admin authority.'
    Write-Output 'Role deletion requires no owned objects, no database ownership, and no memberships; this script only reports evidence.'
}
finally {
    if ($null -ne $ptr) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    $script:plainPassword = $null
}
