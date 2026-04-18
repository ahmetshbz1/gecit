import SwiftUI

struct OnboardingFooter: View {
    let theme: AppTheme
    let helperInstalled: Bool
    let onPrimaryAction: () -> Void

    private var title: String {
        helperInstalled ? "Kurulum tamam" : "Yönetici izni gerekli"
    }

    private var description: String {
        helperInstalled
            ? "Artık her start/stop işleminde şifre istenmeyecek."
            : "macOS bir kez yönetici onayı isteyecek. Şifre uygulamada saklanmaz."
    }

    private var buttonLabel: String {
        helperInstalled ? "Devam Et" : "Kurulumu Başlat"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            OnboardingActionButton(
                label: buttonLabel,
                color: theme.primaryButtonStart,
                textColor: theme.primaryButtonText,
                action: onPrimaryAction
            )
        }
    }
}

private struct OnboardingActionButton: View {
    let label: String
    let color: Color
    let textColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(textColor)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(color)
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .focusEffectDisabled()
    }
}
