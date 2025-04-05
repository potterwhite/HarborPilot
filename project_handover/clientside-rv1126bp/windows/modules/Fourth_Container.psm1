<#
.SYNOPSIS
    Container Operations Module for Docker Development Environment
.DESCRIPTION
    Handles all Docker container operations including checking status,
    starting, stopping, and removing containers.
.NOTES
    File Name      : Fourth_Container.psm1
    Version        : 0.5.1
    Author         : MrJamesLZAZ
    Last Modified  : 2024-11-29
#>

# 导入全局变量模块
Import-Module (Join-Path $PSScriptRoot "Global_Vars.psm1")

<#
.SYNOPSIS
    Checks if container exists
.DESCRIPTION
    Verifies if the specified container exists in Docker
.OUTPUTS
    Boolean indicating if container exists
.EXAMPLE
    Fourth-ContainerExists
#>
function Fourth-ContainerExists {
    $exists = docker ps -a --format "{{.Names}}" | Select-String "^${script:CONTAINER_NAME}$"
    return $null -ne $exists
}

<#
.SYNOPSIS
    Checks if container is running
.DESCRIPTION
    Verifies if the specified container is currently running
.OUTPUTS
    Boolean indicating if container is running
.EXAMPLE
    Fourth-ContainerRunning
#>
function Fourth-ContainerRunning {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        return Fourth-WaitForDocker
    }

    $running = docker ps --format "{{.Names}}" | Select-String "^${script:CONTAINER_NAME}$"
    return $null -ne $running
}

<#
.SYNOPSIS
    Ensures Docker registry login
.DESCRIPTION
    Attempts to log into Docker registry with retry mechanism
.PARAMETER maxAttempts
    Maximum number of login attempts
.OUTPUTS
    Boolean indicating if login was successful
.EXAMPLE
    Fourth-EnsureDockerLogin -maxAttempts 3
#>
function Fourth-EnsureDockerLogin {
    $registryUrl = Get-GlobalVar -Key "REGISTRY_URL"
    if (-not $registryUrl) { return $true }

    # 检查是否已经登录
    if (Fourth-CheckRegistryLogin $registryUrl) {
        return $true
    }

    Write-Host "[INFO] Logging into private registry..." -ForegroundColor Yellow

    # 最多尝试3次
    for ($i = 1; $i -le 3; $i++) {
        $username = Read-Host "Username"
        $securePassword = Read-Host "Password" -AsSecureString
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))

        $password | docker login $registryUrl --username $username --password-stdin
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Successfully logged into registry" -ForegroundColor Green
            return $true
        }

        if ($i -lt 3) {
            Write-Host "[WARN] Login failed, attempt $i of 3" -ForegroundColor Yellow
        }
    }

    Write-Host "[ERROR] Failed to login after 3 attempts" -ForegroundColor Red
    return $false
}

<#
.SYNOPSIS
    Starts the development container
.DESCRIPTION
    Creates and starts the development container, pulling image if necessary
.OUTPUTS
    Boolean indicating if container start was successful
.EXAMPLE
    Fourth-StartContainer
