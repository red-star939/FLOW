#include <windows.h>
#include <commctrl.h>
#include <wininet.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <regex>
#include <filesystem>
#include <thread>
#include <mutex>

#pragma comment(lib, "wininet.lib")
#pragma comment(lib, "comctl32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "user32.lib")

namespace fs = std::filesystem;

// Custom WM Message IDs for UI Updates
#define WM_UPDATE_STATUS    (WM_USER + 101)
#define WM_UPDATE_PROGRESS  (WM_USER + 102)
#define WM_UPDATE_LOG       (WM_USER + 103)
#define WM_UPDATE_FINISH    (WM_USER + 104)

struct VersionInfo {
    std::string tag = "v1.5_stable";
    int major = 1;
    int minor = 5;
    std::string sha = "";
};

// Global UI Handles
HWND g_hWnd = NULL;
HWND g_hProgressBar = NULL;
HWND g_hStatusText = NULL;
HWND g_hLogList = NULL;
HFONT g_hFontTitle = NULL;
HFONT g_hFontSub = NULL;
HFONT g_hFontNormal = NULL;
HFONT g_hFontLog = NULL;

VersionInfo load_local_version() {
    VersionInfo info;
    if (fs::exists("version.json")) {
        try {
            std::ifstream ifs("version.json");
            std::string content((std::istreambuf_iterator<char>(ifs)), std::istreambuf_iterator<char>());
            ifs.close();

            std::smatch mTag, mSha;
            if (std::regex_search(content, mTag, std::regex("\"tag\"\\s*:\\s*\"([^\"]+)\""))) {
                info.tag = mTag[1].str();
            }

            if (std::regex_search(content, mSha, std::regex("\"sha\"\\s*:\\s*\"([^\"]+)\""))) {
                info.sha = mSha[1].str();
            }

            std::smatch m;
            if (std::regex_search(info.tag, m, std::regex("v(\\d+)\\.(\\d+)_stable"))) {
                info.major = std::stoi(m[1].str());
                info.minor = std::stoi(m[2].str());
            }
        } catch (...) {}
    }
    return info;
}

void save_local_version(const std::string& tag, int major, int minor, const std::string& sha) {
    try {
        std::ofstream ofs("version.json");
        ofs << "{\n";
        ofs << "  \"tag\": \"" << tag << "\",\n";
        ofs << "  \"version\": \"" << major << "." << minor << "\",\n";
        ofs << "  \"sha\": \"" << sha << "\"\n";
        ofs << "}\n";
        ofs.close();
    } catch (...) {}
}

// Pure WinINet HTTP GET Request (Zero Console Window)
std::string http_get(const std::string& url) {
    HINTERNET hInternet = InternetOpenA("FLOW-AutoUpdater/1.5", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);
    if (!hInternet) return "";

    DWORD flags = INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_SECURE;
    HINTERNET hConnect = InternetOpenUrlA(hInternet, url.c_str(), "User-Agent: FLOW-AutoUpdater\r\n", -1L, flags, 0);
    if (!hConnect) {
        flags = INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE;
        hConnect = InternetOpenUrlA(hInternet, url.c_str(), "User-Agent: FLOW-AutoUpdater\r\n", -1L, flags, 0);
    }
    if (!hConnect) {
        InternetCloseHandle(hInternet);
        return "";
    }

    std::string response;
    char buffer[8192];
    DWORD bytesRead = 0;
    while (InternetReadFile(hConnect, buffer, sizeof(buffer) - 1, &bytesRead) && bytesRead > 0) {
        buffer[bytesRead] = '\0';
        response += buffer;
    }
    InternetCloseHandle(hConnect);
    InternetCloseHandle(hInternet);
    return response;
}

// Pure WinINet HTTP/HTTPS File Downloader (Zero Console Window)
bool download_file(const std::string& url, const std::string& dest_path) {
    fs::path dest(dest_path);
    if (dest.has_parent_path()) {
        std::error_code ec;
        fs::create_directories(dest.parent_path(), ec);
    }

    HINTERNET hInternet = InternetOpenA("FLOW-AutoUpdater/1.5", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);
    if (!hInternet) return false;

    DWORD flags = INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_SECURE;
    HINTERNET hConnect = InternetOpenUrlA(hInternet, url.c_str(), "User-Agent: FLOW-AutoUpdater\r\n", -1L, flags, 0);
    if (!hConnect) {
        flags = INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE;
        hConnect = InternetOpenUrlA(hInternet, url.c_str(), "User-Agent: FLOW-AutoUpdater\r\n", -1L, flags, 0);
    }

    if (!hConnect) {
        InternetCloseHandle(hInternet);
        return false;
    }

    std::ofstream ofs(dest_path, std::ios::binary);
    if (!ofs.is_open()) {
        InternetCloseHandle(hConnect);
        InternetCloseHandle(hInternet);
        return false;
    }

    char buffer[16384];
    DWORD bytesRead = 0;
    while (InternetReadFile(hConnect, buffer, sizeof(buffer), &bytesRead) && bytesRead > 0) {
        ofs.write(buffer, bytesRead);
    }

    ofs.close();
    InternetCloseHandle(hConnect);
    InternetCloseHandle(hInternet);

    return fs::exists(dest_path) && fs::file_size(dest_path) > 0;
}

