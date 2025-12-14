$dllPath = Join-Path -Path $PSScriptRoot -ChildPath 'PoshJohn.dll'
Import-Module $dllPath

# Only set execute permissions on 'john' and 'zip2john' binaries (Linux/macOS only)
$private:SetBinariesExecutable = {
    param(
        [string]$runDir,
        [string[]]$binaries = @('john', 'zip2john')
    )
    if (Test-Path $runDir -PathType Container) {
        foreach ($bin in $binaries) {
            $binPath = Join-Path $runDir $bin
            if (Test-Path $binPath -PathType Leaf) {
                & chmod +x $binPath
            }
        }
    }
}

if ($IsLinux) {
    $runDir = Join-Path $PSScriptRoot 'john/linux/run'
    & $SetBinariesExecutable -runDir $runDir
}

if ($IsMacOS) {
    $runDir = Join-Path $PSScriptRoot 'john/macos/run'
    & $SetBinariesExecutable -runDir $runDir
}
