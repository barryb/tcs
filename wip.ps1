

# Edit hibernate.properties file

function Edit-HibernateProperties {

    param (
        [string] $file,
        [string] $username,
        [string] $password,
        [string] $dbhost,
        [string] $dbtype = 'mssql'
    )

    $orig = "$file.original"
    Rename-Item "$file" $orig -force

    Get-Content $orig |
        ForEach-Object {
        
        if ( $dbtype -eq 'mssql') {
        
            # Uncomment any         
            $_ `
            -replace '#(hibernate.connection.driver_class=com.microsoft)', "`$1" `
            -replace '#(hibernate.connection.url=jdbc:sqlserver://)@sqlhost@', "`$1$dbhost" `
            -replace '#(hibernate.dialect=com.wbtsystems.topclass.util.UnicodeSql)', "`$1"
        
        
        }

            $_ `            -replace '(hibernate.connection.username=)tcUser', "`$1$username" `
            -replace '(hibernate.connection.password=)tcPass', "`$1$password" `
            -replace '(hibernate.connection.isolation=)1', "`${1}2" `
            -replace '(hibernate.connection.driver_class=oracle)', "#`$1" `
            -replace '(hibernate.connection.url=jdbc:oracle)', "#`$1" `
            -replace '(hibernate.dialect=com.wbtsystems.topclass.util.Oracle)', "#`$1" `
            
     
        } | Set-Content $file
}
    
    

Edit-HibernateProperties `    -file "C:\temp\hibernate.properties" `    -username "TCusername" `    -password "TCpassword" `    -dbhost "localhost" `
    -dbtype "mssql"

Copy-Item "C:\temp\fresh-hibernate.properties" "C:\temp\hibernate.properties"