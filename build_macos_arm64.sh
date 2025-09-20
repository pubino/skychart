#!/bin/bash

# SkyChart macOS ARM64 Build Script
# This script reproduces the complete build process for SkyChart on macOS ARM64
# Author: Generated for native ARM64 macOS build
# Date: September 19, 2025

set -e  # Exit on any error

# Color output functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR"
LAZARUS_DIR="$HOME/Downloads/lazarus"
FPC_PATH="/Users/bino/homebrew/bin/fpc"
QT5_PATH="/Users/bino/homebrew/Cellar/qt@5/5.15.17"
TARGET_CPU="aarch64"
TARGET_OS="darwin"
WIDGET_SET="qt5"

# Verify prerequisites
log_info "Checking prerequisites..."

# Check Homebrew
if ! command -v brew &> /dev/null; then
    log_error "Homebrew not found. Please install Homebrew first."
    exit 1
fi

# Check FPC
if [ ! -f "$FPC_PATH" ]; then
    log_error "Free Pascal Compiler not found at $FPC_PATH"
    log_info "Please install with: brew install fpc"
    exit 1
fi

# Check Qt5
if [ ! -d "$QT5_PATH" ]; then
    log_error "Qt5 not found at $QT5_PATH"
    log_info "Please install with: brew install qt@5"
    exit 1
fi

log_success "Prerequisites verified"

# Step 1: Setup Lazarus IDE
setup_lazarus() {
    log_info "Setting up Lazarus IDE..."
    
    if [ ! -d "$LAZARUS_DIR" ]; then
        log_info "Cloning Lazarus from GitLab..."
        cd "$(dirname "$LAZARUS_DIR")"
        git clone https://gitlab.com/freepascal.org/lazarus/lazarus.git
    fi
    
    cd "$LAZARUS_DIR"
    log_info "Building Lazarus with Qt5 support..."
    make clean LCL_PLATFORM=qt5
    make lazbuild LCL_PLATFORM=qt5
    
    log_success "Lazarus setup complete"
}

# Step 2: Build Qt5Pas framework
build_qt5pas() {
    log_info "Building Qt5Pas framework..."
    
    local qt5pas_dir="$LAZARUS_DIR/lcl/interfaces/qt5/cbindings"
    cd "$qt5pas_dir"
    
    # Clean previous builds
    make clean
    
    # Build Qt5Pas framework
    make
    
    # Install to Qt5 lib directory
    local qt5_lib_dir="$QT5_PATH/lib"
    if [ -f "Qt5Pas.framework/Qt5Pas" ]; then
        log_info "Installing Qt5Pas framework to $qt5_lib_dir"
        cp -R Qt5Pas.framework "$qt5_lib_dir/"
        log_success "Qt5Pas framework installed"
    else
        log_error "Qt5Pas framework build failed"
        exit 1
    fi
}

# Step 3: Build dependency packages
build_dependencies() {
    log_info "Building SkyChart dependencies..."
    
    cd "$BUILD_DIR/skychart"
    
    local packages=(
        "component/bgrabitmap/bgrabitmap/bgrabitmappack.lpk"
        "component/synapse/laz_synapse.lpk" 
        "component/indiclient/indiclient.lpk"
        "component/xmlparser/xmlparser.lpk"
        "component/vo/vosamp.lpk"
        "component/enhedits/enhedit.lpk"
        "component/uniqueinstance/uniqueinstance_package.lpk"
        "component/vo/lazvo.lpk"
    )
    
    for package in "${packages[@]}"; do
        if [ -f "$package" ]; then
            log_info "Building package: $(basename "$package")"
            "$LAZARUS_DIR/lazbuild" \
                --lazarusdir="$LAZARUS_DIR" \
                --compiler="$FPC_PATH" \
                --cpu="$TARGET_CPU" \
                --ws="$WIDGET_SET" \
                "$package"
        else
            log_warning "Package not found: $package"
        fi
    done
    
    log_success "Dependencies built"
}

# Step 4: Build WCS library
build_wcs_library() {
    log_info "Building WCS library..."
    
    local wcs_dir="$BUILD_DIR/skychart/library/wcs"
    cd "$wcs_dir"
    
    # Clean previous build
    make clean
    
    # Build for ARM64
    make
    
    if [ -f "libcdcwcs.dylib" ]; then
        log_success "WCS library built successfully"
        
        # Verify architecture
        local arch=$(file libcdcwcs.dylib | grep -o "arm64\|x86_64")
        if [ "$arch" = "arm64" ]; then
            log_success "WCS library is ARM64 native"
        else
            log_warning "WCS library architecture: $arch"
        fi
    else
        log_error "WCS library build failed"
        exit 1
    fi
}

