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
                OnboardingHeroSection(theme: theme)
                OnboardingFeatureList(theme: theme)

                if let installError = model.installError {
                    Text(installError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red)
                }

                Spacer()

                OnboardingFooter(
                    theme: theme,
                    helperInstalled: model.helperInstalled,
                    onPrimaryAction: {
                        if model.helperInstalled {
                            onComplete()
                        } else {
                            model.installHelper()
                        }
                    }
                )
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
}
