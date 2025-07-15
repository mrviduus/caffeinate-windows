@echo off
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   Caffeinate for Windows - Installer
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as administrator - will install system-wide
    set "INSTALL_PATH=%ProgramFiles%\Caffeinate"
    set "SYSTEM_INSTALL=true"
) else (
    echo Running as user - will install for current user only
    set "INSTALL_PATH=%USERPROFILE%\AppData\Local\Caffeinate"
    set "SYSTEM_INSTALL=false"
)

echo Install location: !INSTALL_PATH!
echo.

REM Create installation directory
echo Creating installation directory...
if not exist "!INSTALL_PATH!" (
    mkdir "!INSTALL_PATH!" 2>nul
    if !errorlevel! neq 0 (
        echo ERROR: Failed to create directory !INSTALL_PATH!
        echo Try running as administrator for system-wide installation.
        pause
        exit /b 1
    )
)

REM Copy the PowerShell script
echo Copying caffeinate.ps1...
if exist "caffeinate.ps1" (
    copy "caffeinate.ps1" "!INSTALL_PATH!\caffeinate.ps1" >nul
    if !errorlevel! neq 0 (
        echo ERROR: Failed to copy caffeinate.ps1
        pause
        exit /b 1
    )
) else (
    echo ERROR: caffeinate.ps1 not found in current directory
    echo Please run this installer from the same folder as caffeinate.ps1
    pause
    exit /b 1
)

REM Create batch wrapper
echo Creating command wrapper...
(
echo @echo off
echo REM Caffeinate for Windows - Command Wrapper
echo REM This allows 'caffeinate' to be called from anywhere
echo.
echo REM Check if PowerShell is available
echo where pwsh ^>nul 2^>^&1
echo if %%errorlevel%% == 0 ^(
echo     REM Use PowerShell 7+ if available
echo     pwsh -ExecutionPolicy Bypass -File "!INSTALL_PATH!\caffeinate.ps1" %%*
echo ^) else ^(
echo     REM Fall back to Windows PowerShell
echo     powershell -ExecutionPolicy Bypass -File "!INSTALL_PATH!\caffeinate.ps1" %%*
echo ^)
) > "!INSTALL_PATH!\caffeinate.bat"

REM Add to PATH
echo Adding to PATH...
if "!SYSTEM_INSTALL!" == "true" (
    REM System-wide PATH modification
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "CURRENT_PATH=%%b"
    echo !CURRENT_PATH! | find /i "!INSTALL_PATH!" >nul
    if !errorlevel! neq 0 (
        echo Adding to system PATH...
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!CURRENT_PATH!;!INSTALL_PATH!" /f >nul
        if !errorlevel! neq 0 (
            echo WARNING: Failed to add to system PATH. You may need to add manually.
        ) else (
            echo Successfully added to system PATH
        )
    ) else (
        echo Already in system PATH
    )
) else (
    REM User PATH modification
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "CURRENT_PATH=%%b"
    if "!CURRENT_PATH!" == "" set "CURRENT_PATH=%PATH%"
    echo !CURRENT_PATH! | find /i "!INSTALL_PATH!" >nul
    if !errorlevel! neq 0 (
        echo Adding to user PATH...
        reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "!CURRENT_PATH!;!INSTALL_PATH!" /f >nul
        if !errorlevel! neq 0 (
            echo WARNING: Failed to add to user PATH. You may need to add manually.
        ) else (
            echo Successfully added to user PATH
        )
    ) else (
        echo Already in user PATH
    )
)

REM Set PowerShell execution policy for current user
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force" 2>nul
if !errorlevel! neq 0 (
    echo WARNING: Could not set PowerShell execution policy automatically.
    echo You may need to run: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
)

echo.
echo ========================================
echo   Installation Complete!
echo ========================================
echo.
echo Caffeinate has been installed to: !INSTALL_PATH!
echo.
echo To use caffeinate from anywhere, open a NEW command prompt and type:
echo   caffeinate -d -t 3600    (keep display awake for 1 hour)
echo   caffeinate -i -- cmd     (keep system awake while running a command)
echo   caffeinate -h            (show help)
echo.
echo Note: You need to open a NEW command prompt for the PATH changes to take effect.
echo.
pause
