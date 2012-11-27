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

        [string] $setup_dir = $cf.config.setup_dir.value,
        [string] $phpInstallerName = $cf.config.phpInstallerName
        )

    [string] $args = "/q ADDLOCAL=iis4FastCGI /log $setup_dir\php-install.log"

    [string] $test = $cf.config.setup_dir.value
    Write-host "Test: $test"

    Write-host "File: $setup_dir\$phpInstallerName"
    Write-host "args: $args"

     Start-Process `
        -file "$setup_dir\$phpInstallerName" `
        -arg $args `
        -passthru | Wait-Process

}