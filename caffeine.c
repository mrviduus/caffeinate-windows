/*
 * caffeine.c  —  Tiny keep‑awake utility (console version)
 *
 *  • Prints an ASCII coffee‑cup logo on launch.
 *  • Calls SetThreadExecutionState every 59 s to keep system & display awake.
 *  • Also synthesises an F15 keypress each cycle (original Caffeine behaviour).
 *
 * Build with:
 *   MSVC :  cl /O2 /W4 /nologo caffeine.c user32.lib
 *   GCC  :  gcc -O2 -s -municode -o caffeine.exe caffeine.c -luser32
 */
#define UNICODE
#define _UNICODE
#include <windows.h>
#include <stdio.h>

#pragma comment(lib, "user32.lib")

/* ─────────────────────────  ASCII logo  ───────────────────────── */
static void print_logo(void)
{
    static const wchar_t *art[] = {
        L"           ((",
        L"            ))     ((",
        L"         _______)___",
        L"        /            \\",
        L"       |   _     _    |",
        L"       |  |_|   |_|   |",
        L"        \\            /",
        L"         -------------",
        L"          \\         /",
        L"           \\_______/",
        L"",
        NULL
    };
    for (const wchar_t **line = art; *line; ++line)
        wprintf(L"%s\n", *line);
}

/* ──────────────────  Idle‑timer & fake‑key helpers  ───────────── */
static void keep_awake(void)
{
    /* 1) Tell Windows we’re busy (preferred, silent) */
    SetThreadExecutionState(
        ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);

    /* 2) Fall‑back: synthetic F15 press so apps that rely on input see activity */
    INPUT in[2] = {0};
    in[0].type           = INPUT_KEYBOARD;
    in[0].ki.wVk         = VK_F15;   /* 0x7E */
    in[1]                = in[0];
    in[1].ki.dwFlags     = KEYEVENTF_KEYUP;
    SendInput(2, in, sizeof(INPUT));
}

/* ─────────────────────────────  main  ─────────────────────────── */
int wmain(void)
{
    print_logo();
    wprintf(L"Caffeine console edition — keeping your PC awake.\n"
            L"Press Ctrl+C to exit.\n\n");

    /* Kick immediately, then every 59 s forever */
    for (;;)
    {
        keep_awake();
        Sleep(59 * 1000);
    }
    return 0;   /* never reached */
}