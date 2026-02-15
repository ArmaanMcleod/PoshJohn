#!/usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Building all components for Windows" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Build John the Ripper
Write-Host ""
Write-Host "==> Building John the Ripper..." -ForegroundColor Yellow
& "$PSScriptRoot\build-john.ps1"
if ($LASTEXITCODE -ne 0) { throw "John build failed" }

# Build pdf2john
Write-Host ""
Write-Host "==> Building pdf2john..." -ForegroundColor Yellow
& "$PSScriptRoot\build-pdf2john.ps1"
if ($LASTEXITCODE -ne 0) { throw "pdf2john build failed" }

# Build 7z2john
Write-Host ""
Write-Host "==> Building 7z2john..." -ForegroundColor Yellow
& "$PSScriptRoot\build-7z2john.ps1"
if ($LASTEXITCODE -ne 0) { throw "7z2john build failed" }

# Build archive7z
Write-Host ""
Write-Host "==> Building archive7z..." -ForegroundColor Yellow
& "$PSScriptRoot\build-archive7z.ps1"
if ($LASTEXITCODE -ne 0) { throw "archive7z build failed" }

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "All builds completed successfully!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
