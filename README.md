## Quick Setup for Windows 11

To set up your development environment on a fresh Windows 11 install, open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ms-86/win-dotfiles/main/setup.ps1" -OutFile "$env:TEMP\win-dotfiles-setup.ps1"; & "$env:TEMP\win-dotfiles-setup.ps1"
```

This will:
- Install Chocolatey package manager
- Install Git and Visual Studio Code (disabled for now)
```
