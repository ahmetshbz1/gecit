import Foundation

struct HelperDaemonScriptBuilder {
    func render() -> String {
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
