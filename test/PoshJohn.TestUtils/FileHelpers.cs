using System.Text;
using ICSharpCode.SharpZipLib.Zip;
using iText.Kernel.Pdf;
using iText.Layout;
using iText.Layout.Element;

namespace PoshJohn.TestUtils;

public static class FileHelpers
{
    public static string GetPasswordProtectedPDFEncryptionType(string filePath, string password)
    {
        try
        {
            var readerProps = new ReaderProperties();
            readerProps.SetPassword(Encoding.UTF8.GetBytes(password));
            var pdfReader = new PdfReader(filePath, readerProps);
            using var pdfDoc = new PdfDocument(pdfReader);
            var cryptoMode = pdfDoc.GetReader().GetCryptoMode();
            return cryptoMode switch
            {
                EncryptionConstants.ENCRYPTION_AES_128 => "AES-128",
                EncryptionConstants.ENCRYPTION_AES_256 => "AES-256",
                EncryptionConstants.STANDARD_ENCRYPTION_40 => "RC4-40",
                EncryptionConstants.STANDARD_ENCRYPTION_128 => "RC4-128",
                _ => "Unknown"
            };
        }
        catch (Exception ex)
        {
            var details = ex.InnerException != null ? ex.InnerException.Message : "No inner exception.";
            throw new Exception($"Failed to check PDF encryption: {ex.Message} | Details: {details}", ex);
        }
    }

    public static void CreateSamplePasswordProtectedPDF(string filePath, string password)
    {
        try
        {
            var writerProperties = new WriterProperties()
                .SetStandardEncryption(
                    Encoding.UTF8.GetBytes(password),
                    Encoding.UTF8.GetBytes(password),
                    EncryptionConstants.ALLOW_PRINTING,
                    EncryptionConstants.STANDARD_ENCRYPTION_40);

            using var writer = new PdfWriter(filePath, writerProperties);
            using var pdfDoc = new PdfDocument(writer);
            var document = new Document(pdfDoc);
            document.Add(new Paragraph("This is a sample PDF document."));
            document.Close();
        }
        catch (Exception ex)
        {
            var details = ex.InnerException != null ? ex.InnerException.Message : "No inner exception.";
            throw new Exception($"Failed to create PDF: {ex.Message} | Details: {details}", ex);
        }
    }

    public static bool CanOpenPDF(string filePath, string? password = null)
    {
        try
        {
            var readerProps = new ReaderProperties();
            if (password != null)
            {
                readerProps.SetPassword(Encoding.UTF8.GetBytes(password));
            }
            using var pdfReader = new PdfReader(filePath, readerProps);
            using var pdfDoc = new PdfDocument(pdfReader);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public static void CreatePDFWithNoPassword(string filePath)
    {
        try
        {
            using var writer = new PdfWriter(filePath);
            using var pdfDoc = new PdfDocument(writer);
            var document = new Document(pdfDoc);
            document.Add(new Paragraph("This is a sample PDF document with no password."));
            document.Close();
        }
        catch (Exception ex)
        {
            var details = ex.InnerException != null ? ex.InnerException.Message : "No inner exception.";
            throw new Exception($"Failed to create PDF: {ex.Message} | Details: {details}", ex);
        }
    }

    public static void CreatePasswordProtectedZip(string zipFilePath, string[] inputFiles, string password)
    {
        using var fs = File.Create(zipFilePath);
        using var zipStream = new ZipOutputStream(fs);
        zipStream.Password = password;

        foreach (var filePath in inputFiles)
        {
            var fileInfo = new FileInfo(filePath);
            var entry = new ZipEntry(fileInfo.Name)
            {
                DateTime = fileInfo.LastWriteTime,
                Size = fileInfo.Length
            };
            zipStream.PutNextEntry(entry);

            byte[] buffer = new byte[4096];
            using (var fileStream = File.OpenRead(filePath))
            {
                int bytesRead;
                while ((bytesRead = fileStream.Read(buffer, 0, buffer.Length)) > 0)
                {
                    zipStream.Write(buffer, 0, bytesRead);
                }
            }
            zipStream.CloseEntry();
        }
    }

    public static bool CanOpenZip(string zipFilePath, string? password = null)
    {
        try
        {
            using var fs = File.OpenRead(zipFilePath);
            using var zipFile = new ZipFile(fs);

            if (password != null)
            {
                zipFile.Password = password;
            }

            foreach (ZipEntry entry in zipFile)
            {
                if (!entry.IsFile) continue;

                using var entryStream = zipFile.GetInputStream(entry);
                byte[] buffer = new byte[4096];
                while (entryStream.Read(buffer, 0, buffer.Length) > 0)
                {
                    // Just read to verify password works
                }
            }

            return true;
        }
        catch
        {
            return false;
        }
    }
}
