#!/bin/sh
# Build a Release macOS app and install it to /Applications/Hanahuac.app.
set -e

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
export DEVELOPER_DIR

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$REPO_ROOT/.build-mac"
LOG="/tmp/hanahuac-mac-build.log"

echo "==> Building Hanahuac (macOS Release)…"
if "$DEVELOPER_DIR/usr/bin/xcodebuild" \
  -project "$REPO_ROOT/Hanahuac.xcodeproj" \
  -scheme Hanahuac \
  -destination 'platform=macOS,arch=arm64' \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  build > "$LOG" 2>&1; then
  echo "    Build succeeded."
else
  grep -E "error:" "$LOG" | head -20
  echo "error: macOS build failed — full log at $LOG" >&2
  exit 1
fi

APP_SRC="$BUILD_DIR/Build/Products/Release/Hanahuac.app"

if [ ! -d "$APP_SRC" ]; then
  echo "error: app not found at $APP_SRC" >&2
  exit 1
fi

echo "==> Installing to /Applications/Hanahuac.app…"
rm -rf /Applications/Hanahuac.app
cp -R "$APP_SRC" /Applications/Hanahuac.app

echo "==> Installed: /Applications/Hanahuac.app"
