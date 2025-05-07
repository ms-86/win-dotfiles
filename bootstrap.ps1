# Windows 11 Initial Bootstrap (2025-05-07 22:20:23)
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
    param(
        [bool]$AdminMode
    )
    
    Write-Host "Installing Git..." -ForegroundColor Cyan
    Write-Host "Admin mode: $AdminMode" -ForegroundColor Magenta  # Debug output
    
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

# Get script path to use for elevation if needed
$scriptPath = $MyInvocation.MyCommand.Path

# Check if the script was run with elevated flag
$elevated = $false
if ($args -contains "-Elevated") {
    $elevated = $true
    # Remove -Elevated from args if present to avoid issues with subsequent parsing
    $args = $args | Where-Object { $_ -ne "-Elevated" }
}

# ===== Main Script =====

Write-Host "Starting Windows initial bootstrap..." -ForegroundColor Green

$currentPolicy = Get-ExecutionPolicy -Scope Process
if ($currentPolicy -ne 'RemoteSigned') {
    Write-Host "Setting execution policy to RemoteSigned for this process..." -ForegroundColor Cyan
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
}

$isAdmin = Test-Administrator
Write-Host "Running as administrator: $isAdmin" -ForegroundColor Magenta  # Debug output

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
        if ($scriptPath) {
            # If the script path is available
            $command = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Elevated"
            Start-Process PowerShell -Verb RunAs -ArgumentList $command
        } else {
            # Fallback for when the script is run directly from a web download
            $tempScriptPath = "$env:TEMP\bootstrap.ps1"
            if (Test-Path $tempScriptPath) {
                $command = "-NoProfile -ExecutionPolicy Bypass -File `"$tempScriptPath`" -Elevated"
                Start-Process PowerShell -Verb RunAs -ArgumentList $command
            } else {
                Write-Host "Unable to find script path for elevation." -ForegroundColor Red
                exit 1
            }
        }
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
    # Pass the admin status to the Install-Git function
    Write-Host "Calling Install-Git with AdminMode=$isAdmin" -ForegroundColor Magenta  # Debug output
    Install-Git -AdminMode $isAdmin
}

Write-Host "`nBootstrap complete!" -ForegroundColor Green
Write-Host "You now have Chocolatey and Git installed." -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Clone your repository:" -ForegroundColor Yellow
Write-Host "   git clone https://github.com/ms-86/win-dotfiles.git" -ForegroundColor Cyan
Write-Host "   cd win-dotfiles" -ForegroundColor Cyan
Write-Host "2. Run the setup script:" -ForegroundColor Yellow
Write-Host "   .\setup.ps1" -ForegroundColor Cyan

# If this was run in elevated mode, wait for user input before closing
if ($elevated) {
    Write-Host "`nPress any key to exit..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
