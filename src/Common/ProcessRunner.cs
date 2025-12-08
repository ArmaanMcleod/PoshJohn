using System;
using System.Diagnostics;
using System.Management.Automation;
using System.Text;
using PoshJohn.Enums;
using PoshJohn.Models;

namespace PoshJohn.Common;

internal interface IProcessRunner
{
    ProcessResult RunCommand(CommandType type, string arguments, bool logOutput, bool failOnStderr);
}

internal sealed class ProcessRunner : IProcessRunner
{
    private readonly PSCmdlet _cmdlet;
    private readonly IFileSystemProvider _fileSystemProvider;
    private readonly string[] _newLineChars = new[] { "\r", "\n" };

    public ProcessRunner(IFileSystemProvider fileSystemProvider)
    {
        _fileSystemProvider = fileSystemProvider;
    }

    public ProcessRunner(PSCmdlet cmdlet, IFileSystemProvider fileSystemProvider) : this(fileSystemProvider)
    {
        _cmdlet = cmdlet;
    }

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
                    _cmdlet?.WriteVerbose($"[Command StdOut] {line}");
                }
            }

            if (stderrBuilder.Length > 0)
            {
                var errorLines = stderrBuilder.ToString().Split(_newLineChars, StringSplitOptions.RemoveEmptyEntries);
                foreach (var line in errorLines)
                {
                    _cmdlet?.WriteDebug($"[Command StdErr] {line}");
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
