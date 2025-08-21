#!/bin/bash

echo "Building mytides widget with Xcode..."

# Clean previous builds
rm -rf ~/Library/Widgets/mytides.widgetextension
rm -rf build
rm -rf DerivedData

# Build using xcodebuild
xcodebuild -project mytides.xcodeproj \
           -scheme TideWidgetExtension \
           -configuration Release \
           -derivedDataPath DerivedData \
           CODE_SIGN_IDENTITY="-" \
           CODE_SIGNING_REQUIRED=NO \
           build

# Find the built widget
WIDGET_PATH=$(find DerivedData -name "*.widgetextension" -type d | head -1)

if [ -z "$WIDGET_PATH" ]; then
    echo "Error: Widget extension not found in build output"
    exit 1
fi

echo "Found widget at: $WIDGET_PATH"

# Copy to Library/Widgets
echo "Installing widget..."
cp -R "$WIDGET_PATH" ~/Library/Widgets/

# Restart WidgetKit
killall WidgetKitExtension 2>/dev/null

echo "Widget installed successfully!"
echo ""
echo "To add the widget:"
echo "1. Right-click on desktop"
echo "2. Select 'Edit Widgets'"
echo "3. Search for 'mytides'"
echo "4. Add the widget"