#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install native artifacts into the extracted PowerShell module.

.DESCRIPTION
    Extracts the nupkg and copies platform-specific native artifacts (john, pdf2john, 7z2john, repack7z)
    into the module directory structure.

.PARAMETER Platform
    The platform name (Windows, Linux, MacOS).

.PARAMETER ModuleManifestPath
    Path to the module manifest file.

.PARAMETER OutputPath
    Path to the output directory containing the nupkg.
#>
param(
    [Parameter(Mandatory)]
    [ValidateSet('Windows', 'Linux', 'MacOS')]
    [string]$Platform,

    [Parameter(Mandatory)]
    [string]$ModuleManifestPath,

    [Parameter(Mandatory)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$RepoPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName

$ModulePath = Join-Path $RepoPath 'PowerShellBuildTools/tools/helper.psm1'

# Extract the nupkg
Import-Module $ModulePath -Force
Expand-Nupkg -ModuleManfifestPath $ModuleManifestPath -OutputPath $OutputPath

# Find the extracted module directory
$modulePath = Get-ChildItem -Path "$OutputPath/PoshJohn" -Directory | Select-Object -First 1 -ExpandProperty FullName
Write-Host "Module extracted to: $modulePath"

function Copy-Artifacts {
    param(
        [string]$ArtifactName,
        [string]$SourcePath,
        [string]$DestinationPath,
        [switch]$SkipIfMissing
    )

    if ($SkipIfMissing -and -not (Test-Path $SourcePath)) {
        Write-Host "Skipping $ArtifactName (not present for this platform)"
        return
    }

    if (-not (Test-Path $SourcePath)) {
        throw "Source path for $ArtifactName artifacts not found: $SourcePath"
    }

    if (Test-Path $DestinationPath) {
        throw "Extracted module should not already contain $ArtifactName artifacts at $DestinationPath"
    }

    Write-Host "Copying $ArtifactName artifacts..."
    New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null
    Copy-Item -Path "$SourcePath/*" -Destination $DestinationPath -Recurse -Force
    Write-Host "  -> $DestinationPath"
}

Copy-Artifacts -ArtifactName "john" `
    -SourcePath "john-artifacts/$Platform" `
    -DestinationPath (Join-Path $modulePath "john")

Copy-Artifacts -ArtifactName "pdf2john" `
    -SourcePath "pdf2john-artifacts/$Platform" `
    -DestinationPath (Join-Path $modulePath "pdf2john")

Copy-Artifacts -ArtifactName "7z2john" `
    -SourcePath "7z2john-artifacts/$Platform" `
    -DestinationPath (Join-Path $modulePath "7z2john")

Copy-Artifacts -ArtifactName "repack7z" `
    -SourcePath "repack7z-artifacts/$Platform" `
    -DestinationPath (Join-Path $modulePath "repack7z")

Write-Host "`nAll artifacts installed successfully for $Platform"
