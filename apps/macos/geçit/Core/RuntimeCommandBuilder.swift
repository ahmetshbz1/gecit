import Foundation

enum RuntimeCommandBuilder {
    static func buildStartCommand(settings: SettingsStore) -> String {
        let ttl = max(1, settings.fakeTTL)
        let doh = settings.doHEnabled ? "true" : "false"
        let upstream = settings.doHUpstream.trimmingCharacters(in: .whitespacesAndNewlines)
        let iface = settings.interface.trimmingCharacters(in: .whitespacesAndNewlines)
        let ports = settings.ports.trimmingCharacters(in: .whitespacesAndNewlines)

        var parts = ["start", "--fake-ttl=\(ttl)", "--doh=\(doh)"]
        if !upstream.isEmpty { parts.append("--doh-upstream=\(upstream)") }
        if !iface.isEmpty { parts.append("--interface=\(iface)") }
        if !ports.isEmpty { parts.append("--ports=\(ports)") }
        return parts.joined(separator: " ")
    }
}
