#!/bin/bash

# Build script for caffeinate executables

set -e

echo "Building caffeinate executables..."

cd "$(dirname "$0")/src"

# Clean previous builds
if [ -d "bin" ]; then
    rm -rf bin
fi

if [ -d "obj" ]; then
    rm -rf obj
fi

# Build console version (optimized, small)
echo "Building console version..."
dotnet publish -c Release -r win-x64 --self-contained \
    -p:PublishSingleFile=true \
    -p:PublishTrimmed=true \
    -p:TrimMode=link \
    -p:DebuggerSupport=false \
    -p:EnableUnsafeBinaryFormatterSerialization=false \
    -p:InvariantGlobalization=true \
    -p:OutputType=Exe \
    -p:UseWindowsForms=false \
    -p:TargetFramework=net8.0

# Copy console version to root
cp bin/Release/net8.0/win-x64/publish/caffeinate.exe ../caffeinate.exe

# Clean for GUI build
rm -rf bin obj

# Build GUI version (Windows Forms, larger)
echo "Building GUI version with Windows Forms..."
dotnet publish -c Release -r win-x64 --self-contained \
    -p:PublishSingleFile=true \
    -p:OutputType=WinExe \
    -p:UseWindowsForms=true \
    -p:TargetFramework=net8.0-windows \
    -p:EnableWindowsTargeting=true

# Copy GUI version to root
cp bin/Release/net8.0-windows/win-x64/publish/caffeinate.exe ../caffeinate-winforms.exe

echo "Build complete!"
echo "Console version: $(ls -lh ../caffeinate.exe | awk '{print $5}')"
echo "GUI version: $(ls -lh ../caffeinate-winforms.exe | awk '{print $5}')"
