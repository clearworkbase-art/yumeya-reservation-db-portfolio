# Windows PowerShell 5.1: keep this file saved as UTF-8 with BOM.
[CmdletBinding()]
param(
    [ValidateSet('Status', 'Test', 'Deploy', 'HotDeploy', 'Up', 'Start', 'Stop', 'Restart', 'DbCheck', 'Smoke', 'RestoreV1')]
    [string]$Action = 'Status',
    [string]$TomcatHome = $env:CATALINA_HOME,
    [string]$BackupRoot,
    [string]$BackupPath,
    [switch]$NoPrompt
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($TomcatHome)) {
    throw 'TomcatHomeを指定してください。例: -TomcatHome <Tomcat installation directory>'
}
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $env:USERPROFILE 'Documents\yumeya-reservation-backups'
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot 'apps\yumeya-reservation'
$PomPath = Join-Path $AppRoot 'pom.xml'
$WarPath = Join-Path $AppRoot 'target\yumeya-reservation.war'
$WebappsPath = Join-Path $TomcatHome 'webapps'
$DeployWarPath = Join-Path $WebappsPath 'yumeya-reservation.war'
$DeployDirPath = Join-Path $WebappsPath 'yumeya-reservation'
$CatalinaPath = Join-Path $TomcatHome 'bin\catalina.bat'

function Assert-FeatureBranch {
    $branch = (& git -C $RepoRoot branch --show-current 2>$null).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
        throw 'Gitのブランチを確認できません。リポジトリの場所とGitを確認してください。'
    }
    if ($branch -in @('main', 'master')) {
        throw "安全のため main/master では実行しません。現在のブランチ: $branch"
    }
    Write-Host "ブランチ確認: $branch"
}

function Assert-Tomcat {
    foreach ($path in @(
        (Join-Path $TomcatHome 'conf\server.xml'),
        (Join-Path $TomcatHome 'bin\catalina.bat'),
        $WebappsPath
    )) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Tomcatの場所を確認してください: $path"
        }
    }
}

function Initialize-Tooling {
    $javaHome = $env:JAVA_HOME
    if ([string]::IsNullOrWhiteSpace($javaHome)) {
        $javaHome = [Environment]::GetEnvironmentVariable('JAVA_HOME', 'User')
    }
    if ([string]::IsNullOrWhiteSpace($javaHome) -or -not (Test-Path -LiteralPath (Join-Path $javaHome 'bin\java.exe'))) {
        throw 'JAVA_HOMEがJDK 17を指していません。新しいPowerShellでJAVA_HOMEを確認してください。'
    }
    $env:JAVA_HOME = $javaHome
    $javaBin = Join-Path $javaHome 'bin'
    $mvn = Get-Command mvn.cmd -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $mvn) { throw 'mvn.cmdが見つかりません。MavenのbinをPATHへ追加してください。' }
    $mvnPath = $mvn.Source
    $mavenBin = Split-Path -Parent $mvnPath
    $env:Path = "$javaBin;$mavenBin;$env:Path"
    return $mvnPath
}