// Execute command silently with CREATE_NO_WINDOW flag (Zero CMD Popup)
bool RunCommandNoWindow(const std::string& cmd, const std::string& workDir = "") {
    STARTUPINFOA si = { sizeof(si) };
    PROCESS_INFORMATION pi = { 0 };
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;

    std::vector<char> cmdBuf(cmd.begin(), cmd.end());
    cmdBuf.push_back('\0');

    BOOL ret = CreateProcessA(
        NULL, cmdBuf.data(), NULL, NULL, FALSE,
        CREATE_NO_WINDOW,
        NULL, workDir.empty() ? NULL : workDir.c_str(),
        &si, &pi
    );

    if (ret) {
        WaitForSingleObject(pi.hProcess, INFINITE);
        DWORD exitCode = 0;
        GetExitCodeProcess(pi.hProcess, &exitCode);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return exitCode == 0;
    }
    return false;
}

// Thread-safe UI update helpers
void UI_SetStatus(const std::wstring& status) {
    if (!g_hWnd) return;
    wchar_t* msg = _wcsdup(status.c_str());
    PostMessageW(g_hWnd, WM_UPDATE_STATUS, 0, (LPARAM)msg);
}

void UI_SetProgress(int pos) {
    if (!g_hWnd) return;
    PostMessageW(g_hWnd, WM_UPDATE_PROGRESS, (WPARAM)pos, 0);
}

void UI_AddLog(const std::wstring& log) {
    if (!g_hWnd) return;
    wchar_t* msg = _wcsdup(log.c_str());
    PostMessageW(g_hWnd, WM_UPDATE_LOG, 0, (LPARAM)msg);
}

void UI_Finish() {
    if (!g_hWnd) return;
    PostMessageW(g_hWnd, WM_UPDATE_FINISH, 0, 0);
}

// Background Worker Thread performing actual Update Sync
void PerformUpdateWorker(VersionInfo localVer, std::string remoteSha, std::string commitJson) {
    UI_SetProgress(10);
    UI_SetStatus(L"업데이트 파일 목록 수신 중...");
    UI_AddLog(L"[시작] 새 버전 감지: " + std::wstring(remoteSha.begin(), remoteSha.begin() + 7));

    std::regex fileRegex("\"filename\"\\s*:\\s*\"([^\"]+)\"");
    auto file_begin = std::sregex_iterator(commitJson.begin(), commitJson.end(), fileRegex);
    auto file_end = std::sregex_iterator();

    std::vector<std::string> changedFiles;
    for (std::sregex_iterator i = file_begin; i != file_end; ++i) {
        std::smatch match = *i;
        changedFiles.push_back(match[1].str());
    }

    if (changedFiles.empty()) {
        changedFiles = { "dist/Flow.exe", "version.json" };
    }

    size_t totalFiles = changedFiles.size();
    size_t updatedCount = 0;
    size_t skippedCount = 0;
    bool sourceFilesChanged = false;

    for (size_t i = 0; i < totalFiles; ++i) {
        std::string rawPath = changedFiles[i];
        int pct = 10 + static_cast<int>((static_cast<double>(i) / totalFiles) * 70);
        UI_SetProgress(pct);

        // Data protection
        if (rawPath == "db/database.json" || rawPath == "db\\database.json" || rawPath.find(".db") != std::string::npos) {
            UI_AddLog(L"[보호] 가계부 DB 보존: " + std::wstring(rawPath.begin(), rawPath.end()));
            skippedCount++;
            continue;
        }

        std::string destPath = rawPath;
        if (destPath.rfind("dist/", 0) == 0 || destPath.rfind("dist\\", 0) == 0) {
            destPath = destPath.substr(5);
        }

        std::wstring wDest(destPath.begin(), destPath.end());
        UI_SetStatus(L"파일 수신 중: " + wDest);
        UI_AddLog(L"[다운로드] " + wDest);

        std::string rawUrl = "https://raw.githubusercontent.com/red-star939/FLOW/" + remoteSha + "/" + rawPath;
        if (download_file(rawUrl, destPath)) {
            updatedCount++;
            if (rawPath.find("flowui/") != std::string::npos || rawPath.find("engine/") != std::string::npos) {
                sourceFilesChanged = true;
            }
        }
    }

    UI_SetProgress(85);

    // Automated local build if Qt compiler exists
    bool hasQt = fs::exists("C:\\Qt\\6.11.1\\mingw_64\\bin\\qmake.exe") || fs::exists("C:\\Qt\\Tools\\mingw1310_64\\bin\\g++.exe");
    if ((sourceFilesChanged || !fs::exists("Flow.exe")) && hasQt && fs::exists("flowui\\CMakeLists.txt")) {
        UI_SetStatus(L"최신 C++/QML 자동 컴파일 진행 중...");
        UI_AddLog(L"[빌드] Qt MinGW 컴파일러 작동 중...");

        std::string buildCmd = "powershell -NoProfile -Command \"$env:PATH='C:\\Qt\\Tools\\mingw1310_64\\bin;C:\\Qt\\6.11.1\\mingw_64\\bin;' + $env:PATH; cd flowui; if (-not (Test-Path build)) { cmake -B build -G 'Ninja' -DCMAKE_C_COMPILER='C:/Qt/Tools/mingw1310_64/bin/gcc.exe' -DCMAKE_CXX_COMPILER='C:/Qt/Tools/mingw1310_64/bin/g++.exe' }; cmake --build build; if ($LASTEXITCODE -eq 0) { Copy-Item -Force build\\appflowui.exe ..\\Flow.exe; Copy-Item -Force build\\appflowui.exe ..\\dist\\Flow.exe }\"";
        if (RunCommandNoWindow(buildCmd)) {
            UI_AddLog(L"[성공] 현장 자동 컴파일 완료!");
        }
    }

    if (!fs::exists("Flow.exe")) {
        UI_SetStatus(L"최신 실행 파일 다운로드 중...");
        std::string exeUrl = "https://raw.githubusercontent.com/red-star939/FLOW/" + remoteSha + "/dist/Flow.exe";
        download_file(exeUrl, "Flow.exe");
    }

    save_local_version("v1.5_stable", 1, 5, remoteSha);

    UI_SetProgress(100);
    UI_SetStatus(L"업데이트 완료!");
    UI_AddLog(L"[완료] 성공적으로 최신 버전으로 업데이트되었습니다.");

    std::this_thread::sleep_for(std::chrono::milliseconds(900));
    UI_Finish();
}

