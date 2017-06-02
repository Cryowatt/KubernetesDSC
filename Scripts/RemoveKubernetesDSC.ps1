#Requires -Version 5
#Requires -Module PackageManagementProviderResource

Configuration RemoveDockerMsft
{
    param($Hostname = "localhost")
    New-Item Modules -ItemType Directory -Force
    Import-DSCResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName PackageManagementProviderResource

    Node $Hostname
    {
        Service docker
        {
            Name = "docker"
            Ensure = "Absent"
        }

        PSModule DockerMsftProvider
        {
            DependsOn = @("[Service]docker")
            Ensure = "Absent"
            Name = "DockerMsftProvider"
            Repository = "PSGallery"
        }
    }
}

RemoveDockerMsft
Start-DSCConfiguration .\RemoveDockerMsft -Wait -Force