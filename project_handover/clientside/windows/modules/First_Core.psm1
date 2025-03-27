# 最优先：设置错误处理
$ErrorActionPreference = 'Stop'  # 类似 bash 的 set -e
$WarningPreference = 'SilentlyContinue'

<#
.SYNOPSIS
    Core Module for Docker Development Environment Manager
.DESCRIPTION
    Main entry point for the Docker development environment management system.
    Coordinates all other modules and provides the primary command interface.
.NOTES
    File Name      : First_Core.psm1
    Version        : 0.5.1
    Author         : MrJamesLZA
    Last Modified  : 2024-11-29
#>

# Initialize environment settings
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$script:SCRIPT_DIR = Split-Path -Parent $PSScriptRoot

# 导入其他模块
$modulePath = $PSScriptRoot
Import-Module (Join-Path $modulePath "Second_Environment.psm1")
Import-Module (Join-Path $modulePath "Third_Configuration.psm1")
Import-Module (Join-Path $modulePath "Fourth_Container.psm1")
Import-Module (Join-Path $modulePath "Fifth_Interactive.psm1")

<#
.SYNOPSIS
    Processes the command line arguments
.DESCRIPTION
    Handles all supported commands for container management
.PARAMETER Command
    The command to execute (start, stop, restart, recreate, remove)
.EXAMPLE
    First-ProcessCommand "start"
#>
function First-ProcessCommand {
    param (
        [string]$Command
    )

    switch ($Command) {
        "start" {
            if (Fourth-ContainerRunning) {
                Fifth-HandleRunningContainer
                return $true  # 成功
            } else {
                # 只有在成功启动容器后才询问是否进入
                $result = Fourth-StartContainer
                if ($result) {
                    Fifth-AskEnterContainer
                    return $true  # 成功
                } else {
                    Write-Host "[ERROR] Failed to start container. Exiting..." -ForegroundColor Red
                    return $false  # 失败
                }
            }
        }
        "stop" {
            Fourth-StopContainer
            return $true
        }
        "remove" {
            Fourth-RemoveContainer
            return $true
        }
        default {
            Write-Host "[ERROR] Unknown command: $Command" -ForegroundColor Red
            return $false
        }
    }
}

<#
.SYNOPSIS
    Displays command usage information
.DESCRIPTION
    Shows available commands and their descriptions
.EXAMPLE
    First-ShowUsage
#>
function First-ShowUsage {
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) [COMMAND]`n" -ForegroundColor Yellow
    Write-Host "Commands:"
    Write-Host "    start     Start development environment"
    Write-Host "    stop      Stop development environment"
    Write-Host "    restart   Restart development environment"
    Write-Host "    recreate  Remove and recreate development environment"
    Write-Host "    remove    Remove development environment"
}

<#
.SYNOPSIS
    Ensures script is running with administrator privileges
.DESCRIPTION
    Checks current privileges and restarts with elevation if necessary
.OUTPUTS
    Boolean indicating if script has admin privileges
.EXAMPLE
    First-EnsureAdminPrivileges
#>
function First-EnsureAdminPrivileges {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        try {
            # Get the script path and arguments
            $scriptPath = $MyInvocation.MyCommand.Definition
            $arguments = $args

            # Start new elevated process
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`" $arguments" -Wait

            # Exit current non-elevated process
            exit
        }
        catch {
            Write-Host "[ERROR] Failed to elevate privileges: $_" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

<#
.SYNOPSIS
    Main entry point for the module
.DESCRIPTION
    Coordinates the overall flow of the application
.PARAMETER Command
    The command to execute
.EXAMPLE
    First-Main "start"
#>
function First-Main {
    param (
        [string]$Command
    )

    # Ensure admin privileges first
    if (-not (First-EnsureAdminPrivileges)) { return }

    if (-not (Second-EnvironmentCheck)) { return }
    if (-not (Third-LoadEnvironment)) { return }

    $result = First-ProcessCommand $Command
    if (-not $result) {
        exit 1  # 失败时退出码为1
    }
}

function Show-MainMenu {
    # 确保环境检查和加载
    if (-not (Second-EnvironmentCheck)) {
        Write-Host "[ERROR] Environment check failed" -ForegroundColor Red
        return
    }
    if (-not (Third-LoadEnvironment)) {
        Write-Host "[ERROR] Failed to load environment variables" -ForegroundColor Red
        return
    }

    while ($true) {
        Write-Host "`n=== Docker Development Environment Manager ===" -ForegroundColor Cyan
        Write-Host "1. Start Development Environment" -ForegroundColor Green
        Write-Host "2. Stop Development Environment" -ForegroundColor Yellow
        Write-Host "3. Remove Development Environment" -ForegroundColor Red
        Write-Host "4. Exit" -ForegroundColor Gray
        Write-Host "============================================`n" -ForegroundColor Cyan

        $choice = Read-Host "Please enter your choice (1-4)"

        switch ($choice) {
            "1" {
                Write-Host "`n[ACTION] Starting Development Environment..." -ForegroundColor Green
                $result = First-ProcessCommand "start"
                if (-not $result) {
                    Write-Host "[ERROR] Failed to start environment" -ForegroundColor Red
                }
            }
            "2" {
                Write-Host "`n[ACTION] Stopping Development Environment..." -ForegroundColor Yellow
                $result = First-ProcessCommand "stop"
                if (-not $result) {
                    Write-Host "[ERROR] Failed to stop environment" -ForegroundColor Red
                }
            }
            "3" {
                Write-Host "`n[ACTION] Removing Development Environment..." -ForegroundColor Red
                $confirm = Read-Host "Are you sure you want to remove the environment? (y/N)"
                if ($confirm -eq "y") {
                    $result = First-ProcessCommand "remove"
                    if (-not $result) {
                        Write-Host "[ERROR] Failed to remove environment" -ForegroundColor Red
                    }
                }
            }
            "4" {
                Write-Host "`n[INFO] Exiting..." -ForegroundColor Gray
                return
            }
            default {
                Write-Host "`n[ERROR] Invalid choice. Please try again." -ForegroundColor Red
            }
        }

        Write-Host "`nPress Enter to continue..." -ForegroundColor Gray
        Read-Host
        Clear-Host
    }
}

# 修改现有的 Main 函数
function Main {
    param (
        [string]$Command
    )

    if ([string]::IsNullOrEmpty($Command)) {
        Show-MainMenu
    } else {
        # 确保环境检查和加载
        if (-not (Second-EnvironmentCheck)) { return $false }
        if (-not (Third-LoadEnvironment)) { return $false }

        First-ProcessCommand $Command
    }
}

# Export module members
Export-ModuleMember -Function Main, Show-MainMenu