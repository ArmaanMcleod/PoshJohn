using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Language;
using PoshJohn.Enums;

namespace PoshJohn.Common;

public class IncrementalModeCompleter : IArgumentCompleter
{
    private static IEnumerable<string> _cachedIncrementalModes;

    private readonly IProcessRunner _processRunner = new ProcessRunner(new FileSystemProvider());

    private const string ListIncrementalModesCommand = "--list=inc-modes";

    private readonly string[] _newLineSeparators = new[] { "\r\n", "\n" };

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
