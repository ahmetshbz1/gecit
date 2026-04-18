import Foundation

struct AdministratorScriptRunner {
    func runScript(at path: String) throws {
        let script = "do shell script \"/bin/bash \" & quoted form of \"\(appleScriptEscaped(path))\" with administrator privileges"
        NSLog("gecit install AppleScript: %@", script)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        NSLog("gecit install output: %@", output)

        if process.terminationStatus != 0 {
            throw NSError(domain: "GecitHelperInstaller", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output.isEmpty ? "Yönetici onayı başarısız oldu" : output])
        }
    }

    private func appleScriptEscaped(_ string: String) -> String {
        string.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
