import SwiftUI

struct MainPageView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var model: AppModel
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Spacer()
                headerActions
            }

            primaryActionSection

            VStack(alignment: .leading, spacing: 10) {
                Text("Durum")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                infoRow("Servis", model.helperInstalled ? "Hazır" : "Yeniden kurulum gerekli")
                runtimeBadgeRow
                infoRow("PID", model.status.pid.map(String.init) ?? "—")
                infoRow("Mesaj", model.status.message)
                infoRow("Ayarlar", model.currentSettingsSummary)
            }
            .padding(16)
            .background(theme.card, in: RoundedRectangle(cornerRadius: 18))

            Spacer()
        }
    }

    private var primaryActionSection: some View {
        HStack {
            Spacer()
            PrimaryActionButton(
                title: model.primaryActionTitle,
                symbol: model.primaryActionSymbol,
                enabled: true,
                state: model.status.state,
                theme: theme,
                colorScheme: colorScheme
            ) {
                model.performPrimaryAction()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var headerActions: some View {
        HStack(spacing: 10) {
            Button {
                model.currentPage = .logs
            } label: {
                HoverCapsuleContent(helpText: "Loglar") {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .focusEffectDisabled()

            Button {
                model.currentPage = .settings
            } label: {
                HoverCapsuleContent(helpText: "Ayarlar") {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .focusEffectDisabled()
        }
    }

    private var runtimeBadgeRow: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("Runtime")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textMuted)
                .frame(width: 72, alignment: .leading)

            HStack {
                Text(model.statusTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(badgeForeground)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(badgeBackground, in: Capsule())
                    .animation(.easeInOut(duration: 0.22), value: model.status.state)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var badgeForeground: Color {
        switch model.status.state {
        case .running:
            return Color.green
        case .starting, .stopping:
            return Color.orange
        default:
            return theme.textPrimary
        }
    }

    private var badgeBackground: Color {
        switch model.status.state {
        case .running:
            return Color.green.opacity(colorScheme == .dark ? 0.16 : 0.14)
        case .starting, .stopping:
            return Color.orange.opacity(colorScheme == .dark ? 0.18 : 0.14)
        default:
            return theme.badgeBackground
        }
    }

    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textMuted)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textPrimary)
            Spacer()
        }
    }
}