# Step 5: Build main SkyChart application
build_skychart() {
    log_info "Building main SkyChart application..."
    
    cd "$BUILD_DIR/skychart"
    
    # Build the main application
    "$LAZARUS_DIR/lazbuild" \
        --lazarusdir="$LAZARUS_DIR" \
        --compiler="$FPC_PATH" \
        --cpu="$TARGET_CPU" \
        --ws="$WIDGET_SET" \
        --skip-dependencies \
        skychart.lpi
    
    local executable="units/${TARGET_CPU}-${TARGET_OS}-${WIDGET_SET}/skychart"
    
    if [ -f "$executable" ]; then
        log_success "SkyChart executable built: $executable"
        
        # Show file info
        local size=$(du -h "$executable" | cut -f1)
        log_info "Executable size: $size"
        
        # Verify architecture
        local arch=$(file "$executable" | grep -o "arm64\|x86_64")
        log_info "Architecture: $arch"
    else
        log_error "SkyChart build failed"
        exit 1
    fi
}

# Step 6: Setup data directories
setup_data_directories() {
    log_info "Setting up data directories..."
    
    cd "$BUILD_DIR"
    
    # Create symlink to data directory
    if [ ! -L "data" ]; then
        ln -sf tools/data data
        log_success "Data directory symlink created"
    fi
    
    # Create share directory structure
    local share_dir="skychart/units/share/skychart"
    if [ ! -d "$share_dir" ]; then
        mkdir -p "$share_dir"
        ln -sf ../../../tools/data "$share_dir/data"
        log_success "Share directory structure created"
    fi
}

# Step 7: Deploy libraries and create launcher
deploy_and_create_launcher() {
    log_info "Deploying libraries and creating launcher..."
    
    local executable_dir="$BUILD_DIR/skychart/units/${TARGET_CPU}-${TARGET_OS}-${WIDGET_SET}"
    local wcs_lib="$BUILD_DIR/skychart/library/wcs/libcdcwcs.dylib"
    
    # Copy WCS library to executable directory
    cp "$wcs_lib" "$executable_dir/"
    
    # Also copy to homebrew lib directory for system-wide access
    cp "$wcs_lib" "/Users/bino/homebrew/lib/"
    
    log_success "Libraries deployed"
}

# Step 8: Verify build
verify_build() {
    log_info "Verifying build..."
    
    local executable="$BUILD_DIR/skychart/units/${TARGET_CPU}-${TARGET_OS}-${WIDGET_SET}/skychart"
    local wcs_lib="$BUILD_DIR/skychart/library/wcs/libcdcwcs.dylib"
    
    # Check executable
    if [ -f "$executable" ]; then
        log_success "✓ SkyChart executable exists"
    else
        log_error "✗ SkyChart executable missing"
        return 1
    fi
    
    # Check WCS library
    if [ -f "$wcs_lib" ]; then
        log_success "✓ WCS library exists"
    else
        log_error "✗ WCS library missing"
        return 1
    fi
    
    # Check Qt5Pas framework
    if [ -f "$QT5_PATH/lib/Qt5Pas.framework/Qt5Pas" ]; then
        log_success "✓ Qt5Pas framework exists"
    else
        log_error "✗ Qt5Pas framework missing"
        return 1
    fi
    
    # Check data directory
    if [ -d "$BUILD_DIR/tools/data" ]; then
        log_success "✓ Data directory exists"
    else
        log_error "✗ Data directory missing"
        return 1
    fi
    
    log_success "Build verification complete"
}

# Main build process
main() {
    log_info "Starting SkyChart macOS ARM64 build process..."
    log_info "Build directory: $BUILD_DIR"
    log_info "Target: $TARGET_CPU-$TARGET_OS with $WIDGET_SET"
    
    # Execute build steps
    setup_lazarus
    build_qt5pas
    build_dependencies
    build_wcs_library
    build_skychart
    setup_data_directories
    deploy_and_create_launcher
    verify_build
    
    log_success "Build process completed successfully!"
    log_info "To run SkyChart: cd $BUILD_DIR && ./launch_skychart.sh"
}

# Handle command line arguments
case "${1:-}" in
    "clean")
        log_info "Cleaning build artifacts..."
        cd "$BUILD_DIR/skychart"
        make clean
        rm -rf units/
        cd library/wcs
        make clean
        log_success "Clean complete"
        ;;
    "verify")
        verify_build
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [clean|verify|help]"
        echo "  clean   - Clean build artifacts"
        echo "  verify  - Verify build without building"
        echo "  help    - Show this help"
        echo ""
        echo "Run without arguments to perform full build"
        ;;
    *)
        main
        ;;
esac