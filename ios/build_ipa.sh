#!/bin/bash

# iOS Build Script for Corgi AI Edu
# This script builds and exports an IPA file using App Store Connect API authentication

set -e

# Configuration
PROJECT_NAME="corgi_ai_edu"
SCHEME="Runner"
WORKSPACE_PATH="ios/Runner.xcworkspace"
EXPORT_OPTIONS_PATH="ios/ExportOptions.plist"
ARCHIVE_PATH="build/ios/Runner.xcarchive"
EXPORT_PATH="build/ios/ipa"
BUILD_CONFIGURATION="Release"

# App Store Connect API Configuration
API_KEY_PATH="ios/certificates/AuthKey_ZS4N64F44P.p8"
API_KEY_ID="ZS4N64F44P"
API_ISSUER_ID="029f0283-ed13-4b9a-9ac9-34b99e7227d9"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools are not installed"
        exit 1
    fi
    
    print_success "All dependencies are available"
}

# Function to clean previous builds
clean_build() {
    print_status "Cleaning previous builds..."
    
    # Flutter clean
    flutter clean
    
    # Remove previous archives and exports
    rm -rf build/ios/
    
    print_success "Clean completed"
}

# Function to get Flutter dependencies
get_dependencies() {
    print_status "Getting Flutter dependencies..."
    flutter pub get
    print_success "Dependencies installed"
}

# Function to build Flutter for iOS
build_flutter() {
    print_status "Building Flutter for iOS..."
    flutter build ios --release --no-codesign
    print_success "Flutter build completed"
}

# Function to create Xcode archive
create_archive() {
    print_status "Creating Xcode archive..."
    
    xcodebuild archive \
        -workspace "$WORKSPACE_PATH" \
        -scheme "$SCHEME" \
        -configuration "$BUILD_CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -allowProvisioningUpdates \
        -authenticationKeyPath "$API_KEY_PATH" \
        -authenticationKeyID "$API_KEY_ID" \
        -authenticationKeyIssuerID "$API_ISSUER_ID" \
        CODE_SIGN_STYLE=Automatic \
        | tee build_archive.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "Archive created successfully"
    else
        print_error "Archive creation failed. Check build_archive.log for details."
        exit 1
    fi
}

# Function to export IPA
export_ipa() {
    print_status "Exporting IPA..."
    
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
        -allowProvisioningUpdates \
        -authenticationKeyPath "$API_KEY_PATH" \
        -authenticationKeyID "$API_KEY_ID" \
        -authenticationKeyIssuerID "$API_ISSUER_ID" \
        | tee build_export.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "IPA exported successfully"
        
        # Find and display the IPA file path
        IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
        if [ -n "$IPA_FILE" ]; then
            print_success "IPA file created: $IPA_FILE"
            
            # Display file size
            FILE_SIZE=$(du -h "$IPA_FILE" | cut -f1)
            print_status "File size: $FILE_SIZE"
        else
            print_warning "IPA file not found in export directory"
        fi
    else
        print_error "IPA export failed. Check build_export.log for details."
        exit 1
    fi
}

# Function to validate configuration
validate_config() {
    print_status "Validating configuration..."
    
    # Check if AuthKey file exists
    if [ ! -f "$API_KEY_PATH" ]; then
        print_error "AuthKey file not found at $API_KEY_PATH"
        exit 1
    fi
    
    # Check if ExportOptions.plist exists
    if [ ! -f "$EXPORT_OPTIONS_PATH" ]; then
        print_error "ExportOptions.plist not found at $EXPORT_OPTIONS_PATH"
        exit 1
    fi
    
    # Check if workspace exists
    if [ ! -d "$WORKSPACE_PATH" ]; then
        print_error "Xcode workspace not found at $WORKSPACE_PATH"
        exit 1
    fi
    
    print_success "Configuration validation passed"
}

# Function to show help
show_help() {
    echo "iOS Build Script for Corgi AI Edu"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -c, --clean         Clean build artifacts before building"
    echo "  --skip-flutter      Skip Flutter build step"
    echo "  --archive-only      Only create archive, don't export IPA"
    echo ""
    echo "Environment Variables:"
    echo "  TEAM_ID            Your Apple Developer Team ID (required)"
    echo ""
    echo "Example:"
    echo "  TEAM_ID=ABCD123456 $0 --clean"
}

# Main build function
main() {
    print_status "Starting iOS build process for $PROJECT_NAME"
    print_status "Build configuration: $BUILD_CONFIGURATION"
    
    # Parse command line arguments
    CLEAN_BUILD=false
    SKIP_FLUTTER=false
    ARCHIVE_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            --skip-flutter)
                SKIP_FLUTTER=true
                shift
                ;;
            --archive-only)
                ARCHIVE_ONLY=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check for Team ID
    if [ -z "$TEAM_ID" ]; then
        print_warning "TEAM_ID environment variable not set."
        print_warning "You may need to set it manually in Xcode or provide it via environment variable."
        print_warning "Example: TEAM_ID=ABCD123456 $0"
    fi
    
    # Validate configuration
    validate_config
    
    # Check dependencies
    check_dependencies
    
    # Clean if requested
    if [ "$CLEAN_BUILD" = true ]; then
        clean_build
    fi
    
    # Get dependencies
    get_dependencies
    
    # Build Flutter if not skipped
    if [ "$SKIP_FLUTTER" = false ]; then
        build_flutter
    fi
    
    # Create archive
    create_archive
    
    # Export IPA if not archive-only
    if [ "$ARCHIVE_ONLY" = false ]; then
        export_ipa
    fi
    
    print_success "Build process completed successfully!"
    
    if [ "$ARCHIVE_ONLY" = false ]; then
        print_status "Your IPA file is ready for distribution or upload to App Store Connect."
    else
        print_status "Archive created. You can manually export it using Xcode Organizer."
    fi
}

# Run main function with all arguments
main "$@"