import SwiftUI

struct OnboardingHeroSection: View {
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("geçit")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
        }
    }
}
