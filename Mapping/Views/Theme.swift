import SwiftUI
import AppKit

enum Theme {
    static var isLight: Bool {
        switch MappingEngine.shared.config.theme {
        case .light:
            return true
        case .dark:
            return false
        case .system:
            if let appearance = NSApp?.effectiveAppearance {
                return appearance.bestMatch(from: [.darkAqua, .aqua]) == .aqua
            }
            return false
        }
    }

    // Background colors
    static var popoverBackground: Color {
        isLight ? Color(hex: "#F5F5F7") : Color(hex: "#1C1C1E")
    }
    static var cardBackground: Color {
        isLight ? Color(hex: "#FFFFFF") : Color(hex: "#2C2C2E")
    }
    static var cardBackgroundHover: Color {
        isLight ? Color(hex: "#E5E5EA") : Color(hex: "#3A3A3C")
    }
    static var cardBorder: Color {
        isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.05)
    }

    // Text colors
    static var textPrimary: Color {
        isLight ? Color(hex: "#1D1D1F") : Color.white
    }
    static var textSecondary: Color {
        isLight ? Color(hex: "#6E6E73") : Color(hex: "#ABABAB")
    }
    static var textTertiary: Color {
        isLight ? Color(hex: "#8E8E93") : Color(hex: "#636366")
    }

    // Accent colors
    static var accentGreen: Color {
        isLight ? Color(hex: "#288A36") : Color(hex: "#6BD35F")
    }
    static var accentBlue: Color {
        isLight ? Color(hex: "#0066CC") : Color(hex: "#5B8DEF")
    }
    static var accentPurple: Color {
        isLight ? Color(hex: "#8E24AA") : Color(hex: "#C678DD")
    }
    static var accentRed: Color {
        isLight ? Color(hex: "#D32F2F") : Color(hex: "#E06C75")
    }
    static var accentOrange: Color {
        isLight ? Color(hex: "#E65100") : Color(hex: "#E5A05B")
    }
    static var accentCyan: Color {
        isLight ? Color(hex: "#00838F") : Color(hex: "#56B6C2")
    }

    // Status colors
    static var statusActive: Color {
        Color(hex: "#34C759")
    }
    static var statusInactive: Color {
        Color(hex: "#FF3B30")
    }

    // Corner radius
    static let cornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 10
    static let badgeCornerRadius: CGFloat = 6

    // Popover size
    static let popoverWidth: CGFloat = 380
    static let popoverMaxHeight: CGFloat = 540
    // Height reserved for the non-scrolling chrome (header + dividers + footer).
    static let popoverChromeHeight: CGFloat = 94
    // Max height the scrollable list may take before it starts scrolling.
    static var scrollMaxHeight: CGFloat { popoverMaxHeight - popoverChromeHeight }

    // Native Keycap Style
    static var keycapBackground: Color {
        isLight ? Color(hex: "#EAEAEF") : Color(hex: "#3A3A3C")
    }
    static var keycapBorder: Color {
        isLight ? Color.black.opacity(0.12) : Color.white.opacity(0.1)
    }
    static var keycapText: Color {
        isLight ? Color(hex: "#2C2C2E") : Color(hex: "#F2F2F7")
    }

    // Input & Form Field Style
    static var inputBackground: Color {
        isLight ? Color(hex: "#F2F2F7") : Color(hex: "#242426")
    }
    static var inputBorder: Color {
        isLight ? Color.black.opacity(0.1) : Color.white.opacity(0.08)
    }

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
