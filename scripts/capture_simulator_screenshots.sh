#!/bin/bash
# Capture App Store screenshots from the booted iOS Simulator.
# Requires: Xcode Simulator frontmost, ListenToPsalm installed on booted device.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
SIMCTL="$DEVELOPER_DIR/usr/bin/simctl"
OUT_69="$ROOT/AppStoreScreenshots/iPhone-6.9-Display"
OUT_67="$ROOT/AppStoreScreenshots/iPhone-6.7-Display"
UDID="$("$SIMCTL" list devices booted | grep -oE '[A-F0-9-]{36}' | head -1)"

if [[ -z "$UDID" ]]; then
  echo "No booted simulator. Boot iPhone 17 Pro Max (or similar) first." >&2
  exit 1
fi

mkdir -p "$OUT_69" "$OUT_67"

shot() {
  local name="$1"
  local path_69="$OUT_69/$name"
  "$SIMCTL" io "$UDID" screenshot "$path_69"
  # 6.7" slot: scale from 6.9 capture (1320x2868 -> 1290x2796)
  sips -z 2796 1290 "$path_69" --out "$OUT_67/$name" >/dev/null
  echo "  $name"
}

# Tap device coordinates (1320x2868) via Simulator window — fractions of device frame
tap_device() {
  local dx="$1"
  local dy="$2"
  osascript <<APPLESCRIPT
tell application "Simulator" to activate
delay 0.35
tell application "System Events"
  tell process "Simulator"
    set frontWindow to front window
    set {wx, wy} to position of frontWindow
    set {ww, wh} to size of frontWindow
    -- Approximate device screen inset inside simulator chrome
    set insetX to 28
    set insetY to 88
    set screenW to ww - (insetX * 2)
    set screenH to wh - (insetY * 2)
    set px to wx + insetX + (screenW * ($dx / 1320.0))
    set py to wy + insetY + (screenH * ($dy / 2868.0))
    click at {px, py}
  end tell
end tell
APPLESCRIPT
  sleep 0.6
}

echo "Booted: $UDID"
echo "Saving to AppStoreScreenshots/"

# 01 — already on home (마태오)
shot "01-home-matthew.png"

# 02 — play chapter 5
tap_device 660 820
sleep 0.4
tap_device 660 1080
sleep 1.2
shot "02-playing-progress.png"

# 03 — 요한복음
tap_device 990 430
sleep 0.8
shot "03-gospel-john.png"

# 04 — 수면 타이머 시트
tap_device 1050 500
sleep 0.9
shot "04-sleep-timer.png"

# dismiss sheet
tap_device 120 520
sleep 0.5

# 05 — 마르코 + 재생
tap_device 990 320
sleep 0.5
tap_device 660 900
sleep 0.4
tap_device 660 1080
sleep 1.0
shot "05-mark-continuous.png"

echo "Done. Upload iPhone-6.9-Display/ or iPhone-6.7-Display/ to App Store Connect."
