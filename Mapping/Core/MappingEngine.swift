import Cocoa
import Combine

/// Central engine that coordinates event interception and action execution
final class MappingEngine: ObservableObject {
    static let shared = MappingEngine()

    @Published var config: MappingConfiguration
    @Published var isRunning = false
    @Published var lastTriggered: String?
    @Published var stats: UsageStats

    private let eventTap = EventTapManager()
    private let appWatcher = AppWatcher()

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
        isRunning = tapStarted
    }

    func stop() {
        eventTap.stop()
        appWatcher.stop()
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
        for group in config.groups where group.isEnabled {
            for mapping in group.mappings where mapping.isEnabled {
                guard mapping.trigger.type == .appActivation else { continue }
                recordTrigger(mapping)
                executeActions(mapping.actions)
            }
        }
    }

    private func recordTrigger(_ mapping: KeyMapping) {
        stats.record(mappingId: mapping.id)
        UsageStatsManager.save(stats)
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
            var elapsed: UInt64 = 0
            for action in actions {
                if elapsed > 0 {
                    Thread.sleep(forTimeInterval: Double(elapsed) / 1000.0)
                    elapsed = 0
                }
                if action.type == .delay {
                    elapsed = UInt64(action.delayMs ?? 0)
                } else {
                    DispatchQueue.main.sync {
                        self?.executeAction(action)
                    }
                }
            }
        }
    }

    private func executeAction(_ action: MappingAction) {
        switch action.type {
        case .openApp:
            if let bundleId = action.bundleId {
                openApp(bundleId: bundleId)
            }
        case .sendKeyCombo:
            if let key = action.key {
                KeySimulator.send(key: key, modifiers: action.modifiers ?? [])
            }
        case .runShellScript:
            if let script = action.script {
                runShellScript(script)
            }
        case .delay:
            break // handled in executeActions
        }
    }

    // MARK: - Actions Implementation

    private func openApp(bundleId: String) {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }

    private func runShellScript(_ script: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:" + (env["PATH"] ?? "")
        process.environment = env

        DispatchQueue.global(qos: .utility).async {
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("[Mapping] Shell script error: \(error)")
            }
        }
    }
}
