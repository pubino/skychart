#!/bin/bash

# SkyChart Dependencies Build Script
# Builds all required Pascal packages for SkyChart on macOS ARM64
# Author: Generated for ARM64 macOS build system
# Date: September 19, 2025

set -e

# Color output functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAZARUS_DIR="$HOME/Downloads/lazarus"
FPC_PATH="/Users/bino/homebrew/bin/fpc"
TARGET_CPU="aarch64"
WIDGET_SET="qt5"

# Verify prerequisites
log_info "Checking prerequisites for dependency build..."

if [ ! -d "$LAZARUS_DIR" ]; then
    log_error "Lazarus directory not found at $LAZARUS_DIR"
    log_info "Please run the main build script first or clone Lazarus manually"
    exit 1
fi

if [ ! -f "$FPC_PATH" ]; then
    log_error "Free Pascal Compiler not found at $FPC_PATH"
    log_info "Please install with: brew install fpc"
    exit 1
fi

if [ ! -f "$LAZARUS_DIR/lazbuild" ]; then
    log_error "Lazarus lazbuild not found. Lazarus may not be built yet."
    log_info "Please run the main build script first to build Lazarus"
    exit 1
fi

# Build parameters
BUILD_ARGS="--lazarusdir=$LAZARUS_DIR --compiler=$FPC_PATH --cpu=$TARGET_CPU --ws=$WIDGET_SET"

log_info "Build configuration:"
log_info "  Lazarus: $LAZARUS_DIR"
log_info "  FPC: $FPC_PATH"
log_info "  Target: $TARGET_CPU"
log_info "  Widget Set: $WIDGET_SET"

# Package list - order matters for dependencies
packages=(
    "component/bgrabitmap/bgrabitmappack.lpk"
    "component/synapse/laz_synapse.lpk"
    "component/indiclient/indiclient.lpk"
    "component/xmlparser/xmlparser.lpk"
    "component/enhedits/enhedit.lpk"
    "component/uniqueinstance/uniqueinstance_package.lpk"
    "component/vo/lazvo.lpk"
)

# Change to skychart directory
cd "$SCRIPT_DIR/skychart"

log_info "Building ${#packages[@]} dependency packages..."
echo ""

# Build each package
built_count=0
failed_count=0

for package in "${packages[@]}"; do
    if [ -f "$package" ]; then
        log_info "Building package: $(basename "$package")"
        
        if "$LAZARUS_DIR/lazbuild" $BUILD_ARGS "$package"; then
            log_success "✓ $(basename "$package") built successfully"
            ((built_count++))
        else
            log_error "✗ $(basename "$package") build failed"
            ((failed_count++))
        fi
        echo ""
    else
        log_warning "Package not found: $package"
        ((failed_count++))
    fi
done

# Summary
echo "=== Build Summary ==="
log_info "Packages built successfully: $built_count"
if [ $failed_count -gt 0 ]; then
    log_warning "Packages failed: $failed_count"
else
    log_success "All packages built successfully!"
fi

# Verify some key packages were built
log_info "Verifying key package installations..."

# Check for compiled units in common locations
units_dirs=(
    "component/bgrabitmap/lib"
    "component/synapse/lib"
    "component/indiclient/lib"
)

verified=0
for dir in "${units_dirs[@]}"; do
    if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
        log_success "✓ $(basename "$(dirname "$dir")") units found"
        ((verified++))
    fi
done

if [ $verified -gt 0 ]; then
    log_success "Dependency verification passed ($verified/$((${#units_dirs[@]})) key packages verified)"
else
    log_warning "Could not verify compiled units. Check build output above."
fi

if [ $failed_count -eq 0 ]; then
    log_success "🎉 All dependencies ready for SkyChart build!"
    log_info "Next step: Run './build_macos_arm64.sh' to build the main application"
    exit 0
else
    log_error "Some dependencies failed to build. Check the errors above."
    exit 1
fi