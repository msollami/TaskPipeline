//
//  AppDelegate.swift
//  TaskTimer
//
//  Manages menubar app lifecycle
//

import SwiftUI
import AppKit
import UserNotifications

// MARK: - Settings Section Component

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 4)

            content
        }
        .padding(16)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("maxTaskDuration") private var maxTaskDuration: Double = 120
    @AppStorage("completionSound") private var completionSound: String = "Ping"
    @AppStorage("speakTaskName") private var speakTaskName: Bool = true
    @AppStorage("bufferLength") private var bufferLength: Double = 0

    @State private var maxDurationText: String = "120"
    @State private var bufferLengthText: String = "0"

    let availableSounds = [
        "Ping",
        "Pop",
        "Purr",
        "Funk",
        "Glass",
        "Hero",
        "Morse",
        "Sosumi",
        "Tink",
        "Blow",
        "Bottle",
        "Frog",
        "Submarine"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(24)
            .background(Color.secondary.opacity(0.05))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Max task duration setting
                    SettingsSection(title: "Timer", icon: "clock") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Text("Maximum Task Duration")
                                    .font(.subheadline)
                                    .frame(width: 180, alignment: .leading)

                                TextField("", text: $maxDurationText)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                    .onSubmit {
                                        updateMaxDuration()
                                    }

                                Text("minutes")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text("Set the maximum duration for a single task (10-600 minutes).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 180)

                            Divider()
                                .padding(.vertical, 4)

                            HStack(spacing: 12) {
                                Text("Buffer Between Tasks")
                                    .font(.subheadline)
                                    .frame(width: 180, alignment: .leading)

                                TextField("", text: $bufferLengthText)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                    .onSubmit {
                                        updateBufferLength()
                                    }

                                Text("seconds")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text("Pause time between tasks (0-300 seconds).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 180)
                        }
                    }

                    // Sound settings
                    SettingsSection(title: "Audio", icon: "speaker.wave.2") {
                        VStack(alignment: .leading, spacing: 16) {
                            // Sound selection
                            HStack(spacing: 12) {
                                Text("Completion Sound")
                                    .font(.subheadline)
                                    .frame(width: 180, alignment: .leading)

                                Picker("", selection: $completionSound) {
                                    ForEach(availableSounds, id: \.self) { sound in
                                        Text(sound).tag(sound)
                                    }
                                }
                                .frame(width: 120)

                                Button(action: {
                                    if let sound = NSSound(named: completionSound) {
                                        sound.play()
                                    }
                                }) {
                                    Image(systemName: "play.circle")
                                        .font(.system(size: 16))
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.accentColor)
                                .help("Preview sound")
                            }

                            Divider()

                            // Text-to-speech option
                            HStack(spacing: 12) {
                                Text("Announce Task Names")
                                    .font(.subheadline)
                                    .frame(width: 180, alignment: .leading)

                                Toggle("", isOn: $speakTaskName)
                                    .labelsHidden()
                            }

                            Text("Speak the task name aloud when switching tasks.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 180)
                        }
                    }
                }
                .padding(24)
            }

            // Footer with buttons
            Divider()

            HStack(spacing: 12) {
                Button("Reset to Defaults") {
                    maxTaskDuration = 120
                    maxDurationText = "120"
                    bufferLength = 0
                    bufferLengthText = "0"
                    completionSound = "Ping"
                    speakTaskName = true
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Done") {
                    updateMaxDuration()
                    updateBufferLength()
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
            .background(Color.secondary.opacity(0.03))
        }
        .frame(width: 520, height: 450)
        .onAppear {
            maxDurationText = "\(Int(maxTaskDuration))"
            bufferLengthText = "\(Int(bufferLength))"
        }
    }

    private func updateMaxDuration() {
        if let value = Double(maxDurationText), value >= 10 && value <= 600 {
            maxTaskDuration = value
        } else {
            maxDurationText = "\(Int(maxTaskDuration))"
        }
    }

    private func updateBufferLength() {
        if let value = Double(bufferLengthText), value >= 0 && value <= 300 {
            bufferLength = value
        } else {
            bufferLengthText = "\(Int(bufferLength))"
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var timerManager = TimerManager()
    private var pipelineManager = PipelineManager()
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }

        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Task Timer")
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 600, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView(timerManager: timerManager, pipelineManager: pipelineManager))

        // Update menu bar icon and popover size when timer state changes
        timerManager.onStatusChange = { [weak self] isRunning in
            DispatchQueue.main.async {
                if let button = self?.statusItem.button {
                    if isRunning {
                        button.image = NSImage(systemSymbolName: "timer.circle.fill", accessibilityDescription: "Task Timer Running")
                        // Compact size when running
                        self?.popover.contentSize = NSSize(width: 500, height: 200)
                    } else {
                        button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Task Timer")
                        // Default size when editing
                        self?.popover.contentSize = NSSize(width: 600, height: 400)
                    }
                }
            }
        }

        // Show popover when task transitions
        timerManager.onTaskTransition = { [weak self] in
            DispatchQueue.main.async {
                self?.showPopover()
            }
        }
    }

    @objc func handleClick() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            togglePopover()
        }
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func showPopover() {
        if let button = statusItem.button {
            if !popover.isShown {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        if let button = statusItem.button {
            statusItem.menu = menu
            button.performClick(nil)
            statusItem.menu = nil
        }
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "Task Timer Settings"
            window.styleMask = [NSWindow.StyleMask.titled, NSWindow.StyleMask.closable]
            window.center()
            window.setFrameAutosaveName("Settings")
            window.isReleasedWhenClosed = false

            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerManager.reset()
    }
}
