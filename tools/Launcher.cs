using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;
using System.Reflection;

[assembly: AssemblyTitle("BetterSteamTools Manager")]
[assembly: AssemblyDescription("Desktop launcher for BetterSteamTools Manager")]
[assembly: AssemblyVersion("1.0.0.0")]
internal static class Launcher
{
    [STAThread]
    private static int Main(string[] args)
    {
        string folder = AppDomain.CurrentDomain.BaseDirectory;
        string command = Path.Combine(folder, "Launch.cmd");
        string[] required = { "Launch.cmd", "Manager.ps1", "Core.ps1", "assets\\manager.ico" };
        bool check = args.Length == 1 && args[0] == "--check";
        foreach (string file in required)
        {
            if (!File.Exists(Path.Combine(folder, file)))
            {
                if (!check) MessageBox.Show("Missing: " + file + "\n\nExtract the complete app folder before opening the launcher.", "BetterSteamTools Manager", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return 1;
            }
        }
        if (check) return 0;
        try
        {
            ProcessStartInfo start = new ProcessStartInfo();
            start.FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "cmd.exe");
            start.Arguments = "/d /s /c \"\"" + command + "\"\"";
            start.WorkingDirectory = folder;
            start.UseShellExecute = false;
            start.CreateNoWindow = true;
            using (Process process = Process.Start(start))
            {
                process.WaitForExit();
                if (process.ExitCode != 0) throw new Exception("The command launcher returned code " + process.ExitCode + ".");
            }
            return 0;
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message, "Could not open BetterSteamTools Manager", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
