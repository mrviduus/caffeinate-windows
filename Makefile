# ---------- config ----------
TARGET   := caffeine.exe
SRC      := src/caffeine.c
RC       := resources/caffeine.rc
ICON     := resources/img/logo.ico
RES      := build/$(notdir $(RC:.rc=.res))

MINGW_PREFIX ?= x86_64-w64-mingw32

BUILD_DIR := build/win
CFLAGS    := -O2 -s -municode
LDFLAGS   := -luser32
# ----------------------------

.PHONY: all clean

all: $(BUILD_DIR)/$(TARGET)

$(BUILD_DIR)/$(TARGET): $(SRC) $(RES) | $(BUILD_DIR)
	$(MINGW_PREFIX)-gcc $(CFLAGS) $< $(RES) $(LDFLAGS) -o $@

$(RES): $(RC) $(ICON) | build
	$(MINGW_PREFIX)-windres -i $< -O coff -o $@

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf build