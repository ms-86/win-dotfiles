# Windows 11 Initial Bootstrap
# Created: 2025-05-06
# Author: ms-86
# Repository: ms-86/win-dotfiles

# Make sure script exits on first error
$ErrorActionPreference = 'Stop'

try {
    Write-Host "Starting Windows initial bootstrap..." -ForegroundColor Green

    # Ensure script execution is allowed
    if ((Get-ExecutionPolicy) -gt 'RemoteSigned') {
        Write-Host "Setting ExecutionPolicy to RemoteSigned for this process only..." -ForegroundColor Yellow
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
    }

    # Install Chocolatey
    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    # Refresh environment variables to recognize choco
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    # Install Git immediately
    Write-Host "Installing Git..." -ForegroundColor Cyan
    & choco install git -y
    if ($LASTEXITCODE -ne 0) { throw "Git installation failed with exit code $LASTEXITCODE" }

    # Refresh environment variables to recognize git
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Write-Host ""
    Write-Host "Bootstrap complete!" -ForegroundColor Green
    Write-Host "You now have Chocolatey and Git installed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Clone your repository:" -ForegroundColor Yellow
    Write-Host "   git clone https://github.com/ms-86/win-dotfiles.git" -ForegroundColor Cyan
    Write-Host "   cd win-dotfiles" -ForegroundColor Cyan
    Write-Host "2. Run the setup script:" -ForegroundColor Yellow
    Write-Host "   .\setup.ps1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You may need to restart your terminal for all Git commands to work properly." -ForegroundColor Yellow
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Bootstrap failed! Please fix the error and try again." -ForegroundColor Red
    exit 1
}
