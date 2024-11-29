<#
.SYNOPSIS
    Configuration Management Module for Docker Development Environment
.DESCRIPTION
    Handles environment variable loading and docker-compose configuration generation.
    Manages all configuration-related tasks for the development environment.
.NOTES
    File Name      : Third_Configuration.psm1
    Version        : 0.5.1
    Author         : MrJamesLZA
    Last Modified  : 2024-11-29
#>

# 导入全局变量模块
Import-Module (Join-Path $PSScriptRoot "Global_Vars.psm1")

<#
.SYNOPSIS
    Loads environment variables from .env file
.DESCRIPTION
    Reads and processes the .env file, setting both script and process level variables.
    Handles variable substitution for nested environment variables.
.OUTPUTS
    Boolean indicating if environment loading was successful
.EXAMPLE
    Third-LoadEnvironment
#>
function Third-LoadEnvironment {
    try {
        $parentDir = Split-Path -Parent $PSScriptRoot
        $projectRoot = Split-Path -Parent $parentDir
        $envPath = Join-Path $projectRoot ".env"

        if (-not (Test-Path $envPath)) {
            Write-Host "[ERROR] .env file not found at: $envPath" -ForegroundColor Red
            return $false
        }

        Write-Host "[INFO] Loading environment variables from $envPath" -ForegroundColor Yellow

        # 读取并解析 .env 文件
        Get-Content $envPath | ForEach-Object {
            if ($_ -match '^([^#][^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # 使用全局变量存储
                Set-GlobalVar -Key $key -Value $value

                # 设置到环境变量
                [Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)

                Write-Host "[DEBUG] Loaded: $key = $value" -ForegroundColor Gray
            }
        }

        # 验证必要的变量
        if ([string]::IsNullOrEmpty((Get-GlobalVar -Key "IMAGE_NAME"))) {
            Write-Host "[ERROR] IMAGE_NAME is empty or not set in .env file" -ForegroundColor Red
            return $false
        }

        Write-Host "[SUCCESS] Environment variables loaded" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to load environment variables: $_" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    Generates docker-compose configuration
.DESCRIPTION
    Creates a docker-compose.yaml file based on environment variables.
    Sets up container configuration including volumes, ports, and environment variables.
.OUTPUTS
    Boolean indicating if configuration generation was successful
.EXAMPLE
    Third-GenerateComposeConfig
#>
function Third-GenerateComposeConfig {
    Write-Host "[INFO] Generating docker-compose.yaml..." -ForegroundColor Yellow

    # Process parent directory volumes path
    $parentDir = Split-Path -Parent $PSScriptRoot
    $volumePath = Join-Path $parentDir "volumes"

    # Ensure volumes directory exists
    if (-not (Test-Path $volumePath)) {
        New-Item -ItemType Directory -Path $volumePath -Force | Out-Null
    }

    # Convert to Unix-style path
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

    $composeFile = Join-Path (Split-Path -Parent $PSScriptRoot) "docker-compose.yaml"
    $composeContent | Set-Content -Path $composeFile -Encoding UTF8
    Write-Host "[SUCCESS] docker-compose.yaml generated" -ForegroundColor Green
    return $true
}

<#
.SYNOPSIS
    Main configuration management function
.DESCRIPTION
    Coordinates the loading of environment variables and generation of configuration files
.OUTPUTS
    Boolean indicating if all configuration tasks completed successfully
.EXAMPLE
    Main
#>
function Main {
    if (-not (Third-LoadEnvironment)) { return $false }
    if (-not (Third-GenerateComposeConfig)) { return $false }
    return $true
}

# Export module members
Export-ModuleMember -Function Main, Third-*