#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$RepoPath = Split-Path -Parent $PSScriptRoot
$bit7zDir = Join-Path $RepoPath "bit7z"
$helperModulePath = Join-Path -Path $RepoPath -ChildPath "PowerShellBuildTools/tools/helper.psm1"
Import-Module $helperModulePath -Force

Write-Log "Building bit7z in MinGW64 environment..."
Write-Log "Starting MinGW bootstrap..."
Start-MinGwBootstrap
$bit7zMsysPath = Convert-ToMsysPath $bit7zDir
Invoke-Mingw64 "cd $bit7zMsysPath && mkdir -p build && cd build && cmake ../ && cmake --build ."
Write-Log "bit7z built successfully."
