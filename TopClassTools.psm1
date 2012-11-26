Import-Module   ServerManager

function Setup-TCiis {

    Add-WindowsFeature -Name Web-Static-Content, `
    Web-Default-Doc, Web-Http-Errors, `
    Web-CGI, Web-ISAPI-Ext, Web-ISAPI-Filter, `
    Web-Http-Logging, Web-Request-Monitor, `
    Web-Filtering, `
    Web-Stat-Compression, `
    Web-Mgmt-Console, Web-Scripting-Tools, Web-Mgmt-Service

}


function Setup-TCphp {

    param (

        [string] $setup_dir = $config.setup_dir,
        [string] $installer = "$setup_dir/$config.php.installer"
        )

    [string] $args = "/q ADDLOCAL=iis4FastCGI /log $setup_dir\php-install.log"

    Write-host  $setup_dir
    Write-host $installer
    Write-host $args

     #Start-Process `
     #   -file $installer `
     #   -arg $args `
     #   -passthru | Wait-Process

}