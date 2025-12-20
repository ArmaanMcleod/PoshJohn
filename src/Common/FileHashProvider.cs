using System;
using System.IO;
using System.Management.Automation;
using System.Reflection;
using System.Runtime.InteropServices;
using PoshJohn.Enums;

namespace PoshJohn.Common;

/// <summary>
/// Provides methods for extracting and writing password hashes from files for use with John the Ripper.
/// </summary>
internal interface IFileHashProvider
{
    /// <summary>
    /// Extracts a password hash from the target file.
    /// </summary>
    /// <returns>The extracted hash string.</returns>
    string ExtractFileHash();

    /// <summary>
    /// Writes a password hash to the output file.
    /// Can either append or overwrite based on the append parameter.
    /// </summary>
    /// <param name="hash">The hash string to write.</param>
    /// <param name="append">If true, appends to the file; otherwise, overwrites.</param>
    void WriteFileHash(string hash, bool append);
}

/// <summary>
/// Implements IFileHashProvider for extracting and writing password hashes from PDF and ZIP files.
/// </summary>
internal sealed class FileHashProvider : IFileHashProvider
{
    private readonly IFileSystemProvider _fileSystemProvider;
    private readonly IProcessRunner _processRunner;
    private readonly PSCmdlet _cmdlet;

    private const string WindowsPdfHashDll = "pdfhash.dll";
    private const string LinuxPdfHashSo = "libpdfhash.so";
    private const string MacOsPdfHashDylib = "libpdfhash.dylib";

    [DllImport("pdfhash", EntryPoint = "get_pdf_hash", CallingConvention = CallingConvention.Cdecl)]
    private static extern IntPtr get_pdf_hash([MarshalAs(UnmanagedType.LPUTF8Str)] string path);

    [DllImport("pdfhash", EntryPoint = "free_pdf_hash", CallingConvention = CallingConvention.Cdecl)]
    private static extern void free_pdf_hash(IntPtr ptr);

    /// <summary>
    /// Initializes a new instance of the FileHashProvider class.
    /// </summary>
    /// <param name="cmdlet">The PowerShell cmdlet instance.</param>
    /// <param name="fileSystemProvider">The file system provider.</param>
    /// <param name="processRunner">The process runner.</param>
    internal FileHashProvider(PSCmdlet cmdlet, IFileSystemProvider fileSystemProvider, IProcessRunner processRunner)
    {
        _fileSystemProvider = fileSystemProvider;
        _processRunner = processRunner;
        _cmdlet = cmdlet;
    }

    static FileHashProvider()
    {
        NativeLibrary.SetDllImportResolver(typeof(FileHashProvider).Assembly, (name, assembly, path) =>
        {
            string libraryName =
                OperatingSystem.IsWindows() ? WindowsPdfHashDll :
                OperatingSystem.IsLinux() ? LinuxPdfHashSo :
                OperatingSystem.IsMacOS() ? MacOsPdfHashDylib :
                throw new PlatformNotSupportedException();

            string libraryPath = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), libraryName);

            IntPtr handle = NativeLibrary.Load(libraryPath);

            return handle;
        });
    }

    /// <inheritdoc/>
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

    /// <inheritdoc/>
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

    /// <summary>
    /// Extracts a John the Ripper-compatible hash from a PDF file using the pdf2john script.
    /// </summary>
    /// <param name="pdfPath">The path to the PDF file.</param>
    /// <returns>The extracted hash string.</returns>
    /// <exception cref="InvalidOperationException">Thrown if the hash extraction fails.</exception>
    private string ExtractPdfJohnHash(string pdfPath)
    {
        _cmdlet?.WriteVerbose("Extracting PDF John hash");

        IntPtr ptr = get_pdf_hash(pdfPath);
        if (ptr == IntPtr.Zero)
        {
            throw new Exception("get_pdf_hash returned null");
        }

        try
        {
            return Marshal.PtrToStringUTF8(ptr)!;
        }
        finally
        {
            free_pdf_hash(ptr);
        }
    }

    /// <summary>
    /// Extracts a John the Ripper-compatible hash from a ZIP file using the zip2john utility.
    /// </summary>
    /// <param name="zipPath">The path to the ZIP file.</param>
    /// <returns>The extracted hash string.</returns>
    /// <exception cref="InvalidOperationException">Thrown if the hash extraction fails.</exception>
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
