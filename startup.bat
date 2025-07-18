@echo off
REM ========================================
REM Caffeine Startup Helper
REM ========================================
REM This batch file launches Caffeine minimized at startup.
REM 
REM Usage:
REM 1. Edit the CAFFEINE_PATH below to point to your caffeine.exe
REM 2. Copy this file to your startup folder:
REM    - Press Win+R, type "shell:startup", press Enter
REM    - Copy startup.bat to that folder
REM 3. Caffeine will now start minimized at login
REM ========================================

REM Edit this path to point to your caffeine.exe location
set CAFFEINE_PATH=%~dp0build\win\caffeine.exe

REM Check if caffeine.exe exists
if not exist "%CAFFEINE_PATH%" (
    echo Error: Caffeine executable not found at: %CAFFEINE_PATH%
    echo Please edit this batch file and set the correct path to caffeine.exe
    pause
    exit /b 1
)

REM Launch Caffeine minimized
start /min "" "%CAFFEINE_PATH%"

REM Optional: Show a brief notification (remove REM to enable)
REM echo Caffeine started in background - your PC will stay awake
REM timeout /t 2 /nobreak >nul
