#Requires -Version 5
param($Ensure = "Present")

Configuration KubernetesWorkerConf
{
    param([ipaddress]$HostName, $Ensure = "Present")

    # Import the module that defines custom resources Import-DSCResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName PackageManagementProviderResource
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    Import-DscResource –ModuleName xPSDesiredStateConfiguration
    Import-DscResource –ModuleName xHyper-V
    Import-DSCResource -ModuleName KubernetesDSC
    Import-DSCResource -ModuleName cChoco

    $chocoPath = "c:\ProgramData\chocolatey"

    Node Localhost
    {
        PackageManagementSource PSGallery
        {
            Name = "PSGallery"
            ProviderName = "PowerShellGet"
            InstallationPolicy = "Trusted"
            SourceUri = "https://www.powershellgallery.com/api/v2/"
        }

        PSModule DockerMsftProvider
        {
            DependsOn = @("[PackageManagementSource]PSGallery")
            Name = "DockerMsftProvider"
            Repository = "PSGallery"
            InstallationPolicy = "Trusted"
        }

        PackageManagementSource DockerPS
        {
            Name = "DockerPS-Dev"
            ProviderName = "PowerShellGet"
            InstallationPolicy = "Trusted"
            SourceUri = "https://ci.appveyor.com/nuget/docker-powershell-dev"
        }

        PSModule DockerPS
        {
            DependsOn = @("[PackageManagementSource]DockerPS")
            Name = "Docker"
            Repository = "DockerPS-Dev"
            InstallationPolicy = "Trusted"
        }

        PackageManagement docker
        {
            DependsOn = @("[PSModule]DockerMsftProvider")
            Name = "docker"
            ProviderName = "DockerMsftProvider"
        }

        Service docker
        {
            DependsOn = @("[PackageManagement]docker")
            Name = "docker"
            State = "Running"
        }
    
        WindowsFeature Routing
        {
            Name = "Routing"
        }

        xVMSwitch KubeProxySwitch
        {
            Name = "KubeProxySwitch"
            Type = "Internal"
        }

        DockerImage Pause
        {
            Name = "apprenda/pause"
        }

        cChocoInstaller installChoco
        {
            InstallDir =  $chocoPath          
        }

        cChocoPackageInstaller kubernetes-node
        {
            Name = "kubernetes-node"
            DependsOn = "[cChocoInstaller]installChoco"
            Version = "1.5.7"
        }

        WindowsProcess kubelet
        {
            Arguments = "--kubeconfig C:\kubernetes\buildlab.ims.io\kubeconfig --require-kubeconfig --pod-infra-container-image='apprenda/pause' --hostname-override=$HostName"
            Path = [System.IO.Path]::Combine($chocoPath, "bin\kubelet.exe")   
            Ensure = "Present"
            DependsOn = "[cChocoPackageInstaller]kubernetes-node"
        }

        WindowsProcess kube-proxy
        {
            Arguments = "--kubeconfig C:\kubernetes\buildlab.ims.io\kubeconfig --hostname-override=$HostName --bind-address=$HostName --proxy-mode=userspace --v=3"
            Path = [System.IO.Path]::Combine($chocoPath, "bin\kube-proxy.exe")   
            Ensure = "Present"
            DependsOn = "[cChocoPackageInstaller]kubernetes-node"
        }
    }
}

KubernetesWorkerConf -HostName ([ipaddress] (Invoke-RestMethod http://169.254.169.254/latest/meta-data/local-ipv4))
Start-DSCConfiguration '.\KubernetesWorkerConf' -Wait -Force