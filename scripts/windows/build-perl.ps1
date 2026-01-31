#!/usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

try {
    $LogPath = Join-Path $PSScriptRoot "build.log"
    Start-Transcript -Path $LogPath -Append

    Write-Host "Downloading Strawberry Perl for Windows..." -ForegroundColor Cyan

    $url = "https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_54201_64bit/strawberry-perl-5.42.0.1-64bit-portable.zip"

    $repoRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.FullName
    $helperModulePath = Join-Path -Path $repoRoot -ChildPath "PowerShellBuildTools/tools/helper.psm1"
    Import-Module $helperModulePath -Force

    $tempFile = Join-Path $env:TEMP "strawberry-perl.zip"
    $extractPath = Join-Path $env:TEMP "strawberry-perl-extract"
    $outputDir = Join-Path $repoRoot "strawberry-perl"

    # Download
    Write-Host "Downloading from: $url" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $tempFile -ErrorAction Stop

    # Extract
    Write-Host "Extracting to $extractPath..." -ForegroundColor Cyan
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    Expand-Archive -Path $tempFile -DestinationPath $extractPath -Force

    # Create output directory
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

    # Copy all files to output directory
    Write-Host "Copying all files to $outputDir..." -ForegroundColor Cyan
    Copy-Item "$extractPath/*" $outputDir -Recurse -Force

    Write-Host "Strawberry Perl downloaded and extracted successfully to $outputDir" -ForegroundColor Green

    # Build 7z2john.exe using PAR::Packer
    Write-Host "Building 7z2john.exe using PAR::Packer..." -ForegroundColor Cyan
    $parPackerPath = Join-Path $outputDir "perl\bin\pp.bat"
    $exeDirPath = Join-Path $outputDir "7z2john"
    New-Item -ItemType Directory -Force -Path $exeDirPath | Out-Null
    $exePath = Join-Path $exeDirPath "7z2john.exe"
    $perlScriptPath = Join-Path $repoRoot "john\7z2john.pl"
    cmd.exe /c "call $parPackerPath -o $exePath $perlScriptPath"

    # Define what to keep and remove non-essential files
    Remove-NonEssentialFiles -TargetDir $outputDir -KeepDirs @('7z2john')

    Write-Host "7z2john.exe built successfully at $exePath" -ForegroundColor Green
}
catch {
    Write-Error "Failed to download or extract Strawberry Perl: $_"
    Write-Host "`nYou can manually download from: $url" -ForegroundColor Yellow
    exit 1
}
finally {
    # Clean up temporary files
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    Stop-Transcript
}
