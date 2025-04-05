@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit
)

echo Shutting down Docker Desktop and services...
taskkill /f /im "Docker Desktop.exe" 2>nul
timeout /t 2
net stop "com.docker.service"

echo Shutting down WSL...
wsl --shutdown

echo Verifying WSL status...
wsl --list --running
if %ERRORLEVEL% EQU 0 (
    echo ERROR: WSL is still running. Please close all WSL instances manually.
    pause
    exit
) else (
    echo SUCCESS: All WSL instances are stopped.
)

echo Please enter target path (e.g. D:\DockerWSL):
set /p TARGET_PATH=

echo Exporting docker-desktop WSL instances...
wsl --export docker-desktop C:\docker-desktop-backup.tar
wsl --export docker-desktop-data C:\docker-desktop-data-backup.tar

echo Unregistering existing WSL instances...
wsl --unregister docker-desktop
wsl --unregister docker-desktop-data

echo Cleaning up old WSL files...
del /f "%LOCALAPPDATA%\Docker\wsl\data\docker-desktop.vhdx" 2>nul
del /f "%LOCALAPPDATA%\Docker\wsl\data\docker-desktop-data.vhdx" 2>nul

echo Reimporting WSL instances...
wsl --import docker-desktop %TARGET_PATH%\docker-desktop C:\docker-desktop-backup.tar
wsl --import docker-desktop-data %TARGET_PATH%\docker-desktop-data C:\docker-desktop-data-backup.tar

echo Migration completed!
echo [IMPORTANT] Next steps:
echo 1. Start Docker Desktop manually
echo 2. Wait for Docker Desktop to initialize completely
echo 3. If everything works properly, you can delete:
echo    - C:\docker-desktop-backup.tar
echo    - C:\docker-desktop-data-backup.tar
pause