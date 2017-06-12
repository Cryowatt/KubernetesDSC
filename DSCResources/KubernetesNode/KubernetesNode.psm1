Configuration KubernetesNode
{
    param(
        [ipaddress]$HostName,
        [string]$KubeConfig)
    )

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