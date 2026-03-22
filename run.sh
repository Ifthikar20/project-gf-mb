#!/bin/bash
# Launch the Flutter app with full verbose logging.
# Usage: ./run.sh

set -e

echo "=== Launching Great Feel (Flutter) with full logs ==="
echo "Timestamp: $(date)"
echo ""

flutter run --verbose 2>&1 | tee "flutter_run_$(date +%Y%m%d_%H%M%S).log"
