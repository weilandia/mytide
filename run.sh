#!/bin/bash

echo "Building mytides Widget..."
swift build

if [ $? -eq 0 ]; then
    echo "Running widget..."
    swift run
else
    echo "Build failed. Please check for errors."
    exit 1
fi
