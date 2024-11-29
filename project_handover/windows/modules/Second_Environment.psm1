<#
.SYNOPSIS
    Environment Check Module for Docker Development Environment
.DESCRIPTION
    Handles all environment-related checks and installations including
    WSL2, Docker Desktop, and system requirements verification.
.NOTES
    File Name      : Second_Environment.psm1
    Version        : 0.5.1
    Author         : MrJamesLZA
    Last Modified  : 2024-11-29
#>

<#
.SYNOPSIS
    Checks if WSL2 is installed and enabled
.DESCRIPTION
    Verifies WSL2 installation status and enables required features
.OUTPUTS
    Boolean indicating if WSL2 is properly configured
.EXAMPLE
    Second-CheckWSL2
#>
function Second-CheckWSL2 {
    try {
        # Check if WSL is installed
        $wslStatus = wsl --status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[INFO] Installing WSL..." -ForegroundColor Yellow

            # Enable WSL feature
            $process = Start-Process -FilePath "dism.exe" -ArgumentList "/online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -ne 0) {
                Write-Host "[ERROR] Failed to enable WSL feature" -ForegroundColor Red
                return $false
            }

            # Enable Virtual Machine feature
            $process = Start-Process -FilePath "dism.exe" -ArgumentList "/online /enable-feature /featurename:VirtualMachinePlatform /all /norestart" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -ne 0) {
                Write-Host "[ERROR] Failed to enable Virtual Machine Platform" -ForegroundColor Red
                return $false
            }

            # Download and install WSL2 kernel update
            Write-Host "[INFO] Downloading WSL2 kernel update..." -ForegroundColor Yellow
            $wslUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
            $wslUpdateFile = Join-Path $env:TEMP "wsl_update_x64.msi"
            Invoke-WebRequest -Uri $wslUpdateUrl -OutFile $wslUpdateFile

            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$wslUpdateFile`" /quiet" -Wait -PassThru
            if ($process.ExitCode -ne 0) {
                Write-Host "[ERROR] Failed to install WSL2 kernel update" -ForegroundColor Red
                return $false
            }

            # Set WSL2 as default
            wsl --set-default-version 2

            Write-Host "[SUCCESS] WSL2 installation completed. System restart required." -ForegroundColor Green
            return $false
        }

        # Check if WSL2 is the default version
        if ($wslStatus -notmatch "Default Version: 2") {
            Write-Host "[INFO] Setting WSL2 as default version..." -ForegroundColor Yellow
            wsl --set-default-version 2
        }

        return $true
    }
    catch {
        Write-Host "[ERROR] WSL2 check failed: $_" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    Checks system requirements for Docker Desktop
.DESCRIPTION
    Verifies if the system meets all requirements for Docker Desktop
.OUTPUTS
    Boolean indicating if system meets requirements
.EXAMPLE
    Second-CheckSystemRequirements
#>
function Second-CheckSystemRequirements {
    # Check Windows version
    $osInfo = Get-WmiObject -Class Win32_OperatingSystem
    $version = [Version]$osInfo.Version
    if ($version.Major -lt 10) {
        Write-Host "[ERROR] Windows 10/11 is required for Docker Desktop" -ForegroundColor Red
        return $false
    }

    # Check Windows build number for WSL2 support
    if ($version.Build -lt 18362) {
        Write-Host "[ERROR] Windows 10 version 1903 or higher is required for WSL2" -ForegroundColor Red
        return $false
    }

    # Check system architecture
    if ((Get-WmiObject Win32_Processor).Architecture -ne 9) {
        Write-Host "[ERROR] 64-bit processor is required for Docker Desktop" -ForegroundColor Red
        return $false
    }

    # Check system memory
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    if ([math]::Round($memory.TotalPhysicalMemory / 1GB) -lt 4) {
        Write-Host "[ERROR] At least 4GB of RAM is required for Docker Desktop" -ForegroundColor Red
        return $false
    }

    # Check virtualization support
    $hyperv = Get-WmiObject -Class Win32_ComputerSystem
    if ($hyperv.HypervisorPresent -ne $true) {
        Write-Host "[ERROR] Hardware virtualization must be enabled in BIOS" -ForegroundColor Red
        return $false
    }

    return $true
}

<#
.SYNOPSIS
    Installs Docker Desktop silently
.DESCRIPTION
    Downloads and installs Docker Desktop with minimal user interaction
.OUTPUTS
    Boolean indicating if installation was successful
.EXAMPLE
    Second-InstallDockerDesktop
#>
function Second-InstallDockerDesktop {
    try {
        $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        $tempDir = Join-Path $PSScriptRoot "temp"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir | Out-Null
        }
        $installerPath = Join-Path $tempDir "DockerDesktopInstaller.exe"

        Write-Host "[INFO] Downloading Docker Desktop installer..." -ForegroundColor Yellow
        Write-Host "[INFO] Download URL: $dockerUrl" -ForegroundColor Yellow
        Write-Host "[INFO] Target path: $installerPath" -ForegroundColor Yellow
        Write-Host "[INFO] This may take several minutes depending on your internet connection..." -ForegroundColor Yellow

        # 获取文件大小
        $response = [System.Net.HttpWebRequest]::Create($dockerUrl).GetResponse()
        $totalBytes = $response.ContentLength
        $response.Close()

        $totalMB = [Math]::Round($totalBytes / 1MB, 2)
        Write-Host "[INFO] Total file size: $totalMB MB" -ForegroundColor Yellow

        # 使用 BitsTransfer 来下载（支持进度显示和取消）
        $job = Start-BitsTransfer -Source $dockerUrl -Destination $installerPath -Asynchronous

        # 监控下载进度
        while (($job.JobState -eq "Transferring") -or ($job.JobState -eq "Connecting")) {
            Write-Progress -Activity "Downloading Docker Desktop" `
                         -Status "Downloaded: $([Math]::Round($job.BytesTransferred / 1MB, 2)) MB of $totalMB MB" `
                         -PercentComplete ($job.BytesTransferred / $totalBytes * 100)

            # 显示当前进度
            Write-Host "`r[INFO] Progress: $([Math]::Round($job.BytesTransferred / $totalBytes * 100, 2))% ($([Math]::Round($job.BytesTransferred / 1MB, 2)) MB / $totalMB MB)" -NoNewline -ForegroundColor Yellow

            # 检查是否按下 Ctrl+C
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'C' -and $key.Modifiers -eq 'Control') {
                    Remove-BitsTransfer $job
                    Write-Host "`n[INFO] Download cancelled by user" -ForegroundColor Yellow
                    return $false
                }
            }

            Start-Sleep -Milliseconds 500
        }

        # 完成下载
        Complete-BitsTransfer $job
        Write-Host "`n[SUCCESS] Download completed!" -ForegroundColor Green

        if (Test-Path $installerPath) {
            Write-Host "[INFO] Starting Docker Desktop installation..." -ForegroundColor Yellow
            Start-Process $installerPath -ArgumentList "install --quiet" -Wait
            Write-Host "[SUCCESS] Docker Desktop installation completed!" -ForegroundColor Green

            # 清理下载文件和临时目录
            Write-Host "[INFO] Cleaning up temporary files..." -ForegroundColor Yellow
            Remove-Item $installerPath -Force
            if ((Get-ChildItem $tempDir).Count -eq 0) {
                Remove-Item $tempDir -Force
            }
            Write-Host "[SUCCESS] Cleanup completed!" -ForegroundColor Green

            return $true
        }
    }
    catch {
        Write-Host "[ERROR] Failed to install Docker Desktop: $_" -ForegroundColor Red
        return $false
    }
    return $false
}