function Initialize-DbEnvironment([bool]$RequirePassword) {
    $url = $env:YUMEYA_JDBC_URL
    if ([string]::IsNullOrWhiteSpace($url)) {
        $url = [Environment]::GetEnvironmentVariable('YUMEYA_JDBC_URL', 'User')
    }
    if ([string]::IsNullOrWhiteSpace($url)) {
        if ($NoPrompt) { throw 'YUMEYA_JDBC_URLが未設定です。' }
        $url = Read-Host 'JDBC URL（Enterで既定値 jdbc:postgresql://127.0.0.1:5432/yumeya_portfolio）'
        if ([string]::IsNullOrWhiteSpace($url)) { $url = 'jdbc:postgresql://127.0.0.1:5432/yumeya_portfolio' }
    }
    if (-not $url.StartsWith('jdbc:postgresql://')) { throw 'PostgreSQL JDBC URLのみ使用できます。' }
    $env:YUMEYA_JDBC_URL = $url

    $user = $env:YUMEYA_DB_USER
    if ([string]::IsNullOrWhiteSpace($user)) {
        $user = [Environment]::GetEnvironmentVariable('YUMEYA_DB_USER', 'User')
    }
    if ([string]::IsNullOrWhiteSpace($user)) {
        if ($NoPrompt) { throw 'YUMEYA_DB_USERが未設定です。' }
        $user = Read-Host 'DBユーザー（Enterで yumeya_app）'
        if ([string]::IsNullOrWhiteSpace($user)) { $user = 'yumeya_app' }
    }
    $env:YUMEYA_DB_USER = $user

    if ($RequirePassword -and [string]::IsNullOrEmpty($env:YUMEYA_DB_PASSWORD)) {
        if ($NoPrompt) { throw 'YUMEYA_DB_PASSWORDが未設定です。-NoPromptを外して端末で入力してください。' }
        $securePassword = Read-Host 'デモDBパスワード（画面には表示されません）' -AsSecureString
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        try { $env:YUMEYA_DB_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
        if ([string]::IsNullOrEmpty($env:YUMEYA_DB_PASSWORD)) { throw 'DBパスワードが空です。' }
    }
    Write-Host 'DB接続環境変数を現在のプロセスへ設定しました（パスワードは表示・保存していません）。'
}

function Get-Listening8080 {
    @(Get-NetTCPConnection -State Listen -LocalPort 8080 -ErrorAction SilentlyContinue)
}

function Wait-HttpPort([bool]$ExpectedOpen) {
    for ($i = 0; $i -lt 30; $i++) {
        $open = @(Get-Listening8080).Count -gt 0
        if ($open -eq $ExpectedOpen) { return }
        Start-Sleep -Seconds 1
    }
    $state = if ($ExpectedOpen) { '起動' } else { '停止' }
    throw "Tomcatの${state}を30秒以内に確認できませんでした。logsを確認してください。"
}

function Invoke-Catalina([string]$Command) {
    Assert-Tomcat
    & $CatalinaPath $Command 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw "catalina.bat $Command が失敗しました。" }
}

function Start-YumeyaTomcat {
    if (@(Get-Listening8080).Count -gt 0) {
        Write-Host 'Tomcatはすでに8080番で起動しています。'
        return
    }
    $env:CATALINA_HOME = $TomcatHome
    Invoke-Catalina 'start'
    Wait-HttpPort $true
    Write-Host 'Tomcatを起動しました: http://127.0.0.1:8080/yumeya-reservation/'
}

function Stop-YumeyaTomcat {
    if (@(Get-Listening8080).Count -eq 0) {
        Write-Host 'Tomcatは8080番で起動していません。'
        return
    }
    $env:CATALINA_HOME = $TomcatHome
    Invoke-Catalina 'stop'
    Wait-HttpPort $false
    Write-Host 'Tomcatを停止しました。'
}

function Invoke-MavenPackage {
    $mvnPath = Initialize-Tooling
    if (-not (Test-Path -LiteralPath $PomPath)) { throw "pom.xmlが見つかりません: $PomPath" }
    & $mvnPath -f $PomPath clean package 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw 'Mavenビルドまたは自動テストに失敗しました。WARは配置しません。' }
    if (-not (Test-Path -LiteralPath $WarPath)) { throw "WARが生成されませんでした: $WarPath" }
    Write-Host "Mavenビルド・テスト成功: $WarPath"
}

function New-DeploymentBackup {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupPath = Join-Path $BackupRoot ("yumeya-reservation_" + $stamp)
    $suffix = 1
    while (Test-Path -LiteralPath $backupPath) {
        $backupPath = Join-Path $BackupRoot ("yumeya-reservation_" + $stamp + '_' + $suffix)
        $suffix++
    }
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    $hasWar = Test-Path -LiteralPath $DeployWarPath
    $hasDir = Test-Path -LiteralPath $DeployDirPath
    if ($hasWar) { Move-Item -LiteralPath $DeployWarPath -Destination (Join-Path $backupPath 'yumeya-reservation.war') }
    if ($hasDir) { Move-Item -LiteralPath $DeployDirPath -Destination (Join-Path $backupPath 'yumeya-reservation') }
    [ordered]@{
        created_at = (Get-Date).ToString('o')
        tomcat_home = $TomcatHome
        had_war = $hasWar
        had_exploded_directory = $hasDir
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backupPath 'manifest.json') -Encoding UTF8
    Write-Host "既存配備をバックアップしました: $backupPath"
    return $backupPath
}

