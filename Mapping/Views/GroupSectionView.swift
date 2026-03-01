import SwiftUI

struct GroupSectionView: View {
    @Binding var group: MappingGroup
    @EnvironmentObject var engine: MappingEngine

    var onEditGroup: () -> Void
    var onDeleteGroup: () -> Void
    var onAddMapping: () -> Void
    var onEditMapping: (UUID) -> Void
    var onDeleteMapping: (UUID) -> Void

    @State private var isExpanded = true
    @State private var isHeaderHovered = false

    var body: some View {
        VStack(spacing: 0) {
            groupHeader
            if isExpanded {
                VStack(spacing: 2) {
                    ForEach(group.mappings) { mapping in
                        MappingRowView(
                            mapping: bindingForMapping(mapping.id),
                            onEdit: { onEditMapping(mapping.id) },
                            onDelete: { onDeleteMapping(mapping.id) }
                        )
                    }

                    // Add mapping button
                    Button(action: onAddMapping) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("添加映射")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cardCornerRadius)
    }

    // MARK: - Header

    private var groupHeader: some View {
        HStack(spacing: 8) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Theme.groupColor(group.color))
                        .frame(width: 8, height: 8)

                    Image(systemName: group.icon)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)

                    Text(group.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)

                    if let ids = group.bundleIdentifiers {
                        Text(ids.first?.components(separatedBy: ".").last ?? "")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.popoverBackground.opacity(0.6))
                            .cornerRadius(Theme.badgeCornerRadius)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Hover action buttons
            if isHeaderHovered {
                HStack(spacing: 6) {
                    Button(action: onEditGroup) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.accentBlue)
                    }
                    .buttonStyle(.plain)
                    .help("编辑分组")

                    Button(action: onDeleteGroup) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.statusInactive.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("删除分组")
                }
            }

            Text("\(group.mappings.count)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textTertiary)

            Toggle("", isOn: $group.isEnabled)
                .toggleStyle(.switch)
                .scaleEffect(0.6)
                .frame(width: 36)
                .onChange(of: group.isEnabled) { _, _ in engine.saveConfig() }

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onHover { isHeaderHovered = $0 }
    }

    private func bindingForMapping(_ id: UUID) -> Binding<KeyMapping> {
        Binding(
            get: { group.mappings.first(where: { $0.id == id }) ?? KeyMapping(name: "", trigger: .appActivation, actions: []) },
            set: { newValue in
                if let i = group.mappings.firstIndex(where: { $0.id == id }) {
                    group.mappings[i] = newValue
                    engine.saveConfig()
                }
            }
        )
    }
}
