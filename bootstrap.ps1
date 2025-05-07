# Windows 11 Initial Bootstrap (2025-05-07 19:38:35)
# Author: ms-86
# Repository: ms-86/win-dotfiles

# Exit immediately on any error (like set -e in bash)
$ErrorActionPreference = 'Stop'

function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-UserConfirmation {
    param(
        [string]$Message,
        [string]$YesText = "&Yes",
        [string]$NoText = "&No",
        [string]$DefaultChoice = "Y"
    )
    
    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new($YesText, "Proceed with the action.")
        [System.Management.Automation.Host.ChoiceDescription]::new($NoText, "Cancel the action.")
    )
    
    $defaultChoiceIndex = if ($DefaultChoice -eq "Y") { 0 } else { 1 }
    $result = $host.UI.PromptForChoice("Confirmation", $Message, $choices, $defaultChoiceIndex)
    
    return $result -eq 0
}

function Install-Chocolatey {
    param(
        [bool]$AdminMode,
        [string]$InstallDir = $null
    )

    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan

    if (-not $AdminMode -and $InstallDir) {
        # Set environment variable for non-admin install
        $env:ChocolateyInstall = $InstallDir
        [Environment]::SetEnvironmentVariable("ChocolateyInstall", $InstallDir, "User")
    }
    
    # Install Chocolatey
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "Chocolatey installed successfully at: $env:ChocolateyInstall" -ForegroundColor Green
}

function Install-Git {
    Write-Host "Installing Git..." -ForegroundColor Cyan
    
    if ($AdminMode) {
        Write-Host "Installing standard Git package (requires admin rights)..." -ForegroundColor Cyan
        & choco install git -y
    } else {
        Write-Host "Installing portable Git package (no admin rights required)..." -ForegroundColor Cyan
        & choco install git.portable -y
    }
    
    if ($LASTEXITCODE -ne 0) { throw "Git installation failed with exit code $LASTEXITCODE" }
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "Git installed successfully!" -ForegroundColor Green
}

# ===== Main Script =====

Write-Host "Starting Windows initial bootstrap..." -ForegroundColor Green

$currentPolicy = Get-ExecutionPolicy -Scope Process
if ($currentPolicy -ne 'RemoteSigned') {
    Write-Host "Setting execution policy to RemoteSigned for this process..." -ForegroundColor Cyan
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
}

$isAdmin = Test-Administrator

if ($isAdmin) {
    Write-Host "Administrator privileges detected." -ForegroundColor Cyan
    $confirmStandardInstall = Get-UserConfirmation "Would you like to proceed with standard installation of Chocolatey to C:\ProgramData\chocolatey?"
    
    if ($confirmStandardInstall) {
        Install-Chocolatey -AdminMode $true
    } else {
        Write-Host "Installation cancelled by user." -ForegroundColor Yellow
        exit
    }
} else {
    Write-Host "Running without administrator privileges." -ForegroundColor Yellow
    $confirmElevate = Get-UserConfirmation "Standard installation requires administrator privileges. Would you like to restart the script with elevated permissions? (Recommended)"
    
    if ($confirmElevate) {
        # Self-elevate the script
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`""
        exit
    } else {
        # User declined elevation, offer non-admin install
        $userInstallDir = Read-Host "Enter installation directory (default: $HOME\chocolatey)"
        if (-not $userInstallDir) {
            $userInstallDir = "$HOME\chocolatey"
        }
        
        $confirmDir = Get-UserConfirmation "Install Chocolatey to $($userInstallDir)?"
        if (-not $confirmDir) {
            exit 1
        }
        
        # Install Chocolatey in non-admin mode (custom location)
        Install-Chocolatey -AdminMode $false -InstallDir $userInstallDir
    }
}

$confirmGit = Get-UserConfirmation "Do you want to install Git?"
if ($confirmGit) {
    Install-Git
}

Write-Host "`nBootstrap complete!" -ForegroundColor Green
Write-Host "You now have Chocolatey and Git installed." -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Clone your repository:" -ForegroundColor Yellow
Write-Host "   git clone https://github.com/ms-86/win-dotfiles.git" -ForegroundColor Cyan
Write-Host "   cd win-dotfiles" -ForegroundColor Cyan
Write-Host "2. Run the setup script:" -ForegroundColor Yellow
Write-Host "   .\setup.ps1" -ForegroundColor Cyan
