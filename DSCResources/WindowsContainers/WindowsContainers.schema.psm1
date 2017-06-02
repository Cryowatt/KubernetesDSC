Configuration WindowsContainers
{
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure
    )

    # Import the module that defines custom resources Import-DSCResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName PackageManagementProviderResource
    Import-DscResource –ModuleName PSDesiredStateConfiguration

    PackageManagementSource PSGallery
    {
        Name = "PSGallery"
        Ensure = $Ensure
        ProviderName = "PowerShellGet"
        InstallationPolicy = "Trusted"
        SourceUri = "https://www.powershellgallery.com/api/v2/"
    }

    PSModule DockerMsftProvider
    {
        DependsOn = @("[PackageManagementSource]PSGallery")
        Ensure = $Ensure
        Name = "DockerMsftProvider"
        Repository = "PSGallery"
        InstallationPolicy = "Trusted"
    }

    PackageManagementSource DockerPS
    {
        Name = "DockerPS-Dev"
        Ensure = $Ensure
        ProviderName = "PowerShellGet"
        InstallationPolicy = "Trusted"
        SourceUri = "https://ci.appveyor.com/nuget/docker-powershell-dev"
    }

    PSModule DockerPS
    {
        DependsOn = @("[PackageManagementSource]DockerPS")
        Ensure = $Ensure
        Name = "Docker"
        Repository = "DockerPS-Dev"
        InstallationPolicy = "Trusted"
    }

    PackageManagement docker {
        DependsOn = @("[PSModule]DockerMsftProvider")
        Name = "docker"
        Ensure = $Ensure
        ProviderName = "DockerMsftProvider"
    }

    Service docker
    {
        DependsOn = @("[PackageManagement]docker")
        Name = "docker"
        Ensure = $Ensure        
        State = "Running"
    }
}