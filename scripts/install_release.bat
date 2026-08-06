@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_release.ps1" %*
if errorlevel 1 exit /b 1
pause
