//
//  CompletionView.swift
//  TaskTimer
//
//  Session completion view
//

import SwiftUI

struct CompletionView: View {
    @ObservedObject var timerManager: TimerManager

    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            HStack(alignment: .center) {
                // Status icon - changes based on completion status
                if skippedTasksCount > 0 {
                    // Partial completion - show warning icon
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    }
                } else {
                    // Full completion - show success icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Session Complete!")
                        .font(.system(size: 18, weight: .bold))

                    HStack(spacing: 6) {
                        // Completed count
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text("\(completedTasksCount)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }

                        // Skipped count (if any)
                        if skippedTasksCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "forward.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Text("\(skippedTasksCount)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                        }

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text("\(totalDurationFormatted)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        if timerManager.pauseCount > 0 {
                            Text("•")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.5))

                            HStack(spacing: 3) {
                                Image(systemName: "pause.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text("\(timerManager.pauseCount)x")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text("(\(formatPauseDuration(timerManager.totalPausedSeconds)))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                // New Session button (compact)
                Button(action: {
                    timerManager.reset()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("New")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.08))

            Divider()

            // Compact task list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(timerManager.tasks.enumerated()), id: \.element.id) { index, task in
                        HStack(spacing: 12) {
                            // Status indicator
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "forward.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(task.isCompleted ? .green : .orange)
                                .frame(width: 20)

                            // Task number
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(task.isCompleted ? .secondary : .orange.opacity(0.6))
                                .frame(width: 24, alignment: .trailing)

                            // Task name (strikethrough for skipped)
                            if task.isCompleted {
                                Text(task.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            } else {
                                Text(task.name)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .strikethrough(true, color: .orange.opacity(0.7))
                                    .italic()
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Duration
                            Text(formatDuration(task.durationMinutes))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(task.isCompleted ? .secondary : .orange.opacity(0.7))
                                .frame(minWidth: 40, alignment: .trailing)
                                .strikethrough(!task.isCompleted, color: .orange.opacity(0.5))

                            // Status
                            if !task.isCompleted {
                                Text("SKIPPED")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(3)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            task.isCompleted
                                ? (index % 2 == 0 ? Color.clear : Color.secondary.opacity(0.04))
                                : Color.orange.opacity(0.06)
                        )
                        .opacity(task.isCompleted ? 1.0 : 0.75)

                        if index < timerManager.tasks.count - 1 {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
            }
        }
    }

    private var totalDurationFormatted: String {
        let totalMinutes = timerManager.tasks.reduce(0) { $0 + $1.durationMinutes }
        let hours = Int(totalMinutes) / 60
        let minutes = Int(totalMinutes) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(Int(totalMinutes)) min"
        }
    }

    private var completedTasksCount: Int {
        timerManager.tasks.filter { $0.isCompleted }.count
    }

    private var skippedTasksCount: Int {
        timerManager.tasks.filter { !$0.isCompleted }.count
    }

    private func formatDuration(_ minutes: Double) -> String {
        if minutes < 1 {
            let seconds = Int(minutes * 60)
            return "\(seconds)s"
        } else if minutes < 60 {
            return "\(Int(minutes))m"
        } else {
            let hours = Int(minutes) / 60
            let mins = Int(minutes) % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }

    private func formatPauseDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}

#Preview {
    let manager = TimerManager()
    manager.addTask(TimerTask(name: "Review Design", durationMinutes: 25, isCompleted: true))
    manager.addTask(TimerTask(name: "Write Code", durationMinutes: 45, isCompleted: true))
    manager.isCompleted = true
    return CompletionView(timerManager: manager)
}
