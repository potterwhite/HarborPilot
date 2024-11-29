<#
.SYNOPSIS
    Docker Development Environment Manager for Windows
.DESCRIPTION
    Manages Docker development environment with automatic configuration generation
    and container lifecycle management.
.NOTES
    File Name      : docker-manager.ps1
    Version        : 1.0.0
#>

# Initialize environment settings
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$script:SCRIPT_DIR = $PSScriptRoot

function First-LoadEnvironment {
    $envFile = Join-Path $SCRIPT_DIR "../.env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # Handle variable substitution
                if ($value -match "\$\{([^}]+)\}") {
                    $varName = $matches[1]
                    if (Get-Variable -Name $varName -ErrorAction SilentlyContinue) {
                        $varValue = (Get-Variable -Name $varName).Value
                        $value = $value.Replace("`${$varName}", $varValue)
                    }
                }

                # Set as script variable
                Set-Variable -Name $key -Value $value -Scope Script

                # Also set as environment variable
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }
        Write-Host "[SUCCESS] Environment variables loaded" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ERROR] .env file not found" -ForegroundColor Red
        return $false
    }
}

function Second-GenerateComposeConfig {
    Write-Host "[INFO] Generating docker-compose.yaml..." -ForegroundColor Yellow

    # 正确处理父目录的 volumes 路径
    $parentDir = Split-Path -Parent $SCRIPT_DIR
    $volumePath = Join-Path $parentDir "volumes"

    # 确保 volumes 目录存在
    if (-not (Test-Path $volumePath)) {
        New-Item -ItemType Directory -Path $volumePath -Force | Out-Null
    }

    # 转换为 Unix 风格的路径
    $volumePath = $volumePath.Replace('\', '/')

    # Construct full image name with registry URL
    $fullImageName = "$script:REGISTRY_URL/$script:IMAGE_NAME`:latest"

    $composeContent = @"
services:
  dev-env:
    image: $fullImageName
    container_name: $script:CONTAINER_NAME
    hostname: $script:CONTAINER_NAME
    user: "$script:DEV_USERNAME"
    restart: unless-stopped
    privileged: true
    tty: true
    stdin_open: true

    volumes:
      - "$volumePath`:$script:VOLUMES_ROOT"

    ports:
      - "$script:SSH_PORT`:22"
      - "$script:GDB_PORT`:2345"
      - "$script:WORKSPACE_DEBUG_PORT`:3000"

    environment:
      - TIMEZONE=$script:TIMEZONE
      - WORKSPACE_ENABLE_REMOTE_DEBUG=$script:WORKSPACE_ENABLE_REMOTE_DEBUG
      - WORKSPACE_LOG_LEVEL=$script:WORKSPACE_LOG_LEVEL
      - DEV_USERNAME=$script:DEV_USERNAME
      - DEV_USER_PASSWORD=$script:DEV_USER_PASSWORD
      - DEV_USER_ROOT_PASSWORD=$script:DEV_USER_ROOT_PASSWORD
      - DEV_UID=$script:DEV_UID
      - DEV_GID=$script:DEV_GID
      - DEV_GROUP=$script:DEV_GROUP
      - WORKSPACE_ROOT=$script:WORKSPACE_ROOT
      - SDK_INSTALL_PATH=$script:SDK_INSTALL_PATH
      - SDK_GIT_REPO=$script:SDK_GIT_REPO
      - ENABLE_SSH=$script:ENABLE_SSH
      - ENABLE_SYSLOG=$script:ENABLE_SYSLOG
      - ENABLE_GDB_SERVER=$script:ENABLE_GDB_SERVER
      - ENABLE_CORE_DUMPS=$script:ENABLE_CORE_DUMPS
      - CORE_PATTERN=$script:CORE_PATTERN

    working_dir: $script:WORKSPACE_ROOT

    networks:
      - dev-net

networks:
  dev-net:
    driver: bridge
"@

    $composeFile = Join-Path $SCRIPT_DIR "docker-compose.yaml"
    $composeContent | Set-Content -Path $composeFile -Encoding UTF8
    Write-Host "[SUCCESS] docker-compose.yaml generated" -ForegroundColor Green
}

function Third-ContainerExists {
    $exists = docker ps -a --format "{{.Names}}" | Select-String "^${script:CONTAINER_NAME}$"
    return $null -ne $exists
}

function Third-ContainerRunning {
    $running = docker ps --format "{{.Names}}" | Select-String "^${script:CONTAINER_NAME}$"
    return $null -ne $running
}

function Ensure-DockerLogin {
    param (
        [int]$maxAttempts = 3
    )

    if (-not $script:REGISTRY_URL) { return $true }

    Write-Host "[INFO] Logging into private registry..." -ForegroundColor Yellow

    for ($i = 1; $i -le $maxAttempts; $i++) {
        docker login $script:REGISTRY_URL
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        if ($i -lt $maxAttempts) {
            Write-Host "[WARN] Login failed, attempt $i of $maxAttempts" -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }

    Write-Host "[ERROR] Failed to login after $maxAttempts attempts" -ForegroundColor Red
    return $false
}

function Fourth-StartContainer {
    if (-not (Ensure-DockerLogin)) {
        return $false
    }

    if (-not (Third-ContainerExists)) {
        Write-Host "[INFO] Creating new development environment..." -ForegroundColor Yellow
        Second-GenerateComposeConfig

        # Pull image first with retry
        Write-Host "[INFO] Pulling image ${script:REGISTRY_URL}/${script:IMAGE_NAME}:latest..." -ForegroundColor Yellow
        $pullAttempts = 3
        for ($i = 1; $i -le $pullAttempts; $i++) {
            docker pull "${script:REGISTRY_URL}/${script:IMAGE_NAME}:latest"
            if ($LASTEXITCODE -eq 0) {
                break
            }
            if ($i -lt $pullAttempts) {
                Write-Host "[WARN] Pull failed, attempt $i of $pullAttempts" -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            } else {
                Write-Host "[ERROR] Failed to pull image after $pullAttempts attempts" -ForegroundColor Red
                return $false
            }
        }

        Push-Location $SCRIPT_DIR
        docker compose up -d
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to start container" -ForegroundColor Red
            Pop-Location
            return $false
        }
        Pop-Location
    } else {
        Write-Host "[INFO] Starting existing container..." -ForegroundColor Yellow
        docker start $script:CONTAINER_NAME
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to start container" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

function Fourth-StopContainer {
    if (Third-ContainerRunning) {
        Write-Host "[INFO] Stopping container..." -ForegroundColor Yellow
        docker stop $script:CONTAINER_NAME
    }
}

function Fourth-RemoveContainer {
    if (Third-ContainerExists) {
        Write-Host "[INFO] Removing container..." -ForegroundColor Yellow
        Push-Location $SCRIPT_DIR
        docker compose down
        Pop-Location
        Remove-Item (Join-Path $SCRIPT_DIR "docker-compose.yaml") -ErrorAction SilentlyContinue
    }
}

function Fifth-HandleRunningContainer {
    while ($true) {
        Clear-Host
        Write-Host "Container is already running!" -ForegroundColor Yellow
        Write-Host "Please choose an option (press Ctrl+C to cancel):" -ForegroundColor Yellow
        Write-Host "1. Enter the container" -ForegroundColor Yellow
        Write-Host "2. Restart container" -ForegroundColor Yellow
        Write-Host "3. Remove and recreate" -ForegroundColor Yellow
        Write-Host "`nYou can always enter container manually using:" -ForegroundColor Green
        Write-Host "docker exec -it -u $script:DEV_USERNAME $script:CONTAINER_NAME bash" -ForegroundColor Yellow

        $choice = Read-Host "Enter your choice (1-3)"

        switch ($choice) {
            "1" {
                docker exec -it -u $script:DEV_USERNAME $script:CONTAINER_NAME bash
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

function Fifth-AskEnterContainer {
    $answer = Read-Host "Enter container? [Y/n]"
    if ($answer -notmatch '^[Nn]$') {
        docker exec -it -u $script:DEV_USERNAME $script:CONTAINER_NAME bash
    } else {
        Write-Host "`nYou can always enter container manually using:" -ForegroundColor Green
        Write-Host "docker exec -it -u $script:DEV_USERNAME $script:CONTAINER_NAME bash" -ForegroundColor Yellow
    }
}

function Main {
    param (
        [string]$Command
    )

    if (-not (First-LoadEnvironment)) { return }

    switch ($Command) {
        "start" {
            if (Third-ContainerRunning) {
                Fifth-HandleRunningContainer
            } else {
                Fourth-StartContainer
                Fifth-AskEnterContainer
            }
        }
        "stop" {
            Fourth-StopContainer
        }
        "restart" {
            Fourth-StopContainer
            Start-Sleep -Seconds 2
            Fourth-StartContainer
            Fifth-AskEnterContainer
        }
        "recreate" {
            Fourth-RemoveContainer
            Fourth-StartContainer
            Fifth-AskEnterContainer
        }
        "remove" {
            Fourth-RemoveContainer
        }
        default {
            Write-Host "Usage: $($MyInvocation.MyCommand.Name) [COMMAND]`n" -ForegroundColor Yellow
            Write-Host "Commands:"
            Write-Host "    start     Start development environment"
            Write-Host "    stop      Stop development environment"
            Write-Host "    restart   Restart development environment"
            Write-Host "    recreate  Remove and recreate development environment"
            Write-Host "    remove    Remove development environment"
        }
    }
}

# Script entry point
try {
    Main $args[0]
} catch {
    Write-Host "[ERROR] An error occurred: $_" -ForegroundColor Red
    exit 1
}