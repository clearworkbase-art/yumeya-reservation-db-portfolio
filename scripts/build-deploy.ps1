# Windows PowerShell 5.1: keep this file saved as UTF-8 with BOM.
param(
    [string]$TomcatHome = $env:CATALINA_HOME
)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($TomcatHome)) {
    throw 'TomcatHomeを指定してください。例: -TomcatHome <Tomcat installation directory>'
}
$runner = Join-Path $PSScriptRoot 'yumeya-local.ps1'
if (-not (Test-Path -LiteralPath $runner)) { throw "統合スクリプトが見つかりません: $runner" }
& $runner -Action Deploy -TomcatHome $TomcatHome
exit $LASTEXITCODE
