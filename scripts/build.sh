#!/bin/bash
echo "Building Better & Bliss with obfuscation..."
flutter build ios --release --obfuscate --split-debug-info=build/debug-info/ios
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/android
echo "Build complete. Debug symbols in build/debug-info/"
