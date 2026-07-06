import SwiftUI

/// The Silencia design system (docs/design/design-system.html).
///
/// Warm cream base; brick red is the color of protection ("the wall is up");
/// plum as secondary accent, amber for the paused state, green for confirmation.
/// Telecom blue is deliberately avoided. Touch targets ≥ 60 pt (senior audience).
enum Brand {
    // Foundations
    static let cream = Color(hex: 0xF4F1EA) // screen background
    static let surface = Color(hex: 0xFCFBF8) // cards
    static let border = Color(hex: 0xE7E2D9) // card borders
    static let divider = Color(hex: 0xEFEAE1) // row separators
    static let chip = Color(hex: 0xEFE7DC) // icon tiles / soft panels

    // Ink
    static let ink = Color(hex: 0x2B2630) // primary text
    static let inkMuted = Color(hex: 0x6E6774) // body text
    static let inkFaint = Color(hex: 0x8B8590) // captions, hints

    // Semantic accents
    static let brick = Color(hex: 0xA8443A) // protection ("the wall is up")
    static let brickTint = Color(hex: 0xF4D9D3) // accents on brick surfaces
    static let brickSoft = Color(hex: 0xF4E7E3) // body text on brick surfaces
    static let plum = Color(hex: 0x574766) // secondary accent
    static let amber = Color(hex: 0xB8863A) // paused state
    static let amberBg = Color(hex: 0xEFE3CE)
    static let amberBorder = Color(hex: 0xE4D3B4)
    static let green = Color(hex: 0x4E7A5B) // confirmation
    static let greenBg = Color(hex: 0xE4EDE4)
    static let greenBorder = Color(hex: 0xC9DCC9)
    static let greenText = Color(hex: 0x5E7A63)
    static let danger = Color(hex: 0xC0483B) // destructive glyphs
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

// MARK: - Typography (scale from the design system; nothing below 15 pt in-app)

extension Font {
    /// Display · 32/800 — the promise headline.
    static let brandDisplay = Font.system(size: 32, weight: .heavy)
    /// Screen title · 28/800 — onboarding headers.
    static let brandScreenTitle = Font.system(size: 28, weight: .heavy)
    /// Title · 26/800 — hero states.
    static let brandTitle = Font.system(size: 26, weight: .heavy)
    /// Header · 22/800 — top bars.
    static let brandHeader = Font.system(size: 22, weight: .heavy)
    /// Subtitle · 20/700.
    static let brandSubtitle = Font.system(size: 20, weight: .bold)
    /// Body · 17/400.
    static let brandBody = Font.system(size: 17)
    /// Row text · 16.
    static let brandRow = Font.system(size: 16)
    /// Secondary · 15.
    static let brandSecondary = Font.system(size: 15)
    /// Caption · 13/600 — smallest size allowed by the design system.
    static let brandCaption = Font.system(size: 13, weight: .semibold)
}

// MARK: - Components

/// Primary action button: 60 pt tall, radius 18, bold 18 pt label.
struct PrimaryButtonStyle: ButtonStyle {
    var background: Color = Brand.brick
    var foreground: Color = Brand.cream

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(background, in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .shadow(color: background.opacity(0.35), radius: 14, y: 8)
    }
}

/// Standard card surface: warm white with a hairline border, radius 20.
struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(Brand.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Brand.border, lineWidth: 1)
            )
    }
}

extension View {
    func card(cornerRadius: CGFloat = 20) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}

/// The "12M / numéros couverts" stat card.
struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Brand.ink)
            Text(label)
                .font(.brandCaption)
                .foregroundStyle(Brand.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .card()
    }
}

/// Icon-tile + title + subtitle row card (the "How it works" cards).
struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 48, height: 48)
                .background(Brand.chip, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Brand.ink)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Brand.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .card()
    }
}

/// The privacy covenant note shown at the bottom of screens.
struct PrivacyNote: View {
    var text = "Tout fonctionne sur votre téléphone. Aucun compte, aucun serveur, rien ne sort de l'appareil."

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Brand.brick)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 13.5))
                .lineSpacing(3)
                .foregroundStyle(Brand.inkMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(Brand.chip, in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Formatting helpers (French-first copy)

enum FrenchFormat {
    /// `12_000_000` → `"12 millions"`, `2_000_001` → `"2 000 001"`.
    static func count(_ value: Int64) -> String {
        if value >= 2_000_000, value % 1_000_000 == 0 {
            return "\(value / 1_000_000)\u{00A0}millions"
        }
        return decimal(value)
    }

    /// `12_000_000` → `"12M"` for the compact stat cards.
    static func compactCount(_ value: Int64) -> String {
        if value >= 1_000_000 {
            let millions = Double(value) / 1_000_000
            let rounded = (millions * 10).rounded() / 10
            return rounded == rounded.rounded()
                ? "\(Int(rounded))M"
                : String(format: "%.1fM", locale: Locale(identifier: "fr_FR"), rounded)
        }
        return decimal(value)
    }

    static func decimal(_ value: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// ISO `"2026-07-01"` → `"1 juil. 2026"`.
    static func date(fromISO iso: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: iso) else { return iso }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}
