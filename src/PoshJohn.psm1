$dllPath = Join-Path -Path $PSScriptRoot -ChildPath 'PoshJohn.dll'
Import-Module $dllPath

# Download John the Ripper assets from GitHub releases
function Install-JohnAssets {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AssetName,

        [Parameter(Mandatory = $true)]
        [string]$OutputDir
    )

    Write-Information "Downloading John the Ripper GitHub release asset: $AssetName" -InformationAction Continue
    Write-Information "Output directory: $OutputDir" -InformationAction Continue

    # Get module version from manifest
    $manifestPath = Join-Path $PSScriptRoot 'PoshJohn.psd1'
    $manifest = Import-PowerShellDataFile -Path $manifestPath
    $moduleVersion = $manifest.ModuleVersion
    $preRelease = $manifest.PrivateData.PSData.Prerelease
    if ($preRelease) {
        $moduleVersion += "-$preRelease"
    }

    # Get specific release from GitHub matching module version
    $repo = 'ArmaanMcleod/PoshJohn'
    $tag = "v$moduleVersion"
    $apiUrl = "https://api.github.com/repos/$repo/releases/tags/$tag"

    Write-Information "Fetching release info from: $apiUrl" -InformationAction Continue

    $release = Invoke-RestMethod -Uri $apiUrl
    $asset = $release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1

    if (-not $asset) {
        throw "Could not find $AssetName in release $tag"
    }

    # Download the asset
    $downloadUrl = $asset.browser_download_url
    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) $AssetName

    Write-Information "Downloading from: $downloadUrl" -InformationAction Continue

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -ErrorAction Stop

        # Extract the archive
        New-Item -ItemType Directory -Force -Path $OutputDir -ErrorAction Stop | Out-Null

        if ($AssetName.EndsWith('.zip')) {
            # Windows
            Expand-Archive -Path $tempFile -DestinationPath $OutputDir -Force -ErrorAction Stop
        } else {
            # Linux/macOS (tar.gz)
            & tar -xzvf $tempFile -C $OutputDir
            if ($LASTEXITCODE -ne 0) {
                throw "Tar extraction failed with exit code $LASTEXITCODE"
            }
        }

        Write-Information "Successfully downloaded and extracted John the Ripper assets to: $OutputDir" -InformationAction Continue
    }
    finally {
        # Always clean up temp file
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            Write-Information "Cleaned up temporary file: $tempFile" -InformationAction Continue
        }
    }
}

# Only set execute permissions on 'john' and 'zip2john' binaries (Linux/macOS only)
function Set-BinariesExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RunDir,

        [Parameter(Mandatory = $false)]
        [string[]]$Binaries = @('john', 'zip2john')
    )

    if (Test-Path $RunDir -PathType Container) {
        foreach ($bin in $Binaries) {
            $binPath = Join-Path $RunDir $bin

            if (Test-Path $binPath -PathType Leaf) {
                & chmod +x $binPath
                if ($LASTEXITCODE -ne 0) {
                    throw "Failed to set execute permission on '$binPath' with exit code $LASTEXITCODE."
                }
            }
        }
    }
}

# Main module import logic
# Handle platform-specific John the Ripper asset installation
try {
    if ($IsWindows) {
        $runDir = Join-Path $PSScriptRoot 'john/windows/run'
        if (-not (Test-Path $runDir)) {
            Install-JohnAssets -AssetName 'john-windows-x64.zip' -OutputDir $runDir
        }
    }

    elseif ($IsLinux) {
        $runDir = Join-Path $PSScriptRoot 'john/linux/run'
        if (-not (Test-Path $runDir)) {
            Install-JohnAssets -AssetName 'john-linux-x64.tar.gz' -OutputDir $runDir
        }
        Set-BinariesExecutable -RunDir $runDir
    }

    elseif ($IsMacOS) {
        $runDir = Join-Path $PSScriptRoot 'john/macos/run'
        if (-not (Test-Path $runDir)) {
            Install-JohnAssets -AssetName 'john-macos-arm64.tar.gz' -OutputDir $runDir
        }
        Set-BinariesExecutable -RunDir $runDir
    }
}
catch {
    throw "Module import failed. Failed to download John the Ripper assets: $_"
}
