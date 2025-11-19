//
//  FocusedTaskView.swift
//  TaskPipeline
//
//  Compact focused view with timeline-based interface
//

import SwiftUI

// MARK: - Scrolling Text View

struct ScrollingTextView: View {
    let text: String
    let font: Font
    let foregroundColor: Color

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var shouldScroll: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Measure text width
                Text(text)
                    .font(font)
                    .foregroundColor(foregroundColor)
                    .fixedSize()
                    .frame(maxWidth: .infinity, alignment: shouldScroll ? .leading : .center)
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear.preference(
                                key: TextWidthPreferenceKey.self,
                                value: textGeometry.size.width
                            )
                        }
                    )
                    .opacity(shouldScroll ? 0 : 1) // Hide if scrolling

                // Scrolling text (only visible if needed)
                if shouldScroll {
                    HStack(spacing: 40) {
                        Text(text)
                            .font(font)
                            .foregroundColor(foregroundColor)
                            .fixedSize()

                        Text(text)
                            .font(font)
                            .foregroundColor(foregroundColor)
                            .fixedSize()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .offset(x: offset)
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: Double(textWidth) / 15.0)
                                .repeatForever(autoreverses: false)
                        ) {
                            offset = -(textWidth + 40)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
            .clipped()
            .onPreferenceChange(TextWidthPreferenceKey.self) { width in
                textWidth = width
                containerWidth = geometry.size.width
                shouldScroll = width > geometry.size.width

                if shouldScroll {
                    offset = 0
                }
            }
        }
    }
}

struct TextWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Always Scrolling Text View

struct AlwaysScrollingTextView: View {
    let text: String
    let font: Font
    let foregroundColor: Color

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 150) {
                Text(text)
                    .font(font)
                    .foregroundColor(foregroundColor)
                    .fixedSize()
                    .background(
                        GeometryReader { textGeometry in
                            Color.clear.preference(
                                key: TextWidthPreferenceKey.self,
                                value: textGeometry.size.width
                            )
                        }
                    )

                Text(text)
                    .font(font)
                    .foregroundColor(foregroundColor)
                    .fixedSize()
            }
            .offset(x: offset)
            .onAppear {
                // Start animation after text width is measured
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    guard textWidth > 0 else { return }
                    withAnimation(
                        Animation.linear(duration: Double(textWidth + 150) / 30.0)
                            .repeatForever(autoreverses: false)
                    ) {
                        offset = -(textWidth + 150)
                    }
                }
            }
            .onPreferenceChange(TextWidthPreferenceKey.self) { width in
                textWidth = width
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
            .clipped()
        }
    }
}

// MARK: - Break Quote Scrolling View (Queue-based)

struct BreakQuoteScrollingView: View {
    let font: Font
    let foregroundColor: Color
    let getRandomQuote: () -> String

    @State private var quotes: [QuoteItem] = []
    @State private var offset: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    struct QuoteItem: Identifiable {
        let id = UUID()
        let text: String
        var width: CGFloat = 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                HStack(spacing: 80) {
                    ForEach(quotes) { quote in
                        Text(quote.text)
                            .font(font)
                            .foregroundColor(foregroundColor)
                            .fixedSize()
                            .background(
                                GeometryReader { textGeometry in
                                    Color.clear.onAppear {
                                        updateQuoteWidth(id: quote.id, width: textGeometry.size.width)
                                    }
                                }
                            )
                    }
                }
                .offset(x: offset)
                .onAppear {
                    containerWidth = geometry.size.width
                    offset = containerWidth  // Start quotes off screen to the right
                    // Start with first two quotes
                    quotes = [
                        QuoteItem(text: getRandomQuote()),
                        QuoteItem(text: getRandomQuote())
                    ]
                    // Scrolling will start automatically once first quote width is measured
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
            .clipped()
        }
    }

    private func updateQuoteWidth(id: UUID, width: CGFloat) {
        if let index = quotes.firstIndex(where: { $0.id == id }) {
            quotes[index].width = width

            // Only start scrolling once the first quote's width is measured
            // Check if offset equals containerWidth (initial position) to ensure we only start once
            if index == 0 && width > 0 && offset == containerWidth {
                animateScroll()
            }
        }
    }

