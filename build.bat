@echo off
setlocal

echo Building caffeinate.exe...

cd /d "%~dp0src"

REM Clean previous builds
if exist bin rmdir /s /q bin
if exist obj rmdir /s /q obj

REM Build optimized single-file executable
dotnet publish -c Release -r win-x64 --self-contained ^
    -p:PublishSingleFile=true ^
    -p:PublishTrimmed=true ^
    -p:TrimMode=link ^
    -p:DebuggerSupport=false ^
    -p:EnableUnsafeBinaryFormatterSerialization=false ^
    -p:InvariantGlobalization=true

if errorlevel 1 (
    echo Build failed!
    pause
    exit /b 1
)

REM Copy to root directory
copy bin\Release\net8.0\win-x64\publish\caffeinate.exe ..\

echo Build complete! caffeinate.exe created.
for %%I in (..\caffeinate.exe) do echo File size: %%~zI bytes

pause
