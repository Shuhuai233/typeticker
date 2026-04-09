// global_input_hook.cpp
// Standalone background EXE — installs global keyboard/mouse/controller hooks
// and writes the running count to a temp file that Godot polls.
// Usage: global_input_hook.exe <output_file_path>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <xinput.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

static volatile int64_t g_count = 0;
static HHOOK g_kb_hook = NULL;
static HHOOK g_ms_hook = NULL;
static char g_out_file[MAX_PATH] = {0};

static void write_count() {
    char tmp[MAX_PATH];
    snprintf(tmp, MAX_PATH, "%s.tmp", g_out_file);
    FILE* f = fopen(tmp, "w");
    if (f) {
        fprintf(f, "%lld", (long long)g_count);
        fclose(f);
        MoveFileExA(tmp, g_out_file, MOVEFILE_REPLACE_EXISTING);
    }
}

LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN)) {
        InterlockedIncrement64(&g_count);
        write_count();
    }
    return CallNextHookEx(g_kb_hook, nCode, wParam, lParam);
}

LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode == HC_ACTION && (
        wParam == WM_LBUTTONDOWN || wParam == WM_RBUTTONDOWN ||
        wParam == WM_MBUTTONDOWN || wParam == WM_XBUTTONDOWN)) {
        InterlockedIncrement64(&g_count);
        write_count();
    }
    return CallNextHookEx(g_ms_hook, nCode, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInst, HINSTANCE, LPSTR lpCmdLine, int) {
    // Get output file path from command line
    if (!lpCmdLine || !lpCmdLine[0]) {
        snprintf(g_out_file, MAX_PATH, "%s\\desktoppet_count.txt",
            getenv("TEMP") ? getenv("TEMP") : "C:\\Temp");
    } else {
        strncpy(g_out_file, lpCmdLine, MAX_PATH - 1);
    }

    // Write initial 0
    write_count();

    // Install hooks
    g_kb_hook = SetWindowsHookEx(WH_KEYBOARD_LL, LowLevelKeyboardProc, hInst, 0);
    g_ms_hook = SetWindowsHookEx(WH_MOUSE_LL,    LowLevelMouseProc,    hInst, 0);

    WORD prev_buttons[XUSER_MAX_COUNT] = {0};

    // Message loop — required for hooks to fire
    MSG msg;
    while (true) {
        // Poll XInput controllers
        for (DWORD i = 0; i < XUSER_MAX_COUNT; i++) {
            XINPUT_STATE state = {};
            if (XInputGetState(i, &state) == ERROR_SUCCESS) {
                WORD diff = state.Gamepad.wButtons & ~prev_buttons[i];
                if (diff) {
                    for (WORD b = diff; b; b &= b - 1)
                        InterlockedIncrement64(&g_count);
                    write_count();
                    prev_buttons[i] = state.Gamepad.wButtons;
                }
            }
        }

        // Process hook messages
        while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT) goto cleanup;
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
        Sleep(8);
    }

cleanup:
    if (g_kb_hook) UnhookWindowsHookEx(g_kb_hook);
    if (g_ms_hook) UnhookWindowsHookEx(g_ms_hook);
    return 0;
}
