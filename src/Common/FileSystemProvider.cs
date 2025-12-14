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
    /// <summary>
    /// Provides an abstraction for file system operations and John the Ripper resource management.
    /// </summary>
    internal interface IFileSystemProvider
    {
        /// <summary>
        /// Deletes and refreshes the John the Ripper pot file.
        /// </summary>
        void RefreshPotFile();

        /// <summary>
        /// Gets the path to the John the Ripper pot file.
        /// </summary>
        string PotPath { get; }

        /// <summary>
        /// Gets the path to the pdf2john Python script.
        /// </summary>
        string Pdf2JohnPythonScriptPath { get; }

        /// <summary>
        /// Gets the path to the zip2john executable.
        /// </summary>
        string Zip2JohnExePath { get; }

        /// <summary>
        /// Gets the path to the Python executable in the virtual environment.
        /// </summary>
        string VenvPythonExePath { get; }

        /// <summary>
        /// Gets the path to the system Python executable.
        /// </summary>
        string SystemPythonExePath { get; }

        /// <summary>
        /// Gets the path to the virtual environment directory.
        /// </summary>
        string VenvDirectoryPath { get; }

        /// <summary>
        /// Gets the path to the John the Ripper executable.
        /// </summary>
        string JohnExePath { get; }

        /// <summary>
        /// Gets the path to the file to be cracked.
        /// </summary>
        string FileToCrackPath { get; }

        /// <summary>
        /// Gets the file format type of the file to be cracked.
        /// </summary>
        FileFormatType FileToCrackFileFormat { get; }

        /// <summary>
        /// Gets or sets the path to the hash file.
        /// </summary>
        string HashFilePath { get; set; }

        /// <summary>
        /// Gets the dictionary of loaded pot file hash-password pairs.
        /// </summary>
        Dictionary<string, string> LoadedPotHashPasswords { get; }

        /// <summary>
        /// Gets the dictionary of loaded input hash entries by file format.
        /// </summary>
        Dictionary<FileFormatType, Dictionary<string, string>> LoadedInputHashEntries { get; }

        /// <summary>
        /// Gets the dictionary mapping hash labels to file paths.
        /// </summary>
        Dictionary<string, string> LabelToFilePaths { get; }
    }

    /// <summary>
    /// Implements IFileSystemProvider for managing John the Ripper resources, hash files, and pot files.
    /// </summary>
    internal class FileSystemProvider : IFileSystemProvider
    {
        #region Private Members

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
        private const string WindowsZipHashPrefix = "$pkzip2$";
        private const string UnixZipHashPrefix = "$pkzip$";
        private static readonly string ZipHashPrefix = RuntimeInformation.IsOSPlatform(OSPlatform.Windows) ? WindowsZipHashPrefix : UnixZipHashPrefix;
        private const string WindowsOSPlatformName = "windows";
        private const string UnixOSPlatformName = "linux";
        private const string MacOSPlatformName = "macos";

        private readonly string _potPath;
        private readonly PSCmdlet _cmdlet;
        private readonly string _fileToCrackPath;
        private string _hashFilePath;
        private readonly string _appDataDirectory;
        private readonly string _packageAssemblyDirectory;
        private readonly string _pdf2JohnPythonScriptPath;
        private readonly string _venvDirectoryPath;
        private readonly string _venvPythonExePath;
        private readonly string _systemPythonExePath;
        private readonly string _johnExecutablePath;
        private readonly string _zip2JohnExecutablePath;
        private readonly Dictionary<FileFormatType, Dictionary<string, string>> _loadedInputHashEntries = new();
        private readonly Dictionary<string, string> _loadedPotHashPasswords = new(StringComparer.OrdinalIgnoreCase);
        private readonly Dictionary<string, string> _labelToFilePaths = new(StringComparer.OrdinalIgnoreCase);
        private readonly FileFormatType _fileToCrackFileFormat;

        #endregion Private Members

        #region Public Members

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

        /// <summary>
        /// Initializes a new instance of the FileSystemProvider class with default settings.
        /// </summary>
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
            _pdf2JohnPythonScriptPath = GetPackageAssemblyResourcePath(JohnDirName, DetectOSPlatform(), JohnRunDirName, Pdf2JohnPythonScriptName);
        }

        /// <summary>
        /// Initializes a new instance of the FileSystemProvider class with a PowerShell cmdlet context.
        /// </summary>
        /// <param name="cmdlet">The PowerShell cmdlet instance.</param>
        public FileSystemProvider(PSCmdlet cmdlet) : this()
        {
            _cmdlet = cmdlet;
        }

        /// <summary>
        /// Initializes a new instance of the FileSystemProvider class for hash export operations.
        /// </summary>
        /// <param name="config">The export hash configuration.</param>
        public FileSystemProvider(ExportHashConfig config) : this(config.Cmdlet)
        {
            _fileToCrackPath = config.FileToCrackPath;
            _fileToCrackFileFormat = DetectFileToCrackFormat();
            _hashFilePath = config.HashFilePath;
        }

        /// <summary>
        /// Initializes a new instance of the FileSystemProvider class for password cracking operations.
        /// </summary>
        /// <param name="config">The password crack configuration.</param>
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

        /// <inheritdoc/>
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

        #endregion Public Members

        #region Private Methods

        /// <summary>
        /// Detects the current operating system platform as a string.
        /// </summary>
        /// <returns>The OS platform name (windows, linux, or macos).</returns>
        /// <exception cref="PlatformNotSupportedException">Thrown if the OS is not supported.</exception>
        private static string DetectOSPlatform()
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                return WindowsOSPlatformName;
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                return UnixOSPlatformName;
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            {
                return MacOSPlatformName;
            }
            else
            {
                throw new PlatformNotSupportedException("Unsupported operating system platform.");
            }
        }

        /// <summary>
        /// Combines the app data directory with additional subpaths.
        /// </summary>
        /// <param name="paths">Subpaths to combine.</param>
        /// <returns>The combined path.</returns>
        private string GetAppDataSubPath(params string[] paths)
            => Path.Combine(_appDataDirectory, Path.Combine(paths));

        /// <summary>
        /// Gets the full path to a resource in the package assembly directory.
        /// </summary>
        /// <param name="paths">Subpaths to combine.</param>
        /// <returns>The full resource path.</returns>
        /// <exception cref="FileNotFoundException">Thrown if the resource is not found.</exception>
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

        /// <summary>
        /// Finds the path to a bundled executable for the current OS.
        /// </summary>
        /// <param name="baseName">The base name of the executable.</param>
        /// <returns>The full path to the executable.</returns>
        private string FindBundledExePath(string baseName)
        {
            string exeName = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
                ? $"{baseName}{ExeFileExtension}"
                : baseName;

            return GetPackageAssemblyResourcePath(JohnDirName, DetectOSPlatform(), JohnRunDirName, exeName);
        }

        /// <summary>
        /// Gets the path to the Python executable in a virtual environment.
        /// </summary>
        /// <param name="venvPath">The virtual environment path.</param>
        /// <returns>The full path to the Python executable.</returns>
        private static string GetVenvPythonExePath(string venvPath)
        {
            return RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
                ? Path.Combine(venvPath, WindowsVenvScriptsFolder, WindowsPythonExe)
                : Path.Combine(venvPath, UnixVenvBinFolder, UnixPythonExe);
        }

        /// <summary>
        /// Detects the system Python executable path.
        /// </summary>
        /// <returns>The path to the system Python executable.</returns>
        /// <exception cref="InvalidOperationException">Thrown if Python is not found.</exception>
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
        /// <summary>
        /// Finds a file in the system PATH.
        /// </summary>
        /// <param name="fileName">The file name to search for.</param>
        /// <returns>The full path if found; otherwise, null.</returns>
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

        /// <summary>
        /// Parses the John the Ripper pot file and loads hash-password pairs.
        /// </summary>
        /// <param name="filePath">The path to the pot file.</param>
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
                    _cmdlet?.WriteDebug($"Invalid pot file line format: '{line}'. Skipping this line.");
                    continue;
                }

                string hash = hashAndPassword[0];
                string password = hashAndPassword[1];
                _loadedPotHashPasswords[hash] = password;
            }
        }

        /// <summary>
        /// Parses the hash file and loads label-hash and file path mappings.
        /// </summary>
        /// <param name="filePath">The path to the hash file.</param>
        /// <exception cref="InvalidDataException">Thrown if the hash file format is invalid.</exception>
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
                    throw new InvalidDataException($"Invalid hash file line format: '{line}'. Each line must contain a label and hash separated by a colon (:).");
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
                        throw new InvalidDataException($"Invalid ZIP hash format in line: '{line}'. Missing double colon (::) when splitting {hash} into 2 parts.");
                    }

                    string zipHash = zipHashWithFileMetadata[0];
                    string zipFileMetadata = zipHashWithFileMetadata[1];

                    var zipFileMetadataParts = zipFileMetadata.Split(':', 3);
                    if (zipFileMetadataParts.Length != 3)
                    {
                        throw new InvalidDataException($"Invalid ZIP hash format in line: '{line}'. Missing colon (:) when splitting {zipFileMetadata} into 3 parts.");
                    }

                    string zipFilePath = zipFileMetadataParts[2];

                    _loadedInputHashEntries[FileFormatType.PKZIP][zipHash] = zipFilePath;

                    _labelToFilePaths[label] = zipFilePath;
                }
                else
                {
                    throw new InvalidDataException($"Unsupported hash format in line: '{line}'. Supported formats are {PdfHashPrefix} and {ZipHashPrefix}.");
                }
            }
        }

        /// <summary>
        /// Detects the file format of the file to crack based on its extension.
        /// </summary>
        /// <returns>The detected file format type.</returns>
        /// <exception cref="InvalidDataException">Thrown if the file format is not supported.</exception>
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

        #endregion Private Methods
    }
}
