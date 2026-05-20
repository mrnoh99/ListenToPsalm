#!/bin/bash
# Scale 6.9" screenshots to 6.7" App Store size.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/AppStoreScreenshots/iPhone-6.9-Display"
DST="$ROOT/AppStoreScreenshots/iPhone-6.7-Display"
mkdir -p "$DST"
for f in "$SRC"/*.png; do
  [[ -f "$f" ]] || continue
  sips -z 2796 1290 "$f" --out "$DST/$(basename "$f")" >/dev/null
  echo "  $(basename "$f")"
done
