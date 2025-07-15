# Caffeinate C# Build

This directory contains the C# source code for building a self-contained executable version of caffeinate.

## Building

Make sure you have the .NET 8 SDK installed, then run:

```bash
# Build for Windows x64
dotnet publish -c Release -r win-x64 --self-contained

# Build optimized single-file executable
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true -p:PublishTrimmed=true
```

The resulting executable will be in `bin/Release/net8.0/win-x64/publish/caffeinate.exe`.

## Usage

The executable has the same command-line interface as the PowerShell script:

```bash
caffeinate.exe -d -t 3600          # Keep display awake for 1 hour
caffeinate.exe -i -- long-task.exe # Keep system awake during task
caffeinate.exe -h                  # Show help
```

## Features

- Single-file executable (no dependencies)
- Same functionality as PowerShell version
- Better startup performance
- Works without PowerShell installed
- Verbose logging support
- Proper exit codes
