#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

try {
    $LogPath = Join-Path $PSScriptRoot "build.log"
    Start-Transcript -Path $LogPath -Append

    $RepoPath = (Get-Item -Path $PSScriptRoot).Parent.Parent.FullName

    $bit7zDir = Join-Path $RepoPath "bit7z"
    $repack7zDir = Join-Path $RepoPath "src" "repack7z"
    $bit7zRepo = "https://github.com/rikyoz/bit7z.git"

    Write-Host "repack7z directory: $repack7zDir"
    Write-Host "bit7z directory: $bit7zDir"

    # Clone bit7z if not present
    if (-not (Test-Path $bit7zDir)) {
        Write-Host "Cloning bit7z repository..."
        git clone $bit7zRepo $bit7zDir --depth 1
        Write-Host "bit7z repository cloned."
    }
    else {
        Write-Host "bit7z directory already exists, skipping clone."
    }

    $helperModulePath = Join-Path -Path $RepoPath -ChildPath "PowerShellBuildTools/tools/helper.psm1"
    Write-Host "Importing helper module from $helperModulePath"
    Import-Module $helperModulePath -Force
    Write-Host "Helper module imported."

    Write-Host "Building repack7z in MinGW64 environment..."
    Write-Host "Starting MinGW bootstrap..."
    Start-MinGwBootstrap
    Write-Host "MinGW bootstrap complete."
    $repack7zMsysPath = Convert-ToMsysPath $repack7zDir
    Write-Host "repack7z MSYS2 path: $repack7zMsysPath"
    
    # Clean existing CMake build directory to avoid path mismatch issues
    $buildDir = Join-Path $repack7zDir "build"
    if (Test-Path $buildDir) {
        Write-Host "Cleaning existing CMake build directory..."
        Remove-Item -Path $buildDir -Recurse -Force
    }
    
    Write-Host "Running CMake and build in MSYS2..."
    Invoke-Mingw64 "cd $repack7zMsysPath && mkdir -p build && cd build && cmake ../ && cmake --build ."
    Write-Host "repack7z built successfully."
}
catch {
    Write-Error "An error occurred during the repack7z build process: $_"
    exit 1
}
finally {
    Stop-Transcript
}
