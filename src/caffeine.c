// src/caffeine.c — GUI/tray edition (no console window)
// ------------------------------------------------------
// * Runs as a background tray app ( subsystem: WINDOWS )
// * Refreshes system/display idle timers every 59 s
// * Sends a harmless F15 key‑stroke as fallback
// * Right‑click tray icon → Exit
//
// Build (macOS / Linux cross‑compile, 64‑bit):
//   x86_64-w64-mingw32-gcc -O2 -s -municode -mwindows \
//       -Iresources -ffunction-sections -fdata-sections -Wl,--gc-sections \
//       src/caffeine.c build/mac/caffeine.res -luser32 \
//       -o build/mac/caffeine.exe
//
// Build (Windows / MSVC):
//   rc /nologo /fo build\win\caffeine.res resources\caffeine.rc
//   cl /O2 /W4 /nologo /Iresources src\caffeine.c build\win\caffeine.res user32.lib ^
//      /link /SUBSYSTEM:WINDOWS /OUT:build\win\caffeine.exe
//
// License: CC0‑1.0 — public domain dedication.

#ifndef UNICODE            // -municode defines these, guard to avoid re‑define warning
#  define UNICODE
#  define _UNICODE
#endif

#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include "../resources/resource.h"     // IDI_ICON1 definition

// ─────────────────── Constants ─────────────────────
#define IDT_TIMER     1
#define WM_TRAYICON  (WM_USER + 1)

static const wchar_t TOOLTIP[]    = L"Caffeine – keeping you awake";
static const wchar_t CLASS_NAME[] = L"CaffeineTrayWindow";
static const UINT_PTR INTERVAL_MS = 59 * 1000;  // 59 s

// ─────────────────── Globals ───────────────────────
static HINSTANCE      g_hInst;
static NOTIFYICONDATA g_nid = {0};

// ─────────────────── Helper: keep system awake ────
static void keep_awake(void)
{
    // Preferred API (silent)
    SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);

    // Fallback: synthetic F15 key press
    INPUT in[2] = {0};
    in[0].type       = INPUT_KEYBOARD;
    in[0].ki.wVk     = VK_F15;          // 0x7E – rarely used
    in[1]            = in[0];
    in[1].ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(2, in, sizeof(INPUT));
}

// ─────────────────── Tray icon helpers ────────────
static void tray_add(HWND hwnd)
{
    g_nid.cbSize           = sizeof(g_nid);
    g_nid.hWnd             = hwnd;
    g_nid.uID              = 1;
    g_nid.uFlags           = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    g_nid.uCallbackMessage = WM_TRAYICON;
    g_nid.hIcon = (HICON)LoadImageW(g_hInst,
                                    MAKEINTRESOURCEW(IDI_ICON1),
                                    IMAGE_ICON,
                                    16, 16, LR_DEFAULTCOLOR);
    wcscpy_s(g_nid.szTip, ARRAYSIZE(g_nid.szTip), TOOLTIP);
    Shell_NotifyIconW(NIM_ADD, &g_nid);
}

static void tray_remove(void)
{
    Shell_NotifyIconW(NIM_DELETE, &g_nid);
    if (g_nid.hIcon) DestroyIcon(g_nid.hIcon);
}

static void tray_show_menu(HWND hwnd, POINT pt)
{
    HMENU hMenu = CreatePopupMenu();
    if (!hMenu) return;

    InsertMenuW(hMenu, 0, MF_BYPOSITION | MF_STRING, 100, L"Exit");
    SetForegroundWindow(hwnd);  // ensures menu closes correctly
    TrackPopupMenu(hMenu, TPM_RIGHTBUTTON, pt.x, pt.y, 0, hwnd, NULL);
    DestroyMenu(hMenu);
}

// ─────────────────── Window procedure ─────────────
static LRESULT CALLBACK wnd_proc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
{
    switch (msg)
    {
        case WM_CREATE:
            tray_add(hwnd);
            SetTimer(hwnd, IDT_TIMER, INTERVAL_MS, NULL);
            keep_awake();
            return 0;

        case WM_TIMER:
            if (wp == IDT_TIMER) keep_awake();
            return 0;

        case WM_TRAYICON:
            if (LOWORD(lp) == WM_RBUTTONUP)
            {
                POINT pt; GetCursorPos(&pt);
                tray_show_menu(hwnd, pt);
            }
            return 0;

        case WM_COMMAND:
            if (LOWORD(wp) == 100) PostQuitMessage(0);
            return 0;

        case WM_DESTROY:
            tray_remove();
            PostQuitMessage(0);
            return 0;
    }
    return DefWindowProcW(hwnd, msg, wp, lp);
}

// ─────────────────── Entry point ───────────────────
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int)
{
    g_hInst = hInstance;

    WNDCLASSW wc = {0};
    wc.lpfnWndProc   = wnd_proc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = CLASS_NAME;
    RegisterClassW(&wc);

    HWND hwnd = CreateWindowExW(0, CLASS_NAME, L"CaffeineTray",
                                0, 0, 0, 0, 0,
                                HWND_MESSAGE, NULL, hInstance, NULL);
    if (!hwnd) return 0;

    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return 0;
}
