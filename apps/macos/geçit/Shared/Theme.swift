import SwiftUI

struct AppTheme {
    let backgroundBase: Color
    let backgroundAccent: Color
    let card: Color
    let cardStrong: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let logBackground: Color
    let badgeBackground: Color
    let primaryButton: Color
    let primaryButtonText: Color
    let disabledButton: Color
    let disabledButtonText: Color

    static func current(for scheme: ColorScheme) -> AppTheme {
        if scheme == .light {
            return AppTheme(
                backgroundBase: Color.white,
                backgroundAccent: Color.black.opacity(0.03),
                card: Color.black.opacity(0.05),
                cardStrong: Color.black.opacity(0.035),
                textPrimary: Color.black.opacity(0.92),
                textSecondary: Color.black.opacity(0.66),
                textMuted: Color.black.opacity(0.5),
                logBackground: Color.black.opacity(0.06),
                badgeBackground: Color.black.opacity(0.06),
                primaryButton: Color.black.opacity(0.92),
                primaryButtonText: .white,
                disabledButton: Color.black.opacity(0.08),
                disabledButtonText: Color.black.opacity(0.35)
            )
        }

        return AppTheme(
            backgroundBase: Color.black,
            backgroundAccent: Color.white.opacity(0.03),
            card: Color.white.opacity(0.06),
            cardStrong: Color.white.opacity(0.045),
            textPrimary: .white,
            textSecondary: Color.white.opacity(0.72),
            textMuted: Color.white.opacity(0.55),
            logBackground: Color.black.opacity(0.3),
            badgeBackground: Color.white.opacity(0.08),
            primaryButton: Color.white.opacity(0.92),
            primaryButtonText: .black,
            disabledButton: Color.white.opacity(0.12),
            disabledButtonText: Color.white.opacity(0.4)
        )
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}
