import SwiftUI

struct OnboardingFeatureList: View {
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingFeatureRow(text: "Menü bardan başlat / durdur", symbol: "menubar.rectangle", theme: theme)
            OnboardingFeatureRow(text: "İlk kurulum için yönetici onayı gerekir", symbol: "lock.shield", theme: theme)
            OnboardingFeatureRow(text: "Arka planda güvenli şekilde çalışır", symbol: "terminal", theme: theme)
        }
    }
}

private struct OnboardingFeatureRow: View {
    let text: String
    let symbol: String
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
                .frame(width: 34, height: 34)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 10))

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.textPrimary)
        }
    }
}
