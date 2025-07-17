// src/caffeine.c – GUI/tray edition (no console)
// Builds as ~45-50 KB dynamic EXE that lives in the system tray and
// keeps the PC/display awake every 59 s. Right-click tray → Exit.
//
// Build (macOS cross-compile, 64-bit GUI subsystem):
//   x86_64-w64-mingw32-gcc -O2 -s -municode -mwindows \
//       -ffunction-sections -fdata-sections -Wl,--gc-sections \
//       src/caffeine.c build/mac/caffeine.res -luser32 -o build/mac/caffeine.exe
//
// © <Your Name>, CC0.

#ifndef UNICODE
#   define UNICODE
#   define _UNICODE
#endif

#include <windows.h>
#include <shellapi.h>
#include <stdio.h>

#define IDT_TIMER   1
#define WM_TRAYICON (WM_USER + 1)

static const wchar_t TOOLTIP[] = L"Caffeine – keeping you awake";
static const wchar_t CLASS_NAME[] = L"CaffeineTrayWindow";
static const UINT_PTR INTERVAL_MS = 59 * 1000; // 59 s

static HINSTANCE hInst;
static NOTIFYICONDATA nid = {0};

static void keep_awake(void)
{
    SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);

    INPUT in[2] = {0};
    in[0].type   = INPUT_KEYBOARD;
    in[0].ki.wVk = VK_F15;
    in[1]        = in[0];
    in[1].ki.dwFlags = KEYEVENTF_KEYUP;
    SendInput(2, in, sizeof(INPUT));
}

static void add_tray_icon(HWND hwnd)
{
    nid.cbSize           = sizeof(nid);
    nid.hWnd             = hwnd;
    nid.uID              = 1;
    nid.uFlags           = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    nid.uCallbackMessage = WM_TRAYICON;
    nid.hIcon            = LoadIconW(hInst, MAKEINTRESOURCEW(1)); // IDI_ICON1
    wcscpy_s(nid.szTip, 64, TOOLTIP);
    Shell_NotifyIconW(NIM_ADD, &nid);
}

static void del_tray_icon(void)
{
    Shell_NotifyIconW(NIM_DELETE, &nid);
    if (nid.hIcon) DestroyIcon(nid.hIcon);
}

static void show_context_menu(HWND hwnd, POINT pt)
{
    HMENU hMenu = CreatePopupMenu();
    if (!hMenu) return;
    InsertMenuW(hMenu, 0, MF_BYPOSITION | MF_STRING, 100, L"Exit");
    SetForegroundWindow(hwnd); // required
    TrackPopupMenu(hMenu, TPM_RIGHTBUTTON, pt.x, pt.y, 0, hwnd, NULL);
    DestroyMenu(hMenu);
}

static LRESULT CALLBACK wnd_proc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg)
    {
        case WM_CREATE:
            add_tray_icon(hwnd);
            SetTimer(hwnd, IDT_TIMER, INTERVAL_MS, NULL);
            keep_awake();
            return 0;

        case WM_TIMER:
            if (wParam == IDT_TIMER) keep_awake();
            return 0;

        case WM_TRAYICON:
            if (LOWORD(lParam) == WM_RBUTTONUP)
            {
                POINT pt; GetCursorPos(&pt);
                show_context_menu(hwnd, pt);
            }
            return 0;

        case WM_COMMAND:
            if (LOWORD(wParam) == 100)
                PostQuitMessage(0);
            return 0;

        case WM_DESTROY:
            del_tray_icon();
            PostQuitMessage(0);
            return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int)
{
    hInst = hInstance;

    WNDCLASSW wc = {0};
    wc.lpfnWndProc   = wnd_proc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = CLASS_NAME;
    RegisterClassW(&wc);

    HWND hwnd = CreateWindowExW(0, CLASS_NAME, L"CaffeineTray", 0,
                                0,0,0,0, HWND_MESSAGE, NULL, hInstance, NULL);
    if (!hwnd) return 0;

    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return 0;
}