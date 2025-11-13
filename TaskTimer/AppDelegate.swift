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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.accentColor)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 2)

            content
        }
        .padding(12)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("maxTaskDuration") private var maxTaskDuration: Double = 120
    @AppStorage("completionSound") private var completionSound: String = "Ping"
    @AppStorage("speakTaskName") private var speakTaskName: Bool = true
    @AppStorage("bufferLength") private var bufferLength: Double = 0
    @AppStorage("clockGlowRed") private var clockGlowRed: Double = 0.2
    @AppStorage("clockGlowGreen") private var clockGlowGreen: Double = 1.0
    @AppStorage("clockGlowBlue") private var clockGlowBlue: Double = 0.3
    @AppStorage("clockColorRed") private var clockColorRed: Double = 0.2
    @AppStorage("clockColorGreen") private var clockColorGreen: Double = 1.0
    @AppStorage("clockColorBlue") private var clockColorBlue: Double = 0.3

    @State private var maxDurationText: String = "120"
    @State private var bufferLengthText: String = "0"
    @State private var clockGlowColor: Color = Color(red: 0.2, green: 1.0, blue: 0.3)
    @State private var clockColor: Color = Color(red: 0.2, green: 1.0, blue: 0.3)

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
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(12)
            .background(Color.secondary.opacity(0.05))

            // Two-column layout
            HStack(alignment: .top, spacing: 16) {
                // Left column
                VStack(alignment: .leading, spacing: 10) {
                    Text("Timer")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    SettingRow(label: "Max Duration") {
                        HStack(spacing: 4) {
                            TextField("", text: $maxDurationText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                                .onSubmit { updateMaxDuration() }
                            Text("min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    SettingRow(label: "Buffer") {
                        HStack(spacing: 4) {
                            TextField("", text: $bufferLengthText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                                .onSubmit { updateBufferLength() }
                            Text("sec")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("Appearance")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    SettingRow(label: "Clock Color") {
                        ColorPicker("", selection: $clockColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 40)
                            .onChange(of: clockColor) { updateClockColor($0) }
                    }

                    SettingRow(label: "Clock Glow") {
                        ColorPicker("", selection: $clockGlowColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 40)
                            .onChange(of: clockGlowColor) { updateGlowColor($0) }
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Right column
                VStack(alignment: .leading, spacing: 10) {
                    Text("Audio")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    SettingRow(label: "Sound") {
                        HStack(spacing: 6) {
                            Picker("", selection: $completionSound) {
                                ForEach(availableSounds, id: \.self) { sound in
                                    Text(sound).tag(sound)
                                }
                            }
                            .frame(width: 90)

                            Button(action: {
                                if let sound = NSSound(named: completionSound) {
                                    sound.play()
                                }
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                        }
                    }

                    SettingRow(label: "Announce") {
                        Toggle("", isOn: $speakTaskName)
                            .labelsHidden()
                            .controlSize(.small)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(12)

            // Footer with buttons
            Divider()

            HStack(spacing: 12) {
                Button("Reset") {
                    maxTaskDuration = 120
                    maxDurationText = "120"
                    bufferLength = 0
                    bufferLengthText = "0"
                    completionSound = "Ping"
                    speakTaskName = true
                    clockGlowRed = 0.2
                    clockGlowGreen = 1.0
                    clockGlowBlue = 0.3
                    clockGlowColor = Color(red: 0.2, green: 1.0, blue: 0.3)
                    clockColorRed = 0.2
                    clockColorGreen = 1.0
                    clockColorBlue = 0.3
                    clockColor = Color(red: 0.2, green: 1.0, blue: 0.3)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Done") {
                    updateMaxDuration()
                    updateBufferLength()
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.defaultAction)
            }
            .padding(10)
            .background(Color.secondary.opacity(0.03))
        }
        .frame(width: 480, height: 280)
        .onAppear {
            maxDurationText = "\(Int(maxTaskDuration))"
            bufferLengthText = "\(Int(bufferLength))"
            clockGlowColor = Color(red: clockGlowRed, green: clockGlowGreen, blue: clockGlowBlue)
            clockColor = Color(red: clockColorRed, green: clockColorGreen, blue: clockColorBlue)
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

    private func updateGlowColor(_ color: Color) {
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
            clockGlowRed = Double(rgbColor.redComponent)
            clockGlowGreen = Double(rgbColor.greenComponent)
            clockGlowBlue = Double(rgbColor.blueComponent)
        }
    }

    private func updateClockColor(_ color: Color) {
        let nsColor = NSColor(color)
        if let rgbColor = nsColor.usingColorSpace(.deviceRGB) {
            clockColorRed = Double(rgbColor.redComponent)
            clockColorGreen = Double(rgbColor.greenComponent)
            clockColorBlue = Double(rgbColor.blueComponent)
        }
    }
}

// MARK: - Setting Row Helper

struct SettingRow<Content: View>: View {
    let label: String
    let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 85, alignment: .leading)

            content
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
