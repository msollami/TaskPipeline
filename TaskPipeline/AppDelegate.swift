//
//  AppDelegate.swift
//  TaskPipeline
//
//  Manages menubar app lifecycle
//

import SwiftUI
import AppKit
import UserNotifications
import ServiceManagement

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
    @AppStorage("clockGlowRed") private var clockGlowRed: Double = 0.2
    @AppStorage("clockGlowGreen") private var clockGlowGreen: Double = 1.0
    @AppStorage("clockGlowBlue") private var clockGlowBlue: Double = 0.3
    @AppStorage("clockColorRed") private var clockColorRed: Double = 0.2
    @AppStorage("clockColorGreen") private var clockColorGreen: Double = 1.0
    @AppStorage("clockColorBlue") private var clockColorBlue: Double = 0.3
    @AppStorage("defaultTaskDuration") private var defaultTaskDuration: Double = 10
    @AppStorage("defaultBreakDuration") private var defaultBreakDuration: Double = 0
    @AppStorage("useBlueClockDuringBreaks") private var useBlueClockDuringBreaks: Bool = false
    @AppStorage("syncClockToTaskColor") private var syncClockToTaskColor: Bool = true

    @State private var maxDurationText: String = "120"
    @State private var defaultTaskText: String = "10"
    @State private var defaultBreakText: String = "0"
    @State private var clockGlowColor: Color = Color(red: 0.2, green: 1.0, blue: 0.3)
    @State private var clockColor: Color = Color(red: 0.2, green: 1.0, blue: 0.3)
    @State private var launchAtLogin: Bool = false

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

                    SettingRow(label: "Default Task") {
                        HStack(spacing: 4) {
                            TextField("", text: $defaultTaskText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                                .onSubmit { updateDefaultTask() }
                            Text("min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    SettingRow(label: "Default Break") {
                        HStack(spacing: 4) {
                            TextField("", text: $defaultBreakText)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 50)
                                .onSubmit { updateDefaultBreak() }
                            Text("min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()
                        .padding(.vertical, 12)

                    Text("General")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    SettingRow(label: "Launch at Login") {
                        Toggle("", isOn: $launchAtLogin)
                            .labelsHidden()
                            .controlSize(.small)
                            .onChange(of: launchAtLogin) { newValue in
                                setLaunchAtLogin(enabled: newValue)
                            }
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Right column
                VStack(alignment: .leading, spacing: 10) {
                    Text("Appearance")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

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

                    SettingRow(label: "Blue Clock on Break") {
                        Toggle("", isOn: $useBlueClockDuringBreaks)
                            .labelsHidden()
                            .controlSize(.small)
                    }

                    SettingRow(label: "Sync Clock Colors to Task Colors") {
                        Toggle("", isOn: $syncClockToTaskColor)
                            .labelsHidden()
                            .controlSize(.small)
                    }

                    Divider()
                        .padding(.vertical, 12)

                    Text("Audio")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    SettingRow(label: "Sound") {
                        HStack(alignment: .center, spacing: 6) {
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
                        .frame(height: 20)
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
                    defaultTaskDuration = 10
                    defaultTaskText = "10"
                    defaultBreakDuration = 0
                    defaultBreakText = "0"
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
                    useBlueClockDuringBreaks = false
                    syncClockToTaskColor = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Done") {
                    updateMaxDuration()
                    updateDefaultTask()
                    updateDefaultBreak()
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.defaultAction)
            }
            .padding(10)
            .background(Color.secondary.opacity(0.03))
        }
        .frame(width: 480, height: 380)
        .onAppear {
            maxDurationText = "\(Int(maxTaskDuration))"
            defaultTaskText = "\(Int(defaultTaskDuration))"
            defaultBreakText = "\(Int(defaultBreakDuration))"
            clockGlowColor = Color(red: clockGlowRed, green: clockGlowGreen, blue: clockGlowBlue)
            clockColor = Color(red: clockColorRed, green: clockColorGreen, blue: clockColorBlue)
            launchAtLogin = getLaunchAtLoginStatus()
        }
    }

    private func updateMaxDuration() {
        if let value = Double(maxDurationText), value >= 10 && value <= 600 {
            maxTaskDuration = value
        } else {
            maxDurationText = "\(Int(maxTaskDuration))"
        }
    }

    private func updateDefaultTask() {
        if let value = Double(defaultTaskText), value >= 1 && value <= 600 {
            defaultTaskDuration = value
        } else {
            defaultTaskText = "\(Int(defaultTaskDuration))"
        }
    }

    private func updateDefaultBreak() {
        if let value = Double(defaultBreakText), value >= 0 && value <= 120 {
            defaultBreakDuration = value
        } else {
            defaultBreakText = "\(Int(defaultBreakDuration))"
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

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            }
        }
    }

    private func getLaunchAtLoginStatus() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
}

// MARK: - About Window

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            // App Icon
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            }

            // App Name and Version
            VStack(spacing: 4) {
                Text("TaskPipeline")
                    .font(.system(size: 24, weight: .semibold))

                if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                   let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
                    Text("Version \(version) (\(build))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Description
            VStack(spacing: 8) {
                Text("Focus on what matters")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text("TaskPipeline helps you manage your time effectively with visual task pipelines, customizable breaks, and focused work sessions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 320)
            }
            .padding(.vertical, 4)

            // Credits
            VStack(spacing: 2) {
                Text("Created by Michael Sollami")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("© 2024 All rights reserved")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(24)
        .frame(width: 360)
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
    private var aboutWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }

        // Register for notification center events
        NotificationCenter.default.addObserver(self, selector: #selector(openSettings), name: NSNotification.Name("OpenSettings"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openAbout), name: NSNotification.Name("OpenAbout"), object: nil)

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
        menu.addItem(NSMenuItem(title: "About TaskPipeline", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
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
            window.title = "TaskPipeline Settings"
            window.styleMask = [NSWindow.StyleMask.titled, NSWindow.StyleMask.closable]
            window.center()
            window.setFrameAutosaveName("Settings")
            window.isReleasedWhenClosed = false

            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openAbout() {
        if aboutWindow == nil {
            let aboutView = AboutView()
            let hostingController = NSHostingController(rootView: aboutView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "About TaskPipeline"
            window.styleMask = [NSWindow.StyleMask.titled, NSWindow.StyleMask.closable]
            window.center()
            window.setFrameAutosaveName("About")
            window.isReleasedWhenClosed = false

            aboutWindow = window
        }

        aboutWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timerManager.reset()
    }
}
