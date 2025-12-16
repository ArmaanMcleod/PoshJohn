# Changelog for PoshJohn

## Unreleased

### Build and Packaging Improvements

+ Add Test workflow, PSGallery and License badges to README.md (#5)
+ Reduce package size by only keeping necessary files in John the Ripper builds (#21).

## v1.0.0 - 15/12/2025

### General Cmdlet Updates and Fixes

+ Initial version of the `PoshJohn` module (#1).
  + Added `Export-JohnPasswordHash` and `Invoke-JohnPasswordCrack` cmdlets for extracting and cracking password hashes using John the Ripper.

### Build and Packaging Improvements

+ Fixed GHA Workflow CI to build and package module correctly (#2).
+ Included up to date documentation in the module package (#3).
+ Stripped unnecessary files from John the Ripper builds to reduce package size (#4).
