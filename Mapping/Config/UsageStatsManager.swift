import Foundation

struct UsageStats: Codable {
    var totalTriggers: Int = 0
    var todayTriggers: Int = 0
    var todayDate: String = ""
    var mappingCounts: [String: Int] = [:]

    mutating func record(mappingId: UUID) {
        totalTriggers += 1

        let today = Self.dateFormatter.string(from: Date())
        if todayDate != today {
            todayDate = today
            todayTriggers = 0
        }
        todayTriggers += 1

        mappingCounts[mappingId.uuidString, default: 0] += 1
    }

    func count(for mappingId: UUID) -> Int {
        mappingCounts[mappingId.uuidString] ?? 0
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

enum UsageStatsManager {
    static let statsFile = ConfigManager.configDir.appendingPathComponent("stats.json")

    static func load() -> UsageStats {
        guard FileManager.default.fileExists(atPath: statsFile.path),
              let data = try? Data(contentsOf: statsFile),
              let stats = try? JSONDecoder().decode(UsageStats.self, from: data) else {
            return UsageStats()
        }
        return stats
    }

    static func save(_ stats: UsageStats) {
        do {
            try FileManager.default.createDirectory(
                at: ConfigManager.configDir, withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(stats)
            try data.write(to: statsFile, options: .atomic)
        } catch {
            print("[Mapping] Failed to save stats: \(error)")
        }
    }
}
