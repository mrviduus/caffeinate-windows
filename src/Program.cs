using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace Caffeinate
{
    /// <summary>
    /// Windows caffeinate command - prevent sleep/display sleep like macOS
    /// </summary>
    class Program
    {
        #region Win32 API

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern uint SetThreadExecutionState(uint esFlags);

        // Execution state flags
        private const uint ES_CONTINUOUS = 0x80000000;
        private const uint ES_SYSTEM_REQUIRED = 0x00000001;
        private const uint ES_DISPLAY_REQUIRED = 0x00000002;
        private const uint ES_AWAYMODE_REQUIRED = 0x00000040;
        private const uint ES_USER_PRESENT = 0x00000004;

        #endregion

        #region Configuration

        private static readonly TimeSpan SleepInterval = TimeSpan.FromSeconds(50);
        private static readonly TimeSpan ProcessCheckInterval = TimeSpan.FromSeconds(10);

        #endregion

        #region Command Line Arguments

        private class Arguments
        {
            public bool Display { get; set; }
            public bool System { get; set; }
            public bool UserPresent { get; set; }
            public int Timeout { get; set; }
            public bool Verbose { get; set; }
            public string[] Command { get; set; } = Array.Empty<string>();
            public bool ShowHelp { get; set; }
        }

        #endregion

        static int Main(string[] args)
        {
            try
            {
                var arguments = ParseArguments(args);

                if (arguments.ShowHelp)
                {
                    ShowHelp();
                    return 0;
                }

                if (!ValidateArguments(arguments))
                {
                    return 1;
                }

                return RunCaffeinate(arguments);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Error: {ex.Message}");
                return 1;
            }
        }

        private static Arguments ParseArguments(string[] args)
        {
            var arguments = new Arguments();
            var commandArgs = new List<string>();
            bool foundDoubleDash = false;

            for (int i = 0; i < args.Length; i++)
            {
                var arg = args[i];

                if (foundDoubleDash)
                {
                    commandArgs.Add(arg);
                    continue;
                }

                switch (arg.ToLowerInvariant())
                {
                    case "-d":
                        arguments.Display = true;
                        break;
                    case "-i":
                    case "-s":
                        arguments.System = true;
                        break;
                    case "-u":
                        arguments.UserPresent = true;
                        break;
                    case "-v":
                    case "-verbose":
                        arguments.Verbose = true;
                        break;
                    case "-h":
                    case "-help":
                    case "--help":
                    case "/?":
                        arguments.ShowHelp = true;
                        return arguments;
                    case "-t":
                        if (i + 1 < args.Length && int.TryParse(args[i + 1], out int timeout))
                        {
                            arguments.Timeout = timeout;
                            i++; // Skip the next argument
                        }
                        else
                        {
                            throw new ArgumentException("Invalid timeout value. Must be a positive integer.");
                        }
                        break;
                    case "--":
                        foundDoubleDash = true;
                        break;
                    default:
                        if (arg.StartsWith('-'))
                        {
                            throw new ArgumentException($"Unknown option: {arg}");
                        }
                        else
                        {
                            // Treat as beginning of command
                            commandArgs.Add(arg);
                            foundDoubleDash = true;
                        }
                        break;
                }
            }

            arguments.Command = commandArgs.ToArray();
            return arguments;
        }

        private static bool ValidateArguments(Arguments arguments)
        {
            if (!arguments.Display && !arguments.System && !arguments.UserPresent)
            {
                Console.Error.WriteLine("Error: No power management flags specified.");
                Console.Error.WriteLine("Use -d (display), -i/-s (system), or -u (user-present).");
                Console.Error.WriteLine("Use -h for help.");
                return false;
            }

            if (arguments.Timeout < 0)
            {
                Console.Error.WriteLine("Error: Timeout must be a positive number.");
                return false;
            }

            return true;
        }

        private static int RunCaffeinate(Arguments arguments)
        {
            var powerFlags = GetPowerFlags(arguments);

            if (arguments.Verbose)
            {
                Console.WriteLine($"Power flags: 0x{powerFlags:X8}");
                if (arguments.Display) Console.WriteLine("- Display sleep prevention enabled");
                if (arguments.System) Console.WriteLine("- System sleep prevention enabled");
                if (arguments.UserPresent) Console.WriteLine("- User-present mode enabled");
            }

            // Set initial power state
            if (!SetPowerState(powerFlags, arguments.Verbose))
            {
                Console.Error.WriteLine("Failed to set initial power state");
                return 1;
            }

            // Send user-present pulse if requested
            if (arguments.UserPresent)
            {
                SendUserPresentPulse(arguments.Verbose);
            }

            try
            {
                if (arguments.Command.Length > 0)
                {
                    return ExecuteCommandWithAssertion(arguments.Command, powerFlags, arguments.Verbose);
                }
                else if (arguments.Timeout > 0)
                {
                    Console.WriteLine($"Caffeinate active for {arguments.Timeout} seconds – press Ctrl+C to exit early");
                    MaintainAssertionWithTimeout(powerFlags, arguments.Timeout, arguments.Verbose);
                }
                else
                {
                    Console.WriteLine("Caffeinate active indefinitely – press Ctrl+C to exit");
                    MaintainAssertionIndefinitely(powerFlags, arguments.Verbose);
                }

                return 0;
            }
            finally
            {
                // Clear power assertion on exit
                if (arguments.Verbose)
                {
                    Console.WriteLine("Clearing power assertions");
                }
                SetThreadExecutionState(ES_CONTINUOUS);
            }
        }

        private static uint GetPowerFlags(Arguments arguments)
        {
            uint flags = ES_CONTINUOUS;

            if (arguments.Display)
            {
                flags |= ES_DISPLAY_REQUIRED;
            }

            if (arguments.System)
            {
                flags |= ES_SYSTEM_REQUIRED;
            }

            // User-present requires display flag to keep screen on
            if (arguments.UserPresent)
            {
                flags |= ES_DISPLAY_REQUIRED;
            }

            return flags;
        }

        private static bool SetPowerState(uint flags, bool verbose)
        {
            var result = SetThreadExecutionState(flags);
            if (result == 0)
            {
                var error = Marshal.GetLastWin32Error();
                Console.Error.WriteLine($"Failed to set power state. Error: {error}");
                return false;
            }

            if (verbose)
            {
                Console.WriteLine($"Power state set successfully with flags: 0x{flags:X8}");
            }

            return true;
        }

        private static void SendUserPresentPulse(bool verbose)
        {
            var userPresentFlags = ES_CONTINUOUS | ES_USER_PRESENT;
            if (SetPowerState(userPresentFlags, false) && verbose)
            {
                Console.WriteLine("User-present pulse sent successfully");
            }
        }

        private static void MaintainAssertionWithTimeout(uint powerFlags, int timeoutSeconds, bool verbose)
        {
            var startTime = DateTime.UtcNow;
            var timeout = TimeSpan.FromSeconds(timeoutSeconds);

            if (verbose)
            {
                Console.WriteLine($"Starting power assertion for {timeoutSeconds} seconds");
            }

            while (true)
            {
                Thread.Sleep(SleepInterval);

                if (!SetPowerState(powerFlags, false))
                {
                    Console.Error.WriteLine("Warning: Failed to maintain power state");
                }

                var elapsed = DateTime.UtcNow - startTime;
                if (elapsed >= timeout)
                {
                    if (verbose)
                    {
                        Console.WriteLine($"Timeout reached after {elapsed.TotalSeconds:F1} seconds");
                    }
                    break;
                }
            }
        }

        private static void MaintainAssertionIndefinitely(uint powerFlags, bool verbose)
        {
            if (verbose)
            {
                Console.WriteLine("Starting power assertion indefinitely");
            }

            while (true)
            {
                Thread.Sleep(SleepInterval);

                if (!SetPowerState(powerFlags, false))
                {
                    Console.Error.WriteLine("Warning: Failed to maintain power state");
                }
            }
        }

        private static int ExecuteCommandWithAssertion(string[] command, uint powerFlags, bool verbose)
        {
            var executable = command[0];
            var arguments = command.Length > 1 ? string.Join(" ", command[1..]) : "";

            Console.WriteLine($"Starting command: {executable} {arguments}");
            if (verbose)
            {
                Console.WriteLine("Maintaining power assertion while command executes...");
            }

            try
            {
                var processInfo = new ProcessStartInfo
                {
                    FileName = executable,
                    Arguments = arguments,
                    UseShellExecute = false,
                    CreateNoWindow = false
                };

                using var process = Process.Start(processInfo);
                if (process == null)
                {
                    Console.Error.WriteLine("Failed to start process");
                    return 1;
                }

                while (!process.HasExited)
                {
                    Thread.Sleep(ProcessCheckInterval);

                    if (!SetPowerState(powerFlags, false))
                    {
                        Console.Error.WriteLine("Warning: Failed to maintain power state during command execution");
                    }
                }

                Console.WriteLine($"Command completed with exit code: {process.ExitCode}");
                return process.ExitCode;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"Failed to execute command: {ex.Message}");
                return 1;
            }
        }

        private static void ShowHelp()
        {
            Console.WriteLine("caffeinate - Windows caffeinate command");
            Console.WriteLine();
            Console.WriteLine("SYNOPSIS");
            Console.WriteLine("    caffeinate [-d] [-i] [-s] [-u] [-t seconds] [-v] [--] [command [args...]]");
            Console.WriteLine();
            Console.WriteLine("DESCRIPTION");
            Console.WriteLine("    Prevents Windows from sleeping, turning off the display, or going idle");
            Console.WriteLine("    using the SetThreadExecutionState Win32 API.");
            Console.WriteLine();
            Console.WriteLine("OPTIONS");
            Console.WriteLine("    -d        Prevent display sleep");
            Console.WriteLine("    -i        Prevent system sleep due to idle (works on AC or battery)");
            Console.WriteLine("    -s        Prevent system sleep while on AC power (alias for -i)");
            Console.WriteLine("    -u        Signal \"user present\" once (wakes display if already asleep)");
            Console.WriteLine("    -t n      Hold the assertion for n seconds, then exit");
            Console.WriteLine("    -v        Show verbose output");
            Console.WriteLine("    -h        Show this help message");
            Console.WriteLine("    --        Everything after -- is treated as a command to run");
            Console.WriteLine();
            Console.WriteLine("EXAMPLES");
            Console.WriteLine("    caffeinate -d");
            Console.WriteLine("        Keep the display awake indefinitely");
            Console.WriteLine();
            Console.WriteLine("    caffeinate -i -t 1800");
            Console.WriteLine("        Prevent system sleep for 30 minutes");
            Console.WriteLine();
            Console.WriteLine("    caffeinate -s -- msbuild MySolution.sln /m");
            Console.WriteLine("        Stay awake while a long build runs");
            Console.WriteLine();
            Console.WriteLine("If neither -t nor a wrapped command is supplied, caffeinate holds the");
            Console.WriteLine("assertion indefinitely until you press Ctrl+C.");
        }
    }
}
