using System;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using PoshJohn.Enums;
using PoshJohn.Models;

namespace PoshJohn.Common
{
    internal interface IFileSystemProvider
    {
        void RefreshPotFile();

        string PotPath { get; }
        string Pdf2JohnPythonScriptPath { get; }
        string Zip2JohnExePath { get; }
        string VenvPythonExePath { get; }
        string SystemPythonExePath { get; }
        string VenvDirectoryPath { get; }
        string JohnExePath { get; }
        string FileToCrackPath { get; }
        FileFormatType FileToCrackFileFormat { get; }
        string HashFilePath { get; set; }
        Dictionary<string, string> LoadedPotHashPasswords { get; }
        Dictionary<FileFormatType, Dictionary<string, string>> LoadedInputHashEntries { get; }
        Dictionary<string, string> LabelToFilePaths { get; }
    }

    internal class FileSystemProvider : IFileSystemProvider
    {
        private const string JohnDirName = "john";
        private const string JohnExeBaseName = "john";
        private const string JohnPotFileName = "john.pot";
        private const string JohnRunDirName = "run";
        private const string Pdf2JohnPythonScriptName = "pdf2john.py";
        private const string Zip2JohnExeBaseName = "zip2john";
        private const string WindowsPythonExe = "python.exe";
        private const string UnixPythonExe = "python3";
        private const string WindowsVenvScriptsFolder = "Scripts";
        private const string UnixVenvBinFolder = "bin";
        private const string VenvName = "venv";
        private const string PdfFileExtension = ".pdf";
        private const string ZipFileExtension = ".zip";
        private const string ExeFileExtension = ".exe";
        private const string PdfHashPrefix = "$pdf$";
        private const string ZipHashPrefix = "$pkzip2$";

        private string _potPath;
        private PSCmdlet _cmdlet;
        private string _fileToCrackPath;
        private string _hashFilePath;
        private string _appDataDirectory;
        private string _packageAssemblyDirectory;
        private string _pdf2JohnPythonScriptPath;
        private string _venvDirectoryPath;
        private string _venvPythonExePath;
        private string _systemPythonExePath;
        private string _johnExecutablePath;
        private string _zip2JohnExecutablePath;
        private readonly Dictionary<FileFormatType, Dictionary<string, string>> _loadedInputHashEntries = new();
        private readonly Dictionary<string, string> _loadedPotHashPasswords = new(StringComparer.OrdinalIgnoreCase);
        private readonly Dictionary<string, string> _labelToFilePaths = new(StringComparer.OrdinalIgnoreCase);
        private FileFormatType _fileToCrackFileFormat;

        public string PotPath => _potPath;
        public string Pdf2JohnPythonScriptPath => _pdf2JohnPythonScriptPath;
        public string Zip2JohnExePath => _zip2JohnExecutablePath;
        public string VenvPythonExePath => _venvPythonExePath;
        public string SystemPythonExePath => _systemPythonExePath;
        public string VenvDirectoryPath => _venvDirectoryPath;
        public string JohnExePath => _johnExecutablePath;
        public string FileToCrackPath => _fileToCrackPath;
        public FileFormatType FileToCrackFileFormat => _fileToCrackFileFormat;
        public string HashFilePath
        {
            get => _hashFilePath;
            set
            {
                _hashFilePath = value;
                ParseHashEntries(_hashFilePath);
            }
        }
        public Dictionary<string, string> LoadedPotHashPasswords => _loadedPotHashPasswords;
        public Dictionary<FileFormatType, Dictionary<string, string>> LoadedInputHashEntries => _loadedInputHashEntries;
        public Dictionary<string, string> LabelToFilePaths => _labelToFilePaths;

        public FileSystemProvider()
        {
            _appDataDirectory = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                Assembly.GetExecutingAssembly().GetName().Name);

