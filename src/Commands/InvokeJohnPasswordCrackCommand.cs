using System;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using System.Text;
using System.Text.RegularExpressions;
using PoshJohn.Common;
using PoshJohn.Enums;
using PoshJohn.Models;

namespace PoshJohn.Commands;

/// <summary>
/// Implements the Invoke-JohnPasswordCrack cmdlet.
/// Cracks password hashes using John the Ripper.
/// </summary>
[Cmdlet(VerbsLifecycle.Invoke, "JohnPasswordCrack", HelpUri = "https://github.com/ArmaanMcleod/PoshJohn/blob/main/docs/en-US/Invoke-JohnPasswordCrack.md")]
[OutputType(typeof(PasswordCrackResult))]
public sealed class InvokeJohnPasswordCrackCommand : PSCmdlet
{
    private const string IncrementalWithInputObjectParameterSet = "IncrementalWithInputObject";
    private const string IncrementalWithInputPathParameterSet = "IncrementalWithInputPath";
    private const string WordListWithInputObjectParameterSet = "WordListWithInputObject";
    private const string WordListWithInputPathParameterSet = "WordListWithInputPath";

    /// <summary>
    /// The hash object to be cracked. Accepts pipeline input from previous commands.
    /// </summary>
    [Parameter(Mandatory = true, ValueFromPipeline = true, ParameterSetName = IncrementalWithInputObjectParameterSet)]
    [Parameter(Mandatory = true, ValueFromPipeline = true, ParameterSetName = WordListWithInputObjectParameterSet)]
    public HashResult InputObject { get; set; }

    /// <summary>
    /// Path to the file containing password hashes to crack.
    /// </summary>
    [Parameter(Mandatory = true, ParameterSetName = IncrementalWithInputPathParameterSet)]
    [Parameter(Mandatory = true, ParameterSetName = WordListWithInputPathParameterSet)]
    [Alias("HashPath")]
    public string InputPath { get; set; }

    /// <summary>
    /// Specifies the John the Ripper incremental mode to use (e.g., 'ASCII', 'Digits').
    /// </summary>
    [Parameter(Mandatory = false, ParameterSetName = IncrementalWithInputPathParameterSet)]
    [Parameter(Mandatory = false, ParameterSetName = IncrementalWithInputObjectParameterSet)]
    [ArgumentCompleter(typeof(IncrementalModeCompleter))]
    public string IncrementalMode { get; set; }

    /// <summary>
    /// Path to the word list file.
    /// </summary>
    [Parameter(Mandatory = true, ParameterSetName = WordListWithInputPathParameterSet)]
    [Parameter(Mandatory = true, ParameterSetName = WordListWithInputObjectParameterSet)]
    [Alias("DictionaryPath")]
    public string WordListPath { get; set; }

    /// <summary>
    /// Specifies a custom pot file to use for storing cracked passwords.
    /// </summary>
    [Parameter(Mandatory = false)]
    public string CustomPotPath { get; set; }

    /// <summary>
    /// If set, refreshes the pot file before cracking.
    /// </summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter RefreshPot { get; set; }

    /// <summary>
    /// Specifies the directory where unlocked files will be saved.
    /// </summary>
    [Parameter(Mandatory = false)]
    public string UnlockedFileDirectoryPath { get; set; }

    private IProcessRunner _processRunner;

    private IFileSystemProvider _fileSystemProvider;
    private IFileUnlockManager _fileUnlockManager;

    private bool _initialized;

    private readonly string[] _newLineChars = new[] { "\r", "\n" };

    private readonly Regex _formatGroupRegex = new(
        @"Loaded (\d+) password hash(?:es)?(?: with (\d+) different salts)? \(([^ ]+) \[([^\]]+)\]\)",
        RegexOptions.Compiled
    );

    private readonly Regex _passwordLabelRegex = new(
        @"^(\S+)\s+\((\S+)\)$",
        RegexOptions.Compiled
    );

    private const string NoPasswordHashesLeftToCrackMessage = "No password hashes left to crack";

