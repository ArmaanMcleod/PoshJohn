using System;
using System.IO;
using System.Management.Automation;
using PoshJohn.Enums;

namespace PoshJohn.Common;

internal interface IFileHashProvider
{
    string ExtractFileHash();
    void WriteFileHash(string hash, bool append);
}

internal sealed class FileHashProvider : IFileHashProvider
{
    private readonly IFileSystemProvider _fileSystemProvider;
    private readonly IProcessRunner _processRunner;
    private readonly PSCmdlet _cmdlet;

    internal FileHashProvider(PSCmdlet cmdlet, IFileSystemProvider fileSystemProvider, IProcessRunner processRunner)
    {
        _fileSystemProvider = fileSystemProvider;
        _processRunner = processRunner;
        _cmdlet = cmdlet;
    }

    public string ExtractFileHash()
    {
        var fileFormat = _fileSystemProvider.FileToCrackFileFormat;
        return fileFormat switch
        {
            FileFormatType.PDF => ExtractPdfJohnHash(_fileSystemProvider.FileToCrackPath),
            FileFormatType.PKZIP => ExtractZipJohnHash(_fileSystemProvider.FileToCrackPath),
            _ => throw new InvalidDataException($"Unsupported file format for hash extraction: {fileFormat}"),
        };
    }

    public void WriteFileHash(string hash, bool append)
    {
        _cmdlet?.WriteVerbose($"Writing hash to output file: {_fileSystemProvider.HashFilePath}");

        string line;

        var fileFormat = _fileSystemProvider.FileToCrackFileFormat;
        switch (fileFormat)
        {
            case FileFormatType.PDF:
                string base64PathLabel = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(Path.GetFullPath(_fileSystemProvider.FileToCrackPath)));
                line = $"{base64PathLabel}:{hash}" + Environment.NewLine;
                break;
            case FileFormatType.PKZIP:
                line = hash + Environment.NewLine;
                break;
            default:
                throw new InvalidDataException($"Unsupported file format for writing hash: {fileFormat}");
        }

        if (append)
        {
            File.AppendAllText(_fileSystemProvider.HashFilePath, line);
        }
        else
        {
            File.WriteAllText(_fileSystemProvider.HashFilePath, line);
        }
    }

    private string ExtractPdfJohnHash(string pdfPath)
    {
        _cmdlet?.WriteVerbose("Extracting PDF John hash");

        var scriptResult = _processRunner.RunCommand(
            CommandType.VenvPython,
            $"\"{_fileSystemProvider.Pdf2JohnPythonScriptPath}\" \"{pdfPath}\"",
            logOutput: false,
            failOnStderr: true);

        if (!scriptResult.Success)
        {
            throw new InvalidOperationException($"Failed to extract PDF hash: {scriptResult.StandardError}");
        }

        return scriptResult.StandardOutput.Trim();
    }

    private string ExtractZipJohnHash(string zipPath)
    {
        _cmdlet?.WriteVerbose("Extracting ZIP John hash");

        var zip2JohnResult = _processRunner.RunCommand(
            CommandType.Zip2John,
            $"\"{zipPath}\"",
            logOutput: true,
            failOnStderr: false);

        if (!zip2JohnResult.Success)
        {
            throw new InvalidOperationException($"Failed to extract ZIP hash: {zip2JohnResult.StandardError}");
        }

        return zip2JohnResult.StandardOutput.Trim();
    }
}
