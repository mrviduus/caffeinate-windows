#!/bin/bash

# Build script for caffeinate.exe

set -e

echo "Building caffeinate.exe..."

cd "$(dirname "$0")/src"

# Clean previous builds
if [ -d "bin" ]; then
    rm -rf bin
fi

if [ -d "obj" ]; then
    rm -rf obj
fi

# Build optimized single-file executable
dotnet publish -c Release -r win-x64 --self-contained \
    -p:PublishSingleFile=true \
    -p:PublishTrimmed=true \
    -p:TrimMode=link \
    -p:DebuggerSupport=false \
    -p:EnableUnsafeBinaryFormatterSerialization=false \
    -p:InvariantGlobalization=true

# Copy to root directory
cp bin/Release/net8.0/win-x64/publish/caffeinate.exe ../

echo "Build complete! caffeinate.exe created."
echo "File size: $(ls -lh ../caffeinate.exe | awk '{print $5}')"
