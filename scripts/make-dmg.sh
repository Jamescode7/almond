#!/usr/bin/env bash
# make-dmg.sh — Package Almond.app into an unsigned DMG
#
# Prerequisites: scripts/build-release.sh completed successfully, create-dmg installed
# Output: dist/Almond-<version>.dmg

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v create-dmg >/dev/null 2>&1; then
    echo "SKIP: create-dmg not installed." >&2
    echo "      Run: brew install create-dmg" >&2
    exit 2
fi

APP_PATH="build/Build/Products/Release/Almond.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: $APP_PATH not found. Run ./scripts/build-release.sh first." >&2
    exit 1
fi

VERSION=$(plutil -extract CFBundleShortVersionString raw "$APP_PATH/Contents/Info.plist")
if [[ -z "$VERSION" ]]; then
    echo "ERROR: failed to read CFBundleShortVersionString" >&2
    exit 1
fi

mkdir -p dist
DMG_PATH="dist/Almond-${VERSION}.dmg"
rm -f "$DMG_PATH"

STAGING=$(mktemp -d -t almond-dmg)
trap 'rm -rf "$STAGING"' EXIT

cp -R "$APP_PATH" "$STAGING/"
cp scripts/dmg-contents/How\ to\ open.txt "$STAGING/"

echo "==> Creating DMG: $DMG_PATH"
create-dmg \
    --volname "Almond ${VERSION}" \
    --window-size 540 360 \
    --icon-size 96 \
    --icon "Almond.app" 140 170 \
    --app-drop-link 400 170 \
    --no-internet-enable \
    --skip-jenkins \
    "$DMG_PATH" \
    "$STAGING"

if [[ ! -f "$DMG_PATH" ]]; then
    echo "ERROR: DMG creation failed" >&2
    exit 1
fi

SIZE=$(stat -f %z "$DMG_PATH")
echo "==> DMG complete: $DMG_PATH (${SIZE} bytes)"
