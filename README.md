

<div align="center">
  <img src="img/logo.png" alt="Caffeinate Windows Logo" width="200" height="200">
</div>
# Caffeine (Console Edition)

Tiny Windows utility that keeps your computer **and** display awake
by:

1. Calling `SetThreadExecutionState` every **59 s**
2. Sending a harmless **F15** key-press

On launch it prints a cup ASCII logo, then runs until you hit **Ctrl +C**.

## Build

| Tool-chain | Command |
|------------|---------|
| MSVC (Visual Studio 2022 Build Tools) | `cl /O2 /W4 /nologo caffeine.c caffeine.rc user32.lib` |
| MinGW-w64 (MSYS2) | `windres caffeine.rc -O coff -o caffeine.res`<br>`gcc -O2 -s -municode caffeine.c caffeine.res -luser32 -o caffeine.exe` |

`logo.ico` becomes the program icon; `logo.png` is also embedded
(resource ID `IDR_PNG1`) for reuse in a GUI variant.

## Usage
caffeine.exe        # runs in foreground, prints status

Put a shortcut to `caffeine.exe` in **shell:startup** (Windows start-up folder) if you want it to auto-launch.  
Add `cmd /c start /min "" caffeine.exe` to hide the console window after launch.

## License

Public-domain / CC0 for the code.  
`logo.png` remains © _you_, used here with permission.