            _packageAssemblyDirectory = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            _johnExecutablePath = FindBundledExePath(JohnExeBaseName);
            _zip2JohnExecutablePath = FindBundledExePath(Zip2JohnExeBaseName);
            _venvDirectoryPath = GetAppDataSubPath(VenvName);
            _venvPythonExePath = GetVenvPythonExePath(_venvDirectoryPath);
            _systemPythonExePath = DetectSystemPythonExePath();
            _potPath = GetAppDataSubPath(JohnPotFileName);
            _pdf2JohnPythonScriptPath = GetPackageAssemblyResourcePath(JohnDirName, JohnRunDirName, Pdf2JohnPythonScriptName);
        }

        public FileSystemProvider(PSCmdlet cmdlet) : this()
        {
            _cmdlet = cmdlet;
        }

        public FileSystemProvider(ExportHashConfig config) : this(config.Cmdlet)
        {
            _fileToCrackPath = config.FileToCrackPath;
            _fileToCrackFileFormat = DetectFileToCrackFormat();
            _hashFilePath = config.HashFilePath;
        }

        public FileSystemProvider(PasswordCrackConfig config) : this(config.Cmdlet)
        {
            _hashFilePath = config.HashFilePath;

            if (!string.IsNullOrEmpty(config.CustomPotPath))
            {
                _potPath = config.CustomPotPath;
            }

            ParseKeyValuePotFile(_potPath);
            ParseHashEntries(_hashFilePath);
        }

        private string GetAppDataSubPath(params string[] paths)
            => Path.Combine(_appDataDirectory, Path.Combine(paths));

        private string GetPackageAssemblyResourcePath(params string[] paths)
        {
            string subPath = Path.Combine(paths);
            string resourcePath = Path.Combine(_packageAssemblyDirectory, subPath);

            if (!File.Exists(resourcePath))
            {
                throw new FileNotFoundException($"Required resource '{subPath}' not found in package directory '{_packageAssemblyDirectory}'.", resourcePath);
            }

            return resourcePath;
        }

        private string FindBundledExePath(string baseName)
        {
            string exeName = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
                ? $"{baseName}{ExeFileExtension}"
                : baseName;

            return GetPackageAssemblyResourcePath(JohnDirName, JohnRunDirName, exeName);
        }

        private static string GetVenvPythonExePath(string venvPath)
        {
            return RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
                ? Path.Combine(venvPath, WindowsVenvScriptsFolder, WindowsPythonExe)
                : Path.Combine(venvPath, UnixVenvBinFolder, UnixPythonExe);
        }

        private static string DetectSystemPythonExePath()
        {
            string systemPythonExePath = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
                ? FindInPath(WindowsPythonExe)
                : FindInPath(UnixPythonExe);

            if (string.IsNullOrEmpty(systemPythonExePath))
            {
                throw new InvalidOperationException("Python interpreter not found. Please ensure Python is installed and added to PATH.");
            }

            return systemPythonExePath;
        }
        private static string FindInPath(string fileName)
        {
            var paths = Environment.GetEnvironmentVariable("PATH")?.Split(Path.PathSeparator) ?? Array.Empty<string>();
            foreach (var path in paths)
            {
                try
                {
                    var fullPath = Path.Combine(path, fileName);
                    if (File.Exists(fullPath))
                    {
                        return fullPath;
                    }
                }
                catch
                {
                    // Skip invalid path entries
                }
            }
            return null;
        }

        private void ParseKeyValuePotFile(string filePath)
        {
            if (!File.Exists(filePath))
            {
                _cmdlet?.WriteDebug("Pot file does not exist. Skipping pot file parsing.");
                return;
            }

            _cmdlet?.WriteVerbose($"Parsing pot file: {filePath}");

            foreach (var line in File.ReadLines(filePath))
            {
                var hashAndPassword = line.Split(':', 2);
                if (hashAndPassword.Length != 2)
                {
                    _cmdlet?.WriteDebug($"Invalid pot file line format: {line}. Skipping this line.");
                    continue;
                }

                string hash = hashAndPassword[0];
                string password = hashAndPassword[1];
                _loadedPotHashPasswords[hash] = password;
            }
        }

