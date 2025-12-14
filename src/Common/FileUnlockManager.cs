using System.IO;
using System.Management.Automation;
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
}

/// <summary>
/// Implements IFileUnlockManager for unlocking and saving PDF and ZIP files.
/// </summary>
internal sealed class FileUnlockManager : IFileUnlockManager
{
    private readonly PSCmdlet _cmdlet;

    /// <summary>
    /// Initializes a new instance of the FileUnlockManager class.
    /// </summary>
    /// <param name="cmdlet">The PowerShell cmdlet instance for verbose output.</param>
    public FileUnlockManager(PSCmdlet cmdlet)
    {
        _cmdlet = cmdlet;
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
            default:
                throw new InvalidDataException($"Unsupported file format for unlocking: {unlockResult.FileFormat}");
        }
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
}
