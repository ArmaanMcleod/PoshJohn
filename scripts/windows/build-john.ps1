#!/usr/bin/env pwsh

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

try {
    $LogPath = Join-Path $PSScriptRoot "build.log"
    Start-Transcript -Path $LogPath -Append

    Write-Host "Downloading John the Ripper for Windows..." -ForegroundColor Cyan

    $url = "https://www.openwall.com/john/k/john-1.9.0-jumbo-1-win64.zip"
    $cacheDir = Join-Path $env:LOCALAPPDATA "PoshJohn"
    if (!(Test-Path $cacheDir)) { 
        New-Item -ItemType Directory -Path $cacheDir | Out-Null 
    }
    $archiveName = Split-Path $url -Leaf
    $cachedArchive = Join-Path $cacheDir $archiveName
    $extractPath = Join-Path $env:TEMP ("john-extract-" + [guid]::NewGuid().ToString())
    $repoRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.FullName
    $outputDir = Join-Path $repoRoot "john"
    $johnRepoUrl = "https://github.com/openwall/john.git"
    $johnCloneDir = Join-Path $env:TEMP "john-bleeding-jumbo"
    $pdf2johnSrc = Join-Path $johnCloneDir "run/pdf2john.py"

    $repoRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.FullName
    $helperModulePath = Join-Path -Path $repoRoot -ChildPath "PowerShellBuildTools/tools/helper.psm1"
    Import-Module $helperModulePath -Force

    # Download or use cached archive
    if (!(Test-Path $cachedArchive)) {
        Write-Host "Downloading from: $url" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $cachedArchive -ErrorAction Stop
    }
    else {
        Write-Host "Using cached John archive from $cachedArchive" -ForegroundColor Green
    }

    # Extract
    Write-Host "Extracting to $extractPath..." -ForegroundColor Cyan
    Expand-Archive -Path $cachedArchive -DestinationPath $extractPath -Force

    # Create output directory
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

    # Copy all files from the run directory
    Write-Host "Copying all files to $outputDir..." -ForegroundColor Cyan
    $runDir = "$extractPath/john-1.9.0-jumbo-1-win64/run"
    Copy-Item "$runDir/*" $outputDir -Recurse -Force

    # Clone John the Ripper repo and copy pdf2john.py
    Write-Host "Cloning John the Ripper repo to get pdf2john.py..." -ForegroundColor Cyan
    git clone --depth 1 $johnRepoUrl $johnCloneDir

    if (Test-Path $pdf2johnSrc) {
        Write-Host "Copying pdf2john.py to $outputDir..." -ForegroundColor Cyan
        Copy-Item $pdf2johnSrc $outputDir -Force
    }
    else {
        Write-Warning "pdf2john.py not found in cloned repo at $pdf2johnSrc"
    }

    # Define what to keep
    $keepFilePatterns = @('john.exe', 'zip2john.exe', 'pdf2john.py', '*.conf', '*.chr', '*.dll', '7z2john.pl')
    $keepDirs = @('lib', 'rules')
    Remove-NonEssentialFiles -TargetDir $outputDir -KeepFilePatterns $keepFilePatterns -KeepDirs $keepDirs

    Write-Host "John the Ripper downloaded and extracted successfully to $outputDir" -ForegroundColor Green
}
catch {
    Write-Error "Failed to download John binaries: $_"
    Write-Host "`nYou can manually download from: $url" -ForegroundColor Yellow
    exit 1
}
finally {
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
    Remove-Item $johnCloneDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    Stop-Transcript
}
