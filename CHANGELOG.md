# Changelog for PoshJohn

## Unreleased

### Build and Packaging Improvements

+ Install John assets externally during module import to reduce module package size (#29).
  + Download John the Ripper from GitHub release assets.
+ Remove OS Run Directory from John Files (#30).
  + Removes `windows/run`, `linux/run` and `macos/run` OS directories and includes John files directly into `john` folder.

### General Cmdlet Updates and Fixes

+ Migrate pdf2john.py functionality to .NET ([#12](https://github.com/ArmaanMcleod/PoshJohn/issues/12)).
  + Removes dependency on Python and uses native C library `libpdfhash` to generate hashes with `get_pdf_hash` function using P/Invoke.

## v1.0.1 - 16/12/2025

### Build and Packaging Improvements

+ Add Test workflow, PSGallery and License badges to README.md (#5)
+ Reduce package size from 235 MB to 219 MB (#21).

## v1.0.0 - 15/12/2025

### General Cmdlet Updates and Fixes

+ Initial version of the `PoshJohn` module (#1).
  + Added `Export-JohnPasswordHash` and `Invoke-JohnPasswordCrack` cmdlets for extracting and cracking password hashes using John the Ripper.

### Build and Packaging Improvements

+ Fixed GHA Workflow CI to build and package module correctly (#2).
+ Included up to date documentation in the module package (#3).
+ Stripped unnecessary files from John the Ripper builds to reduce package size (#4).
