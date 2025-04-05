function Second-CheckWSL2 {
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ACTION REQUIRED] Please install WSL and Ubuntu from Microsoft Store" -ForegroundColor Yellow
        Write-Host "1. Open Microsoft Store" -ForegroundColor Yellow
        Write-Host "2. Search and install 'Windows Subsystem for Linux'" -ForegroundColor Yellow
        Write-Host "3. Search and install 'Ubuntu'" -ForegroundColor Yellow
        Write-Host "4. Restart your computer after installation" -ForegroundColor Yellow
        return $false
    }

    if ($wslStatus -notmatch "Default Version: 2") {
        Write-Host "[INFO] Setting WSL2 as default version..." -ForegroundColor Yellow
        wsl --set-default-version 2
    }

    return $true
}

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

function Second-EnvironmentCheck {
    # Check system requirements first
    if (-not (Second-CheckSystemRequirements)) {
        return $false
    }

    # Check Docker Desktop installation
    $dockerService = Get-Service "com.docker.service" -ErrorAction SilentlyContinue
    if (-not $dockerService) {
        Write-Host "[ACTION REQUIRED] Please install Docker Desktop manually" -ForegroundColor Yellow
        Write-Host "1. Visit https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        Write-Host "2. Download and install Docker Desktop" -ForegroundColor Yellow
        Write-Host "3. Restart your computer after installation" -ForegroundColor Yellow
        return $false
    }

    # Check WSL2 status
    if (-not (Second-CheckWSL2)) {
        Write-Host "[INFO] Please follow the steps above to install WSL2 and restart" -ForegroundColor Yellow
        return $false
    }

    # Start Docker service if not running
    if ($dockerService.Status -ne 'Running') {
        Write-Host "[INFO] Starting Docker Desktop service..." -ForegroundColor Yellow
        Start-Service "com.docker.service" -ErrorAction Stop
        Start-Sleep -Seconds 10  # Give service time to start
    }

    # Verify Docker engine response
    $retries = 30
    while ($retries -gt 0) {
        $null = docker info 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[SUCCESS] Docker Desktop service started successfully!" -ForegroundColor Green
            return $true
        }
        Write-Host "[INFO] Waiting for Docker to start..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        $retries--
    }
    Write-Host "[ERROR] Docker service start timeout!" -ForegroundColor Red
    return $false
}

# Export module members
Export-ModuleMember -Function Second-EnvironmentCheck, Second-CheckWSL2, Second-CheckSystemRequirements