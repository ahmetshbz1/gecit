import SwiftUI

struct OnboardingHeroSection: View {
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("geçit")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Text("Menü barda çalışan, tek tıkla açılıp kapanan macOS istemcisi.")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(theme.textSecondary)
        }
    }
}
