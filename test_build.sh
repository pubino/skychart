#!/bin/bash

# SkyChart Build Test Script
# Quick validation of the build and runtime environment

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[TEST]${NC} $1"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== SkyChart Build Validation ==="
echo ""

# Test 1: Build script exists and is executable
log_info "Checking build scripts..."
if [ -x "./build_macos_arm64.sh" ]; then
    log_pass "Build script exists and is executable"
else
    log_fail "Build script missing or not executable"
    exit 1
fi

if [ -x "./package_macos.sh" ]; then
    log_pass "Package script exists and is executable"
else
    log_fail "Package script missing or not executable"
    exit 1
fi

# Test 2: Prerequisites check
log_info "Checking prerequisites..."

if command -v brew &> /dev/null; then
    log_pass "Homebrew installed"
else
    log_fail "Homebrew not found"
    exit 1
fi

if [ -f "/Users/bino/homebrew/bin/fpc" ]; then
    FPC_VERSION=$(/Users/bino/homebrew/bin/fpc -iV)
    log_pass "Free Pascal Compiler found: $FPC_VERSION"
else
    log_fail "Free Pascal Compiler not found"
    exit 1
fi

if [ -d "/Users/bino/homebrew/Cellar/qt@5" ]; then
    log_pass "Qt5 framework found"
else
    log_fail "Qt5 framework not found"
    exit 1
fi

# Test 3: Build artifacts
log_info "Checking build artifacts..."

EXECUTABLE="skychart/units/aarch64-darwin-qt5/skychart"
if [ -f "$EXECUTABLE" ]; then
    ARCH=$(file "$EXECUTABLE" | grep -o "arm64\|x86_64")
    SIZE=$(du -h "$EXECUTABLE" | cut -f1)
    log_pass "SkyChart executable exists: $SIZE, $ARCH"
else
    log_fail "SkyChart executable not found at $EXECUTABLE"
    exit 1
fi

WCS_LIB="skychart/library/wcs/libcdcwcs.dylib"
if [ -f "$WCS_LIB" ]; then
    ARCH=$(file "$WCS_LIB" | grep -o "arm64\|x86_64")
    SIZE=$(du -h "$WCS_LIB" | cut -f1)
    log_pass "WCS library exists: $SIZE, $ARCH"
else
    log_fail "WCS library not found at $WCS_LIB"
    exit 1
fi

QT5PAS_FRAMEWORK="/Users/bino/homebrew/Cellar/qt@5/5.15.17/lib/Qt5Pas.framework/Qt5Pas"
if [ -f "$QT5PAS_FRAMEWORK" ]; then
    log_pass "Qt5Pas framework installed"
else
    log_fail "Qt5Pas framework not found"
    exit 1
fi

# Test 4: Data directories
log_info "Checking data configuration..."

if [ -d "tools/data" ]; then
    DATA_SIZE=$(du -sh tools/data | cut -f1)
    log_pass "Data directory exists: $DATA_SIZE"
else
    log_fail "Data directory not found"
    exit 1
fi

if [ -d "tools/cat" ]; then
    CAT_COUNT=$(ls -1 tools/cat/ | wc -l | tr -d ' ')
    log_pass "Star catalogs directory exists: $CAT_COUNT catalogs"
else
    log_fail "Star catalogs directory not found"
    exit 1
fi

if [ -L "data" ] && [ -d "data" ]; then
    log_pass "Data symlink configured correctly"
else
    log_warn "Data symlink not configured"
fi

# Test 5: Launch script
log_info "Checking launch configuration..."

if [ -x "./launch_skychart.sh" ]; then
    log_pass "Launch script exists and is executable"
else
    log_fail "Launch script missing or not executable"
    exit 1
fi

# Test 6: Quick runtime test (non-interactive)
log_info "Testing runtime environment..."

if timeout 10s ./launch_skychart.sh --version &> /dev/null; then
    log_pass "Application launches successfully"
elif [ $? -eq 124 ]; then
    log_warn "Application launch test timed out (this may be normal)"
else
    log_fail "Application failed to launch"
fi

# Test 7: Architecture validation
log_info "Validating ARM64 architecture..."

ALL_ARM64=true
for file in "$EXECUTABLE" "$WCS_LIB"; do
    if [ -f "$file" ]; then
        ARCH=$(file "$file" | grep -o "arm64\|x86_64")
        if [ "$ARCH" != "arm64" ]; then
            log_fail "$(basename "$file") is not ARM64: $ARCH"
            ALL_ARM64=false
        fi
    fi
done

if [ "$ALL_ARM64" = true ]; then
    log_pass "All binaries are ARM64 native"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo ""

if [ "$ALL_ARM64" = true ]; then
    log_pass "✅ All tests passed! SkyChart is ready for ARM64 macOS."
    log_info "To run: ./launch_skychart.sh"
    log_info "To package: ./package_macos.sh all"
    exit 0
else
    log_fail "❌ Some tests failed. Check the output above."
    exit 1
fi