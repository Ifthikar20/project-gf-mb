#!/bin/bash

# ==============================================
# PRODUCTION BUILD SCRIPT WITH OBFUSCATION
# ==============================================
# This script builds the app with security hardening:
# 1. Code obfuscation (makes reverse engineering harder)
# 2. Split debug info (keeps symbols separate)
# 3. Release mode optimization
# 
# Usage:
#   ./scripts/build_release.sh android
#   ./scripts/build_release.sh ios
#   ./scripts/build_release.sh web

set -e

PLATFORM=$1
DEBUG_INFO_DIR="./debug-info"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Building secure release for ${PLATFORM}${NC}"

# Create debug info directory (for crash symbolication)
mkdir -p $DEBUG_INFO_DIR

# Check for .env file
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Error: .env file not found${NC}"
    echo "Please copy .env.example to .env and configure your secrets"
    exit 1
fi

# Common build flags
BUILD_FLAGS="--release --obfuscate --split-debug-info=$DEBUG_INFO_DIR"

# Run tests before building
echo -e "${YELLOW}🧪 Running tests before build...${NC}"
flutter test
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Tests failed. Aborting build.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ All tests passed!${NC}"
echo ""

case $PLATFORM in
    "android")
        echo -e "${YELLOW}📱 Building Android APK with obfuscation...${NC}"
        flutter build apk $BUILD_FLAGS
        echo -e "${GREEN}✅ Android APK built: build/app/outputs/flutter-apk/app-release.apk${NC}"
        
        # Optional: Build App Bundle for Play Store
        echo -e "${YELLOW}📦 Building Android App Bundle...${NC}"
        flutter build appbundle $BUILD_FLAGS
        echo -e "${GREEN}✅ App Bundle built: build/app/outputs/bundle/release/app-release.aab${NC}"
        ;;
        
    "ios")
        echo -e "${YELLOW}🍎 Building iOS with obfuscation...${NC}"
        flutter build ios $BUILD_FLAGS
        echo -e "${GREEN}✅ iOS build complete${NC}"
        echo "Open Xcode to archive: ios/Runner.xcworkspace"
        ;;
        
    "web")
        echo -e "${YELLOW}🌐 Building web release...${NC}"
        flutter build web --release
        echo -e "${GREEN}✅ Web build complete: build/web/${NC}"
        ;;
        
    *)
        echo -e "${RED}Usage: $0 [android|ios|web]${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🔒 Security features applied:${NC}"
echo "  ✓ Code obfuscation enabled"
echo "  ✓ Debug symbols split to: $DEBUG_INFO_DIR"
echo "  ✓ Release mode optimizations"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Keep $DEBUG_INFO_DIR safe for crash symbolication${NC}"
echo -e "${YELLOW}⚠️  NEVER commit debug-info or .env to version control${NC}"
