import SwiftUI

struct HotkeyRecorderView: View {
    @Binding var key: String
    @Binding var modifiers: [KeyModifier]
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: { isRecording ? stopRecording() : startRecording() }) {
            HStack(spacing: 8) {
                if isRecording {
                    Circle()
                        .fill(Theme.accentRed)
                        .frame(width: 6, height: 6)
                    Text("请按下快捷键组合（Esc 取消）...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.accentOrange)
                } else if key.isEmpty {
                    Text("点击录制快捷键")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                } else {
                    Text(displayText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.keycapText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.keycapBackground)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Theme.keycapBorder, lineWidth: 0.8)
                        )
                }
                Spacer()
                if !key.isEmpty && !isRecording {
                    Button(action: {
                        key = ""
                        modifiers = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .help("清空快捷键")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isRecording ? Theme.accentOrange.opacity(0.08) : Theme.inputBackground)
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(
                        isRecording ? Theme.accentOrange.opacity(0.6) : Theme.inputBorder,
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
