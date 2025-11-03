# Task Timer

A native macOS menubar app for managing sequential countdown timers with a focus-driven interface. Create a pipeline of tasks, then enter "focus mode" to work through them one at a time with prominent reminders of what you should be working on.

Inspired by the Wolfram Language [TimerTable](https://resources.wolframcloud.com/FunctionRepository/resources/TimerTable/) function.

## Features

### Pipeline Editor Mode
- **Easy Task Management**: Add, edit, reorder, and delete tasks
- **Inline Editing**: Click pencil icon to edit task name and duration
- **Drag-and-Drop Reordering**: Rearrange tasks in your pipeline
- **Total Time Display**: See total duration across all tasks
- **Visual Pipeline**: Numbered list showing your task sequence

### Focus Mode
- **Prominent Focus Message**: Large "Right now, focus only on: [TASK NAME]" display
- **Big Countdown Timer**: Can't miss the time remaining
- **Progress Indicator**: Visual progress bar for current task
- **Next Task Preview**: See what's coming up next
- **Quick Controls**: Pause, Skip, or Stop at any time
- **Audio Notifications**: System beep when each task completes

### Menubar Integration
- Lives in your menubar for quick access
- Icon changes when timer is running
- No dock icon - stays out of your way

## Workflow

### 1. Build Your Pipeline (Edit Mode)

Click the menubar icon to open the app. You'll see the Pipeline Editor:

- **Add Tasks**: Click "Add Task" and enter name and duration
- **Edit Tasks**: Click the pencil icon to modify any task
- **Reorder**: Drag and drop tasks to rearrange them
- **Delete**: Click the trash icon to remove tasks
- **Review**: See your complete pipeline with total time

### 2. Start Focus Mode

Click "Start Pipeline" to enter focus mode. The interface transforms to show:

- **Big focus message**: "Right now, focus only on: [CURRENT TASK]"
- **Large countdown**: Remaining time in large, easy-to-read digits
- **Progress bar**: Visual indication of task progress
- **Next preview**: Small preview of what's coming next

### 3. Work Through Tasks

- Tasks automatically advance when time expires
- System beep plays between tasks
- Skip tasks if needed with the "Skip" button
- Pause/resume as needed
- Stop to return to pipeline editor

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building from source)

## Installation

### Building from Source

1. Clone or download this repository
2. Open `TaskTimer.xcodeproj` in Xcode
3. Build and run the project (⌘R)

The app will appear in your menubar.

## Usage Examples

### Example 1: Pomodoro-style Work Session
```
1. Deep Work Session → 25 min
2. Short Break → 5 min
3. Deep Work Session → 25 min
4. Short Break → 5 min
5. Deep Work Session → 25 min
6. Long Break → 15 min
```

### Example 2: Meeting Agenda
```
1. Introductions → 5 min
2. Project Updates → 15 min
3. Q&A Discussion → 20 min
4. Action Items → 10 min
```

### Example 3: Study Session
```
1. Review Notes → 15 min
2. Practice Problems → 30 min
3. Break → 10 min
4. Flashcards → 20 min
```

## Keyboard Tips

While in the app:
- **Enter**: Saves task edits
- **Esc**: Cancels task edits
- **Tab**: Navigate between fields

## Project Structure

```
TaskTimer/
├── TaskTimerApp.swift              # Main app entry point
├── AppDelegate.swift               # Menubar app lifecycle
├── Models/
│   ├── Task.swift                 # Task data model
│   └── TimerManager.swift         # Timer logic and state
├── Views/
│   ├── ContentView.swift          # Mode switcher (edit/run)
│   ├── FocusedTaskView.swift     # Focus mode display
│   ├── EditableTaskRowView.swift # Editable task row
│   ├── TaskRowView.swift         # Task display component
│   └── AddTaskView.swift         # Add task modal
└── Assets.xcassets/              # App icons and assets
```

## Architecture

### Two-Mode Interface

**Edit Mode (Pipeline Editor)**
- Full list of all tasks
- Inline editing capabilities
- Drag-and-drop reordering
- Add/remove tasks
- Shows total pipeline duration

**Run Mode (Focus View)**
- Shows ONLY current task
- Large, prominent display
- Focus message: "Right now, focus only on: [TASK]"
- Big countdown timer
- Next task preview at bottom

### Key Components

**TimerManager** (`TimerManager.swift:11`)
- Observable object managing timer state
- Handles countdown logic (1-second intervals)
- Automatic sequential task progression
- Skip, pause, resume, reset functionality
- Status change callbacks for menubar icon

**FocusedTaskView** (`FocusedTaskView.swift:11`)
- Dedicated focus mode interface
- Large typography for current task
- 72pt countdown timer display
- Next task preview section
- Pause/Skip/Stop controls

**EditableTaskRowView** (`EditableTaskRowView.swift:11`)
- Inline editing of task properties
- Edit/display mode toggling
- Drag handle for reordering
- Delete button

## Customization

### Change Countdown Display Size

Edit `FocusedTaskView.swift:40`:
```swift
.font(.system(size: 72, weight: .bold, design: .rounded))
```

### Modify Focus Message

Edit `FocusedTaskView.swift:29`:
```swift
Text("Right now, focus only on:")
```

### Adjust Audio Notification

Edit `TimerManager.swift:159`:
```swift
private func playCompletionSound() {
    NSSound.beep() // Replace with custom sound
}
```

### Change Window Size

Edit `ContentView.swift:24`:
```swift
.frame(minWidth: 500, minHeight: 400)
```

## Features in Detail

### Inline Editing
- Click pencil icon on any task
- Edit name and duration fields
- Save with "Done" or cancel with "Cancel"
- Changes take effect immediately

### Drag-and-Drop
- Click and hold on the drag handle (≡)
- Drag task to new position
- Drop to reorder
- Disabled during running mode

### Skip Functionality
- Marks current task as completed
- Immediately advances to next task
- Useful for completed tasks or changes in plans

### Next Task Preview
- Shows upcoming task name and duration
- Helps maintain context
- Disappears on final task

## Known Limitations

- No task persistence (tasks cleared on app quit)
- Cannot edit tasks while timer is running
- Cannot reorder tasks while timer is running
- Single pipeline only (no multiple saved pipelines)
- No time tracking/statistics

## Future Enhancements

Potential features for future versions:

- [ ] Task persistence (save/load pipelines)
- [ ] Multiple saved pipelines
- [ ] Import/export pipeline templates
- [ ] Custom audio sounds
- [ ] Spoken task announcements
- [ ] Keyboard shortcuts for controls
- [ ] Session history and time tracking
- [ ] Desktop notifications
- [ ] Full-screen focus mode option
- [ ] Break reminders
- [ ] Task notes/descriptions

## Tips for Effective Use

1. **Plan Before You Start**: Build your complete pipeline before starting
2. **Be Realistic**: Set achievable time durations for each task
3. **Use Clear Names**: Write task names that clearly state the goal
4. **Review Next Task**: Check the preview to mentally prepare
5. **Don't Fight It**: If you need to skip, skip - the tool serves you
6. **Regular Breaks**: Build in break tasks for longer sessions

## License

This project is provided as-is for educational and personal use.

## Credits

Inspired by the Wolfram Language [TimerTable](https://resources.wolframcloud.com/FunctionRepository/resources/TimerTable/) function.

Built with SwiftUI for macOS.
