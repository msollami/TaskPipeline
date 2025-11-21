//
//  ContentView.swift
//  TaskPipeline
//
//  Main view that switches between edit and running modes
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var pipelineManager: PipelineManager

    var body: some View {
        Group {
            if timerManager.isCompleted {
                // Completion view - session finished
                CompletionView(timerManager: timerManager)
                    .frame(minWidth: 450, idealWidth: 480, maxWidth: 550, minHeight: 200, idealHeight: 250, maxHeight: 400)
            } else if timerManager.isRunning {
                // Running mode - show focused view (compact)
                FocusedTaskView(timerManager: timerManager)
                    .frame(minWidth: 500, minHeight: 95)
            } else {
                // Edit mode - timeline-based editor
                TimelineEditorView(timerManager: timerManager, pipelineManager: pipelineManager)
                    .frame(minWidth: 600, idealHeight: 300, maxHeight: 600)
            }
        }
    }
}

// MARK: - Timeline Editor View

struct TimelineEditorView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var pipelineManager: PipelineManager
    @State private var totalMinutesText: String = ""
    @State private var showPipelineLibrary: Bool = false
    @State private var showSavePipeline: Bool = false
    @State private var newPipelineName: String = ""
    @State private var lockTotalTime: Bool = false
    @AppStorage("defaultBreakDuration") private var breakDurationMinutes: Double = 0.0
    @State private var breakDurationText: String = "0"
    @State private var useDoneByTime: Bool = false
    @State private var doneByTimeText: String = "12:00AM"
    @FocusState private var isBreakFieldFocused: Bool
    @FocusState private var isTotalFieldFocused: Bool
    @FocusState private var isDoneByFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                // Title
                Text("Task Pipeline")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))

                // Menu button with Settings, About, and Quit
                Menu {
                    Button("Settings...") {
                        NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                    }

                    Button("About TaskPipeline") {
                        NotificationCenter.default.post(name: NSNotification.Name("OpenAbout"), object: nil)
                    }

                    Divider()

                    Button("Quit TaskPipeline") {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Menu")

                Spacer()

                // Right: Total time control
                HStack(spacing: 8) {
                    // Break duration control
                    Text("Break\nLength:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize()

                    VStack(alignment: .center, spacing: 2) {
                        TextField("", text: $breakDurationText)
                            .textFieldStyle(.plain)
                            .font(.caption)
                            .fontWeight(isBreakFieldFocused ? .semibold : .medium)
                            .foregroundColor(isBreakFieldFocused ? .primary : .secondary)
                            .frame(width: 25)
                            .multilineTextAlignment(.center)
                            .focused($isBreakFieldFocused)
                            .onSubmit {
                                if let value = Double(breakDurationText), value >= 0 {
                                    breakDurationMinutes = value
                                    rebuildTasksWithBreaks()

                                    // Update total time after rebuild
                                    let newTotal = timerManager.tasks.reduce(0.0) { $0 + $1.durationMinutes }
                                    timerManager.setTargetTotalMinutes(newTotal)
                                }
                                breakDurationText = "\(Int(breakDurationMinutes))"
                                isBreakFieldFocused = false
                            }

                        Text("min")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    Divider()
                        .frame(height: 20)
                    Text("Total\nTime:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize()

                    VStack(alignment: .center, spacing: 2) {
                        TextField("", text: $totalMinutesText)
                            .textFieldStyle(.plain)
                            .font(.caption)
                            .fontWeight(isTotalFieldFocused ? .semibold : .medium)
                            .foregroundColor(isTotalFieldFocused ? .primary : .secondary)
                            .frame(width: 30)
                            .multilineTextAlignment(.center)
                            .focused($isTotalFieldFocused)
                            .onSubmit {
                                if let newTotalMinutes = Double(totalMinutesText), newTotalMinutes > 0 {
                                    // Calculate how many breaks will be added
                                    let nonBreakTasks = timerManager.tasks.filter { !$0.isBreak }
                                    let breakCount = max(0, nonBreakTasks.count - 1)
                                    let totalBreakTime = Double(breakCount) * breakDurationMinutes

                                    // Subtract break time from total to get available time for tasks
                                    let availableTaskTime = max(1, newTotalMinutes - totalBreakTime)
                                    timerManager.setTargetTotalMinutes(availableTaskTime)

                                    // Rebuild with breaks to apply the new total
                                    rebuildTasksWithBreaks()
                                }
                                // Display actual total including breaks
                                let actualTotal = timerManager.tasks.reduce(0.0) { $0 + $1.durationMinutes }
                                totalMinutesText = "\(Int(actualTotal))"
                                isTotalFieldFocused = false
                            }
                            .onChange(of: timerManager.targetTotalMinutes) { newValue in
                                if !isTotalFieldFocused {
                                    // Display actual total including breaks
                                    let actualTotal = timerManager.tasks.reduce(0.0) { $0 + $1.durationMinutes }
                                    totalMinutesText = "\(Int(actualTotal))"
                                }
                            }

                        Text("min")
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    Divider()
                        .frame(height: 20)

                    // Done by time control
                    Text("Done\nBy:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize()

                    TextField("", text: $doneByTimeText)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .fontWeight(isDoneByFieldFocused ? .semibold : .medium)
                        .foregroundColor(isDoneByFieldFocused ? .primary : .secondary)
                        .frame(width: 50)
                        .multilineTextAlignment(.trailing)
                        .focused($isDoneByFieldFocused)
                        .onSubmit {
                            applyDoneByTimeChange()
                            isDoneByFieldFocused = false
                        }
                }
            }
            .padding()

            Divider()

            VStack(spacing: 12) {
                if timerManager.tasks.isEmpty {
                    emptyStateView
                        .padding(.top, 12)
                } else {
                    // Interactive Timeline Bar - PRIMARY VISUAL
                    InteractiveTimelineBar(timerManager: timerManager, lockTotalTime: $lockTotalTime)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }

                // Inline add task row
                AddTaskRowView(timerManager: timerManager, breakDurationMinutes: $breakDurationMinutes)
                    .padding(.horizontal, 24)
                    .zIndex(200) // Keep above timeline segment editors

                Spacer()
            }

            Divider()

            // Controls
            HStack(spacing: 12) {
                // Pipeline library button (left)
                Button(action: { showPipelineLibrary = true }) {
                    Label("Load Pipeline", systemImage: "folder")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .help("Load a saved pipeline")

                // Save pipeline button
                Button(action: { showSavePipeline = true }) {
                    Label("Save Pipeline", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(timerManager.tasks.isEmpty)
                .help("Save current tasks as a pipeline")

                // Clear button
                Button(action: {
                    timerManager.tasks.removeAll()
                    timerManager.setTargetTotalMinutes(5)
                }) {
                    Text("Clear")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(timerManager.tasks.isEmpty)
                .help("Clear all tasks")

                Spacer()

                Button(action: { timerManager.start() }) {
                    Label("Start Pipeline", systemImage: "play.fill")
                        .frame(minWidth: 120)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(timerManager.tasks.isEmpty)
            }
            .padding()
        }
        .sheet(isPresented: $showPipelineLibrary) {
            PipelineLibraryView(
                pipelineManager: pipelineManager,
                timerManager: timerManager,
                isPresented: $showPipelineLibrary
            )
        }
        .sheet(isPresented: $showSavePipeline) {
            SavePipelineView(
                pipelineManager: pipelineManager,
                timerManager: timerManager,
                isPresented: $showSavePipeline,
                pipelineName: $newPipelineName
            )
        }
        .onAppear {
            updateDoneByTimeFromTotal()
            // Display actual total including breaks
            let actualTotal = timerManager.tasks.reduce(0.0) { $0 + $1.durationMinutes }
            totalMinutesText = "\(Int(actualTotal))"
            breakDurationText = "\(Int(breakDurationMinutes))"
        }
        .onChange(of: timerManager.targetTotalMinutes) { _ in
            if !isDoneByFieldFocused {
                updateDoneByTimeFromTotal()
            }
        }
        .onChange(of: timerManager.tasks) { _ in
            // Update total time display when tasks change
            if !isTotalFieldFocused {
                let actualTotal = timerManager.tasks.reduce(0.0) { $0 + $1.durationMinutes }
                totalMinutesText = "\(Int(actualTotal))"
            }
        }
        .onChange(of: breakDurationMinutes) { newValue in
            // Update break duration text when setting changes
            if !isBreakFieldFocused {
                breakDurationText = "\(Int(newValue))"
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No tasks yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Start typing below")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var totalDurationFormatted: String {
        let totalMinutes = timerManager.tasks.reduce(0) { $0 + $1.durationMinutes }
        let hours = Int(totalMinutes) / 60
        let minutes = Int(totalMinutes) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m total"
        } else {
            return "\(Int(totalMinutes))m total"
        }
    }

    private func formatTotalMinutes(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(Int(minutes))m"
        }
    }

    private func applyDoneByTimeChange() {
        // Parse time format H:mmAM/PM or HH:mmAM/PM
        let text = doneByTimeText.uppercased()
        let isAM = text.contains("AM")
        let isPM = text.contains("PM")

        // Remove AM/PM to get just the time
        let timeOnly = text.replacingOccurrences(of: "AM", with: "").replacingOccurrences(of: "PM", with: "").trimmingCharacters(in: .whitespaces)
        let timeParts = timeOnly.split(separator: ":")

        guard timeParts.count == 2,
              let hour12 = Int(timeParts[0]),
              let minute = Int(String(timeParts[1]).prefix(2)),
              hour12 >= 1 && hour12 <= 12,
              minute >= 0 && minute < 60 else {
            // Invalid format, revert
            updateDoneByTimeFromTotal()
            return
        }

        // Convert to 24-hour format
        var hour24 = hour12
        if isAM && hour12 == 12 {
            hour24 = 0  // 12 AM = 0:00
        } else if isPM && hour12 != 12 {
            hour24 = hour12 + 12  // 1 PM = 13:00, etc.
        }

        // Calculate total time needed to reach this time
        let now = Date()
        let calendar = Calendar.current

        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = hour24
        dateComponents.minute = minute

        guard var targetDate = calendar.date(from: dateComponents) else {
            return
        }

        // If target time is in the past (earlier today), assume it's tomorrow
        if targetDate < now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        }

        // Calculate minutes between now and target
        let minutesUntilTarget = calendar.dateComponents([.minute], from: now, to: targetDate).minute ?? 0

        if minutesUntilTarget > 0 {
            timerManager.setTargetTotalMinutes(Double(minutesUntilTarget))
        }
    }

    private func updateDoneByTimeFromTotal() {
        // Update done by time based on current total time
        let now = Date()
        let calendar = Calendar.current
        let totalMinutes = Int(timerManager.targetTotalMinutes)

        if let futureTime = calendar.date(byAdding: .minute, value: totalMinutes, to: now) {
            let hour = calendar.component(.hour, from: futureTime)
            let minute = calendar.component(.minute, from: futureTime)

            // Convert to 12-hour format with AM/PM
            let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            let ampm = hour < 12 ? "AM" : "PM"
            doneByTimeText = String(format: "%d:%02d%@", hour12, minute, ampm)
        }
    }


    private func rebuildTasksWithBreaks() {
        // Remove existing break tasks
        let nonBreakTasks = timerManager.tasks.filter { !$0.isBreak }

        // Clear all tasks
        timerManager.tasks.removeAll()

        // Re-add tasks with breaks between them
        for (index, task) in nonBreakTasks.enumerated() {
            timerManager.addTask(task)

            // Add break after each task except the last one
            if breakDurationMinutes > 0 && index < nonBreakTasks.count - 1 {
                let breakTask = TimerTask(
                    name: "Break",
                    durationMinutes: breakDurationMinutes,
                    isBreak: true
                )
                timerManager.addTask(breakTask)
            }
        }
    }

}

// MARK: - Interactive Timeline Bar (Primary Visual)

struct InteractiveTimelineBar: View {
    @ObservedObject var timerManager: TimerManager
    @Binding var lockTotalTime: Bool
    @State private var selectedTask: TimerTask?
    @State private var editingTask: TimerTask?
    @State private var draggedTask: TimerTask?
    @State private var currentDropTarget: UUID?
    @State private var isDraggingDivider: Bool = false
    @State private var isHoveringTimeline: Bool = false
    @State private var activeDividerIndex: Int? = nil

    var body: some View {
        VStack(spacing: 12) {
            // Main timeline bar with native drag and drop
            GeometryReader { geometry in
                let widths = calculateSegmentWidths(totalWidth: geometry.size.width)

                ZStack(alignment: .leading) {
                    // Segments
                    HStack(spacing: 3) {
                        ForEach(timerManager.tasks) { task in
                            let index = timerManager.tasks.firstIndex(where: { $0.id == task.id }) ?? 0
                            let width = index < widths.count ? widths[index] : 60

                            TimelineSegment(
                                task: task,
                                index: index,
                                width: width,
                                isSelected: selectedTask?.id == task.id,
                                isEditing: editingTask?.id == task.id,
                                onTap: {
                                    if editingTask?.id == task.id {
                                        // Close editor if clicking same task
                                        selectedTask = nil
                                        editingTask = nil
                                    } else {
                                        // Open editor on single click
                                        selectedTask = task
                                        editingTask = task
                                    }
                                },
                                onDoubleTap: {
                                    // Double-tap also opens editor (same as single tap now)
                                    selectedTask = task
                                    editingTask = task
                                },
                                timerManager: timerManager,
                                onNameChange: { newName in
                                    if let idx = timerManager.tasks.firstIndex(where: { $0.id == task.id }) {
                                        timerManager.updateTask(at: idx, name: newName, durationMinutes: task.durationMinutes)
                                    }
                                },
                                onDurationChange: { newDuration, unlockIfLocked in
                                    if let idx = timerManager.tasks.firstIndex(where: { $0.id == task.id }) {
                                        // If manually typed, unlock total time
                                        if unlockIfLocked && lockTotalTime {
                                            lockTotalTime = false
                                        }

                                        if lockTotalTime {
                                            // Locked: maintain total time and recalculate proportions
                                            let currentTotal = timerManager.targetTotalMinutes

                                            // Update this task's duration
                                            timerManager.updateTask(at: idx, name: task.name, durationMinutes: newDuration)

                                            // Recalculate proportions for all tasks to maintain total
                                            let newProportion = newDuration / currentTotal
                                            timerManager.tasks[idx].proportion = newProportion

                                            // Redistribute remaining time to other tasks
                                            let remainingTime = currentTotal - newDuration
                                            let otherTasksOldTotal = timerManager.tasks.enumerated().reduce(0.0) { sum, item in
                                                return item.offset == idx ? sum : sum + item.element.durationMinutes
                                            }

                                            if otherTasksOldTotal > 0 {
                                                for i in 0..<timerManager.tasks.count where i != idx {
                                                    let ratio = timerManager.tasks[i].durationMinutes / otherTasksOldTotal
                                                    let newTaskDuration = remainingTime * ratio
                                                    timerManager.tasks[i].durationMinutes = newTaskDuration
                                                    timerManager.tasks[i].proportion = newTaskDuration / currentTotal
                                                }
                                            }
                                        } else {
                                            // Unlocked: just update the duration exactly as entered
                                            timerManager.updateTask(at: idx, name: task.name, durationMinutes: newDuration)

                                            // Update total time to reflect actual sum (including breaks)
                                            // Set directly to avoid proportional recalculation
                                            let actualTotal = timerManager.tasks.reduce(0.0) { $0 + $1.durationMinutes }
                                            timerManager.targetTotalMinutes = actualTotal
                                        }
                                    }
                                },
                                onDelete: {
                                    if let idx = timerManager.tasks.firstIndex(where: { $0.id == task.id }) {
                                        timerManager.removeTask(at: idx)
                                        editingTask = nil
                                        selectedTask = nil
                                    }
                                }
                            )
                            .opacity(draggedTask?.id == task.id ? 0.3 : 1.0)
                            .onDrag {
                                self.draggedTask = task
                                return NSItemProvider(object: task.id.uuidString as NSString)
                            }
                            .onDrop(of: [.plainText], delegate: TaskDropDelegate(
                                task: task,
                                tasks: $timerManager.tasks,
                                draggedTask: $draggedTask,
                                currentDropTarget: $currentDropTarget,
                                selectedTask: $selectedTask,
                                editingTask: $editingTask
                            ))
                        }
                    }

                    // Resize dividers - only show on hover (not when dragging tasks)
                    if timerManager.tasks.count > 1 && (isHoveringTimeline || isDraggingDivider) && draggedTask == nil {
                        ForEach(0..<timerManager.tasks.count - 1, id: \.self) { index in
                            let xPosition = widths.prefix(index + 1).reduce(0, +) + CGFloat(index + 1) * 3 - 1.5
                            ResizeDivider(
                                isActive: activeDividerIndex == index,
                                onDragStart: {
                                    isDraggingDivider = true
                                    activeDividerIndex = index
                                },
                                onDrag: { delta in
                                    handleDividerDrag(at: index, delta: delta, totalWidth: geometry.size.width)
                                },
                                onDragEnd: {
                                    isDraggingDivider = false
                                    activeDividerIndex = nil
                                }
                            )
                            .frame(width: 12, height: 60)
                            .offset(x: xPosition - 2, y: 0)
                        }
                    }
                }
            }
            .frame(height: 60)
            .clipped() // Ensure child elements don't escape bounds
            .onHover { hovering in
                isHoveringTimeline = hovering
            }
            .cornerRadius(8)
            .onChange(of: draggedTask) { newValue in
                if newValue != nil {
                    // When drag starts, hide dividers by clearing hover state
                    isHoveringTimeline = false
                }

                // When drag ends (draggedTask becomes nil), clear selection and reset state
                if newValue == nil {
                    self.selectedTask = nil
                    self.editingTask = nil
                    self.currentDropTarget = nil

                    // Force the window to accept keyboard input again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.keyWindow?.makeKeyAndOrderFront(nil)
                    }
                }
            }

            // Instructions
            HStack(spacing: 8) {
                Text("Click to edit • Drag to reorder")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }

    private func calculateSegmentWidths(totalWidth: CGFloat) -> [CGFloat] {
        let totalDuration = timerManager.tasks.reduce(0) { $0 + $1.durationMinutes }
        guard totalDuration > 0 else { return Array(repeating: 0, count: timerManager.tasks.count) }

        let taskCount = timerManager.tasks.count
        let spacing: CGFloat = 3
        let totalSpacing = spacing * CGFloat(max(taskCount - 1, 0))
        let availableWidth = totalWidth - totalSpacing

        // Calculate proportional widths first
        var widths: [CGFloat] = timerManager.tasks.map { task in
            let proportion = task.durationMinutes / totalDuration
            return availableWidth * proportion
        }

        // Determine appropriate minimum width - absolute minimum for usability
        let absoluteMinWidth: CGFloat = 25
        let desiredMinWidth: CGFloat
        if taskCount <= 3 {
            desiredMinWidth = 60
        } else if taskCount <= 6 {
            desiredMinWidth = 40
        } else {
            desiredMinWidth = 30
        }

        // Smart redistribution algorithm
        // 1. Find tasks below minimum and tasks that can give space
        var needsAdjustment = true
        var iterations = 0
        let maxIterations = 10

        while needsAdjustment && iterations < maxIterations {
            iterations += 1
            needsAdjustment = false

            var belowMinIndices: [Int] = []
            var aboveMinIndices: [Int] = []
            var totalDeficit: CGFloat = 0
            var totalSurplus: CGFloat = 0

            for (index, width) in widths.enumerated() {
                if width < absoluteMinWidth {
                    belowMinIndices.append(index)
                    totalDeficit += (absoluteMinWidth - width)
                } else if width > desiredMinWidth {
                    aboveMinIndices.append(index)
                    totalSurplus += (width - desiredMinWidth)
                }
            }

            // If we have tasks below minimum and tasks that can give space
            if !belowMinIndices.isEmpty {
                needsAdjustment = true

                // Apply absolute minimum to tiny tasks
                for index in belowMinIndices {
                    widths[index] = absoluteMinWidth
                }

                // Redistribute the deficit from larger tasks
                if !aboveMinIndices.isEmpty && totalDeficit > 0 {
                    for index in aboveMinIndices {
                        let surplusRatio = (widths[index] - desiredMinWidth) / totalSurplus
                        let reduction = min(totalDeficit * surplusRatio, widths[index] - absoluteMinWidth)
                        widths[index] -= reduction
                    }
                } else if totalDeficit > 0 {
                    // No large tasks to take from, reduce all proportionally
                    let totalCurrent = widths.reduce(0, +)
                    let scale = availableWidth / totalCurrent
                    widths = widths.map { $0 * scale }
                    needsAdjustment = false // Prevent infinite loop
                }
            } else {
                needsAdjustment = false
            }
        }

        // Final safety check: ensure total doesn't exceed available width
        let totalWidth = widths.reduce(0, +)
        if totalWidth > availableWidth {
            let scale = availableWidth / totalWidth
            widths = widths.map { max($0 * scale, absoluteMinWidth) }
        }

        return widths
    }

    private func handleDividerDrag(at dividerIndex: Int, delta: CGFloat, totalWidth: CGFloat) {
        guard dividerIndex < timerManager.tasks.count - 1,
              timerManager.tasks[dividerIndex].proportion != nil,
              timerManager.tasks[dividerIndex + 1].proportion != nil else {
            return
        }

        let leftTask = timerManager.tasks[dividerIndex]
        let rightTask = timerManager.tasks[dividerIndex + 1]

        guard let leftProportion = leftTask.proportion,
              let rightProportion = rightTask.proportion else {
            return
        }

        // Calculate the change in proportion based on pixel delta
        let totalProportion = timerManager.tasks.reduce(0.0) { $0 + ($1.proportion ?? 0.0) }
        let deltaInProportion = (delta / totalWidth) * totalProportion

        // Compute new proportions
        let newLeftProportion = max(0.1, leftProportion + deltaInProportion)
        let newRightProportion = max(0.1, rightProportion - deltaInProportion)

        // Ensure we don't make either task too small
        if newLeftProportion >= 0.1 && newRightProportion >= 0.1 {
            timerManager.tasks[dividerIndex].proportion = newLeftProportion
            timerManager.tasks[dividerIndex + 1].proportion = newRightProportion

            // Recalculate durations
            timerManager.recalculateTaskDurations()
        }
    }
}

// MARK: - Resize Divider

struct ResizeDivider: View {
    let isActive: Bool
    let onDragStart: () -> Void
    let onDrag: (CGFloat) -> Void
    let onDragEnd: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var accumulatedDelta: CGFloat = 0
    @State private var updateTimer: Timer?
    @State private var isHovering: Bool = false

    var body: some View {
        ZStack {
            // Invisible wider hit area
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())

            // Visible handle - only show when hovering or dragging
            if isHovering || isActive {
                Capsule()
                    .fill(Color.white.opacity(isActive ? 0.9 : 0.6))
                    .frame(width: 4, height: 40)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 0)
                    .animation(.easeInOut(duration: 0.15), value: isActive)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
        }
        .cursor(NSCursor.resizeLeftRight)
        .onHover { hovering in
            isHovering = hovering
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    if dragOffset == 0 {
                        onDragStart()
                    }

                    let delta = value.translation.width - dragOffset
                    dragOffset = value.translation.width
                    accumulatedDelta += delta

                    // Throttle updates - only update every 5 pixels of accumulated drag
                    if abs(accumulatedDelta) >= 5 {
                        onDrag(accumulatedDelta)
                        accumulatedDelta = 0
                    }
                }
                .onEnded { _ in
                    // Apply any remaining accumulated delta
                    if accumulatedDelta != 0 {
                        onDrag(accumulatedDelta)
                    }

                    dragOffset = 0
                    accumulatedDelta = 0
                    onDragEnd()
                }
        )
    }
}

// MARK: - Task Drop Delegate

struct TaskDropDelegate: DropDelegate {
    let task: TimerTask
    @Binding var tasks: [TimerTask]
    @Binding var draggedTask: TimerTask?
    @Binding var currentDropTarget: UUID?
    @Binding var selectedTask: TimerTask?
    @Binding var editingTask: TimerTask?

    func performDrop(info: DropInfo) -> Bool {
        // Reset drag state and clear selection
        draggedTask = nil
        currentDropTarget = nil
        selectedTask = nil
        editingTask = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedTask,
              dragged.id != task.id else {
            return
        }

        // Only move if this is a new drop target
        if currentDropTarget != task.id {
            currentDropTarget = task.id

            guard let fromIndex = tasks.firstIndex(where: { $0.id == dragged.id }),
                  let toIndex = tasks.firstIndex(where: { $0.id == task.id }) else {
                return
            }

            if fromIndex != toIndex {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    tasks.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                }
            }
        }
    }

    func dropExited(info: DropInfo) {
        // Don't reset currentDropTarget here to prevent re-entering
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Timeline Segment

struct TimelineSegment: View {
    let task: TimerTask
    let index: Int
    let width: CGFloat
    let isSelected: Bool
    let isEditing: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    @ObservedObject var timerManager: TimerManager
    let onNameChange: (String) -> Void
    let onDurationChange: (Double, Bool) -> Void
    let onDelete: () -> Void

    @State private var editName: String = ""
    @State private var sliderValue: Double = 0
    @State private var durationText: String = ""
    @State private var showEditor: Bool = false
    @FocusState private var isDurationFieldFocused: Bool
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        ZStack {
            // Main segment
            ZStack {
                // Background
                backgroundView

                // Content - responsive layout based on width
                contentView
            }
            .frame(width: width, height: 60)
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            .contentShape(Rectangle()) // Define hit area without button behavior
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded { _ in
                        onDoubleTap()
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded { _ in
                        onTap()
                    }
            )
            .focusable(false) // Disable focus ring
            .overlay(alignment: .topTrailing) {
                if isEditing {
                    Button(action: onDelete) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: deleteButtonSize, height: deleteButtonSize)
                            Image(systemName: "xmark")
                                .font(.system(size: deleteButtonIconSize, weight: .semibold))
                                .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Delete task")
                    .frame(width: deleteButtonSize, height: deleteButtonSize)
                    .padding([.top, .trailing], deleteButtonPadding)
                }
            }
        }
        .frame(width: width, height: 60)
        .onAppear {
            editName = task.name
            sliderValue = task.durationMinutes
            durationText = formatDurationNumber(task.durationMinutes)
        }
        .onChange(of: task.name) { newValue in
            editName = newValue
        }
        .onChange(of: task.durationMinutes) { newValue in
            sliderValue = newValue
            durationText = formatDurationNumber(newValue)
        }
        .onChange(of: isEditing) { editing in
            if editing {
                // Focus the name field when editor opens
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isNameFieldFocused = true
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
                    if width < 35 {
                        // Extremely narrow - show just duration vertically
                        VStack(spacing: 0) {
                            if isEditing {
                                TextField("", text: $durationText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 25)
                                    .focused($isDurationFieldFocused)
                                    .onChange(of: durationText) { newValue in
                                        let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                        if filtered != newValue {
                                            durationText = filtered
                                        }
                                        if let value = Double(filtered), value >= 0.166 && value <= 120 {
                                            sliderValue = value
                                        }
                                    }
                                    .onSubmit {
                                        if let value = Double(durationText), value >= 0.166 && value <= 120 {
                                            onDurationChange(value, true)
                                        }
                                        onTap()
                                    }
                            } else {
                                Text(formatDuration(task.durationMinutes))
                                    .font(.system(size: 9, weight: .bold))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.6)
                            }
                        }
                        .padding(2)
                    } else if width < 80 {
                        // Very narrow - show only duration, centered
                        VStack(spacing: 0) {
                            if isEditing {
                                TextField("", text: $durationText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 40)
                                    .focused($isDurationFieldFocused)
                                    .onChange(of: durationText) { newValue in
                                        let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                        if filtered != newValue {
                                            durationText = filtered
                                        }
                                        if let value = Double(filtered), value >= 0.166 && value <= 120 {
                                            sliderValue = value
                                        }
                                    }
                                    .onSubmit {
                                        if let value = Double(durationText), value >= 0.166 && value <= 120 {
                                            onDurationChange(value, true)
                                        }
                                        onTap()
                                    }
                            } else {
                                Text(formatDuration(task.durationMinutes))
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                        .padding(4)
                    } else if width < 120 {
                        // Narrow - show duration prominently, name smaller
                        VStack(spacing: 1) {
                            if isEditing {
                                HStack(spacing: 2) {
                                    TextField("", text: $durationText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 35)
                                        .focused($isDurationFieldFocused)
                                        .onChange(of: durationText) { newValue in
                                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                            if filtered != newValue {
                                                durationText = filtered
                                            }
                                            if let value = Double(filtered), value >= 0.166 && value <= 120 {
                                                sliderValue = value
                                            }
                                        }
                                        .onSubmit {
                                            if let value = Double(durationText), value >= 0.166 && value <= 120 {
                                                onDurationChange(value, true)
                                            }
                                            onTap()
                                        }
                                    Text("m")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            } else {
                                Text(formatDuration(task.durationMinutes))
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                            }

                            Text(task.name)
                                .font(.system(size: 8, weight: .medium))
                                .lineLimit(1)
                                .foregroundColor(.white.opacity(0.85))
                                .minimumScaleFactor(0.7)
                        }
                        .padding(4)
                    } else {
                        // Normal - show both name and duration clearly
                        VStack(spacing: 2) {
                            // Task name - editable when editing
                            if isEditing {
                                TextField("Task name", text: $editName)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .focused($isNameFieldFocused)
                                    .allowsHitTesting(true)
                                    .onSubmit {
                                        onNameChange(editName)
                                        // Focus duration field after submitting name
                                        isDurationFieldFocused = true
                                    }
                            } else {
                                Text(task.name)
                                    .font(.system(size: 10, weight: .semibold))
                                    .lineLimit(1)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.7)
                            }

                            // Editable duration field
                            if isEditing {
                                HStack(spacing: 2) {
                                    TextField("", text: $durationText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 30)
                                        .focused($isDurationFieldFocused)
                                        .allowsHitTesting(true)
                                        .onChange(of: durationText) { newValue in
                                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                            if filtered != newValue {
                                                durationText = filtered
                                            }
                                            if let value = Double(filtered), value >= 0.166 && value <= 120 {
                                                sliderValue = value
                                            }
                                        }
                                        .onSubmit {
                                            if let value = Double(durationText), value >= 0.166 && value <= 120 {
                                                onDurationChange(value, true) // true = unlock if locked
                                            }
                                            onTap() // Close editor
                                        }

                                    Text("m")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.25))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                )
                                .frame(maxWidth: .infinity)
                                .allowsHitTesting(true)
                            } else {
                                // Non-editing: show duration
                                Text(formatDuration(task.durationMinutes))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(6)
                    }
        }
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(TaskColorHelper.gradient(for: task))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEditing ? Color.white.opacity(0.8) : Color.clear, lineWidth: isEditing ? 2 : 0)
            )
            .shadow(color: isEditing ? Color.white.opacity(0.3) : Color.clear, radius: isEditing ? 8 : 0, x: 0, y: 0)
    }

    private var deleteButtonSize: CGFloat {
        if width < 50 {
            return 14
        } else if width < 80 {
            return 16
        } else if width < 120 {
            return 18
        } else {
            return 20
        }
    }

    private var deleteButtonIconSize: CGFloat {
        if width < 50 {
            return 7
        } else if width < 80 {
            return 8
        } else if width < 120 {
            return 9
        } else {
            return 10
        }
    }

    private var deleteButtonPadding: CGFloat {
        if width < 50 {
            return 2
        } else if width < 80 {
            return 2.5
        } else if width < 120 {
            return 3
        } else {
            return 3
        }
    }

    private var segmentColor: Color {
        return TaskColorHelper.color(for: task.colorIndex)
    }

    private func formatDuration(_ minutes: Double) -> String {
        if minutes < 1 {
            let seconds = Int(minutes * 60)
            return "\(seconds)s"
        } else {
            return "\(Int(minutes))m"
        }
    }

    private func formatDurationNumber(_ minutes: Double) -> String {
        if minutes < 1 {
            // For sub-minute, show as seconds
            let seconds = Int(minutes * 60)
            return "\(seconds)"
        } else {
            // Round to nearest whole minute
            return String(Int(minutes.rounded()))
        }
    }
}

// Safe array access extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Cursor modifier for macOS
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { hovering in
            if hovering {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Task Color Helper

struct TaskColorHelper {
    static func gradient(for index: Int) -> LinearGradient {
        let gradients: [LinearGradient] = [
            // Blue-purple gradient
            LinearGradient(
                colors: [Color(red: 0.4, green: 0.5, blue: 0.85), Color(red: 0.6, green: 0.4, blue: 0.85)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            // Purple-pink gradient
            LinearGradient(
                colors: [Color(red: 0.65, green: 0.35, blue: 0.85), Color(red: 0.85, green: 0.4, blue: 0.7)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            // Pink-orange gradient
            LinearGradient(
                colors: [Color(red: 0.9, green: 0.4, blue: 0.65), Color(red: 0.95, green: 0.55, blue: 0.4)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            // Orange-yellow gradient
            LinearGradient(
                colors: [Color(red: 0.95, green: 0.6, blue: 0.35), Color(red: 0.95, green: 0.75, blue: 0.4)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            // Green-cyan gradient
            LinearGradient(
                colors: [Color(red: 0.35, green: 0.75, blue: 0.5), Color(red: 0.35, green: 0.7, blue: 0.75)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            // Cyan-blue gradient
            LinearGradient(
                colors: [Color(red: 0.3, green: 0.7, blue: 0.85), Color(red: 0.4, green: 0.55, blue: 0.85)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            // Indigo-purple gradient
            LinearGradient(
                colors: [Color(red: 0.45, green: 0.4, blue: 0.85), Color(red: 0.6, green: 0.45, blue: 0.8)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            // Teal-green gradient
            LinearGradient(
                colors: [Color(red: 0.35, green: 0.75, blue: 0.7), Color(red: 0.4, green: 0.75, blue: 0.55)],
                startPoint: .leading,
                endPoint: .trailing
            )
        ]
        return gradients[index % gradients.count]
    }

    static func gradient(for task: TimerTask) -> LinearGradient {
        // Break tasks get a special gray gradient
        if task.isBreak {
            return LinearGradient(
                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return gradient(for: task.colorIndex)
    }

    // Legacy color method for backward compatibility
    static func color(for index: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.5, green: 0.45, blue: 0.85),
            Color(red: 0.75, green: 0.375, blue: 0.775),
            Color(red: 0.875, green: 0.4, blue: 0.675),
            Color(red: 0.95, green: 0.675, blue: 0.375),
            Color(red: 0.35, green: 0.725, blue: 0.625),
            Color(red: 0.35, green: 0.625, blue: 0.85),
            Color(red: 0.525, green: 0.425, blue: 0.825),
            Color(red: 0.375, green: 0.75, blue: 0.625)
        ]
        return colors[index % colors.count]
    }

    static func color(for task: TimerTask) -> Color {
        let hash = abs(task.id.hashValue)
        return color(for: hash)
    }
}


// MARK: - Compact Task Detail Row

struct TaskDetailRow: View {
    let task: TimerTask
    let index: Int
    @ObservedObject var timerManager: TimerManager
    @State private var isEditingName: Bool = false
    @State private var editName: String = ""
    @State private var sliderValue: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator matching timeline
            RoundedRectangle(cornerRadius: 3)
                .fill(TaskColorHelper.color(for: task.colorIndex))
                .frame(width: 6, height: 40)

            Text("\(index + 1).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 25, alignment: .trailing)

            VStack(alignment: .leading, spacing: 6) {
                if isEditingName {
                    HStack {
                        TextField("Task name", text: $editName, onCommit: {
                            saveNameChange()
                        })
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)

                        Button("Done") {
                            saveNameChange()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                    }
                } else {
                    Text(task.name)
                        .font(.subheadline)
                        .onTapGesture {
                            startEditingName()
                        }
                }

                HStack(spacing: 8) {
                    Text(formatDurationForTask(sliderValue))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()

                    Slider(value: $sliderValue, in: 0.166...120, step: 0.166, onEditingChanged: { editing in
                        if !editing {
                            saveDurationChange()
                        }
                    })
                    .tint(.accentColor)

                    Text("120m")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.5))
                        .frame(width: 30, alignment: .leading)
                }
            }

            Button(action: {
                timerManager.removeTask(at: index)
            }) {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(TaskColorHelper.color(for: task.colorIndex).opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            sliderValue = task.durationMinutes
        }
        .onChange(of: task.durationMinutes) { newValue in
            sliderValue = newValue
        }
    }

    private func startEditingName() {
        editName = task.name
        isEditingName = true
    }

    private func saveNameChange() {
        guard !editName.isEmpty else {
            isEditingName = false
            return
        }
        timerManager.updateTask(at: index, name: editName, durationMinutes: task.durationMinutes)
        isEditingName = false
    }

    private func saveDurationChange() {
        timerManager.updateTask(at: index, name: task.name, durationMinutes: sliderValue)
    }

    private func formatDurationForTask(_ minutes: Double) -> String {
        if minutes < 1 {
            let seconds = Int(minutes * 60)
            return "\(seconds)s"
        } else {
            return "\(Int(minutes))m"
        }
    }
}

// MARK: - Inline Add Task Row

struct AddTaskRowView: View {
    @ObservedObject var timerManager: TimerManager
    @Binding var breakDurationMinutes: Double
    @State private var taskName: String = ""
    @State private var durationText: String = "10"
    @State private var sliderValue: Double = 10.0
    @AppStorage("maxTaskDuration") private var maxTaskDuration: Double = 120
    @AppStorage("defaultTaskDuration") private var defaultTaskDuration: Double = 10
    @State private var previousTaskCount: Int = 0
    @Environment(\.colorScheme) var colorScheme
    private let minDuration: Double = 0.166 // 10 seconds

    var body: some View {
        VStack(spacing: 8) {
            // Top row: Task name, duration/proportion, and add button
            HStack(spacing: 12) {
                // Task name input with cursor
                ClickableTextField(text: $taskName, placeholder: "Add task (optional)...", onSubmit: addTask, autoFocus: true)
                    .font(.system(size: 14, weight: .medium))

                // Duration controls (always proportional)
                HStack(spacing: 6) {
                    TextField("", text: $durationText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(durationColor(for: sliderValue).opacity(0.4))
                        .frame(width: 35)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: durationText) { newValue in
                            let filtered = newValue.filter { $0.isNumber || $0 == "." }
                            if filtered != newValue {
                                durationText = filtered
                            }

                            if let value = Double(filtered), value >= minDuration && value <= maxTaskDuration {
                                sliderValue = value
                            }
                        }
                        .onSubmit {
                            addTask()
                        }

                    Text("min")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .frame(width: 75)

                // Add button - always visible
                Button(action: addTask) {
                    Text("Add")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .frame(width: 50)
            }
            .padding(.vertical, 8)
            .frame(height: 40)

            // Quick select duration buttons
            HStack(spacing: 8) {
                ForEach([10, 15, 20, 30, 40], id: \.self) { duration in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            sliderValue = Double(duration)
                            durationText = "\(duration)"
                        }
                    }) {
                        Text("\(duration)m")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(sliderValue == Double(duration) ? .white : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                sliderValue == Double(duration)
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.15)
                            )
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 4)

            // Bottom row: Visual slider bar with draggable thumb
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)

                    // Duration slider
                    Capsule()
                        .fill(durationColor(for: sliderValue).opacity(0.4))
                        .frame(width: max(8, geometry.size.width * CGFloat((sliderValue - minDuration) / (maxTaskDuration - minDuration))), height: 6)

                    Circle()
                        .fill(durationColor(for: sliderValue).opacity(0.6))
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                        .offset(x: max(0, min(geometry.size.width - 16, geometry.size.width * CGFloat((sliderValue - minDuration) / (maxTaskDuration - minDuration)) - 8)))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let proportion = value.location.x / geometry.size.width
                                    let newValue = max(minDuration, min(maxTaskDuration, minDuration + (proportion * (maxTaskDuration - minDuration))))
                                    sliderValue = newValue
                                    if newValue < 1 {
                                        durationText = String(format: "%.2f", newValue)
                                    } else {
                                        durationText = "\(Int(round(newValue)))"
                                    }
                                }
                        )
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let proportion = location.x / geometry.size.width
                    let newValue = max(minDuration, min(maxTaskDuration, minDuration + (proportion * (maxTaskDuration - minDuration))))
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sliderValue = newValue
                        if newValue < 1 {
                            durationText = String(format: "%.2f", newValue)
                        } else {
                            durationText = "\(Int(round(newValue)))"
                        }
                    }
                }
            }
            .frame(height: 16)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .onChange(of: timerManager.tasks.count) { newCount in
            // Track when tasks are added or removed
            previousTaskCount = newCount
        }
        .onAppear {
            previousTaskCount = timerManager.tasks.count
            sliderValue = defaultTaskDuration
            durationText = "\(Int(defaultTaskDuration))"
        }
        .onChange(of: defaultTaskDuration) { newValue in
            sliderValue = newValue
            durationText = "\(Int(newValue))"
        }
        .onChange(of: maxTaskDuration) { newValue in
            // Ensure current slider value doesn't exceed new max
            if sliderValue > newValue {
                sliderValue = newValue
                durationText = "\(Int(newValue))"
            }
        }
    }

    private func durationColor(for minutes: Double) -> Color {
        let maxDuration = maxTaskDuration
        let percentage = minutes / maxDuration

        // In light mode, use darker colors for better contrast
        let isDark = colorScheme == .dark
        let multiplier = isDark ? 1.0 : 0.6

        // Create smooth gradient: green -> yellow -> orange -> red
        if percentage <= 0.33 {
            // Green to Yellow
            let local = percentage / 0.33
            return Color(
                red: local * multiplier,  // 0 to 1.0 (or 0.6 in light mode)
                green: 1.0 * multiplier,  // stays 1.0 (or 0.6 in light mode)
                blue: 0
            )
        } else if percentage <= 0.66 {
            // Yellow to Orange
            let local = (percentage - 0.33) / 0.33
            return Color(
                red: 1.0 * multiplier,
                green: (1.0 - local * 0.5) * multiplier,  // 1.0 to 0.5
                blue: 0
            )
        } else {
            // Orange to Red
            let local = (percentage - 0.66) / 0.34
            return Color(
                red: 1.0 * multiplier,
                green: (0.5 - local * 0.5) * multiplier,  // 0.5 to 0
                blue: 0
            )
        }
    }

    private func addTask() {
        // Allow empty task names - use "Task" as default
        let finalName = taskName.trimmingCharacters(in: .whitespaces).isEmpty ? "Task" : taskName

        // Count non-break tasks to determine if we need to insert a break
        let nonBreakTaskCount = timerManager.tasks.filter { !$0.isBreak }.count

        // If there are already tasks and break duration is > 0, insert a break before this task
        if nonBreakTaskCount > 0 && breakDurationMinutes > 0 {
            let breakTask = TimerTask(
                name: "Break",
                durationMinutes: breakDurationMinutes,
                isBreak: true
            )
            timerManager.addTask(breakTask)
        }

        // Create task with the desired duration
        let task = TimerTask(
            name: finalName,
            durationMinutes: sliderValue,
            proportion: nil  // Will be set after we update total
        )

        timerManager.addTask(task)

        // Update total time and proportions based on new task list
        let newTotal = timerManager.tasks.reduce(0.0) { $0 + $1.durationMinutes }
        timerManager.setTargetTotalMinutes(newTotal)

        // Set proportions for all tasks based on the new total
        for (index, task) in timerManager.tasks.enumerated() {
            timerManager.tasks[index].proportion = task.durationMinutes / newTotal
        }

        // Only reset task name, keep duration sticky
        taskName = ""
    }
}

// MARK: - Save Pipeline View

struct SavePipelineView: View {
    @ObservedObject var pipelineManager: PipelineManager
    @ObservedObject var timerManager: TimerManager
    @Binding var isPresented: Bool
    @Binding var pipelineName: String
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Save Pipeline")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Pipeline Name")
                    .font(.headline)

                TextField("Enter pipeline name", text: $pipelineName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tasks")
                    .font(.headline)

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(timerManager.tasks.enumerated()), id: \.element.id) { index, task in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 25, alignment: .trailing)

                                Text(task.name)
                                    .font(.subheadline)

                                Spacer()

                                Text("\(Int(task.durationMinutes))m")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 120)
                .padding(8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }

            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button("Save") {
                    savePipeline()
                }
                .buttonStyle(.borderedProminent)
                .disabled(pipelineName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 400)
    }

    private func savePipeline() {
        let trimmedName = pipelineName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showError(message: "Pipeline name is required")
            return
        }

        pipelineManager.savePipeline(name: trimmedName, tasks: timerManager.tasks)
        isPresented = false
        pipelineName = ""
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
}

// MARK: - Pipeline Library View

struct PipelineLibraryView: View {
    @ObservedObject var pipelineManager: PipelineManager
    @ObservedObject var timerManager: TimerManager
    @Binding var isPresented: Bool
    @State private var selectedPipeline: SavedPipeline?
    @State private var editingPipeline: SavedPipeline?
    @State private var editName: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Pipeline Library")
                .font(.title2)
                .fontWeight(.bold)

            if pipelineManager.savedPipelines.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No saved pipelines")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Save your current tasks to create reusable pipelines")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(pipelineManager.savedPipelines) { pipeline in
                            PipelineRowView(
                                pipeline: pipeline,
                                isSelected: selectedPipeline?.id == pipeline.id,
                                isEditing: editingPipeline?.id == pipeline.id,
                                editName: $editName,
                                onSelect: {
                                    selectedPipeline = pipeline
                                },
                                onLoad: {
                                    loadPipeline(pipeline)
                                },
                                onDelete: {
                                    pipelineManager.deletePipeline(pipeline)
                                },
                                onStartEdit: {
                                    editingPipeline = pipeline
                                    editName = pipeline.name
                                },
                                onSaveEdit: {
                                    if let editing = editingPipeline {
                                        pipelineManager.renamePipeline(editing, newName: editName)
                                        editingPipeline = nil
                                    }
                                },
                                onCancelEdit: {
                                    editingPipeline = nil
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack(spacing: 12) {
                Button("Close") {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                if selectedPipeline != nil {
                    Button("Load Selected") {
                        if let pipeline = selectedPipeline {
                            loadPipeline(pipeline)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 500, height: 400)
    }

    private func loadPipeline(_ pipeline: SavedPipeline) {
        let tasks = pipelineManager.loadPipeline(pipeline)
        timerManager.tasks = tasks
        isPresented = false
    }
}

// MARK: - Pipeline Row View

struct PipelineRowView: View {
    let pipeline: SavedPipeline
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editName: String
    let onSelect: () -> Void
    let onLoad: () -> Void
    let onDelete: () -> Void
    let onStartEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if isEditing {
                        HStack {
                            TextField("Pipeline name", text: $editName)
                                .textFieldStyle(.roundedBorder)
                                .font(.headline)

                            Button("✓") {
                                onSaveEdit()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.green)

                            Button("✕") {
                                onCancelEdit()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                        }
                    } else {
                        Text(pipeline.name)
                            .font(.headline)
                            .onTapGesture(count: 2) {
                                onStartEdit()
                            }
                    }

                    HStack(spacing: 12) {
                        Text("\(pipeline.taskCount) tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(formatDuration(pipeline.totalDuration))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let lastUsed = pipeline.lastUsed {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("Last used \(formatDate(lastUsed))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: onLoad) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Load this pipeline")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("Delete this pipeline")
                }
            }
        }
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60

        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(Int(minutes))m"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Clickable TextField Wrapper

struct ClickableTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void
    var autoFocus: Bool = false

    func makeNSView(context: Context) -> ForceFocusTextField {
        let textField = ForceFocusTextField()
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.delegate = context.coordinator
        textField.refusesFirstResponder = false

        // Set text color to adapt to appearance
        textField.textColor = .labelColor

        // Set placeholder color with better contrast
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: 14, weight: .medium)
        ]
        textField.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: placeholderAttributes
        )

        // Auto-focus if requested
        if autoFocus {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                textField.window?.makeFirstResponder(textField)
            }
        }

        return textField
    }

    func updateNSView(_ nsView: ForceFocusTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        // Update text color to adapt to appearance changes
        nsView.textColor = .labelColor

        // Update placeholder attributes when appearance changes
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.placeholderTextColor,
            .font: NSFont.systemFont(ofSize: 14, weight: .medium)
        ]
        nsView.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: placeholderAttributes
        )

        // Auto-focus on first update if requested and not already focused
        // Use asyncAfter to ensure it happens after the current update cycle completes
        if autoFocus && !context.coordinator.hasFocused && nsView.window != nil {
            context.coordinator.hasFocused = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: ClickableTextField
        var hasFocused: Bool = false

        init(_ parent: ClickableTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit()
                return true
            }
            // Return false for other commands to allow default handling (prevents beeping)
            // Common editing commands that should be allowed: deleteBackward, deleteForward, moveLeft, moveRight, etc.
            return false
        }

        // Override this to prevent beeping on unsupported commands
        func control(_ control: NSControl, isValidObject obj: Any?) -> Bool {
            return true
        }
    }
}

class ForceFocusTextField: NSTextField {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.focusRingType = .none
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.focusRingType = .none
    }

    override func mouseDown(with event: NSEvent) {
        // Force become first responder on ANY click
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override var focusRingType: NSFocusRingType {
        get { return .none }
        set { }
    }

    // Prevent beeping - override to handle all key events
    override func keyDown(with event: NSEvent) {
        // Just pass through to the field editor - this prevents beeping
        self.currentEditor()?.keyDown(with: event) ?? super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Don't intercept key equivalents - let them be handled normally
        return false
    }
}

#Preview {
    ContentView(timerManager: TimerManager(), pipelineManager: PipelineManager())
}
