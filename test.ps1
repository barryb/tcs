# This PowerShell Script will enable CLR on the local SQL Server, disabling lightweight pooling

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath

[xml] $cf = Get-Content $scriptDir\config.xml

Import-Module $scriptDir\TopClassTools


Install-TCiis
Install-TCphp