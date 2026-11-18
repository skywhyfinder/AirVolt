#!/bin/bash
set -e

echo "🚀 Building AirVolt for macOS (Release)..."
cd "$(dirname "$0")/.."

swift build -c release

APP_NAME="AirVolt.app"
APP_DIR="build/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Assembling $APP_NAME bundle..."
rm -rf build
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp .build/release/AirVolt "$MACOS_DIR/AirVolt"

# Copy Info.plist
cp Resources/Info.plist "$CONTENTS_DIR/Info.plist"

# Ad-hoc code sign for local running
codesign --force --deep --sign - "$APP_DIR"

echo "✅ Successfully built $APP_DIR"
echo "🗜 Creating zip archive for GitHub Releases..."
(cd build && zip -r "AirVolt-macOS-v1.0.0.zip" "$APP_NAME")
echo "🎉 Done! Bundle available at build/AirVolt.app and build/AirVolt-macOS-v1.0.0.zip"
