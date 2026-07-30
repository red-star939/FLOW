@echo off
title Flow Application Launcher
cd /d "%~dp0"
if exist "%~dp0dist\Flow.exe" (
    start "" "%~dp0dist\Flow.exe"
) else (
    set PATH=C:\Qt\6.11.1\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;%PATH%
    start "" "%~dp0flowui\build\appflowui.exe"
)
