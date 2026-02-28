import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

/// Design system for Wake Protocol — Olive Garden Feast
/// Earthy olive and moss dance with creamy beige, warm gold, and rustic copper
enum Theme {
    // MARK: - Olive Garden Palette
    static let oliveLeaf = Color(hex: "606c38")      // Muted green — natural balance
    static let blackForest = Color(hex: "283618")    // Intense dark green — strength
    static let cornsilk = Color(hex: "fefae0")       // (kept for ColorMatch challenge)
    static let lightCaramel = Color(hex: "dda15e")   // Warm buttery gold
    static let copper = Color(hex: "bc6c25")        // Reddish-brown metallic

    // MARK: - Core Colors (light theme — pale olive/sage to match palette)
    static let background = Color(red: 0.94, green: 0.95, blue: 0.90)       // Pale sage
    static let surface = Color(red: 0.97, green: 0.97, blue: 0.93)        // Light olive-tinted
    static let surfaceElevated = Color(red: 0.98, green: 0.98, blue: 0.95)
    static let primaryAccent = copper
    static let warningAccent = lightCaramel
    static let dangerAccent = Color(red: 0.85, green: 0.35, blue: 0.20)      // Warm brick
    static let successAccent = oliveLeaf
    static let purpleAccent = lightCaramel

    // MARK: - Text Colors (dark on light — strong contrast)
    static let textPrimary = Color(red: 0.11, green: 0.13, blue: 0.07)
    static let textSecondary = Color(red: 0.11, green: 0.13, blue: 0.07).opacity(0.82)
    static let textTertiary = Color(red: 0.11, green: 0.13, blue: 0.07).opacity(0.62)

    // MARK: - Typography
    static let titleFont = Font.system(size: 36, weight: .bold, design: .monospaced)
    static let headlineFont = Font.system(size: 20, weight: .semibold, design: .monospaced)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 12, weight: .medium, design: .monospaced)
    static let timeFont = Font.system(size: 64, weight: .ultraLight, design: .rounded)

    // MARK: - Gradients
    static let cardGradient = LinearGradient(
        colors: [surfaceElevated, surface],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let accentGradient = LinearGradient(
        colors: [copper, lightCaramel],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Layout (consistent structure)
    static let sectionSpacing: CGFloat = 24
    static let cardSpacing: CGFloat = 14
    static let innerPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 14
    static let cornerRadiusLarge: CGFloat = 18
}

// MARK: - Reusable Modifiers

/// Glowing card style
struct GlowCardModifier: ViewModifier {
    var color: Color = Theme.primaryAccent
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func glowCard(color: Color = Theme.primaryAccent, cornerRadius: CGFloat = 16) -> some View {
        modifier(GlowCardModifier(color: color, cornerRadius: cornerRadius))
    }
}
