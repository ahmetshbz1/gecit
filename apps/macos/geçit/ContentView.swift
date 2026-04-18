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

            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("geçit")
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                        Text("Menü bar kontrol paneli")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(theme.textSecondary)
                    }
                    Spacer()
                    statusBadge
                }

                HStack(spacing: 16) {
                    actionButton(title: model.primaryActionTitle, symbol: model.primaryActionSymbol, enabled: true) {
                        model.performPrimaryAction()
                    }
                    actionButton(title: "Temizle", symbol: "sparkles", enabled: model.helperInstalled) {
                        model.cleanup()
                    }
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
                .padding(20)
                .background(theme.card, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Loglar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    ScrollView {
                        Text(model.logs)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(theme.logBackground, in: RoundedRectangle(cornerRadius: 18))
                }

                Spacer()
            }
            .padding(28)
        }
        .frame(minWidth: 720, minHeight: 560)
        .focusable(false)
    }

    private var statusBadge: some View {
        Text(model.statusTitle)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(model.status.state == .running ? Color.green : Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(theme.badgeBackground, in: Capsule())
    }

    private func actionButton(title: String, symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(enabled ? theme.primaryButtonText : theme.disabledButtonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(enabled ? theme.primaryButton : theme.disabledButton)
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .focusEffectDisabled()
        .disabled(!enabled)
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
