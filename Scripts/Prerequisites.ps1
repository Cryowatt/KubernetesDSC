#Requires -Version 5
#Requires -Modules PackageManagementProviderResource
<#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PackageManagementProviderResource -Repository PSGallery -Force
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force#>



$requiredModules = @("PackageManagementProviderResource"; "PSDesiredStateConfiguration"; "xPSDesiredStateConfiguration"; "cChoco"; "Pscx"; "xHyper-V")
$requiredModules | Where-Object { 
    return (Get-InstalledModule -Name $_ -ErrorAction SilentlyContinue) -eq $null -and (Get-Module -Name $_) -eq $null
} | ForEach-Object {
    Install-Module -Name $_ -Force -AllowClobber
}

$requiredModules | ForEach-Object { Import-Module $_ }