# caffeinate.ps1

<div align="center">
  <img src="img/logo.png" alt="Caffeinate Windows Logo" width="200" height="200">
</div>

*A drop‑in, macOS‑style **caffeinate** command for Windows written in pure PowerShell.*

`caffeinate.ps1` prevents your PC from sleeping, turning off the display, or idling out—exactly like the macOS `caffeinate` utility.  
It relies solely on the Win32 API (`SetThreadExecutionState`) and therefore **requires no installation, admin rights, or external modules.**

## ✨ Features

This PowerShell script provides:
- **Enhanced error handling** and validation
- **Detailed documentation** with parameter help  
- **Modular functions** for better code organization
- **Verbose logging** support for troubleshooting
- **Robust process management** with proper cleanup
- **PowerShell best practices** throughout

Use `Get-Help .\caffeinate.ps1 -Full` to see detailed documentation.

---

## Project Structure

```
caffeinate-windows/
├── caffeinate.ps1      # Main PowerShell script
├── install.bat         # Easy installer (adds to PATH)
├── uninstall.bat       # Uninstaller
├── img/               # Logo and assets
│   └── logo.png       # README logo
└── README.md          # This documentation
```

---

## Capabilities

| Feature | macOS flag | Windows equivalent | Supported? |
|---------|-----------|-------------------|------------|
| Keep display awake | `-d` | `ES_DISPLAY_REQUIRED` | ✔ |
| Prevent system sleep / idle | `-i`, `-s` | `ES_SYSTEM_REQUIRED` | ✔ |
| Announce "user active" pulse | `-u` | `ES_USER_PRESENT` | ✔ |
| Run for *n* seconds | `-t n` | re‑assert every 50 s until *n* expires | ✔ |
| Wrap another command | `caffeinate [flags] -- cmd …` | holds assertion while `cmd` runs | ✔ |
| Indefinite hold | no `-t` and no wrapped command | Ctrl‑C to cancel | ✔ |

> Windows clears a power request after ~60 seconds, so this script refreshes every **50 seconds** while active.

---

## Quick Start

### Easy Installation
1. **Download** this repository or clone it
2. **Run** `install.bat` (right-click → "Run as administrator" for system-wide installation)
3. **Open a new command prompt** and start using `caffeinate`:

   ```cmd
   # Keep the display awake indefinitely
   caffeinate -d

   # Prevent the entire PC from sleeping for 30 minutes
   caffeinate -i -t 1800

   # Stay awake only while a long build runs
   caffeinate -i -- msbuild MySolution.sln

   # Show detailed logging
   caffeinate -d -t 300 -Verbose
   ```

### Manual Setup (Alternative)
1. **Download** `caffeinate.ps1` or clone this repository
2. **Set execution policy** (one‑time setup):
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```
3. **Place the script** in a folder on your `PATH` or run directly:
   ```powershell
   .\caffeinate.ps1 -d -t 3600
   ```

---

## Usage

```
SYNTAX
    caffeinate.ps1 [-d] [-i] [-s] [-u] [-t <seconds>] [-Verbose] [-- <command>]

PARAMETERS
  -d        Prevent the display from sleeping.
  -i        Prevent the system from idle sleeping.
  -s        Prevent the system from sleeping (same as -i).
  -u        Signal "user present" once (wakes display if already asleep).
  -t n      Hold the assertion for n seconds, then exit.
  -Verbose  Show detailed logging and status information.
  --        Everything after -- is treated as a command to run under the assertion.

If neither -t nor a wrapped command is supplied, caffeinate.ps1 holds the
assertion indefinitely until you press Ctrl‑C.
```

### Getting Help

```cmd
# After installation, show basic help
caffeinate -h

# For PowerShell detailed help (if running manually)
Get-Help .\caffeinate.ps1 -Full
```

---

## Examples

```cmd
# Keep display awake for 1 hour
caffeinate -d -t 3600

# Prevent system sleep during a long download
caffeinate -i -t 7200

# Keep awake while running a command
caffeinate -d -i -- docker build -t myapp .

# Wake display and keep it awake indefinitely
caffeinate -u -d

# Run with detailed logging
caffeinate -d -t 1800 -Verbose
```

### Manual Usage Examples (if not installed)

If you haven't run the installer, use these commands:

```powershell
# Keep display awake for 1 hour
.\caffeinate.ps1 -d -t 3600

# Prevent system sleep during a long download
.\caffeinate.ps1 -i -t 7200

# Keep awake while running a command
.\caffeinate.ps1 -d -i -- docker build -t myapp .

# Wake display and keep it awake indefinitely
.\caffeinate.ps1 -u -d

# Run with detailed logging
.\caffeinate.ps1 -d -t 1800 -Verbose
```

---

## Verifying It Works

Run `powercfg /requests` in another terminal.  
While `caffeinate` is active you should see an **EXECUTION** request attributed to `powershell.exe` (or `pwsh.exe`) with the flags you specified.

For detailed monitoring, run with the `-Verbose` flag:

```cmd
# Run with verbose output to see what's happening
caffeinate -d -t 300 -Verbose
```

---

## Troubleshooting

* **'caffeinate' is not recognized** – Make sure you ran `install.bat` and opened a new command prompt.
* **Script won't run** – Make sure you changed your execution policy (`RemoteSigned` is sufficient).
* **Display still turns off** – Include **`-d`**. The default without flags does *not* assert display wakefulness.
* **Laptop sleeps on lid close** – Hardware lid switches override software requests. This is expected.
* **Need help with parameters** – Run `caffeinate -h` for quick help or `Get-Help .\caffeinate.ps1 -Full` for detailed documentation.
* **Want to see what's happening** – Use the `-Verbose` flag for detailed logging.
* **Command fails to execute** – The script now provides better error messages and exit codes.

### Common Error Messages

- **"No power management flags specified"** – You must specify at least one flag (`-d`, `-i`, `-s`, or `-u`).
- **"Failed to set power state"** – Check if another application is interfering with power management.
- **"Command parameter specified but empty"** – Make sure you provide a valid command after the flags.

---

## PowerShell Compatibility

- **Windows PowerShell 5.1** ✔
- **PowerShell 7+** ✔
- **PowerShell Core 6.x** ✔

The script uses only built-in PowerShell features and Win32 APIs available on all Windows versions.

---

## Installation

### 🚀 Easy Installation (Recommended)

1. **Download or clone** this repository
2. **Run the installer** as administrator (for system-wide) or as user:
   ```cmd
   install.bat
   ```
3. **Open a new command prompt** and use `caffeinate` from anywhere:
   ```cmd
   caffeinate -d -t 3600    # Keep display awake for 1 hour
   caffeinate -h            # Show help
   ```

The installer will:
- ✅ Copy the script to the appropriate location
- ✅ Add it to your system PATH automatically  
- ✅ Set up PowerShell execution policy
- ✅ Create a wrapper so you can use `caffeinate` instead of `.\caffeinate.ps1`

### Manual Installation Options

#### Option 1: Download Single File
Download `caffeinate.ps1` and place it in a folder on your PATH.

#### Option 2: Clone Repository
```bash
git clone https://github.com/mrviduus/caffeinate-windows.git
cd caffeinate-windows
```

#### Option 3: PowerShell Gallery (Coming Soon)
```powershell
Install-Script -Name caffeinate
```

### Uninstallation

To remove caffeinate from your system:
```cmd
uninstall.bat
```

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

This project is released under the **MIT License**.

## Acknowledgements

* Inspired by Apple's `caffeinate` command.
* Uses Win32 `SetThreadExecutionState`, documented by Microsoft.  
* Thanks to everyone who improves this script via issues and PRs!
