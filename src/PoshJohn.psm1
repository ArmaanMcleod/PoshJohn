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
            $file = Get-Item $binPath

            # Only chmod if not already executable by user, group, and others
            # 0o111 = 73 decimal, so check all three execute bits
            if (($file.UnixMode -band 73) -ne 73) {
                & chmod +x $file.FullName
            }
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
