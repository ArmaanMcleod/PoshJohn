$dllPath = Join-Path -Path $PSScriptRoot -ChildPath 'PoshJohn.dll'
Import-Module $dllPath

# Set execute permissions on all files in the run directory (Linux/macOS only)
if ($IsLinux) {
    $runDir = Join-Path $PSScriptRoot 'john/linux/run'
    if (Test-Path $runDir) {
        Get-ChildItem $runDir | ForEach-Object {
            & chmod +x $_.FullName
        }
    }
}
if ($IsMacOS) {
    $runDir = Join-Path $PSScriptRoot 'john/macos/run'
    if (Test-Path $runDir) {
        Get-ChildItem $runDir | ForEach-Object {
            & chmod +x $_.FullName
        }
    }
}
