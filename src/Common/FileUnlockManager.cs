using System.IO;
using System.Management.Automation;
using ICSharpCode.SharpZipLib.Zip;
using iText.Kernel.Exceptions;
using iText.Kernel.Pdf;
using PoshJohn.Enums;
using PoshJohn.Models;
using SharpCompress.Common;
using SharpCompress.Readers;
using SharpCompress.Writers;

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
    private void SaveUnlockedPasswordProtected7Zip(PasswordUnlockResult unlockResult)
    {
        _cmdlet?.WriteVerbose($"Unlocking 7-Zip: {unlockResult.FilePath}");
        _cmdlet?.WriteVerbose($"Saving unlocked 7-Zip to: {unlockResult.UnlockedFilePath}");

        var tempDir = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
        Directory.CreateDirectory(tempDir);
        try
        {
            using (var fileStream = File.OpenRead(unlockResult.FilePath))
            using (var reader = ReaderFactory.Open(fileStream, new ReaderOptions { Password = unlockResult.Password }))
            {
                var options = new ExtractionOptions { ExtractFullPath = true, Overwrite = true };
                while (reader.MoveToNextEntry())
                {
                    if (!reader.Entry.IsDirectory)
                    {
                        reader.WriteEntryToDirectory(tempDir, options);
                    }
                }
            }

            using var destStream = File.Create(unlockResult.UnlockedFilePath);
            using var writer = WriterFactory.Open(destStream, ArchiveType.SevenZip, CompressionType.LZMA);
            foreach (var filePath in Directory.EnumerateFiles(tempDir, "*", SearchOption.AllDirectories))
            {
                var entryName = Path.GetRelativePath(tempDir, filePath);
                using var fileStream = File.OpenRead(filePath);
                writer.Write(entryName, fileStream);
            }
        }
        finally
        {
            Directory.Delete(tempDir, true);
        }
    }
}
