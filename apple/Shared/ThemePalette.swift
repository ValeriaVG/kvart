import App
import SwiftUI

enum ThemePalette {
    static func accent(_ id: ThemeId) -> Color {
        switch id {
        case .modern: Color(red: 0xC5 / 255.0, green: 0xF9 / 255.0, blue: 0x74 / 255.0)
        case .vintageAmber: Color(red: 0xFF / 255.0, green: 0xB3 / 255.0, blue: 0x47 / 255.0)
        case .blaze: Color(red: 0xFF / 255.0, green: 0x78 / 255.0, blue: 0x4C / 255.0)
        }
    }

    static func background(_ id: ThemeId) -> Color {
        switch id {
        case .modern: Color(red: 0x0A / 255.0, green: 0x1A / 255.0, blue: 0x30 / 255.0)
        case .vintageAmber: Color(red: 0x2D / 255.0, green: 0x1F / 255.0, blue: 0x0F / 255.0)
        case .blaze: Color(red: 0x0C / 255.0, green: 0x0B / 255.0, blue: 0x0B / 255.0)
        }
    }

    static func gradient(_ id: ThemeId) -> LinearGradient {
        let accent = accent(id)
        return LinearGradient(
            colors: [accent.opacity(0.95), accent.opacity(0.55)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static func fromString(_ raw: String) -> ThemeId {
        switch raw {
        case "modern": return .modern
        case "blaze": return .blaze
        case "vintageAmber": return .vintageAmber
        default: return .modern
        }
    }
}