function New-DeploymentSnapshot {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $snapshotPath = Join-Path $BackupRoot ("yumeya-reservation_hotdeploy_" + $stamp)
    $suffix = 1
    while (Test-Path -LiteralPath $snapshotPath) {
        $snapshotPath = Join-Path $BackupRoot ("yumeya-reservation_hotdeploy_" + $stamp + '_' + $suffix)
        $suffix++
    }
    New-Item -ItemType Directory -Path $snapshotPath -Force | Out-Null
    $hasWar = Test-Path -LiteralPath $DeployWarPath
    $hasDir = Test-Path -LiteralPath $DeployDirPath
    if ($hasWar) { Copy-Item -LiteralPath $DeployWarPath -Destination (Join-Path $snapshotPath 'yumeya-reservation.war') }
    if ($hasDir) { Copy-Item -LiteralPath $DeployDirPath -Destination (Join-Path $snapshotPath 'yumeya-reservation') -Recurse }
    [ordered]@{
        created_at = (Get-Date).ToString('o')
        mode = 'hotdeploy-snapshot'
        tomcat_home = $TomcatHome
        had_war = $hasWar
        had_exploded_directory = $hasDir
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $snapshotPath 'manifest.json') -Encoding UTF8
    Write-Host "現行配備をスナップショットしました: $snapshotPath"
    return $snapshotPath
}

function Restore-MovedDeployment([string]$Path) {
    $backupWar = Join-Path $Path 'yumeya-reservation.war'
    $backupDir = Join-Path $Path 'yumeya-reservation'
    if (Test-Path -LiteralPath $DeployWarPath) { Move-Item -LiteralPath $DeployWarPath -Destination (Join-Path $Path 'rollback-yumeya-reservation.war') }
    if (Test-Path -LiteralPath $DeployDirPath) { Move-Item -LiteralPath $DeployDirPath -Destination (Join-Path $Path 'rollback-yumeya-reservation') }
    if (Test-Path -LiteralPath $backupWar) { Move-Item -LiteralPath $backupWar -Destination $DeployWarPath }
    if (Test-Path -LiteralPath $backupDir) { Move-Item -LiteralPath $backupDir -Destination $DeployDirPath }
}

function Deploy-War {
    Assert-Tomcat
    if (-not (Test-Path -LiteralPath $WarPath)) { throw "WARがありません。先にTestを実行してください: $WarPath" }
    $wasRunning = @(Get-Listening8080).Count -gt 0
    if ($wasRunning) { Stop-YumeyaTomcat }
    $backupPath = $null
    try {
        $backupPath = New-DeploymentBackup
        Copy-Item -LiteralPath $WarPath -Destination $DeployWarPath
        Write-Host "v2 WARを配置しました: $DeployWarPath"
        return $backupPath
    } catch {
        if ($null -ne $backupPath) { Restore-MovedDeployment $backupPath }
        throw
    }
}

function HotDeploy-War {
    Assert-Tomcat
    if (@(Get-Listening8080).Count -eq 0) {
        throw 'HotDeployには起動中のTomcatが必要です。停止中は -Action Up を使用してください。'
    }
    if (-not (Test-Path -LiteralPath $WarPath)) { throw "WARがありません: $WarPath" }
    $snapshotPath = New-DeploymentSnapshot
    try {
        Copy-Item -LiteralPath $WarPath -Destination $DeployWarPath -Force
        Write-Host "修正版WARを実行中Tomcatへ配置しました。autoDeployによる再配備を待機します。"
        Start-Sleep -Seconds 3
        return $snapshotPath
    } catch {
        $snapshotWar = Join-Path $snapshotPath 'yumeya-reservation.war'
        if (Test-Path -LiteralPath $snapshotWar) { Copy-Item -LiteralPath $snapshotWar -Destination $DeployWarPath -Force }
        throw
    }
}

