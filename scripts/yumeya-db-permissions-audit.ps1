#requires -version 5.1
[CmdletBinding()]
param(
    [string]$PsqlPath,
    [string]$HostName = '127.0.0.1',
    [int]$Port = 5432,
    [string]$Database = 'yumeya_portfolio',
    [string]$User = 'yumeya_app'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($PsqlPath)) {
    $psqlCommand = Get-Command psql.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $psqlCommand) { throw 'psql.exeが見つかりません。PATHへ追加するか、-PsqlPathを指定してください。' }
    $PsqlPath = $psqlCommand.Source
}
if (-not (Test-Path -LiteralPath $PsqlPath)) {
    throw "psql.exeが見つかりません: $PsqlPath"
}

$securePassword = Read-Host 'yumeya_app のDBパスワード（表示・保存されません）' -AsSecureString
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    $env:PGPASSWORD = $plainPassword
    $query = @"
SELECT current_user, current_database();
SELECT datname, pg_get_userbyid(datdba) AS database_owner
FROM pg_database WHERE datname = current_database();
SELECT nspname AS schema_name, pg_get_userbyid(nspowner) AS schema_owner
FROM pg_namespace
WHERE nspname NOT LIKE 'pg_%' AND nspname <> 'information_schema';
SELECT n.nspname AS object_schema, c.relname AS object_name,
       CASE c.relkind WHEN 'r' THEN 'table' WHEN 'S' THEN 'sequence' ELSE c.relkind::text END AS object_type,
       pg_get_userbyid(c.relowner) AS object_owner
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname <> 'information_schema'
  AND c.relkind IN ('r', 'S')
ORDER BY n.nspname, c.relkind, c.relname;
SELECT rolname, rolsuper, rolcreatedb, rolcreaterole, rolcanlogin, rolreplication, rolbypassrls
FROM pg_roles WHERE rolname = current_user;
SELECT datname,
       has_database_privilege(current_user, datname, 'CONNECT') AS can_connect,
       has_database_privilege(current_user, datname, 'CREATE') AS can_create,
       has_database_privilege(current_user, datname, 'TEMPORARY') AS can_temp
FROM pg_database WHERE datname = current_database();
SELECT n.nspname AS schema_name,
       has_schema_privilege(current_user, n.oid, 'USAGE') AS has_usage,
       has_schema_privilege(current_user, n.oid, 'CREATE') AS has_create
FROM pg_namespace n
WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname <> 'information_schema';
SELECT table_schema, table_name,
       has_table_privilege(current_user, format('%I.%I', table_schema, table_name), 'SELECT') AS can_select,
       has_table_privilege(current_user, format('%I.%I', table_schema, table_name), 'INSERT') AS can_insert,
       has_table_privilege(current_user, format('%I.%I', table_schema, table_name), 'UPDATE') AS can_update,
       has_table_privilege(current_user, format('%I.%I', table_schema, table_name), 'DELETE') AS can_delete,
       has_table_privilege(current_user, format('%I.%I', table_schema, table_name), 'TRUNCATE') AS can_truncate,
       has_table_privilege(current_user, format('%I.%I', table_schema, table_name), 'REFERENCES') AS can_references,
       has_table_privilege(current_user, format('%I.%I', table_schema, table_name), 'TRIGGER') AS can_trigger
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name;
SELECT sequence_schema, sequence_name,
       has_sequence_privilege(current_user, format('%I.%I', sequence_schema, sequence_name), 'USAGE') AS can_usage,
       has_sequence_privilege(current_user, format('%I.%I', sequence_schema, sequence_name), 'SELECT') AS can_select,
       has_sequence_privilege(current_user, format('%I.%I', sequence_schema, sequence_name), 'UPDATE') AS can_update
FROM information_schema.sequences
WHERE sequence_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY sequence_schema, sequence_name;
SELECT member.rolname AS member_role, parent.rolname AS granted_role
FROM pg_auth_members m
JOIN pg_roles member ON member.oid = m.member
JOIN pg_roles parent ON parent.oid = m.roleid
WHERE member.rolname = current_user;
SELECT datname AS isolated_test_database
FROM pg_database
WHERE datname LIKE 'yumeya_privtest_%'
ORDER BY datname;
SELECT rolname AS isolated_test_role
FROM pg_roles
WHERE rolname LIKE 'yumeya_owner_test_%'
   OR rolname LIKE 'yumeya_app_test_%'
ORDER BY rolname;
"@
    & $PsqlPath -X -h $HostName -p $Port -U $User -d $Database -v ON_ERROR_STOP=1 -P pager=off -P footer=off -c $query
    if ($LASTEXITCODE -ne 0) { throw "権限監査SQLが失敗しました。終了コード: $LASTEXITCODE" }
}
finally {
    if ($null -ne $pointer) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
    $plainPassword = $null
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}
