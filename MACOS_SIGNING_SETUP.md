# macOS Code Signing & Notarization Setup Guide

## 📋 Prerequisites

### 1. Apple Developer Account
- Sign up at [developer.apple.com](https://developer.apple.com)
- Cost: $99/year
- Provides access to certificates and notarization service

### 2. Required Certificates

#### Option A: Using Apple Developer Portal (Recommended)
1. **Login to Apple Developer Portal**: [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates)

2. **Create Developer ID Application Certificate**:
   - Click "+" to create new certificate
   - Select "Developer ID Application"
   - Upload Certificate Signing Request (CSR)
   - Download and install certificate

3. **Create Developer ID Installer Certificate** (optional):
   - Select "Developer ID Installer" 
   - Follow same process

#### Option B: Using Xcode Command Line Tools
```bash
# Generate CSR and private key
security create-keypair -a RSA -s 2048 -f ~/Desktop/CertificateSigningRequest.certSigningRequest

# Then upload CSR to Apple Developer Portal
```

### 3. Install Certificates
```bash
# Download .cer files from Apple Developer Portal
# Double-click to install in Keychain Access
# Or use command line:
security import DeveloperID_Application.cer -k ~/Library/Keychains/login.keychain
security import DeveloperID_Installer.cer -k ~/Library/Keychains/login.keychain
```

### 4. Verify Certificate Installation
```bash
# List available code signing identities
security find-identity -v -p codesigning

# Should show something like:
# 1) XXXXXXXXXX "Developer ID Application: Your Name (TEAM_ID)"
# 2) YYYYYYYYYY "Developer ID Installer: Your Name (TEAM_ID)"
```

## 🔐 App-Specific Password Setup

### 1. Generate App-Specific Password
1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Go to "Sign-In and Security" → "App-Specific Passwords"
4. Click "Generate Password..."
5. Enter label: "SkyChart Notarization"
6. Copy the generated password (format: xxxx-xxxx-xxxx-xxxx)

### 2. Store Credentials Securely

#### For Local Development:
```bash
# Store in keychain (recommended)
xcrun notarytool store-credentials "skychart-notarize" \
    --apple-id "your-apple-id@example.com" \
    --team-id "XXXXXXXXXX" \
    --password "xxxx-xxxx-xxxx-xxxx"
```

#### For GitHub Actions:
Set these as repository secrets:
- `APPLE_ID`: Your Apple ID email
- `APP_PASSWORD`: The app-specific password
- `TEAM_ID`: Your 10-character team ID
- `DEVELOPER_ID_APPLICATION`: Full certificate name
- `DEVELOPER_ID_INSTALLER`: Full certificate name (if used)

## 🧪 Testing the Setup

### 1. Test Certificate Access
```bash
# Check if certificates are accessible
security find-identity -v -p codesigning | grep "Developer ID"
```

### 2. Test Basic Signing
```bash
# Sign a test binary
echo "test" > test_binary
chmod +x test_binary
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" test_binary
codesign --verify --verbose test_binary
rm test_binary
```

### 3. Test Notarization
```bash
# Create a simple test app and notarize
mkdir TestApp.app
echo "test" > TestApp.app/test
zip -r TestApp.zip TestApp.app

xcrun notarytool submit TestApp.zip \
    --apple-id "your-apple-id@example.com" \
    --password "xxxx-xxxx-xxxx-xxxx" \
    --team-id "XXXXXXXXXX" \
    --wait

rm -rf TestApp.app TestApp.zip
```

## 🚀 Integration with GitHub Actions

### Environment Variables Needed:
```yaml
env:
  DEVELOPER_ID_APPLICATION: ${{ secrets.DEVELOPER_ID_APPLICATION }}
  DEVELOPER_ID_INSTALLER: ${{ secrets.DEVELOPER_ID_INSTALLER }}
  APPLE_ID: ${{ secrets.APPLE_ID }}
  APP_PASSWORD: ${{ secrets.APP_PASSWORD }}
  TEAM_ID: ${{ secrets.TEAM_ID }}
```

### Certificate Installation in CI:
```yaml
- name: Install certificates
  env:
    BUILD_CERTIFICATE_BASE64: ${{ secrets.BUILD_CERTIFICATE_BASE64 }}
    P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
  run: |
    # Decode and install certificates
    echo $BUILD_CERTIFICATE_BASE64 | base64 --decode > certificate.p12
    security create-keychain -p "" build.keychain
    security import certificate.p12 -k build.keychain -P "$P12_PASSWORD" -T /usr/bin/codesign
    security list-keychains -s build.keychain
    security default-keychain -s build.keychain
```

## 📝 Common Issues & Solutions

### Issue: "Developer ID Application certificate not found"
**Solution**: 
- Verify certificate installation in Keychain Access
- Check certificate name matches exactly
- Ensure certificate is in login keychain

### Issue: "Notarization failed with invalid credentials"
**Solution**:
- Verify Apple ID and app-specific password
- Check team ID is correct (10 characters)
- Ensure 2FA is enabled on Apple ID

### Issue: "App bundle format is invalid"
**Solution**:
- Ensure Info.plist is present and valid
- Sign all binaries with hardened runtime
- Use proper entitlements file

### Issue: "Gatekeeper rejection after download"
**Solution**:
- Ensure app is properly notarized
- Check stapler attached the ticket
- Verify with: `spctl --assess --verbose`

## 🔧 Automation Script Usage

```bash
# Make script executable
chmod +x sign_and_notarize_macos.sh

# Set environment variables
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAM_ID)"
export APPLE_ID="your-apple-id@example.com"
export APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export TEAM_ID="XXXXXXXXXX"

# Run signing and notarization
./sign_and_notarize_macos.sh dist/SkyChart.app
```

## 📚 Additional Resources

- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Hardened Runtime Entitlements](https://developer.apple.com/documentation/security/hardened_runtime)
- [Gatekeeper and Quarantine](https://support.apple.com/guide/security/gatekeeper-and-runtime-protection-sec5599b66df/web)