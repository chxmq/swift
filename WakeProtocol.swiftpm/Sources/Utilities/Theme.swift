import SwiftUI

/// Design system for Wake Protocol — dark sci-fi aesthetic with depth
enum Theme {
    // MARK: - Core Colors
    static let background = Color(red: 0.04, green: 0.05, blue: 0.10)
    static let surface = Color(red: 0.08, green: 0.10, blue: 0.18)
    static let surfaceElevated = Color(red: 0.10, green: 0.12, blue: 0.22)
    static let primaryAccent = Color(red: 0.0, green: 0.85, blue: 1.0)    // Cyan
    static let warningAccent = Color(red: 1.0, green: 0.65, blue: 0.0)    // Amber
    static let dangerAccent = Color(red: 1.0, green: 0.15, blue: 0.15)    // Red
    static let successAccent = Color(red: 0.0, green: 1.0, blue: 0.53)    // Green
    static let purpleAccent = Color(red: 0.56, green: 0.35, blue: 1.0)    // Purple

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.3)

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
        colors: [primaryAccent, purpleAccent],
        startPoint: .leading,
        endPoint: .trailing
    )
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
                    .stroke(color.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func glowCard(color: Color = Theme.primaryAccent, cornerRadius: CGFloat = 16) -> some View {
        modifier(GlowCardModifier(color: color, cornerRadius: cornerRadius))
    }
}
