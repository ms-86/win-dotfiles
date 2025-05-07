@echo off
echo Running Windows setup script with execution policy bypass...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
pause
