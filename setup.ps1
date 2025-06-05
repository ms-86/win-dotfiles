# Windows 11 Developer Environment Setup (2025-05-07 22:02:30)
# Author: ms-86
# Repository: ms-86/win-dotfiles

param (
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile,
    [switch]$UpgradeUnpinned,
    [switch]$DebugMode
)

Write-Host "Script is starting to load..." -ForegroundColor Cyan

# Exit immediately on any error (like set -e in bash)
$ErrorActionPreference = 'Stop'

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Print-NewVersionMsg {
    param($msg, $isPinned)
    if ($isPinned) {
        Write-Host $msg -ForegroundColor Magenta
    } else {
        Write-Host $msg -ForegroundColor Yellow
    }
}

function Print-InstallMsg {
    param($msg, $color)
    Write-Host $msg -ForegroundColor $color
}

function Handle-NotInstalled {
    param(
        $toolToCheck,
        $installArgs,
        $targetVersion,
        $toolStatus
    )
    & choco install @installArgs | Out-Null
    $result = Handle-ChocoCommandResult $toolToCheck 'install' $targetVersion $toolStatus.pinned
    
    # Preserve the toolStatus.newerVersionAvailable in case it's already known
    $result.newer = $result.newer -or $toolStatus.newerVersionAvailable
    
    return $result
}

function Handle-VersionSpecified {
    param(
        $toolToCheck,
        $Version,
        $installArgs,
        $toolStatus
    )
    if ($toolStatus.installedVersion -ne $Version) {
        return (Invoke-InstallOrUpgrade $toolToCheck $installArgs $Version $toolStatus.pinned)
    }
    
    if ($toolStatus.newerVersionAvailable -and $Version -ne $toolStatus.latestVersion) {
        $statusText = if ($toolStatus.pinned) { 'PINNED' } else { 'installed' }
        $msg = "[NEW VERSION] $toolToCheck $Version is $statusText. [$($toolStatus.latestVersion) available]"
        Print-NewVersionMsg $msg $toolStatus.pinned
    } else {
        Write-Host "[SKIPPED] $toolToCheck $Version is up to date."
    }
    
    return @{
        result = 'skipped'
        newer = $toolStatus.newerVersionAvailable
        pinned = $toolStatus.pinned
    }
}

function Handle-Installed {
    param(
        $toolToCheck,
        $UpgradeUnpinned,
        $toolStatus
    )
    if (-not $toolStatus.newerVersionAvailable) {
        Write-Host "[SKIPPED] $toolToCheck $($toolStatus.installedVersion) is up to date."
        return @{
            result = 'skipped'
            newer = $false
            pinned = $false
        }
    }
    
    if ($toolStatus.pinned) {
        $msg = "[NEW VERSION] $toolToCheck $($toolStatus.installedVersion) is PINNED. "
        $msg += "[$($toolStatus.latestVersion) available]"
        Print-NewVersionMsg $msg $true
        
        return @{
            result = 'skipped'
            newer = $true
            pinned = $toolStatus.pinned
        }
    }
      if ($UpgradeUnpinned) {
        return (Invoke-InstallOrUpgrade 
            $toolToCheck 
            @($toolToCheck, '-y') 
            $toolStatus.latestVersion 
            $false 
            $true 
            $toolStatus.installedVersion
        )
    }
    
    $msg = "[NEW VERSION] $toolToCheck $($toolStatus.installedVersion) is installed. "
    $msg += "[$($toolStatus.latestVersion) available]"
    Print-NewVersionMsg $msg $false
    
    return @{
        result = 'skipped'
        newer = $true
        pinned = $toolStatus.pinned
    }
}

