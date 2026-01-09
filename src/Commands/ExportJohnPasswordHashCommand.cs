using System;
using System.IO;
using System.Management.Automation;
using PoshJohn.Common;
using PoshJohn.Models;

namespace PoshJohn.Commands;

/// <summary>
/// Implements the Export-JohnPasswordHash cmdlet.
/// Exports password hashes from files for use with John the Ripper.
/// </summary>
[Cmdlet(VerbsData.Export, "JohnPasswordHash", HelpUri = "https://github.com/ArmaanMcleod/PoshJohn/blob/main/docs/en-US/Export-JohnPasswordHash.md")]
[OutputType(typeof(HashResult))]
public sealed class ExportJohnPasswordHashCommand : PSCmdlet
{
    #region Parameters

    /// <summary>
    /// Path to the password-protected file.
    /// </summary>
    [Parameter(Mandatory = true)]
    public string InputPath { get; set; }

    /// <summary>
    /// Path to save the exported hash.
    /// </summary>
    [Parameter(Mandatory = true)]
    [Alias("HashPath")]
    public string OutputPath { get; set; }

    /// <summary>
    /// Append the exported hash to the output file.
    /// </summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter Append { get; set; }

    #endregion Parameters

    #region  Private Members

    private bool _initialized;
    private IProcessRunner _processRunner;
    private FileSystemProvider _fileSystemProvider;
    private IFileHashProvider _fileHashProvider;

    #endregion Private Members

    #region  Protected Methods

    /// <summary>
    /// Initializes the cmdlet, setting up necessary components.
    /// </summary>
    protected override void BeginProcessing()
    {
        try
        {
            if (!File.Exists(InputPath))
            {
                throw new FileNotFoundException("Input file not found.", InputPath);
            }

            WriteVerbose($"Processing file: {InputPath}");

            _fileSystemProvider = new FileSystemProvider(new ExportHashConfig
            {
                Cmdlet = this,
                FileToCrackPath = InputPath,
                HashFilePath = OutputPath
            });
            _processRunner = new ProcessRunner(this, _fileSystemProvider);
            _fileHashProvider = new FileHashProvider(this, _fileSystemProvider, _processRunner);

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

    /// <summary>
    /// Processes the record, extracting and exporting the password hash.
    /// </summary>
    protected override void ProcessRecord()
    {
        if (!_initialized)
        {
            return;
        }

        try
        {
            string hash = _fileHashProvider.ExtractFileHash();

            if (string.IsNullOrWhiteSpace(hash))
            {
                throw new InvalidOperationException("Extracted hash is empty.");
            }

            _fileHashProvider.WriteFileHash(hash, Append.IsPresent);

            var hashResult = new HashResult
            {
                Hash = hash,
                HashFilePath = OutputPath,
            };

            WriteObject(hashResult);
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(
                ex,
                this.FormatProcessRecordErrorId(),
                ErrorCategory.InvalidOperation,
                InputPath));
        }
    }

    #endregion Protected Methods
}