function Parse-JdbcUrl {
    $match = [regex]::Match($env:YUMEYA_JDBC_URL, '^jdbc:postgresql://(?<host>[^/:?]+)(?::(?<port>\d+))?/(?<db>[^?]+)')
    if (-not $match.Success) { throw 'YUMEYA_JDBC_URLを解析できません。' }
    if ($match.Groups['host'].Value -notin @('127.0.0.1', 'localhost')) { throw '安全のためローカルPostgreSQLだけを対象にします。' }
    [pscustomobject]@{
        Host = $match.Groups['host'].Value
        Port = if ($match.Groups['port'].Success) { $match.Groups['port'].Value } else { '5432' }
        Database = $match.Groups['db'].Value
    }
}

function Find-Psql {
    $command = Get-Command psql.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command) { return $command.Source }
    throw 'psql.exeが見つかりません。PostgreSQL 17のbinを確認してください。'
}

function Invoke-Psql([string]$Sql, [switch]$TuplesOnly) {
    $settings = Parse-JdbcUrl
    $psql = Find-Psql
    $oldPassword = $env:PGPASSWORD
    try {
        $env:PGPASSWORD = $env:YUMEYA_DB_PASSWORD
        $args = @('-X', '-w', '-v', 'ON_ERROR_STOP=1', '-h', $settings.Host, '-p', $settings.Port,
            '-U', $env:YUMEYA_DB_USER, '-d', $settings.Database)
        if ($TuplesOnly) { $args += '-At' }
        $args += @('-c', $Sql)
        $output = & $psql @args 2>&1
        if ($LASTEXITCODE -ne 0) { throw (($output | Out-String).Trim()) }
        return $output
    } finally {
        if ($null -eq $oldPassword) { Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue }
        else { $env:PGPASSWORD = $oldPassword }
    }
}

function Invoke-DbCheck {
    Initialize-DbEnvironment $true
    $output = Invoke-Psql "SELECT current_database(), current_user; SELECT 'rooms=' || COUNT(*) FROM rooms; SELECT 'reservations=' || COUNT(*) FROM reservations;" -TuplesOnly
    Write-Host ($output | Out-String).Trim()
    Write-Host 'PostgreSQL接続・基本テーブル確認に成功しました。'
}

function Get-HiddenValue([string]$Html, [string]$Name) {
    $pattern = 'name="' + [regex]::Escape($Name) + '"\s+value="([^"]+)"'
    $match = [regex]::Match($Html, $pattern)
    if (-not $match.Success) { throw "画面から$Nameを取得できませんでした。" }
    return [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value)
}

