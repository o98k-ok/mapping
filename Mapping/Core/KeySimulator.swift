import Cocoa

enum KeySimulator {
    /// Send a key combo (key down + key up)
    static func send(keyCode: UInt16, modifiers: [KeyModifier], to pid: pid_t? = nil) {
        let flags = modifiers.reduce(CGEventFlags()) { result, mod in
            result.union(mod.cgFlag)
        }

        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags

        if let pid {
            keyDown.postToPid(pid)
            keyUp.postToPid(pid)
        } else {
            keyDown.post(tap: .cgSessionEventTap)
            keyUp.post(tap: .cgSessionEventTap)
        }
    }

    /// Send a key combo by key name
    static func send(key: String, modifiers: [KeyModifier], to pid: pid_t? = nil) {
        guard let keyCode = KeyCodeMap.keyCode(for: key) else {
            print("[Mapping] Unknown key: \(key)")
            return
        }
        send(keyCode: keyCode, modifiers: modifiers, to: pid)
    }

    /// Execute a sequence of key combos with a small delay between them
    static func sendSequence(_ combos: [(key: String, modifiers: [KeyModifier])], to pid: pid_t? = nil) {
        for (index, combo) in combos.enumerated() {
            let delay = Double(index) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                send(key: combo.key, modifiers: combo.modifiers, to: pid)
            }
        }
    }
}
