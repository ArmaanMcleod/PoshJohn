$ErrorActionPreference = "Stop"

$MUPDF_REPO = "https://github.com/ArtifexSoftware/mupdf.git"
$RepoPath = Split-Path -Parent $PSScriptRoot
$MuPDFRepoDir = Join-Path $RepoPath "mupdf"
$Pdf2JohnDir = Join-Path $RepoPath "src" "pdf2john"

Write-Host "REPO_PATH: $RepoPath"
Write-Host "MUPDF_REPO_DIR: $MuPDFRepoDir"

# Clone MuPDF only if directory does not exist
if (-not (Test-Path $MuPDFRepoDir)) {
    Write-Host "Cloning MuPDF into $MuPDFRepoDir..."
    git clone --depth 1 $MUPDF_REPO $MuPDFRepoDir
}
else {
    Write-Host "MuPDF directory already exists at $MuPDFRepoDir. Skipping clone."
}

# Convert Windows path to MSYS2 path
function Convert-ToMsysPath($winPath) {
    $msysPath = $winPath -replace '\\', '/'
    if ($msysPath -match '^([A-Za-z]):') {
        $drive = $matches[1].ToLower()
        $rest = $msysPath.Substring(2)
        return "/$drive$rest"
    }
    return $msysPath
}

$MuPDFRepoDirMsys = Convert-ToMsysPath $MuPDFRepoDir
$Pdf2JohnDirMsys = Convert-ToMsysPath $Pdf2JohnDir

# Use bash.exe (MSYS environment)
$bash = "C:\msys64\usr\bin\bash.exe"

# Required MinGW64 packages
$packages = @(
    'gcc'
    'make'
    'pkg-config'
)
$pkgList = $packages -join " "

Write-Host "Ensuring MSYS2 MinGW64 packages are installed..."
& $bash -lc "pacman -S --needed --noconfirm $pkgList"

# Build
try {
    Push-Location $MuPDFRepoDir
    Write-Host "Building MuPDF..."
    git submodule update --init --recursive --depth 1

    $procCount = [Environment]::ProcessorCount

    Write-Host "Running MuPDF build in MinGW64 environment..."
    & $bash -lc "cd $MuPDFRepoDirMsys; make -j$procCount build=release XCFLAGS='-msse4.1' libs"

    Write-Host "MuPDF build completed."

    Write-Host "Building pdf2john..."
    & $bash -lc "cd $Pdf2JohnDirMsys; make -j$procCount pdfhash.dll"

    Write-Host "pdf2john build completed."
}
finally {
    Pop-Location
}