// Window Procedure
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_CREATE: {
        // Create Fonts
        g_hFontTitle = CreateFontW(-24, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, DEFAULT_PITCH, L"Segoe UI");
        g_hFontSub = CreateFontW(-14, 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, DEFAULT_PITCH, L"Malgun Gothic");
        g_hFontNormal = CreateFontW(-13, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, DEFAULT_PITCH, L"Malgun Gothic");
        g_hFontLog = CreateFontW(-12, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, DEFAULT_PITCH, L"Consolas");

        // Status Label Static Control
        g_hStatusText = CreateWindowExW(0, L"STATIC", L"최신 업데이트 확인 중...", WS_CHILD | WS_VISIBLE | SS_LEFT, 24, 60, 470, 22, hWnd, (HMENU)1001, GetModuleHandle(NULL), NULL);
        SendMessageW(g_hStatusText, WM_SETFONT, (WPARAM)g_hFontSub, TRUE);

        // Progress Bar
        g_hProgressBar = CreateWindowExW(0, PROGRESS_CLASSW, NULL, WS_CHILD | WS_VISIBLE | PBS_SMOOTH, 24, 88, 470, 16, hWnd, (HMENU)1002, GetModuleHandle(NULL), NULL);
        SendMessageW(g_hProgressBar, PBM_SETRANGE, 0, MAKELPARAM(0, 100));
        SendMessageW(g_hProgressBar, PBM_SETPOS, 0, 0);

        // Log ListBox Control
        g_hLogList = CreateWindowExW(0, L"LISTBOX", NULL, WS_CHILD | WS_VISIBLE | WS_VSCROLL | LBS_NOINTEGRALHEIGHT | LBS_NOTIFY, 24, 116, 470, 160, hWnd, (HMENU)1003, GetModuleHandle(NULL), NULL);
        SendMessageW(g_hLogList, WM_SETFONT, (WPARAM)g_hFontLog, TRUE);

        break;
    }

    case WM_CTLCOLORSTATIC: {
        HDC hdc = (HDC)wParam;
        HWND hStatic = (HWND)lParam;
        if (hStatic == g_hStatusText) {
            SetTextColor(hdc, RGB(0, 229, 255)); // Cyan Accent Color
            SetBkMode(hdc, TRANSPARENT);
            static HBRUSH hBrushDark = CreateSolidBrush(RGB(20, 20, 20));
            return (LRESULT)hBrushDark;
        }
        break;
    }

    case WM_CTLCOLORLISTBOX: {
        HDC hdc = (HDC)wParam;
        SetTextColor(hdc, RGB(216, 216, 216)); // Light Grey Log Text
        SetBkColor(hdc, RGB(28, 28, 28));     // Dark ListBox Background
        static HBRUSH hBrushList = CreateSolidBrush(RGB(28, 28, 28));
        return (LRESULT)hBrushList;
    }

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);

        // Draw FLOW Header Title
        SetBkMode(hdc, TRANSPARENT);
        SelectObject(hdc, g_hFontTitle);
        SetTextColor(hdc, RGB(255, 255, 255));
        TextOutW(hdc, 24, 20, L"FLOW", 4);

        SelectObject(hdc, g_hFontSub);
        SetTextColor(hdc, RGB(140, 140, 140));
        TextOutW(hdc, 105, 26, L"자동 업데이트 진행 중...", 14);

        EndPaint(hWnd, &ps);
        break;
    }

    case WM_UPDATE_STATUS: {
        wchar_t* statusMsg = (wchar_t*)lParam;
        if (statusMsg) {
            SetWindowTextW(g_hStatusText, statusMsg);
            free(statusMsg);
        }
        break;
    }

    case WM_UPDATE_PROGRESS: {
        int pos = (int)wParam;
        SendMessageW(g_hProgressBar, PBM_SETPOS, (WPARAM)pos, 0);
        break;
    }

    case WM_UPDATE_LOG: {
        wchar_t* logMsg = (wchar_t*)lParam;
        if (logMsg) {
            int idx = (int)SendMessageW(g_hLogList, LB_ADDSTRING, 0, (LPARAM)logMsg);
            SendMessageW(g_hLogList, LB_SETCURSEL, idx, 0);
            free(logMsg);
        }
        break;
    }

    case WM_UPDATE_FINISH: {
        DestroyWindow(hWnd);
        break;
    }

    case WM_DESTROY:
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProcW(hWnd, message, wParam, lParam);
    }
    return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    // 1. Silent Check: Read local version and check remote SHA first
    VersionInfo localVer = load_local_version();

    std::string commitJson = http_get("https://api.github.com/repos/red-star939/FLOW/commits/main");
    if (commitJson.empty()) {
        commitJson = http_get("https://api.github.com/repos/red-star939/FLOW/commits/flow_v1.5");
    }

    if (commitJson.empty()) {
        // Offline or GitHub rate limit reached: silent launch
        return 0;
    }

    std::string remoteSha = "";
    std::smatch mSha;
    if (std::regex_search(commitJson, mSha, std::regex("\"sha\"\\s*:\\s*\"([0-9a-f]{40})\""))) {
        remoteSha = mSha[1].str();
    }

    if (remoteSha.empty()) {
        return 0;
    }

    // ─── SILENT EXIT IF 100% UP-TO-DATE ───
    if (!localVer.sha.empty() && localVer.sha == remoteSha) {
        // No window displayed, exit cleanly in 0.05s!
        return 0;
    }

    // ─── UPDATE DETECTED: SHOW WIN32 GUI WINDOW ───
    INITCOMMONCONTROLSEX icex;
    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC = ICC_PROGRESS_CLASS | ICC_STANDARD_CLASSES;
    InitCommonControlsEx(&icex);

    WNDCLASSEXW wcex = { 0 };
    wcex.cbSize = sizeof(WNDCLASSEXW);
    wcex.style = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc = WndProc;
    wcex.hInstance = hInstance;
    wcex.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wcex.hCursor = LoadCursor(NULL, IDC_ARROW);
    wcex.hbrBackground = CreateSolidBrush(RGB(20, 20, 20)); // #141414 Dark Background
    wcex.lpszClassName = L"FLOW_UpdaterUI";

    RegisterClassExW(&wcex);

    int winW = 520;
    int winH = 320;
    int screenW = GetSystemMetrics(SM_CXSCREEN);
    int screenH = GetSystemMetrics(SM_CYSCREEN);
    int posX = (screenW - winW) / 2;
    int posY = (screenH - winH) / 2;

    g_hWnd = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_APPWINDOW,
        L"FLOW_UpdaterUI",
        L"FLOW - 자동 업데이트",
        WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
        posX, posY, winW, winH,
        NULL, NULL, hInstance, NULL
    );

    if (!g_hWnd) return 0;

    ShowWindow(g_hWnd, SW_SHOW);
    UpdateWindow(g_hWnd);

    // Launch worker thread for downloading/building files
    std::thread worker(PerformUpdateWorker, localVer, remoteSha, commitJson);
    worker.detach();

    // Message Loop
    MSG msg;
    while (GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    return 0;
}
