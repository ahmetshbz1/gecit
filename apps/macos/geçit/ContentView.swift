//
//  ContentView.swift
//  geçit
//
//  Created by Ahmet on 18.04.2026.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var model: AppModel

    private var theme: AppTheme {
        AppTheme.current(for: colorScheme)
    }

    var body: some View {
        ZStack {
            theme.backgroundBase.ignoresSafeArea()
            LinearGradient(colors: [theme.backgroundAccent, .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Group {
                switch model.currentPage {
                case .main:
                    mainPage
                case .logs:
                    logsPage
                }
            }
            .padding(20)
        }
        .frame(width: 360, height: 500)
        .focusable(false)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: model.status.state)
        .animation(.easeInOut(duration: 0.2), value: model.currentPage)
    }

    private var mainPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Spacer()
                statusBadge
            }

            HStack {
                Spacer()
                primaryActionButton(title: model.primaryActionTitle, symbol: model.primaryActionSymbol, enabled: true) {
                    model.performPrimaryAction()
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Durum")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                infoRow("Servis", model.helperInstalled ? "Hazır" : "Yeniden kurulum gerekli")
                infoRow("Runtime", model.statusTitle)
                infoRow("PID", model.status.pid.map(String.init) ?? "—")
                infoRow("Mesaj", model.status.message)
            }
            .padding(16)
            .background(theme.card, in: RoundedRectangle(cornerRadius: 18))

            Button {
                model.currentPage = .logs
            } label: {
                Label("Loglar", systemImage: "doc.text.magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(theme.card, in: Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .focusEffectDisabled()

            Spacer()
        }
    }

    private var logsPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    model.currentPage = .main
                } label: {
                    Label("Geri", systemImage: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()

                Spacer()
            }

            Text("Loglar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    Text(model.logs.isEmpty ? "Henüz log yok." : model.logs)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                        .textSelection(.enabled)
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(14)
            .background(theme.logBackground, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.textPrimary.opacity(colorScheme == .dark ? 0.08 : 0.06), lineWidth: 1))
        }
    }

    private var statusBadge: some View {
        Text(model.statusTitle)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(badgeForeground)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(badgeBackground, in: Capsule())
            .animation(.easeInOut(duration: 0.22), value: model.status.state)
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

    private func primaryActionButton(title: String, symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        let buttonColor = primaryButtonColor
        let spinning = model.status.state == .starting || model.status.state == .stopping

        return Button(action: action) {
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
        .animation(.easeInOut(duration: 0.22), value: model.status.state)
    }

    private var primaryButtonColor: Color {
        switch model.status.state {
        case .stopping:
            return theme.primaryButtonStop.opacity(0.82)
        case .starting:
            return Color.orange
        default:
            return model.primaryActionSymbol == "stop.fill" ? theme.primaryButtonStop : theme.primaryButtonStart
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

#Preview {
    ContentView(model: AppModel())
}
