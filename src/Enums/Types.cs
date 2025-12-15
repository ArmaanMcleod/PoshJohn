namespace PoshJohn.Enums;

/// <summary>
/// Specifies the type of command or executable to run.
/// </summary>
internal enum CommandType
{
    /// <summary>
    /// John the Ripper executable.
    /// </summary>
    John,

    /// <summary>
    /// System Python interpreter.
    /// </summary>
    SystemPython,

    /// <summary>
    /// Python interpreter in the virtual environment.
    /// </summary>
    VenvPython,

    /// <summary>
    /// zip2john executable for extracting ZIP hashes.
    /// </summary>
    Zip2John,
}

/// <summary>
/// Specifies the supported file formats for hash extraction and cracking.
/// </summary>
public enum FileFormatType
{
    /// <summary>
    /// PKZIP (ZIP archive) file format.
    /// </summary>
    PKZIP,

    /// <summary>
    /// PDF file format.
    /// </summary>
    PDF
}
