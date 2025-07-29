# Makefile — Cross-platform Windows executable build
# =====================================================
# This makefile builds a Windows executable from macOS/Linux using MinGW-w64
# Generates build/win/caffeine.exe (~45–50 KB) or build/win/caffeine-static.exe (~800 KB)
# 
# Prerequisites on macOS:
#   brew install mingw-w64
# Prerequisites on Linux:
#   sudo apt-get install mingw-w64
# -----------------------------------------------------

# ========== Configurable Variables ==========
# PREFIX: The MinGW compiler prefix (can be overridden from command line)
# On macOS with Homebrew, this is typically in /usr/local/bin/ or /opt/homebrew/bin/
PREFIX  ?= x86_64-w64-mingw32

# Source files and resources
SRC     := src/caffeine.c                    # Main C source file
RCFILE  := resources/caffeine.rc             # Windows resource script (defines icon, version info)
ICON    := resources/img/logo.ico            # Icon file referenced by the resource script
OUTDIR  := build/win                         # Output directory for built files
RES     := $(OUTDIR)/caffeine.res            # Compiled resource object file
TARGET  := caffeine.exe                      # Default output executable name

# ========== Compiler and Linker Flags ==========
# CFLAGS: Compilation flags
# -O2: Optimization level 2 (good balance of speed and size)
# -s: Strip debug symbols to reduce file size
# -municode: Use Unicode version of Windows API (wWinMain instead of WinMain)
# -mwindows: Create Windows GUI application (no console window)
# -ffunction-sections: Place each function in its own section
# -fdata-sections: Place each data item in its own section
CFLAGS  := -O2 -s -municode -mwindows -ffunction-sections -fdata-sections

# Additional flags for better compatibility and error checking
CFLAGS  += -Wall -Wextra                    # Enable most warning messages
CFLAGS  += -Iresources                      # Add resources directory to include path

# LDFLAGS: Linker flags
# -Wl,--gc-sections: Remove unused sections (works with -ffunction-sections/-fdata-sections)
# -luser32: Link with user32.dll (required for Windows GUI functions)
LDFLAGS := -Wl,--gc-sections -luser32

# Static build option (creates larger but self-contained executable)
ifeq ($(STATIC),1)
  LDFLAGS += -static                         # Link all libraries statically
  LDFLAGS += -static-libgcc -static-libstdc++ # Also link GCC runtime statically
  TARGET   := caffeine-static.exe            # Change output filename for static build
endif

# Final binary path
BIN := $(OUTDIR)/$(TARGET)

# ========== Build Tools ==========
# Define the actual compiler and resource compiler commands
CC      := $(PREFIX)-gcc                     # C compiler command
WINDRES := $(PREFIX)-windres                 # Windows resource compiler command

# ========== Phony Targets ==========
# These targets don't create files with their names
.PHONY: all clean dirs help check debug

# Default target - builds everything
all: dirs $(BIN)
	@echo "✓ Successfully built $(BIN)"
	@echo "  Size: $$(ls -lh $(BIN) | awk '{print $$5}')"

# ========== Build Rules ==========
# Main executable build rule
# $< = first prerequisite ($(SRC))
# $@ = target name ($(BIN))
$(BIN): $(SRC) $(RES)
	@echo "Building executable..."
	$(CC) $(CFLAGS) $< $(RES) $(LDFLAGS) -o $@
	@echo "Stripping unnecessary symbols..."
	$(PREFIX)-strip --strip-all $@

# Resource compilation rule
# -i: input file
# -O coff: output format (COFF object file)
# -o: output file
# | dirs: order-only prerequisite (dirs must exist but timestamp doesn't matter)
$(RES): $(RCFILE) $(ICON) | dirs
	@echo "Compiling Windows resources..."
	$(WINDRES) -i $(RCFILE) -O coff -o $@

# Create output directories
dirs:
	@mkdir -p $(OUTDIR)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(OUTDIR)
	@echo "✓ Cleaned build artifacts."

# ========== Help Target ==========
# Shows usage information
help:
	@echo "Caffeine Windows Build System"
	@echo "============================="
	@echo "Usage: make [target] [options]"
	@echo ""
	@echo "Targets:"
	@echo "  all    - Build the executable (default)"
	@echo "  clean  - Remove all build artifacts"
	@echo "  check  - Check if required tools are installed"
	@echo "  help   - Show this help message"
	@echo ""
	@echo "Options:"
	@echo "  STATIC=1 - Build statically linked executable"
	@echo "  PREFIX=<prefix> - Override MinGW prefix (default: x86_64-w64-mingw32)"
	@echo ""
	@echo "Examples:"
	@echo "  make              # Build normal executable"
	@echo "  make STATIC=1     # Build static executable"
	@echo "  make clean        # Clean build files"

# ========== Diagnostic Target ==========
# Checks if required tools are installed
check:
	@echo "Checking build environment..."
	@echo -n "MinGW GCC: "
	@which $(CC) > /dev/null 2>&1 && echo "✓ Found at $$(which $(CC))" || echo "✗ Not found"
	@echo -n "MinGW Windres: "
	@which $(WINDRES) > /dev/null 2>&1 && echo "✓ Found at $$(which $(WINDRES))" || echo "✗ Not found"
	@echo -n "Source file: "
	@test -f $(SRC) && echo "✓ Found" || echo "✗ Not found at $(SRC)"
	@echo -n "Resource file: "
	@test -f $(RCFILE) && echo "✓ Found" || echo "✗ Not found at $(RCFILE)"
	@echo -n "Icon file: "
	@test -f $(ICON) && echo "✓ Found" || echo "✗ Not found at $(ICON)"
	@echo ""
	@echo "Compiler version:"
	@$(CC) --version 2>/dev/null | head -n1 || echo "Cannot determine version"

# ========== Debug Information ==========
# Shows all variables (useful for debugging)
debug:
	@echo "Build Configuration:"
	@echo "==================="
	@echo "PREFIX    = $(PREFIX)"
	@echo "CC        = $(CC)"
	@echo "WINDRES   = $(WINDRES)"
	@echo "SRC       = $(SRC)"
	@echo "RCFILE    = $(RCFILE)"
	@echo "ICON      = $(ICON)"
	@echo "OUTDIR    = $(OUTDIR)"
	@echo "RES       = $(RES)"
	@echo "TARGET    = $(TARGET)"
	@echo "BIN       = $(BIN)"
	@echo "CFLAGS    = $(CFLAGS)"
	@echo "LDFLAGS   = $(LDFLAGS)"
