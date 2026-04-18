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
                case .settings:
                    settingsPage
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

    private var logsPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            pageHeader(title: "Loglar")

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(attributedLogs)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Color.clear
                            .frame(height: 1)
                            .id("logs-bottom")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(14)
                .background(theme.logBackground, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.textPrimary.opacity(colorScheme == .dark ? 0.08 : 0.06), lineWidth: 1))
                .onAppear {
                    scrollToBottom(proxy)
                }
                .onChange(of: model.logs) { _, _ in
                    scrollToBottom(proxy)
                }
            }
        }
    }

    private var settingsPage: some View {
        VStack(alignment: .leading, spacing: 16) {
            pageHeader(title: "Ayarlar")

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Spacer()
                        HoverCapsuleButton(helpText: "Varsayılan ayarlara dön", action: {
                            model.resetSettingsToDefault()
                        }) {
                            Text("Varsayılana dön")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                settingsField(title: "Fake TTL") {
                    NativeStepperField(value: $model.settingsFakeTTL, minValue: 1, maxValue: 64)
                }

                settingsField(title: "DoH") {
                    Toggle("Etkin", isOn: $model.settingsDoHEnabled)
                        .toggleStyle(.switch)
                }

                settingsField(title: "Upstream") {
                    Picker("Upstream", selection: $model.settingsDoHUpstream) {
                        ForEach(AppModel.dohPresets, id: \.self) { preset in
                            Text(preset.capitalized).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                settingsField(title: "Interface") {
                    TextField("en0", text: $model.settingsInterface)
                        .textFieldStyle(.roundedBorder)
                }

                settingsField(title: "Ports") {
                    TextField("443 veya 443,8443", text: $model.settingsPorts)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(16)
            .background(theme.card, in: RoundedRectangle(cornerRadius: 18))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func settingsField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.textMuted)
            content()
        }
    }

    private func pageHeader(title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
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

    private var primaryActionSection: some View {
        HStack {
            Spacer()
            primaryActionButton(title: model.primaryActionTitle, symbol: model.primaryActionSymbol, enabled: true) {
                model.performPrimaryAction()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var headerActions: some View {
        HStack(spacing: 10) {
            HoverCapsuleButton(helpText: "Loglar", action: {
                model.currentPage = .logs
            }) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
            }

            HoverCapsuleButton(helpText: "Ayarlar", action: {
                model.currentPage = .settings
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .semibold))
            }
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

    private var attributedLogs: AttributedString {
        let lines = model.logs
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        let source = lines.isEmpty ? ["Henüz log yok."] : lines
        var output = AttributedString()

        for (index, entry) in source.enumerated() {
            var line = AttributedString(entry.isEmpty ? " " : entry)
            line.foregroundColor = logTextColor(for: entry)
            output.append(line)
            if index < source.count - 1 {
                output.append(AttributedString("\n"))
            }
        }

        return output
    }

    private func logTextColor(for entry: String) -> Color {
        if entry.contains("level=error") || entry.contains("error") {
            return colorScheme == .dark ? Color.red.opacity(0.95) : Color.red.opacity(0.85)
        }
        if entry.contains("level=info") || entry.contains("injected") || entry.contains("running") {
            return colorScheme == .dark ? Color.green.opacity(0.95) : Color.green.opacity(0.78)
        }
        if entry.contains("level=debug") || entry.contains("resolved") {
            return colorScheme == .dark ? Color.blue.opacity(0.92) : Color.blue.opacity(0.78)
        }
        if entry.contains("warning") || entry.contains("stopping") || entry.contains("starting") {
            return colorScheme == .dark ? Color.orange.opacity(0.95) : Color.orange.opacity(0.82)
        }
        return theme.textSecondary
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.24)) {
                proxy.scrollTo("logs-bottom", anchor: .bottom)
            }
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
