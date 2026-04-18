import Foundation

struct GecitControlService {
    func send(_ command: String) throws {
        guard ["start", "stop", "cleanup", "status"].contains(command) else {
            throw NSError(domain: "GecitControlService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz komut"])
        }
        try FileManager.default.createDirectory(atPath: AppPaths.sharedDirectory, withIntermediateDirectories: true)
        try (command + "\n").write(toFile: AppPaths.commandFile, atomically: true, encoding: .utf8)
    }

    func readStatus() -> GecitStatus {
        guard let data = FileManager.default.contents(atPath: AppPaths.statusFile) else {
            return .empty
        }
        return (try? JSONDecoder().decode(GecitStatus.self, from: data)) ?? .empty
    }

    func readLogs() -> String {
        guard let text = try? String(contentsOfFile: AppPaths.logFile, encoding: .utf8) else {
            return "Henüz log yok."
        }
        return String(text.suffix(6000))
    }
}