function Parse-ChocoOutdatedLine {
    param(
        [string]$line
    )
    $fields = $line -split '\|'
    $result = @{}
    
    if ($fields.Count -ge 1) {
        $result.PackageName = $fields[0].Trim()
    }
    
    if ($fields.Count -ge 2) {
        $result.InstalledVersion = $fields[1].Trim()
    }
    
    if ($fields.Count -ge 3) {
        $result.LatestVersion = $fields[2].Trim()
    }
    
    # Set pinned status to false by default and only true if explicitly marked as 'true'
    $result.Pinned = $false
    if ($fields.Count -ge 4) {
        $result.Pinned = ($fields[3].Trim().ToLower() -eq 'true')
    }
    
    return $result
}

function Get-ChocoOutdated {
    $outdatedCache = @{}
    $outdated = choco outdated -r
    foreach ($line in $outdated) {
        if ($line -match '^([^\|]+)\|') {
            $parsed = Parse-ChocoOutdatedLine $line
            $packageName = $parsed.PackageName
            if ($packageName) {
                $outdatedCache[$packageName] = $parsed
            }
        }
    }
    return $outdatedCache
}

function Get-ToolStatus {
    param(
        [string]$toolName,
        $outdatedCache = $null
    )
    $installed = $false
    $installedVersion = $null
    $pinned = $false
    $newerVersionAvailable = $false
    $latestVersion = $null

    # Check if installed
    $listResult = choco list --exact $toolName | Select-String "^$toolName "
    if ($listResult) {
        $installed = $true
        $installedVersion = ($listResult -split ' ')[1]
    }

    # Check if pinned
    $pinResult = choco pin list | Select-String "^$toolName "
    if ($pinResult) {
        $pinned = $true
    }

    # Check for newer version using the outdated cache
    if (-not $outdatedCache) {
        $outdatedCache = Get-ChocoOutdated
    }    if ($outdatedCache.ContainsKey($toolName)) {
        $latestVersion = $outdatedCache[$toolName].LatestVersion
        $newerVersionAvailable = $true
        
        # Only override pinned status from outdated cache if it's explicitly set to true
        # This allows the pin list check above to take precedence
        if ($outdatedCache[$toolName].Pinned -eq $true) {
            $pinned = $true
        }
    }elseif ($installed) {
        $latestResult = choco info $toolName | Select-String "^Latest Version: "
        if ($latestResult) {
            $latestVersion = ($latestResult -split ': ')[1].Trim()
        } else {
            $latestVersion = $installedVersion
        }
    }

    return @{
        installed = $installed
        installedVersion = $installedVersion
        pinned = $pinned
        newerVersionAvailable = $newerVersionAvailable
        latestVersion = $latestVersion
    }
}

function Install-Tool {
    param(
        [string]$Name,
        [string]$PortableName = "",
        [bool]$RequiresAdmin = $true,
        [string]$Version = "",
        [switch]$UpgradeUnpinned,
        $outdatedCache = $null
    )
    $isAdmin = Test-Admin
    
    $toolToCheck = if (-not $isAdmin -and $PortableName) { $PortableName } else { $Name }
    $installArgs = @($toolToCheck, '-y')
    
    if ($Version) {
        $installArgs += @('--version', $Version)
    }
    
    $toolStatus = Get-ToolStatus $toolToCheck $outdatedCache
    $targetVersion = if ($Version) { $Version } else { "latest" }
    
    if (-not $toolStatus.installed) {
        return Handle-NotInstalled $toolToCheck $installArgs $targetVersion $toolStatus
    }
    
    if ($Version) {
        return Handle-VersionSpecified $toolToCheck $Version $installArgs $toolStatus
    }
    
    return Handle-Installed $toolToCheck $UpgradeUnpinned $toolStatus
}

