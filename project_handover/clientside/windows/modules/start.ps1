<#
.SYNOPSIS
    Entry Point Script for Docker Development Environment
.DESCRIPTION
    Main entry point that coordinates all modules for the Docker development environment.
.NOTES
    File Name      : start.ps1
    Version        : 0.5.1
    Author         : MrJamesLZA
    Last Modified  : 2024-11-29
#>

$WarningPreference = 'SilentlyContinue'

# 导入主模块
$modulePath = $PSScriptRoot
Import-Module (Join-Path $modulePath "First_Core.psm1")

function Create-Shortcuts {
    $response = Read-Host "Would you like to create desktop shortcuts for the development environment? (y/N)"
    if ($response -ne "y") {
        Write-Host "[INFO] Skipping shortcut creation" -ForegroundColor Yellow
        return
    }

    try {
        $WshShell = New-Object -comObject WScript.Shell
        $scriptPath = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
        $desktopPath = [System.Environment]::GetFolderPath('Desktop')

        Write-Host "[INFO] Creating shortcuts on desktop..." -ForegroundColor Yellow

        # 创建开发环境启动快捷方式
        $shortcut = $WshShell.CreateShortcut("$desktopPath\Docker Dev Env - Start.lnk")
        $shortcut.TargetPath = "cmd.exe"
        $shortcut.Arguments = "/k `"`"$scriptPath\windows_only_entrance.bat`" start`""
        $shortcut.WorkingDirectory = $scriptPath
        $shortcut.IconLocation = "C:\Windows\System32\shell32.dll,146"
        $shortcut.Description = "Start Docker Development Environment"
        $shortcut.Save()

        # 创建开发环境停止快捷方式
        $shortcut = $WshShell.CreateShortcut("$desktopPath\Docker Dev Env - Stop.lnk")
        $shortcut.TargetPath = "cmd.exe"
        $shortcut.Arguments = "/k `"`"$scriptPath\windows_only_entrance.bat`" stop`""
        $shortcut.WorkingDirectory = $scriptPath
        $shortcut.IconLocation = "C:\Windows\System32\shell32.dll,27"
        $shortcut.Description = "Stop Docker Development Environment"
        $shortcut.Save()

        Write-Host "[SUCCESS] Desktop shortcuts created successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to create shortcuts: $_" -ForegroundColor Red
    }
}

# 在初始化时询问是否创建快捷方式
Create-Shortcuts

# Call the main function
First-Main $args[0]
