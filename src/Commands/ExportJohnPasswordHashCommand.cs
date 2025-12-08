using System;
using System.IO;
using System.Management.Automation;
using PoshJohn.Common;
using PoshJohn.Enums;
using PoshJohn.Models;

namespace PoshJohn.Commands;

[Cmdlet(VerbsData.Export, "JohnPasswordHash")]
[OutputType(typeof(HashResult))]
public sealed class ExportJohnPasswordHashCommand : PSCmdlet
{
    [Parameter(Mandatory = true)]
    public string InputPath { get; set; }

    [Parameter(Mandatory = true)]
    [Alias("HashPath")]
    public string OutputPath { get; set; }

    [Parameter(Mandatory = false)]
    public SwitchParameter Append { get; set; }

    private const string PyhankoModuleName = "pyhanko";

    private bool _initialized;
    private IPythonEnvironmentManager _pythonEnvManager;
    private IProcessRunner _processRunner;
    private FileSystemProvider _fileSystemProvider;
    private IFileHashProvider _fileHashProvider;

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

            if (_fileSystemProvider.FileToCrackFileFormat == FileFormatType.PDF)
            {
                _pythonEnvManager = new PythonEnvironmentManager(this, _processRunner, _fileSystemProvider);

                _pythonEnvManager.CreateVirtualEnvironment();
                _pythonEnvManager.InstallPackage(PyhankoModuleName);
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
}
