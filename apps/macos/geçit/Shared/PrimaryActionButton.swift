import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let symbol: String
    let enabled: Bool
    let state: GecitRuntimeState
    let theme: AppTheme
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        let buttonColor = primaryButtonColor
        let spinning = state == .starting || state == .stopping

        Button(action: action) {
            ZStack {
                Circle()
                    .fill(enabled ? buttonColor : theme.disabledButton)
                    .overlay(Circle().stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12), lineWidth: 1))
                    .scaleEffect(spinning ? 1.06 : 1)

                Circle()
                    .stroke(theme.primaryButtonText.opacity(spinning ? 0.28 : 0), lineWidth: 3)
                    .scaleEffect(spinning ? 1.16 : 1)
                    .opacity(spinning ? 1 : 0)

                VStack(spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: spinning ? 30 : 28, weight: .bold))
                        .offset(y: spinning ? -2 : 0)
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .offset(y: spinning ? 2 : 0)
                }
                .foregroundStyle(enabled ? theme.primaryButtonText : theme.disabledButtonText)
                .opacity(spinning ? 0.96 : 1)
            }
            .frame(width: 104, height: 104)
            .shadow(color: buttonColor.opacity(colorScheme == .dark ? 0.28 : 0.16), radius: spinning ? 24 : 18, y: spinning ? 12 : 10)
        }
        .buttonStyle(ScaleButtonStyle())
        .focusEffectDisabled()
        .disabled(!enabled)
        .animation(.spring(response: 0.42, dampingFraction: 0.72), value: spinning)
        .animation(.easeInOut(duration: 0.22), value: state)
    }

    private var primaryButtonColor: Color {
        switch state {
        case .stopping:
            return theme.primaryButtonStop.opacity(0.82)
        case .starting:
            return Color.orange
        default:
            return symbol == "stop.fill" ? theme.primaryButtonStop : theme.primaryButtonStart
        }
    }
}
