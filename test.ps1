# This PowerShell Script will enable CLR on the local SQL Server, disabling lightweight pooling

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath

$cf = [xml](Get-Content "$scriptDir\config.xml")

$setup_dir = $cf.config.setup_dir.value
$phpInstallerName = $cf.config.phpInstallerName.value

Import-Module $scriptDir\TopClassTools


Install-TCiis
Install-TCphp -setup_dir $setup_dir -phpInstallerName $phpInstallerName