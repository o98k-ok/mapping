import SwiftUI

struct EditGroupView: View {
    let existingGroup: MappingGroup?
    let onSave: (MappingGroup) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var color: String = "#5B8DEF"
    @State private var icon: String = "keyboard"
    @State private var useAppFilter: Bool = false
    @State private var selectedBundleIds: Set<String> = []
    @State private var customBundleId: String = ""

    private let presetColors = [
        "#6BD35F", "#5B8DEF", "#C678DD", "#E06C75", "#E5A05B", "#56B6C2",
    ]
    private let presetIcons = [
        "keyboard", "globe", "terminal", "folder", "app", "gear", "star", "bolt",
    ]

    var isEditing: Bool { existingGroup != nil }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Theme.textTertiary.opacity(0.3))
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    nameSection
                    colorSection
                    iconSection
                    appFilterSection
                }
                .padding(16)
            }
            Divider().background(Theme.textTertiary.opacity(0.3))
            footer
        }
        .frame(width: Theme.popoverWidth)
        .background(Theme.popoverBackground)
        .onAppear { loadExisting() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
                .font(.system(size: 12))
                .foregroundColor(Theme.accentBlue)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(isEditing ? "编辑分组" : "新建分组")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Spacer()
            // Balance spacer
            Color.clear.frame(width: 50, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("名称")
            TextField("分组名称", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(8)
                .background(Theme.cardBackground)
                .cornerRadius(8)
                .foregroundColor(Theme.textPrimary)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("颜色")
            HStack(spacing: 8) {
                ForEach(presetColors, id: \.self) { c in
                    Circle()
                        .fill(Color(hex: c))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: color == c ? 2 : 0)
                        )
                        .onTapGesture { color = c }
                }
            }
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("图标")
            HStack(spacing: 8) {
                ForEach(presetIcons, id: \.self) { ic in
                    Image(systemName: ic)
                        .font(.system(size: 14))
                        .frame(width: 30, height: 30)
                        .background(icon == ic ? Theme.accentBlue.opacity(0.2) : Theme.cardBackground)
                        .foregroundColor(icon == ic ? Theme.accentBlue : Theme.textSecondary)
                        .cornerRadius(6)
                        .onTapGesture { icon = ic }
                }
            }
        }
    }

    private var appFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $useAppFilter) {
                sectionLabel("仅特定应用")
            }
            .toggleStyle(.switch)
            .tint(Theme.accentBlue)

            if useAppFilter {
                VStack(spacing: 4) {
                    ForEach(runningApps, id: \.bundleId) { app in
                        HStack(spacing: 8) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            }
                            Text(app.name)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: selectedBundleIds.contains(app.bundleId) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedBundleIds.contains(app.bundleId) ? Theme.accentBlue : Theme.textTertiary)
                                .font(.system(size: 14))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.cardBackground)
                        .cornerRadius(6)
                        .onTapGesture {
                            if selectedBundleIds.contains(app.bundleId) {
                                selectedBundleIds.remove(app.bundleId)
                            } else {
                                selectedBundleIds.insert(app.bundleId)
                            }
                        }
                    }
                }

                // Custom bundle ID input
                HStack {
                    TextField("自定义 Bundle ID", text: $customBundleId)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(6)
                        .background(Theme.cardBackground)
                        .cornerRadius(6)
                        .foregroundColor(Theme.textPrimary)
                    Button(action: {
                        guard !customBundleId.isEmpty else { return }
                        selectedBundleIds.insert(customBundleId)
                        customBundleId = ""
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.accentBlue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button("取消") { onCancel() }
                .buttonStyle(.plain)
                .foregroundColor(Theme.textSecondary)
                .font(.system(size: 12))

            Button(action: save) {
                Text("保存")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(name.isEmpty ? Theme.textTertiary : Theme.accentBlue)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(name.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Theme.textSecondary)
    }

    private var runningApps: [AppEntry] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName else { return nil }
                return AppEntry(bundleId: bundleId, name: name, icon: app.icon)
            }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private func loadExisting() {
        guard let g = existingGroup else { return }
        name = g.name
        color = g.color
        icon = g.icon
        useAppFilter = g.bundleIdentifiers != nil
        selectedBundleIds = Set(g.bundleIdentifiers ?? [])
    }

    private func save() {
        let group = MappingGroup(
            id: existingGroup?.id ?? UUID(),
            name: name,
            color: color,
            icon: icon,
            isEnabled: existingGroup?.isEnabled ?? true,
            bundleIdentifiers: useAppFilter ? Array(selectedBundleIds) : nil,
            mappings: existingGroup?.mappings ?? []
        )
        onSave(group)
    }
}

struct AppEntry {
    let bundleId: String
    let name: String
    let icon: NSImage?
}
