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

[Boolean] $ask_permission = [System.Convert]::ToBoolean($cf.config.ask_permission.value)
[Boolean] $sql_use_windows_auth = [System.Convert]::ToBoolean($cf.config.sql_use_windows_auth.value)

Import-Module $scriptDir\TopClassTools

Write-host "TC: $tc_installer_zip"

write-host $sql_user_windows_auth

if ( $sql_user_windows_auth -eq $true ) {

    write-host "Using Windows AUTH"
} else {

    write-host "Using SA details provided"
}


#Install-TCiis
#Install-TCphp -setup_dir $setup_dir -phpInstallerName $phpInstallerName