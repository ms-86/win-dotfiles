# Windows 11 Initial Bootstrap (2025-05-07 12:58:54)
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
        [string]$DefaultChoice = "Y"
    )
    
    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Proceed with the action.")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Cancel the action.")
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
    
    # Set up environment for Chocolatey installation
    $env:ChocolateyInstall = $InstallDir
    
    if (-not $AdminMode -and $InstallDir) {
        # Create install directory if it doesn't exist
        if (-not (Test-Path $InstallDir)) {
            New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
        }
        
        # Set environment variable for non-admin install
        [Environment]::SetEnvironmentVariable("ChocolateyInstall", $InstallDir, "User")
    }
    
    # Install Chocolatey
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "Chocolatey installed successfully at: $env:ChocolateyInstall" -ForegroundColor Green
}

# Function to install Git
function Install-Git {
    Write-Host "Installing Git..." -ForegroundColor Cyan
    & choco install git -y
    if ($LASTEXITCODE -ne 0) { throw "Git installation failed with exit code $LASTEXITCODE" }
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "Git installed successfully!" -ForegroundColor Green
}

# ===== Main Script Execution Starts Here =====

Write-Host "Starting Windows initial bootstrap..." -ForegroundColor Green

# Set execution policy for this process
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

# Detect if running as Administrator
$isAdmin = Test-Administrator
if ($isAdmin) {
    Write-Host "Currently running with administrator privileges." -ForegroundColor Cyan
} else {
    Write-Host "Currently running without administrator privileges." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Chocolatey Installation Options:" -ForegroundColor Magenta
Write-Host "1) Standard installation with administrator privileges (recommended for most users)" -ForegroundColor White
Write-Host "   - Installs to C:\ProgramData\chocolatey" -ForegroundColor Gray
Write-Host "   - Allows system-wide package management" -ForegroundColor Gray
Write-Host ""
Write-Host "2) User-specific installation without administrator privileges" -ForegroundColor White
Write-Host "   - Installs to $HOME\chocolatey" -ForegroundColor Gray
Write-Host "   - Limited to current user only" -ForegroundColor Gray
Write-Host "   - Some packages may not work properly" -ForegroundColor Gray
Write-Host ""

$installChoice = Read-Host "Choose installation type (1 or 2)"

# Process the choice
switch ($installChoice) {
    "1" {
        # Admin installation selected
        if (-not $isAdmin) {
            $confirmElevate = Get-UserConfirmation "Administrator privileges are required for standard installation. Do you want to restart the script with elevated permissions?"
            if ($confirmElevate) {
                # Self-elevate the script
                $scriptPath = $MyInvocation.MyCommand.Path
                Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`""
                exit
            } else {
                Write-Host "Cannot proceed with standard installation without administrator privileges." -ForegroundColor Red
                exit 1
            }
        } else {
            $confirmInstall = Get-UserConfirmation "Proceed with standard Chocolatey installation to C:\ProgramData\chocolatey?"
            if (-not $confirmInstall) {
                Write-Host "Installation cancelled by user." -ForegroundColor Yellow
                exit
            }
            
            # Install Chocolatey in admin mode (default location)
            Install-Chocolatey -AdminMode $true
        }
    }
    "2" {
        # Non-admin installation selected
        $userInstallDir = "$HOME\chocolatey"
        $confirmDir = Get-UserConfirmation "Install Chocolatey to $userInstallDir?"
        if (-not $confirmDir) {
            $userInstallDir = Read-Host "Enter custom installation directory"
            if (-not $userInstallDir) {
                Write-Host "Installation cancelled: No directory specified" -ForegroundColor Red
                exit 1
            }
        }
        
        # Install Chocolatey in non-admin mode (custom location)
        Install-Chocolatey -AdminMode $false -InstallDir $userInstallDir
    }
    default {
        Write-Host "Invalid choice. Exiting." -ForegroundColor Red
        exit 1
    }
}

# After Chocolatey is installed, install Git
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
