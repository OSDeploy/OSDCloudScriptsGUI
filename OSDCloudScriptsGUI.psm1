function Start-OSDCloudScriptsGUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]$Path = "$env:Temp\OSDCloudScripts\OSDCloudScripts-main"
    )
    #================================================
    #   Set Global Variables
    #================================================
    $Global:OSDPadBranding = @{
        Title = 'OSDCloudScriptsGUI'
        Color = '#024AD8'
    }
    #=================================================
    #   Parameters
    #=================================================
    $ScriptFiles = Get-ChildItem -Path $Path -Recurse -File
    $ScriptFiles = $ScriptFiles | Where-Object {$_.Name -notlike '.git*'}
    if ($env:SystemDrive -eq 'X:') {
        #$ScriptFiles = $ScriptFiles | Where-Object {($_.Directory -eq (Resolve-Path $Path)) -or ($_.Directory -match 'WinPE') -or ($_.Directory -match 'Alpha')} 
    }
    #$ScriptFiles = $ScriptFiles | Where-Object {($_.Name -match '.ps1') -or ($_.Name -match '.md') -or ($_.Name -match '.json')}
    #=================================================
    #   Create Object
    #=================================================
    $Global:OSDCloudScriptsGUI = foreach ($Item in $ScriptFiles) {
        $FullName = $Item.FullName
        $DirectoryName = $Item.DirectoryName
        $RelativePath = $Item.FullName -replace [regex]::Escape("$Path\"), ''

        if ($DirectoryName -eq $Path) {
            $Category = ''
            $Script = $RelativePath
        }
        else {
            $Category = $Item.DirectoryName -replace [regex]::Escape("$Path\"), ''
            $Script = $RelativePath
        }

        # Category is the first part of the path
        # $Category = $RelativePath.Split('\')[0]
        # $Category = $RelativePath.Split('\')[0..1] -join '\'

        $ObjectProperties = [ordered]@{
            Category = $Category
            Script = $Script
            Content = Get-Content -Path $Item.FullName -Raw -Encoding utf8
            DirectoryName = $DirectoryName
            RelativePath = $RelativePath
            Name = $Item.Name
            FullName = $FullName
            LocalRepository = $Path
        }
        New-Object -TypeName PSObject -Property $ObjectProperties
    }
    #=================================================
    #   OSDCloudScriptsGUI.ps1
    #=================================================
    & "$($MyInvocation.MyCommand.Module.ModuleBase)\Project\MainWindow.ps1"
    #=================================================
}
Export-ModuleMember -Function Start-OSDCloudScriptsGUI