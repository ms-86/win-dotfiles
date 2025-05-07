# Windows 11 Developer Environment Setup (2025-05-07 21:58:23)
# Author: ms-86
# Repository: ms-86/win-dotfiles

# Exit immediately on any error (like set -e in bash)
$ErrorActionPreference = 'Stop'

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Tool {
    param(
        [string]$Name,
        [string]$PortableName = "",
        [bool]$RequiresAdmin = $true
    )
    
    $isAdmin = Test-Admin
    
    if (-not $isAdmin -and $PortableName) {
        Write-Host "Installing $PortableName (portable version)..." -ForegroundColor Cyan
        & choco install $PortableName -y
        if ($LASTEXITCODE -ne 0) { 
            Write-Host "$PortableName installation failed with exit code $LASTEXITCODE" -ForegroundColor Red
            return $false
        }
        return $true
    }
    elseif (-not $isAdmin -and $RequiresAdmin) {
        Write-Host "Skipping $Name - requires administrator privileges" -ForegroundColor Yellow
        return $false
    }
    else {
        Write-Host "Installing $Name..." -ForegroundColor Cyan
        & choco install $Name -y
        if ($LASTEXITCODE -ne 0) { 
            Write-Host "$Name installation failed with exit code $LASTEXITCODE" -ForegroundColor Red
            return $false
        }
        return $true
    }
}

function Load-ToolsConfig {
    param (
        [string]$ConfigPath = "tools.json"
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

Write-Host "Starting Windows development environment setup..." -ForegroundColor Green

# Verify Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) { 
    throw "Chocolatey is not installed. Please run bootstrap.ps1 first." 
}

# Check if running as admin
$isAdmin = Test-Admin
if (-not $isAdmin) {
    Write-Host "Warning: Running without administrator privileges. Some installations will be skipped or use portable versions." -ForegroundColor Yellow
}

# Define configuration file path
$configFile = Join-Path -Path $PSScriptRoot -ChildPath "tools.json"
if (-not (Test-Path $configFile)) {
    $configFile = "tools.json"  # Fallback to current directory
}

# Load tools configuration
$toolsConfig = Load-ToolsConfig -ConfigPath $configFile

$successful = 0
$skipped = 0
$failed = 0

# Install each tool from the configuration
foreach ($tool in $toolsConfig.tools) {
    $portableName = if ($tool.portableName) { $tool.portableName } else { "" }
    $requiresAdmin = if ($null -eq $tool.requiresAdmin) { $true } else { $tool.requiresAdmin }
    
    $result = Install-Tool -Name $tool.name -PortableName $portableName -RequiresAdmin $requiresAdmin
    
    if ($result) {
        $successful++
    }
    elseif (-not $isAdmin -and $requiresAdmin) {
        $skipped++
    }
    else {
        $failed++
    }
}

# Update PATH to include newly installed tools
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Display results
Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "Results: $successful tools installed successfully" -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Host "$skipped tools skipped (requires administrator privileges)" -ForegroundColor Yellow
}
if ($failed -gt 0) {
    Write-Host "$failed tools failed to install" -ForegroundColor Red
}

if (-not $isAdmin -and $skipped -gt 0) {
    Write-Host "`nRun this script as administrator to install all tools." -ForegroundColor Yellow
}
Write-Host "`nYou may need to restart your terminal for all changes to take effect." -ForegroundColor Yellow
