//
//  TaskRowView.swift
//  TaskPipeline
//
//  Individual task row with progress indicator
//

import SwiftUI

struct TaskRowView: View {
    let task: TimerTask
    let isActive: Bool
    let remainingSeconds: TimeInterval?
    let progress: Double?
    let timerManager: TimerManager

    var body: some View {
        HStack(spacing: 16) {
            // Status Indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(statusColor)
                        .fontWeight(.bold)
                } else if isActive {
                    Image(systemName: "timer")
                        .foregroundColor(statusColor)
                } else {
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                }
            }

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .foregroundColor(isActive ? .primary : .secondary)

                if let remaining = remainingSeconds, isActive {
                    Text(timerManager.formattedTime(remaining))
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                } else {
                    Text(task.formattedDuration)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Progress Bar
                if let prog = progress, isActive {
                    ProgressView(value: prog)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                }
            }

            Spacer()
        }
        .padding()
        .background(isActive ? Color.accentColor.opacity(0.05) : Color.clear)
    }

    private var statusColor: Color {
        if task.isCompleted {
            return .green
        } else if isActive {
            return .accentColor
        } else {
            return .secondary
        }
    }
}
