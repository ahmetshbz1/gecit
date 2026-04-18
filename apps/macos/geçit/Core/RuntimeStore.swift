import Combine
import Foundation

@MainActor
final class RuntimeStore: ObservableObject {
    @Published var helperInstalled = false
    @Published var onboardingCompleted = false
    @Published var status: GecitStatus = .empty
    @Published var logs = "Henüz log yok."
    @Published var installError: String?
    @Published var currentPage: Page = .main {
        didSet {
            handlePageChange(from: oldValue, to: currentPage)
        }
    }

    private let installer: GecitHelperInstaller
    private let control: GecitControlService
    private var timer: Timer?
    private var pollingInterval: TimeInterval?
    private var isObserving = false
    private var lastStatusSignature = ""
    private var lastLogsSignature = ""

    init(installer: GecitHelperInstaller? = nil, control: GecitControlService? = nil) {
        self.installer = installer ?? GecitHelperInstaller()
        self.control = control ?? GecitControlService()
        onboardingCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        helperInstalled = self.installer.isInstalled()
        refresh()
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
                refresh(includeLogs: true)
                NSLog("gecit install succeeded")
            } else {
                installError = "Kurulum tamamlanmadı. Yönetici onayı penceresi kapanmış olabilir."
            }
        } catch {
            NSLog("gecit install failed: %@", error.localizedDescription)
            installError = error.localizedDescription
        }
    }

    func start(with settings: SettingsStore) {
        status = GecitStatus(state: .starting, pid: status.pid, message: "Gecit başlatılıyor", updatedAt: status.updatedAt)
        let command = RuntimeCommandBuilder.buildStartCommand(settings: settings)
        try? control.send(command)
        refreshSoon(includeLogs: true)
    }

    func stop() {
        status = GecitStatus(state: .stopping, pid: status.pid, message: "Gecit durduruluyor", updatedAt: status.updatedAt)
        try? control.send("stop")
        refreshSoon(includeLogs: true)
    }

    func cleanup() {
        try? control.send("cleanup")
        stopObserving()
        refreshSoon(includeLogs: false)
    }

    func startObserving() {
        isObserving = true
        refresh()
        schedulePolling(force: true)
    }

    func stopObserving() {
        isObserving = false
        timer?.invalidate()
        timer = nil
        pollingInterval = nil
    }

    func refresh() {
        refresh(includeLogs: nil)
    }

    func refresh(includeLogs: Bool?) {
        refreshStatus()
        if includeLogs ?? shouldReadLogs {
            refreshLogs()
        }
    }

    private func refreshStatus() {
        helperInstalled = installer.isInstalled()
        let nextStatus = control.readStatus()
        if !helperInstalled && nextStatus.state == .error && nextStatus.message == "Gecit başlatılamadı" {
            installError = "Helper güncellendi. Bir kez daha 'Yeniden Kur' ile kurulumu tazele."
        }
        let signature = "\(nextStatus.state.rawValue)|\(nextStatus.pid ?? -1)|\(nextStatus.message)|\(nextStatus.updatedAt)"
        guard signature != lastStatusSignature else { return }
        lastStatusSignature = signature
        status = nextStatus
    }

    private func refreshLogs() {
        let nextLogs = control.readLogs()
        let signature = String(nextLogs.hashValue)
        guard signature != lastLogsSignature else { return }
        lastLogsSignature = signature
        logs = nextLogs
    }

    private var shouldReadLogs: Bool {
        currentPage == .logs
    }

    private var targetPollingInterval: TimeInterval {
        shouldReadLogs ? 2 : 4
    }

    private func handlePageChange(from oldPage: Page, to newPage: Page) {
        guard oldPage != newPage else { return }
        if newPage == .logs {
            refreshLogs()
        }
        if isObserving {
            schedulePolling(force: true)
        }
    }

    private func schedulePolling(force: Bool) {
        guard isObserving else { return }
        let interval = targetPollingInterval
        guard force || timer == nil || pollingInterval != interval else { return }
        timer?.invalidate()
        pollingInterval = interval
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        timer.tolerance = interval * 0.35
        self.timer = timer
    }

    private func refreshSoon(includeLogs: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.refresh(includeLogs: includeLogs)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.refresh(includeLogs: includeLogs)
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

    func performPrimaryAction(start: () -> Void) {
        if needsHelperReinstall {
            installHelper()
        } else if canStop {
            stop()
        } else {
            start()
        }
    }
}
