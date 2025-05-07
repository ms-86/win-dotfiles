# Windows Dotfiles
A collection of PowerShell scripts and configurations for setting up a Windows 11 development environment.

## Overview
This repository contains scripts to quickly bootstrap a new Windows 11 installation with essential development tools and configurations. It's designed to be modular, customizable, and user-friendly.

## Quick Start

### Step 1: Run the Bootstrap Script
Run this command in PowerShell to start the bootstrap process:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ms-86/win-dotfiles/main/bootstrap.ps1" -OutFile "$env:TEMP\bootstrap.ps1"; & "$env:TEMP\bootstrap.ps1"
```

The bootstrap script provides two installation options:
1. **Standard Installation (Recommended)**
    - Requires administrator privileges
    - Installs to C:\ProgramData\chocolatey
    - Provides system-wide package management
2. **User-specific Installation**
    - Does not require administrator privileges
    - Installs to $HOME\chocolatey by default (customizable)
    - Limited to current user only
    - Some packages may not work properly

You'll be asked to confirm your choices before proceeding.

### Step 2: Clone Repository and Run Setup Script
After the bootstrap completes:

```powershell
git clone https://github.com/ms-86/win-dotfiles.git
cd win-dotfiles
.\setup.ps1
```

## What's Included

### Bootstrap Script (bootstrap.ps1)
Sets up the essential foundations:

- **Chocolatey**: Package manager for Windows
- **Git**: Version control system
- Options for admin or non-admin installation

### Setup Script (setup.ps1)
Installs and configures:
- **VS Code**: Code editor
- **Slack**: Team communication

## Customization

### Adding More Tools
To add more tools to the setup script, simply modify the setup.ps1 file:

```powershell
# Uncomment and add more tools as needed
# Install-Tool "microsoft-windows-terminal"
# Install-Tool "nodejs-lts"
# Install-Tool "docker-desktop"
```

### Custom Configurations
<tbd>
Create your own configuration scripts in the configs directory or modify the existing ones.

## Requirements
- Windows 11
- PowerShell 5.1 or later
- Internet connection

## Troubleshooting

### Execution Policy Issues
If you encounter an error about running scripts being disabled:

```cmd
.\setup.ps1 cannot be loaded because running scripts is disabled on this system.
```

Run PowerShell as Administrator and execute:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

### Non-Admin Chocolatey Limitations
When using the non-admin installation:
- Some packages may fail to install or function properly
- You might need to specify custom installation directories for some software

### Common Errors
- Access Denied: Ensure you're running with appropriate permissions
- Package Installation Failures: Try running with admin privileges or check internet connection
- Script Execution Errors: Ensure PowerShell execution policy is properly set

## Maintenance

### Updating Tools
To update all installed packages:

```powershell
choco upgrade all -y
```

### Uninstalling
There is no automatic uninstall script. To remove installed packages, use Chocolatey:

```powershell
choco uninstall <package-name>
```
