#!/bin/bash

# Generate all required macOS icon sizes from a 1024x1024 source image
# Usage: ./generate_all_icons.sh path/to/source_icon.png

set -e

SOURCE_IMAGE="$1"
OUTPUT_DIR="TaskPipeline/Assets.xcassets/AppIcon.appiconset"

if [ -z "$SOURCE_IMAGE" ]; then
    echo "Usage: $0 <source_icon.png>"
    echo "Example: $0 ~/Downloads/new_icon.png"
    exit 1
fi

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found: $SOURCE_IMAGE"
    exit 1
fi

echo "🎨 Generating macOS app icons from: $SOURCE_IMAGE"
echo ""

# Function to generate icon at specific size
generate_icon() {
    local size=$1
    local filename=$2
    echo "  ✓ Generating $filename (${size}x${size})"
    sips -z $size $size "$SOURCE_IMAGE" --out "$OUTPUT_DIR/$filename" > /dev/null 2>&1
}

# Generate all required sizes
generate_icon 16 "icon_16x16.png"
generate_icon 32 "icon_16x16@2x.png"
generate_icon 32 "icon_32x32.png"
generate_icon 64 "icon_32x32@2x.png"
generate_icon 128 "icon_128x128.png"
generate_icon 256 "icon_128x128@2x.png"
generate_icon 256 "icon_256x256.png"
generate_icon 512 "icon_256x256@2x.png"
generate_icon 512 "icon_512x512.png"
generate_icon 1024 "icon_512x512@2x.png"

# Also save the 1024x1024 for App Store submissions
cp "$SOURCE_IMAGE" "icon_1024x1024.png"
echo "  ✓ Saved 1024x1024 for App Store: icon_1024x1024.png"

echo ""
echo "✅ All icons generated successfully!"
echo "📁 Location: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "1. Clean build folder in Xcode (Product → Clean Build Folder)"
echo "2. Rebuild the project"
echo "3. Check that the icon looks correct in the asset catalog"