    protected override void BeginProcessing()
    {
        try
        {
            if (!string.IsNullOrEmpty(UnlockedFileDirectoryPath) && !Directory.Exists(UnlockedFileDirectoryPath))
            {
                Directory.CreateDirectory(UnlockedFileDirectoryPath);
            }

            _fileSystemProvider = new FileSystemProvider(new PasswordCrackConfig
            {
                Cmdlet = this,
                HashFilePath = InputPath,
                CustomPotPath = CustomPotPath,
            });

            _processRunner = new ProcessRunner(this, _fileSystemProvider);

            _fileUnlockManager = new FileUnlockManager(this);

            if (RefreshPot.IsPresent)
            {
                _fileSystemProvider.RefreshPotFile();
            }

            _initialized = true;
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(
                ex,
                this.FormatBeginProcessingErrorId(),
                ErrorCategory.InvalidOperation,
                null));

            _initialized = false;
        }
    }

    protected override void ProcessRecord()
    {
        if (!_initialized)
        {
            return;
        }

        if (InputObject != null)
        {
            _fileSystemProvider.HashFilePath = InputObject.HashFilePath;
        }

        try
        {
            if (!File.Exists(_fileSystemProvider.HashFilePath))
            {
                throw new FileNotFoundException("Input file not found.", _fileSystemProvider.HashFilePath);
            }

            WriteVerbose("Starting John the Ripper password cracking");

            string args;

            if (!string.IsNullOrEmpty(WordListPath))
            {
                if (!File.Exists(WordListPath))
                {
                    throw new FileNotFoundException("Wordlist file not found.", WordListPath);
                }
                args = $"--pot=\"{_fileSystemProvider.PotPath}\" --wordlist=\"{WordListPath}\" \"{_fileSystemProvider.HashFilePath}\"";
            }
            else
            {
                string modeArg = string.IsNullOrEmpty(IncrementalMode) ? "--incremental" : $"--incremental={IncrementalMode}";
                args = $"--pot=\"{_fileSystemProvider.PotPath}\" {modeArg} \"{_fileSystemProvider.HashFilePath}\"";
            }

            var commandResult = _processRunner.RunCommand(
                CommandType.John,
                args,
                logOutput: true,
                failOnStderr: false);

            if (!commandResult.Success)
            {
                throw new InvalidOperationException($"John failed: {commandResult.StandardError}");
            }

            var crackResult = new PasswordCrackResult
            {
                RawOutput = commandResult.StandardOutput,
                PotPath = _fileSystemProvider.PotPath,
                Summary = ParseJohnOutputToSummary(commandResult.StandardOutput)
            };

            foreach (var formatGroup in crackResult.Summary.FormatGroups)
            {
                foreach (var passwordUnlockResult in formatGroup.FilePasswords.Values)
                {
                    _fileUnlockManager.SaveAndUnlockPasswordProtectedFile(passwordUnlockResult);
                }
            }

            WriteObject(crackResult);
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(
                ex,
                this.FormatProcessRecordErrorId(),
                ErrorCategory.InvalidOperation,
                _fileSystemProvider.HashFilePath));
        }
    }

    private PasswordCrackSummary ParseJohnOutputToSummary(string output)
    {
        var result = new PasswordCrackSummary
        {
            FormatGroups = new List<FormatGroup>()
        };

        var lines = output.Split(_newLineChars, StringSplitOptions.RemoveEmptyEntries);

        FormatGroup currentGroup = null;

        foreach (var line in lines)
        {
            if (_formatGroupRegex.Match(line) is { Success: true } loadedMatch)
            {
                WriteDebug($"Matched '{line}'. Adding new format group from John output parsing.");

                int hashCount = int.TryParse(loadedMatch.Groups[1].Value, out var hc) ? hc : 0;
                int saltsCount = loadedMatch.Groups[2].Success && int.TryParse(loadedMatch.Groups[2].Value, out var sc) ? sc : 1;

                if (!Enum.TryParse<FileFormatType>(loadedMatch.Groups[3].Value, ignoreCase: true, out var fileFormat))
                {
                    throw new InvalidDataException($"Unsupported file format found in John output: {loadedMatch.Groups[3].Value}");
                }

                string encryptionAlgorithms = loadedMatch.Groups[4].Value;

                currentGroup = new FormatGroup
                {
                    PasswordHashCount = hashCount,
                    SaltsCount = saltsCount,
                    FileFormat = fileFormat,
                    EncryptionAlgorithms = encryptionAlgorithms,
                    FilePasswords = new Dictionary<string, PasswordUnlockResult>(StringComparer.OrdinalIgnoreCase)
                };

                result.FormatGroups.Add(currentGroup);
            }

            else if (_passwordLabelRegex.Match(line) is { Success: true } passwordMatch && currentGroup != null)
            {
                WriteDebug($"Matched '{line}'. Adding cracked password from John output parsing.");
                string password = passwordMatch.Groups[1].Value;
                string label = passwordMatch.Groups[2].Value;

                if (!_fileSystemProvider.LabelToFilePaths.TryGetValue(label, out string filePath))
                {
                    WriteDebug($"No matching file path found for label: {label}. Skipping this cracked password entry.");
                    continue;
                }

                currentGroup.FilePasswords[filePath] = new PasswordUnlockResult(filePath, password, currentGroup.FileFormat, UnlockedFileDirectoryPath);
            }

            else if (line.StartsWith(NoPasswordHashesLeftToCrackMessage, StringComparison.OrdinalIgnoreCase) && currentGroup != null)
            {
                WriteDebug($"Matched '{line}'. No password hashes left to crack message encountered. Loading cracked passwords from pot file.");

                if (!_fileSystemProvider.LoadedInputHashEntries.TryGetValue(currentGroup.FileFormat, out Dictionary<string, string> fileHashes))
                {
                    WriteDebug($"No loaded input hash entries found for format {currentGroup.FileFormat}. Skipping pot file parsing for this format group.");
                    continue;
                }

                foreach (var kvp in fileHashes)
                {
                    if (!_fileSystemProvider.LoadedPotHashPasswords.TryGetValue(kvp.Key, out string password))
                    {
                        WriteDebug($"No matching password found in pot file for hash: {kvp.Key}. Skipping this entry.");
                        continue;
                    }

                    string filePath = kvp.Value;
                    currentGroup.FilePasswords[filePath] = new PasswordUnlockResult(filePath, password, currentGroup.FileFormat, UnlockedFileDirectoryPath);
                }
            }
        }

        return result;
    }
}
