#!/bin/bash

echo "Creating Xcode project..."
swift package generate-xcodeproj

if [ $? -eq 0 ]; then
    echo "Opening in Xcode..."
    open TideWidget.xcodeproj
    echo ""
    echo "To run the widget:"
    echo "1. Select the TideWidget scheme in Xcode"
    echo "2. Press Cmd+R to build and run"
    echo ""
    echo "The widget will appear as a beautiful floating window showing:"
    echo "- Current tide height with negative tide indicators"
    echo "- Surf condition recommendations"
    echo "- Visual tide chart"
    echo "- Upcoming tide times"
else
    echo "Failed to generate Xcode project. You may need to install Xcode."
fi