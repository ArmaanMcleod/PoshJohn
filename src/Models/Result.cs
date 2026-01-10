using System.Collections.Generic;
using System.IO;
using PoshJohn.Enums;

namespace PoshJohn.Models;

/// <summary>
/// Represents the result of a hash extraction operation.
/// </summary>
public sealed class HashResult
{
    /// <summary>
    /// The extracted hash string.
    /// </summary>
    public string Hash { get; init; }

    /// <summary>
    /// The path to the file containing the hash.
    /// </summary>
    public string HashFilePath { get; init; }
}

/// <summary>
/// Represents the result of a password cracking operation.
/// </summary>
public sealed class PasswordCrackResult
{
    /// <summary>
    /// The raw output from the cracking tool.
    /// </summary>
    public string RawOutput { get; init; }

    /// <summary>
    /// The path to the pot file used or generated.
    /// </summary>
    public string PotPath { get; init; }

    /// <summary>
    /// The summary of the password cracking operation.
    /// </summary>
    public PasswordCrackSummary Summary { get; init; }
}

/// <summary>
/// Represents a summary of password cracking results, grouped by format.
/// </summary>
public sealed class PasswordCrackSummary
{
    /// <summary>
    /// The list of format groups found in the cracking results.
    /// </summary>
    public List<FormatGroup> FormatGroups { get; init; }
}

/// <summary>
/// Represents a group of cracked hashes for a specific file format.
/// </summary>
public sealed class FormatGroup
{
    /// <summary>
    /// The file format type (e.g., PDF, PKZIP).
    /// </summary>
    public FileFormatType FileFormat { get; init; }

    /// <summary>
    /// The number of password hashes in this group.
    /// </summary>
    public int PasswordHashCount { get; init; }

    /// <summary>
    /// The number of salts in this group.
    /// </summary>
    public int SaltsCount { get; init; }

    /// <summary>
    /// The encryption algorithms used in this group.
    /// </summary>
    public string EncryptionAlgorithms { get; init; }

    /// <summary>
    /// The dictionary of file paths to password unlock results.
    /// </summary>
    public Dictionary<string, PasswordUnlockResult> FilePasswords { get; init; }
}

/// <summary>
/// Represents the result of unlocking a password-protected file.
/// </summary>
public sealed class PasswordUnlockResult
{
    /// <summary>
    /// The file format type (e.g., PDF, PKZIP).
    /// </summary>
    public FileFormatType FileFormat { get; init; }

    /// <summary>
    /// The path to the original file.
    /// </summary>
    public string FilePath { get; init; }

    /// <summary>
    /// The cracked password for the file.
    /// </summary>
    public string Password { get; init; }

    /// <summary>
    /// The path to the unlocked file that was saved.
    /// </summary>
    public string UnlockedFilePath { get; init; }
}

/// <summary>
/// Represents the result of running an external process or command.
/// </summary>
internal sealed class ProcessResult
{
    /// <summary>
    /// Indicates whether the process completed successfully.
    /// </summary>
    public bool Success { get; init; }

    /// <summary>
    /// The standard output produced by the process.
    /// </summary>
    public string StandardOutput { get; init; }

    /// <summary>
    /// The standard error output produced by the process.
    /// </summary>
    public string StandardError { get; init; }
}
