//
//  AddTaskView.swift
//  TaskPipeline
//
//  Sheet view for adding new tasks
//

import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var timerManager: TimerManager

    @State private var taskName: String = ""
    @State private var durationMinutes: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Task")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Task Name")
                    .font(.headline)

                TextField("Enter task name", text: $taskName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Duration (minutes)")
                    .font(.headline)

                TextField("Enter duration", text: $durationMinutes)
                    .textFieldStyle(.roundedBorder)
            }

            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Add Task") {
                    addTask()
                }
                .buttonStyle(.borderedProminent)
                .disabled(taskName.isEmpty || durationMinutes.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 400)
    }

    private func addTask() {
        guard !taskName.isEmpty else {
            showError(message: "Task name is required")
            return
        }

        guard let duration = Double(durationMinutes), duration > 0 else {
            showError(message: "Please enter a valid duration")
            return
        }

        let task = TimerTask(name: taskName, durationMinutes: duration)
        timerManager.addTask(task)
        dismiss()
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
}
