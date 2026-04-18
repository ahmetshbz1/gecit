import SwiftUI

@MainActor
final class SettingsStore {
    static let dohPresets = ["cloudflare", "google", "quad9", "nextdns", "adguard"]

    @AppStorage("settingsFakeTTL") var fakeTTL = 8
    @AppStorage("settingsDoHEnabled") var doHEnabled = true
    @AppStorage("settingsDoHUpstream") var doHUpstream = "cloudflare"
    @AppStorage("settingsInterface") var interface = ""
    @AppStorage("settingsPorts") var ports = "443"

    func resetToDefault() {
        fakeTTL = 8
        doHEnabled = true
        doHUpstream = "cloudflare"
        interface = ""
        ports = "443"
    }

    var summary: String {
        let upstream = doHUpstream.isEmpty ? "cloudflare" : doHUpstream
        let interfaceValue = interface.isEmpty ? "otomatik" : interface
        let dohValue = doHEnabled ? "açık" : "kapalı"
        return "TTL \(fakeTTL) • DoH \(dohValue) • \(upstream) • \(interfaceValue) • \(ports)"
    }
}
