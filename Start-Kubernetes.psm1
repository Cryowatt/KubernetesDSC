
<#PSScriptInfo

.VERSION 0.0.3

.GUID 0dc9be5e-07da-4c07-a4e1-341038c2e1ba

.AUTHOR Eric Carter

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


#>

#Requires -Module cChoco

<#

.DESCRIPTION
 Initiates a Kubernetes DSC configuration

#>

[cmdletbinding()]
param([string]$KubeConfig)

Configuration KubernetesWorkerConf
{
    param([ipaddress]$HostName)

    Import-DSCResource -ModuleName KubernetesDSC
    Import-DSCResource -ModuleName cChoco

    $chocoPath = "c:\ProgramData\chocolatey"
    $kubeConfigPath = "C:\kube\kubeconfig"

    Node Localhost
    {
        Service docker
        {
            Name = "docker"
            State = "Running"
        }
    
        WindowsFeature Routing
        {
            Name = "Routing"
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

        File kubeconfig
        {
            DestinationPath = $kubeConfigPath
            Contents = $KubeConfig
        }

        WindowsProcess kubelet
        {
            Arguments = "--kubeconfig $kubeConfigPath --require-kubeconfig --pod-infra-container-image='apprenda/pause' --hostname-override=$HostName"
            Path = [System.IO.Path]::Combine($chocoPath, "bin\kubelet.exe")   
            DependsOn = "[cChocoPackageInstaller]kubernetes-node", "[File]kubeconfig"
        }

        WindowsProcess kube-proxy
        {
            Arguments = "--kubeconfig $kubeConfigPath --hostname-override=$HostName --bind-address=$HostName --proxy-mode=userspace --v=3"
            Path = [System.IO.Path]::Combine($chocoPath, "bin\kube-proxy.exe")   
            DependsOn = "[cChocoPackageInstaller]kubernetes-node", "[File]kubeconfig"
        }
    }
}

KubernetesWorkerConf -HostName ([ipaddress] (Invoke-RestMethod http://169.254.169.254/latest/meta-data/local-ipv4))
Start-DSCConfiguration '.\KubernetesWorkerConf' -Wait -Force