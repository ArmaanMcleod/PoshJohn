$dllPath = Join-Path -Path $PSScriptRoot -ChildPath 'PoshJohn.dll'
Import-Module $dllPath

# Download John the Ripper assets from GitHub releases
$private:DownloadJohnAssets = {
    param(
        [string]$AssetName,
        [string]$OutputDir
    )

    Write-Verbose "Downloading John the Ripper Github release asset: $AssetName"
    Write-Verbose "Output directory: $OutputDir"

    try {
        # Get module version from manifest
        $manifestPath = Join-Path $PSScriptRoot 'PoshJohn.psd1'
        $manifest = Import-PowerShellDataFile -Path $manifestPath
        $moduleVersion = $manifest.ModuleVersion

        # Get specific release from GitHub matching module version
        $repo = 'ArmaanMcleod/PoshJohn'
        $tag = "v$moduleVersion"
        $apiUrl = "https://api.github.com/repos/$repo/releases/tags/$tag"

        $release = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        $asset = $release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1

        if (-not $asset) {
            Write-Warning "Could not find $AssetName in release $tag. John the Ripper functionality may be limited."
            return
        }

        # Download the asset
        $downloadUrl = $asset.browser_download_url
        $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) $AssetName

        Write-Verbose "Downloading from: $downloadUrl"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile -ErrorAction Stop

        # Extract the archive
        New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

        if ($AssetName.EndsWith('.zip')) {
            # Windows
            Expand-Archive -Path $tempFile -DestinationPath $OutputDir -Force
        } else {
            # Linux/macOS (tar.gz)
            & tar -xzf $tempFile -C $OutputDir
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to extract tar.gz archive: $tempFile"
            }
        }

        # Clean up temp file
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

        Write-Verbose "Successfully downloaded and extracted John the Ripper binaries to: $OutputDir"
    }
    catch {
        Write-Warning "Failed to download John the Ripper binaries: $_"
        Write-Warning "John the Ripper functionality may be limited."
    }
}

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

if ($IsWindows) {
    $runDir = Join-Path $PSScriptRoot 'john/windows/run'
    if (-not (Test-Path $runDir)) {
        & $DownloadJohnAssets -AssetName 'john-windows-x64.zip' -OutputDir $runDir
    }
}

if ($IsLinux) {
    $runDir = Join-Path $PSScriptRoot 'john/linux/run'
    if (-not (Test-Path $runDir)) {
        & $DownloadJohnAssets -AssetName 'john-linux-x64.tar.gz' -OutputDir $runDir
    }
    & $SetBinariesExecutable -runDir $runDir
}

if ($IsMacOS) {
    $runDir = Join-Path $PSScriptRoot 'john/macos/run'
    if (-not (Test-Path $runDir)) {
        & $DownloadJohnAssets -AssetName 'john-macos-arm64.tar.gz' -OutputDir $runDir
    }
    & $SetBinariesExecutable -runDir $runDir
}
