# This PowerShell Script will enable CLR on the local SQL Server, disabling lightweight pooling

[xml] $config = Get-Content .\config.xml


# By default we use Windows integrated auth for SQL server, but creds can be supplied here if required
$sql_use_windows_auth = $true

$sql_admin_name = 'sa'
$sql_admin_password = 'CHANGE_ME'
$sql_server_name = "MSSQLSERVER"

# Where to find any install files we need
$setup_dir = 'c:\wbt_setup'

# If false, this will run as a batch and won't seek confirmation
$ask_permission = $false


$phpInstallerName = 'php-installer.msi'
$phpArgs = "/q ADDLOCAL=iis4FastCGI /log $setup_dir\php-install.log"


$tc_installer_zip = "tc9-installer.zip"

#
# No user configuration below this line
#

$phpInstallerPath = "$setup_dir\$phpInstallerName"


# Do IIS config

Import-Module ServerManager

# Install IIS
 
Add-WindowsFeature -Name Web-Static-Content, `
    Web-Default-Doc, Web-Http-Errors, `
    Web-CGI, Web-ISAPI-Ext, Web-ISAPI-Filter, `
    Web-Http-Logging, Web-Request-Monitor, `
    Web-Filtering, `
    Web-Stat-Compression, `
    Web-Mgmt-Console, Web-Scripting-Tools, Web-Mgmt-Service


# Install php-install

 Start-Process `
    -file $phpInstallerPath `
    -arg $phpArgs `
    -passthru | Wait-Process


if ( $sql_use_windows_auth -eq $true ) {
    $sql_creds = ""
} else {
    $sql_creds = "-Username $sql_admin_name -Password $sql_admin_password"
}


# Add SQL Snapins if they aren't loaded
    
if ( (Get-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PSSnapin SqlServerCmdletSnapin100
}
    
if ( (Get-PSSnapin -Name SqlServerProviderSnapin100 -ErrorAction SilentlyContinue) -eq $null ) {
    Add-PSSnapin SqlServerProviderSnapin100
}

$sql_cmd = "Invoke-Sqlcmd -Database master $sql_creds -Query "

# Enable Showing advanced options
$command = "exec sp_configure 'show advanced options',1; reconfigure"
Invoke-Expression "$sql_cmd `"$command`""

# Determine if CLR is aready enabled
$command = "exec sp_configure 'clr enabled'"
$result = Invoke-Expression "$sql_cmd `"$command`""
$clr_enabled = $result.config_value

# Determine if Lightweight Pooling is aready enabled
$command = "exec sp_configure 'lightweight pooling'"
$result = Invoke-Expression "$sql_cmd `"$command`""
$lwp_enabled = $result.config_value

$action_commands = @()
$action_notes = @()


if ($clr_enabled -eq 0) {
    
    
   if ($lwp_enabled -eq 1) {

        $action_notes += "Lightweight Pooling will be disabled"
        $command = "exec sp_configure 'lightweight pooling', 0; reconfigure"
        $action_commands += "$sql_cmd `"$command`""
        
        $action_notes += "SQL Server service will be restarted"
        $svc = get-service $sql_server_name
        $svc_name = $svc.name
        $action_commands += "Restart-Service $svc_name -Force"
        $action_commands += "`$svc.WaitForStatus('Running', (new-timespan -seconds 30))"      
        $action_commands += "$sql_cmd `"select newid()`" -ErrorAction SilentlyContinue"
        
   }
   
   $action_notes += "CLR WILL be enabled"
   $command = "exec sp_configure 'clr enabled', 1; reconfigure"
   $action_commands += "$sql_cmd `"$command`""
   
} else {
    Write-Host "CLR was already enabled"
}

Write-Host "`n`nThe following tasks will be done:`n"
foreach ($note in $action_notes) {
    Write-Host $note
}

Write-Host "`n`nThis means the following commands will be executed:`n"
foreach ($action in $action_commands) {
    Write-Host $action
}

$choice = ""


if (($ask_permission -eq $true) -and ($action_commands.length -gt 0)) {
    while ($choice -notmatch "[y|n]") {
        $choice = Read-Host "Are you sure you want to do this? (y/n)?"
    }
    if ($choice -eq "y") {
        $do_actions = $true
    } else {
        $do_actions = $false
    }
} else {
    $do_actions = $true
}

if ( $do_actions -eq $true ) {
    foreach ($action in $action_commands) {
        Invoke-Expression $action
    }
    Write-Host "`n`nAll Done`n"
}