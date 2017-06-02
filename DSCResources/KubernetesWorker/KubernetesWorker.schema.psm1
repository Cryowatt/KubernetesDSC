Configuration KubernetesWorker
{
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure
    )

    Import-DscResource –ModuleName KubernetesDSC

    WindowsContainers Containers {
        Ensure = $Ensure
    }
    
    WindowsFeature Routing {
        Name = "Routing"
        Ensure = $Ensure
    }

    # Import the module that defines custom resources Import-DSCResource -ModuleName PSDesiredStateConfiguration
    DockerImage Pause
    {
        Name = "apprenda/pause"
        Ensure = $Ensure
    }

}