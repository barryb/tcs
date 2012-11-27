Import-Module   ServerManager

function Install-TCiis {

    Add-WindowsFeature -Name Web-Static-Content, `
    Web-Default-Doc, Web-Http-Errors, `
    Web-CGI, Web-ISAPI-Ext, Web-ISAPI-Filter, `
    Web-Http-Logging, Web-Request-Monitor, `
    Web-Filtering, `
    Web-Stat-Compression, `
    Web-Mgmt-Console, Web-Scripting-Tools, Web-Mgmt-Service

}


function Install-TCphp {
    param (

        [string] $setup_dir,
        [string] $installerName
        )

    [string] $args = "/q ADDLOCAL=iis4FastCGI /log $setup_dir\php-install.log"

     Start-Process `
        -file "$setup_dir\$installerName" `
        -arg $args `
        -passthru | Wait-Process

}



function Enable-TCclr {

    param (
            [boolean] $use_windows_auth = $true,
            [string] $admin_name = 'sa',
            [string] $admin_password = 'needpassword',
            [string] $instance_name = 'MSSQLSERVER',
            [boolean] $ask_permission = $false

        )

    if ( $use_windows_auth -eq $true ) {
        $sql_creds = ""
    } else {
        $sql_creds = "-Username $admin_name -Password $admin_password"
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
            $svc = get-service $instance_name
            $svc_name = $svc.name
            $action_commands += "Restart-Service $svc_name -Force"
            $action_commands += "`$svc.WaitForStatus('Running', (new-timespan -seconds 30))"  

            # The following command is a dummy command to force a new connection after the above restart    
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
}