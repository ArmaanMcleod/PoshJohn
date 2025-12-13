using System.Management.Automation;

namespace PoshJohn.Models;

internal class FileSystemBaseConfig
{
    public PSCmdlet Cmdlet { get; init; }
    public string HashFilePath { get; init; }
}

internal sealed class ExportHashConfig : FileSystemBaseConfig
{
    public string FileToCrackPath { get; init; }
}

internal sealed class PasswordCrackConfig : FileSystemBaseConfig
{
    public string CustomPotPath { get; init; }
}
