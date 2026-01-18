using System.Management.Automation;

namespace PoshJohn.Models;

/// <summary>
/// Base configuration for file system operations, including cmdlet context and hash file path.
/// </summary>
internal class FileSystemBaseConfig
{
    /// <summary>
    /// The PowerShell cmdlet instance for context and output.
    /// </summary>
    public PSCmdlet Cmdlet { get; init; }

    /// <summary>
    /// The path to the hash file.
    /// </summary>
    public string HashFilePath { get; init; }
}

/// <summary>
/// Configuration for exporting password hashes from a file.
/// </summary>
internal sealed class ExportHashConfig : FileSystemBaseConfig
{
    /// <summary>
    /// The path to the file to extract hashes from.
    /// </summary>
    public string FileToCrackPath { get; init; }

    /// <summary>
    /// Indicates whether Python integration is enabled.
    /// </summary>
    public bool IsPythonEnabled { get; init; }
}

/// <summary>
/// Configuration for password cracking operations, including custom pot file path.
/// </summary>
internal sealed class PasswordCrackConfig : FileSystemBaseConfig
{
    /// <summary>
    /// The path to a custom John the Ripper pot file, if specified.
    /// </summary>
    public string CustomPotPath { get; init; }

    /// <summary>
    /// The directory path where unlocked files should be saved.
    /// </summary>
    public string UnlockedFileDirectoryPath { get; init; }
}
