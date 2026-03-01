import Cocoa

/// Monitors frontmost application changes
final class AppWatcher {
    var onAppActivated: ((NSRunningApplication) -> Void)?

    private var observer: NSObjectProtocol?

    var currentApp: NSRunningApplication? {
        NSWorkspace.shared.frontmostApplication
    }

    func start() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            self?.onAppActivated?(app)
        }
        print("[Mapping] App watcher started")
    }

    func stop() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observer = nil
        print("[Mapping] App watcher stopped")
    }

    deinit {
        stop()
    }
}
