#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Mapping"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"

cd "$PROJECT_DIR"

# Keep the checked-in Xcode project in sync with project.yml.
echo "⚙️  Generating Xcode project..."
xcodegen generate

# Build
echo "🔨 Building $APP_NAME..."
xcodebuild -project "$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
    -quiet

echo "✅ Build succeeded: $APP_PATH"

# Install to /Applications if --install flag
if [ "$1" = "--install" ]; then
    echo "📦 Installing to /Applications..."
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP_PATH" "/Applications/$APP_NAME.app"
    echo "✅ Installed to /Applications/$APP_NAME.app"
fi

# Run if --run flag
if [ "$1" = "--run" ] || [ "$2" = "--run" ]; then
    echo "🚀 Launching $APP_NAME..."
    open "$APP_PATH"
fi
