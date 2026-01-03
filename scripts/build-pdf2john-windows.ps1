#!/usr/bin/env pwsh

param([switch]$ReBuild)

$ErrorActionPreference = "Stop"

# --- Basic paths -------------------------------------------------------------

$MUPDF_REPO = "https://github.com/ArtifexSoftware/mupdf.git"
$RepoPath   = Split-Path -Parent $PSScriptRoot
$MuPDFRepoDir = Join-Path $RepoPath "mupdf"
$Pdf2JohnDir  = Join-Path $RepoPath "src" "pdf2john"

$helperModulePath = Join-Path -Path $RepoPath -ChildPath "PowerShellBuildTools/tools/helper.psm1"
Import-Module $helperModulePath -Force

Write-Host "REPO_PATH: $RepoPath"
Write-Host "MUPDF_REPO_DIR: $MuPDFRepoDir"

if ($ReBuild -and (Test-Path $MuPDFRepoDir)) {
    Write-Host "Rebuild requested. Removing existing MuPDF directory..."
    Remove-Item -Recurse -Force $MuPDFRepoDir
}

# --- Clone MuPDF (no shallow clone, no submodules) --------------------------

if (-not (Test-Path $MuPDFRepoDir)) {
    Write-Host "Cloning MuPDF into $MuPDFRepoDir..."
    Invoke-Git "clone $MUPDF_REPO $MuPDFRepoDir --depth 1"
} else {
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
$Pdf2JohnDirMsys  = Convert-ToMsysPath $Pdf2JohnDir

# --- MSYS2 / MinGW64 bootstrap ----------------------------------------------

$msys2Root = "C:\msys64"
$envExe    = Join-Path $msys2Root "usr\bin\env.exe"

if (-not (Test-Path $envExe)) {
    Write-Host "MSYS2 not found at $msys2Root. Installing via winget..."
    Invoke-Winget "install -e --id MSYS2.MSYS2"
}

if (-not (Test-Path $envExe)) {
    throw "MSYS2 installation not found at $envExe even after install attempt."
}

# --- Ensure required MinGW64 packages ---------------------------------------

$packages = @(
    'mingw-w64-x86_64-pkg-config'
    'mingw-w64-x86_64-gcc'
    'mingw-w64-x86_64-make'
    'mingw-w64-x86_64-python'
)

$pkgList = $packages -join " "

Write-Host "Ensuring MSYS2 MinGW64 packages are installed..."
Invoke-Mingw64 "pacman --needed --noconfirm -S $pkgList"

# --- Build MuPDF ------------------------------------------------------------

$procCount = [Environment]::ProcessorCount

Write-Host "Running MuPDF resource generation in MinGW64 environment..."
Invoke-Mingw64 "cd $MuPDFRepoDirMsys && mingw32-make generate"

Write-Host "Running MuPDF build in MinGW64 environment..."
Invoke-Mingw64 "cd $MuPDFRepoDirMsys && CC=/mingw64/bin/gcc mingw32-make -j$procCount build=release XCFLAGS='-msse4.1' libs"

Write-Host "MuPDF build completed."

# --- Build pdf2john using the same environment -------------------------

Write-Host "Cleaning pdf2john build..."
Invoke-Mingw64 "cd $Pdf2JohnDirMsys && mingw32-make clean" -IgnoreError

Write-Host "Building libpdfhash.dll..."
Invoke-Mingw64 "cd $Pdf2JohnDirMsys && CC=/mingw64/bin/gcc mingw32-make -j$procCount libpdfhash.dll"

Write-Host "Building pdf2john.exe..."
Invoke-Mingw64 "cd $Pdf2JohnDirMsys && CC=/mingw64/bin/gcc mingw32-make -j$procCount"

Write-Host "pdf2john build completed."
