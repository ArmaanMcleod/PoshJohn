$dllPath = Join-Path -Path $PSScriptRoot -ChildPath 'PoshJohn.dll'
Import-Module $dllPath

# Download John the Ripper assets from GitHub releases
function Install-JohnAssets {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AssetName,

        [Parameter(Mandatory = $true)]
        [string]$OutputDir,

        [Parameter(Mandatory = $false)]
        [string]$GitHubToken
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

    # Prepare headers for authenticated requests if token is provided
    $headers = @{}
    if ($GitHubToken) {
        $headers['Authorization'] = "Bearer $GitHubToken"
    }

    $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers
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

# Set execute permissions on binaries (Linux/macOS)
function Set-BinariesExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RunDir,

        [Parameter(Mandatory = $true)]
        [string[]]$Binaries
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
# Handle platform-specific John the Ripper & pdf2john asset installation
try {
    # Check for GitHub token in environment (for CI/CD scenarios)
    $githubToken = $env:GITHUB_TOKEN
    $johnDir = Join-Path $PSScriptRoot 'john'
    $pdf2johnDir = Join-Path $PSScriptRoot 'pdf2john'

    $johnAssetParams = @{
        OutputDir   = $johnDir
        GitHubToken = $githubToken
    }

    $pdf2johnAssetParams = @{
        OutputDir   = $pdf2johnDir
        GitHubToken = $githubToken
    }

    if ($IsWindows) {
        if (-not (Test-Path $johnDir)) {
            Install-JohnAssets @johnAssetParams -AssetName 'john-windows-x64.zip'
        }
        if (-not (Test-Path $pdf2johnDir)) {
            Install-JohnAssets @pdf2johnAssetParams -AssetName 'pdf2john-windows-x64.zip'
        }
    }

    elseif ($IsLinux) {
        if (-not (Test-Path $johnDir)) {
            Install-JohnAssets @johnAssetParams -AssetName 'john-linux-x64.tar.gz'
        }
        if (-not (Test-Path $pdf2johnDir)) {
            Install-JohnAssets @pdf2johnAssetParams -AssetName 'pdf2john-linux-x64.tar.gz'
        }
        Set-BinariesExecutable -RunDir $johnDir -Binaries @('john', 'zip2john')
        Set-BinariesExecutable -RunDir $pdf2johnDir -Binaries @('pdf2john')
    }

    elseif ($IsMacOS) {
        if (-not (Test-Path $johnDir)) {
            Install-JohnAssets @johnAssetParams -AssetName 'john-macos-arm64.tar.gz'
        }
        if (-not (Test-Path $pdf2johnDir)) {
            Install-JohnAssets @pdf2johnAssetParams -AssetName 'pdf2john-macos-arm64.tar.gz'
        }
        Set-BinariesExecutable -RunDir $johnDir -Binaries @('john', 'zip2john')
        Set-BinariesExecutable -RunDir $pdf2johnDir -Binaries @('pdf2john')
    }
}
catch {
    throw "Module import failed. Failed to download John the Ripper assets: $_"
}