    private func animateScroll() {
        guard !quotes.isEmpty else { return }

        let firstQuote = quotes[0]
        let spacing: CGFloat = 80

        // Calculate distance: scroll just enough to move first quote off screen
        let scrollDistance = firstQuote.width + spacing

        // Scroll at consistent speed: 50 pixels per second
        let duration = Double(scrollDistance) / 50.0

        withAnimation(.linear(duration: duration)) {
            offset -= scrollDistance
        }

        // After first quote scrolls off, remove it and add new one
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // Remove the quote that just scrolled off (without animation)
            if !quotes.isEmpty {
                quotes.removeFirst()
            }

            // Add a new quote to the end
            quotes.append(QuoteItem(text: getRandomQuote()))

            // Adjust offset to account for removed quote (no animation, so it's seamless)
            offset += scrollDistance

            // Continue scrolling
            animateScroll()
        }
    }
}

// MARK: - Digital Clock Components

struct DigitalClockView: View {
    let timeString: String
    let clockColor: Color
    let glowColor: Color

    init(timeString: String, clockColor: Color = Color(red: 0.2, green: 1.0, blue: 0.3), glowColor: Color = Color(red: 0.2, green: 1.0, blue: 0.3)) {
        self.timeString = timeString
        self.clockColor = clockColor
        self.glowColor = glowColor
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(timeString.enumerated()), id: \.offset) { index, char in
                if char == ":" {
                    ColonView(clockColor: clockColor, glowColor: glowColor)
                } else {
                    DigitView(digit: String(char), clockColor: clockColor, glowColor: glowColor)
                }
            }
        }
    }
}

struct DigitView: View {
    let digit: String
    let clockColor: Color
    let glowColor: Color

    var body: some View {
        ZStack {
            // Background dimmed segments
            SegmentedDigit(digit: digit, clockColor: clockColor, isBackground: true)
                .opacity(0.12)

            // Active glowing segments
            SegmentedDigit(digit: digit, clockColor: clockColor, isBackground: false)
                .foregroundColor(clockColor)
                .shadow(color: glowColor.opacity(0.8), radius: 6, x: 0, y: 0)
                .shadow(color: glowColor.opacity(0.4), radius: 3, x: 0, y: 0)
        }
        .frame(width: 18, height: 32)
    }
}

struct ColonView: View {
    let clockColor: Color
    let glowColor: Color

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(clockColor)
                .frame(width: 3, height: 3)
                .shadow(color: glowColor.opacity(0.8), radius: 3, x: 0, y: 0)

            Circle()
                .fill(clockColor)
                .frame(width: 3, height: 3)
                .shadow(color: glowColor.opacity(0.8), radius: 3, x: 0, y: 0)
        }
        .frame(width: 5, height: 32)
    }
}

struct SegmentedDigit: View {
    let digit: String
    let clockColor: Color
    let isBackground: Bool

    var body: some View {
        let segments = segmentsForDigit(digit)

        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let segmentWidth = width * 0.8
            let segmentHeight = (height - 6) / 2
            let thickness: CGFloat = 2.5

            ZStack {
                // Top horizontal (a)
                if isBackground || segments.contains("a") {
                    Capsule()
                        .fill(clockColor)
                        .frame(width: segmentWidth, height: thickness)
                        .position(x: width / 2, y: thickness / 2)
                }

                // Top right vertical (b)
                if isBackground || segments.contains("b") {
                    Capsule()
                        .fill(clockColor)
                        .frame(width: thickness, height: segmentHeight)
                        .position(x: width - thickness, y: height / 4)
                }

                // Bottom right vertical (c)
                if isBackground || segments.contains("c") {
                    Capsule()
                        .fill(clockColor)
                        .frame(width: thickness, height: segmentHeight)
                        .position(x: width - thickness, y: height * 0.75)
                }

                // Bottom horizontal (d)
                if isBackground || segments.contains("d") {
                    Capsule()
                        .fill(clockColor)
                        .frame(width: segmentWidth, height: thickness)
                        .position(x: width / 2, y: height - thickness / 2)
                }

                // Bottom left vertical (e)
                if isBackground || segments.contains("e") {
                    Capsule()
                        .fill(clockColor)
                        .frame(width: thickness, height: segmentHeight)
                        .position(x: thickness, y: height * 0.75)
                }

                // Top left vertical (f)
                if isBackground || segments.contains("f") {
                    Capsule()
                        .fill(clockColor)
                        .frame(width: thickness, height: segmentHeight)
                        .position(x: thickness, y: height / 4)
                }

                // Middle horizontal (g)
                if isBackground || segments.contains("g") {
                    Capsule()
                        .fill(clockColor)
                        .frame(width: segmentWidth, height: thickness)
                        .position(x: width / 2, y: height / 2)
                }
            }
        }
    }

    private func segmentsForDigit(_ digit: String) -> Set<String> {
        switch digit {
        case "0": return ["a", "b", "c", "d", "e", "f"]
        case "1": return ["b", "c"]
        case "2": return ["a", "b", "g", "e", "d"]
        case "3": return ["a", "b", "g", "c", "d"]
        case "4": return ["f", "g", "b", "c"]
        case "5": return ["a", "f", "g", "c", "d"]
        case "6": return ["a", "f", "g", "e", "d", "c"]
        case "7": return ["a", "b", "c"]
        case "8": return ["a", "b", "c", "d", "e", "f", "g"]
        case "9": return ["a", "b", "c", "d", "f", "g"]
        default: return []
        }
    }
}

