//
//  TimerManager.swift
//  TaskTimer
//
//  Manages timer state, countdown logic, and sequential task progression
//

import Foundation
import AppKit
import UserNotifications
import AVFoundation

class TimerManager: ObservableObject {
    @Published var tasks: [TimerTask] = []
    @Published var currentTaskIndex: Int = 0
    @Published var remainingSeconds: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var isCompleted: Bool = false
    @Published var showTaskTransitionFlash: Bool = false
    @Published var pauseCount: Int = 0
    @Published var totalPausedSeconds: TimeInterval = 0

    private var timer: Timer?
    private var pauseStartTime: Date?
    private var nextColorIndex: Int = 0
    private let speechSynthesizer = AVSpeechSynthesizer()
    var onStatusChange: ((Bool) -> Void)?
    var onTaskTransition: (() -> Void)?

    var currentTask: TimerTask? {
        guard currentTaskIndex < tasks.count else { return nil }
        return tasks[currentTaskIndex]
    }

    var totalRemainingTime: TimeInterval {
        var total: TimeInterval = remainingSeconds

        for i in (currentTaskIndex + 1)..<tasks.count {
            total += tasks[i].durationSeconds
        }

        return total
    }

    var progress: Double {
        guard let task = currentTask else { return 0 }
        let elapsed = task.durationSeconds - remainingSeconds
        return elapsed / task.durationSeconds
    }

    func addTask(_ task: TimerTask) {
        var taskWithColor = task
        taskWithColor.colorIndex = nextColorIndex
        nextColorIndex = (nextColorIndex + 1) % 8  // Cycle through 8 colors
        tasks.append(taskWithColor)
    }

    func removeTask(at index: Int) {
        guard index < tasks.count else { return }
        tasks.remove(at: index)
    }

    func deleteCurrentTaskAndContinue() {
        guard isRunning, currentTaskIndex < tasks.count else { return }

        // Stop the timer
        timer?.invalidate()
        timer = nil

        // Remove the current task
        tasks.remove(at: currentTaskIndex)

        // Handle what to do next
        if tasks.isEmpty {
            // No more tasks, reset completely
            isRunning = false
            isPaused = false
            isCompleted = false
            onStatusChange?(false)
            currentTaskIndex = 0
            remainingSeconds = 0
        } else {
            // Adjust index if needed
            if currentTaskIndex >= tasks.count {
                currentTaskIndex = tasks.count - 1
            }

            // Start the new current task
            let task = tasks[currentTaskIndex]
            remainingSeconds = task.durationSeconds
            startTimer()
        }
    }

    func updateTask(at index: Int, name: String, durationMinutes: Double) {
        guard index < tasks.count else { return }
        tasks[index].name = name
        tasks[index].durationMinutes = durationMinutes
    }

    func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
    }

    var nextTask: TimerTask? {
        guard currentTaskIndex + 1 < tasks.count else { return nil }
        return tasks[currentTaskIndex + 1]
    }

    func start() {
        guard !tasks.isEmpty else { return }

        if !isRunning {
            isRunning = true
            isPaused = false
            onStatusChange?(true)

            if remainingSeconds == 0 {
                startNextTask()
            } else {
                resume()
            }
        }
    }

    func skipToNext() {
        guard isRunning else { return }

        timer?.invalidate()
        timer = nil

        // Don't mark as completed when skipping - leave isCompleted as false
        // The task remains with isCompleted = false to indicate it was skipped

        currentTaskIndex += 1

        // Check if there are more tasks
        if currentTaskIndex < tasks.count {
            startNextTask()
        } else {
            // No more tasks - mark session as completed
            isRunning = false
            isPaused = false
            isCompleted = true
            remainingSeconds = 0
            onStatusChange?(false)
        }
    }

    func pause() {
        isPaused = true
        pauseCount += 1
        pauseStartTime = Date()
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        isPaused = false

        // Calculate pause duration
        if let startTime = pauseStartTime {
            let pauseDuration = Date().timeIntervalSince(startTime)
            totalPausedSeconds += pauseDuration
            pauseStartTime = nil
        }

        startTimer()
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        isCompleted = false
        pauseCount = 0
        totalPausedSeconds = 0
        pauseStartTime = nil
        onStatusChange?(false)
        currentTaskIndex = 0
        remainingSeconds = 0

        for i in 0..<tasks.count {
            tasks[i].isCompleted = false
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            completeCurrentTask()
            return
        }

        remainingSeconds -= 1
    }

    private func completeCurrentTask() {
        timer?.invalidate()
        timer = nil

        if currentTaskIndex < tasks.count {
            tasks[currentTaskIndex].isCompleted = true
        }

        playCompletionSound()

        // Trigger visual flash for task transition
        showTaskTransitionFlash = true

        currentTaskIndex += 1

        if currentTaskIndex < tasks.count {
            // Check if there's a buffer configured
            let bufferSeconds = UserDefaults.standard.double(forKey: "bufferLength")
            if bufferSeconds > 0 {
                // Wait for buffer duration before starting next task
                DispatchQueue.main.asyncAfter(deadline: .now() + bufferSeconds) { [weak self] in
                    self?.startNextTask()
                }
            } else {
                startNextTask()
            }
        } else {
            isRunning = false
            isPaused = false
            isCompleted = true
            onStatusChange?(false)
        }
    }

    private func startNextTask() {
        guard currentTaskIndex < tasks.count else { return }

        let task = tasks[currentTaskIndex]
        remainingSeconds = task.durationSeconds
        startTimer()
    }

    private func playCompletionSound() {
        // Show the popover to display the transition
        onTaskTransition?()

        // Get user preferences
        let completionSound = UserDefaults.standard.string(forKey: "completionSound") ?? "Ping"
        let speakTaskName = UserDefaults.standard.object(forKey: "speakTaskName") as? Bool ?? true

        // Play selected sound
        if let sound = NSSound(named: completionSound) {
            sound.play()
        } else {
            NSSound.beep()
        }

        // Text-to-speech announcement
        if speakTaskName {
            speakTaskTransition()
        }

        // Send notification when task completes
        let content = UNMutableNotificationContent()

        if currentTaskIndex < tasks.count {
            let nextTask = tasks[currentTaskIndex]
            let duration = formatDurationForNotification(nextTask.durationMinutes)
            content.title = "Time to Switch Tasks!"
            content.body = "Next: \(nextTask.name) (\(duration))"
        } else {
            content.title = "All Tasks Complete!"
            content.body = "Great work! You've completed all your tasks."
        }

        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }

    private func speakTaskTransition() {
        var message = ""

        if currentTaskIndex < tasks.count {
            let nextTask = tasks[currentTaskIndex]
            message = "Next task: \(nextTask.name)"
        } else {
            message = "All tasks complete"
        }

        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Slightly slower for clarity

        speechSynthesizer.speak(utterance)
    }

    func formattedTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    private func formatDurationForNotification(_ minutes: Double) -> String {
        if minutes < 1 {
            let seconds = Int(minutes * 60)
            return "\(seconds) seconds"
        } else if minutes == 1 {
            return "1 minute"
        } else {
            return "\(Int(minutes)) minutes"
        }
    }
}
