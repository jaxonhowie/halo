#!/bin/bash
set -e

cd "$(dirname "$0")"

APP_NAME="Halo"
BUILD_CONFIG="${1:-release}"
BUILD_DIR=".build"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"

echo "==> Building ${BUILD_CONFIG}..."
swift build -c "$BUILD_CONFIG"

BINARY="${BUILD_DIR}/$(uname -m)-apple-macosx/${BUILD_CONFIG}/${APP_NAME}"
BUNDLE="${BUILD_DIR}/$(uname -m)-apple-macosx/${BUILD_CONFIG}/${APP_NAME}_${APP_NAME}.bundle"

if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY"
    exit 1
fi

echo "==> Assembling ${APP_NAME}.app..."
rm -rf "$APP_PATH"
mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

# Copy binary
cp "$BINARY" "${APP_PATH}/Contents/MacOS/${APP_NAME}"

# Copy resource bundle
if [ -d "$BUNDLE" ]; then
    cp -R "$BUNDLE" "${APP_PATH}/Contents/Resources/"
fi

# Copy app icon
ICON_SRC="Sources/Halo/Resources/Halo.icns"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "${APP_PATH}/Contents/Resources/AppIcon.icns"
fi

# Write Info.plist
cat > "${APP_PATH}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Halo</string>
    <key>CFBundleIdentifier</key>
    <string>com.halo.desktop-pet</string>
    <key>CFBundleName</key>
    <string>Halo</string>
    <key>CFBundleDisplayName</key>
    <string>Halo</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc code sign
codesign --force --sign - "$APP_PATH" 2>/dev/null || true

echo "==> Done! ${APP_PATH}"
echo "    Run: open ${APP_PATH}"
