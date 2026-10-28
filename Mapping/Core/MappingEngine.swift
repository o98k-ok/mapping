import Cocoa
import Combine
import SwiftUI

/// Central engine that coordinates event interception and action execution
final class MappingEngine: ObservableObject {
    static let shared = MappingEngine()

    @Published var config: MappingConfiguration
    @Published var isRunning = false
    @Published var lastTriggered: String?
    @Published var stats: UsageStats

    var colorScheme: ColorScheme? {
        switch config.theme {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }

    private let eventTap = EventTapManager()
    private let appWatcher = AppWatcher()
    private var watchTimer: Timer?
    private var lastWatchCheck: [UUID: Date] = [:]

    private init() {
        config = ConfigManager.load()
        stats = UsageStatsManager.load()
        setupEventTap()
        setupAppWatcher()
    }

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        let tapStarted = eventTap.start()
        appWatcher.start()
        startWatchTimer()
        isRunning = tapStarted
    }

    func stop() {
        eventTap.stop()
        appWatcher.stop()
        watchTimer?.invalidate()
        watchTimer = nil
        isRunning = false
    }

    func toggle() {
        if isRunning { stop() } else { start() }
    }

    func reload() {
        config = ConfigManager.load()
    }

    func saveConfig() {
        ConfigManager.save(config)
    }

    func setTheme(_ theme: AppThemeMode) {
        config.theme = theme
        saveConfig()
    }

    func cycleTheme() {
        config.theme = config.theme.next
        saveConfig()
    }

    // MARK: - CRUD

    func addGroup(_ group: MappingGroup) {
        config.groups.append(group)
        saveConfig()
    }

    func updateGroup(_ group: MappingGroup) {
        guard let i = config.groups.firstIndex(where: { $0.id == group.id }) else { return }
        config.groups[i] = group
        saveConfig()
    }

    func deleteGroup(_ id: UUID) {
        config.groups.removeAll { $0.id == id }
        saveConfig()
    }

    func addMapping(to groupId: UUID, _ mapping: KeyMapping) {
        guard let i = config.groups.firstIndex(where: { $0.id == groupId }) else { return }
        config.groups[i].mappings.append(mapping)
        saveConfig()
    }

    func updateMapping(in groupId: UUID, _ mapping: KeyMapping) {
        guard let gi = config.groups.firstIndex(where: { $0.id == groupId }),
              let mi = config.groups[gi].mappings.firstIndex(where: { $0.id == mapping.id }) else { return }
        config.groups[gi].mappings[mi] = mapping
        saveConfig()
    }

    func deleteMapping(from groupId: UUID, _ mappingId: UUID) {
        guard let gi = config.groups.firstIndex(where: { $0.id == groupId }) else { return }
        config.groups[gi].mappings.removeAll { $0.id == mappingId }
        saveConfig()
    }

    // MARK: - Accessibility

    static func checkAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Setup

    private func setupEventTap() {
        eventTap.onKeyEvent = { [weak self] event, type in
            self?.handleKeyEvent(event, type: type)
        }
    }

    private func setupAppWatcher() {
        appWatcher.onAppActivated = { [weak self] app in
            self?.handleAppActivation(app)
        }
    }

    // MARK: - Event Handling

    private func handleKeyEvent(_ event: CGEvent, type: CGEventType) -> CGEvent? {
        guard type == .keyDown else { return event }

        // Ignore our own simulated key events to prevent feedback loops
        if event.getIntegerValueField(.eventSourceUserData) == 0x4D4150 {
            return event
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let frontmostBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier

        for group in config.groups where group.isEnabled {
            // Check app filter
            if let bundleIds = group.bundleIdentifiers {
                guard let appId = frontmostBundleId, bundleIds.contains(appId) else {
                    continue
                }
            }

            for mapping in group.mappings where mapping.isEnabled {
                guard mapping.trigger.type == .hotkey,
                      let triggerKey = mapping.trigger.key,
                      let triggerKeyCode = KeyCodeMap.keyCode(for: triggerKey) else {
                    continue
                }

                let triggerModifiers = mapping.trigger.modifiers ?? []

                if keyCode == triggerKeyCode && modifiersMatch(flags, expected: triggerModifiers) {
                    DispatchQueue.main.async { [weak self] in
                        self?.lastTriggered = mapping.name
                        self?.recordTrigger(mapping)
                        self?.executeActions(mapping.actions)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if self?.lastTriggered == mapping.name {
                                self?.lastTriggered = nil
                            }
                        }
                    }
                    return nil // Suppress original event
                }
            }
        }

        return event // Pass through
    }

