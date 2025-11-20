//
//  TaskPipelineApp.swift
//  TaskPipeline
//
//  A macOS menubar app for managing sequential countdown timers
//

import SwiftUI

@main
struct TaskPipelineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
