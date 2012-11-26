# This PowerShell Script will enable CLR on the local SQL Server, disabling lightweight pooling

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath

[xml] $config = Get-Content $scriptDir\config.xml

Import-Module $scriptDir\TopClassTools


Setup-TCiis
#Setup-TCphp