function Handle-ChocoCommandResult {
    param(
        $toolToCheck,
        $actionName,
        $version,
        $pinned,
        $fromVersion = ""
    )
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAILED] $toolToCheck $actionName failed with exit code $LASTEXITCODE" -ForegroundColor Red
        return @{
            result = 'failed'
            newer = ($actionName -eq 'upgrade')
            pinned = $pinned
        }
    }
    
    if ($actionName -eq 'upgrade') {
        $msg = "[UPGRADED] $toolToCheck $version upgraded from $fromVersion."
        Write-Host $msg -ForegroundColor Green
        return @{
            result = 'upgraded'
            newer = $false
            pinned = $pinned
        }
    }
    
    # For installations, check if a newer version is available
    $outdatedCache = Get-ChocoOutdated
    if ($outdatedCache.ContainsKey($toolToCheck)) {
        $latestVersion = $outdatedCache[$toolToCheck].LatestVersion
        $pinned = $outdatedCache[$toolToCheck].Pinned
        
        $msg = "[INSTALLED] $toolToCheck $version installed. [NEW VERSION: $latestVersion available"
        $msg += if ($pinned) { ', PINNED' } else { '' }
        $msg += "]"
        
        Print-NewVersionMsg $msg $pinned
        
        return @{
            result = 'installed'
            newer = $true
            pinned = $pinned
        }
    }
    
    Write-Host "[INSTALLED] $toolToCheck $version installed." -ForegroundColor Green
    
    return @{
        result = 'installed'
        newer = $false
        pinned = $pinned
    }
}

function Invoke-InstallOrUpgrade {
    param(
        $toolToCheck, $args, $version, $pinned, $isUpgrade = $false, $fromVersion = ""
    )
    if ($isUpgrade) {
        & choco upgrade $toolToCheck -y | Out-Null
        return (Handle-ChocoCommandResult $toolToCheck 'upgrade' $version $pinned $fromVersion)
    }

    & choco install @args | Out-Null
    return (Handle-ChocoCommandResult $toolToCheck 'install' $version $pinned)
}

function Load-ToolsConfig {
    param (
        [string]$ConfigPath
    )
    
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found at '$ConfigPath'"
    }
    
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        throw "Failed to parse configuration file: $_"
    }
}

