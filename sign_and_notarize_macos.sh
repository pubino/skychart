#!/bin/bash

# sign_and_notarize_macos.sh - Automated macOS app signing and notarization
# Usage: ./sign_and_notarize_macos.sh path/to/SkyChart.app

set -e

# Configuration - Set these as environment variables or GitHub secrets
DEVELOPER_ID_APPLICATION=${DEVELOPER_ID_APPLICATION:-""}  # "Developer ID Application: Your Name (TEAM_ID)"
DEVELOPER_ID_INSTALLER=${DEVELOPER_ID_INSTALLER:-""}      # "Developer ID Installer: Your Name (TEAM_ID)"
APPLE_ID=${APPLE_ID:-""}                                  # Your Apple ID email
APP_PASSWORD=${APP_PASSWORD:-""}                          # App-specific password
TEAM_ID=${TEAM_ID:-""}                                    # Your 10-character Team ID

# Check if required parameters are provided
if [[ -z "$1" ]]; then
    echo "❌ Usage: $0 <path-to-app-bundle>"
    echo "Example: $0 dist/SkyChart.app"
    exit 1
fi

APP_PATH="$1"
APP_NAME=$(basename "$APP_PATH" .app)
DMG_NAME="${APP_NAME}-$(date +%Y%m%d).dmg"

echo "🔐 Starting macOS code signing and notarization process..."
echo "📱 App: $APP_PATH"
echo "💾 DMG: $DMG_NAME"

# Function to check if certificates are available
check_certificates() {
    echo "🔍 Checking for required certificates..."
    
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        echo "❌ Developer ID Application certificate not found"
        echo "📋 To install certificates:"
        echo "   1. Download certificates from Apple Developer portal"
        echo "   2. Double-click to install in Keychain Access"
        echo "   3. Or use: security import certificate.p12 -k ~/Library/Keychains/login.keychain"
        return 1
    fi
    
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Installer"; then
        echo "⚠️  Developer ID Installer certificate not found (optional for DMG)"
    fi
    
    echo "✅ Code signing certificates found"
    return 0
}

# Function to sign the app bundle
sign_app() {
    echo "🔏 Signing app bundle and all contents..."
    
    # Sign all executable files and frameworks first (inside-out signing)
    find "$APP_PATH" -type f \( -name "*.dylib" -o -name "*.framework" -o -perm +111 \) | while read -r file; do
        if file "$file" | grep -q "Mach-O"; then
            echo "  📝 Signing: $(basename "$file")"
            codesign --force --verify --verbose --sign "$DEVELOPER_ID_APPLICATION" \
                --options runtime --timestamp "$file"
        fi
    done
    
    # Sign the main app bundle
    echo "  📝 Signing main app bundle..."
    codesign --force --verify --verbose --sign "$DEVELOPER_ID_APPLICATION" \
        --options runtime --timestamp --entitlements entitlements.plist "$APP_PATH" 2>/dev/null || \
    codesign --force --verify --verbose --sign "$DEVELOPER_ID_APPLICATION" \
        --options runtime --timestamp "$APP_PATH"
    
    echo "✅ App bundle signed successfully"
}

# Function to create DMG
create_dmg() {
    echo "💾 Creating DMG installer..."
    
    # Create a temporary directory for DMG contents
    DMG_DIR=$(mktemp -d)
    cp -R "$APP_PATH" "$DMG_DIR/"
    
    # Create Applications shortcut
    ln -s /Applications "$DMG_DIR/Applications"
    
    # Create DMG
    hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG_NAME"
    
    # Clean up
    rm -rf "$DMG_DIR"
    
    # Sign the DMG
    echo "🔏 Signing DMG..."
    codesign --force --verify --verbose --sign "$DEVELOPER_ID_APPLICATION" \
        --timestamp "$DMG_NAME"
    
    echo "✅ DMG created and signed: $DMG_NAME"
}

# Function to notarize the DMG
notarize_dmg() {
    echo "🍎 Submitting DMG for notarization..."
    
    if [[ -z "$APPLE_ID" || -z "$APP_PASSWORD" || -z "$TEAM_ID" ]]; then
        echo "⚠️  Notarization skipped - Apple ID, app password, or team ID not provided"
        echo "📋 To enable notarization, set:"
        echo "   export APPLE_ID='your-apple-id@example.com'"
        echo "   export APP_PASSWORD='xxxx-xxxx-xxxx-xxxx'"  # App-specific password
        echo "   export TEAM_ID='XXXXXXXXXX'"  # 10-character team ID
        return 0
    fi
    
    # Submit for notarization
    echo "  📤 Uploading to Apple..."
    SUBMISSION_ID=$(xcrun notarytool submit "$DMG_NAME" \
        --apple-id "$APPLE_ID" \
        --password "$APP_PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait 2>&1 | grep -E "id: [a-f0-9\-]+" | awk '{print $2}')
    
    if [[ -z "$SUBMISSION_ID" ]]; then
        echo "❌ Notarization submission failed"
        return 1
    fi
    
    echo "  🔍 Submission ID: $SUBMISSION_ID"
    echo "  ⏳ Waiting for notarization (this may take several minutes)..."
    
    # Check status (notarytool submit --wait should handle this, but let's be explicit)
    xcrun notarytool info "$SUBMISSION_ID" \
        --apple-id "$APPLE_ID" \
        --password "$APP_PASSWORD" \
        --team-id "$TEAM_ID"
    
    # Staple the notarization ticket
    echo "  📎 Stapling notarization ticket..."
    xcrun stapler staple "$DMG_NAME"
    
    echo "✅ Notarization complete!"
}

# Function to verify the final result
verify_signature() {
    echo "🔍 Verifying final signatures..."
    
    echo "  App bundle verification:"
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
    spctl --assess --type exec --verbose "$APP_PATH"
    
    echo "  DMG verification:"
    codesign --verify --deep --strict --verbose=2 "$DMG_NAME"
    spctl --assess --type open --context context:primary-signature --verbose "$DMG_NAME"
    
    echo "✅ All verifications passed!"
}

# Main execution flow
main() {
    # Pre-flight checks
    if [[ ! -d "$APP_PATH" ]]; then
        echo "❌ App bundle not found: $APP_PATH"
        exit 1
    fi
    
    if ! check_certificates; then
        echo "❌ Required certificates not available"
        exit 1
    fi
    
    # Execute signing and notarization pipeline
    sign_app
    create_dmg
    notarize_dmg
    verify_signature
    
    echo ""
    echo "🎉 SUCCESS! macOS app signing and notarization complete!"
    echo "📦 Distributable DMG: $DMG_NAME"
    echo "🍎 Ready for distribution outside the App Store"
}

# Execute main function
main "$@"