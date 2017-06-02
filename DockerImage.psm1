#Requires -Module Docker

enum Ensure 
{ 
    Absent 
    Present 
}

[DscResource()]
class DockerImage {
    [DscProperty(Key)]
    [string] $Name
    
    [DscProperty()]
    [Ensure] $Ensure = [Ensure]::Present
    
    [DscProperty(NotConfigurable)]
    [datetime] $Created
    
    [DscProperty(NotConfigurable)]
    [string] $ID
    
    [DscProperty(NotConfigurable)]
    [string] $ParentID
    
    [DscProperty(NotConfigurable)]
    [string[]] $RepoDigests
    
    [DscProperty(NotConfigurable)]
    [string[]] $RepoTags
    
    [DscProperty(NotConfigurable)]
    [long] $Size
    
    [DscProperty(NotConfigurable)]
    [long] $VirtualSize

    [void] Set()
    {
        $container = Get-ContainerImage -ImageIdOrName $this.Name

        if ($this.ensure -eq [Ensure]::Present)
        {
            if($container -eq $null)
            {
                Pull-ContainerImage $this.Name
            }
        }
        else
        {
            if ($container -ne $null)
            {
                Remove-ContainerImage $this.Name
            }
        }
    }

    [bool] Test()
    {
        $container = Get-ContainerImage -ImageIdOrName $this.Name

        if ($this.Ensure -eq [Ensure]::Present)
        {
            return $container -ne $null
        }
        else
        {
            return $container -eq $null
        }
    }

    [DockerImage] Get()
    {
        $container = Get-ContainerImage -ImageIdOrName $this.Name

        if ($container -eq $null) 
        {
            $this.Created = $container.Created
            $this.ID = $container.ID
            $this.ParentID = $container.ParentID
            $this.RepoDigests = $container.RepoDigests
            $this.RepoTags = $container.RepoTags
            $this.Size = $container.Size
            $this.VirtualSize = $container.VirtualSize
        }


        <#$present = $this.TestFilePath($this.Path)

        if ($present)
        {
            $file = Get-ChildItem -LiteralPath $this.Path
            $this.CreationTime = $file.CreationTime
            $this.Ensure = [Ensure]::Present
        }
        else
        {
            $this.CreationTime = $null
            $this.Ensure = [Ensure]::Absent
        }#>

        return $this
    }
}