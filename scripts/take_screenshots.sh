#!/bin/bash

# Automated Screenshot Generator for TaskPipeline
# This script captures screenshots of the app in various states

set -e

# Configuration
APP_NAME="TaskPipeline"
APP_PATH="$HOME/Library/Developer/Xcode/DerivedData/TaskPipeline-*/Build/Products/Debug/TaskPipeline.app"
SCREENSHOT_DIR="$HOME/Desktop/TaskPipeline_Screenshots_$(date +%Y%m%d_%H%M%S)"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📸 TaskPipeline Screenshot Generator${NC}"
echo ""

# Create screenshot directory
mkdir -p "$SCREENSHOT_DIR"
echo -e "${GREEN}✓${NC} Created screenshot directory: $SCREENSHOT_DIR"

# Find the app
APP_FULL_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "TaskPipeline.app" -path "*/Debug/*" | head -1)

if [ -z "$APP_FULL_PATH" ]; then
    echo "❌ Could not find TaskPipeline.app. Please build the project first."
    exit 1
fi

echo -e "${GREEN}✓${NC} Found app at: $APP_FULL_PATH"

# Kill any running instances
killall TaskPipeline 2>/dev/null || true
sleep 1

# Launch the app
echo -e "${BLUE}▶${NC}  Launching TaskPipeline..."
open "$APP_FULL_PATH"
sleep 3

# Function to take a screenshot
take_screenshot() {
    local name=$1
    local delay=$2
    sleep "$delay"
    screencapture -x -o -l $(osascript -e 'tell application "TaskPipeline" to id of window 1') "$SCREENSHOT_DIR/${name}.png"
    echo -e "${GREEN}✓${NC} Captured: ${name}.png"
}

# Function to click menu bar item
click_menu_bar() {
    osascript <<EOF
tell application "System Events"
    tell process "TaskPipeline"
        click menu bar item 1 of menu bar 1
    end tell
end tell
EOF
}

echo ""
echo -e "${BLUE}📸 Capturing screenshots...${NC}"
echo ""

# Screenshot 1: Empty state
echo "1️⃣  Empty state..."
click_menu_bar
sleep 1
take_screenshot "01_empty_state" 0.5

# Screenshot 2: Adding tasks
echo "2️⃣  Adding tasks..."
osascript <<EOF
tell application "System Events"
    tell process "TaskPipeline"
        -- Type task name
        keystroke "Review design mockups"
        delay 0.5
        -- Tab to duration field (or click Add)
        key code 48 -- Tab key
        delay 0.3
        keystroke "15"
        delay 0.3
        -- Click Add button
        click button "Add" of window 1
        delay 1

        -- Add second task
        keystroke "Write implementation code"
        delay 0.5
        key code 48
        delay 0.3
        keystroke "45"
        delay 0.3
        click button "Add" of window 1
        delay 1

        -- Add third task
        keystroke "Test and debug"
        delay 0.5
        key code 48
        delay 0.3
        keystroke "30"
        delay 0.3
        click button "Add" of window 1
        delay 1
    end tell
end tell
EOF

take_screenshot "02_with_tasks" 0.5

# Screenshot 3: Running state
echo "3️⃣  Running state..."
osascript <<EOF
tell application "System Events"
    tell process "TaskPipeline"
        click button "Start Pipeline" of window 1
        delay 2
    end tell
end tell
EOF

take_screenshot "03_running_state" 0.5

# Screenshot 4: Paused state
echo "4️⃣  Paused state..."
osascript <<EOF
tell application "System Events"
    tell process "TaskPipeline"
        click button 1 of window 1 -- Pause button
        delay 1
    end tell
end tell
EOF

take_screenshot "04_paused_state" 0.5

# Screenshot 5: Skip to completion
echo "5️⃣  Completion state..."
osascript <<EOF
tell application "System Events"
    tell process "TaskPipeline"
        -- Resume first
        click button 1 of window 1
        delay 0.5
        -- Skip tasks to get to completion
        click button 2 of window 1 -- Skip button
        delay 1
        click button 2 of window 1
        delay 1
        click button 2 of window 1
        delay 1
    end tell
end tell
EOF

take_screenshot "05_completion_state" 1

echo ""
echo -e "${GREEN}✅ Done!${NC}"
echo ""
echo "Screenshots saved to:"
echo "$SCREENSHOT_DIR"
echo ""
echo "Opening screenshot directory..."
open "$SCREENSHOT_DIR"
