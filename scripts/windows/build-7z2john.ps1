#!/usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

try {

    $LogPath = Join-Path $PSScriptRoot "build.log"
    Start-Transcript -Path $LogPath -Append

    $repoRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.FullName

    Write-Host "Building 7z2john.exe..." -ForegroundColor Cyan
    $outputDir = Join-Path $repoRoot "perl\7z2john"
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    
    $exePath = Join-Path $outputDir "7z2john.exe"
    $perlScriptPath = Join-Path $repoRoot "john\7z2john.pl"

    $helperModulePath = Join-Path -Path $repoRoot -ChildPath "PowerShellBuildTools/tools/helper.psm1"
    Import-Module $helperModulePath -Force

    # Check if perl is available
    $perlCommand = Get-Command perl -ErrorAction SilentlyContinue
    if (-not $perlCommand) {
        Write-Host "Perl not found. Installing Strawberry Perl via winget..." -ForegroundColor Cyan
        Invoke-Winget -Command "install StrawberryPerl.StrawberryPerl --silent --accept-source-agreements --accept-package-agreements"
    }

    Invoke-PerlParPacker -Command "-o $exePath $perlScriptPath"

    Write-Host "7z2john.exe built successfully at $exePath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to build 7z2john.exe: $_"
    exit 1
}
finally {
    Stop-Transcript
}
