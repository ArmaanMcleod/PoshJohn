# Download John the Ripper pre-built binaries for Windows
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "Downloading John the Ripper for Windows..." -ForegroundColor Cyan

$url = "https://www.openwall.com/john/k/john-1.9.0-jumbo-1-win64.zip"
$tempFile = Join-Path $env:TEMP "john-win64.zip"
$extractPath = Join-Path $env:TEMP "john-extract"
$outputDir = Join-Path $PSScriptRoot "..\john-binaries\windows"

try {
    # Download
    Write-Host "Downloading from: $url" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $tempFile -ErrorAction Stop
    
    # Extract
    Write-Host "Extracting..." -ForegroundColor Cyan
    if (Test-Path $extractPath) {
        Remove-Item $extractPath -Recurse -Force
    }
    Expand-Archive -Path $tempFile -DestinationPath $extractPath -Force
    
    # Create output directory
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    
    # Copy all files from the run directory
    Write-Host "Copying all files to $outputDir..." -ForegroundColor Cyan
    $runDir = "$extractPath\john-1.9.0-jumbo-1-win64\run"
    Copy-Item "$runDir\*" $outputDir -Recurse -Force
    
    # Cleanup
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    
    $fileCount = (Get-ChildItem $outputDir -Recurse -File).Count
    Write-Host "`nDownload completed successfully!" -ForegroundColor Green
    Write-Host "Copied $fileCount files to: $outputDir" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to download John binaries: $_"
    Write-Host "`nYou can manually download from: $url" -ForegroundColor Yellow
    exit 1
}
