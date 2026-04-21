#!/usr/bin/env bash
# make-icon.sh — Regenerate Resources/AppIcon.icns from a master PNG.
#
# Usage: scripts/make-icon.sh [path/to/master.png]
# Default source: doc/AppIcon-master.png
# Requires: sips (macOS built-in), iconutil (macOS built-in)

set -euo pipefail

cd "$(dirname "$0")/.."

SRC="${1:-doc/AppIcon-master.png}"
if [[ ! -f "$SRC" ]]; then
    echo "ERROR: master PNG not found: $SRC" >&2
    echo "Usage: $0 path/to/master.png" >&2
    exit 1
fi

WORK="build/AppIcon.iconset"
OUT="Resources/AppIcon.icns"

rm -rf "$WORK"
mkdir -p "$WORK"

gen() { sips -s format png -z "$1" "$1" "$SRC" --out "$WORK/$2" >/dev/null; }
gen 16   icon_16x16.png
gen 32   icon_16x16@2x.png
gen 32   icon_32x32.png
gen 64   icon_32x32@2x.png
gen 128  icon_128x128.png
gen 256  icon_128x128@2x.png
gen 256  icon_256x256.png
gen 512  icon_256x256@2x.png
gen 512  icon_512x512.png
gen 1024 icon_512x512@2x.png

iconutil -c icns "$WORK" -o "$OUT"
echo "==> wrote $OUT ($(stat -f%z "$OUT") bytes)"
