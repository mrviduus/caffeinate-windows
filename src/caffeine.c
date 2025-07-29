// src/caffeine.c — GUI/tray edition (no console window)
// ------------------------------------------------------
// * Runs as a background tray app ( subsystem: WINDOWS )
// * Refreshes system/display idle timers every 59 s
// * Sends a harmless F15 key‑stroke as fallback
// * Right‑click tray icon → Exit
//
// Build (macOS / Linux cross‑compile, 64‑bit):
//   x86_64-w64-mingw32-gcc -O2 -s -municode -mwindows 
//       -Iresources -ffunction-sections -fdata-sections -Wl,--gc-sections 
//       src/caffeine.c build/mac/caffeine.res -luser32 
//       -o build/mac/caffeine.exe
//
// Build (Windows / MSVC):
//   rc /nologo /fo build/win/caffeine.res resources/caffeine.rc
//   cl /O2 /W4 /nologo /Iresources src/caffeine.c build/win/caffeine.res user32.lib 
//      /link /SUBSYSTEM:WINDOWS /OUT:build/win/caffeine.exe
//
// License: CC0‑1.0 — public domain dedication.

#ifndef UNICODE            // Check if UNICODE is not already defined to avoid redefinition warnings
#  define UNICODE          // Define UNICODE macro to use wide character (UTF-16) versions of Windows API functions
#  define _UNICODE         // Define _UNICODE macro to use wide character versions of C runtime functions
#endif                     // End of conditional compilation block

#include <stddef.h>        // Include standard definitions for size_t, wchar_t, and other basic types
#include <windows.h>       // Include core Windows API headers for system functions and data types
#include <shellapi.h>      // Include shell API headers for system tray/notification icon functions
#include <stdio.h>         // Include standard I/O library headers (unused in this program but commonly included)
#include "../resources/resource.h"     // Include custom resource header file containing IDI_ICON1 icon definition

// ─────────────────── Constants ─────────────────────
#define IDT_TIMER     1                        // Timer identifier constant used to identify our periodic timer
#define WM_TRAYICON  (WM_USER + 1)            // Custom window message ID for tray icon events (WM_USER + 1 = 0x401)

static const wchar_t TOOLTIP[]    = L"Caffeine – keeping you awake";   // Tooltip text displayed when hovering over tray icon
static const wchar_t CLASS_NAME[] = L"CaffeineTrayWindow";              // Window class name for our hidden message-only window
static const UINT_PTR INTERVAL_MS = 59 * 1000;  // Timer interval in milliseconds (59 seconds)

// ─────────────────── Globals ───────────────────────
static HINSTANCE      g_hInst;                   // Global variable to store the application instance handle
static NOTIFYICONDATA g_nid = {0};              // Global structure containing tray icon data, zero-initialized

// ─────────────────── Helper: keep system awake ────
static void keep_awake(void)                     // Function to prevent system from going to sleep or turning off display
{
    // Preferred API (silent)
    SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);  // Tell Windows to stay awake: ES_CONTINUOUS=keep awake until called again, ES_SYSTEM_REQUIRED=prevent sleep, ES_DISPLAY_REQUIRED=keep display on

    // Fallback: synthetic F15 key press
    INPUT in[2] = {0};                           // Array of 2 INPUT structures for key press and release, zero-initialized
    in[0].type       = INPUT_KEYBOARD;           // Set first input structure type to keyboard input
    in[0].ki.wVk     = VK_F15;                   // Set virtual key code to F15 (0x7E) - rarely used key that won't interfere
    in[1]            = in[0];                    // Copy first structure to second (for key release)
    in[1].ki.dwFlags = KEYEVENTF_KEYUP;         // Set flag for key release event on second structure
    SendInput(2, in, sizeof(INPUT));            // Send both key press and release events to system input queue
}

// ─────────────────── Tray icon helpers ────────────
static void tray_add(HWND hwnd)                 // Function to add icon to system tray/notification area
{
    g_nid.cbSize           = sizeof(g_nid);      // Set size of NOTIFYICONDATA structure for version compatibility
    g_nid.hWnd             = hwnd;               // Set window handle that will receive tray icon messages
    g_nid.uID              = 1;                  // Set unique identifier for this tray icon (arbitrary value)
    g_nid.uFlags           = NIF_MESSAGE | NIF_ICON | NIF_TIP;  // Enable message callbacks, icon display, and tooltip
    g_nid.uCallbackMessage = WM_TRAYICON;        // Set custom message ID that will be sent when tray icon is clicked
    g_nid.hIcon = (HICON)LoadImageW(g_hInst,     // Load icon from resources and cast to HICON handle
                                    MAKEINTRESOURCEW(IDI_ICON1),  // Convert icon resource ID to wide string resource identifier
                                    IMAGE_ICON,                   // Specify that we're loading an icon (not bitmap/cursor)
                                    16, 16, LR_DEFAULTCOLOR);     // Load as 16x16 pixels with default color depth
    wcscpy_s(g_nid.szTip, ARRAYSIZE(g_nid.szTip), TOOLTIP);     // Safely copy tooltip text to structure, respecting buffer size
    Shell_NotifyIconW(NIM_ADD, &g_nid);         // Add the configured icon to the system tray
}

