import SwiftUI
import AppKit

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var model: AppModel
    let onComplete: () -> Void

    private var theme: AppTheme {
        AppTheme.current(for: colorScheme)
    }

    var body: some View {
        ZStack {
            theme.backgroundBase.ignoresSafeArea()
            LinearGradient(colors: [theme.backgroundAccent, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                Text("geçit")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)

                Text("Menü barda çalışan, tek tıkla açılıp kapanan macOS istemcisi.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(theme.textSecondary)

                VStack(alignment: .leading, spacing: 16) {
                    featureRow("Menü bardan başlat / durdur", symbol: "menubar.rectangle")
                    featureRow("Yetki yalnızca ilk kurulumda alınır", symbol: "lock.shield")
                    featureRow("Binary arka planda child process olarak çalışır", symbol: "terminal")
                    featureRow("Temizlik ve durum bilgisi uygulama içinde görünür", symbol: "waveform.path.ecg")
                }

                if let installError = model.installError {
                    Text(installError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red)
                }

                Spacer()

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.helperInstalled ? "Kurulum tamam" : "Yönetici izni gerekli")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)
                        Text(model.helperInstalled ? "Artık her start/stop işleminde şifre istenmeyecek." : "macOS bir kez yönetici onayı isteyecek. Şifre uygulamada saklanmaz.")
                            .font(.system(size: 13))
                            .foregroundStyle(theme.textSecondary)
                    }
                    Spacer()
                    OnboardingActionButton(
                        label: model.helperInstalled ? "Devam Et" : "Kurulumu Başlat",
                        color: model.helperInstalled ? theme.primaryButton : theme.primaryButton,
                        textColor: model.helperInstalled ? theme.primaryButtonText : theme.primaryButtonText,
                        action: {
                            if model.helperInstalled {
                                onComplete()
                            } else {
                                model.installHelper()
                            }
                        }
                    )
                }
            }
            .padding(36)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable(false)
        .onChange(of: model.helperInstalled) { _, installed in
            if installed {
                onComplete()
            }
        }
    }

    private func featureRow(_ text: String, symbol: String) -> some View {
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
