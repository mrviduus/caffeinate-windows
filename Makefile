# Makefile — Windows-only build (x64 GUI, tray edition)
# =====================================================
# Generates build/win/caffeine.exe  (~45–50 KB) or a fully
# static build/win/caffeine-static.exe (~800 KB) if STATIC=1.
# Requires MinGW-w64 toolchain (x86_64 prefix).
# -----------------------------------------------------

# —— Configurable vars ——
PREFIX  ?= x86_64-w64-mingw32
SRC     := src/caffeine.c
RCFILE  := resources/caffeine.rc
ICON    := resources/img/logo.ico
OUTDIR  := build/win
RES     := $(OUTDIR)/caffeine.res
TARGET  := caffeine.exe

# Compile & link flags
CFLAGS  := -O2 -s -municode -mwindows -ffunction-sections -fdata-sections
LDFLAGS := -Wl,--gc-sections -luser32

ifeq ($(STATIC),1)
  LDFLAGS += -static
  TARGET   := caffeine-static.exe
endif

BIN := $(OUTDIR)/$(TARGET)

# —— Phony targets ——
.PHONY: all clean dirs

all: dirs $(BIN)
	@echo "Built $(BIN)"

# —— Build rules ——
$(BIN): $(SRC) $(RES)
	$(PREFIX)-gcc $(CFLAGS) $< $(RES) $(LDFLAGS) -o $@

$(RES): $(RCFILE) $(ICON) | dirs
	$(PREFIX)-windres -i $(RCFILE) -O coff -o $(RES)

dirs:
	@mkdir -p $(OUTDIR)

clean:
	rm -rf $(OUTDIR)
	@echo "Cleaned build artifacts."