#>
function Fourth-StartContainer {
    if (-not (Fourth-EnsureDockerLogin)) {
        return $false
    }

    if (-not (Fourth-ContainerExists)) {
        Write-Host "[INFO] Creating new development environment..." -ForegroundColor Yellow

        # 创建 docker-compose.yaml
        if (-not (Fourth-CreateComposeFile)) {
            return $false
        }

        # 从全局变量中获取值
        $imageName = Get-GlobalVar -Key "IMAGE_NAME"
        $registryUrl = Get-GlobalVar -Key "REGISTRY_URL"

        if (-not $imageName) {
            Write-Host "[ERROR] Image name is not configured. Please check your configuration." -ForegroundColor Red
            return $false
        }

        # 构建完整的镜像名称
        $fullImageName = $imageName
        if ($registryUrl) {
            $fullImageName = "${registryUrl}/${imageName}"
        }

        # 添加标签
        $tag = "latest"
        $fullImageName = "${fullImageName}:${tag}"

        Write-Host "[INFO] Using image: $fullImageName" -ForegroundColor Yellow

        # Pull image first with retry
        Write-Host "[INFO] Pulling image $fullImageName..." -ForegroundColor Yellow
        $pullAttempts = 3
        for ($i = 1; $i -le $pullAttempts; $i++) {
            docker pull $fullImageName
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

        Push-Location (Split-Path -Parent $PSScriptRoot)
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

<#
.SYNOPSIS
    Stops the development container
.DESCRIPTION
    Stops the running development container
.EXAMPLE
    Fourth-StopContainer
#>
function Fourth-StopContainer {
    if (Fourth-ContainerRunning) {
        Write-Host "[INFO] Stopping container..." -ForegroundColor Yellow
        docker stop $script:CONTAINER_NAME
    }
}

<#
.SYNOPSIS
    Removes the development container
.DESCRIPTION
    Removes the development container and associated configuration
.EXAMPLE
    Fourth-RemoveContainer
#>
function Fourth-RemoveContainer {
    try {
        $containerName = Get-GlobalVar -Key "CONTAINER_NAME"
        if (-not $containerName) {
            Write-Host "[ERROR] Container name not configured" -ForegroundColor Red
            return $false
        }

        Write-Host "[INFO] Removing development environment..." -ForegroundColor Yellow

        # 检查容器是否存在
        $containerExists = docker ps -a --format '{{.Names}}' | Select-String -Pattern "^${containerName}$"

        if ($containerExists) {
            $parentDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            Push-Location $parentDir

            # 1. 先停止容器
            Write-Host "[INFO] Stopping container..." -ForegroundColor Yellow
            docker stop $containerName

            # 2. 使用 docker compose down 删除容器和网络
            Write-Host "[INFO] Removing container and networks..." -ForegroundColor Yellow
            docker compose down

            # 3. 强制删除容器（以防万一）
            Write-Host "[INFO] Force removing container if still exists..." -ForegroundColor Yellow
            docker rm -f $containerName 2>$null

            # 4. 删除相关文件
            Write-Host "[INFO] Cleaning up files..." -ForegroundColor Yellow

            # 删除 docker-compose.yaml
            $composeFile = Join-Path $parentDir "docker-compose.yaml"
            if (Test-Path $composeFile) {
                Remove-Item $composeFile -Force
                Write-Host "[INFO] Removed docker-compose.yaml" -ForegroundColor Yellow
            }

            # 5. 清理未使用的卷（可选）
            Write-Host "[INFO] Cleaning up unused volumes..." -ForegroundColor Yellow
            docker volume prune -f

            Pop-Location

            Write-Host "[SUCCESS] Development environment removed completely" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[INFO] Container does not exist" -ForegroundColor Yellow
            return $true
        }
    }
    catch {
        Write-Host "[ERROR] Failed to remove container: $_" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    Main container operations function
.DESCRIPTION
    Coordinates container operations based on command
.PARAMETER Command
    The container operation to perform
.EXAMPLE
    Main -Command "start"
#>
function Main {
    param (
        [string]$Command
    )

    switch ($Command) {
        "start" { return Fourth-StartContainer }
        "stop" { Fourth-StopContainer; return $true }
        "remove" { Fourth-RemoveContainer; return $true }
        default { return $true }
    }
}

function Fourth-WaitForDocker {
    Write-Host "[INFO] Waiting for Docker to be ready..." -ForegroundColor Yellow
    $maxAttempts = 30
    $attempt = 0

    while ($attempt -lt $maxAttempts) {
        try {
            $result = docker info 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[SUCCESS] Docker is ready!" -ForegroundColor Green
                return $true
            }
        }
        catch { }

        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
        $attempt++
    }

    Write-Host "`n[ERROR] Docker did not become ready in time" -ForegroundColor Red
    return $false
}

function Fourth-CheckRegistryLogin {
    param (
        [string]$registryUrl
    )

    try {
        # 检查 Docker 凭据存储
        $configFile = "$env:USERPROFILE\.docker\config.json"
        Write-Host "[DEBUG] Checking Docker config at: $configFile" -ForegroundColor Gray

        if (Test-Path $configFile) {
            Write-Host "[DEBUG] Config file exists" -ForegroundColor Gray
            $config = Get-Content $configFile | ConvertFrom-Json

            # 显示现有的认证信息
            Write-Host "[DEBUG] Available auths:" -ForegroundColor Gray
            $config.auths.PSObject.Properties.Name | ForEach-Object {
                Write-Host "[DEBUG] - $_" -ForegroundColor Gray
            }

            if ($config.auths.PSObject.Properties.Name -contains $registryUrl) {
                Write-Host "[DEBUG] Found credentials for $registryUrl" -ForegroundColor Gray

                # 直接使用 docker pull 测试凭据
                $testImage = "$registryUrl/n8-dev-env:latest"
                Write-Host "[DEBUG] Testing credentials with: $testImage" -ForegroundColor Gray

                # 静默执行 pull 测试
                $null = docker pull $testImage 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[INFO] Using existing registry credentials" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "[DEBUG] Existing credentials are invalid" -ForegroundColor Gray
                }
            } else {
                Write-Host "[DEBUG] No credentials found for $registryUrl" -ForegroundColor Gray
            }
        } else {
            Write-Host "[DEBUG] Config file does not exist" -ForegroundColor Gray
        }
        return $false
    }
    catch {
        Write-Host "[DEBUG] Error checking registry login: $_" -ForegroundColor Gray
        return $false
    }
}

function Fourth-ConfigureInsecureRegistry {
    try {
        $registryUrl = Get-GlobalVar -Key "REGISTRY_URL"
        if (-not $registryUrl) { return $true }

        Write-Host "[INFO] Configuring insecure registry: $registryUrl" -ForegroundColor Yellow

        Write-Host @"
[WARN] To use an insecure registry, you need to configure Docker Desktop:

1. Open Docker Desktop
2. Click the gear icon (Settings)
3. Go to 'Docker Engine'
4. Add your registry to the 'insecure-registries' list:

{
  "insecure-registries": [
    "$registryUrl"
  ]
}

5. Click 'Apply & Restart'

"@ -ForegroundColor Yellow

        $response = Read-Host "Have you configured the insecure registry in Docker Desktop? (y/N)"
        if ($response -ne "y") {
            Write-Host "[ERROR] Please configure Docker Desktop and try again" -ForegroundColor Red
            return $false
        }

        # 等待 Docker 重启并验证
        return Fourth-WaitForDocker
    }
    catch {
        Write-Host "[ERROR] Failed to configure insecure registry: $_" -ForegroundColor Red
        return $false
    }
}

function Fourth-CreateComposeFile {
    try {
        $parentDir = Split-Path -Parent $PSScriptRoot  # 退一级到项目根目录
        $grandparentDir = Split-Path -Parent ($parentDir)  # 退两级到项目根目录
        $composeFile = Join-Path $parentDir "docker-compose.yaml"

        # 从环境变量获取配置
        $imageName = Get-GlobalVar -Key "IMAGE_NAME"
        $registryUrl = Get-GlobalVar -Key "REGISTRY_URL"
        $containerName = Get-GlobalVar -Key "CONTAINER_NAME"
        $devUsername = Get-GlobalVar -Key "DEV_USERNAME"
        $workspaceRoot = Get-GlobalVar -Key "WORKSPACE_ROOT"
        $volumesRoot = Get-GlobalVar -Key "VOLUMES_ROOT"
        $timezone = Get-GlobalVar -Key "TIMEZONE"
        $workspaceEnableRemoteDebug = Get-GlobalVar -Key "WORKSPACE_ENABLE_REMOTE_DEBUG"
        $workspaceLogLevel = Get-GlobalVar -Key "WORKSPACE_LOG_LEVEL"
        $sshPort = Get-GlobalVar -Key "CLIENT_SSH_PORT"
        $gdbPort = Get-GlobalVar -Key "GDB_PORT"

        if (-not $workspaceRoot) {
            Write-Host "[ERROR] WORKSPACE_ROOT not configured in environment" -ForegroundColor Red
            return $false
        }

        # 构建完整的镜像名称
        $fullImageName = $imageName
        if ($registryUrl) {
            $fullImageName = "${registryUrl}/${imageName}"
        }
        $fullImageName = "${fullImageName}:latest"

        # 转换路径分隔符
        $volumePath = ($grandparentDir + "/volumes").Replace('\', '/')

        # 创建 docker-compose.yaml 内容
        $composeContent = @'
services:
  dev-env:
    image: {0}
    container_name: {1}
    hostname: {1}
    user: "{2}"
    restart: unless-stopped
    privileged: true
    tty: true
    stdin_open: true

    volumes:
      - "{3}:{4}"

    ports:
      - "{5}:22"
      - "{6}:2345"

    environment:
      - TIMEZONE={7}
      - WORKSPACE_ENABLE_REMOTE_DEBUG={8}
      - WORKSPACE_LOG_LEVEL={9}

    working_dir: {10}

    networks:
      - dev-net

networks:
  dev-net:
    driver: bridge
'@ -f $fullImageName, $containerName, $devUsername, $volumePath, $volumesRoot,
        $sshPort, $gdbPort, $timezone, $workspaceEnableRemoteDebug, $workspaceLogLevel, $workspaceRoot

        # 写入文件
        $composeContent | Set-Content $composeFile -Force -Encoding UTF8
        Write-Host "[INFO] Created docker-compose.yaml" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-Host "[ERROR] Failed to create docker-compose.yaml: $_" -ForegroundColor Red
        return $false
    }
}

# Export module members
Export-ModuleMember -Function Main, Fourth-*