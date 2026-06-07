#!/bin/sh
# Build a Release macOS app and install it to /Applications/ProjectHana.app.
set -e

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export DEVELOPER_DIR

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/.build-mac"

echo "==> Building ProjectHana (macOS Release)…"
"$DEVELOPER_DIR/usr/bin/xcodebuild" \
  -project "$REPO_ROOT/ProjectHana.xcodeproj" \
  -scheme ProjectHana \
  -destination 'platform=macOS,arch=arm64' \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  build 2>&1 | grep -E "^.*error:|BUILD SUCCEEDED|BUILD FAILED" | grep -v "^$" || true

APP_SRC="$BUILD_DIR/Build/Products/Release/ProjectHana.app"

if [ ! -d "$APP_SRC" ]; then
  echo "error: macOS build failed — app not found at $APP_SRC" >&2
  exit 1
fi

echo "==> Installing to /Applications/ProjectHana.app…"
rm -rf /Applications/ProjectHana.app
cp -R "$APP_SRC" /Applications/ProjectHana.app

echo "==> Installed: /Applications/ProjectHana.app"