struct FocusedTaskView: View {
    @ObservedObject var timerManager: TimerManager
    @AppStorage("clockGlowRed") private var clockGlowRed: Double = 0.2
    @AppStorage("clockGlowGreen") private var clockGlowGreen: Double = 1.0
    @AppStorage("clockGlowBlue") private var clockGlowBlue: Double = 0.3
    @AppStorage("clockColorRed") private var clockColorRed: Double = 0.2
    @AppStorage("clockColorGreen") private var clockColorGreen: Double = 1.0
    @AppStorage("clockColorBlue") private var clockColorBlue: Double = 0.3
    @AppStorage("useBlueClockDuringBreaks") private var useBlueClockDuringBreaks: Bool = false
    @AppStorage("syncClockToTaskColor") private var syncClockToTaskColor: Bool = false
    @State private var isFlashing: Bool = false

    var body: some View {
        // Safety check: Return empty if completed
        if timerManager.isCompleted {
            return AnyView(EmptyView())
        }

        // Determine clock colors based on break status and settings
        let isBreak = timerManager.currentTask?.isBreak ?? false
        let isPaused = timerManager.isPaused

        // Priority order:
        // 1. Blue color for breaks (if enabled)
        // 2. Task color sync (if enabled and not a break)
        // 3. Default custom color from settings
        let baseClockColor: Color
        let baseGlowColor: Color

        if isBreak && useBlueClockDuringBreaks {
            // Use blue for breaks
            baseClockColor = Color(red: 0.4, green: 0.8, blue: 1.0)
            baseGlowColor = Color(red: 0.4, green: 0.8, blue: 1.0)
        } else if syncClockToTaskColor, let currentTask = timerManager.currentTask, !currentTask.isBreak {
            // Sync to task color (only for non-break tasks)
            let taskColor = extractTaskColor(from: currentTask)
            baseClockColor = taskColor
            baseGlowColor = taskColor
        } else {
            // Use default custom colors from settings
            baseClockColor = Color(red: clockColorRed, green: clockColorGreen, blue: clockColorBlue)
            baseGlowColor = Color(red: clockGlowRed, green: clockGlowGreen, blue: clockGlowBlue)
        }

        // Dim when paused
        let finalClockColor = isPaused ? baseClockColor.opacity(0.3) : baseClockColor
        let finalGlowColor = isPaused ? baseGlowColor.opacity(0.3) : baseGlowColor

        return AnyView(
        ZStack {
            CompactTimelineView(
                timerManager: timerManager,
                clockColor: finalClockColor,
                glowColor: finalGlowColor
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Task transition flash overlay
            if isFlashing {
                ZStack {
                    // Semi-transparent dark background
                    Rectangle()
                        .fill(Color.black.opacity(0.85))
                        .ignoresSafeArea()

                    // Next task indicator card
                    if let nextTask = timerManager.currentTask {
                        HStack(spacing: 20) {
                            // Checkmark icon
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.6))
                                    .frame(width: 60, height: 60)
                                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 0)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            // "Next Task" label
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NEXT TASK")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .tracking(2)

                                // Task name
                                Text(nextTask.name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.6)

                                // Duration info
                                Text(formatTaskDuration(nextTask.durationMinutes))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .scaleEffect(isFlashing ? 1.0 : 0.9)
                        .padding(30)
                    }
                }
                .transition(.opacity)
            }
        }
        .onChange(of: timerManager.showTaskTransitionFlash) { shouldFlash in
            if shouldFlash {
                withAnimation(.easeIn(duration: 0.2)) {
                    isFlashing = true
                }

                // Hide flash after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isFlashing = false
                    }
                    timerManager.showTaskTransitionFlash = false
                }
            }
        }
        )
    }

    private func formatTaskDuration(_ minutes: Double) -> String {
        if minutes < 1 {
            let seconds = Int(minutes * 60)
            return "\(seconds) seconds"
        } else if minutes == 1 {
            return "1 minute"
        } else {
            return "\(Int(minutes)) minutes"
        }
    }

    private func extractTaskColor(from task: TimerTask) -> Color {
        // Get the gradient colors for this task
        let gradients: [(Color, Color)] = [
            (Color(red: 0.4, green: 0.5, blue: 0.85), Color(red: 0.6, green: 0.4, blue: 0.85)),
            (Color(red: 0.65, green: 0.35, blue: 0.85), Color(red: 0.85, green: 0.4, blue: 0.7)),
            (Color(red: 0.9, green: 0.4, blue: 0.65), Color(red: 0.95, green: 0.55, blue: 0.4)),
            (Color(red: 0.95, green: 0.6, blue: 0.35), Color(red: 0.95, green: 0.75, blue: 0.4)),
            (Color(red: 0.35, green: 0.75, blue: 0.5), Color(red: 0.35, green: 0.7, blue: 0.75)),
            (Color(red: 0.3, green: 0.7, blue: 0.85), Color(red: 0.4, green: 0.55, blue: 0.85)),
            (Color(red: 0.45, green: 0.4, blue: 0.85), Color(red: 0.6, green: 0.45, blue: 0.8)),
            (Color(red: 0.35, green: 0.75, blue: 0.7), Color(red: 0.4, green: 0.75, blue: 0.55))
        ]

        let colorPair = gradients[task.colorIndex % gradients.count]

        // Return the first (leading) color from the gradient
        return colorPair.0
    }
}