# Main script execution logic
# A more reliable way to determine if the script is being run directly vs. dot-sourced
if (-not $MyInvocation.line.Contains('. ')) {
    Write-Host "Main script execution started" -ForegroundColor Cyan
    if ($DebugMode) {
        Write-Host "Debug information: " -ForegroundColor Cyan
        Write-Host "MyInvocation.line: $($MyInvocation.line)" -ForegroundColor DarkCyan
        Write-Host "ThisScript: $($MyInvocation.MyCommand.Name)" -ForegroundColor DarkCyan
    }
    
    Write-Host "Starting Windows development environment setup..." -ForegroundColor Green

    # Verify Chocolatey is installed
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) { 
        throw "Chocolatey is not installed. Please run bootstrap.ps1 first." 
    }    # Check if running as admin
    $isAdmin = Test-Admin
    if (-not $isAdmin) {
        $warningMsg = "Warning: Running without administrator privileges. "
        $warningMsg += "Some installations will be skipped or use portable versions."
        Write-Host $warningMsg -ForegroundColor Yellow
    }# Determine configuration file path
    if (-not $ConfigFile) {
        # Try to find config file in script directory
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $defaultPath = Join-Path -Path $scriptDir -ChildPath "tools.json"
        
        if (Test-Path $defaultPath) {
            $ConfigFile = $defaultPath
        } else {
            # Try current directory as fallback
            $currentDirPath = Join-Path -Path (Get-Location) -ChildPath "tools.json"
            
            if (Test-Path $currentDirPath) {
                $ConfigFile = $currentDirPath
            } else {
                $errorMsg = "No tools.json configuration file found. "
                $errorMsg += "Please specify a path using -ConfigFile parameter."
                throw $errorMsg
            }
        }
    }

    Write-Host "Using configuration from: $ConfigFile" -ForegroundColor Cyan

    # Load tools configuration
    $toolsConfig = Load-ToolsConfig -ConfigPath $ConfigFile

    # Get initial outdated packages info
    $outdatedCache = Get-ChocoOutdated    # Install each tool from the configuration
    $successful = 0
    $skipped = 0
    $failed = 0
    $upgraded = 0
    $newerAvailable = 0
    
    foreach ($tool in $toolsConfig.tools) {
        $portableName = if ($tool.portableName) { $tool.portableName } else { "" }
        $requiresAdmin = if ($null -eq $tool.requiresAdmin) { $true } else { $tool.requiresAdmin }
        $version = if ($tool.version) { $tool.version } else { "" }
        
        $resultObj = Install-Tool -Name $tool.name `
                                 -PortableName $portableName `
                                 -RequiresAdmin $requiresAdmin `
                                 -Version $version `
                                 -UpgradeUnpinned:$UpgradeUnpinned `
                                 -outdatedCache $outdatedCache
                                 
        switch ($resultObj.result) {
            'installed' { $successful++ }
            'skipped'   { $skipped++ }
            'failed'    { $failed++ }
            'upgraded'  { $upgraded++ }
        }
        
        if ($resultObj.newer) { 
            $newerAvailable++ 
        }
    }

    # Update PATH to include newly installed tools
    $machinePathVar = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPathVar = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = $machinePathVar + ";" + $userPathVar    # Display results
    Write-Host "`nSetup complete!" -ForegroundColor Green
    Write-Host "Results: $successful installed, $upgraded upgraded, $skipped skipped, $failed failed." `
              -ForegroundColor Green
              
    if ($newerAvailable -gt 0) {
        $msg = "$newerAvailable tools have newer versions available "
        $msg += "(see [NEW VERSION] messages above)."
        Write-Host $msg -ForegroundColor Yellow
    }
    
    if ($skipped -gt 0) {
        $msg = "$skipped tools skipped (already up to date or requested version)"
        Write-Host $msg -ForegroundColor Yellow
    }
    
    if ($failed -gt 0) {
        Write-Host "$failed tools failed to install" -ForegroundColor Red
    }
    
    if (-not $isAdmin -and $skipped -gt 0) {
        $msg = "`nRun this script as administrator to install all tools."
        Write-Host $msg -ForegroundColor Yellow
    }
    
    $msg = "`nYou may need to restart your terminal for all changes to take effect."
    Write-Host $msg -ForegroundColor Yellow
}

function Test-Function {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FunctionName,
        [Parameter(ValueFromRemainingArguments=$true)]
        $Arguments
    )
    
    switch ($FunctionName) {
        "Get-ToolStatus" {
            if ($Arguments.Count -eq 0) {
                Write-Host "Usage: Test-Function Get-ToolStatus <packageName>"
                return
            }
            $result = Get-ToolStatus -toolName $Arguments[0]
            return $result | Format-Table
        }
        "Get-ChocoOutdated" {
            return Get-ChocoOutdated | Format-Table
        }
        default {
            Write-Host "Unknown function: $FunctionName"
            Write-Host "Available functions: Get-ToolStatus, Get-ChocoOutdated"
        }
    }
}

<#+
.SYNOPSIS
    Windows 11 Developer Environment Setup Script

.DESCRIPTION
    Installs developer tools using Chocolatey based on a configuration file (tools.json).
    Each tool can optionally specify a version. If no version is specified, the latest version is installed.
    
    tools.json example:
    {
        "tools": [
            { "name": "git" },
            { "name": "nodejs", "version": "20.11.1" },
            { "name": "python", "portableName": "python.portable", "requiresAdmin": false }
        ]
    }

.PARAMETER ConfigFile
    Path to the tools.json configuration file. If not specified, the script will look for tools.json in the script directory or current directory.

.PARAMETER UpgradeUnpinned
    If specified, unpinned packages with new versions will be upgraded. Pinned packages will only show a message.

.NOTES
    - If a version is specified for a tool, that version will be installed using Chocolatey's --version argument.
    - If no version is specified, the latest version will be installed.
#>
