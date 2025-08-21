#!/bin/bash

echo "Building mytides app with embedded widget..."

# Clean
rm -rf ~/Applications/mytides.app
rm -rf mytides.app

# Build the widget
swift build -c release --product TideWidget

# Create app bundle structure
APP_DIR="mytides.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$APP_DIR/Contents/PlugIns"

# Create a minimal launcher app
cat > "$APP_DIR/Contents/MacOS/mytides" << 'EOF'
#!/bin/bash
echo "mytides widget is installed. Please add it through the widget gallery."
osascript -e 'display notification "Widget installed! Right-click desktop and select Edit Widgets to add it." with title "mytides"'
EOF

chmod +x "$APP_DIR/Contents/MacOS/mytides"

# Create app Info.plist
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.mytides.app</string>
    <key>CFBundleName</key>
    <string>mytides</string>
    <key>CFBundleDisplayName</key>
    <string>mytides</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>mytides</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.weather</string>
</dict>
</plist>
EOF

# Create widget extension bundle
WIDGET_DIR="$APP_DIR/Contents/PlugIns/mytides.widgetextension"
mkdir -p "$WIDGET_DIR/Contents/MacOS"
mkdir -p "$WIDGET_DIR/Contents/Resources"

# Copy widget executable
cp .build/release/TideWidget "$WIDGET_DIR/Contents/MacOS/mytides"

# Create widget Info.plist
cat > "$WIDGET_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.mytides.app.widget</string>
    <key>CFBundleName</key>
    <string>mytides Widget</string>
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
    </dict>
    <key>CFBundleExecutable</key>
    <string>mytides</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF

# Move to Applications folder
echo "Installing to ~/Applications..."
mkdir -p ~/Applications
cp -R "$APP_DIR" ~/Applications/

# Clean up
rm -rf "$APP_DIR"

echo "Installation complete!"
echo ""
echo "The app has been installed to ~/Applications/mytides.app"
echo ""
echo "To add the widget:"
echo "1. The widget should now appear in the widget gallery"
echo "2. Right-click on your desktop"
echo "3. Select 'Edit Widgets'"
echo "4. Search for 'mytides'"
echo "5. Add the widget in your preferred size"
echo ""
echo "If the widget doesn't appear, try:"
echo "1. Open the mytides app once from ~/Applications"
echo "2. Restart your Mac"