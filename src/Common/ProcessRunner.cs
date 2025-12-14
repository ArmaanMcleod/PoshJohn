using System;
using System.Diagnostics;
using System.Management.Automation;
using System.Text;
using PoshJohn.Enums;
using PoshJohn.Models;

namespace PoshJohn.Common;

/// <summary>
/// Provides an abstraction for running external processes and commands.
/// </summary>
internal interface IProcessRunner
{
    /// <summary>
    /// Runs a command of the specified type with arguments and options.
    /// </summary>
    /// <param name="type">The type of command to run (e.g., John, Python).</param>
    /// <param name="arguments">The command-line arguments.</param>
    /// <param name="logOutput">Whether to log output to the cmdlet's verbose/debug streams.</param>
    /// <param name="failOnStderr">Whether to treat any stderr output as a failure.</param>
    /// <returns>The result of the process execution.</returns>
    ProcessResult RunCommand(CommandType type, string arguments, bool logOutput, bool failOnStderr);
}

/// <summary>
/// Implements IProcessRunner for running external processes and capturing their output.
/// </summary>
internal sealed class ProcessRunner : IProcessRunner
{
    private readonly PSCmdlet _cmdlet;
    private readonly IFileSystemProvider _fileSystemProvider;
    private readonly string[] _newLineChars = new[] { "\r", "\n" };

    /// <summary>
    /// Initializes a new instance of the ProcessRunner class with a file system provider.
    /// </summary>
    /// <param name="fileSystemProvider">The file system provider for resolving executable paths.</param>
    public ProcessRunner(IFileSystemProvider fileSystemProvider)
    {
        _fileSystemProvider = fileSystemProvider;
    }

    /// <summary>
    /// Initializes a new instance of the ProcessRunner class with a cmdlet context and file system provider.
    /// </summary>
    /// <param name="cmdlet">The PowerShell cmdlet instance for verbose/debug output.</param>
    /// <param name="fileSystemProvider">The file system provider for resolving executable paths.</param>
    public ProcessRunner(PSCmdlet cmdlet, IFileSystemProvider fileSystemProvider) : this(fileSystemProvider)
    {
        _cmdlet = cmdlet;
    }

    /// <inheritdoc/>
    public ProcessResult RunCommand(CommandType type, string arguments, bool logOutput, bool failOnStderr)
    {
        string exePath = type switch
        {
            CommandType.John => _fileSystemProvider.JohnExePath,
            CommandType.SystemPython => _fileSystemProvider.SystemPythonExePath,
            CommandType.VenvPython => _fileSystemProvider.VenvPythonExePath,
            CommandType.Zip2John => _fileSystemProvider.Zip2JohnExePath,
            _ => throw new ArgumentException("Unknown run command type")
        };
        return RunCommand(exePath, arguments, logOutput, failOnStderr);
    }

    /// <summary>
    /// Runs a process with the specified command path and arguments, capturing output and error streams.
    /// </summary>
    /// <param name="commandPath">The path to the executable to run.</param>
    /// <param name="arguments">The command-line arguments.</param>
    /// <param name="logOutput">Whether to log output to the cmdlet's verbose/debug streams.</param>
    /// <param name="failOnStderr">Whether to treat any stderr output as a failure.</param>
    /// <returns>The result of the process execution.</returns>
    private ProcessResult RunCommand(string commandPath, string arguments, bool logOutput, bool failOnStderr)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = commandPath,
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        _cmdlet?.WriteVerbose($"Executing command: {commandPath} {arguments}");

        using var process = new Process
        {
            StartInfo = startInfo
        };

        var stdoutBuilder = new StringBuilder();
        var stderrBuilder = new StringBuilder();

        process.OutputDataReceived += (sender, e) =>
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                stdoutBuilder.AppendLine(e.Data);
            }
        };

        process.ErrorDataReceived += (sender, e) =>
        {
            if (!string.IsNullOrEmpty(e.Data))
            {
                stderrBuilder.AppendLine(e.Data);
            }
        };

        process.Start();

        process.BeginOutputReadLine();
        process.BeginErrorReadLine();

        _cmdlet?.WriteVerbose($"Waiting for process to exit. Process Id: {process.Id}");

        process.WaitForExit();

        _cmdlet?.WriteVerbose($"Process exited with code: {process.ExitCode}");

        if (logOutput)
        {
            if (stdoutBuilder.Length > 0)
            {
                var outputLines = stdoutBuilder.ToString().Split(_newLineChars, StringSplitOptions.RemoveEmptyEntries);
                foreach (var line in outputLines)
                {
                    _cmdlet?.WriteVerbose($"[STDOUT] {line}");
                }
            }

            if (stderrBuilder.Length > 0)
            {
                var errorLines = stderrBuilder.ToString().Split(_newLineChars, StringSplitOptions.RemoveEmptyEntries);
                foreach (var line in errorLines)
                {
                    _cmdlet?.WriteDebug($"[STDERR] {line}");
                }
            }
        }

        return new ProcessResult
        {
            Success = process.ExitCode == 0 && (!failOnStderr || stderrBuilder.Length == 0),
            StandardOutput = stdoutBuilder.ToString(),
            StandardError = stderrBuilder.ToString()
        };
    }
}
