#!/bin/bash
# ════════════════════════════════════════
# BetterBliss — Build & Run on iPhone
# Usage: ./run.sh
# ════════════════════════════════════════

set -e
cd "$(dirname "$0")"

echo ""
echo "📱 BetterBliss — Building for iPhone"
echo "═════════════════════════════════════"

# 1. Check .env
if [ ! -f ".env" ]; then
  echo "❌ .env file missing — copy .env.example to .env first"
  exit 1
fi

# 2. Kill stale Xcode that might hold device
killall Xcode 2>/dev/null && echo "🧹 Killed stale Xcode" || true

# 3. Find iPhone
echo "🔍 Looking for iPhone..."
IPHONE_LINE=$(flutter devices 2>/dev/null | grep -i "ios" | grep -iv "simulator" | head -1)

if [ -z "$IPHONE_LINE" ]; then
  echo "❌ No iPhone found. Connect via USB or enable wireless debugging."
  exit 1
fi

DEVICE_ID=$(echo "$IPHONE_LINE" | grep -oE '[a-f0-9-]{20,}' | head -1)
DEVICE_NAME=$(echo "$IPHONE_LINE" | sed 's/ *•.*//' | xargs)
echo "✅ Found: $DEVICE_NAME"

# 4. Dependencies
echo "📦 Getting dependencies..."
flutter pub get > /dev/null 2>&1
echo "✅ Dependencies ready"

# 5. Build & Run with full logs
echo ""
echo "🚀 Launching on $DEVICE_NAME..."
echo "   r = hot reload | R = restart | q = quit"
echo "═════════════════════════════════════"
echo ""

flutter run -d "$DEVICE_ID" --device-timeout 90
