import Foundation
import Carbon

// MARK: - Configuration Root

struct MappingConfiguration: Codable {
    var groups: [MappingGroup]
}

// MARK: - Group

struct MappingGroup: Identifiable, Codable {
    var id: UUID
    var name: String
    var color: String
    var icon: String
    var isEnabled: Bool
    var bundleIdentifiers: [String]?
    var mappings: [KeyMapping]

    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#5B8DEF",
        icon: String = "keyboard",
        isEnabled: Bool = true,
        bundleIdentifiers: [String]? = nil,
        mappings: [KeyMapping] = []
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.isEnabled = isEnabled
        self.bundleIdentifiers = bundleIdentifiers
        self.mappings = mappings
    }

    var isGlobal: Bool { bundleIdentifiers == nil }
}

// MARK: - Key Mapping

struct KeyMapping: Identifiable, Codable {
    var id: UUID
    var name: String
    var isEnabled: Bool
    var trigger: MappingTrigger
    var actions: [MappingAction]

    init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        trigger: MappingTrigger,
        actions: [MappingAction]
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.trigger = trigger
        self.actions = actions
    }
}

// MARK: - Trigger

struct MappingTrigger: Codable {
    var type: TriggerType
    var key: String?
    var modifiers: [KeyModifier]?

    enum TriggerType: String, Codable {
        case hotkey
        case appActivation
    }

    static func hotkey(_ key: String, _ modifiers: [KeyModifier]) -> MappingTrigger {
        MappingTrigger(type: .hotkey, key: key, modifiers: modifiers)
    }

    static var appActivation: MappingTrigger {
        MappingTrigger(type: .appActivation)
    }
}

// MARK: - Action

struct MappingAction: Identifiable, Codable {
    var id: UUID
    var type: ActionType
    var bundleId: String?
    var appName: String?
    var key: String?
    var modifiers: [KeyModifier]?
    var script: String?
    var delayMs: Int?

    enum ActionType: String, Codable, CaseIterable {
        case openApp
        case sendKeyCombo
        case runShellScript
        case delay

        var displayName: String {
            switch self {
            case .openApp: return "打开应用"
            case .sendKeyCombo: return "发送按键"
            case .runShellScript: return "运行脚本"
            case .delay: return "延迟"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, bundleId, appName, key, modifiers, script, delayMs
    }

    // Extra key for legacy config migration
    private enum LegacyKeys: String, CodingKey {
        case inputMethodId
    }

    init(
        id: UUID = UUID(), type: ActionType,
        bundleId: String? = nil, appName: String? = nil,
        key: String? = nil, modifiers: [KeyModifier]? = nil,
        script: String? = nil, delayMs: Int? = nil
    ) {
        self.id = id; self.type = type
        self.bundleId = bundleId; self.appName = appName
        self.key = key; self.modifiers = modifiers
        self.script = script; self.delayMs = delayMs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()

        // Backward compat: convert legacy switchInputMethod → runShellScript
        let rawType = try c.decode(String.self, forKey: .type)
        if rawType == "switchInputMethod" {
            type = .runShellScript
            let legacy = try decoder.container(keyedBy: LegacyKeys.self)
            let imId = (try? legacy.decode(String.self, forKey: .inputMethodId)) ?? ""
            script = "im-select \(imId)"
        } else {
            type = ActionType(rawValue: rawType) ?? .runShellScript
            script = try c.decodeIfPresent(String.self, forKey: .script)
        }

        bundleId = try c.decodeIfPresent(String.self, forKey: .bundleId)
        appName = try c.decodeIfPresent(String.self, forKey: .appName)
        key = try c.decodeIfPresent(String.self, forKey: .key)
        modifiers = try c.decodeIfPresent([KeyModifier].self, forKey: .modifiers)
        delayMs = try c.decodeIfPresent(Int.self, forKey: .delayMs)
    }

    static func openApp(_ bundleId: String, name: String) -> MappingAction {
        MappingAction(type: .openApp, bundleId: bundleId, appName: name)
    }

    static func sendKeyCombo(_ key: String, _ modifiers: [KeyModifier]) -> MappingAction {
        MappingAction(type: .sendKeyCombo, key: key, modifiers: modifiers)
    }

    static func runShellScript(_ script: String) -> MappingAction {
        MappingAction(type: .runShellScript, script: script)
    }

    static func delay(_ ms: Int) -> MappingAction {
        MappingAction(type: .delay, delayMs: ms)
    }
}

// MARK: - Key Modifier

enum KeyModifier: String, Codable, CaseIterable, Hashable {
    case command
    case option
    case control
    case shift

    var symbol: String {
        switch self {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        }
    }

    var cgFlag: CGEventFlags {
        switch self {
        case .command: return .maskCommand
        case .option: return .maskAlternate
        case .control: return .maskControl
        case .shift: return .maskShift
        }
    }

    var carbonFlag: UInt32 {
        switch self {
        case .command: return UInt32(cmdKey)
        case .option: return UInt32(optionKey)
        case .control: return UInt32(controlKey)
        case .shift: return UInt32(shiftKey)
        }
    }
}
