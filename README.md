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
Installs tools defined in tools.json:
- Automatically detects admin privileges
- Uses portable versions when possible in non-admin mode
- Reports installation success, skips, and failures

### Configuration File (tools.json)
Defines what tools to install:
- Standard and portable package names
- Admin requirement flags
- **Optional version property**: Specify a version to install, or omit for latest
- Easy to customize without modifying scripts

#### Example tools.json
```json
{
  "tools": [
    {
      "name": "git"
    },
    {
      "name": "nodejs",
      "version": "20.11.1"
    },
    {
      "name": "python",
      "portableName": "python.portable",
      "requiresAdmin": false
    }
  ]
}
```
- `version` (optional): If specified, installs that version using Chocolatey. If omitted, installs the latest version.
- `portableName` (optional): Name of the portable package to use if not running as admin.
- `requiresAdmin` (optional): Set to `false` to allow install without admin rights.

## Customization

### Modifying Tools Configuration
To add, remove, or modify tools, edit the `tools.json` file:

```json
{
  "tools": [
    {
      "name": "vscode",
      "portableName": "vscode.portable",
      "requiresAdmin": true
    },
    {
      "name": "your-new-tool",
      "portableName": "your-new-tool.portable",
      "requiresAdmin": true
    }
  ]
}
```

### Using Custom Configuration Files
You can use different configuration files for different setups:

```powershell
# Use a custom configuration file
.\setup.ps1 -ConfigFile "path\to\custom-tools.json"

# Or with the batch file
run-setup.bat -ConfigFile "path\to\custom-tools.json"
```

### Configuration Fields
- name: The Chocolatey package name
- portableName: (Optional) The portable version package name
- requiresAdmin: (Optional) Whether this package requires admin rights (defaults to true)

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

Or use the included `run-setup.bat` which automatically bypasses the execution policy.

### Non-Admin Chocolatey Limitations
When using the non-admin installation:
- Some packages may fail to install or function properly
- Portable versions will be used when available
- Some tools may be skipped if they require admin and have no portable version

### Common Errors
- Access Denied: Ensure you're running with appropriate permissions
- Package Installation Failures: Try running with admin privileges or check internet connection
- Script Execution Errors: Ensure PowerShell execution policy is properly set
- Missing Configuration: Ensure `tools.json` exists in the script directory or specify with `-ConfigFile`

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
