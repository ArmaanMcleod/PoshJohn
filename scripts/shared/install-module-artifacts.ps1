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
        [string]$SourcePath,
        [string]$DestinationPath
    )

    if (-not (Test-Path $SourcePath)) {
        throw "Source path for $ArtifactName artifacts not found: $SourcePath"
    }

    if (Test-Path $DestinationPath) {
        throw "Extracted module should not already contain $ArtifactName artifacts at $DestinationPath"
    }

    Write-Host "Copying $SourcePath artifacts to $DestinationPath"
    New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null
    Copy-Item -Path "$SourcePath/*" -Destination $DestinationPath -Recurse -Force
}

$artifactNames = @(
    'john'
    'pdf2john'
    '7z2john'
    'repack7z'
)

foreach ($artifact in $artifactNames) {
    $sourcePath = "$artifact-artifacts/$Platform"
    $destinationPath = Join-Path $modulePath $artifact
    Copy-Artifacts -SourcePath $sourcePath -DestinationPath $destinationPath
}

Write-Host "`nAll artifacts installed successfully for $Platform"
