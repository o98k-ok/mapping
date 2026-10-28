import Foundation

enum Shell {
    /// Run a script and return its trimmed stdout. Nil on failure or timeout.
    static func output(_ script: String, timeout: TimeInterval = 5) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:" + (env["PATH"] ?? "")
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return nil
        }

        let done = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .utility).async {
            process.waitUntilExit()
            done.signal()
        }
        if done.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            return nil
        }
        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum StateSource {
    /// Current state for a stateWatch trigger: the fetch script's trimmed
    /// stdout. Nil/blank script or failure returns nil, which never triggers.
    static func currentState(script: String?) -> String? {
        guard let script, !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return Shell.output(script)
    }
}
