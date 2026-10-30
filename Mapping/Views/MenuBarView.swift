import SwiftUI

enum ViewMode: Equatable {
    case list
    case addGroup
    case editGroup(UUID)
    case addMapping(UUID)
    case editMapping(UUID, UUID)
}

struct MenuBarView: View {
    @EnvironmentObject var engine: MappingEngine
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var viewMode: ViewMode = .list
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        Group {
            switch viewMode {
            case .list:
                listView
            case .addGroup:
                EditGroupView(existingGroup: nil, onSave: { group in
                    engine.addGroup(group)
                    viewMode = .list
                }, onCancel: { viewMode = .list })
            case .editGroup(let id):
                if let group = engine.config.groups.first(where: { $0.id == id }) {
                    EditGroupView(existingGroup: group, onSave: { group in
                        engine.updateGroup(group)
                        viewMode = .list
                    }, onCancel: { viewMode = .list })
                }
            case .addMapping(let groupId):
                EditMappingView(existingMapping: nil, onSave: { mapping in
                    engine.addMapping(to: groupId, mapping)
                    viewMode = .list
                }, onCancel: { viewMode = .list })
            case .editMapping(let groupId, let mappingId):
                if let gi = engine.config.groups.firstIndex(where: { $0.id == groupId }),
                   let mapping = engine.config.groups[gi].mappings.first(where: { $0.id == mappingId }) {
                    EditMappingView(existingMapping: mapping, onSave: { mapping in
                        engine.updateMapping(in: groupId, mapping)
                        viewMode = .list
                    }, onCancel: { viewMode = .list })
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: viewMode)
        .id(engine.config.theme)
        .environment(\.locale, Locale(identifier: engine.config.language.rawValue))
        .preferredColorScheme(engine.colorScheme)
    }

    // MARK: - List View

    private var listView: some View {
        VStack(spacing: 0) {
            headerView
            Divider().background(Theme.textTertiary.opacity(0.3))
            scrollContent
            Divider().background(Theme.textTertiary.opacity(0.3))
            footerView
        }
        .frame(width: Theme.popoverWidth)
        .frame(maxHeight: Theme.popoverMaxHeight)
        .background(Theme.popoverBackground)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accentBlue, Theme.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 30, height: 30)
                Image(systemName: "command")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Mapping")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("快捷键管理")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer(minLength: 6)

            // Stats (Prevent wrapping by using explicit subviews & fixedSize)
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text("\(engine.stats.todayTriggers)")
                }
                HStack(spacing: 3) {
                    Image(systemName: "sum")
                        .font(.system(size: 9))
                    Text("\(engine.stats.totalTriggers)")
                }
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(Theme.textTertiary)
            .lineLimit(1)
            .fixedSize()

            statusBadge

            if let triggered = engine.lastTriggered {
                Text(triggered)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Theme.accentGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentGreen.opacity(0.12))
                    .cornerRadius(4)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var statusBadge: some View {
        Button(action: { engine.toggle() }) {
            HStack(spacing: 5) {
                Circle()
                    .fill(engine.isRunning ? Theme.statusActive : Theme.statusInactive)
                    .frame(width: 6, height: 6)
                Text(engine.isRunning ? LocalizedStringKey("运行中") : LocalizedStringKey("已停止"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(engine.isRunning ? Theme.statusActive : Theme.statusInactive)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (engine.isRunning ? Theme.statusActive : Theme.statusInactive).opacity(0.12)
            )
            .cornerRadius(Theme.badgeCornerRadius)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content

    private var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(engine.config.groups) { group in
                    GroupSectionView(
                        group: bindingForGroup(group.id),
                        onEditGroup: { viewMode = .editGroup(group.id) },
                        onDeleteGroup: { engine.deleteGroup(group.id) },
                        onAddMapping: { viewMode = .addMapping(group.id) },
                        onEditMapping: { mid in viewMode = .editMapping(group.id, mid) },
                        onDeleteMapping: { mid in engine.deleteMapping(from: group.id, mid) }
                    )
                }
            }
            .padding(10)
            .background(
                // Measure the natural content height so the ScrollView can be
                // given a definite frame. Inside MenuBarExtra(.window) the window
                // sizes-to-fit, proposing a nil height; without a definite frame a
                // ScrollView collapses to zero and the whole list disappears.
                GeometryReader { proxy in
                    Color.clear.preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
                }
            )
        }
        .frame(height: min(max(contentHeight, 1), Theme.scrollMaxHeight))
        .onPreferenceChange(ContentHeightPreferenceKey.self) { contentHeight = $0 }
    }

    private func bindingForGroup(_ id: UUID) -> Binding<MappingGroup> {
        Binding(
            get: { engine.config.groups.first(where: { $0.id == id }) ?? MappingGroup(name: "") },
            set: { engine.updateGroup($0) }
        )
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("v1.2.0")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.textTertiary)

            Menu {
                Picker("语言", selection: $engine.config.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(verbatim: language.displayName).tag(language)
                    }
                }
            } label: {
                Image(systemName: "globe")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("语言 / Language")
            .onChange(of: engine.config.language) { _, _ in engine.saveConfig() }

            Spacer()

            Button(action: { viewMode = .addGroup }) {
                HStack(spacing: 3) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("分组")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Theme.accentBlue)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Theme.accentBlue.opacity(0.12))
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .help("新建分组")

            Button(action: { engine.reload() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("重新加载配置")

            Button(action: { NSWorkspace.shared.open(ConfigManager.configDir) }) {
                Image(systemName: "folder")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("打开配置目录")

            Button(action: { engine.cycleTheme() }) {
                Image(systemName: engine.config.theme.iconName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help(Text("主题（点击切换）") + Text(": ") + Text(LocalizedStringKey(engine.config.theme.displayName)))

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("退出")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
