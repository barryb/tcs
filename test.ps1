# This PowerShell Script will enable CLR on the local SQL Server, disabling lightweight pooling

[xml] $config = Get-Content .\config.xml

Import-Module .\TopClassTools


Setup-TC-IIS
Setup-TC-PHP