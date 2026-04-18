import Foundation

struct GecitHelperInstaller {
    func isInstalled() -> Bool {
        guard FileManager.default.fileExists(atPath: AppPaths.helperScriptPath),
              FileManager.default.fileExists(atPath: AppPaths.helperPlistPath),
              FileManager.default.fileExists(atPath: AppPaths.installedBinaryPath),
              let version = try? String(contentsOfFile: AppPaths.helperVersionPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            return false
        }
        return version == AppPaths.helperVersion
    }

    func install() throws {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let daemonURL = tempDirectory.appendingPathComponent("gecit-helper.sh")
        let plistURL = tempDirectory.appendingPathComponent("\(AppPaths.helperIdentifier).plist")
        let installURL = tempDirectory.appendingPathComponent("install-helper.sh")
        let binaryURL = tempDirectory.appendingPathComponent("gecit-darwin-arm64")

        try renderDaemonScript().write(to: daemonURL, atomically: true, encoding: .utf8)
        try renderPlist().write(to: plistURL, atomically: true, encoding: .utf8)
        try FileManager.default.copyItem(at: URL(fileURLWithPath: AppPaths.bundledBinaryPath), to: binaryURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryURL.path)
        try renderInstallScript(daemonURL: daemonURL.path, plistURL: plistURL.path, binaryURL: binaryURL.path).write(to: installURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installURL.path)

        try runAdministratorScript(at: installURL.path)
    }

    private func runAdministratorScript(at path: String) throws {
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

    private func renderInstallScript(daemonURL: String, plistURL: String, binaryURL: String) -> String {
        """
        #!/bin/bash
        set -euo pipefail
        mkdir -p "/Library/Application Support/Gecit"
        install -m 755 "\(daemonURL)" "\(AppPaths.helperScriptPath)"
        install -m 755 "\(binaryURL)" "\(AppPaths.installedBinaryPath)"
        install -m 644 "\(plistURL)" "\(AppPaths.helperPlistPath)"
        echo "\(AppPaths.helperVersion)" > "\(AppPaths.helperVersionPath)"
        mkdir -p "\(AppPaths.sharedDirectory)"
        chmod 777 "\(AppPaths.sharedDirectory)"
        touch "\(AppPaths.commandFile)" "\(AppPaths.logFile)"
        chmod 666 "\(AppPaths.commandFile)" "\(AppPaths.logFile)"
        launchctl bootout system/\(AppPaths.helperIdentifier) >/dev/null 2>&1 || true
        launchctl bootstrap system "\(AppPaths.helperPlistPath)"
        launchctl kickstart -k system/\(AppPaths.helperIdentifier)
        """
    }

    private func renderPlist() -> String {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(AppPaths.helperIdentifier)</string>
            <key>ProgramArguments</key>
            <array>
                <string>/bin/bash</string>
                <string>\(AppPaths.helperScriptPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>\(AppPaths.logFile)</string>
            <key>StandardErrorPath</key>
            <string>\(AppPaths.logFile)</string>
        </dict>
        </plist>
        """
    }

    private func renderDaemonScript() -> String {
        """
        #!/bin/bash
        set -uo pipefail
        BASE="\(AppPaths.sharedDirectory)"
        CMD_FILE="$BASE/command"
        STATUS_FILE="$BASE/status.json"
        LOG_FILE="$BASE/gecit.log"
        PID_FILE="$BASE/gecit.pid"
        BINARY="\(AppPaths.installedBinaryPath)"

        mkdir -p "$BASE"
        touch "$CMD_FILE" "$LOG_FILE"
        chmod 777 "$BASE"
        chmod 666 "$CMD_FILE" "$LOG_FILE"

        write_status() {
          local state="$1"
          local message="$2"
          local pid="null"
          if [ -f "$PID_FILE" ]; then
            local current_pid
            current_pid=$(cat "$PID_FILE" 2>/dev/null || true)
            if [ -n "$current_pid" ] && kill -0 "$current_pid" 2>/dev/null; then
              pid="$current_pid"
            fi
          fi
          cat > "$STATUS_FILE" <<EOF
        {"state":"$state","pid":$pid,"message":"$message","updatedAt":"$(date -u +%FT%TZ)"}
        EOF
          chmod 666 "$STATUS_FILE"
        }

        is_running() {
          [ -f "$PID_FILE" ] || return 1
          local current_pid
          current_pid=$(cat "$PID_FILE" 2>/dev/null || true)
          [ -n "$current_pid" ] && kill -0 "$current_pid" 2>/dev/null
        }

        start_gecit() {
          shift
          if is_running; then
            write_status "running" "Gecit zaten çalışıyor"
            return
          fi
          if [ ! -x "$BINARY" ]; then
            write_status "error" "Binary bulunamadı: $BINARY"
            return
          fi
          write_status "starting" "Gecit başlatılıyor"
          local args=(run -v "$@")
          "$BINARY" "${args[@]}" >> "$LOG_FILE" 2>&1 &
          echo $! > "$PID_FILE"
          sleep 2
          if is_running; then
            write_status "running" "Gecit çalışıyor"
          else
            rm -f "$PID_FILE"
            write_status "error" "Gecit başlatılamadı"
          fi
        }

        stop_gecit() {
          write_status "stopping" "Gecit durduruluyor"
          if is_running; then
            local current_pid
            current_pid=$(cat "$PID_FILE")
            kill "$current_pid" 2>/dev/null || true
            sleep 2
            kill -9 "$current_pid" 2>/dev/null || true
          fi
          rm -f "$PID_FILE"
          "$BINARY" cleanup >> "$LOG_FILE" 2>&1 || true
          write_status "stopped" "Gecit durdu"
        }

        handle_command() {
          read -r -a parts <<< "$1"
          local command="${parts[0]}"
          case "$command" in
            start) start_gecit "${parts[@]}" ;;
            stop) stop_gecit ;;
            cleanup) stop_gecit ;;
            status) if is_running; then write_status "running" "Gecit çalışıyor"; else write_status "stopped" "Gecit durdu"; fi ;;
            *) write_status "error" "Bilinmeyen komut: $1" ;;
          esac
        }

        write_status "stopped" "Hazır"
        while true; do
          if [ -s "$CMD_FILE" ]; then
            command=$(tr -d '\\r' < "$CMD_FILE" | tr -d '\\n')
            : > "$CMD_FILE"
            handle_command "$command"
          else
            if is_running; then
              write_status "running" "Gecit çalışıyor"
            fi
          fi
          sleep 1
        done
        """
    }
}
