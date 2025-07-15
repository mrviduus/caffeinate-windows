@echo off
setlocal

echo Building caffeinate executables...

cd /d "%~dp0src"

REM Clean previous builds
if exist bin rmdir /s /q bin
if exist obj rmdir /s /q obj

REM Build console version (optimized, small)
echo Building console version...
dotnet publish -c Release -r win-x64 --self-contained ^
    -p:PublishSingleFile=true ^
    -p:PublishTrimmed=true ^
    -p:TrimMode=link ^
    -p:DebuggerSupport=false ^
    -p:EnableUnsafeBinaryFormatterSerialization=false ^
    -p:InvariantGlobalization=true ^
    -p:OutputType=Exe ^
    -p:UseWindowsForms=false ^
    -p:TargetFramework=net8.0

if errorlevel 1 (
    echo Console build failed!
    pause
    exit /b 1
)

REM Copy console version to root
copy bin\Release\net8.0\win-x64\publish\caffeinate.exe ..\caffeinate.exe

REM Clean for GUI build
rmdir /s /q bin obj

REM Build GUI version (Windows Forms, larger)
echo Building GUI version with Windows Forms...
dotnet publish -c Release -r win-x64 --self-contained ^
    -p:PublishSingleFile=true ^
    -p:OutputType=WinExe ^
    -p:UseWindowsForms=true ^
    -p:TargetFramework=net8.0-windows ^
    -p:EnableWindowsTargeting=true

if errorlevel 1 (
    echo GUI build failed!
    pause
    exit /b 1
)

REM Copy GUI version to root
copy bin\Release\net8.0-windows\win-x64\publish\caffeinate.exe ..\caffeinate-winforms.exe

echo Build complete!
for %%I in (..\caffeinate.exe) do echo Console version: %%~zI bytes
for %%I in (..\caffeinate-winforms.exe) do echo GUI version: %%~zI bytes

pause
