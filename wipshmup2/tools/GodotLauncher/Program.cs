using System;
using System.Diagnostics;
using System.IO;
using System.Linq;

class Program
{
    static int Main(string[] args)
    {
        string godotPath = GetGodotPathFromArgs(args);
        string projectPath = GetProjectPathFromArgs(args);

        if (string.IsNullOrEmpty(godotPath) || !File.Exists(godotPath))
        {
            // Try to auto-detect common Godot install locations
            godotPath = FindGodotExecutable();
        }

        if (string.IsNullOrEmpty(godotPath) || !File.Exists(godotPath))
        {
            Console.Error.WriteLine("Godot executable not found. Provide path as first argument or set GODOT_PATH environment variable.");
            Console.WriteLine("Usage: GodotLauncher <path-to-godot-exe> [path-to-godot-project-folder]");
            return 1;
        }

        if (string.IsNullOrEmpty(projectPath))
        {
            projectPath = FindGodotProjectDirectory(Directory.GetCurrentDirectory());
        }

        if (string.IsNullOrEmpty(projectPath))
        {
            projectPath = Directory.GetCurrentDirectory();
        }

        var psi = new ProcessStartInfo
        {
            FileName = godotPath,
            Arguments = $"--path \"{projectPath}\"",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };

        try
        {
            using var proc = new Process { StartInfo = psi };

            proc.OutputDataReceived += (sender, e) =>
            {
                if (e.Data != null)
                    Console.WriteLine(e.Data);
            };
            proc.ErrorDataReceived += (sender, e) =>
            {
                if (e.Data != null)
                    Console.Error.WriteLine(e.Data);
            };

            proc.Start();

            proc.BeginOutputReadLine();
            proc.BeginErrorReadLine();

            Console.WriteLine($"Launched Godot: {godotPath} --path {projectPath}");
            proc.WaitForExit();
            return proc.ExitCode;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error launching Godot: {ex}");
            return 3;
        }
    }

    static string GetGodotPathFromArgs(string[] args)
    {
        if (args.Length >= 1 && !string.IsNullOrWhiteSpace(args[0]))
            return args[0];

        var env = Environment.GetEnvironmentVariable("GODOT_PATH");
        return env ?? string.Empty;
    }

    static string GetProjectPathFromArgs(string[] args)
    {
        if (args.Length >= 2 && !string.IsNullOrWhiteSpace(args[1]))
            return args[1];

        var env = Environment.GetEnvironmentVariable("GODOT_PROJECT_PATH");
        return env ?? string.Empty;
    }

    static string FindGodotProjectDirectory(string startPath)
    {
        var currentDir = new DirectoryInfo(startPath);
        while (currentDir != null)
        {
            if (File.Exists(Path.Combine(currentDir.FullName, "project.godot")))
            {
                return currentDir.FullName;
            }
            currentDir = currentDir.Parent;
        }
        return string.Empty; // Or fallback to a default
    }

    // Attempts to find a Godot executable in common install locations on Windows, macOS and Linux.
    static string FindGodotExecutable()
    {
        // Check environment variables first
        var env = Environment.GetEnvironmentVariable("GODOT_PATH");
        if (!string.IsNullOrWhiteSpace(env) && File.Exists(env))
            return env;

        // Common platform-specific locations
        if (OperatingSystem.IsWindows())
        {
            string programFiles = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
            string programFilesX86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
            string userLocal = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Godot");
            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);

            string[] dirs = new[]
            {
                programFiles,
                programFilesX86,
                Path.Combine(programFiles, "Godot"),
                Path.Combine(programFilesX86, "Godot"),
                userLocal,
                Path.Combine(userProfile, "Downloads"),
                Path.Combine(userProfile, "AppData", "Local", "Programs", "Godot")
            };

            foreach (var d in dirs.Where(d => !string.IsNullOrEmpty(d) && Directory.Exists(d)))
            {
                try
                {
                    var files = Directory.GetFiles(d, "Godot*.exe", SearchOption.TopDirectoryOnly)
                        .Concat(Directory.GetFiles(d, "Godot*.exe", SearchOption.AllDirectories));

                    var monoFiles = Directory.GetFiles(d, "*mono*.exe", SearchOption.TopDirectoryOnly)
                        .Concat(Directory.GetFiles(d, "*mono*.exe", SearchOption.AllDirectories));

                    var candidate = files.Concat(monoFiles).FirstOrDefault(File.Exists);
                    if (candidate != null)
                        return candidate;
                }
                catch { /* ignore access errors */ }
            }

            // Also check typical standalone names in Program Files root
            string[] typicalNames = new[] { "Godot_mono.exe", "Godot.exe", "Godot_v*_*mono*.exe" };
            foreach (var name in typicalNames)
            {
                try
                {
                    var candidate = Directory.GetFiles(programFiles, name, SearchOption.AllDirectories).FirstOrDefault();
                    if (candidate != null)
                        return candidate;
                }
                catch { }
            }
        }
        else if (OperatingSystem.IsMacOS())
        {
            string[] macPaths = new[] { 
                "/Applications/Godot.app/Contents/MacOS/Godot",
                "/Applications/Godot_mono.app/Contents/MacOS/Godot"
            };
            foreach (var p in macPaths) if (File.Exists(p)) return p;
        }
        else // Linux
        {
            string[] linuxPaths = new[] { "/usr/bin/godot", "/usr/local/bin/godot", "/snap/bin/godot" };
            foreach (var p in linuxPaths) if (File.Exists(p)) return p;
        }

        return string.Empty;
    }
}
