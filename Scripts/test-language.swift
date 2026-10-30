// Run on macOS:
// swiftc Mapping/Models/MappingConfig.swift Scripts/test-language.swift -o /tmp/mapping-language-test
// /tmp/mapping-language-test
import Foundation

@main
struct LanguageConfigurationTest {
    static func main() throws {
        let decoder = JSONDecoder()
        for json in ["{\"groups\":[]}", "{\"language\":\"unknown\",\"groups\":[]}"] {
            let config = try decoder.decode(MappingConfiguration.self, from: Data(json.utf8))
            precondition(config.language == .chinese, "Old or unsupported language settings must default to Chinese")
        }

        for language in AppLanguage.allCases {
            let mapping = KeyMapping(name: "我的映射", trigger: .appActivation,
                                     actions: [.runShellScript("echo 中文")])
            let original = MappingConfiguration(language: language,
                                                groups: [MappingGroup(name: "我的分组", mappings: [mapping])])
            let data = try JSONEncoder().encode(original)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            precondition(json["language"] as? String == (language == .english ? "en" : "zh-Hans"))
            let restored = try decoder.decode(MappingConfiguration.self, from: data)
            precondition(restored.language == language)
            precondition(restored.groups[0].name == "我的分组")
            precondition(restored.groups[0].mappings[0].name == "我的映射")
            precondition(restored.groups[0].mappings[0].actions[0].script == "echo 中文")
        }
        print("PASS: language defaults, persistence, and user content preservation")
    }
}
