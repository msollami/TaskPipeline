# App Icon Setup

This folder requires the following icon sizes for macOS:

## Required Icon Files:
- `icon_16x16.png` - 16×16 pixels
- `icon_16x16@2x.png` - 32×32 pixels
- `icon_32x32.png` - 32×32 pixels
- `icon_32x32@2x.png` - 64×64 pixels
- `icon_128x128.png` - 128×128 pixels
- `icon_128x128@2x.png` - 256×256 pixels
- `icon_256x256.png` - 256×256 pixels
- `icon_256x256@2x.png` - 512×512 pixels
- `icon_512x512.png` - 512×512 pixels
- `icon_512x512@2x.png` - 1024×1024 pixels

## Design Suggestions:
For a TaskTimer app, consider:
- A clock or timer icon
- Gradient colors matching your app's theme
- Simple, recognizable design
- Works well at small sizes (16×16)

## Tools to Create Icons:
1. **Icon Composer** (built into Xcode)
2. **SF Symbols** - Export as PNG
3. **Figma/Sketch** - Design and export at multiple sizes
4. **Online tools** - Like appicon.co or makeappicon.com
5. **ImageMagick** - Command line tool to resize a master icon

## Quick Generation (if you have a 1024×1024 source):
```bash
# Install ImageMagick first: brew install imagemagick
sips -z 16 16 source.png --out icon_16x16.png
sips -z 32 32 source.png --out icon_16x16@2x.png
sips -z 32 32 source.png --out icon_32x32.png
sips -z 64 64 source.png --out icon_32x32@2x.png
sips -z 128 128 source.png --out icon_128x128.png
sips -z 256 256 source.png --out icon_128x128@2x.png
sips -z 256 256 source.png --out icon_256x256.png
sips -z 512 512 source.png --out icon_256x256@2x.png
sips -z 512 512 source.png --out icon_512x512.png
sips -z 1024 1024 source.png --out icon_512x512@2x.png
```
