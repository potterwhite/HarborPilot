<#
.SYNOPSIS
    Interactive Operations Module for Docker Development Environment
.DESCRIPTION
    Handles all user interaction operations including container access,
    menu displays, and interactive prompts.
.NOTES
    File Name      : Fifth_Interactive.psm1
    Version        : 0.5.1
    Author         : MrJamesLZAZ
    Last Modified  : 2024-11-29
#>

# 导入全局变量模块
Import-Module (Join-Path $PSScriptRoot "Global_Vars.psm1")

<#
.SYNOPSIS
    Handles interaction with running container
.DESCRIPTION
    Provides interactive menu for container operations when container is already running
.OUTPUTS
    None
.EXAMPLE
    Fifth-HandleRunningContainer
#>
function Fifth-HandleRunningContainer {
    while ($true) {
        Clear-Host
        Write-Host "[INFO] Container is already running!" -ForegroundColor Yellow
        Write-Host "[INFO] Please choose an option (press Ctrl+C to cancel):" -ForegroundColor Yellow
        Write-Host "1. Enter the container" -ForegroundColor Yellow
        Write-Host "2. Restart container" -ForegroundColor Yellow
        Write-Host "3. Remove and recreate" -ForegroundColor Yellow
        Write-Host "`n[INFO] You can always enter container manually using:" -ForegroundColor Green
        Write-Host "docker exec -it -u $script:DEV_USERNAME $script:CONTAINER_NAME bash" -ForegroundColor Yellow

        $choice = Read-Host "Enter your choice (1-3)"

        switch ($choice) {
            "1" {
                Fifth-EnterContainer
                return
            }
            "2" {
                Fourth-StopContainer
                Fourth-StartContainer
                Fifth-AskEnterContainer
                return
            }
            "3" {
                Fourth-RemoveContainer
                Fourth-StartContainer
                Fifth-AskEnterContainer
                return
            }
            default {
                Write-Host "[ERROR] Invalid choice! Please try again..." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

<#
.SYNOPSIS
    Enters the container shell
.DESCRIPTION
    Executes an interactive bash shell in the container as the specified user
.OUTPUTS
    None
.EXAMPLE
    Fifth-EnterContainer
#>
function Fifth-EnterContainer {
    $containerName = Get-GlobalVar -Key "CONTAINER_NAME"
    if (-not $containerName) {
        Write-Host "[ERROR] Container name not configured" -ForegroundColor Red
        return $false
    }

    Write-Host "[INFO] Entering container $containerName..." -ForegroundColor Yellow

    # 检查容器状态
    $status = docker inspect -f '{{.State.Status}}' $containerName 2>$null
    Write-Host "[DEBUG] Container status: $status" -ForegroundColor Gray

    if ($status -ne "running") {
        Write-Host "[ERROR] Container is not running" -ForegroundColor Red
        return $false
    }

    Write-Host "[INFO] Attempting to enter container..." -ForegroundColor Yellow

    try {
        # 使用新的 PowerShell 窗口运行容器
        $command = "docker exec -it $containerName /bin/bash"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $command

        Write-Host "[INFO] Container shell opened in new window" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[ERROR] Exception while entering container: $_" -ForegroundColor Red
        Write-Host "[DEBUG] Exception details: $($_.Exception.Message)" -ForegroundColor Gray
        return $false
    }
}

<#
.SYNOPSIS
    Prompts user to enter container
.DESCRIPTION
    Asks user if they want to enter the container and handles their response
.OUTPUTS
    None
.EXAMPLE
    Fifth-AskEnterContainer
#>
function Fifth-AskEnterContainer {
    $response = Read-Host "Enter container? [Y/n]"
    if ($response -ne "n") {
        if (-not (Fifth-EnterContainer)) {
            Write-Host "[ERROR] Failed to enter container. Please check container status and try again." -ForegroundColor Red
        }
    }
}

<#
.SYNOPSIS
    Shows command help information
.DESCRIPTION
    Displays available commands and their descriptions
.OUTPUTS
    None
.EXAMPLE
    Fifth-ShowHelp
#>
function Fifth-ShowHelp {
    Write-Host "`nAvailable commands:" -ForegroundColor Yellow
    Write-Host "    enter     Enter the container shell"
    Write-Host "    help      Show this help message"
    Write-Host "    exit      Exit the interactive session"
}

<#
.SYNOPSIS
    Main interactive operations function
.DESCRIPTION
    Coordinates all interactive operations based on command
.PARAMETER Command
    The interactive operation to perform
.EXAMPLE
    Main -Command "enter"
#>
function Main {
    param (
        [string]$Command
    )

    switch ($Command) {
        "enter" { Fifth-EnterContainer }
        "help" { Fifth-ShowHelp }
        default { return $true }
    }
}

# Export module members
Export-ModuleMember -Function Main, Fifth-*