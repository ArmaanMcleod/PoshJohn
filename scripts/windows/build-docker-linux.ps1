#!/usr/bin/env pwsh

[CmdletBinding(DefaultParameterSetName = 'Build')]
param(
    [Parameter(ParameterSetName = 'Run')]
    [switch]$Run,

    [Parameter(ParameterSetName = 'Test')]
    [switch]$Test,

    [Parameter(ParameterSetName = 'Run')]
    [ValidateSet('/bin/bash', 'pwsh')]
    [string]$Shell = '/bin/bash',

    [Parameter(ParameterSetName = 'Build')]
    [Parameter(ParameterSetName = 'Run')]
    [Parameter(ParameterSetName = 'Test')]
    [switch]$NoCache,

    [Parameter(ParameterSetName = 'Run')]
    [Parameter(ParameterSetName = 'Test')]
    [switch]$RemoveOnExit,

    [Parameter(ParameterSetName = 'Build')]
    [Parameter(ParameterSetName = 'Run')]
    [Parameter(ParameterSetName = 'Test')]
    [switch]$Prune,

    [Parameter(ParameterSetName = 'Build')]
    [Parameter(ParameterSetName = 'Test')]
    [switch]$CI
)

function Start-DockerWindows {
    [CmdletBinding()]
    param()

    # Check if Docker is already running and responsive
    Invoke-Docker "info" -SuppressOutput -IgnoreError
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
        Invoke-Winget "install Docker.DockerDesktop --silent --accept-source-agreements --accept-package-agreements"

        Write-Host "Docker Desktop installed successfully" -ForegroundColor Green

        # Verify installation
        if (-not (Test-Path $dockerDesktopPath)) {
            throw "Docker Desktop installation completed but executable not found at: $dockerDesktopPath"
        }
    }

    Start-Process $dockerDesktopPath

    # Wait for Docker to be ready (up to 90 seconds)
    $maxWaitTime = 90
    $waitedTime = 0
    Write-Host "Waiting for Docker to start..." -ForegroundColor Yellow

    while ($waitedTime -lt $maxWaitTime) {
        Write-Host "Checking Docker status... ($waitedTime/$maxWaitTime seconds elapsed)" -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        $waitedTime += 3

        # Check if Docker daemon is responding
        Invoke-Docker "info" -SuppressOutput -IgnoreError
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Docker is ready!" -ForegroundColor Green
            return
        }
    }

    throw "Docker failed to start within $maxWaitTime seconds"
}

$RepoRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.FullName

$DockerFilePath = Join-Path $RepoRoot "docker/Dockerfile.linux"
if (-not (Test-Path $DockerFilePath)) {
    throw "Dockerfile not found at: $DockerFilePath"
}

$DockerImageTag = "poshjohn-linux"

$helperModulePath = Join-Path -Path $RepoRoot -ChildPath "PowerShellBuildTools/tools/helper.psm1"
Import-Module $helperModulePath -Force

# Add checks for supported OS platforms
# TODO: Add more local support for other OS platforms
if ($CI) {
    if (-not $IsLinux) {
        throw "CI Docker builds are only supported on Linux agents currently."
    }
}
else {
    if (-not $IsWindows) {
        throw "Local Docker builds are only supported on Windows currently. Please run this script on a Windows machine."
    }

    Start-DockerWindows
}

Write-Host "Building Docker image '$DockerImageTag' from '$DockerFilePath'..." -ForegroundColor Cyan

try {
    Push-Location -Path $RepoRoot

    if ($Prune) {
        Write-Warning "Pruning unused Docker images, containers, networks, build cache and volumes..."
        Invoke-Docker "system prune -a --volumes"
    }

    $buildCommand = "build"

    if ($NoCache) {
        $buildCommand += " --no-cache"
    }

    $buildCommand += " -f ${DockerFilePath} -t ${DockerImageTag} ."

    Invoke-Docker $buildCommand

    $runCommand = "run"

    if ($RemoveOnExit) {
        $runCommand += " --rm"
    }
    if (-not $CI) {
        $runCommand += " -it"
    }

    $runCommand += " ${DockerImageTag}"

    if ($Run) {
        Write-Host "Running interactive PowerShell session in Docker container..." -ForegroundColor Cyan
        Invoke-Docker "${runCommand} ${Shell}"
    }
    elseif ($Test) {
        Write-Host "Running tests inside Docker container..." -ForegroundColor Cyan
        $buildScriptPathInContainer = "/PoshJohn/PowerShellBuildTools/build.ps1"
        Invoke-Docker "${runCommand} pwsh -File ${buildScriptPathInContainer} -Task TestPackage"
    }
}
finally {
    Pop-Location
}
