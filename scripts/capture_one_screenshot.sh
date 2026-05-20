#!/bin/bash
# Capture one App Store screenshot from the booted simulator.
# Usage: ./scripts/capture_one_screenshot.sh 02-playing-progress.png
# Set up the screen in Simulator first, then run this script.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <filename.png>" >&2
  echo "Example: $0 02-playing-progress.png" >&2
  exit 1
fi

NAME="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
SIMCTL="$DEVELOPER_DIR/usr/bin/simctl"
OUT_69="$ROOT/AppStoreScreenshots/iPhone-6.9-Display"
OUT_67="$ROOT/AppStoreScreenshots/iPhone-6.7-Display"
UDID="$("$SIMCTL" list devices booted | grep -oE '[A-F0-9-]{36}' | head -1)"

if [[ -z "$UDID" ]]; then
  echo "No booted simulator." >&2
  exit 1
fi

mkdir -p "$OUT_69" "$OUT_67"
"$SIMCTL" io "$UDID" screenshot "$OUT_69/$NAME"
sips -z 2796 1290 "$OUT_69/$NAME" --out "$OUT_67/$NAME" >/dev/null
echo "Saved:"
echo "  $OUT_69/$NAME"
echo "  $OUT_67/$NAME  (scaled for 6.7\" display)"
