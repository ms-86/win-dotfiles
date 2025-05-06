## Windows 11 Setup Instructions

### Step 1: Initial Bootstrap

To set up your development environment on a fresh Windows 11 machine, first run this command in PowerShell (as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ms-86/win-dotfiles/main/bootstrap.ps1" -OutFile "$env:TEMP\bootstrap.ps1"; & "$env:TEMP\bootstrap.ps1"
```

This will install:
- Chocolatey package manager
- Git

### Step 2: Clone Repository and Complete Setup

After running the bootstrap script, clone this repository and run the setup script:

```powershell
git clone https://github.com/ms-86/win-dotfiles.git
cd win-dotfiles
.\setup.ps1
```

The setup script will install:
- Visual Studio Code
- Slack
- DBeaver Community

### Manual Installation

If you prefer to install additional tools manually:

```powershell
# After running bootstrap.ps1
choco install vscode -y
choco install slack -y
# Add any other tools you need
```
