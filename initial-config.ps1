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
$iis_user = $cf.config.iis_user.value
$tc_user = $cf.config.tc_user.value
$tc_pass = $cf.config.tc_pass.value
$tc_db_path = $cf.config.tc_db_path.value
$iis_topclass_root = $cf.config.iis_topclass_root.value
$tc_db_server = $cf.config.tc_db_server.value
$tc_server_path = $cf.config.tc_server_path.value
$ask_permission = [Boolean]::Parse($cf.config.ask_permission.value)
$sql_use_windows_auth = [Boolean]::Parse($cf.config.sql_use_windows_auth.value)




# The messy bits are kept in the TopClassTools Module
Import-Module $scriptDir\TopClassTools

# Install/Config required IIS features
Install-TCiis

# Install PHP with fastcgi module for IIS
Install-TCphp -setup_dir $setup_dir -installerName $phpInstallerName


# Configure SQL server to allow CLRs, which it doesn't by default
# and enable 'sa' account - bad practice. We should fix our install scripts
Enable-TCclr `
    -use_windows_auth $sql_use_windows_auth `
    -admin_name $sql_admin_name `
    -admin_password $sql_admin_password `
    -instance_name $sql_server_name `
    -ask_permission $ask_permission `
    -enable_mixed_mode $true `
    -enable_sa_account $true `
    -reset_sa_password $true


# Unzip makes use of tools installed by git, there is no unzip command in base Windows
$tc_base_name = (Split-Path $tc_installer_zip -leaf).ToString().Replace(".zip", "")
$tc_dist_path = "$setup_dir\$tc_base_name"
#Invoke-Expression "C:\Program Files (x86)\Git\bin\unzip.exe -q $setup_dir\$tc_installer_zip -d $tc_dist_path"

Start-Process `
    -file "C:\Program Files (x86)\Git\bin\unzip.exe" `
    -arg "-q $setup_dir\$tc_installer_zip -d $tc_dist_path" `
    -passthru | Wait-Process


# SQL Config
$install_dir = "$setup_dir\install"
mkdir $install_dir
Copy-Item "$tc_dist_path\MSSQL" $install_dir -recurse

# Edit tc_setup.command

$file = "$install_dir\MSSQL\tc_setenv.cmd"
$orig = "$file.orig"
Rename-Item $file $orig

Get-Content $orig |
    ForEach-Object {

        $_ -replace 'set MS_SRV_NAME=%COMPUTERNAME%', "set MS_SRV_NAME=$tc_db_server" `
        -replace 'set TC_USER=tc_user92', "set TC_USER=$tc_user" `
        -replace 'set TC_DATA=C:\\Program Files\\Microsoft SQL Server\\MSSQL.1\\MSSQL\\Data', "set TC_DATA=$tc_db_path"
    } | Set-Content $file

New-Item -type directory -path $tc_db_path -force

$env:SILENT="true"
cd "$install_dir\MSSQL"
Invoke-Expression ".\tc_setup_db.cmd $tc_pass $sql_admin_password"
Invoke-Expression ".\tc_db_schema.cmd $tc_pass install"


# Copy TC Server files into place

Copy-Item "$tc_dist_path\TopClass9" $tc_server_path -recurse

Copy-Item "$tc_server_path\topclass.war" "$tc_server_path\tcc\tomcat\webapps"

# Edit server.xml file

$file = "$tc_server_path\tcc\tomcat\conf\server.xml"
$orig = "$file.orig"
Rename-Item $file $orig

Get-Content $orig |
    ForEach-Object {

        $_ -replace 'Connector port="8009" protocol="AJP/1.3" redirectPort="8443"', `
            "Connector port=`"8009`" protocol=`"AJP/1.3`" redirectPort=`"8443`" URIEncoding=`"UTF8`""
 
    } | Set-Content $file

Write-Host "Setting permissions on $tc_server_path"

# Set Permissions on TopClass directory
$acl = Get-Acl $tc_server_path
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($iis_user, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl -aclobject $acl $tc_server_path


# Create Tomcat Service

Write-Host "Creating TomCat Service"

cd "$tc_server_path\tcc\tomcat\bin"
$env:JAVA_HOME="$tc_server_path\tcc\jdk"
Invoke-Expression ".\service install tomcat6"
New-Item -type directory -path "$tc_server_path\tcc\tomcat\conf\topclass" -force


Invoke-Expression "net start tomcat6"

Write-Host "Waiting four minutes for the WAR to deploy"
Start-Sleep -seconds 240

Write-Host "Stopping Tomcat"

Invoke-Expression "net stop tomcat6"

Write-Host "Configure Hibernate properties"

$tc_conf_dir = "$tc_server_path\tcc\tomcat\conf\topclass"
$tc_class_dir = "$tc_server_path\tcc\tomcat\webapps\topclass\WEB-INF\classes"
Copy-Item "$tc_class_dir\hibernate.properties" $tc_conf_dir
Copy-Item "$tc_class_dir\defaults.xml" $tc_conf_dir


# Edit hibernate.properties file

$file = "$tc_conf_dir\hibernate.properties"
$orig = "$file.orig"
Rename-Item $file $orig

Get-Content $orig |
    ForEach-Object {

        $_ -replace 'hibernate.connection.username=tcUser', "hibernate.connection.username=$tc_user" `
        -replace 'hibernate.connection.password=tcPass', "hibernate.connection.password=$tc_pass" `
        -replace 'hibernate.connection.isolation=1', "hibernate.connection.isolation=2" `
        -replace 'hibernate.connection.driver_class=oracle', "#hibernate.connection.driver_class=oracle" `
        -replace 'hibernate.connection.url=jdbc:oracle', "#hibernate.connection.url=jdbc:oracle" `
        -replace 'hibernate.dialect=com.wbtsystems.topclass.util.Oracle', "#hibernate.dialect=com.wbtsystems.topclass.util.Oracle" `
        -replace '#hibernate.connection.driver_class=com.microsoft', "hibernate.connection.driver_class=com.microsoft" `
        -replace '#hibernate.connection.url=jdbc:sqlserver://@sqlhost@', "hibernate.connection.url=jdbc:sqlserver://$tc_db_server" `
        -replace '#hibernate.dialect=com.wbtsystems.topclass.util.UnicodeSql', "hibernate.dialect=com.wbtsystems.topclass.util.UnicodeSql" `
 
    } | Set-Content $file

