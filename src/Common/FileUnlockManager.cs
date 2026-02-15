using System;
using System.IO;
using System.Management.Automation;
using System.Runtime.InteropServices;
using ICSharpCode.SharpZipLib.Zip;
using iText.Kernel.Exceptions;
using iText.Kernel.Pdf;
using PoshJohn.Enums;
using PoshJohn.Models;

namespace PoshJohn.Common;

/// <summary>
/// Provides an abstraction for unlocking and saving password-protected files.
/// </summary>
internal interface IFileUnlockManager
{
    /// <summary>
    /// Unlocks and saves a password-protected file using the provided unlock result.
    /// </summary>
    /// <param name="unlockResult">The result containing file, password, and format information.</param>
    void SaveAndUnlockPasswordProtectedFile(PasswordUnlockResult unlockResult);

    /// <summary>
    /// Generates the file path for the unlocked version of the file.
    /// </summary>
    /// <param name="filePath">The original file path.</param>
    /// <returns>The file path for the unlocked file.</returns>
    string GetUnlockedFilePath(string filePath);
}

/// <summary>
/// Implements IFileUnlockManager for unlocking and saving PDF and ZIP files.
/// </summary>
internal sealed class FileUnlockManager : IFileUnlockManager
{
    private readonly PSCmdlet _cmdlet;
    private readonly IFileSystemProvider _fileSystemProvider;
    private readonly string _unlockedFileDirectoryPath;

    private const string UnlockedFileSuffix = "_unlocked";

    public enum Archive7zResult
    {
        Ok = 0,
        InvalidArgument = 1,
        Io = 2,
        Format = 3,
        Internal = 4
    }

    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    private delegate void Archive7zLogCallback(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string message);

    [DllImport("libarchive7z_shared", CallingConvention = CallingConvention.Cdecl)]
    private static extern void archive7z_set_log_callback(Archive7zLogCallback cb);

    [DllImport("libarchive7z_shared", CallingConvention = CallingConvention.Cdecl)]
    private static extern Archive7zResult repack_7z_without_password(
        [MarshalAs(UnmanagedType.LPUTF8Str)] string inputPath,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string password,
        [MarshalAs(UnmanagedType.LPUTF8Str)] string outputPath);

    private static readonly object _logLock = new();
    private static bool _logRegistered;
    private static string _lastNativeLog;
    private static readonly Archive7zLogCallback _logCallback = msg => _lastNativeLog = msg;

    /// <summary>
    /// Initializes a new instance of the FileUnlockManager class.
    /// </summary>
    /// <param name="cmdlet">The PowerShell cmdlet instance for verbose output.</param>
    /// <param name="fileSystemProvider">The file system provider for path resolution.</param>
    public FileUnlockManager(PSCmdlet cmdlet, IFileSystemProvider fileSystemProvider)
    {
        _cmdlet = cmdlet;
        _fileSystemProvider = fileSystemProvider;
        _unlockedFileDirectoryPath = _fileSystemProvider.UnlockedFileDirectoryPath;
    }

    /// <inheritdoc/>
    public void SaveAndUnlockPasswordProtectedFile(PasswordUnlockResult unlockResult)
    {
        switch (unlockResult.FileFormat)
        {
            case FileFormatType.PDF:
                SaveUnlockedPasswordProtectedPDF(unlockResult);
                break;
            case FileFormatType.PKZIP:
                SaveUnlockedPasswordProtectedZIP(unlockResult);
                break;
            case FileFormatType.SevenZip:
                SaveUnlockedPasswordProtected7Zip(unlockResult);
                break;
            default:
                throw new InvalidDataException($"Unsupported file format for unlocking: {unlockResult.FileFormat}");
        }
    }

    /// <summary>
    /// Generates the file path for the unlocked version of the file.
    /// </summary>
    /// <param name="unlockResult">The result containing file and password information.</param>
    /// <returns>The file path for the unlocked file.</returns>
    public string GetUnlockedFilePath(string filePath)
    {
        var originalFileName = Path.GetFileNameWithoutExtension(filePath);
        var originalExtension = Path.GetExtension(filePath);
        var unlockedFileName = $"{originalFileName}{UnlockedFileSuffix}{originalExtension}";

        // If a specific directory for unlocked files is provided, put file there
        if (!string.IsNullOrEmpty(_unlockedFileDirectoryPath))
        {
            return Path.Combine(_unlockedFileDirectoryPath, unlockedFileName);
        }

        // Otherwise, save in the same directory as the original file
        var originalDirectory = Path.GetDirectoryName(filePath);
        return Path.Combine(originalDirectory, unlockedFileName);
    }

