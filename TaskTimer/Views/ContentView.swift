//
//  ContentView.swift
//  TaskTimer
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
                    .frame(minWidth: 450, idealWidth: 480, maxWidth: 550, minHeight: 300, idealHeight: 350, maxHeight: 500)
            } else if timerManager.isRunning {
                // Running mode - show focused view (compact)
                FocusedTaskView(timerManager: timerManager)
                    .frame(minWidth: 500, minHeight: 160)
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
    @State private var isEditingTotalTime: Bool = false
    @FocusState private var isTotalTimeFocused: Bool
    @State private var showPipelineLibrary: Bool = false
    @State private var showSavePipeline: Bool = false
    @State private var newPipelineName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Task Pipeline")
                    .font(.title)
                    .fontWeight(.bold)

                // Mode selector
                Picker("Pipeline Mode", selection: $timerManager.pipelineMode) {
                    Text("Fixed Duration").tag(PipelineMode.fixedDuration)
                    Text("Proportional").tag(PipelineMode.proportional)
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                .onChange(of: timerManager.pipelineMode) { newMode in
                    timerManager.setPipelineMode(newMode)
                }

                // Total time control for proportional mode
                if timerManager.pipelineMode == .proportional {
                    HStack(spacing: 8) {
                        Text("Total Time:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if isEditingTotalTime {
                            TextField("", text: $totalMinutesText)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 50)
                                .multilineTextAlignment(.trailing)
                                .focused($isTotalTimeFocused)
                                .onSubmit {
                                    applyTargetTimeChange()
                                }

                            Text("min")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button("✓") {
                                applyTargetTimeChange()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.green)
                            .font(.caption)
                        } else {
                            Button(action: {
                                startEditingTargetTime()
                            }) {
                                HStack(spacing: 4) {
                                    Text(formatTotalMinutes(timerManager.targetTotalMinutes))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Image(systemName: "pencil.circle")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !timerManager.tasks.isEmpty {
                    HStack(spacing: 8) {
                        Text("\(timerManager.tasks.count) tasks •")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Editable total time
                        HStack(spacing: 4) {
                            if isEditingTotalTime {
                                TextField("", text: $totalMinutesText)
                                    .textFieldStyle(.plain)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 50)
                                    .multilineTextAlignment(.trailing)
                                    .focused($isTotalTimeFocused)
                                    .onSubmit {
                                        applyTotalTimeChange()
                                    }

                                Text("min total")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Button("✓") {
                                    applyTotalTimeChange()
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.green)
                                .font(.caption)
                            } else {
                                Button(action: {
                                    startEditingTotalTime()
                                }) {
                                    HStack(spacing: 4) {
                                        Text(totalDurationFormatted)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)

                                        Image(systemName: "pencil.circle")
                                            .font(.caption)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
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
                    InteractiveTimelineBar(timerManager: timerManager)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }

                // Inline add task row
                AddTaskRowView(timerManager: timerManager)
                    .padding(.horizontal, 24)
                    .zIndex(200) // Keep above timeline segment editors

                Spacer()
            }

            Divider()

            // Controls
            HStack(spacing: 16) {
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

    private func startEditingTotalTime() {
        let totalMinutes = timerManager.tasks.reduce(0) { $0 + $1.durationMinutes }
        totalMinutesText = "\(Int(totalMinutes))"
        isEditingTotalTime = true
        isTotalTimeFocused = true
    }

    private func startEditingTargetTime() {
        totalMinutesText = "\(Int(timerManager.targetTotalMinutes))"
        isEditingTotalTime = true
        isTotalTimeFocused = true
    }

    private func applyTargetTimeChange() {
        guard let newTotalMinutes = Double(totalMinutesText), newTotalMinutes > 0 else {
            isEditingTotalTime = false
            return
        }

        timerManager.setTargetTotalMinutes(newTotalMinutes)
        isEditingTotalTime = false
    }

    private func applyTotalTimeChange() {
        guard let newTotalMinutes = Double(totalMinutesText), newTotalMinutes > 0 else {
            isEditingTotalTime = false
            return
        }

        let currentTotalMinutes = timerManager.tasks.reduce(0) { $0 + $1.durationMinutes }
        guard currentTotalMinutes > 0 else {
            isEditingTotalTime = false
            return
        }

        // Calculate scaling factor
        let scaleFactor = newTotalMinutes / currentTotalMinutes

        // Scale all tasks proportionally
        for (index, task) in timerManager.tasks.enumerated() {
            let newDuration = max(0.166, task.durationMinutes * scaleFactor)
            timerManager.updateTask(at: index, name: task.name, durationMinutes: newDuration)
        }

        isEditingTotalTime = false
    }
}

// MARK: - Interactive Timeline Bar (Primary Visual)

struct InteractiveTimelineBar: View {
    @ObservedObject var timerManager: TimerManager
    @State private var selectedTask: TimerTask?
    @State private var editingTask: TimerTask?
    @State private var draggedTask: TimerTask?
    @State private var currentDropTarget: UUID?
    @State private var isDraggingDivider: Bool = false

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
                                    if selectedTask?.id == task.id {
                                        selectedTask = nil
                                        editingTask = nil
                                    } else {
                                        selectedTask = task
                                        editingTask = nil
                                    }
                                },
                                onDoubleTap: {
                                    selectedTask = task
                                    editingTask = task
                                },
                                timerManager: timerManager,
                                onNameChange: { newName in
                                    if let idx = timerManager.tasks.firstIndex(where: { $0.id == task.id }) {
                                        timerManager.updateTask(at: idx, name: newName, durationMinutes: task.durationMinutes)
                                    }
                                },
                                onDurationChange: { newDuration in
                                    if let idx = timerManager.tasks.firstIndex(where: { $0.id == task.id }) {
                                        if timerManager.pipelineMode == .proportional {
                                            // Update proportion based on new duration
                                            let totalDuration = timerManager.tasks.reduce(0.0) { $0 + $1.durationMinutes }
                                            let oldDuration = task.durationMinutes
                                            let newTotal = totalDuration - oldDuration + newDuration
                                            timerManager.updateTask(at: idx, name: task.name, durationMinutes: newDuration)
                                            timerManager.tasks[idx].proportion = newDuration / newTotal
                                            timerManager.setTargetTotalMinutes(newTotal)
                                        } else {
                                            timerManager.updateTask(at: idx, name: task.name, durationMinutes: newDuration)
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

                    // Resize dividers for proportional mode
                    if timerManager.pipelineMode == .proportional && timerManager.tasks.count > 1 {
                        ForEach(0..<timerManager.tasks.count - 1, id: \.self) { index in
                            let xPosition = widths.prefix(index + 1).reduce(0, +) + CGFloat(index + 1) * 3 - 1.5
                            ResizeDivider(
                                onDrag: { delta in
                                    handleDividerDrag(at: index, delta: delta, totalWidth: geometry.size.width)
                                }
                            )
                            .frame(width: 8, height: 60)
                            .offset(x: xPosition, y: 0)
                        }
                    }
                }
            }
            .frame(height: 60)
            .cornerRadius(8)
            .onChange(of: draggedTask) { newValue in
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

            // Instructions with delete button for selected task
            HStack(spacing: 8) {
                Text("Click to select • Drag to reorder")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.7))

                if selectedTask != nil && editingTask == nil {
                    Button(action: {
                        if let selected = selectedTask,
                           let index = timerManager.tasks.firstIndex(where: { $0.id == selected.id }) {
                            timerManager.removeTask(at: index)
                            selectedTask = nil
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
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
        guard timerManager.pipelineMode == .proportional,
              dividerIndex < timerManager.tasks.count - 1,
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
    let onDrag: (CGFloat) -> Void
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Invisible wider hit area
            Rectangle()
                .fill(Color.clear)
                .frame(width: 8, height: 60)
                .contentShape(Rectangle())

            // Visible handle
            Capsule()
                .fill(Color.white.opacity(0.5))
                .frame(width: 3, height: 30)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 0)
        }
        .cursor(NSCursor.resizeLeftRight)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let delta = value.translation.width - dragOffset
                    dragOffset = value.translation.width
                    onDrag(delta)
                }
                .onEnded { _ in
                    dragOffset = 0
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
    let onDurationChange: (Double) -> Void
    let onDelete: () -> Void

    @State private var editName: String = ""
    @State private var sliderValue: Double = 0
    @State private var durationText: String = ""
    @State private var showEditor: Bool = false

    var body: some View {
        ZStack {
            // Main segment
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(TaskColorHelper.gradient(for: task.colorIndex))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? (isEditing ? Color.white : Color.white.opacity(0.6)) : Color.clear, lineWidth: isSelected ? 3 : 0)
                    )

                // Content - responsive layout based on width
                Group {
                    if width < 35 {
                        // Extremely narrow - show just duration vertically
                        VStack(spacing: 0) {
                            Text(formatDuration(task.durationMinutes))
                                .font(.system(size: 9, weight: .bold))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.6)
                        }
                        .padding(2)
                    } else if width < 80 {
                        // Very narrow - show only duration, centered
                        VStack(spacing: 0) {
                            Text(formatDuration(task.durationMinutes))
                                .font(.system(size: 11, weight: .bold))
                                .lineLimit(1)
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.5)
                        }
                        .padding(4)
                    } else if width < 120 {
                        // Narrow - show duration prominently, name smaller
                        VStack(spacing: 1) {
                            Text(formatDuration(task.durationMinutes))
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(1)
                                .foregroundColor(.white)

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
                            Text(task.name)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7)

                            Text(formatDuration(task.durationMinutes))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(6)
                    }
                }

            }
            .frame(width: width, height: 60)
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            .onTapGesture(count: 2) {
                onDoubleTap()
            }
            .onTapGesture(count: 1) {
                onTap()
            }

            // Expanded editor as overlay - doesn't affect layout
            if isEditing {
                VStack(spacing: 8) {
                    TextField("Task name", text: $editName, onCommit: {
                        onNameChange(editName)
                    })
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)

                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            TextField("", text: $durationText)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                                .monospacedDigit()
                                .frame(width: 50)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: durationText) { newValue in
                                    // Filter to only allow numbers and decimal point
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
                                        onDurationChange(value)
                                    } else {
                                        durationText = formatDurationNumber(sliderValue)
                                    }
                                }

                            Text("min")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        HStack(spacing: 4) {
                            Text(formatDuration(sliderValue))
                                .font(.caption2)
                                .monospacedDigit()
                                .frame(width: 40)
                                .foregroundColor(.white.opacity(0.9))

                            Slider(value: $sliderValue, in: 0.166...120, step: 0.166, onEditingChanged: { editing in
                                durationText = formatDurationNumber(sliderValue)
                                if !editing {
                                    onDurationChange(sliderValue)
                                }
                            })
                            .tint(.white.opacity(0.8))

                            Text("120m")
                                .font(.caption2)
                                .frame(width: 40)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }

                    Button(action: onDelete) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(.caption2)
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(TaskColorHelper.gradient(for: task.colorIndex))
                        .opacity(0.95)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                .frame(width: 240)
                .offset(y: 80)
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
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
            return String(format: "%.2f", minutes)
        } else {
            return String(format: "%.0f", minutes)
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
        let hash = abs(task.id.hashValue)
        return gradient(for: hash)
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
    @State private var taskName: String = ""
    @State private var durationText: String = "1"
    @State private var sliderValue: Double = 1.0
    @State private var proportionValue: Double = 1.0 // For proportional mode
    @State private var proportionText: String = "1"
    @AppStorage("maxTaskDuration") private var maxTaskDuration: Double = 120
    @State private var previousTaskCount: Int = 0
    private let minDuration: Double = 0.166 // 10 seconds
    private let minProportion: Double = 0.1
    private let maxProportion: Double = 10.0

    var body: some View {
        VStack(spacing: 8) {
            // Top row: Task name, duration/proportion, and add button
            HStack(spacing: 12) {
                // Task name input with cursor
                ClickableTextField(text: $taskName, placeholder: "Add task (optional)...", onSubmit: addTask)
                    .font(.system(size: 14, weight: .medium))

                // Duration or Proportion controls based on mode
                if timerManager.pipelineMode == .proportional {
                    HStack(spacing: 6) {
                        TextField("", text: $proportionText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.accentColor)
                            .frame(width: 35)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: proportionText) { newValue in
                                let filtered = newValue.filter { $0.isNumber || $0 == "." }
                                if filtered != newValue {
                                    proportionText = filtered
                                }

                                if let value = Double(filtered), value >= minProportion && value <= maxProportion {
                                    proportionValue = value
                                }
                            }
                            .onSubmit {
                                addTask()
                            }

                        Text("parts")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 80)
                } else {
                    HStack(spacing: 6) {
                        TextField("", text: $durationText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(durationColor(for: sliderValue))
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
                }

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

            // Bottom row: Visual slider bar with draggable thumb
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)

                    if timerManager.pipelineMode == .proportional {
                        // Proportion slider
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: max(8, geometry.size.width * CGFloat((proportionValue - minProportion) / (maxProportion - minProportion))), height: 8)

                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 16, height: 16)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                            )
                            .offset(x: max(0, min(geometry.size.width - 16, geometry.size.width * CGFloat((proportionValue - minProportion) / (maxProportion - minProportion)) - 8)))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let proportion = value.location.x / geometry.size.width
                                        let newValue = max(minProportion, min(maxProportion, minProportion + (proportion * (maxProportion - minProportion))))
                                        proportionValue = newValue
                                        proportionText = String(format: "%.1f", newValue)
                                    }
                            )
                    } else {
                        // Duration slider
                        Capsule()
                            .fill(durationColor(for: sliderValue))
                            .frame(width: max(8, geometry.size.width * CGFloat((sliderValue - minDuration) / (maxTaskDuration - minDuration))), height: 8)

                        Circle()
                            .fill(durationColor(for: sliderValue))
                            .frame(width: 16, height: 16)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
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
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let proportion = location.x / geometry.size.width

                    if timerManager.pipelineMode == .proportional {
                        let newValue = max(minProportion, min(maxProportion, minProportion + (proportion * (maxProportion - minProportion))))
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proportionValue = newValue
                            proportionText = String(format: "%.1f", newValue)
                        }
                    } else {
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
            }
            .frame(height: 16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .onChange(of: timerManager.tasks.count) { newCount in
            // Track when tasks are added or removed
            previousTaskCount = newCount
        }
        .onAppear {
            previousTaskCount = timerManager.tasks.count
        }
    }

    private func durationColor(for minutes: Double) -> Color {
        let maxDuration = maxTaskDuration
        let percentage = minutes / maxDuration

        // Create smooth gradient: green -> yellow -> orange -> red
        if percentage <= 0.33 {
            // Green to Yellow
            let local = percentage / 0.33
            return Color(
                red: local,  // 0 to 1.0
                green: 1.0,  // stays 1.0
                blue: 0
            )
        } else if percentage <= 0.66 {
            // Yellow to Orange
            let local = (percentage - 0.33) / 0.33
            return Color(
                red: 1.0,
                green: 1.0 - local * 0.5,  // 1.0 to 0.5
                blue: 0
            )
        } else {
            // Orange to Red
            let local = (percentage - 0.66) / 0.34
            return Color(
                red: 1.0,
                green: 0.5 - local * 0.5,  // 0.5 to 0
                blue: 0
            )
        }
    }

    private func addTask() {
        // Allow empty task names - use "Task" as default
        let finalName = taskName.trimmingCharacters(in: .whitespaces).isEmpty ? "Task" : taskName

        let task: TimerTask
        if timerManager.pipelineMode == .proportional {
            // In proportional mode, create task with proportion
            // Initial duration will be calculated by recalculateTaskDurations
            task = TimerTask(
                name: finalName,
                durationMinutes: 1.0, // Placeholder, will be recalculated
                proportion: proportionValue
            )
        } else {
            // In fixed duration mode, use the slider value
            task = TimerTask(name: finalName, durationMinutes: sliderValue)
        }

        timerManager.addTask(task)

        taskName = ""
        durationText = "1"
        sliderValue = 1.0
        proportionText = "1"
        proportionValue = 1.0
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

    func makeNSView(context: Context) -> ForceFocusTextField {
        let textField = ForceFocusTextField()
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.delegate = context.coordinator
        textField.refusesFirstResponder = false

        return textField
    }

    func updateNSView(_ nsView: ForceFocusTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: ClickableTextField

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
            return false
        }
    }
}

class ForceFocusTextField: NSTextField {
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
}

#Preview {
    ContentView(timerManager: TimerManager(), pipelineManager: PipelineManager())
}
