@echo off
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

:: Main script starts here
echo Starting environment setup...

:: 启动 PowerShell 交互式菜单
powershell -NoExit -Command "Write-Host 'Docker Development Environment Manager' -ForegroundColor Cyan; Import-Module '%~dp0\modules\First_Core.psm1'; Show-MainMenu"