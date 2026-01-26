#!/usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "Download LZMA SDK for Windows..." -ForegroundColor Cyan

$url = "https://7-zip.org/a/lzma2501.7z"

$tempFile = Join-Path $env:TEMP "lzma2501.7z"
$extractPath = Join-Path $env:TEMP "lzma2501-extract"
$outputDir = Join-Path $PSScriptRoot "../lzma-sdk"


try {
    # Download
    Write-Host "Downloading from: $url" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $tempFile -ErrorAction Stop

    # Extract
    Write-Host "Extracting to $extractPath..." -ForegroundColor Cyan
    7z.exe x $tempFile "-o$extractPath" -y | Out-Null

    # Create output directory
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

    # Copy all files to output directory
    Write-Host "Copying all files to $outputDir..." -ForegroundColor Cyan
    Copy-Item "$extractPath/*" $outputDir -Recurse -Force

    Write-Host "LZMA SDK downloaded and extracted successfully to $outputDir" -ForegroundColor Green
}
catch {
    Write-Error "Failed to download or extract LZMA SDK: $_"
    Write-Host "`nYou can manually download from: $url" -ForegroundColor Yellow
    exit 1
}
finally {
    # Clean up temporary files
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
}
