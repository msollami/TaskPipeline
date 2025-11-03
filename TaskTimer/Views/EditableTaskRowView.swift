//
//  EditableTaskRowView.swift
//  TaskTimer
//
//  Editable task row with draggable duration slider
//

import SwiftUI

struct EditableTaskRowView: View {
    let task: TimerTask
    let index: Int
    @ObservedObject var timerManager: TimerManager
    @State private var isEditingName: Bool = false
    @State private var editName: String = ""
    @State private var sliderValue: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .font(.caption)

            // Order number
            Text("\(index + 1).")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            VStack(alignment: .leading, spacing: 8) {
                // Task name - editable on click
                if isEditingName {
                    HStack {
                        TextField("Task name", text: $editName, onCommit: {
                            saveNameChange()
                        })
                        .textFieldStyle(.roundedBorder)
                        .font(.headline)

                        Button("Done") {
                            saveNameChange()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } else {
                    Text(task.name)
                        .font(.headline)
                        .onTapGesture {
                            startEditingName()
                        }
                }

                // Duration slider - always visible and draggable
                HStack(spacing: 8) {
                    Text("\(Int(sliderValue))m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                        .monospacedDigit()

                    Slider(value: $sliderValue, in: 1...120, step: 1, onEditingChanged: { editing in
                        if !editing {
                            saveDurationChange()
                        }
                    })
                    .tint(.accentColor)

                    Text("120m")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.5))
                        .frame(width: 35, alignment: .leading)
                }
            }

            Spacer()

            Button(action: {
                timerManager.removeTask(at: index)
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
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
}
