
# caffeinate.ps1

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
caffeinate.ps1 [-d] [-i] [-s] [-u] [-t seconds] [--] [command [args…]]

  -d   Prevent display sleep.
  -i   Prevent system sleep due to idle (works on AC or battery).
  -s   Prevent system sleep while on AC power (alias for -i; no distinction on Windows).
  -u   Signal "user present" once (wakes display if already asleep).
  -t n Hold the assertion for n seconds, then exit.
  --   Everything after -- is treated as a command to run under the assertion.

If neither -t nor a wrapped command is supplied, caffeinate.ps1 holds the
assertion indefinitely until you press Ctrl‑C.
```

---

## Verifying it works

Run `powercfg /requests` in another terminal.  
While `caffeinate.ps1` is active you should see an **EXECUTION** request attributed to `powershell.exe` (or `pwsh.exe`) with the flags you specified.

---

## Building a single‑file `.exe` (optional)

Prefer a self‑contained executable?  A minimal C# translation is included in [/src/CaffeinateWin](src/CaffeinateWin). Compile with the .NET SDK:

```sh
dotnet publish -c Release -r win-x64 -p:PublishSingleFile=true -p:SelfContained=true
# Result: bin/Release/net8.0/win-x64/publish/caffeinate.exe
```

Copy the resulting `caffeinate.exe` anywhere on your `PATH`.  
Command‑line usage is identical.

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
3. Run lint (`pwsh tools/Invoke-ScriptAnalyzer.ps1`) and verify examples.
4. Open a pull request describing your change.

---

## License

This project is released under the **MIT License**—see [LICENSE](LICENSE) for details.

---

## Acknowledgements

* Inspired by Apple’s `caffeinate` command.
* Uses Win32 `SetThreadExecutionState`, documented by Microsoft.  
* Thanks to everyone who improves this script via issues and PRs!
