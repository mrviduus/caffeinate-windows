using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

internal static class Program
{
    // --- Win32 interop ------------------------------------------------------
    [DllImport("kernel32.dll")]
    private static extern uint SetThreadExecutionState(uint esFlags);

    private const uint ES_CONTINUOUS        = 0x80000000;
    private const uint ES_SYSTEM_REQUIRED   = 0x00000001;
    private const uint ES_DISPLAY_REQUIRED  = 0x00000002;
    private const uint ES_USER_PRESENT      = 0x00000004;

    // --- entry point --------------------------------------------------------
    [STAThread]
    private static void Main(string[] args)
    {
        // --- 0. parse minimal flags ----------------------------------------
        bool keepDisplay = false, keepSystem = false;
        int  seconds     = 0;          // 0 == indefinite
        
        for (int i = 0; i < args.Length; i++)
        {
            switch (args[i])
            {
                case "-d": 
                    keepDisplay = true; 
                    break;
                case "-i":
                case "-s": 
                    keepSystem = true; 
                    break;
                case "-t":
                    if (i + 1 == args.Length || !int.TryParse(args[++i], out seconds))
                        Usage();       // exits
                    break;
                case "-h":
                case "--help":
                    Usage();
                    break;
                default:
                    Usage();
                    break;
            }
        }

        // Validate that at least one flag is specified
        if (!keepDisplay && !keepSystem)
        {
            Console.Error.WriteLine("Error: At least one flag (-d or -i/-s) must be specified.");
            Usage();
        }

        uint flags = ES_CONTINUOUS |
                     (keepDisplay ? ES_DISPLAY_REQUIRED : 0) |
                     (keepSystem  ? ES_SYSTEM_REQUIRED  : 0);

        // --- 1. start hidden, create tray icon -----------------------------
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        
        var icon = CreateCoffeeIcon();
        using var tray = new NotifyIcon
        {
            Icon = icon,
            Text = "Caffeinate active" + (seconds > 0 ? $" ({seconds}s)" : ""),
            Visible = true,
            ContextMenuStrip = new ContextMenuStrip()
        };

        var stopItem = new ToolStripMenuItem($"Stop Caffeinate ({DateTime.Now:HH:mm})");
        stopItem.Click += (_, _) => Application.Exit();
        tray.ContextMenuStrip.Items.Add(stopItem);

        // --- 2. worker thread re‑asserts every 50 s -------------------------
        using var tokenSource = new CancellationTokenSource();
        var worker = new Thread(() =>
        {
            DateTime? until = seconds > 0 ? DateTime.UtcNow.AddSeconds(seconds) : null;
            
            while (!tokenSource.IsCancellationRequested &&
                   (until == null || DateTime.UtcNow < until))
            {
                SetThreadExecutionState(flags);
                Thread.Sleep(TimeSpan.FromSeconds(50));
            }
            
            // Timer elapsed, exit gracefully
            Application.Exit();
        })
        { IsBackground = true };
        
        worker.Start();

        // --- 3. run message loop -------------------------------------------
        Application.Run();

        // --- 4. clean‑up ----------------------------------------------------
        tokenSource.Cancel();
        SetThreadExecutionState(ES_CONTINUOUS); // clear assertions
        tray.Visible = false;
        icon?.Dispose();
    }

    private static Icon CreateCoffeeIcon()
    {
        // Create a simple coffee cup icon programmatically
        var bitmap = new Bitmap(16, 16);
        using (var g = Graphics.FromImage(bitmap))
        {
            g.Clear(Color.Transparent);
            
            // Coffee cup shape (brown)
            var cupBrush = new SolidBrush(Color.FromArgb(139, 69, 19));
            g.FillRectangle(cupBrush, 2, 6, 10, 8);
            g.FillRectangle(cupBrush, 3, 5, 8, 1);
            g.FillRectangle(cupBrush, 4, 4, 6, 1);
            
            // Handle
            g.FillRectangle(cupBrush, 12, 8, 1, 4);
            g.FillRectangle(cupBrush, 13, 9, 1, 2);
            
            // Coffee (dark brown)
            var coffeeBrush = new SolidBrush(Color.FromArgb(101, 67, 33));
            g.FillRectangle(coffeeBrush, 3, 6, 8, 6);
            
            // Steam (light gray)
            var steamBrush = new SolidBrush(Color.FromArgb(200, 200, 200));
            g.FillRectangle(steamBrush, 5, 2, 1, 2);
            g.FillRectangle(steamBrush, 7, 1, 1, 3);
            g.FillRectangle(steamBrush, 9, 2, 1, 2);
        }
        
        return Icon.FromHandle(bitmap.GetHicon());
    }

    private static void Usage()
    {
        Console.WriteLine(
@"caffeinate.exe [-d] [-i|-s] [-t seconds]

  -d       Prevent display sleep
  -i       Prevent system sleep/idle            (alias: -s)
  -t n     Hold awake state for n seconds
  -h       Show this help message

At least one of -d or -i/-s must be specified.

If no -t is given, the program runs until you exit via the tray icon.
Right-click the coffee cup icon in the system tray to stop.");
        Environment.Exit(1);
    }
}
