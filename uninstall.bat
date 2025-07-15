@echo off
setlocal enabledelayedexpansion

echo.
echo ==========================================
echo   Caffeinate for Windows - Uninstaller
echo ==========================================
echo.

REM Check both system and user installation locations
set "SYSTEM_PATH=%ProgramFiles%\Caffeinate"
set "USER_PATH=%USERPROFILE%\AppData\Local\Caffeinate"
set "FOUND_INSTALL=false"

if exist "!SYSTEM_PATH!\caffeinate.ps1" (
    echo Found system installation at: !SYSTEM_PATH!
    set "INSTALL_PATH=!SYSTEM_PATH!"
    set "SYSTEM_INSTALL=true"
    set "FOUND_INSTALL=true"
) else if exist "!USER_PATH!\caffeinate.ps1" (
    echo Found user installation at: !USER_PATH!
    set "INSTALL_PATH=!USER_PATH!"
    set "SYSTEM_INSTALL=false"
    set "FOUND_INSTALL=true"
)

if "!FOUND_INSTALL!" == "false" (
    echo No caffeinate installation found.
    echo Checked:
    echo   - !SYSTEM_PATH!
    echo   - !USER_PATH!
    echo.
    pause
    exit /b 1
)

echo.
echo This will remove caffeinate from your system.
set /p "CONFIRM=Are you sure? (y/N): "
if /i not "!CONFIRM!" == "y" (
    echo Uninstallation cancelled.
    pause
    exit /b 0
)

echo.
echo Removing installation files...
if exist "!INSTALL_PATH!" (
    rmdir /s /q "!INSTALL_PATH!" 2>nul
    if !errorlevel! neq 0 (
        echo ERROR: Failed to remove !INSTALL_PATH!
        echo You may need to remove it manually.
    ) else (
        echo Successfully removed installation directory
    )
)

echo Removing from PATH...
if "!SYSTEM_INSTALL!" == "true" (
    REM Remove from system PATH
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "CURRENT_PATH=%%b"
    set "NEW_PATH=!CURRENT_PATH!"
    set "NEW_PATH=!NEW_PATH:;%INSTALL_PATH%=!"
    set "NEW_PATH=!NEW_PATH:%INSTALL_PATH%;=!"
    set "NEW_PATH=!NEW_PATH:%INSTALL_PATH%=!"
    
    if not "!NEW_PATH!" == "!CURRENT_PATH!" (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
        if !errorlevel! neq 0 (
            echo WARNING: Failed to remove from system PATH
        ) else (
            echo Successfully removed from system PATH
        )
    )
) else (
    REM Remove from user PATH
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "CURRENT_PATH=%%b"
    if not "!CURRENT_PATH!" == "" (
        set "NEW_PATH=!CURRENT_PATH!"
        set "NEW_PATH=!NEW_PATH:;%INSTALL_PATH%=!"
        set "NEW_PATH=!NEW_PATH:%INSTALL_PATH%;=!"
        set "NEW_PATH=!NEW_PATH:%INSTALL_PATH%=!"
        
        if not "!NEW_PATH!" == "!CURRENT_PATH!" (
            reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
            if !errorlevel! neq 0 (
                echo WARNING: Failed to remove from user PATH
            ) else (
                echo Successfully removed from user PATH
            )
        )
    )
)

echo.
echo ==========================================
echo   Uninstallation Complete!
echo ==========================================
echo.
echo Caffeinate has been removed from your system.
echo Note: You may need to restart your command prompt for PATH changes to take effect.
echo.
pause
