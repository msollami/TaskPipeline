#!/bin/bash

# Generate placeholder icons with gradient background
# These are temporary - replace with actual designed icons

# Create a base 1024x1024 icon using ImageMagick or simple colored background
# For now, we'll create simple placeholder using macOS built-in tools

echo "To generate icons, you need a 1024x1024 source image."
echo "Place it in this folder as 'source.png' and run:"
echo ""
echo "sips -z 16 16 source.png --out icon_16x16.png"
echo "sips -z 32 32 source.png --out icon_16x16@2x.png"
echo "sips -z 32 32 source.png --out icon_32x32.png"
echo "sips -z 64 64 source.png --out icon_32x32@2x.png"
echo "sips -z 128 128 source.png --out icon_128x128.png"
echo "sips -z 256 256 source.png --out icon_128x128@2x.png"
echo "sips -z 256 256 source.png --out icon_256x256.png"
echo "sips -z 512 512 source.png --out icon_256x256@2x.png"
echo "sips -z 512 512 source.png --out icon_512x512.png"
echo "sips -z 1024 1024 source.png --out icon_512x512@2x.png"
echo ""
echo "Or use online tools like:"
echo "- https://www.appicon.co"
echo "- https://makeappicon.com"
echo "- https://icon.kitchen"
