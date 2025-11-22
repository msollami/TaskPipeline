# Screenshot Automation Scripts

Automated screenshot capture for TaskPipeline App Store submissions.

## Quick Start

### Automated Screenshot Generation

```bash
./scripts/take_screenshots.sh
```

This script will:
1. ✅ Launch TaskPipeline
2. 📸 Capture 5 different app states automatically
3. 💾 Save screenshots to Desktop with timestamp
4. 🎯 Open the screenshot folder when done

**Requirements:**
- TaskPipeline must be built in Debug mode first
- Grant Terminal/Script Editor accessibility permissions in System Preferences

### Manual Screenshot Capture

If you prefer more control, use the manual script:

```bash
./scripts/capture_current_state.sh
```

This captures the current window state on demand. Run it multiple times as you manually navigate the app.

## Screenshot States Captured

1. **Empty State** - Clean interface with no tasks
2. **With Tasks** - Pipeline editor with 3 sample tasks
3. **Running State** - Active timer with timeline view
4. **Paused State** - Paused timer with "PAUSED" indicator
5. **Completion State** - Session complete summary

## Accessibility Permissions

First time running, you'll need to grant permissions:

1. Open **System Preferences** → **Privacy & Security** → **Accessibility**
2. Click the lock to make changes
3. Add and enable:
   - Terminal (or your terminal app)
   - Script Editor
   - TaskPipeline

## Customization

### Change Screenshot Size

For App Store submissions, Apple requires specific sizes:
- 1280x800 (standard)
- 1440x900 (retina)
- 2560x1600 (high res)

Add padding to screenshots:
```bash
# Add 40px padding around screenshot
sips -p 2640 1720 --padColor FFFFFF screenshot.png
```

### Edit the Script

Open `take_screenshots.sh` to customize:
- **Timing**: Adjust `sleep` durations between actions
- **Tasks**: Change the sample task names and durations
- **States**: Add or remove screenshot captures

## Tips

- 🎨 **Background**: Change your desktop wallpaper to showcase the app on different backgrounds
- ⏱️ **Timing**: If screenshots capture mid-animation, increase sleep delays
- 🔄 **Retry**: Run the script multiple times to get perfect shots
- ✂️ **Crop**: Use Preview or another tool to crop/adjust afterwards

## Troubleshooting

**"Cannot find TaskPipeline.app"**
- Build the project in Xcode first (⌘B)

**Screenshots are black**
- Grant Screen Recording permission to Terminal

**Script stops responding**
- The app window might not be focused
- Manually click the app window and try again

**Wrong window captured**
- Make sure only one TaskPipeline window is open
- Close other windows and try again

## Advanced: App Store Screenshots

For official App Store submissions:

1. Run the script to generate base screenshots
2. Add marketing overlays in Figma/Photoshop:
   - App title and tagline
   - Feature highlights
   - Call-to-action text
3. Export at required sizes (see Apple's guidelines)
4. Upload to App Store Connect

## Alternative: Fastlane

For fully automated App Store screenshots with different device sizes:

```bash
# Install fastlane
brew install fastlane

# Setup
fastlane snapshot init

# Configure Snapfile and run
fastlane snapshot
```
