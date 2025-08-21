#!/bin/bash

echo "Building mytides Widget for macOS..."

# Clean previous builds
rm -rf .build
rm -rf ~/Library/Widgets/SantaCruzTides.widgetExtension
rm -rf ~/Library/Widgets/mytides.widgetextension

# Build the widget
swift build -c release --product TideWidget

# Create widget bundle structure
WIDGET_DIR="mytides.widgetextension"
rm -rf "$WIDGET_DIR"
mkdir -p "$WIDGET_DIR/Contents/MacOS"
mkdir -p "$WIDGET_DIR/Contents/Resources"

# Copy the executable
cp .build/release/TideWidget "$WIDGET_DIR/Contents/MacOS/mytides"

# Create Info.plist for the widget extension
cat > "$WIDGET_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.mytides.widget</string>
    <key>CFBundleName</key>
    <string>mytides</string>
    <key>CFBundleDisplayName</key>
    <string>mytides</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
        <key>NSExtensionPrincipalClass</key>
        <string>TideWidget</string>
    </dict>
    <key>CFBundleExecutable</key>
    <string>mytides</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF

# Copy to user's widget directory
echo "Installing widget to ~/Library/Widgets/..."
mkdir -p ~/Library/Widgets/
cp -R "$WIDGET_DIR" ~/Library/Widgets/

echo "Widget installed successfully!"
echo ""
echo "To add the widget to your desktop:"
echo "1. Right-click on your desktop"
echo "2. Select 'Edit Widgets'"
echo "3. Search for 'mytides'"
echo "4. Click the '+' button to add it"
echo "5. Choose your preferred size (Small, Medium, or Large)"
echo ""
echo "Note: You may need to restart the WidgetKit service:"
echo "killall WidgetKitExtension"
