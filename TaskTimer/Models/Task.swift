//
//  Task.swift
//  TaskTimer
//
//  Data model for timer tasks
//

import Foundation

struct TimerTask: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var durationMinutes: Double
    var isCompleted: Bool
    var colorIndex: Int
    var proportion: Double? // For proportional mode (0.0 to 1.0)
    var isBreak: Bool // Whether this is a break task

    init(id: UUID = UUID(), name: String, durationMinutes: Double, isCompleted: Bool = false, colorIndex: Int = 0, proportion: Double? = nil, isBreak: Bool = false) {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
        self.isCompleted = isCompleted
        self.colorIndex = colorIndex
        self.proportion = proportion
        self.isBreak = isBreak
    }

    var durationSeconds: TimeInterval {
        return durationMinutes * 60
    }

    var formattedDuration: String {
        let hours = Int(durationMinutes) / 60
        let minutes = Int(durationMinutes) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(Int(durationMinutes))m"
        }
    }
}

// MARK: - Saved Pipelines

struct SavedPipeline: Identifiable, Codable {
    let id: UUID
    var name: String
    var tasks: [PipelineTask]
    var createdAt: Date
    var lastUsed: Date?

    init(id: UUID = UUID(), name: String, tasks: [PipelineTask], createdAt: Date = Date(), lastUsed: Date? = nil) {
        self.id = id
        self.name = name
        self.tasks = tasks
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }

    var totalDuration: Double {
        tasks.reduce(0) { $0 + $1.durationMinutes }
    }

    var taskCount: Int {
        tasks.count
    }
}

struct PipelineTask: Identifiable, Codable {
    let id: UUID
    var name: String
    var durationMinutes: Double
    var colorIndex: Int
    var isBreak: Bool

    init(id: UUID = UUID(), name: String, durationMinutes: Double, colorIndex: Int = 0, isBreak: Bool = false) {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
        self.colorIndex = colorIndex
        self.isBreak = isBreak
    }

    // Convert to TimerTask
    func toTimerTask() -> TimerTask {
        return TimerTask(name: name, durationMinutes: durationMinutes, colorIndex: colorIndex, isBreak: isBreak)
    }
}

// Convert TimerTask to PipelineTask
extension TimerTask {
    func toPipelineTask() -> PipelineTask {
        return PipelineTask(name: name, durationMinutes: durationMinutes, colorIndex: colorIndex, isBreak: isBreak)
    }
}

// MARK: - Pipeline Manager

class PipelineManager: ObservableObject {
    @Published var savedPipelines: [SavedPipeline] = []

    private let storageKey = "savedPipelines"

    init() {
        loadPipelines()
    }

    // MARK: - Persistence

    func loadPipelines() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedPipeline].self, from: data) else {
            return
        }
        savedPipelines = decoded.sorted { $0.lastUsed ?? $0.createdAt > $1.lastUsed ?? $1.createdAt }
    }

    func savePipelines() {
        guard let encoded = try? JSONEncoder().encode(savedPipelines) else {
            print("Failed to encode pipelines")
            return
        }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    // MARK: - Pipeline Operations

    func savePipeline(name: String, tasks: [TimerTask]) {
        let pipelineTasks = tasks.map { $0.toPipelineTask() }
        let pipeline = SavedPipeline(name: name, tasks: pipelineTasks)

        // Check if a pipeline with this name already exists
        if let index = savedPipelines.firstIndex(where: { $0.name == name }) {
            // Update existing
            savedPipelines[index] = pipeline
        } else {
            // Add new
            savedPipelines.append(pipeline)
        }

        savePipelines()
    }

    func loadPipeline(_ pipeline: SavedPipeline) -> [TimerTask] {
        // Update last used timestamp
        if let index = savedPipelines.firstIndex(where: { $0.id == pipeline.id }) {
            savedPipelines[index].lastUsed = Date()
            savePipelines()
        }

        return pipeline.tasks.map { $0.toTimerTask() }
    }

    func deletePipeline(_ pipeline: SavedPipeline) {
        savedPipelines.removeAll { $0.id == pipeline.id }
        savePipelines()
    }

    func renamePipeline(_ pipeline: SavedPipeline, newName: String) {
        if let index = savedPipelines.firstIndex(where: { $0.id == pipeline.id }) {
            savedPipelines[index].name = newName
            savePipelines()
        }
    }
}
