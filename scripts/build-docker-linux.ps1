#!/usr/bin/env pwsh

param([switch]$Run)

$RepoRoot = Split-Path -Parent $PSScriptRoot
$DockerFilePath = Join-Path $RepoRoot "docker/Dockerfile.linux"
$DockerImageTag = "poshjohn-linux"

docker build -f $DockerFilePath -t $DockerImageTag .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

if ($Run) {
    docker run --rm -it $DockerImageTag pwsh
}
