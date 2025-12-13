using System;
using System.IO;
using System.Management.Automation;
using PoshJohn.Enums;

namespace PoshJohn.Common;

internal interface IPythonEnvironmentManager
{
    void CreateVirtualEnvironment();
    void InstallPackage(string packageName);
}

internal sealed class PythonEnvironmentManager : IPythonEnvironmentManager
{
    private readonly PSCmdlet _cmdlet;
    private readonly IProcessRunner _processRunner;
    private readonly IFileSystemProvider _fileSystemProvider;

    public PythonEnvironmentManager(PSCmdlet cmdlet, IProcessRunner runner, IFileSystemProvider fileSystemProvider)
    {
        _cmdlet = cmdlet;
        _processRunner = runner;
        _fileSystemProvider = fileSystemProvider;
    }

    public void CreateVirtualEnvironment()
    {
        if (Directory.Exists(_fileSystemProvider.VenvDirectoryPath))
        {
            _cmdlet?.WriteVerbose($"Virtual environment already exists at: {_fileSystemProvider.VenvDirectoryPath}");
            return;
        }

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
    }

    public void InstallPackage(string packageName)
    {
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
