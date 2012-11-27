# This PowerShell Script will enable CLR on the local SQL Server, disabling lightweight pooling

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath

$cf = [xml](Get-Content "$scriptDir\config.xml")

# I'm sure there is a better way to auto parse all the variables in the XML, but this will do for now
$setup_dir = $cf.config.setup_dir.value
$phpInstallerName = $cf.config.phpInstallerName.value
$sql_admin_name = $cf.config.sql_admin_name.value
$sql_admin_password = $cf.config.sql_admin_password.value
$sql_server_name = $cf.config.sql_server_name.value
$tc_installer_zip = $cf.config.tc_installer_zip.value
$sql_admin_password = $cf.config.sql_admin_password.value
$ask_permission = [Boolean]::Parse($cf.config.ask_permission.value)
$sql_use_windows_auth = [Boolean]::Parse($cf.config.sql_use_windows_auth.value)


# The messy bits are kept in the TopClassTools Module
Import-Module $scriptDir\TopClassTools

# Install/Config required IIS features
Install-TCiis

# Install PHP with fastcgi module for IIS
Install-TCphp -setup_dir $setup_dir -installerName $phpInstallerName


# Configure SQL server to allow CLRs, which it doesn't by default
Enable-TCclr `
    -use_windows_auth $sql_use_windows_auth `
    -admin_name $sql_admin_name `
    -admin_password $sql_admin_password `
    -instance_name $sql_server_name `
    -ask_permission $ask_permission

# Tweek explorer settings
$key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-ItemProperty $key Hidden 1
Set-ItemProperty $key HideFileExt 0


# Unzip TopClass Zip
cd $setup_dir
$shell_app=new-object -com shell.application
$zip_file = $shell_app.namespace((Get-Location).Path + "\$tc_installer_zip")
$destination = $shell_app.namespace((Get-Location).Path)
$destination.Copyhere($zip_file.items())