    /// <summary>
    /// Unlocks a password-protected PDF file and saves the unlocked version.
    /// </summary>
    /// <param name="unlockResult">The result containing file, password, and output path information.</param>
    /// <exception cref="PdfException">Thrown if unlocking or saving the PDF fails.</exception>
    private void SaveUnlockedPasswordProtectedPDF(PasswordUnlockResult unlockResult)
    {
        _cmdlet?.WriteVerbose($"Unlocking PDF: {unlockResult.FilePath}");

        _cmdlet?.WriteVerbose($"Saving unlocked PDF to: {unlockResult.UnlockedFilePath}");

        try
        {
            var properties = new ReaderProperties().SetPassword(System.Text.Encoding.UTF8.GetBytes(unlockResult.Password));
            using var reader = new PdfReader(unlockResult.FilePath, properties);
            using var pdfDoc = new PdfDocument(reader);
            using var writer = new PdfWriter(unlockResult.UnlockedFilePath);
            using var newPdfDoc = new PdfDocument(writer);

            pdfDoc.CopyPagesTo(1, pdfDoc.GetNumberOfPages(), newPdfDoc);
            newPdfDoc.Close();
        }
        catch (PdfException ex)
        {
            var details = ex.InnerException?.Message ?? "No inner exception.";
            throw new PdfException($"Failed to create PDF: {ex.Message} | Details: {details}", ex);
        }
    }

    /// <summary>
    /// Unlocks a password-protected ZIP file and saves the unlocked version.
    /// </summary>
    /// <param name="unlockResult">The result containing file, password, and output path information.</param>
    private void SaveUnlockedPasswordProtectedZIP(PasswordUnlockResult unlockResult)
    {
        _cmdlet?.WriteVerbose($"Unlocking ZIP: {unlockResult.FilePath}");

        _cmdlet?.WriteVerbose($"Saving unlocked ZIP to: {unlockResult.UnlockedFilePath}");

        using var sourceStream = File.OpenRead(unlockResult.FilePath);
        using var zipFile = new ZipFile(sourceStream);
        using var destStream = File.Create(unlockResult.UnlockedFilePath);
        using var zipOut = new ZipOutputStream(destStream);
        zipFile.Password = unlockResult.Password;

        foreach (ZipEntry entry in zipFile)
        {
            if (!entry.IsFile) continue;

            var buffer = new byte[4096];
            var newEntry = new ZipEntry(entry.Name)
            {
                DateTime = entry.DateTime,
                Size = entry.Size
            };
            zipOut.PutNextEntry(newEntry);

            using (var entryStream = zipFile.GetInputStream(entry))
            {
                int bytesRead;
                while ((bytesRead = entryStream.Read(buffer, 0, buffer.Length)) > 0)
                {
                    zipOut.Write(buffer, 0, bytesRead);
                }
            }
            zipOut.CloseEntry();
        }
    }

    private static void EnsureLogCallbackRegistered()
    {
        if (_logRegistered) return;

        lock (_logLock)
        {
            if (_logRegistered) return;

            archive7z_set_log_callback(_logCallback);
            _logRegistered = true;
        }
    }

    /// <summary>
    /// Unlocks a password-protected 7z archive and saves a new archive with no password.
    /// <para>
    /// This method performs a two-step process:
    /// 1. Extracts all files from the password-protected 7z archive to a temporary directory (using the provided password).
    /// 2. Re-archives the extracted files into a new 7z archive with no password, preserving the directory structure.
    /// </para>
    /// <para>
    /// This is necessary because SharpCompress does not support direct re-archiving from a password-protected archive to a new archive in one step.
    /// The temporary directory is cleaned up automatically after the process completes.
    /// </para>
    /// </summary>
    /// <param name="unlockResult">The result containing file, password, and output path information.</param>
    private static void SaveUnlockedPasswordProtected7Zip(PasswordUnlockResult unlockResult)
    {
        EnsureLogCallbackRegistered();
        _lastNativeLog = null;

        var result = repack_7z_without_password(
            unlockResult.FilePath,
            unlockResult.Password,
            unlockResult.UnlockedFilePath);

        if (result != Archive7zResult.Ok)
        {
            string nativeMessage = _lastNativeLog ?? "No native error message provided.";
            string finalMessage = $"Native error ({result}): {nativeMessage}";
            throw new InvalidOperationException(finalMessage);
        }
    }
}
