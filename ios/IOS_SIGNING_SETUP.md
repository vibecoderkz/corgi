# iOS Code Signing Setup Guide

This guide explains how to set up iOS code signing for the Corgi AI Edu Flutter project using App Store Connect API authentication.

## Prerequisites

1. **Apple Developer Account**: Active paid Apple Developer account
2. **Xcode**: Latest version of Xcode installed
3. **Flutter**: Flutter SDK installed and configured
4. **App Store Connect API Key**: Generated from App Store Connect

## Configuration Files Created

### 1. App Store Connect API Configuration
**File**: `ios/certificates/app_store_connect_api.json`

```json
{
  "key_id": "ZS4N64F44P",
  "issuer_id": "029f0283-ed13-4b9a-9ac9-34b99e7227d9",
  "key_file": "AuthKey_ZS4N64F44P.p8",
  "bundle_id": "com.aicc.corgi",
  "team_id": "YOUR_TEAM_ID"
}
```

### 2. Export Options for IPA Distribution
**File**: `ios/ExportOptions.plist`

Configured for App Store distribution with automatic signing.

### 3. AuthKey File
**File**: `ios/certificates/AuthKey_ZS4N64F44P.p8`

Your App Store Connect API private key (already present).

## Required Setup Steps

### Step 1: Set Your Team ID

You need to set your Apple Developer Team ID in two places:

1. **Update ExportOptions.plist**:
   ```bash
   # Replace YOUR_TEAM_ID with your actual Team ID
   sed -i 's/YOUR_TEAM_ID/ABCD123456/g' ios/ExportOptions.plist
   ```

2. **Update API configuration**:
   ```bash
   # Replace YOUR_TEAM_ID in the JSON file
   sed -i 's/YOUR_TEAM_ID/ABCD123456/g' ios/certificates/app_store_connect_api.json
   ```

3. **Set in Xcode project** (optional - can be done via environment variable):
   - Open `ios/Runner.xcodeproj` in Xcode
   - Select the Runner target
   - In "Signing & Capabilities", set the Team

### Step 2: Verify Bundle Identifier

Ensure the bundle identifier `com.aicc.corgi` is registered in your Apple Developer account:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to "Certificates, Identifiers & Profiles"
3. Add identifier `com.aicc.corgi` if it doesn't exist

### Step 3: Find Your Team ID

If you don't know your Team ID:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Look for "Team ID" in the top-right corner, or
3. Run this command in Terminal:
   ```bash
   security find-identity -v -p codesigning
   ```

## Building Methods

### Method 1: Using Flutter (Recommended)

```bash
# Set your Team ID and build
TEAM_ID=ABCD123456 ./ios/flutter_build_ipa.sh
```

### Method 2: Using Xcode Build Tools

```bash
# Set your Team ID and build with full control
TEAM_ID=ABCD123456 ./ios/build_ipa.sh
```

### Method 3: Manual Flutter Command

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build IPA
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

## Project Configuration

The iOS project has been configured with:

- **Automatic Code Signing**: Enabled for all build configurations
- **Bundle Identifier**: `com.aicc.corgi`
- **Development Team**: Set to empty (will use Team ID from environment or Xcode)
- **Deployment Target**: iOS 12.0+

## Troubleshooting

### Common Issues

1. **"No signing certificate found"**
   - Ensure your Apple Developer account has valid certificates
   - Try: `flutter build ios --release` first to let Xcode download certificates

2. **"Team ID not found"**
   - Set the TEAM_ID environment variable
   - Or update the Team in Xcode manually

3. **"AuthKey file not found"**
   - Verify the AuthKey file is in `ios/certificates/`
   - Check file permissions

4. **"Bundle identifier not registered"**
   - Register `com.aicc.corgi` in Apple Developer Portal
   - Or change the bundle identifier in project settings

### Debug Commands

```bash
# Check signing identities
security find-identity -v -p codesigning

# List available provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Check project settings
cat ios/Runner.xcodeproj/project.pbxproj | grep -A5 -B5 "CODE_SIGN"
```

## File Structure

```
ios/
├── certificates/
│   ├── AuthKey_ZS4N64F44P.p8          # App Store Connect API key
│   └── app_store_connect_api.json      # API configuration
├── ExportOptions.plist                 # IPA export settings
├── build_ipa.sh                       # Comprehensive build script
├── flutter_build_ipa.sh               # Simple Flutter build script
└── IOS_SIGNING_SETUP.md               # This guide
```

## Security Notes

- Keep your AuthKey file secure and never commit it to version control
- The Team ID is not sensitive but should be correct for your account
- Consider using CI/CD environment variables for production builds

## Next Steps

1. Set your Team ID in the configuration files
2. Verify your bundle identifier is registered
3. Run a test build to ensure everything works
4. Set up CI/CD pipeline for automated builds (optional)

## Support

If you encounter issues:
1. Check the build logs in the generated `.log` files
2. Verify all prerequisites are met
3. Ensure your Apple Developer account is active and has the necessary certificates