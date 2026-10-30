import SwiftUI

struct EditMappingView: View {
    let existingMapping: KeyMapping?
    let onSave: (KeyMapping) -> Void
    let onCancel: () -> Void

    @State private var name = ""
    @State private var triggerType: MappingTrigger.TriggerType = .hotkey
    @State private var triggerKey = ""
    @State private var triggerModifiers: [KeyModifier] = []
    @State private var intervalSeconds = 3
    @State private var stateScript = ""
    @State private var expectedState = ""
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
                .frame(maxWidth: .infinity, alignment: .leading)
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
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Theme.cardBackgroundHover.opacity(0.4))
                .cornerRadius(5)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(isEditing ? LocalizedStringKey("编辑映射") : LocalizedStringKey("新建映射"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Spacer()

            // Balance spacer
            Color.clear.frame(width: 50, height: 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("映射名称")
            TextField("输入快捷键或映射用途名称", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Theme.inputBackground)
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Theme.inputBorder, lineWidth: 1)
                )
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trigger

    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("触发方式")

            Picker("", selection: $triggerType) {
                Text("快捷键").tag(MappingTrigger.TriggerType.hotkey)
                Text("应用激活").tag(MappingTrigger.TriggerType.appActivation)
                Text("状态守护").tag(MappingTrigger.TriggerType.stateWatch)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: .infinity)

            if triggerType == .hotkey {
                HotkeyRecorderView(key: $triggerKey, modifiers: $triggerModifiers)
                    .frame(maxWidth: .infinity)
            } else if triggerType == .appActivation {
                Text("当匹配的应用激活或切换到前台时，自动执行下方动作")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
            } else {
                stateWatchFields
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stateWatchFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("获取状态脚本，如 im-select（必填）", text: $stateScript)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Theme.inputBackground)
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Theme.inputBorder, lineWidth: 1)
                )
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity)
            HStack(spacing: 8) {
                TextField("期望状态（脚本的输出）", text: $expectedState)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Theme.inputBackground)
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
                    .foregroundColor(Theme.textPrimary)
                Button("用当前") {
                    let script = stateScript
                    DispatchQueue.global(qos: .userInitiated).async {
                        if let current = StateSource.currentState(script: script) {
                            DispatchQueue.main.async { expectedState = current }
                        }
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Theme.accentBlue)
            }
            HStack(spacing: 8) {
                Text("每隔")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                TextField("秒", value: $intervalSeconds, format: .number)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .multilineTextAlignment(.trailing)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Theme.inputBackground)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 60)
                Text("秒查一次，不符就执行下方动作")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textTertiary)
            }
            Text("分组限定了应用时，只在那些应用在前台时守护；全局分组则哪里都守护。间隔、获取脚本、期望状态缺一则不生效；脚本输出与期望状态不一致才执行动作，脚本失败则跳过。")
                .font(.system(size: 11))
                .foregroundColor(Theme.textTertiary)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                sectionLabel("动作列表")
                Spacer()
                Button(action: addAction) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("添加动作")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(Theme.accentBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accentBlue.opacity(0.12))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)

            if actions.isEmpty {
                Text("暂无动作，点击右上角添加")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.cardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
            } else {
                ForEach(actions) { action in
                    actionEditor(for: action.id)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func actionEditor(for actionId: UUID) -> some View {
        if let index = actions.firstIndex(where: { $0.id == actionId }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text("动作 \(index + 1)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Button(action: { actions.removeAll { $0.id == actionId } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.textTertiary)
                            .frame(width: 18, height: 18)
                            .background(Theme.cardBackgroundHover.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("删除动作")
                }

                // Type picker
                Picker("", selection: $actions[index].type) {
                    ForEach(MappingAction.ActionType.allCases, id: \.self) { t in
                        Text(LocalizedStringKey(t.displayName)).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)

                // Type-specific fields
                switch actions[index].type {
                case .openApp:
                    appPickerField(index: index)
                case .sendKeyCombo:
                    HotkeyRecorderView(
                        key: Binding(
                            get: { actions.indices.contains(index) ? (actions[index].key ?? "") : "" },
                            set: { if actions.indices.contains(index) { actions[index].key = $0 } }
                        ),
                        modifiers: Binding(
                            get: { actions.indices.contains(index) ? (actions[index].modifiers ?? []) : [] },
                            set: { if actions.indices.contains(index) { actions[index].modifiers = $0 } }
                        )
                    )
                    .frame(maxWidth: .infinity)
                case .runShellScript:
                    TextField("输入要执行的终端脚本命令", text: Binding(
                        get: { actions.indices.contains(index) ? (actions[index].script ?? "") : "" },
                        set: { if actions.indices.contains(index) { actions[index].script = $0 } }
                    ))
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Theme.inputBackground)
                    .cornerRadius(7)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Theme.inputBorder, lineWidth: 1)
                    )
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                case .delay:
                    HStack(spacing: 8) {
                        Text("延迟时长")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        TextField("毫秒", value: Binding(
                            get: { actions.indices.contains(index) ? (actions[index].delayMs ?? 50) : 50 },
                            set: { if actions.indices.contains(index) { actions[index].delayMs = $0 } }
                        ), format: .number)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Theme.inputBackground)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.inputBorder, lineWidth: 1)
                        )
                        .foregroundColor(Theme.textPrimary)
                        .frame(width: 70)
                        Text("ms")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.inputBackground.opacity(0.5))
                    .cornerRadius(7)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardBackground)
            .cornerRadius(Theme.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
        }
    }

    private func appPickerField(index: Int) -> some View {
        var seen = Set<String>()
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (String, String, NSImage?)? in
                guard let bid = app.bundleIdentifier,
                      let n = app.localizedName,
                      !seen.contains(bid) else { return nil }
                seen.insert(bid)
                return (bid, n, app.icon)
            }
            .sorted { $0.1.localizedCompare($1.1) == .orderedAscending }

        let currentBundleId = actions.indices.contains(index) ? (actions[index].bundleId ?? "") : ""
        let currentApp = apps.first(where: { $0.0 == currentBundleId })

        return Menu {
            ForEach(apps, id: \.0) { bid, name, icon in
                Button(action: {
                    if actions.indices.contains(index) {
                        actions[index].bundleId = bid
                        actions[index].appName = name
                    }
                }) {
                    Text(name)
                }
            }
        } label: {
            HStack(spacing: 8) {
                if let app = currentApp {
                    if let icon = app.2 {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    Text(app.1)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(app.0)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textTertiary)
                } else {
                    Text("点击选择目标应用...")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                    Spacer()
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Theme.inputBackground)
            .cornerRadius(7)
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(Theme.inputBorder, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
        }
        .menuStyle(.borderlessButton)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button("取消") { onCancel() }
                .buttonStyle(.plain)
                .foregroundColor(Theme.textSecondary)
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)

            Button(action: save) {
                Text("保存")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(canSave ? Theme.accentBlue : Theme.textTertiary.opacity(0.6))
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
        guard !name.isEmpty && !actions.isEmpty else { return false }
        if triggerType == .stateWatch {
            return !expectedState.trimmingCharacters(in: .whitespaces).isEmpty
                && !stateScript.trimmingCharacters(in: .whitespaces).isEmpty
                && intervalSeconds >= 1
        }
        return true
    }

    private func sectionLabel(_ text: LocalizedStringKey) -> some View {
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
        intervalSeconds = m.trigger.intervalSeconds ?? 3
        stateScript = m.trigger.stateScript ?? ""
        expectedState = m.trigger.expectedState ?? ""
        actions = m.actions
    }

    private func save() {
        let trigger: MappingTrigger
        switch triggerType {
        case .hotkey:
            trigger = .hotkey(triggerKey, triggerModifiers)
        case .appActivation:
            trigger = .appActivation
        case .stateWatch:
            let script = stateScript.trimmingCharacters(in: .whitespaces)
            trigger = .stateWatch(
                intervalSeconds: intervalSeconds,
                stateScript: script.isEmpty ? nil : script,
                expectedState: expectedState.trimmingCharacters(in: .whitespaces)
            )
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