function Invoke-HttpSmoke {
    $base = 'http://127.0.0.1:8080/yumeya-reservation'
    if (@(Get-Listening8080).Count -eq 0) { Start-YumeyaTomcat }
    $createdId = $null
    $checkIn = $null
    $checkOut = $null
    $session1 = $null
    for ($attempt = 0; $attempt -lt 8 -and $null -eq $createdId; $attempt++) {
        $checkIn = (Get-Date).Date.AddDays(30 + ($attempt * 14)).ToString('yyyy-MM-dd')
        $checkOut = (Get-Date).Date.AddDays(32 + ($attempt * 14)).ToString('yyyy-MM-dd')
        $session1 = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $form = Invoke-WebRequest -UseBasicParsing -TimeoutSec 15 -Uri "$base/reservation" -WebSession $session1
        $csrf = Get-HiddenValue $form.Content 'csrfToken'
        $confirm = Invoke-WebRequest -UseBasicParsing -TimeoutSec 15 -Method Post -Uri "$base/reservation/confirm" -WebSession $session1 -Body @{
            csrfToken = $csrf; room = 'MATSU'; checkIn = $checkIn; checkOut = $checkOut; guests = '2'
        }
        $confirmToken = Get-HiddenValue $confirm.Content 'csrfToken'
        $complete = Invoke-WebRequest -UseBasicParsing -TimeoutSec 15 -Method Post -Uri "$base/reservation/complete" -WebSession $session1 -Body @{ csrfToken = $confirmToken }
        if ($complete.Content -match '架空データを保存しました') {
            $idMatch = [regex]::Match($complete.Content, 'デモ登録ID</dt>\s*<dd>(\d+)</dd>')
            if ($idMatch.Success) { $createdId = $idMatch.Groups[1].Value }
        }
    }
    if ($null -eq $createdId) { throw '予約登録スモークテストに失敗しました。空いている日程を確保できませんでした。' }

    $list = Invoke-WebRequest -UseBasicParsing -TimeoutSec 15 -Uri "$base/admin/reservations?room=MATSU&status=CONFIRMED" -WebSession $session1
    if ($list.Content -notmatch [regex]::Escape($checkIn) -or $list.Content -notmatch [regex]::Escape($createdId)) {
        throw '予約一覧取得スモークテストに失敗しました。'
    }

    $session2 = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $form2 = Invoke-WebRequest -UseBasicParsing -TimeoutSec 15 -Uri "$base/reservation" -WebSession $session2
    $csrf2 = Get-HiddenValue $form2.Content 'csrfToken'
    $confirm2 = Invoke-WebRequest -UseBasicParsing -TimeoutSec 15 -Method Post -Uri "$base/reservation/confirm" -WebSession $session2 -Body @{
        csrfToken = $csrf2; room = 'MATSU'; checkIn = $checkIn; checkOut = $checkOut; guests = '2'
    }
    $confirmToken2 = Get-HiddenValue $confirm2.Content 'csrfToken'
    $duplicate = Invoke-WebRequest -UseBasicParsing -TimeoutSec 15 -Method Post -Uri "$base/reservation/complete" -WebSession $session2 -Body @{ csrfToken = $confirmToken2 }
    if ($duplicate.Content -notmatch '既に架空の予約が登録されています') {
        throw '重複予約防止スモークテストに失敗しました。'
    }

    $admin = Invoke-WebRequest -UseBasicParsing -TimeoutSec 15 -Uri "$base/admin/reservations?room=MATSU&status=CONFIRMED" -WebSession $session1
    $adminToken = Get-HiddenValue $admin.Content 'csrfToken'
    $cancel = Invoke-WebRequest -UseBasicParsing -TimeoutSec 15 -Method Post -Uri "$base/admin/reservations/cancel" -WebSession $session1 -Body @{ id = $createdId; csrfToken = $adminToken }
    if ($cancel.Content -notmatch '取消状態に更新しました') { throw '予約取消スモークテストに失敗しました。' }

    Write-Host "HTTPスモークテスト成功: 登録・一覧・重複拒否・取消 / ID=$createdId / 日付=$checkIn〜$checkOut"
    Write-Host 'テスト用レコードは削除せずCANCELLEDへ更新しました。DBの履歴を保持する設計です。'
}

