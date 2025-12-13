using System.Collections.Generic;
using System.IO;
using PoshJohn.Enums;

namespace PoshJohn.Models;

public sealed class HashResult
{
    public string Hash { get; init; }
    public string HashFilePath { get; init; }
}

public sealed class PasswordCrackResult
{
    public string RawOutput { get; init; }
    public string PotPath { get; init; }
    public PasswordCrackSummary Summary { get; init; }
}

public sealed class PasswordCrackSummary
{
    public List<FormatGroup> FormatGroups { get; init; }
}

public sealed class FormatGroup
{
    public FileFormatType FileFormat { get; init; }
    public int PasswordHashCount { get; init; }
    public int SaltsCount { get; init; }
    public string EncryptionAlgorithms { get; init; }
    public Dictionary<string, PasswordUnlockResult> FilePasswords { get; init; }
}

public sealed class PasswordUnlockResult
{
    public FileFormatType FileFormat { get; init; }
    public string FilePath { get; init; }
    public string Password { get; init; }
    public string UnlockedFilePath { get; init; }

    private readonly string _unlockedFileDirectoryPath;

    private const string UnlockedFileSuffix = "_unlocked";

    public PasswordUnlockResult(string filePath, string password, FileFormatType fileFormat)
    {
        FilePath = filePath;
        Password = password;
        FileFormat = fileFormat;
    }

    public PasswordUnlockResult(string filePath, string password, FileFormatType fileFormat, string unlockedFileDirectoryPath) : this(filePath, password, fileFormat)
    {
        _unlockedFileDirectoryPath = unlockedFileDirectoryPath;

        if (string.IsNullOrEmpty(_unlockedFileDirectoryPath))
        {
            _unlockedFileDirectoryPath = Path.GetDirectoryName(filePath);
        }

        var extension = Path.GetExtension(filePath);
        var fileNameWithoutExtension = Path.GetFileNameWithoutExtension(filePath);
        UnlockedFilePath = Path.Combine(_unlockedFileDirectoryPath, $"{fileNameWithoutExtension}{UnlockedFileSuffix}{extension}");
    }
}

internal sealed class ProcessResult
{
    public bool Success { get; init; }
    public string StandardOutput { get; init; }
    public string StandardError { get; init; }
}
