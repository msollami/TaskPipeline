#!/bin/bash

# Create a simple colored icon as placeholder using ImageMagick-like approach
# We'll use macOS built-in tools to create a basic icon

# Create a temporary directory
TEMP_DIR=$(mktemp -d)

# Use Python to create a simple PNG icon
python3 << 'PYTHON'
from PIL import Image, ImageDraw, ImageFont
import os

# Create a 1024x1024 image with gradient
size = 1024
img = Image.new('RGB', (size, size))
draw = ImageDraw.Draw(img)

# Draw a gradient background (blue to purple)
for y in range(size):
    r = int(100 + (150 * y / size))
    g = int(120 - (40 * y / size))
    b = int(200 + (55 * y / size))
    draw.line([(0, y), (size, y)], fill=(r, g, b))

# Draw a clock icon (simple)
center = size // 2
radius = size // 3

# Clock circle
draw.ellipse([center - radius, center - radius, center + radius, center + radius], 
             outline='white', width=size//30, fill=None)

# Clock hands
draw.line([center, center, center, center - radius//2], fill='white', width=size//40)
draw.line([center, center, center + radius//3, center], fill='white', width=size//40)

# Save the base image
img.save('/tmp/icon_base.png')
print("Created base icon")
PYTHON

# Now resize for all required sizes
sips -z 16 16 /tmp/icon_base.png --out icon_16x16.png 2>/dev/null
sips -z 32 32 /tmp/icon_base.png --out icon_16x16@2x.png 2>/dev/null
sips -z 32 32 /tmp/icon_base.png --out icon_32x32.png 2>/dev/null
sips -z 64 64 /tmp/icon_base.png --out icon_32x32@2x.png 2>/dev/null
sips -z 128 128 /tmp/icon_base.png --out icon_128x128.png 2>/dev/null
sips -z 256 256 /tmp/icon_base.png --out icon_128x128@2x.png 2>/dev/null
sips -z 256 256 /tmp/icon_base.png --out icon_256x256.png 2>/dev/null
sips -z 512 512 /tmp/icon_base.png --out icon_256x256@2x.png 2>/dev/null
sips -z 512 512 /tmp/icon_base.png --out icon_512x512.png 2>/dev/null
sips -z 1024 1024 /tmp/icon_base.png --out icon_512x512@2x.png 2>/dev/null

echo "Icons created successfully!"
ls -la *.png

# Clean up
rm /tmp/icon_base.png
