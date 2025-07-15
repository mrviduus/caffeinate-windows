
# caffeinate.ps1

*A drop‑in, macOS‑style **caffeinate** command for Windows written in pure PowerShell.*

`caffeinate.ps1` prevents## Troubleshooting

* **Script won't run*## License

This project is released under the **MIT License**.

## Acknowledgements

* Inspired by Apple's `caffeinate` command.
* Uses Win32 `SetThreadExecutionState`, documented by Microsoft.  
* Thanks to everyone who improves this script via issues and PRs!re you changed your execution policy (`RemoteSigned` is sufficient).
* **Display still turns off** – Include **`-d`**. The default without flags does *not* assert display wakefulness.
* **Laptop sleeps on lid close** – Hardware lid switches override software requests. This is expected.
* **Need help with parameters** – Run `Get-Help .\caffeinate.ps1 -Full` for detailed documentation.
* **Want to see what's happening** – Use the `-Verbose` flag for detailed logging.
* **Command fails to execute** – The script now provides better error messages and exit codes.

### Common Error Messages

- **"No power management flags specified"** – You must specify at least one flag (`-d`, `-i`, `-s`, or `-u`).
- **"Failed to set power state"** – Check if another application is interfering with power management.
- **"Command parameter specified but empty"** – Make sure you provide a valid command after the flags.PC from sleeping, turning off the display, or idling out—exactly like the macOS `caffeinate` utility.  
It relies solely on the Win32 API (`SetThreadExecutionState`) and therefore **requires no installation, admin rights, or external modules.**

## ✨ Recent Improvements

This script has been enhanced with:
- **Better error handling** and validation
- **Enhanced documentation** with detailed parameter help
- **Improved code organization** with modular functions
- **Verbose logging** support for troubleshooting
- **More robust process management** with proper cleanup
- **PowerShell best practices** throughout

Use `Get-Help .\caffeinate.ps1 -Full` to see detailed documentation.einate.ps1

*A drop‑in, macOS‑style **caffeinate** command for Windows written in pure PowerShell.*

`caffeinate.ps1` prevents your PC from sleeping, turning off the display, or idling out—exactly like the macOS `caffeinate` utility.  
It relies solely on the Win32 API (`SetThreadExecutionState`) and therefore **requires no installation, admin rights, or external modules.**

---

## Features

| Capability | macOS flag | Windows equivalent | Supported? |
|------------|-----------|--------------------|------------|
| Keep display awake | `-d` | `ES_DISPLAY_REQUIRED` | ✔ |
| Prevent system sleep / idle | `-i`, `-s` | `ES_SYSTEM_REQUIRED` | ✔ |
| Announce “user active” pulse | `-u` | `ES_USER_PRESENT` | ✔ |
| Run for *n* seconds | `-t n` | re‑assert every 50 s until *n* expires | ✔ |
| Wrap another command | `caffeinate [flags] -- cmd …` | holds assertion while `cmd` runs | ✔ |
| Indefinite hold | no `-t` and no wrapped command | Ctrl‑C to cancel | ✔ |

> Windows clears a power request after ~60 seconds, so this script refreshes every **50 seconds** while active.

---

## Quick start

1. **Download** `caffeinate.ps1` or clone this repository.
2. Ensure scripts can run for your user (one‑time):

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

3. Place the script in a folder on your **`PATH`** (e.g. `C:\Tools`).
4. Use it exactly as you would on macOS:

   ```powershell
   # Keep the display awake indefinitely
   caffeinate -d

   # Prevent the entire PC from sleeping for 30 minutes
   caffeinate -i -t 1800

   # Stay awake only while a long build runs
   caffeinate -s -- msbuild MySolution.sln /m
   ```

Calling from **`cmd.exe`**?  Prefix with `pwsh` or `powershell`:

```cmd
pwsh caffeinate.ps1 -d
```

---

## Command‑line reference

```text
caffeinate.ps1 [-d] [-i] [-s] [-u] [-t seconds] [-Verbose] [--] [command [args…]]

  -d        Prevent display sleep.
  -i        Prevent system sleep due to idle (works on AC or battery).
  -s        Prevent system sleep while on AC power (alias for -i; no distinction on Windows).
  -u        Signal "user present" once (wakes display if already asleep).
  -t n      Hold the assertion for n seconds, then exit.
  -Verbose  Show detailed logging and status information.
  --        Everything after -- is treated as a command to run under the assertion.

If neither -t nor a wrapped command is supplied, caffeinate.ps1 holds the
assertion indefinitely until you press Ctrl‑C.
```

### Getting Help

```powershell
# Show basic help
Get-Help .\caffeinate.ps1

# Show detailed documentation with examples
Get-Help .\caffeinate.ps1 -Full

# Show parameter information
Get-Help .\caffeinate.ps1 -Parameter d
```

---

## Verifying it works

Run `powercfg /requests` in another terminal.  
While `caffeinate.ps1` is active you should see an **EXECUTION** request attributed to `powershell.exe` (or `pwsh.exe`) with the flags you specified.

For detailed monitoring, run the script with the `-Verbose` flag:

```powershell
# Run with verbose output to see what's happening
.\caffeinate.ps1 -d -t 300 -Verbose
```

---

## Alternative: Pre-built executable

For users who prefer a standalone executable, a pre-built `caffeinate.exe` is included in this repository. This single-file executable:

- **No dependencies** - Works without PowerShell or .NET runtime
- **Same functionality** - Identical command-line interface to the PowerShell script  
- **Better performance** - Faster startup time
- **Smaller footprint** - Self-contained with optimized size

### Quick Start with Executable

1. Download `caffeinate.exe` from this repository
2. Place it in a folder on your `PATH` (e.g., `C:\Tools`)
3. Use it exactly like the PowerShell version:

```cmd
caffeinate.exe -d -t 3600          # Keep display awake for 1 hour
caffeinate.exe -i -- build.bat     # Keep system awake during build
caffeinate.exe -h                  # Show help
```

### Building from Source

If you want to build the executable yourself:

```bash
cd src
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true -p:PublishTrimmed=true
```

The resulting executable will be in `src/bin/Release/net8.0/win-x64/publish/caffeinate.exe`.

See [src/README.md](src/README.md) for detailed build instructions.

---

## Troubleshooting

* **Script won’t run** – Make sure you changed your execution policy (`RemoteSigned` is sufficient).
* **Display still turns off** – Include **`-d`**. The default without flags does *not* assert display wakefulness.
* **Laptop sleeps on lid close** – Hardware lid switches override software requests. This is expected.
* **Want media‑server behaviour (stay awake but dark)** – Add `ES_AWAYMODE_REQUIRED` in the script or use the `-away` flag in the C# build.

---

## Contributing

Bug reports, feature requests, and pull requests are welcome!  
Please open an issue to discuss significant changes.

1. Fork the repo and create a branch (`git checkout -b feature/foo`).
2. Make your changes with clear, descriptive commits.
3. Test the script with various parameter combinations and verify examples work.
4. Open a pull request describing your change.

### Code Quality

The script follows PowerShell best practices:
- Uses proper error handling with try-catch blocks
- Implements parameter validation and help documentation
- Follows consistent naming conventions
- Includes verbose logging for debugging

---

## License

This project is released under the **MIT License**—see [LICENSE](LICENSE) for details.

---

## Acknowledgements

* Inspired by Apple’s `caffeinate` command.
* Uses Win32 `SetThreadExecutionState`, documented by Microsoft.  
* Thanks to everyone who improves this script via issues and PRs!
