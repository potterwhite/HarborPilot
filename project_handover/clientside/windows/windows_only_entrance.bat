@echo off
setlocal enabledelayedexpansion

:: 设置标题
title Docker Development Environment Manager

:: Check for admin rights and self-elevate if necessary
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

:: 启动 PowerShell 并保持窗口
powershell -NoExit -Command "Write-Host 'Starting environment setup...' -ForegroundColor Cyan; Import-Module '%~dp0modules\First_Core.psm1'; Show-MainMenu"