// MARK: - Modern Compact Timeline View

struct CompactTimelineView: View {
    @ObservedObject var timerManager: TimerManager
    let clockColor: Color
    let glowColor: Color

    var body: some View {
        // Safety check: Don't render if completed or no tasks
        if timerManager.isCompleted || timerManager.tasks.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 12) {
                // Top row: Clock, task name, and task counter
                HStack(alignment: .center, spacing: 12) {
                    // Left: Clock (fixed width to prevent shifting)
                    DigitalClockView(
                        timeString: timerManager.formattedTime(timerManager.remainingSeconds),
                        clockColor: clockColor,
                        glowColor: glowColor
                    )
                    .frame(width: 105, alignment: .leading)

                    Spacer(minLength: 8)

                    // Center: Current task name with scrolling (wider area) or Paused indicator
                    if timerManager.isPaused {
                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                            Text("PAUSED")
                                .font(.custom("Avenir Next", size: 20).weight(.semibold))
                                .foregroundColor(.orange)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .frame(minWidth: 200, maxWidth: .infinity)
                        .frame(height: 30)
                    } else if let currentTask = timerManager.currentTask {
                        if currentTask.isBreak {
                            // Fun break mode with quotes - smooth queue-based scrolling
                            BreakQuoteScrollingView(
                                font: .custom("Avenir Next", size: 20).weight(.medium),
                                foregroundColor: Color(red: 0.4, green: 0.8, blue: 1.0),
                                getRandomQuote: getRandomBreakQuote
                            )
                            .shadow(color: Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.5), radius: 4, x: 0, y: 2)
                            .frame(minWidth: 200, maxWidth: .infinity)
                            .frame(height: 30)
                        } else {
                            AlwaysScrollingTextView(
                                text: "Current Focus: \(currentTask.name)",
                                font: .custom("Avenir Next", size: 20).weight(.medium),
                                foregroundColor: .primary
                            )
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .frame(minWidth: 200, maxWidth: .infinity)
                            .frame(height: 30)
                        }
                    }

                    Spacer(minLength: 8)

                    // Right: Task counter and total time remaining
                    VStack(alignment: .trailing, spacing: 3) {
                        if !timerManager.tasks.isEmpty {
                            let currentIndex = min(timerManager.currentTaskIndex + 1, timerManager.tasks.count)
                            Text("Task \(currentIndex)/\(timerManager.tasks.count)")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)

                            Text("\(formattedTotalRemaining) left")
                                .font(.system(size: 9, weight: .regular))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                    .frame(width: 80, alignment: .trailing)
                }

            // Timeline bar with controls on the right
            HStack(alignment: .center, spacing: 16) {
                // Wide timeline bar (storage-style)
                VStack(spacing: 4) {
                    if !timerManager.tasks.isEmpty {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Task segments
                                HStack(spacing: 1) {
                                    ForEach(Array(timerManager.tasks.enumerated()), id: \.element.id) { index, task in
                                        let width = segmentWidth(for: task, totalWidth: geometry.size.width)

                                        ZStack(alignment: .center) {
                                            Rectangle()
                                                .fill(TaskColorHelper.gradient(for: task))
                                                .opacity(index < timerManager.currentTaskIndex ? 0.5 : 1.0)

                                            if width > 40 {
                                                Text(task.name)
                                                    .font(.system(size: 9, weight: .semibold))
                                                    .foregroundColor(.white.opacity(0.9))
                                                    .lineLimit(1)
                                                    .multilineTextAlignment(.center)
                                                    .padding(.horizontal, 6)
                                                    .frame(maxWidth: .infinity)
                                            }
                                        }
                                        .frame(width: width, height: 28)
                                    }
                                }
                                .frame(height: 28)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                                // Gray overlay for completed portion (left of progress bar)
                                let progress = calculateProgress()
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.black.opacity(0.4),
                                                Color.black.opacity(0.35)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * progress, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .blendMode(.multiply)

                                // Progress indicator line
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 3, height: 34)
                                    .shadow(color: .black.opacity(0.5), radius: 3)
                                    .offset(x: geometry.size.width * progress - 1.5, y: -3)
                            }
                        }
                        .frame(height: 28)

                        // Time scale ticks
                        TimeScaleTicks(totalMinutes: totalDurationMinutes)
                            .frame(height: 24)
                    }
                }

                // Control buttons (right of timeline, centered to bar height)
                HStack(spacing: 12) {
                    Button(action: {
                        if timerManager.isPaused {
                            timerManager.resume()
                        } else {
                            timerManager.pause()
                        }
                    }) {
                        Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(ModernButtonStyle(isPrimary: true))
                    .focusable(false)

                    Button(action: { timerManager.skipToNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(ModernButtonStyle())
                    .focusable(false)

                    Button(action: { timerManager.reset() }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(ModernButtonStyle(isDestructive: true))
                    .focusable(false)
                }
                .offset(y: -12)
            }
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 1)
        }
    }

    private func segmentWidth(for task: TimerTask, totalWidth: CGFloat) -> CGFloat {
        let totalDuration = timerManager.tasks.reduce(0) { $0 + $1.durationMinutes }
        guard totalDuration > 0 else { return 0 }

        let taskCount = timerManager.tasks.count
        let spacing: CGFloat = 1
        let totalSpacing = spacing * CGFloat(max(taskCount - 1, 0))
        let availableWidth = max(totalWidth - totalSpacing, 0)

        guard availableWidth > 0 else { return 0 }

        let proportion = task.durationMinutes / totalDuration
        return max(availableWidth * proportion, 1)
    }

    private func calculateProgress() -> CGFloat {
        guard !timerManager.tasks.isEmpty else { return 0 }

        let totalDuration = timerManager.tasks.reduce(0) { $0 + $1.durationMinutes }
        guard totalDuration > 0 else { return 0 }

        // Ensure we have a valid current task index
        guard timerManager.currentTaskIndex < timerManager.tasks.count else { return 1.0 }

        var elapsedMinutes: Double = 0

        for (index, task) in timerManager.tasks.enumerated() {
            if index < timerManager.currentTaskIndex {
                elapsedMinutes += task.durationMinutes
            } else if index == timerManager.currentTaskIndex {
                if let currentTask = timerManager.currentTask {
                    let taskElapsed = currentTask.durationMinutes - (Double(timerManager.remainingSeconds) / 60.0)
                    elapsedMinutes += taskElapsed
                }
                break
            }
        }

        // If we've gone past all tasks, return 100%
        if timerManager.currentTaskIndex >= timerManager.tasks.count {
            return 1.0
        }

        return CGFloat(elapsedMinutes / totalDuration)
    }

    private var formattedTotalRemaining: String {
        let totalSeconds = timerManager.totalRemainingTime
        let minutes = Int(totalSeconds) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var totalDurationMinutes: Double {
        guard !timerManager.tasks.isEmpty else { return 1.0 }
        return timerManager.tasks.reduce(0) { $0 + $1.durationMinutes }
    }

    private func getRandomBreakQuote() -> String {
        let quotes = [
            "☕ Time to recharge! Your brain needs this break.",
            "🌟 Great work so far! Stretch those legs.",
            "🧘 Breathe in, breathe out. You've got this!",
            "💪 Taking breaks makes you more productive.",
            "🎯 Short breaks = Better focus later.",
            "🌈 You're doing amazing! Keep it up.",
            "⏸️ Pause. Reflect. Return stronger.",
            "🚀 Rest now, achieve more later.",
            "🎨 Creativity needs rest to flourish.",
            "💡 The best ideas come during breaks.",
            "🌊 Flow requires rest. Embrace it.",
            "🎵 Step away from the screen. Dance a little!",
            "🌺 Your mind is a garden. Water it with rest.",
            "⚡ Recharging... Please wait... Just kidding, relax!",
            "🏆 Champions rest between rounds.",
            "🔥 You're on fire! Cool down for a moment.",
            "🎪 Life's a balance. This is your balance beam.",
            "🌙 Even the moon takes breaks. So should you.",
            "🎲 Lucky break! Literally.",
            "🍃 Like trees in autumn, release and renew."
        ]
        return quotes.randomElement() ?? "🎉 Break time! You earned it."
    }
}

