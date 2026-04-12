#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# run.sh — Great Feel Flutter launcher
#
# Usage:
#   ./run.sh                   # auto-detect device, debug mode
#   ./run.sh --device sim      # force simulator
#   ./run.sh --device phone    # force physical iPhone
#   ./run.sh --mode release    # release | profile | debug
#   ./run.sh --clean           # flutter clean before build
#   ./run.sh --verbose         # full verbose output + log file
#   ./run.sh --help            # show this help
# ─────────────────────────────────────────────────────────────────

# ── Colours ───────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
RED='\033[0;31m';   BOLD='\033[1m';      RESET='\033[0m'

log()  { echo -e "${CYAN}▶ $*${RESET}"; }
ok()   { echo -e "${GREEN}✔ $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $*${RESET}"; }
err()  { echo -e "${RED}✘ $*${RESET}"; exit 1; }

# ── Defaults ──────────────────────────────────────────────────────
MODE="debug"
DEVICE_PREF="auto"
DO_CLEAN=false
VERBOSE=false

# ── Parse args ────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)  DEVICE_PREF="$2"; shift 2 ;;
    --mode)    MODE="$2";        shift 2 ;;
    --clean)   DO_CLEAN=true;    shift   ;;
    --verbose) VERBOSE=true;     shift   ;;
    --help)
      sed -n '/^# Usage/,/^# ─/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) err "Unknown option: $1. Run ./run.sh --help" ;;
  esac
done

echo ""
echo -e "${BOLD}═══════════════════════════════════════${RESET}"
echo -e "${BOLD}  Great Feel — Flutter Runner${RESET}"
echo -e "${BOLD}═══════════════════════════════════════${RESET}"
echo -e "  Mode:    ${CYAN}${MODE}${RESET}"
echo -e "  Time:    $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ── Clean if requested ────────────────────────────────────────────
if $DO_CLEAN; then
  log "Running flutter clean..."
  flutter clean
  log "Running flutter pub get..."
  flutter pub get --no-version-check 2>&1 | grep -E "^(Got|Resolving|Changed|.+Error)" || true
  ok "Clean complete"
  echo ""
fi

# ── Detect devices ────────────────────────────────────────────────
KNOWN_PHONE_ID="00008120-000639261EF8201E"     # AliIphone2024 (UDID)
DEVICECTL_ID="430078C4-7DD5-4D3B-A852-336608BB5EE4"  # AliIphone2024 (CoreDevice)

log "Detecting devices..."
DEVICE_LIST=$(flutter devices 2>/dev/null)

# USB-first then wireless
PHYSICAL_DEVICE=$(echo "$DEVICE_LIST" \
  | grep -E '\• ios \•' \
  | grep -iv 'simulator' \
  | grep -iv 'wireless' \
  | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{16}|[0-9a-fA-F-]{36}' \
  | head -1)

if [[ -z "$PHYSICAL_DEVICE" ]]; then
  PHYSICAL_DEVICE=$(echo "$DEVICE_LIST" \
    | grep -E '\• ios \•' \
    | grep -iv 'simulator' \
    | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{16}|[0-9a-fA-F-]{36}' \
    | head -1)
  [[ -n "$PHYSICAL_DEVICE" ]] && warn "Only wireless connection found"
fi

[[ -z "$PHYSICAL_DEVICE" ]] && echo "$DEVICE_LIST" | grep -q "$KNOWN_PHONE_ID" \
  && PHYSICAL_DEVICE="$KNOWN_PHONE_ID"

SIMULATOR_ID=$(echo "$DEVICE_LIST" \
  | grep -iE 'simulator' \
  | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' \
  | head -1)

# ── Select target device ──────────────────────────────────────────
USE_DEVICECTL=false

case "$DEVICE_PREF" in
  phone)
    [[ -z "$PHYSICAL_DEVICE" ]] && err "No physical iPhone found."
    DEVICE="$PHYSICAL_DEVICE"
    ok "Targeting iPhone: ${DEVICE}"
    # Use devicectl for wireless to bypass osascript/Xcode hang
    USE_DEVICECTL=true
    ;;
  sim)
    [[ -z "$SIMULATOR_ID" ]] && err "No simulator found. Open Simulator.app first."
    DEVICE="$SIMULATOR_ID"
    ok "Targeting simulator: ${DEVICE}"
    ;;
  auto)
    if [[ -n "$PHYSICAL_DEVICE" ]]; then
      DEVICE="$PHYSICAL_DEVICE"
      ok "iPhone detected: ${DEVICE}"
      USE_DEVICECTL=true
    elif [[ -n "$SIMULATOR_ID" ]]; then
      DEVICE="$SIMULATOR_ID"
      warn "No iPhone found — using simulator: ${DEVICE}"
    else
      err "No devices found. Connect iPhone or start Simulator."
    fi
    ;;
  *)
    DEVICE="$DEVICE_PREF"
    ok "Using device: ${DEVICE}"
    ;;
esac

echo ""

# ── Build + Run ───────────────────────────────────────────────────
# For physical iOS devices over wireless, flutter's osascript path
# fails with "Xcode is not running" / osascript -2.
# Fix: build the .app with xcodebuild, then install+launch via
# devicectl (iOS 17+) which doesn't need Xcode running at all.

if $USE_DEVICECTL && command -v xcrun &>/dev/null; then
  XCODE_CONFIG="Debug"
  [[ "$MODE" == "release" ]] && XCODE_CONFIG="Release"
  [[ "$MODE" == "profile" ]] && XCODE_CONFIG="Profile"

  APP_PATH="build/ios/iphoneos/Runner.app"

  log "Step 1/2: Building & signing Flutter app (${XCODE_CONFIG})..."
  FLUTTER_BUILD_ARGS=(build ios "--$MODE" --no-pub)
  $VERBOSE && FLUTTER_BUILD_ARGS+=(--verbose)

  flutter "${FLUTTER_BUILD_ARGS[@]}" \
    2>&1 | grep -Ev "^(\[|$)" | grep -v "^$" || true

  ok "Build complete"
  echo ""

  log "Step 2/2: Installing & launching via devicectl..."
  xcrun devicectl device install app \
    --device "$DEVICECTL_ID" \
    "$APP_PATH" 2>&1 | grep -Ev "^\[" || true

  ok "App installed! Launching..."
  xcrun devicectl device process launch \
    --device "$DEVICECTL_ID" \
    "com.ifthikar.wellnessapp2024" 2>&1 || \
  xcrun devicectl device process launch \
    --device "$DEVICECTL_ID" \
    "$(defaults read "$(pwd)/$APP_PATH/Info" CFBundleIdentifier 2>/dev/null || echo 'com.betterbliss.betterbliss')"

  ok "App launched on your iPhone!"
  warn "Note: Hot reload not available in this mode. Re-run ./run.sh to update."

else
  # Simulator or explicit device — standard flutter run
  FLUTTER_ARGS=(-d "$DEVICE" "--$MODE" --no-pub)
  $VERBOSE && FLUTTER_ARGS+=(--verbose)

  if $VERBOSE; then
    LOG_FILE="flutter_run_$(date +%Y%m%d_%H%M%S).log"
    log "Verbose mode — logging to: ${LOG_FILE}"
    echo ""
    flutter run "${FLUTTER_ARGS[@]}" 2>&1 | tee "$LOG_FILE"
  else
    flutter run "${FLUTTER_ARGS[@]}"
  fi
fi
