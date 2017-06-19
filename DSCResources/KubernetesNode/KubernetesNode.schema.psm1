Configuration KubernetesNode
{
    param(
        [string]$HostName,
        [ipaddress]$BindAddress,
        [string]$KubeConfig,
        [hashtable]$NodeLabels,
        [string]$CloudProvider
    )

    Import-DSCResource -ModuleName cChoco

    $chocoPath = "c:\ProgramData\chocolatey"
    $kubeConfigPath = "C:\kube\kubeconfig"
    $cloudProviderParam = "--cloud-provider=$CloudProvider"

    if($NodeLabels.Count > 0) {
        $nodeLabelsParam = '--node-labels=' + ($NodeLabels.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)"} ) -join ","
    }

    Service docker
    {
        Ensure = "Present"
        Name = "docker"
        State = "Running"
    }
    
    WindowsFeature Routing
    {
        Ensure = "Present"
        Name = "Routing"
    }

    DockerImage Pause
    {
        Ensure = "Present"
        Name = "apprenda/pause"
    }

    cChocoInstaller installChoco
    {
        InstallDir =  $chocoPath
    }

    cChocoPackageInstaller kubernetes-node
    {
        Ensure = "Present"
        Name = "kubernetes-node"
        DependsOn = "[cChocoInstaller]installChoco"
        Version = "1.5.7"
    }

    File kubeconfig
    {
        Ensure = "Present"
        DestinationPath = $kubeConfigPath
        Contents = $KubeConfig
    }

    WindowsProcess kubelet
    {
        Ensure = "Present"
        Arguments = "--kubeconfig $kubeConfigPath --require-kubeconfig --pod-infra-container-image='apprenda/pause' --hostname-override=$HostName $nodeLabelsParam $cloudProviderParam"
        Path = [System.IO.Path]::Combine($chocoPath, "bin\kubelet.exe")
        DependsOn = "[cChocoPackageInstaller]kubernetes-node", "[File]kubeconfig"
    }

    WindowsProcess kube-proxy
    {
        Ensure = "Present"
        Arguments = "--kubeconfig $kubeConfigPath --hostname-override=$HostName --bind-address=$BindAddress --proxy-mode=userspace --v=3"
        Path = [System.IO.Path]::Combine($chocoPath, "bin\kube-proxy.exe")
        DependsOn = "[cChocoPackageInstaller]kubernetes-node", "[File]kubeconfig"
    }
}