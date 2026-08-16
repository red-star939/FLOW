# Automated Build, Binary Sync & Push Script for FLOW
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " FLOW Automated Build & Release Sync" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Set Qt / MinGW environment PATH
$env:PATH = "C:\Qt\Tools\mingw1310_64\bin;C:\Qt\6.11.1\mingw_64\bin;" + $env:PATH

# 2. Build binaries using CMake / Ninja
Write-Host "[Build] Compiling C++/QML binaries using MinGW 13.1.0..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\flowui"

if (-not (Test-Path "build")) {
    cmake -B build -G "Ninja" -DCMAKE_C_COMPILER="C:/Qt/Tools/mingw1310_64/bin/gcc.exe" -DCMAKE_CXX_COMPILER="C:/Qt/Tools/mingw1310_64/bin/g++.exe"
}

cmake --build build
Set-Location "$PSScriptRoot"

# 3. Synchronize compiled executables into dist/
Write-Host "[Build] Syncing compiled executables to dist/..." -ForegroundColor Yellow
Copy-Item -Force "flowui\build\appflowui.exe" "dist\Flow.exe"
Copy-Item -Force "flowui\build\launcher.exe" "dist\launcher.exe"
Copy-Item -Force "flowui\build\updater.exe" "dist\updater.exe"

# 4. Fetch current commit SHA and update version.json
$currentSha = (git rev-parse HEAD).Trim()
Write-Host "[Build] Injecting Commit SHA: $currentSha" -ForegroundColor Green

$versionJsonContent = @"
{
  "tag": "v1.5_stable",
  "version": "1.5",
  "sha": "$currentSha"
}
"@

$versionJsonContent | Set-Content -Encoding utf8 "version.json"
Copy-Item -Force "version.json" "dist\version.json"

# 5. Git Stage, Commit & Push across branches and tags
Write-Host "[Git] Staging modified files..." -ForegroundColor Yellow
git add .

$hasChanges = (git status --porcelain).Length -gt 0
if ($hasChanges) {
    git commit -m "build: auto-compiled binaries and updated version SHA ($currentSha)"
    $currentSha = (git rev-parse HEAD).Trim()
}

Write-Host "[Git] Pushing to origin/flow_v1.5, v1.5_test, v1.5_stable, and main..." -ForegroundColor Yellow
git push origin flow_v1.5

git tag -f v1.5_test HEAD
git tag -f v1.5_stable HEAD
git push -f origin refs/tags/v1.5_test
git push -f origin refs/tags/v1.5_stable

git branch -f v1.5_test HEAD
git branch -f v1.5_stable HEAD
git push -f origin refs/heads/v1.5_test:refs/heads/v1.5_test
git push -f origin refs/heads/v1.5_stable:refs/heads/v1.5_stable

git checkout main
git reset --hard flow_v1.5
git push -f origin main
git checkout flow_v1.5

Write-Host "==========================================" -ForegroundColor Green
Write-Host " SUCCESS: Build and Git Push Completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
