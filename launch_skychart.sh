#!/bin/bash

# Launch script for SkyChart with Qt5 framework support on macOS ARM64

# Set the framework path to find Qt5Pas framework
export DYLD_FRAMEWORK_PATH="/Users/bino/homebrew/Cellar/qt@5/5.15.17/lib:$DYLD_FRAMEWORK_PATH"

# Set library search path to find libcdcwcs.dylib
export DYLD_LIBRARY_PATH="/Users/bino/homebrew/lib:/Users/bino/Downloads/skychart/skychart/units/aarch64-darwin-qt5:$DYLD_LIBRARY_PATH"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Path to the SkyChart executable
SKYCHART_EXEC="$SCRIPT_DIR/skychart/units/aarch64-darwin-qt5/skychart"
SKYCHART_DIR="$SCRIPT_DIR/skychart/units/aarch64-darwin-qt5"

# Remove quarantine attributes if present (macOS security feature)
if [ -f "$SKYCHART_EXEC" ]; then
    xattr -d com.apple.provenance "$SKYCHART_EXEC" 2>/dev/null || true
    xattr -d com.apple.quarantine "$SKYCHART_EXEC" 2>/dev/null || true
fi

# Ensure WCS library is available
WCS_LIB="$SCRIPT_DIR/skychart/library/wcs/libcdcwcs.dylib"
HOMEBREW_LIB="/Users/bino/homebrew/lib/libcdcwcs.dylib"
if [ -f "$WCS_LIB" ]; then
    # Install to both executable directory and homebrew lib directory
    if [ ! -f "$SKYCHART_DIR/libcdcwcs.dylib" ]; then
        cp "$WCS_LIB" "$SKYCHART_DIR/"
    fi
    if [ ! -f "$HOMEBREW_LIB" ]; then
        cp "$WCS_LIB" "/Users/bino/homebrew/lib/"
    fi
fi

# Ensure data directory structure exists
DATA_DIR="$SCRIPT_DIR/skychart/units/share/skychart"
if [ ! -d "$DATA_DIR" ]; then
    mkdir -p "$DATA_DIR"
    ln -sf "$SCRIPT_DIR/tools/data" "$DATA_DIR/data"
fi

# Also create symlinks in common search locations
ln -sf "$SCRIPT_DIR/tools/data" "$SCRIPT_DIR/data" 2>/dev/null || true
ln -sf "$SCRIPT_DIR/tools/data" "$SCRIPT_DIR/skychart/units/aarch64-darwin-qt5/data" 2>/dev/null || true

# Change to the skychart directory and launch the application with explicit data directory
cd "$SCRIPT_DIR/skychart/units/aarch64-darwin-qt5"
exec ./skychart --datadir="$SCRIPT_DIR/tools" "$@"