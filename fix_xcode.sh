#!/bin/bash

echo "Fixing Xcode Command Line Tools..."

# Remove old command line tools
sudo rm -rf /Library/Developer/CommandLineTools

# Reinstall command line tools
xcode-select --install

echo "Please follow the installation dialog that appears."
echo "After installation completes, run:"
echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
echo "  sudo xcodebuild -license accept"
echo ""
echo "Then try building the widget again with:"
echo "  ./build_widget.sh"