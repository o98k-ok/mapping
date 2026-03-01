import SwiftUI

struct MappingRowView: View {
    @Binding var mapping: KeyMapping
    @EnvironmentObject var engine: MappingEngine

    var onEdit: () -> Void
    var onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(mapping.isEnabled ? Theme.statusActive : Theme.statusInactive)
                .frame(width: 5, height: 5)

            Text(mapping.name)
                .font(.system(size: 12))
                .foregroundColor(mapping.isEnabled ? Theme.textPrimary : Theme.textTertiary)
                .lineLimit(1)

            Spacer()

            // Trigger badge
            if mapping.trigger.type == .hotkey, let key = mapping.trigger.key {
                triggerBadge(key: key, modifiers: mapping.trigger.modifiers ?? [])
            } else if mapping.trigger.type == .appActivation {
                Text("自动")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Theme.accentGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentGreen.opacity(0.15))
                    .cornerRadius(4)
            }

            actionIcon

            // Hover action buttons
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.accentBlue)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.statusInactive.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }

            Toggle("", isOn: $mapping.isEnabled)
                .toggleStyle(.switch)
                .scaleEffect(0.5)
                .frame(width: 30)
                .onChange(of: mapping.isEnabled) { _, _ in engine.saveConfig() }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isHovered ? Theme.cardBackgroundHover : Color.clear)
        .cornerRadius(6)
        .onHover { isHovered = $0 }
    }

    private func triggerBadge(key: String, modifiers: [KeyModifier]) -> some View {
        let modSymbols = modifiers.map(\.symbol).joined()
        let display = modSymbols + key.uppercased()
        return Text(display)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(Theme.accentCyan)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.accentCyan.opacity(0.12))
            .cornerRadius(4)
    }

    @ViewBuilder
    private var actionIcon: some View {
        let type = mapping.actions.first?.type ?? .sendKeyCombo
        switch type {
        case .openApp:
            Image(systemName: "app.badge")
                .font(.system(size: 10))
                .foregroundColor(Theme.accentBlue)
        case .sendKeyCombo:
            Image(systemName: "keyboard")
                .font(.system(size: 10))
                .foregroundColor(Theme.accentOrange)
        case .runShellScript:
            Image(systemName: "terminal")
                .font(.system(size: 10))
                .foregroundColor(Theme.accentPurple)
        case .delay:
            Image(systemName: "clock")
                .font(.system(size: 10))
                .foregroundColor(Theme.textTertiary)
        }
    }
}
