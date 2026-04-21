#!/usr/bin/env bash
# build-release.sh — Build Almond.app in Release configuration (unsigned)
#
# Prerequisites: Xcode 15+, xcodegen
# Output: build/Build/Products/Release/Almond.app

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "ERROR: xcodegen not installed. Run: brew install xcodegen" >&2
    exit 1
fi

echo "==> Generating Xcode project from project.yml"
xcodegen generate

echo "==> Building Release"
xcodebuild \
    -project Almond.xcodeproj \
    -scheme Almond \
    -configuration Release \
    -derivedDataPath ./build \
    -destination 'generic/platform=macOS' \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    clean build

APP_PATH="build/Build/Products/Release/Almond.app"
if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: build failed — $APP_PATH not produced" >&2
    exit 1
fi

echo "==> Build complete: $APP_PATH"
file "$APP_PATH/Contents/MacOS/Almond" | head -1
