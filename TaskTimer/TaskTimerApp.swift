//
//  TaskTimerApp.swift
//  TaskTimer
//
//  A macOS menubar app for managing sequential countdown timers
//

import SwiftUI

@main
struct TaskTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