function Restore-V1([string]$Path) {
    Assert-Tomcat
    if ([string]::IsNullOrWhiteSpace($Path)) {
        if (-not (Test-Path -LiteralPath $BackupRoot)) { throw 'バックアップフォルダがありません。' }
        $Path = Get-ChildItem -LiteralPath $BackupRoot -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { throw "バックアップが見つかりません: $Path" }
    if (@(Get-Listening8080).Count -gt 0) { Stop-YumeyaTomcat }
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    $rollbackPath = Join-Path $BackupRoot ("rollback_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
    New-Item -ItemType Directory -Path $rollbackPath -Force | Out-Null
    try {
        if (Test-Path -LiteralPath $DeployWarPath) { Move-Item -LiteralPath $DeployWarPath -Destination (Join-Path $rollbackPath 'yumeya-reservation.war') }
        if (Test-Path -LiteralPath $DeployDirPath) { Move-Item -LiteralPath $DeployDirPath -Destination (Join-Path $rollbackPath 'yumeya-reservation') }
        $backupWar = Join-Path $Path 'yumeya-reservation.war'
        $backupDir = Join-Path $Path 'yumeya-reservation'
        if (Test-Path -LiteralPath $backupWar) { Copy-Item -LiteralPath $backupWar -Destination $DeployWarPath }
        if (Test-Path -LiteralPath $backupDir) { Copy-Item -LiteralPath $backupDir -Destination $DeployDirPath -Recurse }
        Write-Host "バックアップから復旧しました: $Path"
        Write-Host "復旧前の配備は保全しました: $rollbackPath"
    } catch {
        if (Test-Path -LiteralPath $DeployWarPath) { Remove-Item -LiteralPath $DeployWarPath -Force }
        if (Test-Path -LiteralPath $DeployDirPath) { Remove-Item -LiteralPath $DeployDirPath -Recurse -Force }
        if (Test-Path -LiteralPath (Join-Path $rollbackPath 'yumeya-reservation.war')) { Move-Item -LiteralPath (Join-Path $rollbackPath 'yumeya-reservation.war') -Destination $DeployWarPath }
        if (Test-Path -LiteralPath (Join-Path $rollbackPath 'yumeya-reservation')) { Move-Item -LiteralPath (Join-Path $rollbackPath 'yumeya-reservation') -Destination $DeployDirPath }
        throw "復旧に失敗しました。元の配備を復元しました。バックアップ: $Path`n$($_.Exception.Message)"
    }
}

switch ($Action) {
    'Status' {
        Assert-FeatureBranch
        Assert-Tomcat
        Write-Host "Tomcat: $TomcatHome"
        Write-Host ("8080 listening: {0}" -f (@(Get-Listening8080).Count -gt 0))
        Write-Host ("WAR exists: {0}" -f (Test-Path -LiteralPath $DeployWarPath))
        Write-Host ("Exploded app exists: {0}" -f (Test-Path -LiteralPath $DeployDirPath))
    }
    'Test' {
        Assert-FeatureBranch
        Invoke-MavenPackage
    }
    'Deploy' {
        Assert-FeatureBranch
        Invoke-MavenPackage
        $backup = Deploy-War
        Write-Host "Tomcatは起動していません。必要なら -Action Start を実行してください。"
        Write-Host "復旧用バックアップ: $backup"
    }
    'HotDeploy' {
        Assert-FeatureBranch
        Invoke-MavenPackage
        $snapshot = HotDeploy-War
        Write-Host 'Tomcatは停止していません。既存プロセスのDB環境変数を維持したままWebアプリを再配備しました。'
        Write-Host "復旧用スナップショット: $snapshot"
    }
    'Up' {
        Assert-FeatureBranch
        Invoke-MavenPackage
        Initialize-DbEnvironment $true
        $backup = Deploy-War
        try { Start-YumeyaTomcat }
        catch {
            Write-Host '起動に失敗したため、直前の配備を復旧します。'
            Restore-MovedDeployment $backup
            throw
        }
        Write-Host "復旧用バックアップ: $backup"
    }
    'Start' {
        Assert-FeatureBranch
        Assert-Tomcat
        Initialize-DbEnvironment $true
        Start-YumeyaTomcat
    }
    'Stop' {
        Assert-FeatureBranch
        Assert-Tomcat
        Stop-YumeyaTomcat
    }
    'Restart' {
        Assert-FeatureBranch
        Assert-Tomcat
        Initialize-DbEnvironment $true
        Stop-YumeyaTomcat
        Start-YumeyaTomcat
    }
    'DbCheck' {
        Assert-FeatureBranch
        Initialize-DbEnvironment $true
        Invoke-DbCheck
    }
    'Smoke' {
        Assert-FeatureBranch
        if (@(Get-Listening8080).Count -eq 0) {
            Initialize-DbEnvironment $true
        } else {
            Write-Host '起動中TomcatへHTTP Smokeを実行します。DBパスワードはこのプロセスで再取得しません。'
        }
        Invoke-HttpSmoke
    }
    'RestoreV1' {
        Assert-FeatureBranch
        Restore-V1 $BackupPath
    }
}
