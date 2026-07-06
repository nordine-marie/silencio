import SwiftUI

/// Minimal slice of the design system (docs/design/design-system.html) — enough to
/// render an on-brand demo dashboard. The full DesignSystem module lands in Core/.
enum Brand {
    static let cream = Color(hex: 0xF4F1EA)  // warm base
    static let brick = Color(hex: 0xA8443A)  // protection ("the wall is up")
    static let plum = Color(hex: 0x574766)   // secondary accent
    static let amber = Color(hex: 0xB8863A)  // paused state
    static let green = Color(hex: 0x4E7A5B)  // confirmation
    static let ink = Color(hex: 0x2A2622)    // primary text
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
