#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <regex>
#include <filesystem>
#include <cstdlib>
#include <sstream>
#include <windows.h>
#include <wininet.h>

#pragma comment(lib, "wininet.lib")

namespace fs = std::filesystem;

struct VersionInfo {
    std::string tag = "v1.5_stable";
    int major = 1;
    int minor = 5;
    std::string sha = "";
};

// Reads version.json if exists
VersionInfo load_local_version() {
    VersionInfo info;
    if (fs::exists("version.json")) {
        try {
            std::ifstream ifs("version.json");
            std::string content((std::istreambuf_iterator<char>(ifs)), std::istreambuf_iterator<char>());
            ifs.close();

            std::smatch mTag, mBranch, mSha;
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

// Saves version.json
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

// Perform HTTP GET request using WinINet or PowerShell fallback
std::string http_get(const std::string& url) {
    HINTERNET hInternet = InternetOpenA("FLOW-AutoUpdater", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);
    if (!hInternet) return "";
    HINTERNET hConnect = InternetOpenUrlA(hInternet, url.c_str(), "User-Agent: FLOW-AutoUpdater\r\n", -1L, INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_SECURE, 0);
    if (!hConnect) {
        hConnect = InternetOpenUrlA(hInternet, url.c_str(), "User-Agent: FLOW-AutoUpdater\r\n", -1L, INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE, 0);
    }
    if (!hConnect) {
        InternetCloseHandle(hInternet);

        // Fallback: PowerShell Invoke-RestMethod
        std::string psCmd = "powershell -NoProfile -Command \"try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $r = Invoke-RestMethod -Uri '" + url + "' -Headers @{'User-Agent'='FLOW-AutoUpdater'}; $r | ConvertTo-Json -Compress | Out-File -FilePath '_http_tmp.txt' -Encoding utf8 } catch {}\"";
        std::system(psCmd.c_str());
        if (fs::exists("_http_tmp.txt")) {
            std::ifstream ifs("_http_tmp.txt");
            std::string res((std::istreambuf_iterator<char>(ifs)), std::istreambuf_iterator<char>());
            ifs.close();
            fs::remove("_http_tmp.txt");
            return res;
        }
        return "";
    }

    std::string response;
    char buffer[4096];
    DWORD bytesRead = 0;
    while (InternetReadFile(hConnect, buffer, sizeof(buffer) - 1, &bytesRead) && bytesRead > 0) {
        buffer[bytesRead] = '\0';
        response += buffer;
    }
    InternetCloseHandle(hConnect);
    InternetCloseHandle(hInternet);
    return response;
}

// Download raw file directly via PowerShell Invoke-WebRequest
bool download_file(const std::string& url, const std::string& dest_path) {
    fs::path dest(dest_path);
    if (dest.has_parent_path()) {
        fs::create_directories(dest.parent_path());
    }

    std::string psCmd = "powershell -NoProfile -Command \"try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '" + url + "' -OutFile '" + dest_path + "' -Headers @{'User-Agent'='FLOW-AutoUpdater'} } catch { exit 1 }\"";
    int ret = std::system(psCmd.c_str());
    return ret == 0 && fs::exists(dest_path) && fs::file_size(dest_path) > 0;
}

int main(int argc, char* argv[]) {
    std::cout << "==========================================" << std::endl;
    std::cout << " FLOW Differential Auto-Updater & Builder" << std::endl;
    std::cout << "==========================================" << std::endl;

    VersionInfo localVer = load_local_version();
    std::cout << "[Updater] Current Local Tag: " << localVer.tag << " (v" << localVer.major << "." << localVer.minor << ")"
              << (localVer.sha.empty() ? "" : " [SHA: " + localVer.sha.substr(0, 7) + "]") << std::endl;

    // 1. Fetch remote commit info from GitHub (latest commit on main or flow_v1.5)
    std::cout << "[Updater] Checking remote commit SHA from GitHub..." << std::endl;
    std::string commitJson = http_get("https://api.github.com/repos/red-star939/FLOW/commits/main");
    if (commitJson.empty()) {
        commitJson = http_get("https://api.github.com/repos/red-star939/FLOW/commits/flow_v1.5");
    }

    if (commitJson.empty()) {
        std::cout << "[Updater] Warning: Offline or GitHub API rate limit reached." << std::endl;
        std::cout << "[Updater] Launching existing FLOW application..." << std::endl;
        return 0;
    }

    std::string remoteSha = "";
    std::smatch mSha;
    if (std::regex_search(commitJson, mSha, std::regex("\"sha\"\\s*:\\s*\"([0-9a-f]{40})\""))) {
        remoteSha = mSha[1].str();
    }

    if (remoteSha.empty()) {
        std::cout << "[Updater] Warning: Could not parse remote commit SHA." << std::endl;
        return 0;
    }

    std::cout << "[Updater] Remote Commit SHA: " << remoteSha.substr(0, 7) << std::endl;

    // ─── NO UPDATE NEEDED CHECK ───
    if (!localVer.sha.empty() && localVer.sha == remoteSha) {
        std::cout << "[Updater] Application is 100% up-to-date! No build needed." << std::endl;
        std::cout << "==========================================" << std::endl;
        return 0;
    }

    // ─── UPDATE DETECTED: SYNC & BUILD ───
    std::cout << "[Updater] *** UPDATE DETECTED: " << remoteSha.substr(0, 7) << " ***" << std::endl;
    std::cout << "[Updater] Fetching modified file list..." << std::endl;

    // 2. Extract list of changed files from commit JSON
    std::regex fileRegex("\"filename\"\\s*:\\s*\"([^\"]+)\"");
    auto file_begin = std::sregex_iterator(commitJson.begin(), commitJson.end(), fileRegex);
    auto file_end = std::sregex_iterator();

    std::vector<std::string> changedFiles;
    for (std::sregex_iterator i = file_begin; i != file_end; ++i) {
        std::smatch match = *i;
        std::string fname = match[1].str();
        changedFiles.push_back(fname);
    }

    if (changedFiles.empty()) {
        changedFiles = { "dist/Flow.exe", "version.json" };
    }

    size_t updatedCount = 0;
    size_t skippedDataCount = 0;
    bool sourceFilesChanged = false;

    std::cout << "[Updater] Fetching changed raw files directly from GitHub..." << std::endl;
    for (const auto& rawPath : changedFiles) {
        // Data Protection: Do NOT overwrite user database files
        if (rawPath == "db/database.json" || rawPath == "db\\database.json" || rawPath.find(".db") != std::string::npos) {
            std::cout << "[Updater] Data Protection: Preserving user database -> " << rawPath << std::endl;
            skippedDataCount++;
            continue;
        }

        std::string destPath = rawPath;
        if (destPath.rfind("dist/", 0) == 0 || destPath.rfind("dist\\", 0) == 0) {
            destPath = destPath.substr(5);
        }

        std::string rawUrl = "https://raw.githubusercontent.com/red-star939/FLOW/" + remoteSha + "/" + rawPath;
        std::cout << "[Updater] Syncing file: " << destPath << std::endl;

        if (download_file(rawUrl, destPath)) {
            updatedCount++;
            if (rawPath.find("flowui/") != std::string::npos || rawPath.find("engine/") != std::string::npos) {
                sourceFilesChanged = true;
            }
        }
    }

    // 3. Automatic Local Build Execution when updates exist
    std::cout << "[Updater] Updates detected. Executing automated local compilation..." << std::endl;
    bool hasQt = fs::exists("C:\\Qt\\6.11.1\\mingw_64\\bin\\qmake.exe") || fs::exists("C:\\Qt\\Tools\\mingw1310_64\\bin\\g++.exe");
    if (hasQt && fs::exists("flowui\\CMakeLists.txt")) {
        std::cout << "[Updater] Compiling updated C++/QML code with MinGW..." << std::endl;
        std::string buildCmd = "powershell -NoProfile -Command \"$env:PATH='C:\\Qt\\Tools\\mingw1310_64\\bin;C:\\Qt\\6.11.1\\mingw_64\\bin;' + $env:PATH; cd flowui; if (-not (Test-Path build)) { cmake -B build -G 'Ninja' -DCMAKE_C_COMPILER='C:/Qt/Tools/mingw1310_64/bin/gcc.exe' -DCMAKE_CXX_COMPILER='C:/Qt/Tools/mingw1310_64/bin/g++.exe' }; cmake --build build; if ($LASTEXITCODE -eq 0) { Copy-Item -Force build\\appflowui.exe ..\\Flow.exe; Copy-Item -Force build\\appflowui.exe ..\\dist\\Flow.exe }\"";
        int buildRes = std::system(buildCmd.c_str());
        if (buildRes == 0) {
            std::cout << "[Updater] SUCCESS: Automated local compilation completed!" << std::endl;
        } else {
            std::cout << "[Updater] Build notice: Fetching pre-compiled executable..." << std::endl;
            std::string exeUrl = "https://raw.githubusercontent.com/red-star939/FLOW/" + remoteSha + "/dist/Flow.exe";
            download_file(exeUrl, "Flow.exe");
        }
    } else {
        // Fallback if no local Qt toolchain is installed
        std::string exeUrl = "https://raw.githubusercontent.com/red-star939/FLOW/" + remoteSha + "/dist/Flow.exe";
        download_file(exeUrl, "Flow.exe");
    }

    save_local_version("v1.5_stable", 1, 5, remoteSha);

    std::cout << "[Updater] SUCCESS: Update completed & synchronized to SHA: " << remoteSha.substr(0, 7) << std::endl;
    std::cout << "==========================================" << std::endl;

    return 0;
}
