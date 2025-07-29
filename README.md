<div align="center">
<img src="resources/img/logo.ico" alt="Caffeine Windows Logo" width="120" height="120">
  <h1>Caffeine for Windows</h1>
  <sub>Keep your Windows system awake with a lightweight system tray utility<br>— cross-compiled from macOS/Linux using MinGW-w64 —</sub>
</div>

---

## ✨ Features

* **🖥️ System Tray App** – Runs silently in the background with tray icon
* **⚡ Lightweight** – Single 27KB executable, no dependencies
* **🔄 Auto-refresh** – Prevents sleep every 59 seconds using Windows API
* **🎯 Fallback Method** – F15 keypress as backup (non-intrusive)
* **🖱️ Simple Controls** – Right-click tray icon to exit
* **💻 Wide Compatibility** – Works on Windows 7 through Windows 11 (x64)

---

## 📦 Quick Start

### Download & Run

#### 📥 Direct Download
**[Download caffeine.exe](https://github.com/mrviduus/caffeinate-windows/raw/main/build/win/caffeine.exe)** (27KB)

*Alternative download link: [View in GitHub](https://github.com/mrviduus/caffeinate-windows/tree/main/build/win)*

#### 🚀 Installation
1. Download `caffeine.exe` using the link above
2. Double-click to run - a coffee cup icon appears in your system tray
3. Your system will stay awake while the app is running
4. Right-click the tray icon and select "Exit" to quit

### Auto-start at Login
To start Caffeine automatically when Windows boots:
1. Press `Win + R`, type `shell:startup`, press Enter
2. Copy `caffeine.exe` or create a shortcut to it in this folder
3. Use the included `startup.bat` for advanced startup options

---

## 🛠️ Building from Source

### Prerequisites
**macOS/Linux:**
```bash
# macOS (Homebrew)
brew install mingw-w64

# Ubuntu/Debian
sudo apt-get install mingw-w64
```

### Build Commands
```bash
# Basic build
make                    # → build/win/caffeine.exe (~27KB)

# Static build (self-contained)
make STATIC=1          # → build/win/caffeine-static.exe (~800KB)

# Clean build artifacts
make clean

# Check build environment
make check
```

### Build Output
- **`build/win/caffeine.exe`** - Main executable
- **`build/win/caffeine.res`** - Compiled Windows resources

---

## 📁 Project Structure

```
caffeine-windows/
├── src/
│   └── caffeine.c              # Main source code (fully commented)
├── resources/
│   ├── caffeine.rc             # Windows resource script
│   ├── resource.h              # Resource definitions
│   └── img/
│       └── logo.ico            # Application icon
├── build/
│   └── win/                    # Build output directory
│       ├── caffeine.exe        # Compiled executable
│       └── caffeine.res        # Compiled resources
├── Makefile                    # Cross-platform build script
├── startup.bat                 # Windows startup helper script
├── LICENSE                     # CC0-1.0 Public Domain
└── README.md                   # This file
```

---

## 🔧 How It Works

Caffeine uses two methods to keep your system awake:

1. **Primary Method**: `SetThreadExecutionState()` Windows API
   - Tells Windows to disable sleep and display timeout
   - Silent and efficient, no visible side effects

2. **Fallback Method**: Synthetic F15 keypress
   - Sends a harmless F15 key event every 59 seconds
   - F15 is rarely used, so it won't interfere with applications
   - Mimics the behavior of the original Zhorn Caffeine

The app runs as a hidden window with only a system tray icon visible.

---

## 🚀 Usage Tips

### Command Line (for advanced users)
While this is a GUI app, you can:
- Run multiple instances (each gets a unique tray icon)
- Use task scheduler for more complex automation
- Integrate with batch scripts using `startup.bat`

### Troubleshooting
- **Icon not showing**: Check if system tray icons are hidden in Windows settings
- **Not preventing sleep**: Ensure no other power management software conflicts
- **App won't start**: Verify you have Visual C++ Redistributables installed

---

## 📄 Technical Details

- **Language**: C (Windows API)
- **Compiler**: MinGW-w64 (GCC 15.1.0)
- **Architecture**: x86-64
- **Subsystem**: Windows GUI (no console window)
- **Dependencies**: None (statically linked option available)

---

## 📝 License

**Code**: [CC0-1.0](LICENSE) (Public Domain) - Use freely for any purpose

**Icon**: Licensed separately (see LICENSE file for details)

---

## 🤝 Contributing

Contributions welcome! For major changes, please open an issue first.

### Development Setup
1. Fork the repository
2. Install MinGW-w64 cross-compiler
3. Make changes to `src/caffeine.c`
4. Test with `make && wine build/win/caffeine.exe` (if Wine is available)
5. Submit a pull request

---

<div align="center">
<sub>Made with ☕ for developers who need their systems to stay awake</sub>
</div>
