import SwiftUI

@main
struct MappingApp: App {
    @StateObject private var engine = MappingEngine.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(engine)
        } label: {
            Image(systemName: "command")
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        // Check accessibility on launch
        if !MappingEngine.checkAccessibility() {
            print("[Mapping] Accessibility permission not granted. Please enable in System Settings > Privacy & Security > Accessibility.")
        }

        // Start engine
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            MappingEngine.shared.start()
        }
    }
}
