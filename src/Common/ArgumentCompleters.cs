using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Language;
using PoshJohn.Enums;

namespace PoshJohn.Common;

/// <summary>
/// Provides argument completion for John the Ripper incremental modes in PowerShell cmdlets.
/// </summary>
public class IncrementalModeCompleter : IArgumentCompleter
{
    /// <summary>
    /// Cached list of incremental modes for performance.
    /// </summary>
    private static IEnumerable<string> _cachedIncrementalModes;

    /// <summary>
    /// Process runner used to execute John the Ripper commands.
    /// </summary>
    private readonly IProcessRunner _processRunner = new ProcessRunner(new FileSystemProvider());

    /// <summary>
    /// The John the Ripper command to list incremental modes.
    /// </summary>
    private const string ListIncrementalModesCommand = "--list=inc-modes";

    /// <summary>
    /// Separators for splitting output into lines.
    /// </summary>
    private readonly string[] _newLineSeparators = new[] { "\r\n", "\n" };

    /// <summary>
    /// Returns completion results for the incremental mode parameter.
    /// </summary>
    /// <param name="commandName">The name of the command being completed.</param>
    /// <param name="parameterName">The name of the parameter being completed.</param>
    /// <param name="wordToComplete">The partial word to complete.</param>
    /// <param name="commandAst">The command abstract syntax tree.</param>
    /// <param name="fakeBoundParameters">Fake bound parameters for completion context.</param>
    /// <returns>Completion results for matching incremental modes.</returns>
    public IEnumerable<CompletionResult> CompleteArgument(
        string commandName,
        string parameterName,
        string wordToComplete,
        CommandAst commandAst,
        IDictionary fakeBoundParameters)
    {
        _cachedIncrementalModes ??= GetIncrementalModes();

        foreach (var mode in _cachedIncrementalModes)
        {
            if (mode.StartsWith(wordToComplete, StringComparison.OrdinalIgnoreCase))
            {
                yield return new CompletionResult(mode);
            }
        }
    }

    /// <summary>
    /// Gets the list of available John the Ripper incremental modes.
    /// </summary>
    /// <returns>An enumerable of incremental mode names.</returns>
    private IEnumerable<string> GetIncrementalModes()
    {
        var listIncrementalModeResult = _processRunner.RunCommand(
            CommandType.John,
            ListIncrementalModesCommand,
            logOutput: false,
            failOnStderr: false);

        return listIncrementalModeResult.StandardOutput.Split(_newLineSeparators, StringSplitOptions.RemoveEmptyEntries);
    }
}
