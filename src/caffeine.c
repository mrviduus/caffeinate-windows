// src/caffeine.c – Console “Caffeine” with animated coffee meter
// Build (cross-compile from macOS):
//   x86_64-w64-mingw32-gcc -O2 -s -municode -ffunction-sections -fdata-sections \
//       -Wl,--gc-sections src/caffeine.c build/mac/caffeine.res -luser32 \
//       -o build/mac/caffeine.exe
//   (run windres on resources/caffeine.rc first; see README)
//
// Windows 7 → 11 (x64).  By <Your Name>, CC0.

#ifndef UNICODE                 // -municode already defines these; guard to avoid warnings
#  define UNICODE
#  define _UNICODE
#endif

#include <windows.h>
#include <stdio.h>

/* ────────── ASCII logo ────────── */
static const wchar_t ASCII_CUP[] =
    L"           (("  L"\n"
    L"            ))     (("  L"\n"
    L"         _______)___"   L"\n"
    L"        /            \\" L"\n"
    L"       |   _     _    |"   L"\n"
    L"       |  |_|   |_|   |"   L"\n"
    L"        \\            /"   L"\n"
    L"         -------------"    L"\n"
    L"          \\         /"    L"\n"
    L"           \\_______/"     L"\n";

static void print_logo(void)
{
    wprintf(L"%ls\n", ASCII_CUP);
}

/* ────────── Humorous coffee-meter ────────── */
static void coffee_meter(int tick)
{
    static const wchar_t *bar[] = {
        L"[█         ] Brewing…   ",
        L"[███       ] Percolating", 
        L"[█████     ] Smells good", 
        L"[███████   ] Almost ☕  ", 
        L"[█████████ ] Caffeine!  "  // tick % 5 == 4
    };
    wprintf(L"\r%ls", bar[tick % 5]);
    fflush(stdout);
}

/* ────────── Keep-awake helpers ────────── */
static void keep_awake(void)
{
    SetThreadExecutionState(
        ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);

    /* Fallback synthetic F15 key down/up */
    INPUT in[2] = {0};
    in[0].type       = INPUT_KEYBOARD;
    in[0].ki.wVk     = VK_F15;          // 0x7E, unused
    in[1]            = in[0];
    in[1].ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(2, in, sizeof(INPUT));
}

/* ────────── Entry point ────────── */
int wmain(void)
{
    print_logo();
    wprintf(L"Caffeine console edition — keeping your PC awake.\n"
            L"Press Ctrl+C to exit.\n\n");

    for (int t = 0;; ++t)
    {
        keep_awake();
        coffee_meter(t);
        Sleep(59 * 1000);    // 59-second cycle
    }
}