// MARK: - Time Scale Ticks

struct TimeScaleTicks: View {
    let totalMinutes: Double

    var body: some View {
        GeometryReader { geometry in
            // Safety check for invalid totalMinutes
            guard totalMinutes > 0 else {
                return AnyView(EmptyView())
            }

            return AnyView(
            ZStack(alignment: .leading) {
                // Calculate ticks
                let tickCount = calculateTickCount(totalMinutes: totalMinutes)
                let interval = totalMinutes / Double(tickCount)

                // Start tick (0) - align text left edge at x=0
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 1, height: 6)
                    Text("0")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .leading)
                }
                .position(x: 15, y: 12)

                // Intermediate ticks - center text on tick position
                if tickCount > 1 {
                    ForEach(1..<tickCount, id: \.self) { index in
                        let minutes = interval * Double(index)
                        let position = geometry.size.width * (minutes / totalMinutes)
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.5))
                                .frame(width: 1, height: 6)
                            Text(formatMinutes(minutes))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 30)
                        }
                        .position(x: position, y: 12)
                    }
                }

                // End tick (total) - align text right edge at x=width
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 1, height: 6)
                    Text(formatMinutes(totalMinutes))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .trailing)
                }
                .position(x: geometry.size.width - 15, y: 12)
            }
            )
        }
    }

    private func calculateTickCount(totalMinutes: Double) -> Int {
        // For sub-minute durations
        if totalMinutes < 1 {
            let totalSeconds = Int(totalMinutes * 60)
            if totalSeconds <= 10 {
                return 2
            } else if totalSeconds <= 30 {
                return 3
            } else {
                return 4
            }
        }

        let rounded = Int(round(totalMinutes))

        // Ensure minimum of 2 ticks for valid range
        if rounded <= 1 {
            return 2
        } else if rounded <= 5 {
            return rounded // 2, 3, 4, 5
        } else if rounded <= 10 {
            return 5 // 0, 2, 4, 6, 8, 10
        } else if rounded <= 30 {
            return 4 // 0, 10, 20, 30
        } else if rounded <= 60 {
            return 5 // 0, 15, 30, 45, 60
        } else if rounded <= 120 {
            return 5 // 0, 30, 60, 90, 120
        } else {
            return 5 // 0, 25%, 50%, 75%, 100%
        }
    }

    private func formatMinutes(_ minutes: Double) -> String {
        // For sub-minute durations, show seconds
        if minutes < 1 {
            let seconds = Int(round(minutes * 60))
            return "\(seconds)s"
        }

        let rounded = Int(round(minutes))
        if rounded >= 60 {
            let hours = rounded / 60
            let mins = rounded % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h\(mins)"
            }
        } else {
            return "\(rounded)m"
        }
    }
}

// MARK: - Modern Button Style

struct ModernButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    var isPrimary: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
            )
            .foregroundColor(foregroundColor)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isPrimary {
            return isPressed ? Color.gray.opacity(0.35) : Color.gray.opacity(0.25)
        } else if isDestructive {
            return isPressed ? Color.gray.opacity(0.35) : Color.gray.opacity(0.25)
        } else {
            return isPressed ? Color.gray.opacity(0.25) : Color.gray.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        if isPrimary {
            return .primary
        } else if isDestructive {
            return .secondary
        } else {
            return .primary
        }
    }
}

#Preview {
    let manager = TimerManager()
    manager.addTask(TimerTask(name: "Review Design Mockups", durationMinutes: 25))
    manager.addTask(TimerTask(name: "Write Code", durationMinutes: 45))
    manager.start()
    return FocusedTaskView(timerManager: manager)
}
