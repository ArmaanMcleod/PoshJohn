#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$RepoPath = (Get-Item -Path $PSScriptRoot).Parent.Parent.FullName
$bit7zDir = Join-Path $RepoPath "bit7z"
$bit7zRepo = "https://github.com/rikyoz/bit7z.git"

# Clone bit7z if not present
if (-not (Test-Path $bit7zDir)) {
    Write-Host "Cloning bit7z repository..."
    git clone $bit7zRepo $bit7zDir --depth 1
}
else {
    Write-Host "bit7z directory already exists, skipping clone."
}

$helperModulePath = Join-Path -Path $RepoPath -ChildPath "PowerShellBuildTools/tools/helper.psm1"
Import-Module $helperModulePath -Force

Write-Host "Building bit7z in MinGW64 environment..."
Write-Host "Starting MinGW bootstrap..."
Start-MinGwBootstrap
$bit7zMsysPath = Convert-ToMsysPath $bit7zDir
Invoke-Mingw64 "cd $bit7zMsysPath && mkdir -p build && cd build && cmake ../ && cmake --build ."
Write-Host "bit7z built successfully."
