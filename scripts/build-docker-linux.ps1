#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [switch]$Run,
    [switch]$NoCache
)

function Start-Docker {
    [CmdletBinding()]
    param()

    # Check if Docker is already running and responsive
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Docker is already running" -ForegroundColor Green
        return
    }

    Write-Host "Docker is not running. Starting Docker Desktop..." -ForegroundColor Yellow

    # Check if Docker Desktop is installed
    $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (-not (Test-Path $dockerDesktopPath)) {
        Write-Host "Docker Desktop not found. Installing via winget..." -ForegroundColor Yellow

        # Install Docker Desktop using winget
        winget install Docker.DockerDesktop --silent --accept-source-agreements --accept-package-agreements

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install Docker Desktop"
            exit 1
        }

        Write-Host "Docker Desktop installed successfully" -ForegroundColor Green

        # Verify installation
        if (-not (Test-Path $dockerDesktopPath)) {
            Write-Error "Docker Desktop installation completed but executable not found at: $dockerDesktopPath"
            exit 1
        }
    }

    Start-Process $dockerDesktopPath

    # Wait for Docker to be ready (up to 90 seconds)
    $maxWaitTime = 90
    $waitedTime = 0
    Write-Host "Waiting for Docker to start..." -ForegroundColor Yellow

    while ($waitedTime -lt $maxWaitTime) {
        Start-Sleep -Seconds 3
        $waitedTime += 3

        # Check if Docker daemon is responding
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Docker is ready!" -ForegroundColor Green
            return
        }
    }

    Write-Error "Docker failed to start within $maxWaitTime seconds"
    exit 1
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DockerFilePath = Join-Path $RepoRoot "docker/Dockerfile.linux"
$DockerImageTag = "poshjohn-linux"

# Ensure Docker is running
Start-Docker

if ($NoCache) {
    docker build --no-cache -f $DockerFilePath -t $DockerImageTag .
}
else {
    docker build -f $DockerFilePath -t $DockerImageTag .
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

if ($Run) {
    docker run --rm -it $DockerImageTag pwsh
}
