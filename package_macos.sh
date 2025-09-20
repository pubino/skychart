#!/bin/bash

# SkyChart macOS Package Preparation Script
# Prepares SkyChart for notarization and distribution
# Author: Generated for macOS ARM64 distribution
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
APP_NAME="SkyChart"
VERSION="4.5"  # Update this as needed
BUNDLE_ID="org.ap-i.skychart"
EXECUTABLE_DIR="$SCRIPT_DIR/skychart/units/aarch64-darwin-qt5"
QT5_PATH="/Users/bino/homebrew/Cellar/qt@5/5.15.17"
DIST_DIR="$SCRIPT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

# Create macOS app bundle structure
create_app_bundle() {
    log_info "Creating macOS app bundle..."
    
    # Remove existing bundle
    rm -rf "$APP_BUNDLE"
    
    # Create bundle structure
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    mkdir -p "$APP_BUNDLE/Contents/Frameworks"
    mkdir -p "$APP_BUNDLE/Contents/Libraries"
    
    log_success "App bundle structure created"
}

# Create Info.plist
create_info_plist() {
    log_info "Creating Info.plist..."
    
    cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>fits</string>
                <string>fit</string>
                <string>fts</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>FITS Image</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 Patrick Chevalley. All rights reserved.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.education</string>
</dict>
</plist>
EOF
    
    log_success "Info.plist created"
}

# Copy executable and libraries
copy_executable_and_libraries() {
    log_info "Copying executable and libraries..."
    
    # Copy main executable
    cp "$EXECUTABLE_DIR/skychart" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    
    # Copy WCS library
    cp "$SCRIPT_DIR/skychart/library/wcs/libcdcwcs.dylib" "$APP_BUNDLE/Contents/Libraries/"
    
    # Copy Qt5Pas framework
    cp -R "$QT5_PATH/lib/Qt5Pas.framework" "$APP_BUNDLE/Contents/Frameworks/"
    
    log_success "Executable and libraries copied"
}

# Copy data and resources
copy_resources() {
    log_info "Copying data and resources..."
    
    # Copy the entire tools directory (includes data and cat subdirectories)
    # IMPORTANT: Must copy entire tools/ directory, not just tools/data/
    # The tools/cat/ directory contains all star catalogs (Hipparcos, GAIA, etc.)
    cp -R "$SCRIPT_DIR/tools" "$APP_BUNDLE/Contents/Resources/"
    
    # Copy any icon files if they exist
    if [ -f "$SCRIPT_DIR/skychart/cdc.icns" ]; then
        cp "$SCRIPT_DIR/skychart/cdc.icns" "$APP_BUNDLE/Contents/Resources/"
    fi
    
    log_success "Resources copied"
}

# Create launcher script inside bundle
create_bundle_launcher() {
    log_info "Creating bundle launcher..."
    
    cat > "$APP_BUNDLE/Contents/MacOS/launcher.sh" << 'EOF'
#!/bin/bash

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESOURCES_DIR="$BUNDLE_DIR/Contents/Resources"
FRAMEWORKS_DIR="$BUNDLE_DIR/Contents/Frameworks"
LIBRARIES_DIR="$BUNDLE_DIR/Contents/Libraries"

# Set up environment
export DYLD_FRAMEWORK_PATH="$FRAMEWORKS_DIR:$DYLD_FRAMEWORK_PATH"
export DYLD_LIBRARY_PATH="$LIBRARIES_DIR:$DYLD_LIBRARY_PATH"

# Launch the application with proper data directory
exec "$SCRIPT_DIR/SkyChart_bin" --datadir="$RESOURCES_DIR/tools" "$@"
EOF
    
    chmod +x "$APP_BUNDLE/Contents/MacOS/launcher.sh"
    
    # Replace main executable with launcher
    mv "$APP_BUNDLE/Contents/MacOS/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/${APP_NAME}_bin"
    mv "$APP_BUNDLE/Contents/MacOS/launcher.sh" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    
    log_success "Bundle launcher created"
}

# Fix library paths and dependencies
fix_library_paths() {
    log_info "Fixing library paths..."
    
    local executable="$APP_BUNDLE/Contents/MacOS/${APP_NAME}_bin"
    local wcs_lib="$APP_BUNDLE/Contents/Libraries/libcdcwcs.dylib"
    local qt5pas_framework="$APP_BUNDLE/Contents/Frameworks/Qt5Pas.framework/Qt5Pas"
    
    # Fix Qt5Pas framework path in executable
    install_name_tool -change \
        "Qt5Pas.framework/Versions/1/Qt5Pas" \
        "@executable_path/../Frameworks/Qt5Pas.framework/Qt5Pas" \
        "$executable" 2>/dev/null || true
    
    # Fix WCS library install name
    install_name_tool -id \
        "@executable_path/../Libraries/libcdcwcs.dylib" \
        "$wcs_lib" 2>/dev/null || true
    
    log_success "Library paths fixed"
}

