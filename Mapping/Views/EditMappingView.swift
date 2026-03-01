import SwiftUI

struct EditMappingView: View {
    let existingMapping: KeyMapping?
    let onSave: (KeyMapping) -> Void
    let onCancel: () -> Void

    @State private var name = ""
    @State private var triggerType: MappingTrigger.TriggerType = .hotkey
    @State private var triggerKey = ""
    @State private var triggerModifiers: [KeyModifier] = []
    @State private var actions: [MappingAction] = []

    var isEditing: Bool { existingMapping != nil }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Theme.textTertiary.opacity(0.3))
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    nameSection
                    triggerSection
                    actionsSection
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
            Text(isEditing ? "编辑映射" : "新建映射")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Color.clear.frame(width: 50, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("名称")
            TextField("映射名称", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(8)
                .background(Theme.cardBackground)
                .cornerRadius(8)
                .foregroundColor(Theme.textPrimary)
        }
    }

    // MARK: - Trigger

    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("触发方式")

            Picker("", selection: $triggerType) {
                Text("快捷键").tag(MappingTrigger.TriggerType.hotkey)
                Text("应用激活").tag(MappingTrigger.TriggerType.appActivation)
            }
            .pickerStyle(.segmented)

            if triggerType == .hotkey {
                HotkeyRecorderView(key: $triggerKey, modifiers: $triggerModifiers)
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("动作列表")
                Spacer()
                Button(action: addAction) {
                    HStack(spacing: 2) {
                        Image(systemName: "plus")
                        Text("添加")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Theme.accentBlue)
                }
                .buttonStyle(.plain)
            }

            if actions.isEmpty {
                Text("暂无动作，点击添加")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.cardBackground)
                    .cornerRadius(8)
            } else {
                ForEach(Array(actions.enumerated()), id: \.offset) { index, _ in
                    actionEditor(index: index)
                }
            }
        }
    }

    private func actionEditor(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("动作 \(index + 1)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Button(action: { actions.remove(at: index) }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.statusInactive.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            // Type picker
            Picker("", selection: $actions[index].type) {
                ForEach(MappingAction.ActionType.allCases, id: \.self) { t in
                    Text(t.displayName).tag(t)
                }
            }
            .pickerStyle(.segmented)

            // Type-specific fields
            switch actions[index].type {
            case .openApp:
                appPickerField(index: index)
            case .sendKeyCombo:
                HotkeyRecorderView(
                    key: Binding(
                        get: { actions[index].key ?? "" },
                        set: { actions[index].key = $0 }
                    ),
                    modifiers: Binding(
                        get: { actions[index].modifiers ?? [] },
                        set: { actions[index].modifiers = $0 }
                    )
                )
            case .runShellScript:
                TextField("脚本命令", text: Binding(
                    get: { actions[index].script ?? "" },
                    set: { actions[index].script = $0 }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .padding(8)
                .background(Theme.cardBackground)
                .cornerRadius(6)
                .foregroundColor(Theme.textPrimary)
            case .delay:
                HStack {
                    TextField("毫秒", value: Binding(
                        get: { actions[index].delayMs ?? 50 },
                        set: { actions[index].delayMs = $0 }
                    ), format: .number)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(8)
                    .background(Theme.cardBackground)
                    .cornerRadius(6)
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 80)
                    Text("ms")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(Theme.cardBackground)
        .cornerRadius(8)
    }

    private func appPickerField(index: Int) -> some View {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (String, String, NSImage?)? in
                guard let bid = app.bundleIdentifier, let n = app.localizedName else { return nil }
                return (bid, n, app.icon)
            }
            .sorted { $0.1.localizedCompare($1.1) == .orderedAscending }

        return VStack(spacing: 4) {
            Picker("", selection: Binding(
                get: { actions[index].bundleId ?? "" },
                set: { newValue in
                    actions[index].bundleId = newValue
                    actions[index].appName = apps.first(where: { a in a.0 == newValue })?.1
                }
            )) {
                Text("选择应用").tag("")
                ForEach(apps, id: \.0) { bid, name, _ in
                    Text(name).tag(bid)
                }
            }
            .pickerStyle(.menu)

            if let name = actions[index].appName, !name.isEmpty {
                HStack {
                    Text(name)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accentBlue)
                    Text(actions[index].bundleId ?? "")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textTertiary)
                    Spacer()
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
                    .background(canSave ? Theme.accentBlue : Theme.textTertiary)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private var canSave: Bool {
        !name.isEmpty && !actions.isEmpty
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Theme.textSecondary)
    }

    private func addAction() {
        actions.append(MappingAction(type: .sendKeyCombo))
    }

    private func loadExisting() {
        guard let m = existingMapping else { return }
        name = m.name
        triggerType = m.trigger.type
        triggerKey = m.trigger.key ?? ""
        triggerModifiers = m.trigger.modifiers ?? []
        actions = m.actions
    }

    private func save() {
        let trigger: MappingTrigger
        if triggerType == .hotkey {
            trigger = .hotkey(triggerKey, triggerModifiers)
        } else {
            trigger = .appActivation
        }

        let mapping = KeyMapping(
            id: existingMapping?.id ?? UUID(),
            name: name,
            isEnabled: existingMapping?.isEnabled ?? true,
            trigger: trigger,
            actions: actions
        )
        onSave(mapping)
    }
}
