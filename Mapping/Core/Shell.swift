import Foundation

enum Shell {
    /// Run a script and return its trimmed stdout. Nil on failure or timeout.
    static func output(_ script: String, timeout: TimeInterval = 5) -> String? {
        let pipe = Pipe()
        guard run(script, stdout: pipe, timeout: timeout) == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Run a script and block until it exits. Returns its exit status,
    /// nil on launch failure or timeout (the process is then terminated).
    /// Waits on terminationHandler, not waitUntilExit: waitUntilExit spins a
    /// run loop on a GCD thread and can hang forever, leaking that thread.
    @discardableResult
    static func run(_ script: String, stdout: Pipe? = nil, timeout: TimeInterval? = nil) -> Int32? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:" + (env["PATH"] ?? "")
        process.environment = env
        if let stdout {
            process.standardOutput = stdout
            process.standardError = FileHandle.nullDevice
        }

        let done = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in done.signal() }

        do {
            try process.run()
        } catch {
            print("[Mapping] Shell script error: \(error)")
            return nil
        }

        let deadline: DispatchTime = timeout.map { .now() + $0 } ?? .distantFuture
        if done.wait(timeout: deadline) == .timedOut {
            process.terminate()
            return nil
        }
        return process.terminationStatus
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