Write-Host "Starting Tomcat"
Invoke-Expression "net start tomcat6"

# Now to configure IIS
Write-Host "Now going to configure IIS"

Import-Module WebAdministration

New-WebApplication -name jakarta -Site "Default Web Site" -PhysicalPath "$tc_server_path\tcc\iis\dll"

$app_cmd = "c:\windows\system32\inetsrv\appcmd.exe"
Invoke-Expression "$app_cmd unlock config 'Default Web Site' /section:system.webserver/handlers /commit:apphost"

Set-WebConfigurationProperty -pspath 'IIS:Sites\Default Web Site\jakarta' `
    -filter 'system.webserver/handlers' -name accesspolicy -value "Read,Execute,Script"

# Add jakarta reg entries

Write-Host "Adding Jakarta Registry entries"

$reg_base = "HKLM:\Software\Apache Software Foundation"
New-Item -Path "$reg_base"
$reg_base = "HKLM:\Software\Apache Software Foundation\Jakarta Isapi Redirector"
New-Item -Path "$reg_base"
$reg_base = "HKLM:\Software\Apache Software Foundation\Jakarta Isapi Redirector\1.0"
New-Item -Path "$reg_base"

New-ItemProperty -Path "$reg_base" -Name "extension_uri" -Value "/jakarta/isapi_redirect.dll"
New-ItemProperty -Path "$reg_base" -Name "worker_file" -Value "$tc_server_path\tcc\iis\conf\workers.properties"
New-ItemProperty -Path "$reg_base" -Name "worker_mount_file" -Value "$tc_server_path\tcc\iis\conf\uriworkermap.properties"
New-ItemProperty -Path "$reg_base" -Name "log_file" -Value "$tc_server_path\tcc\tomcat\logs\isapi_redirect.log"
New-ItemProperty -Path "$reg_base" -Name "log_level" -Value "info"

Invoke-Expression "$app_cmd set config /section:isapiFilters /+`"[name='jakarta',path='$tc_server_path\tcc\iis\dll\isapi_redirect.dll',preCondition='bitness64']`""

Invoke-Expression "$app_cmd set config -section:system.webServer/security/isapiCgiRestriction /+`"[path='$tc_server_path\tcc\iis\dll\isapi_redirect.dll',allowed='True',description='TC Redirector']`" /commit:apphost"

New-Item -type directory -path "$iis_topclass_root" -force
New-Item -type directory -path "$iis_topclass_root\media" -force

# Set Permissions on TopClass directory
$acl = Get-Acl $iis_topclass_root
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($iis_user, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl -aclobject $acl $iis_topclass_root

# Edit PHP File Manager config file

Write-Host "Configure PHP File Manager"

$file = "$tc_server_path\tcc\tomcat\webapps\topclass\tinymce\plugins\filemanager\config.php"
$orig = "$file.orig"
Rename-Item $file $orig

$fwd_path = $iis_topclass_root -replace("\\","/")

Get-Content $orig |
    ForEach-Object {

        $_ -replace "preview.wwwroot'] = ''", "preview.wwwroot'] = '$fwd_path'" `
         -replace "{proto}://{host}/" , "{proto}://{host}/topclass/" `
         -replace "rootpath'] = '`.`.`/`.`.`/`.`.`/';", "rootpath'] = '$fwd_path';"
       
    } | Set-Content $file

Write-Host "Install Complete"

