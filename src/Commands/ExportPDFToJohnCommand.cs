using System;
using System.IO;
using System.Management.Automation;
using System.Reflection;
using System.Runtime.InteropServices;

namespace PoshJohn.Commands;

[Cmdlet(VerbsData.Export, "PDFToJohn")]
public sealed class ExportPDFToJohnCommand : PSCmdlet
{
    [Parameter(Mandatory = true)]
    public string InputPath { get; set; }

    [Parameter(Mandatory = true)]
    public string OutputPath { get; set; }

    private const string VenvName = "pythonnet-venv";
    private const string WindowsPythonFileName = "python.exe";
    private const string UnixPythonFileName = "python3";
    private const string PyhankoModuleName = "pyhanko";
    private const string WindowsVenvScriptsFolder = "Scripts";
    private const string UnixVenvBinFolder = "bin";
    private const string PythonScriptName = "pdf2john.py";

    private string _venvPath;
    private bool _initialized;

    protected override void BeginProcessing()
    {
        try
        {
            string pythonPath = DetectPythonPath();

            if (string.IsNullOrEmpty(pythonPath))
            {
                throw new InvalidOperationException("Python interpreter not found. Please ensure Python is installed and added to PATH.");
            }

            string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            _venvPath = Path.Combine(localAppData, GetType().Namespace.Split('.')[0], VenvName);

            CreateVirtualEnvironment(pythonPath, _venvPath);
            InstallPackage(_venvPath, PyhankoModuleName);

            _initialized = true;
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(
                ex,
                "VenvSetupFailed",
                ErrorCategory.InvalidOperation,
                null));
            _initialized = false;
        }
    }

    protected override void ProcessRecord()
    {
        if (!_initialized)
        {
            return;
        }

        try
        {
            if (!File.Exists(InputPath))
            {
                throw new FileNotFoundException("Input file not found.", InputPath);
            }

            WriteVerbose($"Processing PDF file: {InputPath}");

            string hash = ExtractPdfHash(_venvPath, InputPath);

            if (string.IsNullOrWhiteSpace(hash))
            {
                throw new InvalidOperationException("Extracted hash is empty.");
            }

            File.WriteAllText(OutputPath, hash + Environment.NewLine);

            WriteObject($"Hash written to: {OutputPath}");
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(
                ex,
                "PDFProcessingFailed",
                ErrorCategory.InvalidOperation,
                InputPath));
        }
    }

    private string ExtractPdfHash(string venvPath, string pdfPath)
    {
        string venvPythonPath = GetVenvPythonPath(venvPath);

        string scriptPath = Path.Combine(
            Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location),
            PythonScriptName
        );

        WriteVerbose($"Extracting PDF hash using script: {scriptPath}");

        var result = RunPythonProcess(venvPythonPath, $"\"{scriptPath}\" \"{pdfPath}\"", logOutput: false);

        if (!result.Success)
        {
            throw new InvalidOperationException($"Failed to extract PDF hash: {result.StandardError}");
        }

        return result.StandardOutput.Trim();
    }

    private void CreateVirtualEnvironment(string pythonPath, string venvPath)
    {
        if (Directory.Exists(venvPath))
        {
            WriteVerbose($"Virtual environment already exists at: {venvPath}");
            return;
        }

        WriteVerbose($"Creating virtual environment at: {venvPath}");

        var result = RunPythonProcess(pythonPath, $"-m venv \"{venvPath}\"");

        if (!result.Success)
        {
            throw new InvalidOperationException($"Failed to create virtual environment: {result.StandardError}");
        }

        WriteVerbose($"Virtual environment created successfully at: {venvPath}");
    }

    private void InstallPackage(string venvPath, string packageName)
    {
        WriteVerbose($"Installing {packageName} package...");

        string venvPythonPath = GetVenvPythonPath(venvPath);

        var packageCheck = RunPythonProcess(venvPythonPath, $"-m pip show {packageName}", logOutput: false);

        if (packageCheck.Success)
        {
            WriteVerbose($"{packageName} is already installed");
            return;
        }

        var packageInstall = RunPythonProcess(venvPythonPath, $"-m pip install {packageName}");

        if (!packageInstall.Success)
        {
            throw new InvalidOperationException($"Failed to install {packageName}: {packageInstall.StandardError}");
        }

        WriteVerbose($"{packageName} installed successfully");
    }

    private static string GetVenvPythonPath(string venvPath)
    {
        return RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
            ? Path.Combine(venvPath, WindowsVenvScriptsFolder, WindowsPythonFileName)
            : Path.Combine(venvPath, UnixVenvBinFolder, UnixPythonFileName);
    }

    private PythonProcessResult RunPythonProcess(string pythonPath, string arguments, bool logOutput = true)
    {
        var startInfo = new System.Diagnostics.ProcessStartInfo
        {
            FileName = pythonPath,
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = System.Diagnostics.Process.Start(startInfo);
        string stdout = process.StandardOutput.ReadToEnd();
        string stderr = process.StandardError.ReadToEnd();
        process.WaitForExit();

        if (logOutput && !string.IsNullOrWhiteSpace(stdout))
        {
            WriteVerbose(stdout);
        }

        return new PythonProcessResult
        {
            Success = process.ExitCode == 0,
            StandardOutput = stdout,
            StandardError = stderr
        };
    }

    private sealed class PythonProcessResult
    {
        public bool Success { get; init; }
        public string StandardOutput { get; init; }
        public string StandardError { get; init; }
    }

    private static string DetectPythonPath()
    {
        return RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
            ? FindInPath(WindowsPythonFileName)
            : FindInPath(UnixPythonFileName);
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
}
