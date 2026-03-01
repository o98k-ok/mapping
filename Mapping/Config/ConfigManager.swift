import Foundation

enum ConfigManager {
    static let configDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/mapping")
    static let configFile = configDir.appendingPathComponent("config.json")

    static func load() -> MappingConfiguration {
        if FileManager.default.fileExists(atPath: configFile.path) {
            do {
                let data = try Data(contentsOf: configFile)
                let config = try JSONDecoder().decode(MappingConfiguration.self, from: data)
                print("[Mapping] Loaded config from \(configFile.path)")
                return config
            } catch {
                print("[Mapping] Failed to load config: \(error). Using default.")
            }
        }

        let config = loadDefault()
        save(config)
        return config
    }

    static func save(_ config: MappingConfiguration) {
        do {
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configFile, options: .atomic)
            print("[Mapping] Saved config to \(configFile.path)")
        } catch {
            print("[Mapping] Failed to save config: \(error)")
        }
    }

    private static func loadDefault() -> MappingConfiguration {
        guard let url = Bundle.main.url(forResource: "DefaultConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(MappingConfiguration.self, from: data) else {
            return MappingConfiguration(groups: [])
        }
        return config
    }
}
