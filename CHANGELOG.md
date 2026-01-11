# Changelog for PoshJohn

## Unreleased

### Build and Packaging Improvements

+ Docker Build for Linux Improvements ([#37](https://github.com/ArmaanMcleod/PoshJohn/pull/37)).
  + Added `-Test`, `Shell`, `RemoveOnExit` flags to `docker-build-linux.ps1` to support more troubleshooting & test scenarios.
  + Added `.dockerignore` file to exclude unnecessary files from Docker build context.

+ Added `-Prune` flag to `docker-build-linux.ps1` to remove unused Docker images, containers, networks, build cache and volumes ([#38](https://github.com/ArmaanMcleod/PoshJohn/pull/38)).

### General Cmdlet Updates and Fixes

+ Fixed `corrupted double‑linked list` for Docker Linux and pdfhash cleanup ([#38](https://github.com/ArmaanMcleod/PoshJohn/issues/38)).
  + Use `#ifdef _WIN32` to conditionally drop PDF document early on Windows to avoid `corrupted double‑linked list` error on Docker Linux.
  + Cleaned up C code for `pdfhash.c` to maentain consistency and readability.

## v1.1.1 - 11/01/2026

### General Cmdlet Updates and Fixes

+ Fixed Relative Paths are not being resolved with `Export-JohnPasswordHash` & `Invoke-JohnPasswordCrack` cmdlets ([#34](https://github.com/ArmaanMcleod/PoshJohn/issues/34)).

## v1.1.0 - 09/01/2026

### Build and Packaging Improvements

+ Install John assets externally during module import to reduce module package size ([#28](https://github.com/ArmaanMcleod/PoshJohn/issues/28)).
  + Download John the Ripper from GitHub release assets.
+ Remove OS Run Directory from John Files ([#30](https://github.com/ArmaanMcleod/PoshJohn/pull/30)).
  + Removes `windows/run`, `linux/run` and `macos/run` OS directories and includes John files directly into `john` folder.

### General Cmdlet Updates and Fixes

+ Migrate pdf2john.py functionality to .NET ([#12](https://github.com/ArmaanMcleod/PoshJohn/issues/12)).
  + Removes dependency on Python and uses native C library `libpdfhash` to generate hashes with `get_pdf_hash` function using P/Invoke.

## v1.0.1 - 16/12/2025

### Build and Packaging Improvements

+ Add Test workflow, PSGallery and License badges to README.md ([#5](https://github.com/ArmaanMcleod/PoshJohn/pull/5)).
+ Reduce package size from 235 MB to 219 MB ([#21](https://github.com/ArmaanMcleod/PoshJohn/issues/21)).

## v1.0.0 - 15/12/2025

### General Cmdlet Updates and Fixes

+ Initial version of the `PoshJohn` module ([#1](https://github.com/ArmaanMcleod/PoshJohn/pull/1)).
  + Added `Export-JohnPasswordHash` and `Invoke-JohnPasswordCrack` cmdlets for extracting and cracking password hashes using John the Ripper.

### Build and Packaging Improvements

+ Fixed GHA Workflow CI to build and package module correctly ([#2](https://github.com/ArmaanMcleod/PoshJohn/pull/2)).
+ Included up to date documentation in the module package ([#3](https://github.com/ArmaanMcleod/PoshJohn/pull/3)).
+ Stripped unnecessary files from John the Ripper builds to reduce package size ([#4](https://github.com/ArmaanMcleod/PoshJohn/pull/4)).
