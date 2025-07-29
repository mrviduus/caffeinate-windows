# Makefile for Caffeine Windows
PREFIX = x86_64-w64-mingw32
CC = $(PREFIX)-gcc
WINDRES = $(PREFIX)-windres

SRC = src/caffeine.c
RCFILE = resources/caffeine.rc
ICON = resources/img/logo.ico
OUTDIR = build/win
TARGET = caffeine.exe
BIN = $(OUTDIR)/$(TARGET)
RES = $(OUTDIR)/caffeine.res

CFLAGS = -O2 -s -municode -mwindows -Wall -Iresources
LDFLAGS = -luser32

.PHONY: all clean dirs check

all: dirs $(BIN)

$(BIN): $(SRC) $(RES)
	$(CC) $(CFLAGS) $(SRC) $(RES) $(LDFLAGS) -o $(BIN)
	$(PREFIX)-strip --strip-all $(BIN)
	@echo "✓ Built $(BIN)"

$(RES): $(RCFILE) $(ICON) | dirs  
	$(WINDRES) -i $(RCFILE) -O coff -o $(RES)

dirs:
	mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)

check:
	@echo "Checking build environment..."
	@which $(CC) || echo "MinGW GCC not found"
	@which $(WINDRES) || echo "MinGW windres not found"
	@test -f $(SRC) && echo "✓ Source file found" || echo "✗ Source file missing"
	@test -f $(RCFILE) && echo "✓ Resource file found" || echo "✗ Resource file missing"
	@test -f $(ICON) && echo "✓ Icon file found" || echo "✗ Icon file missing"