        private void ParseHashEntries(string filePath)
        {
            if (!File.Exists(filePath))
            {
                _cmdlet?.WriteDebug("Hash file does not exist. Skipping hash file parsing.");
                return;
            }

            _cmdlet?.WriteVerbose($"Parsing hash entries from file: {filePath}");

            foreach (var line in File.ReadLines(filePath))
            {
                var labelAndHash = line.Split(':', 2);
                if (labelAndHash.Length != 2)
                {
                    throw new InvalidDataException($"Invalid hash file line format: {line}. Each line must contain a label and hash separated by a colon (:).");
                }

                string label = labelAndHash[0].Trim();
                string hash = labelAndHash[1].Trim();

                _cmdlet?.WriteDebug($"Label: '{label}', Hash: '{hash}'");

                if (hash.StartsWith(PdfHashPrefix))
                {
                    if (!_loadedInputHashEntries.ContainsKey(FileFormatType.PDF))
                    {
                        _loadedInputHashEntries[FileFormatType.PDF] = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                    }

                    string pdfFilePath = Encoding.UTF8.GetString(Convert.FromBase64String(label));

                    _loadedInputHashEntries[FileFormatType.PDF][hash] = pdfFilePath;

                    _labelToFilePaths[label] = pdfFilePath;
                }
                else if (hash.StartsWith(ZipHashPrefix))
                {
                    if (!_loadedInputHashEntries.ContainsKey(FileFormatType.PKZIP))
                    {
                        _loadedInputHashEntries[FileFormatType.PKZIP] = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                    }

                    var zipHashWithFileMetadata = hash.Split("::", 2);
                    if (zipHashWithFileMetadata.Length != 2)
                    {
                        throw new InvalidDataException($"Invalid ZIP hash format in line: {line}. Missing double colon (::) when splitting {hash} into 2 parts.");
                    }

                    string zipHash = zipHashWithFileMetadata[0];
                    string zipFileMetadata = zipHashWithFileMetadata[1];

                    var zipFileMetadataParts = zipFileMetadata.Split(':', 3);
                    if (zipFileMetadataParts.Length != 3)
                    {
                        throw new InvalidDataException($"Invalid ZIP hash format in line: {line}. Missing colon (:) when splitting {zipFileMetadata} into 3 parts.");
                    }

                    string zipFilePath = zipFileMetadataParts[2];

                    _loadedInputHashEntries[FileFormatType.PKZIP][zipHash] = zipFilePath;

                    _labelToFilePaths[label] = zipFilePath;
                }
                else
                {
                    throw new InvalidDataException($"Unsupported hash format in line: {line}. Supported formats are {PdfHashPrefix} and {ZipHashPrefix}.");
                }
            }
        }

        public void RefreshPotFile()
        {
            if (!File.Exists(_potPath))
            {
                _cmdlet?.WriteVerbose("Pot file does not exist; no need to refresh.");
                return;
            }

            _cmdlet?.WriteWarning($"Refreshing pot file: {_potPath}");

            try
            {
                File.Delete(_potPath);
                _cmdlet?.WriteVerbose("Pot file refreshed successfully.");
            }
            catch (Exception ex)
            {
                _cmdlet?.WriteWarning($"Failed to refresh pot file: {ex.Message}");
            }
        }

        private FileFormatType DetectFileToCrackFormat()
        {
            var extension = Path.GetExtension(_fileToCrackPath).ToLowerInvariant();
            return extension switch
            {
                PdfFileExtension => FileFormatType.PDF,
                ZipFileExtension => FileFormatType.PKZIP,
                _ => throw new InvalidDataException($"Unsupported file format: {extension}"),
            };
        }
    }
}