<#
.SYNOPSIS
    Main environment check function
.DESCRIPTION
    Coordinates all environment checks and installations
.OUTPUTS
    Boolean indicating if environment is properly configured
.EXAMPLE
    Main
#>
function Second-EnvironmentCheck {
    # Check system requirements first
    if (-not (Second-CheckSystemRequirements)) {
        return $false
    }

    # Check and install WSL2
    if (-not (Second-CheckWSL2)) {
        Write-Host "[INFO] Please restart your computer and run the script again." -ForegroundColor Yellow
        return $false
    }

    # 修改 Docker 检查部分
    # 检查 Docker Desktop 是否已安装
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (-not (Test-Path $dockerPath)) {
        Write-Host "[INFO] Docker Desktop not found. Starting installation..." -ForegroundColor Yellow
        if (-not (Second-InstallDockerDesktop)) {
            return $false
        }
        Write-Host "[INFO] Please restart your computer to complete Docker installation." -ForegroundColor Yellow
        return $false
    }

    # 检查 Docker 服务
    try {
        # 使用完整路径检查 docker 命令
        $dockerCli = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
        if (-not (Test-Path $dockerCli)) {
            throw "Docker CLI not found"
        }

        # 启动 Docker Desktop
        Write-Host "[INFO] Starting Docker Desktop..." -ForegroundColor Yellow
        Start-Process $dockerPath -ErrorAction Stop

        # 等待 Docker 启动
        $retries = 30
        while ($retries -gt 0) {
            try {
                & $dockerCli info | Out-Null
                Write-Host "[SUCCESS] Docker service started successfully!" -ForegroundColor Green
                return $true
            } catch {
                Write-Host "[INFO] Waiting for Docker to start..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
                $retries--
            }
        }
        Write-Host "[ERROR] Docker service start timeout!" -ForegroundColor Red
        return $false
    }
    catch {
        Write-Host "[ERROR] Failed to start Docker: $_" -ForegroundColor Red
        return $false
    }
}

# Export module members
Export-ModuleMember -Function Second-EnvironmentCheck, Second-CheckWSL2, Second-CheckSystemRequirements, Second-InstallDockerDesktop