static void tray_remove(void)                   // Function to remove icon from system tray and clean up resources
{
    Shell_NotifyIconW(NIM_DELETE, &g_nid);      // Remove the tray icon from system notification area
    if (g_nid.hIcon) DestroyIcon(g_nid.hIcon);  // Free icon handle if it exists to prevent memory leak
}

static void tray_show_menu(HWND hwnd, POINT pt)  // Function to display context menu when tray icon is right-clicked
{
    HMENU hMenu = CreatePopupMenu();             // Create a new popup menu handle
    if (!hMenu) return;                          // Exit if menu creation failed

    InsertMenuW(hMenu, 0, MF_BYPOSITION | MF_STRING, 100, L"Exit");  // Insert "Exit" menu item at position 0 with command ID 100
    SetForegroundWindow(hwnd);                   // Bring our window to foreground so menu closes properly when clicking elsewhere
    TrackPopupMenu(hMenu, TPM_RIGHTBUTTON, pt.x, pt.y, 0, hwnd, NULL);  // Display popup menu at cursor position, handle right-clicks
    DestroyMenu(hMenu);                          // Clean up menu handle to prevent memory leak
}

// ─────────────────── Window procedure ─────────────
static LRESULT CALLBACK wnd_proc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)  // Main window message handler function
{
    switch (msg)                                 // Process different types of Windows messages
    {
        case WM_CREATE:                          // Message sent when window is being created
            tray_add(hwnd);                      // Add our icon to the system tray
            SetTimer(hwnd, IDT_TIMER, INTERVAL_MS, NULL);  // Start periodic timer with our defined interval
            keep_awake();                        // Perform initial keep-awake call
            return 0;                            // Return 0 to indicate message was handled successfully

        case WM_TIMER:                           // Message sent when timer expires
            if (wp == IDT_TIMER) keep_awake();   // If it's our timer (check wParam), execute keep-awake function
            return 0;                            // Return 0 to indicate message was handled

        case WM_TRAYICON:                        // Custom message sent when tray icon receives input
            if (LOWORD(lp) == WM_RBUTTONUP)      // Check if low word of lParam indicates right mouse button release
            {
                POINT pt; GetCursorPos(&pt);     // Declare POINT structure and get current cursor coordinates
                tray_show_menu(hwnd, pt);        // Display context menu at cursor position
            }
            return 0;                            // Return 0 to indicate message was handled

        case WM_COMMAND:                         // Message sent when menu item is selected
            if (LOWORD(wp) == 100) PostQuitMessage(0);  // If command ID is 100 (Exit), post quit message to exit application
            return 0;                            // Return 0 to indicate message was handled

        case WM_DESTROY:                         // Message sent when window is being destroyed
            tray_remove();                       // Remove tray icon and clean up resources
            PostQuitMessage(0);                  // Post quit message to exit application message loop
            return 0;                            // Return 0 to indicate message was handled
    }
    return DefWindowProcW(hwnd, msg, wp, lp);    // Pass unhandled messages to default window procedure
}

// ─────────────────── Entry point ───────────────────
int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int)  // Windows GUI application entry point (wide-char version)
{
    g_hInst = hInstance;                         // Store application instance handle in global variable

    WNDCLASSW wc = {0};                          // Window class structure, zero-initialized
    wc.lpfnWndProc   = wnd_proc;                 // Set window procedure function pointer
    wc.hInstance     = hInstance;                // Set application instance handle
    wc.lpszClassName = CLASS_NAME;               // Set window class name
    RegisterClassW(&wc);                         // Register the window class with Windows

    HWND hwnd = CreateWindowExW(0, CLASS_NAME, L"CaffeineTray",  // Create window with extended style 0, our class name, and window title
                                0, 0, 0, 0, 0,                   // Position (0,0) and size (0,0) - not visible anyway
                                HWND_MESSAGE, NULL, hInstance, NULL);  // Create as message-only window (no UI), no parent, with our instance
    if (!hwnd) return 0;                         // Exit if window creation failed

    MSG msg;                                     // Message structure to hold Windows messages
    while (GetMessageW(&msg, NULL, 0, 0))       // Message loop: get messages from system queue (blocks until message received)
    {
        TranslateMessage(&msg);                  // Translate virtual key messages into character messages
        DispatchMessageW(&msg);                  // Dispatch message to appropriate window procedure
    }
    return 0;                                    // Return 0 when application exits (GetMessage returns 0 on WM_QUIT)
}
