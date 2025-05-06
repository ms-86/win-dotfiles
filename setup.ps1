# Windows 11 Developer Environment Setup (2025-05-06)
# Author: ms-86
# Repository: ms-86/win-dotfiles

# Exit immediately on any error (like set -e in bash)
$ErrorActionPreference = 'Stop'

function Install-Tool {
    param([string]$Name)
    Write-Host "Installing $Name..." -ForegroundColor Cyan
    & choco install $Name -y
    if ($LASTEXITCODE -ne 0) { throw "$Name installation failed with exit code $LASTEXITCODE" }
}

Write-Host "Starting Windows development environment setup..." -ForegroundColor Green

# Verify Chocolatey is installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) { 
    throw "Chocolatey is not installed. Please run bootstrap.ps1 first." 
}

# Install tools
Install-Tool "vscode"
Install-Tool "slack"
Install-Tool "dbeaver"

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "`nSetup complete! All tools have been installed successfully.`n" -ForegroundColor Green
Write-Host "You may need to restart your terminal for all changes to take effect." -ForegroundColor Yellow
