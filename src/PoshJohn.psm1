$dllPath = Join-Path -Path $PSScriptRoot -ChildPath 'PoshJohn.dll'
Import-Module $dllPath

# Only set execute permissions on 'john' and 'zip2john' binaries (Linux/macOS only)
function Set-BinariesExecutable {
    param(
        [string]$runDir,
        [string[]]$binaries = @('john', 'zip2john')
    )

    foreach ($bin in $binaries) {
        $binPath = Join-Path $runDir $bin

        if (Test-Path $binPath -PathType Leaf) {
            & chmod +x $binPath
        }
    }
}

if ($IsLinux) {
    $runDir = Join-Path $PSScriptRoot 'john/linux/run'
    if (Test-Path $runDir) {
        Set-BinariesExecutable -runDir $runDir
    }
}

if ($IsMacOS) {
    $runDir = Join-Path $PSScriptRoot 'john/macos/run'
    if (Test-Path $runDir) {
        Set-BinariesExecutable -runDir $runDir
    }
}
