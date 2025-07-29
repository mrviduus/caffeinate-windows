# Cross-platform Windows executable build for caffeine
# Builds Windows .exe from macOS/Linux using MinGW-w64

# PREFIX: MinGW-w64 cross-compiler prefix (can be overridden with: make PREFIX=custom-prefix)
# ?= operator means "assign if not already defined" (allows command-line override)
PREFIX ?= x86_64-w64-mingw32

# CC: C compiler command - constructed from PREFIX + gcc suffix
# := operator means "immediately expanded assignment" (evaluated once at assignment)
CC := $(PREFIX)-gcc

# WINDRES: Windows resource compiler command - constructs resource files into object format
# Used to compile .rc files (containing icons, version info) into .res files
WINDRES := $(PREFIX)-windres

# SRC: Path to main C source file containing the application code
SRC := src/caffeine.c

# RCFILE: Path to Windows resource script file (defines icons, version info, etc.)
RCFILE := resources/caffeine.rc

# OUTDIR: Output directory where all build artifacts will be placed
OUTDIR := build/win

# RES: Path to compiled resource object file (created from RCFILE)
# This will be linked with the main executable
RES := $(OUTDIR)/caffeine.res

# BIN: Final executable path - this is the target we want to build
BIN := $(OUTDIR)/caffeine.exe

# CFLAGS: Compiler flags that control how the C code is compiled
# -O2: Optimization level 2 (good balance of speed and size)
# -s: Strip debug symbols from output (reduces file size)
# -municode: Use Unicode APIs (wWinMain instead of WinMain)
# -mwindows: Create Windows GUI app (no console window appears)
# -Wall: Enable most compiler warnings (helps catch potential bugs)
# -Iresources: Add resources/ directory to include search path
CFLAGS := -O2 -s -municode -mwindows -Wall -Iresources

# LDFLAGS: Linker flags that control how object files are linked together
# -luser32: Link with user32.dll (required for Windows GUI functions like MessageBox)
LDFLAGS := -luser32

# .PHONY: Declares targets that don't create files with their names
# This prevents conflicts if files named 'all', 'clean', etc. exist
# Make will always run these targets regardless of file timestamps
.PHONY: all clean help check

# all: Default target (runs when you type just 'make')
# Dependency: $(BIN) - the executable must be built first
all: $(BIN)
	# @echo: Print message without showing the command itself (@ suppresses echo)
	@echo "✓ Built $(BIN)"

# $(BIN): Rule to build the final executable
# Dependencies: $(SRC) - source file, $(RES) - compiled resources
# Order-only prerequisite: | $(OUTDIR) - directory must exist but timestamp doesn't matter
$(BIN): $(SRC) $(RES) | $(OUTDIR)
	# @echo: Print build status message to user
	@echo "Building executable..."
	# $(CC): Run the C compiler with all our flags and dependencies
	# $< would be first prerequisite, but we specify $(SRC) explicitly for clarity
	$(CC) $(CFLAGS) $(SRC) $(RES) $(LDFLAGS) -o $@
	# $(PREFIX)-strip: Remove debugging symbols and unused sections to minimize size
	# --strip-all: Remove all symbol and debug information
	$(PREFIX)-strip --strip-all $@

# $(RES): Rule to compile Windows resource file (.rc) into object format (.res)
# Dependencies: $(RCFILE) - the .rc source file containing icon and version info
# Order-only prerequisite: | $(OUTDIR) - build directory must exist first
$(RES): $(RCFILE) | $(OUTDIR)
	# @echo: Inform user that resource compilation is starting
	@echo "Compiling Windows resources..."
	# $(WINDRES): Windows resource compiler converts .rc to .res object file
	# -i: Input file (resources/caffeine.rc)
	# -O coff: Output format (Common Object File Format for linking)
	# -o: Output file (build/win/caffeine.res)
	$(WINDRES) -i $(RCFILE) -O coff -o $@

# $(OUTDIR): Rule to create the build output directory
# No dependencies - this just ensures the directory exists
$(OUTDIR):
	# @echo: Inform user that directory creation is happening
	@echo "Creating build directory..."
	# mkdir -p: Create directory and any necessary parent directories
	# -p flag prevents errors if directory already exists
	mkdir -p $(OUTDIR)

# clean: Target to remove all build artifacts and start fresh
# No dependencies - can be run anytime to clean up
clean:
	# @echo: Inform user about cleanup operation
	@echo "Cleaning build artifacts..."
	# rm -rf: Remove files and directories recursively and forcefully
	# -r: Recursive (remove directories and their contents)
	# -f: Force (don't prompt for confirmation, ignore missing files)
	rm -rf $(OUTDIR)
	# @echo: Confirm cleanup completion
	@echo "✓ Cleaned build artifacts."

# help: Target to display usage information for this Makefile
# No dependencies - informational target only
help:
	# @echo: Display help header
	@echo "Caffeine Windows Build System"
	# @echo: Display usage format
	@echo "Usage: make [target]"
	# @echo: List available targets
	@echo "Targets: all, clean, help, check"

# check: Target to verify that all required build tools and files are available
# No dependencies - diagnostic target only
check:
	# @echo: Display diagnostic header
	@echo "Checking build environment..."
	# @which: Check if compiler exists in PATH, show success/failure message
	# > /dev/null: Redirect output to nowhere (suppress command output)
	# &&: Run second command only if first succeeds
	# ||: Run second command only if first fails
	@which $(CC) > /dev/null && echo "✓ $(CC) found" || echo "✗ $(CC) not found"
	# @which: Check if resource compiler exists in PATH
	@which $(WINDRES) > /dev/null && echo "✓ $(WINDRES) found" || echo "✗ $(WINDRES) not found"
	# @test -f: Check if source file exists (test -f returns true for regular files)
	@test -f $(SRC) && echo "✓ Source found" || echo "✗ Source missing"
	# @test -f: Check if resource file exists
	@test -f $(RCFILE) && echo "✓ Resource file found" || echo "✗ Resource file missing"
