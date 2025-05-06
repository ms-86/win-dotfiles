# Windows 11 Developer Environment Bootstrap
# Created: 2025-05-06
# Author: ms-86
# Repository: ms-86/win-dotfiles

# Ensure script execution is allowed
if ((Get-ExecutionPolicy) -gt 'RemoteSigned') {
    Write-Host "Setting ExecutionPolicy to RemoteSigned for this process only..."
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
}

Write-Host "Starting Windows developer environment setup..." -ForegroundColor Green

# Install Chocolatey
Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables to recognize choco
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
Write-Host "Chocolatey installed successfully!" -ForegroundColor Green

# Immediately install Git
Write-Host "Installing Git..." -ForegroundColor Cyan
choco install git -y

# Refresh environment variables to recognize git
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
Write-Host "Git installed successfully!" -ForegroundColor Green

Write-Host "Bootstrap setup complete!" -ForegroundColor Green
Write-Host "You now have Chocolatey and Git installed and can start cloning repositories." -ForegroundColor Green
Write-Host "To install additional tools, you can now use:" -ForegroundColor Yellow
Write-Host "  choco install <package-name> -y" -ForegroundColor Yellow
Write-Host "Example: choco install vscode -y" -ForegroundColor Yellow
Write-Host ""
Write-Host "You may need to restart your terminal for all changes to take effect." -ForegroundColor Yellow
