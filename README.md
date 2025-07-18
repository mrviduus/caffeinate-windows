<div align="center">
  <img s3. Double‑click the EXE → keep the console window open while you work.
4. Hit **Ctrl + C** to exit; normal power‑saving resumes.

**Auto-start at login:**
1. **Easy way**: Edit `startup.bat`, set your caffeine.exe path, then copy it to *shell:startup*
2. **Manual way**: Place the EXE (or shortcut) in *shell:startup* with command:  
   `cmd /c start /min "" "C:\path\to\caffeine.exe"`esources/img/logo.ico" alt="Caffeine Windows Logo" width="180" height="180">
  <h1>Caffeine (Tray Edition)</h1>
  <sub>Keep your Windows PC (and display) awake with a single-file utility<br>— cross-compiled from macOS or Linux with MinGW-w64 —</sub>
</div>

[![Download for Windows](https://img.shields.io/badge/Download-Windows%20EXE-blue?logo=windows)](https://github.com/mrviduus/caffeinate-windows/blob/main/build/win/caffeine.exe)

---

## ✨ Features
* **No dependencies** – pure Win32; runs on Windows 7 → 11 (x64).
* Refreshes idle timers every **59 s** via `SetThreadExecutionState`.
* Sends a harmless **F15** keypress as fallback (mirrors original Zhorn Caffeine).

---

## 📦 Download

Get the latest **pre-built executable** from the [Releases](https://github.com/mrviduus/caffeine-windows/build/caffeine.exe) page.

| Platform | File | Notes |
|----------|------|------|-------|
| Windows x64 | `caffeine.exe` | Requires MSVC runtimes (present on Windows 10/11) |
| Windows x64 | `caffeine-static.exe` | Fully self‑contained; runs even in WinPE |

**Quick start**
1. Download the file that suits you.
2. (Optional) verify the SHA‑256 checksum listed on the release page.
3. Double‑click the EXE → keep the console window open while you work.
4. Hit **Ctrl + C** to exit; normal power‑saving resumes.

Want automatic launch at login? Place the EXE (or a shortcut) in *shell:startup* and, if desired, use  
`cmd /c start /min "" "C:\path\to\caffeine.exe"` to hide the console.

---

## 📁 Folder layout

```
caffeine-windows/
├─ src/                        # C source
│   └─ caffeine.c
├─ resources/                  # Win32 resources
│   ├─ caffeine.rc
│   └─ img/
│       └─ logo.ico
├─ build/                      # ← auto-generated; ignored by Git
│   ├─ mac/
│   └─ win/
├─ .gitignore
├─ Makefile                    # cross-platform build script
├─ startup.bat                 # Windows startup helper
├─ LICENSE
└─ README.md
```

---

## 🛠️ Build

### macOS (Homebrew)

```bash
brew install mingw-w64            # one-time
export PATH="$(brew --prefix)/opt/mingw-w64/bin:$PATH"

make                               # → build/mac/caffeine.exe
```

Add `STATIC=1` for a fully self‑contained EXE:

```bash
make STATIC=1                      # → ≈700 KB binary
```

> **Local test (optional)**  
> `brew install --cask wine-stable && wine64 build/mac/caffeine.exe`

### Windows (MSVC / Visual Studio 2022)

```cmd
:: x64 Native Tools Command Prompt
git clone https://github.com/mrviduus/caffeine-windows.git
cd caffeine-windows
nmake /f Makefile.msvc
```

The resulting executable appears in **`build\win\caffeine.exe`**.

---

## 🚀 Usage

```cmd
caffeine.exe              # runs in foreground, prints status
```

Place a shortcut in **shell:startup** to launch on login:

```
cmd /c start /min "" "C:\path\to\caffeine.exe"
```

Exit with **Ctrl + C**; normal power-saving resumes.

---

## 📝 Licence

*Code* – [CC0 1.0](LICENSE) (public domain).

---

## 🤝 Contributing

Issues and PRs are welcome!  
For anything larger than a typo‑fix, please open an issue first so we can discuss scope and direction.

---

<div align="center"><sub>Made with ☕  by &lt;Your Name&gt;</sub></div>
