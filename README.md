

<div align="center">
  <img src="img/logo.ico" alt="Caffeinate Windows Logo" width="200" height="200">
</div>
# Caffeine (Console Edition)

Tiny Windows utility that stops the system and display from sleeping.

## Build options

### A. Cross-compile on macOS (Homebrew)

```bash
brew install mingw-w64            # one-time
export PATH="$(brew --prefix)/opt/mingw-w64/bin:$PATH"

# Resource → COFF
x86_64-w64-mingw32-windres -i caffeine.rc -O coff -o caffeine.res

# Compile + link
x86_64-w64-mingw32-gcc -O2 -s -municode \
    caffeine.c caffeine.res -luser32 \
    -o caffeine.exe            # add -static for a fully standalone exe (~700 KB)