#!/usr/bin/env pwsh

param([switch]$ReBuild)

$ErrorActionPreference = "Stop"

try {

    $LogPath = Join-Path $PSScriptRoot "$($MyInvocation.MyCommand.Name.Split('.')[0]).log"
    Start-Transcript -Path $LogPath -Append

    # --- Basic paths -------------------------------------------------------------

    $MUPDF_REPO = "https://github.com/ArtifexSoftware/mupdf.git"
    $RepoPath = (Get-Item -Path $PSScriptRoot).Parent.Parent.FullName
    $MuPDFRepoDir = Join-Path $RepoPath "mupdf"
    $Pdf2JohnDir = Join-Path $RepoPath "src" "pdf2john"

    $helperModulePath = Join-Path -Path $RepoPath -ChildPath "PowerShellBuildTools/tools/helper.psm1"
    Import-Module $helperModulePath -Force

    Write-Host "REPO_PATH: $RepoPath"
    Write-Host "MUPDF_REPO_DIR: $MuPDFRepoDir"
    Write-Host "PDF2JOHN_DIR: $Pdf2JohnDir"

    if ($ReBuild -and (Test-Path $MuPDFRepoDir)) {
        Write-Host "Rebuild requested. Removing existing MuPDF directory..."
        Remove-Item -Recurse -Force $MuPDFRepoDir
    }

    # --- Clone MuPDF (no shallow clone, no submodules) --------------------------

    if (-not (Test-Path $MuPDFRepoDir)) {
        Write-Host "Cloning MuPDF into $MuPDFRepoDir..."
        Invoke-Git "clone $MUPDF_REPO $MuPDFRepoDir --depth 1"
    }
    else {
        Write-Host "MuPDF directory already exists at $MuPDFRepoDir. Skipping clone."
    }

    # Ensure Git LFS assets (fonts, etc.) are present and submodules updated
    Push-Location $MuPDFRepoDir
    try {
        Write-Host "Ensuring Git LFS assets are pulled and submodules are updated..."
        Invoke-Git "submodule update --init --recursive --depth 1"
        Invoke-Git "lfs install"
        Invoke-Git "lfs pull"
    }
    finally {
        Pop-Location
    }

    # --- Path conversion for MSYS2 ----------------------------------------------

    $MuPDFRepoDirMsys = Convert-ToMsysPath $MuPDFRepoDir
    $Pdf2JohnDirMsys = Convert-ToMsysPath $Pdf2JohnDir

    # --- MSYS2 / MinGW64 bootstrap ----------------------------------------------

    Write-Host "Starting MinGw Bootstrap..."
    Start-MinGwBootstrap

    # --- Build MuPDF ------------------------------------------------------------

    $procCount = [Environment]::ProcessorCount

    Write-Host "Running MuPDF resource generation in MinGW64 environment..."
    Invoke-Mingw64 "cd $MuPDFRepoDirMsys && make generate"

    Write-Host "Running MuPDF build in MinGW64 environment..."
    Invoke-Mingw64 "cd $MuPDFRepoDirMsys && CC=/mingw64/bin/gcc make -j$procCount build=release XCFLAGS='-msse4.1' libs"

    Write-Host "MuPDF build completed."

    # --- Build pdf2john using the same environment -------------------------

    Write-Host "Cleaning pdf2john build..."
    Invoke-Mingw64 "cd $Pdf2JohnDirMsys && make clean" -IgnoreError

    Write-Host "Building pdf2john in MinGW64 environment..."
    Invoke-Mingw64 "cd $Pdf2JohnDirMsys && CC=/mingw64/bin/gcc make -j$procCount"

    Write-Host "pdf2john build completed."
}
catch {
    Write-Error "An error occurred during the pdf2john build process: $_"
    exit 1
}
finally {
    Stop-Transcript
}
