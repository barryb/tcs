# This PowerShell Script will enable CLR on the local SQL Server, disabling lightweight pooling

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath

$cf = [xml](Get-Content "$scriptDir\config.xml")

write-host $cf.config.phpInstallerName

Import-Module $scriptDir\TopClassTools


Install-TCiis
Install-TCphp