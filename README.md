# PoshJohn

[![GithubActionsWorkflow]][GithubActionsWorkflowYaml]
[![PoshJohn]][PoshJohnGallery]
[![PoshJohnDownloads]][PoshJohnGallery]
[![License]][LicenseBlob]

PoshJohn is a PowerShell wrapper for the popular password-cracking tool [John the Ripper](https://www.openwall.com/john/).

It simplifies the process of using John the Ripper by providing a user-friendly PowerShell interface, making it easier to execute commands and manage password-cracking tasks.

Currently supports Windows, macOS, and Linux platforms.

Current File Types Supported:

- PDF (Portable Document Format)

- ZIP (Zip Archive)

## Requirements

These cmdlets have the following requirements:

- PowerShell v7.2 or newer.
- Python 3

I may decide to also include PowerShell v5.1 support down the line if needed.

## Examples

Crack PDF password using a wordlist:

```powershell
# Generate hash from PDF file
Export-JohnPasswordHash -InputPath "C:\path\to\file.pdf" -OutputPath "C:\path\to\hash.txt"

# Crack the generated hash using John the Ripper
Invoke-JohnPasswordCrack -InputPath "C:\path\to\hash.txt" -WordListPath "C:\path\to\wordlist.txt"
```

Crack PDF password using brute force:

```powershell
# Generate hash from PDF file
Export-JohnPasswordHash -InputPath "C:\path\to\file.pdf" -OutputPath "C:\path\to\hash.txt"

# Crack the generated hash using John the Ripper with brute force
Invoke-JohnPasswordCrack -InputPath "C:\path\to\hash.txt"
```

## Installing

You can install this module by running:

```powershell
# Install for only the current user
Install-Module -Name PoshJohn -Scope CurrentUser

# Install for all users
Install-Module -Name PoshJohn -Scope AllUsers
```

## Contributing

Contributing is quite easy, fork this repo and submit a pull request with the changes. To build this module run `./PowerShellBuildTools/build.ps1` in PowerShell.

To test a build run `./PowerShellBuildTools/build.ps1 -Task Test` in PowerShell. This script will ensure all dependencies are installed before running the test suite.

Build and run the docker image for linux by running `./scripts/build-docker-linux.ps1 -Run`.

<!-- References -->
[GithubActionsWorkflow]: https://github.com/ArmaanMcleod/PoshJohn/workflows/Test%20PoshJohn%20Module/badge.svg
[GithubActionsWorkflowYaml]: https://github.com/ArmaanMcleod/PoshJohn/actions/workflows/ci.yml
[PoshJohnDownloads]: https://img.shields.io/powershellgallery/dt/PoshJohn
[PoshJohnGallery]: https://www.powershellgallery.com/packages/PoshJohn/
[PoshJohn]: https://img.shields.io/powershellgallery/v/PoshJohn?label=PoshJohn
[License]: https://img.shields.io/badge/license-MIT-blue.svg
[LicenseBlob]: https://github.com/ArmaanMcleod/PoshJohn/blob/main/LICENSE
