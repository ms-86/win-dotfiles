# Windows 11 Developer Environment Bootstrap
# Created: 2025-05-06
# Author: ms-86

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

# Install Git
# Write-Host "Installing Git..." -ForegroundColor Cyan
# choco install git -y

# Install VS Code (optional)
# Write-Host "Installing Visual Studio Code..." -ForegroundColor Cyan
# choco install vscode -y

# Install other essential tools
# Uncomment or add tools you need
# choco install nodejs -y
# choco install python -y
# choco install microsoft-windows-terminal -y

# Clone your repository (optional)
# $repoUrl = "https://github.com/yourusername/yourrepository.git"
# $repoPath = "$HOME\Projects\yourrepository"
# Write-Host "Cloning your repository to $repoPath..." -ForegroundColor Cyan
# git clone $repoUrl $repoPath

Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "You may need to restart your terminal for all changes to take effect." -ForegroundColor Yellow
