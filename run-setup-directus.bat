@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo Lancement du script Directus (PowerShell)...
powershell -ExecutionPolicy Bypass -File "scripts\setup-directus.ps1"
echo.
pause
