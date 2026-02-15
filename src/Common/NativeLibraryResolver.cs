
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

namespace PoshJohn.Common;

internal static class NativeLibraryResolver
{
    private static readonly Dictionary<string, Func<string>> LibraryPathResolvers = new()
    {
        { "libarchive7z_shared", GetArchive7zLibraryPath },
        { "libpdfhash", GetPdf2JohnLibraryPath }
    };

    private static bool _initialized = false;

    public static void Initialize()
    {
        if (_initialized)
        {
            return;
        }
        _initialized = true;

        NativeLibrary.SetDllImportResolver(typeof(NativeLibraryResolver).Assembly, (name, assembly, path) =>
        {
            if (LibraryPathResolvers.TryGetValue(name, out var pathResolver))
            {
                string libraryPath = pathResolver();
                IntPtr handle = NativeLibrary.Load(libraryPath);
                return handle;
            }
            return IntPtr.Zero;
        });
    }

    private static string GetPdf2JohnLibraryPath()
    {
        string subLibraryPath =
                OperatingSystem.IsWindows() ? Path.Combine("pdf2john", "libpdfhash.dll") :
                OperatingSystem.IsLinux() ? Path.Combine("pdf2john", "libpdfhash.so") :
                OperatingSystem.IsMacOS() ? Path.Combine("pdf2john", "libpdfhash.dylib") :
                throw new PlatformNotSupportedException();

        string libraryPath = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), subLibraryPath);
        return libraryPath;
    }

    private static string GetArchive7zLibraryPath()
    {
        string subLibraryPath =
                OperatingSystem.IsWindows() ? Path.Combine("archive7z", "libarchive7z_shared.dll") :
                OperatingSystem.IsLinux() ? Path.Combine("archive7z", "libarchive7z_shared.so") :
                OperatingSystem.IsMacOS() ? Path.Combine("archive7z", "libarchive7z_shared.dylib") :
                throw new PlatformNotSupportedException();

        string libraryPath = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), subLibraryPath);
        return libraryPath;
    }
}