    private func handleAppActivation(_ app: NSRunningApplication) {
        guard let frontmostId = app.bundleIdentifier,
              frontmostId != Bundle.main.bundleIdentifier else { return }

        for group in config.groups where group.isEnabled {
            // Check app filter
            if let bundleIds = group.bundleIdentifiers {
                guard bundleIds.contains(frontmostId) else { continue }
            }

            for mapping in group.mappings where mapping.isEnabled {
                guard mapping.trigger.type == .appActivation else { continue }
                recordTrigger(mapping)
                executeActions(mapping.actions)
            }
        }
    }

    // MARK: - State Watch

    private func startWatchTimer() {
        watchTimer?.invalidate()
        watchTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkWatchedStates()
        }
    }

    /// Poll watched states. A group with bundleIdentifiers only guards while
    /// one of those apps is frontmost; a global group guards everywhere.
    private func checkWatchedStates() {
        guard let frontmostId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
              frontmostId != Bundle.main.bundleIdentifier else { return }

        let now = Date()
        for group in config.groups where group.isEnabled {
            if let bundleIds = group.bundleIdentifiers, !bundleIds.contains(frontmostId) {
                continue
            }
            for mapping in group.mappings where mapping.isEnabled {
                // stateWatch needs interval + fetch script + expected state;
                // anything missing means it never fires.
                guard mapping.trigger.type == .stateWatch,
                      let rawScript = mapping.trigger.stateScript,
                      !rawScript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let rawExpected = mapping.trigger.expectedState,
                      !rawExpected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    continue
                }
                let script = rawScript
                let expected = rawExpected.trimmingCharacters(in: .whitespacesAndNewlines)
                let interval = TimeInterval(max(1, mapping.trigger.intervalSeconds ?? 3))
                if let last = lastWatchCheck[mapping.id], now.timeIntervalSince(last) < interval {
                    continue
                }
                lastWatchCheck[mapping.id] = now

                // Fetch state off the main thread: a user script may be slow.
                // A failed fetch (nil) never triggers actions.
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    guard let current = StateSource.currentState(script: script),
                          current != expected else { return }
                    DispatchQueue.main.async {
                        self?.lastTriggered = mapping.name
                    }
                    self?.recordTrigger(mapping)
                    self?.executeActions(mapping.actions)
                }
            }
        }
    }

    private func recordTrigger(_ mapping: KeyMapping) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.stats.record(mappingId: mapping.id)
            UsageStatsManager.saveDebounced(self.stats)
        }
    }

    // MARK: - Modifier Matching

    private func modifiersMatch(_ actual: CGEventFlags, expected: [KeyModifier]) -> Bool {
        let relevantFlags: [(CGEventFlags, KeyModifier)] = [
            (.maskCommand, .command),
            (.maskAlternate, .option),
            (.maskControl, .control),
            (.maskShift, .shift),
        ]

        for (flag, modifier) in relevantFlags {
            let isSet = actual.contains(flag)
            let isExpected = expected.contains(modifier)
            if isSet != isExpected {
                return false
            }
        }
        return true
    }

    // MARK: - Action Execution

    private func executeActions(_ actions: [MappingAction]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            for action in actions {
                switch action.type {
                case .delay:
                    let ms = action.delayMs ?? 50
                    if ms > 0 {
                        Thread.sleep(forTimeInterval: Double(ms) / 1000.0)
                    }
                case .openApp:
                    if let bundleId = action.bundleId {
                        DispatchQueue.main.async {
                            self.openApp(bundleId: bundleId)
                        }
                    }
                case .sendKeyCombo:
                    if let key = action.key {
                        KeySimulator.send(key: key, modifiers: action.modifiers ?? [])
                    }
                case .runShellScript:
                    if let script = action.script {
                        self.runShellScriptSync(script)
                    }
                }
            }
        }
    }

    // MARK: - Actions Implementation

    private func openApp(bundleId: String) {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }

    private func runShellScriptSync(_ script: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:" + (env["PATH"] ?? "")
        process.environment = env

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("[Mapping] Shell script error: \(error)")
        }
    }
}