# Code signing preparation
prepare_for_signing() {
    log_info "Preparing for code signing..."
    
    # Remove extended attributes that might interfere with signing
    xattr -cr "$APP_BUNDLE"
    
    # Set proper permissions
    find "$APP_BUNDLE" -type f -exec chmod 644 {} \;
    find "$APP_BUNDLE" -type d -exec chmod 755 {} \;
    chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    chmod +x "$APP_BUNDLE/Contents/MacOS/${APP_NAME}_bin"
    
    log_success "Prepared for code signing"
}

# Create DMG for distribution
create_dmg() {
    log_info "Creating DMG for distribution..."
    
    local dmg_name="${APP_NAME}-${VERSION}-macOS-ARM64.dmg"
    local temp_dmg="/tmp/${APP_NAME}-temp.dmg"
    
    # Remove existing DMG
    rm -f "$DIST_DIR/$dmg_name"
    rm -f "$temp_dmg"
    
    # Create temporary DMG
    hdiutil create -srcfolder "$APP_BUNDLE" -volname "$APP_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW "$temp_dmg"
    
    # Mount the DMG
    local mount_point="/Volumes/$APP_NAME"
    hdiutil attach "$temp_dmg" -mountpoint "$mount_point"
    
    # Create Applications symlink
    ln -sf /Applications "$mount_point/Applications"
    
    # Set DMG appearance (if you have a background image)
    # You can add DMG customization here
    
    # Unmount and convert to final DMG
    hdiutil detach "$mount_point"
    hdiutil convert "$temp_dmg" -format UDZO -o "$DIST_DIR/$dmg_name"
    rm "$temp_dmg"
    
    log_success "DMG created: $DIST_DIR/$dmg_name"
}

# Code signing function (requires developer certificate)
code_sign() {
    local identity="$1"
    
    if [ -z "$identity" ]; then
        log_warning "No signing identity provided. Skipping code signing."
        log_info "To sign, run: $0 sign 'Developer ID Application: Your Name'"
        return
    fi
    
    log_info "Code signing with identity: $identity"
    
    # Sign frameworks and libraries first
    codesign --force --sign "$identity" --timestamp --options runtime "$APP_BUNDLE/Contents/Frameworks/Qt5Pas.framework"
    codesign --force --sign "$identity" --timestamp --options runtime "$APP_BUNDLE/Contents/Libraries/libcdcwcs.dylib"
    codesign --force --sign "$identity" --timestamp --options runtime "$APP_BUNDLE/Contents/MacOS/${APP_NAME}_bin"
    
    # Sign the main bundle
    codesign --force --sign "$identity" --timestamp --options runtime "$APP_BUNDLE"
    
    # Verify signature
    codesign --verify --verbose "$APP_BUNDLE"
    
    log_success "Code signing completed"
}

# Notarization function (requires Apple ID and app-specific password)
notarize() {
    local apple_id="$1"
    local password="$2"
    local team_id="$3"
    
    if [ -z "$apple_id" ] || [ -z "$password" ] || [ -z "$team_id" ]; then
        log_warning "Missing notarization credentials. Skipping notarization."
        log_info "To notarize, run: $0 notarize your@email.com app-password TEAM_ID"
        return
    fi
    
    log_info "Starting notarization process..."
    
    # Create zip for notarization
    local zip_file="$DIST_DIR/${APP_NAME}-${VERSION}.zip"
    cd "$DIST_DIR"
    zip -r "$zip_file" "$APP_NAME.app"
    
    # Submit for notarization
    xcrun notarytool submit "$zip_file" \
        --apple-id "$apple_id" \
        --password "$password" \
        --team-id "$team_id" \
        --wait
    
    # Staple the notarization ticket
    xcrun stapler staple "$APP_BUNDLE"
    
    log_success "Notarization completed"
}

# Main function
main() {
    log_info "Starting SkyChart packaging process..."
    
    # Ensure dist directory exists
    mkdir -p "$DIST_DIR"
    
    # Create the app bundle
    create_app_bundle
    create_info_plist
    copy_executable_and_libraries
    copy_resources
    create_bundle_launcher
    fix_library_paths
    prepare_for_signing
    
    log_success "App bundle created successfully: $APP_BUNDLE"
    log_info "Bundle size: $(du -sh "$APP_BUNDLE" | cut -f1)"
}

# Command line interface
case "${1:-}" in
    "sign")
        if [ -z "$2" ]; then
            log_error "Usage: $0 sign 'Developer ID Application: Your Name'"
            exit 1
        fi
        code_sign "$2"
        ;;
    "notarize")
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            log_error "Usage: $0 notarize apple_id app_password team_id"
            exit 1
        fi
        notarize "$2" "$3" "$4"
        ;;
    "dmg")
        create_dmg
        ;;
    "all")
        main
        create_dmg
        ;;
    "help"|"-h"|"--help")
        echo "SkyChart macOS Packaging Script"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  (no args)  - Create app bundle"
        echo "  sign ID    - Code sign with Developer ID"
        echo "  notarize   - Notarize with Apple (requires credentials)"
        echo "  dmg        - Create DMG distribution"
        echo "  all        - Create bundle and DMG"
        echo "  help       - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0                    # Create app bundle"
        echo "  $0 all               # Create bundle and DMG"
        echo "  $0 sign 'Developer ID Application: Your Name'"
        echo "  $0 notarize your@email.com app-password TEAM_ID"
        ;;
    *)
        main
        ;;
esac