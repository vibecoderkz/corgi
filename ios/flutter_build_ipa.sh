#!/bin/bash

# Simple Flutter IPA Build Script
# Uses Flutter's built-in build ipa command with App Store Connect API

set -e

# Configuration
API_KEY_PATH="ios/certificates/AuthKey_ZS4N64F44P.p8"
API_KEY_ID="ZS4N64F44P"
API_ISSUER_ID="029f0283-ed13-4b9a-9ac9-34b99e7227d9"
EXPORT_OPTIONS_PATH="ios/ExportOptions.plist"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Team ID is provided
if [ -z "$TEAM_ID" ]; then
    print_error "TEAM_ID environment variable is required"
    echo "Usage: TEAM_ID=YOUR_TEAM_ID $0"
    exit 1
fi

# Validate API key exists
if [ ! -f "$API_KEY_PATH" ]; then
    print_error "AuthKey file not found at $API_KEY_PATH"
    exit 1
fi

print_status "Building IPA with Flutter..."
print_status "Team ID: $TEAM_ID"
print_status "API Key ID: $API_KEY_ID"

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Build IPA using Flutter
print_status "Building IPA..."
flutter build ipa \
    --release \
    --export-options-plist="$EXPORT_OPTIONS_PATH" \
    --export-method=app-store

if [ $? -eq 0 ]; then
    print_success "IPA build completed successfully!"
    
    # Find the IPA file
    IPA_FILE=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1)
    if [ -n "$IPA_FILE" ]; then
        print_success "IPA file: $IPA_FILE"
        FILE_SIZE=$(du -h "$IPA_FILE" | cut -f1)
        print_status "File size: $FILE_SIZE"
    fi
else
    print_error "IPA build failed"
    exit 1
fi