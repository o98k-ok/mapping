import SwiftUI

struct HotkeyRecorderView: View {
    @Binding var key: String
    @Binding var modifiers: [KeyModifier]
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: { isRecording ? stopRecording() : startRecording() }) {
            HStack(spacing: 6) {
                if isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("按下快捷键...")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.accentOrange)
                } else if key.isEmpty {
                    Text("点击录制")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                } else {
                    Text(displayText)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.accentCyan)
                }
                Spacer()
                if !key.isEmpty && !isRecording {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                        .onTapGesture {
                            key = ""
                            modifiers = []
                        }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isRecording ? Theme.accentOrange.opacity(0.08) : Theme.popoverBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isRecording ? Theme.accentOrange.opacity(0.5) : Theme.textTertiary.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onDisappear { stopRecording() }
    }

    private var displayText: String {
        modifiers.map(\.symbol).joined() + key.uppercased()
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            let keyCode = event.keyCode

            // Escape cancels recording
            if keyCode == 0x35 {
                stopRecording()
                return nil
            }

            guard let keyName = KeyCodeMap.keyName(for: keyCode) else { return nil }

            var mods: [KeyModifier] = []
            if event.modifierFlags.contains(.command) { mods.append(.command) }
            if event.modifierFlags.contains(.option) { mods.append(.option) }
            if event.modifierFlags.contains(.control) { mods.append(.control) }
            if event.modifierFlags.contains(.shift) { mods.append(.shift) }

            key = keyName
            modifiers = mods
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
