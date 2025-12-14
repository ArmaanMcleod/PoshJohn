using System;
using System.IO;
using System.Management.Automation;
using PoshJohn.Enums;

namespace PoshJohn.Common;

/// <summary>
/// Provides an abstraction for managing Python virtual environments and packages.
/// </summary>
internal interface IPythonEnvironmentManager
{
    /// <summary>
    /// Creates a Python virtual environment if it does not already exist.
    /// </summary>
    void CreateVirtualEnvironment();

    /// <summary>
    /// Installs a Python package into the virtual environment.
    /// </summary>
    /// <param name="packageName">The name of the package to install.</param>
    void InstallPackage(string packageName);
}

/// <summary>
/// Implements IPythonEnvironmentManager for creating and managing Python virtual environments and packages.
/// </summary>
internal sealed class PythonEnvironmentManager : IPythonEnvironmentManager
{
    private readonly PSCmdlet _cmdlet;
    private readonly IProcessRunner _processRunner;
    private readonly IFileSystemProvider _fileSystemProvider;
    private bool _pipUpgraded;

    /// <summary>
    /// Initializes a new instance of the PythonEnvironmentManager class.
    /// </summary>
    /// <param name="cmdlet">The PowerShell cmdlet instance for verbose output.</param>
    /// <param name="runner">The process runner for executing Python commands.</param>
    /// <param name="fileSystemProvider">The file system provider for environment paths.</param>
    public PythonEnvironmentManager(PSCmdlet cmdlet, IProcessRunner runner, IFileSystemProvider fileSystemProvider)
    {
        _cmdlet = cmdlet;
        _processRunner = runner;
        _fileSystemProvider = fileSystemProvider;
        _pipUpgraded = false;
    }

    /// <inheritdoc/>
    public void CreateVirtualEnvironment()
    {
        var venvExists = Directory.Exists(_fileSystemProvider.VenvDirectoryPath);

        if (venvExists)
        {
            _cmdlet?.WriteVerbose($"Virtual environment already exists at: {_fileSystemProvider.VenvDirectoryPath}");
        }
        else
        {
            _cmdlet?.WriteVerbose($"Creating virtual environment at: {_fileSystemProvider.VenvDirectoryPath}");

            var venvCreateResult = _processRunner.RunCommand(
                CommandType.SystemPython,
                $"-m venv \"{_fileSystemProvider.VenvDirectoryPath}\"",
                logOutput: true,
                failOnStderr: true);

            if (!venvCreateResult.Success)
            {
                throw new InvalidOperationException($"Failed to create virtual environment: {venvCreateResult.StandardError}");
            }

            _cmdlet?.WriteVerbose($"Virtual environment created successfully at: {_fileSystemProvider.VenvDirectoryPath}");
        }

        UpgradePip();
    }

    /// <summary>
    /// Upgrades pip in the virtual environment if it has not already been upgraded.
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown if pip upgrade fails.</exception>
    private void UpgradePip()
    {
        if (_pipUpgraded)
        {
            return;
        }

        _cmdlet?.WriteVerbose("Upgrading pip in the virtual environment...");

        var pipUpgradeResult = _processRunner.RunCommand(
            CommandType.VenvPython,
            "-m pip install --upgrade pip",
            logOutput: true,
            failOnStderr: true);

        if (!pipUpgradeResult.Success)
        {
            throw new InvalidOperationException($"Failed to upgrade pip: {pipUpgradeResult.StandardError}");
        }

        _cmdlet?.WriteVerbose("pip upgraded successfully");
        _pipUpgraded = true;
    }

    /// <inheritdoc/>
    public void InstallPackage(string packageName)
    {
        UpgradePip();

        _cmdlet?.WriteVerbose($"Installing {packageName} package...");

        var packageCheckResult = _processRunner.RunCommand(CommandType.VenvPython, $"-m pip show {packageName}", logOutput: false, failOnStderr: true);
        if (packageCheckResult.Success)
        {
            _cmdlet?.WriteVerbose($"{packageName} is already installed");
            return;
        }

        var packageInstallResult = _processRunner.RunCommand(
            CommandType.VenvPython,
            $"-m pip install {packageName}",
            logOutput: true,
            failOnStderr: true);

        if (!packageInstallResult.Success)
        {
            throw new InvalidOperationException($"Failed to install {packageName}: {packageInstallResult.StandardError}");
        }

        _cmdlet?.WriteVerbose($"{packageName} installed successfully");
    }
}
