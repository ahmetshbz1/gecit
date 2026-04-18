import AppKit
import Combine
import Foundation
import SwiftUI

enum Page {
    case main
    case logs
    case settings
}

@MainActor
final class AppModel: ObservableObject {
    @AppStorage("settingsFakeTTL") var settingsFakeTTL = 8
    @AppStorage("settingsDoHEnabled") var settingsDoHEnabled = true
    static let dohPresets = ["cloudflare", "google", "quad9", "nextdns", "adguard"]
    @AppStorage("settingsDoHUpstream") var settingsDoHUpstream = "cloudflare"
    @AppStorage("settingsInterface") var settingsInterface = ""
    @AppStorage("settingsPorts") var settingsPorts = "443"
    @Published var helperInstalled = false
    @Published var onboardingCompleted = false
    @Published var status: GecitStatus = .empty
    @Published var logs = "Henüz log yok."
    @Published var installError: String?
    @Published var currentPage: Page = .main

    private let installer = GecitHelperInstaller()
    private let control = GecitControlService()
    private var timer: Timer?
    private var lastStatusSignature = ""

    init() {
        onboardingCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        helperInstalled = installer.isInstalled()
        refresh()
        startPolling()
    }

    deinit {
        timer?.invalidate()
    }

    func installHelper() {
        installError = nil
        NSLog("gecit install requested")
        do {
            try installer.install()
            helperInstalled = installer.isInstalled()
            onboardingCompleted = helperInstalled
            if helperInstalled {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                try? control.send("status")
                refresh()
                NSLog("gecit install succeeded")
            } else {
                installError = "Kurulum tamamlanmadı. Yönetici onayı penceresi kapanmış olabilir."
            }
        } catch {
            NSLog("gecit install failed: %@", error.localizedDescription)
            installError = error.localizedDescription
        }
    }

    func start() {
        status = GecitStatus(state: .starting, pid: status.pid, message: "Gecit başlatılıyor", updatedAt: status.updatedAt)
        let command = startCommand()
        try? control.send(command)
        refreshSoon()
    }

    func stop() {
        status = GecitStatus(state: .stopping, pid: status.pid, message: "Gecit durduruluyor", updatedAt: status.updatedAt)
        try? control.send("stop")
        refreshSoon()
    }

    func cleanup() {
        try? control.send("cleanup")
        refreshSoon()
    }

    func refresh() {
        helperInstalled = installer.isInstalled()
        let nextStatus = control.readStatus()
        if !helperInstalled && nextStatus.state == .error && nextStatus.message == "Gecit başlatılamadı" {
            installError = "Helper güncellendi. Bir kez daha 'Yeniden Kur' ile kurulumu tazele."
        }
        let nextLogs = control.readLogs()
        let signature = "\(nextStatus.state.rawValue)|\(nextStatus.pid ?? -1)|\(nextStatus.message)|\(nextLogs.hashValue)"
        guard signature != lastStatusSignature else { return }
        lastStatusSignature = signature
        status = nextStatus
        logs = nextLogs
    }

    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    private func refreshSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.refresh()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.refresh()
        }
    }

    var statusTitle: String {
        switch status.state {
        case .onboarding: return "Kurulum gerekli"
        case .stopped: return "Durduruldu"
        case .starting: return "Başlatılıyor"
        case .running: return "Çalışıyor"
        case .stopping: return "Durduruluyor"
        case .error: return "Hata"
        }
    }

    var canStart: Bool {
        helperInstalled && status.state != .running && status.state != .starting && status.state != .stopping
    }

    var needsHelperReinstall: Bool {
        !helperInstalled
    }

    var canStop: Bool {
        helperInstalled && (status.state == .running || status.state == .starting || status.state == .error)
    }

    var primaryActionTitle: String {
        if needsHelperReinstall { return "Yeniden Kur" }
        if canStop { return "Durdur" }
        return "Başlat"
    }

    var primaryActionSymbol: String {
        if needsHelperReinstall { return "arrow.clockwise" }
        if canStop { return "stop.fill" }
        return "play.fill"
    }

    func performPrimaryAction() {
        if needsHelperReinstall {
            installHelper()
        } else if canStop {
            stop()
        } else {
            start()
        }
    }

    func resetSettingsToDefault() {
        settingsFakeTTL = 8
        settingsDoHEnabled = true
        settingsDoHUpstream = "cloudflare"
        settingsInterface = ""
        settingsPorts = "443"
    }

    var currentSettingsSummary: String {
        let upstream = settingsDoHUpstream.isEmpty ? "cloudflare" : settingsDoHUpstream
        let interfaceValue = settingsInterface.isEmpty ? "otomatik" : settingsInterface
        let dohValue = settingsDoHEnabled ? "açık" : "kapalı"
        return "TTL \(settingsFakeTTL) • DoH \(dohValue) • \(upstream) • \(interfaceValue) • \(settingsPorts)"
    }

    private func startCommand() -> String {
        let ttl = max(1, settingsFakeTTL)
        let doh = settingsDoHEnabled ? "true" : "false"
        let upstream = settingsDoHUpstream.trimmingCharacters(in: .whitespacesAndNewlines)
        let iface = settingsInterface.trimmingCharacters(in: .whitespacesAndNewlines)
        let ports = settingsPorts.trimmingCharacters(in: .whitespacesAndNewlines)

        var parts = ["start", "--fake-ttl=\(ttl)", "--doh=\(doh)"]
        if !upstream.isEmpty { parts.append("--doh-upstream=\(upstream)") }
        if !iface.isEmpty { parts.append("--interface=\(iface)") }
        if !ports.isEmpty { parts.append("--ports=\(ports)") }
        return parts.joined(separator: " ")
    }
}
