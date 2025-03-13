#Requires -RunAsAdministrator
<#
.DESCRIPTION
    Configure the OSDCloudScriptsGUI PowerShell Module and start the OSDCloudScriptsGUI

.EXAMPLE
    Invoke-Expression (Invoke-WebRequest -Uri https://scripts.osdcloud.com)

.EXAMPLE
    iex (irm scripts.osdcloud.com)

.EXAMPLE
    iex (irm scripts.osdcloud.com)
    iex "& { $(irm scripts.osdcloud.com) } -Owner OSDeploy -Repo OSDCloudScripts"

.NOTES
    Author: David Segura
    Modified: 2023-09-28
#>
[CmdletBinding()]
param(
    [System.String] $Owner = 'OSDeploy',
    [System.String] $Repo = 'osdworkspace-scripts'
)
#=================================================
$Error.Clear()
Write-Verbose "[$((Get-Date).ToString('HH:mm:ss'))][$($MyInvocation.MyCommand)] Start"
#=================================================
# Script Information
$ScriptName = 'scripts.osdcloud.com'
$ScriptVersion = '25.3.13.1'
Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] $ScriptName version $ScriptVersion"
#=================================================
# Script Preferences
$ProgressPreference = 'SilentlyContinue'
#=================================================
# Execution Policy
$ExecutionPolicy = Get-ExecutionPolicy
if ($ExecutionPolicy -eq 'Restricted') {
    Write-Warning "[$(Get-Date -format G)] ExecutionPolicy is Restricted"
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
}
#=================================================
# Script Repository
$Repository = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo"

if ($Repository) {
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Found Git repository at $Owner/$Repo"
}
else {
    Write-Warning "[$(Get-Date -format G)] GitHub Repository $Owner/$Repo not found"
    Break
}
#=================================================
# Script Repository Download
# https://api.github.com/repos/$Owner/$Repo/zipball/REF
$ScriptRepoFileName = "$Repo.zip"
$ScriptRepoUrl = "https://github.com/$Owner/$Repo/archive/refs/heads/$($Repository.default_branch).zip"

$OutFile = Join-Path $env:TEMP $ScriptRepoFileName
# Remove existing Zip file
if (Test-Path $OutFile) {
    Remove-Item $OutFile -Force
}

# Download Zip file
Invoke-WebRequest -Uri $ScriptRepoUrl -OutFile $OutFile

if (Test-Path $OutFile) {
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Repo $Repo downloaded to $OutFile"
}
else {
    Write-Warning "[$(Get-Date -format G)] Repo $Repo could not be downloaded"
    Break
}
#=================================================
# Expand Zip file
$CurrentFile = Get-Item -Path $OutFile
$DestinationPath = Join-Path $CurrentFile.DirectoryName $CurrentFile.BaseName
if (Test-Path $DestinationPath) {
    Remove-Item $DestinationPath -Force -Recurse
}
Expand-Archive -Path $OutFile -DestinationPath $DestinationPath -Force
if (Test-Path $DestinationPath) {
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Repo $Repo expanded to $DestinationPath"
}
else {
    Write-Warning "[$(Get-Date -format G)] Repo $Repo could not be expanded to $DestinationPath"
    Break
}
#=================================================
# Set Scripts Path
$ScriptFiles = Get-ChildItem -Path $DestinationPath -Directory | Select-Object -First 1 -ExpandProperty FullName
if (Test-Path $ScriptFiles) {
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Repo $Repo is set to $ScriptFiles"
}
else {
    Write-Warning "[$(Get-Date -format G)] Repo $Repo could not be created at $ScriptFiles"
    Break
}
#=================================================
# Download GUI
$ScriptGuiFileName = 'OSDCloudScriptsGUI.zip'
$ScriptGuiUrl = 'https://github.com/OSDeploy/OSDCloudScriptsGUI/archive/refs/heads/main.zip'

$GUIOutFile = Join-Path $env:TEMP $ScriptGuiFileName
#=================================================
# Remove existing Zip file
if (Test-Path $GUIOutFile) {
    Remove-Item $GUIOutFile -Force
}
#=================================================
# Download Zip file
Invoke-WebRequest -Uri $ScriptGuiUrl -OutFile $GUIOutFile

if (Test-Path $GUIOutFile) {
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] OSDCloudScriptsGUI downloaded to $GUIOutFile"
}
else {
    Write-Warning "[$(Get-Date -format G)] OSDCloudScriptsGUI could not be downloaded"
    Break
}
#=================================================
# Expand Zip file
$CurrentFile = Get-Item -Path $GUIOutFile
$DestinationPath = Join-Path $CurrentFile.DirectoryName $CurrentFile.BaseName
if (Test-Path $DestinationPath) {
    Remove-Item $DestinationPath -Force -Recurse
}
Expand-Archive -Path $GUIOutFile -DestinationPath $DestinationPath -Force
if (Test-Path $DestinationPath) {
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] OSDCloudScriptsGUI expanded to $DestinationPath"
}
else {
    Write-Warning "[$(Get-Date -format G)] OSDCloudScriptsGUI could not be expanded to $DestinationPath"
    Break
}
#=================================================
# Set Excution Policy to RemoteSigned if $env:UserName is defaultuser0
if ($env:UserName -eq 'defaultuser0') {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Set-ExecutionPolicy to RemoteSigned for $env:UserName"
}
#=================================================
# Admin Check
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
#=================================================
# Load the frontend
if ($isAdmin) {
    $ModulePath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules\OSDCloudScriptsGUI"
    if (Test-Path $ModulePath) {
        Remove-Item $ModulePath -Recurse -Force
    }
    # Copy Module
    $SourceModuleRoot = Get-ChildItem -Path $DestinationPath -Directory | Select-Object -First 1 -ExpandProperty FullName
    Copy-Item -Path $SourceModuleRoot -Destination $ModulePath -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $ModulePath) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] OSDCloudScriptsGUI Module copied to $ModulePath"
    }
    else {
        Write-Warning "[$(Get-Date -format G)] OSDCloudScriptsGUI Module could not be copied to $ModulePath"
        Break
    }
    try {
        Import-Module $ModulePath -Force -ErrorAction Stop
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Import-Module $ModulePath -Force"
    }
    catch {
        Write-Warning "[$(Get-Date -format G)] Import-Module $ModulePath -Force"
        Write-Error $_.Exception.Message
        Break
    }
}
else {
    $ModulePath = "$env:TEMP\OSDCloudScriptsGUI\OSDCloudScriptsGUI-main\OSDCloudScriptsGUI.psm1"
    try {
        Import-Module $ModulePath -Force -ErrorAction Stop
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Import-Module $ModulePath -Force"
    }
    catch {
        Write-Warning "[$(Get-Date -format G)] Import-Module $ModulePath -Force"
        Write-Error $_.Exception.Message
        Break
    }
}
#=================================================
# Final Host Message
Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Start-OSDCloudScriptsGUI -Path $ScriptFiles"
if ($isAdmin) {
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)] To start a new PowerShell session, type 'start powershell' and press enter"
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)] Start-OSDCloudScriptsGUI can be run in the new PowerShell window"
}
#=================================================
# Launch
Start-OSDCloudScriptsGUI -Path $ScriptFiles
#=================================================