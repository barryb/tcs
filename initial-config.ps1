# This PowerShell Script will enable CLR on the local SQL Server, disabling lightweight pooling

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath

$cf = [xml](Get-Content "$scriptDir\config.xml")

$setup_dir = $cf.config.setup_dir.value
$phpInstallerName = $cf.config.phpInstallerName.value
$sql_admin_name = $cf.config.sql_admin_name.value
$sql_admin_password = $cf.config.sql_admin_password.value
$sql_server_name = $cf.config.sql_server_name.value
$tc_installer_zip = $cf.config.tc_installer_zip.value
$sql_admin_password = $cf.config.sql_admin_password.value
$ask_permission = [Boolean]::Parse($cf.config.ask_permission.value)
$sql_use_windows_auth = [Boolean]::Parse($cf.config.sql_use_windows_auth.value)

Import-Module $scriptDir\TopClassTools

Install-TCiis
Install-TCphp -setup_dir $setup_dir -installerName $phpInstallerName

Enable-TCclr `
    -use_windows_auth $sql_use_windows_auth `
    -admin_name $sql_admin_name `
    -admin_password $sql_admin_password `
    -instance_name $sql_server_name `
    -ask_permission $ask_permission
