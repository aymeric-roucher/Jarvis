#!/bin/bash

APP_NAME="Jarvis"
SCHEME_NAME="Jarvis"
BUILD_DIR=".build_xcode"
APP_BUNDLE="$APP_NAME.app"

echo "Building $APP_NAME using xcodebuild..."

# Clear previous app settings to ensure onboarding runs for testing purposes
echo "Clearing previous app settings for a fresh run..."
defaults delete com.aymeric.Jarvis || true # '|| true' prevents script from failing if settings don't exist
# Truncate in-app log for clean runs
: > Jarvis_Log.txt

rm -rf "$BUILD_DIR"
rm -rf "$APP_BUNDLE"

echo "Building via swift build (release)..."
swift build -c release
if [ $? -ne 0 ]; then
    echo "Build failed."
    exit 1
fi

echo "Creating App Bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Locate the built executable
# swift build puts binaries in .build/release
BINARY_PATH=".build/release/$APP_NAME"

if [ -z "$BINARY_PATH" ]; then
    echo "Could not find compiled binary."
    exit 1
fi

echo "Found binary at: $BINARY_PATH"
cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.aymeric.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/> <!-- Agent app, no dock icon -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Jarvis needs your microphone to listen to your commands.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Jarvis needs to control other applications to execute commands.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>Jarvis needs accessibility permissions to type text for you.</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.aymeric.Jarvis</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>jarvis</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# Ad-hoc signing
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Done! You can run: open $APP_BUNDLE"
