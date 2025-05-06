# Windows 11 Initial Bootstrap (2025-05-06)
# Author: ms-86
# Repository: ms-86/win-dotfiles

# Exit immediately on any error (like set -e in bash)
$ErrorActionPreference = 'Stop'

function Invoke-CommandWithCheck {
    param([string]$Message, [scriptblock]$Command)
    Write-Host $Message -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "Command failed with exit code $LASTEXITCODE" }
}

Write-Host "Starting Windows initial bootstrap..." -ForegroundColor Green

# Set execution policy
if ((Get-ExecutionPolicy) -gt 'RemoteSigned') {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
}

# Install Chocolatey
Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install Git
Invoke-CommandWithCheck "Installing Git..." { choco install git -y }
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Host "`nBootstrap complete! You now have Chocolatey and Git installed.`n" -ForegroundColor Green
Write-Host "Next steps:`n1. Clone your repository:`n   git clone https://github.com/ms-86/win-dotfiles.git`n   cd win-dotfiles`n2. Run setup.ps1" -ForegroundColor Yellow
