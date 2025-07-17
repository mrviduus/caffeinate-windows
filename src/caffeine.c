/*
 * caffeine.c – tiny console utility that keeps the PC awake
 *
 *   • Prints an ASCII coffee-cup.
 *   • Calls SetThreadExecutionState every 59 s.
 *   • Sends an F15 key press as a fallback.
 *
 * Build (cross-compile from macOS):
 *   x86_64-w64-mingw32-gcc -O2 -s -municode \
 *       caffeine.c caffeine.res -luser32 -o caffeine.exe
 */

#ifndef UNICODE           /* -municode already defines it; guard to avoid warning */
#  define UNICODE
#  define _UNICODE
#endif

#include <windows.h>
#include <stdio.h>

static const wchar_t ASCII_CUP[] =
    L"           (("  L"\n"
    L"            ))     (("  L"\n"
    L"         _______)___"   L"\n"
    L"        /            \\" L"\n"
    L"       |   _     _    |" L"\n"
    L"       |  |_|   |_|   |" L"\n"
    L"        \\            /" L"\n"
    L"         -------------"  L"\n"
    L"          \\         /"   L"\n"
    L"           \\_______/"    L"\n";

static void print_logo(void)
{
    wprintf(L"%s\n", ASCII_CUP);
}

static void keep_awake(void)
{
    /* Official API */
    SetThreadExecutionState(
        ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);

    /* Fallback synthetic key (F15) */
    INPUT in[2] = {0};
    in[0].type       = INPUT_KEYBOARD;
    in[0].ki.wVk     = VK_F15;          /* 0x7E, rarely used */
    in[1]            = in[0];
    in[1].ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(2, in, sizeof(INPUT));
}

int wmain(void)
{
    print_logo();
    wprintf(L"Caffeine console edition — keeping your PC awake.\n"
            L"Press Ctrl+C to exit.\n\n");

    for (;;)
    {
        keep_awake();
        Sleep(59 * 1000);
    }
}