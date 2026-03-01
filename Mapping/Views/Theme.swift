import SwiftUI

enum Theme {
    // Background colors
    static let popoverBackground = Color(hex: "#1C1C1E")
    static let cardBackground = Color(hex: "#2C2C2E")
    static let cardBackgroundHover = Color(hex: "#3A3A3C")

    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#ABABAB")
    static let textTertiary = Color(hex: "#636366")

    // Accent colors
    static let accentGreen = Color(hex: "#6BD35F")
    static let accentBlue = Color(hex: "#5B8DEF")
    static let accentPurple = Color(hex: "#C678DD")
    static let accentRed = Color(hex: "#E06C75")
    static let accentOrange = Color(hex: "#E5A05B")
    static let accentCyan = Color(hex: "#56B6C2")

    // Status colors
    static let statusActive = Color(hex: "#34C759")
    static let statusInactive = Color(hex: "#FF3B30")

    // Corner radius
    static let cornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 10
    static let badgeCornerRadius: CGFloat = 6

    // Popover size
    static let popoverWidth: CGFloat = 360
    static let popoverMaxHeight: CGFloat = 520

    static func groupColor(_ hex: String) -> Color {
        Color(hex: hex)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: Double
        switch hex.count {
        case 3:
            r = Double((int >> 8) & 0xF) / 15.0
            g = Double((int >> 4) & 0xF) / 15.0
            b = Double(int & 0xF) / 15.0
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
