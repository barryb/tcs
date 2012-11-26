# This PowerShell Script will enable CLR on the local SQL Server, disabling lightweight pooling

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath

$cf = [xml](Get-Content "c:\wbt_setup\tcs\config.xml")

write-host "PHP INstaller: $cf.config.phpInstallerName"

Import-Module $scriptDir\TopClassTools


Install-TCiis
Install-TCphp