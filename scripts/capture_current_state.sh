#!/bin/bash

# Simple screenshot capture for TaskPipeline
# Captures the current state of the frontmost TaskPipeline window

SCREENSHOT_DIR="$HOME/Desktop/TaskPipeline_Screenshots"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"

# Capture screenshot
screencapture -x -o -l $(osascript -e 'tell application "TaskPipeline" to id of window 1') \
    "$SCREENSHOT_DIR/screenshot_${TIMESTAMP}.png"

echo "✅ Screenshot saved: screenshot_${TIMESTAMP}.png"
echo "📁 Location: $SCREENSHOT_DIR"

# Optional: Open the file
open "$SCREENSHOT_DIR/screenshot_${TIMESTAMP}.png"
