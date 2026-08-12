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
    std::string tag = "v1.4_stable";
    int major = 1;
    int minor = 4;
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
            } else if (std::regex_search(content, mBranch, std::regex("\"branch\"\\s*:\\s*\"([^\"]+)\""))) {
                std::string b = mBranch[1].str();
                // Map legacy branch name e.g. flow_v1.4 -> v1.4_stable
                std::smatch mB;
                if (std::regex_search(b, mB, std::regex("flow_v(\\d+)\\.(\\d+)"))) {
                    info.tag = "v" + mB[1].str() + "." + mB[2].str() + "_stable";
                }
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

// Download binary file
bool download_file(const std::string& url, const std::string& dest_path) {
    std::string psCmd = "powershell -NoProfile -Command \"try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '" + url + "' -OutFile '" + dest_path + "' -Headers @{'User-Agent'='FLOW-AutoUpdater'} } catch { exit 1 }\"";
    int ret = std::system(psCmd.c_str());
    return ret == 0 && fs::exists(dest_path) && fs::file_size(dest_path) > 0;
}

int main(int argc, char* argv[]) {
    std::cout << "==========================================" << std::endl;
    std::cout << " FLOW Auto-Updater (Stable Tag Sync)" << std::endl;
    std::cout << "==========================================" << std::endl;

    VersionInfo localVer = load_local_version();
    std::cout << "[Updater] Current Local Tag: " << localVer.tag << " (v" << localVer.major << "." << localVer.minor << ")"
              << (localVer.sha.empty() ? "" : " [SHA: " + localVer.sha.substr(0, 7) + "]") << std::endl;

    std::cout << "[Updater] Checking GitHub stable tags for updates..." << std::endl;
    std::string tagsJson = http_get("https://api.github.com/repos/red-star939/FLOW/tags");

    if (tagsJson.empty()) {
        std::cout << "[Updater] Warning: Could not fetch tag info from GitHub (Offline or API limit)." << std::endl;
        std::cout << "[Updater] Continuing with current installation." << std::endl;
        return 0;
    }

    // Regex to match tag objects with name "vX.Y_stable" and their commit SHA
    std::regex tagBlockRegex("\"name\"\\s*:\\s*\"(v(\\d+)\\.(\\d+)_stable)\"[^}]*?\"commit\"\\s*:\\s*\\{[^}]*?\"sha\"\\s*:\\s*\"([^\"]+)\"");
    auto words_begin = std::sregex_iterator(tagsJson.begin(), tagsJson.end(), tagBlockRegex);
    auto words_end = std::sregex_iterator();

    std::string targetTag = localVer.tag;
    int maxMajor = localVer.major;
    int maxMinor = localVer.minor;
    std::string targetSha = localVer.sha;
    bool foundNewVersion = false;
    bool shaUpdated = false;

    for (std::sregex_iterator i = words_begin; i != words_end; ++i) {
        std::smatch match = *i;
        std::string tagName = match[1].str();
        int maj = std::stoi(match[2].str());
        int min = std::stoi(match[3].str());
        std::string sha = match[4].str();

        std::cout << "[Updater] Found Remote Stable Tag: " << tagName << " [SHA: " << sha.substr(0, 7) << "]" << std::endl;

        if (maj > maxMajor || (maj == maxMajor && min > maxMinor)) {
            maxMajor = maj;
            maxMinor = min;
            targetTag = tagName;
            targetSha = sha;
            foundNewVersion = true;
        } else if (maj == localVer.major && min == localVer.minor) {
            // Same version, check if commit SHA changed (recent upload on stable tag)
            if (!sha.empty() && sha != localVer.sha) {
                targetTag = tagName;
                targetSha = sha;
                shaUpdated = true;
            }
        }
    }

    if (!foundNewVersion && !shaUpdated) {
        std::cout << "[Updater] Application is up to date! (Latest Stable Tag: " << localVer.tag << ")" << std::endl;
        return 0;
    }

    if (foundNewVersion) {
        std::cout << "[Updater] *** NEW STABLE VERSION FOUND: " << targetTag << " ***" << std::endl;
    } else if (shaUpdated) {
        std::cout << "[Updater] *** STABLE TAG RECENT UPDATE DETECTED: " << targetTag << " [New SHA: " << targetSha.substr(0, 7) << "] ***" << std::endl;
    }

    std::cout << "[Updater] Downloading update package for " << targetTag << "..." << std::endl;

    std::string zipUrl = "https://raw.githubusercontent.com/red-star939/FLOW/" + targetTag + "/Flow_Release.zip";
    std::string zipFile = "_update.zip";

    if (!download_file(zipUrl, zipFile)) {
        // Fallback to github.com/raw
        zipUrl = "https://github.com/red-star939/FLOW/raw/" + targetTag + "/Flow_Release.zip";
        if (!download_file(zipUrl, zipFile)) {
            std::cerr << "[Updater] Error: Failed to download update zip from " << zipUrl << std::endl;
            return 1;
        }
    }

    std::cout << "[Updater] Extracting update package..." << std::endl;
    std::string tempDir = "_update_temp";
    if (fs::exists(tempDir)) fs::remove_all(tempDir);

    std::string unzipCmd = "powershell -NoProfile -Command \"Expand-Archive -Path '" + zipFile + "' -DestinationPath '" + tempDir + "' -Force\"";
    if (std::system(unzipCmd.c_str()) != 0) {
        std::cerr << "[Updater] Error: Failed to extract update package." << std::endl;
        fs::remove(zipFile);
        return 1;
    }

    std::cout << "[Updater] Applying updates while preserving user database..." << std::endl;

    size_t updatedFiles = 0;
    size_t preservedFiles = 0;

    try {
        for (const auto& entry : fs::recursive_directory_iterator(tempDir)) {
            fs::path rel = fs::relative(entry.path(), tempDir);
            fs::path dest = fs::current_path() / rel;

            if (entry.is_directory()) {
                fs::create_directories(dest);
            } else {
                std::string relStr = rel.generic_string();

                // ─── CRITICAL DATA PROTECTION GUARANTEE ───
                // Do NOT overwrite db/database.json or any .db user data files if they already exist in destination!
                if ((relStr == "db/database.json" || relStr == "db\\database.json" || relStr.find(".db") != std::string::npos) && fs::exists(dest)) {
                    std::cout << "[Updater] Data Protection: Preserving user database -> " << relStr << std::endl;
                    preservedFiles++;
                    continue;
                }

                // Skip updater's own temporary files
                if (relStr == "_update.zip" || relStr.rfind("_update", 0) == 0) continue;

                std::error_code ec;
                fs::copy_file(entry.path(), dest, fs::copy_options::overwrite_existing, ec);
                if (!ec) {
                    updatedFiles++;
                }
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "[Updater] Error copying files: " << e.what() << std::endl;
    }

    save_local_version(targetTag, maxMajor, maxMinor, targetSha);

    // Clean up temporary files
    try {
        fs::remove(zipFile);
        fs::remove_all(tempDir);
    } catch (...) {}

    std::cout << "[Updater] SUCCESS: Successfully updated to " << targetTag << " [SHA: " << targetSha.substr(0, 7) << "]" << std::endl;
    std::cout << "[Updater] Total files updated: " << updatedFiles << ", Preserved user DB files: " << preservedFiles << std::endl;
    std::cout << "==========================================" << std::endl;

    return 0;
}
