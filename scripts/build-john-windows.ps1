# Download John the Ripper pre-built binaries for Windows
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "Downloading John the Ripper for Windows..." -ForegroundColor Cyan

$url = "https://www.openwall.com/john/k/john-1.9.0-jumbo-1-win64.zip"
$tempFile = Join-Path $env:TEMP "john-win64.zip"
$extractPath = Join-Path $env:TEMP "john-extract"
$outputDir = Join-Path $PSScriptRoot "../john/windows/run"
$johnRepoUrl = "https://github.com/openwall/john.git"
$johnCloneDir = Join-Path $env:TEMP "john-bleeding-jumbo"
$pdf2johnSrc = Join-Path $johnCloneDir "run/pdf2john.py"

try {
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
    
    # Strip unnecessary files to reduce package size
    Write-Host "Stripping unnecessary files..." -ForegroundColor Cyan
    $files = Get-ChildItem -Path $outputDir -Recurse -File
    if (-not $files -or $files.Count -eq 0) {
        throw "No files found in $outputDir - download or extraction may have failed"
    }
    $beforeSize = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
    
    $keepPatterns = @(
        'john.exe', 'zip2john.exe', 'pdf2john.py', 
        '*.conf', '*.chr',
        'cygwin1.dll', 'cygcrypto*.dll', 'cygssl*.dll', 'cygz.dll', 
        'cyggmp*.dll', 'cygcrypt*.dll', 'cyggcc_s*.dll', 'cygbz2*.dll', 'cyggomp*.dll',
        'cygOpenCL*.dll'
    )
    
    $allFiles = Get-ChildItem -Path $outputDir -File
    $filesToRemove = $allFiles | Where-Object {
        $file = $_
        $keep = $false
        foreach ($pattern in $keepPatterns) {
            if ($file.Name -like $pattern) {
                $keep = $true
                break
            }
        }
        -not $keep
    }
    
    $removedCount = 0
    foreach ($file in $filesToRemove) {
        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
        $removedCount++
    }
    
    $filesAfter = Get-ChildItem -Path $outputDir -Recurse -File
    if (-not $filesAfter -or $filesAfter.Count -eq 0) {
        throw "All files were removed from $outputDir - file removal logic may be incorrect"
    }
    $afterSize = ($filesAfter | Measure-Object -Property Length -Sum).Sum / 1MB
    $saved = $beforeSize - $afterSize
    
    Write-Host "Removed $removedCount files (saved $([math]::Round($saved, 2)) MB)" -ForegroundColor Green
    
    $fileCount = (Get-ChildItem $outputDir -Recurse -File).Count
    Write-Host "`nDownload completed successfully!" -ForegroundColor Green
    Write-Host "Kept $fileCount essential files ($([math]::Round($afterSize, 2)) MB) in: $outputDir" -ForegroundColor Green
    
}
catch {
    Write-Error "Failed to download John binaries: $_"
    Write-Host "`nYou can manually download from: $url" -ForegroundColor Yellow
    exit 1
}
finally {
    Write-Host "Cleaning up temporary files..." -ForegroundColor Cyan
    Remove-Item $johnCloneDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $tempFile -ErrorAction SilentlyContinue
    Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
}
