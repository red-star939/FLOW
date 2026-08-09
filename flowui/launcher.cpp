#include <windows.h>
#include <iostream>
#include <filesystem>
#include <string>

namespace fs = std::filesystem;

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // 1. Run updater.exe if present
    if (fs::exists("updater.exe")) {
        STARTUPINFOA si;
        PROCESS_INFORMATION pi;
        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);
        si.dwFlags = STARTF_USESHOWWINDOW;
        si.wShowWindow = SW_SHOWNORMAL; // Show update window/logs if any

        ZeroMemory(&pi, sizeof(pi));

        char cmd[] = "updater.exe";
        if (CreateProcessA(NULL, cmd, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
            WaitForSingleObject(pi.hProcess, 60000); // Wait up to 60s for update to complete
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
        }
    }

    // 2. Launch main application Flow.exe (or appflowui.exe)
    std::string appName = "Flow.exe";
    if (!fs::exists(appName) && fs::exists("appflowui.exe")) {
        appName = "appflowui.exe";
    }

    STARTUPINFOA siApp;
    PROCESS_INFORMATION piApp;
    ZeroMemory(&siApp, sizeof(siApp));
    siApp.cb = sizeof(siApp);
    ZeroMemory(&piApp, sizeof(piApp));

    char appCmd[MAX_PATH];
    strncpy(appCmd, appName.c_str(), sizeof(appCmd) - 1);
    appCmd[sizeof(appCmd) - 1] = '\0';

    CreateProcessA(NULL, appCmd, NULL, NULL, FALSE, 0, NULL, NULL, &siApp, &piApp);
    if (piApp.hProcess) CloseHandle(piApp.hProcess);
    if (piApp.hThread) CloseHandle(piApp.hThread);

    return 0;
}
